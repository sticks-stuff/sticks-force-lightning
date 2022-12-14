
-----------------------------------------------------


TRACER_FLAG_USEATTACHMENT	= 0x0002;



local function GetTracerOrigin(start,flags,entity,att)



	--local start = data:GetStart();



	-- use attachment?

	if ( bit.band( flags, TRACER_FLAG_USEATTACHMENT ) == TRACER_FLAG_USEATTACHMENT ) then



		--local entity = data:GetEntity();



		if ( not IsValid( entity ) ) then return start; end

		if ( not game.SinglePlayer() and entity:IsEFlagSet( EFL_DORMANT ) ) then return start; end



		if ( entity:IsWeapon() and entity:IsCarriedByLocalPlayer() ) then

			-- can't be done, can't call the real function

			-- local origin = weapon:GetTracerOrigin();

			-- if( origin ) then

			-- 	return origin, angle, entity;

			-- end



			-- use the view model

			local pl = entity:GetOwner();

			if ( IsValid( pl ) and pl.GetViewModel ) then

				local vm = pl:GetViewModel();

				if ( IsValid( vm ) and not LocalPlayer():ShouldDrawLocalPlayer() ) then

					entity = vm;

				else

					-- HACK: fix the model in multiplayer

					if ( entity.WorldModel ) then

						entity:SetModel( entity.WorldModel );

					end

				end

			end

		end



		local attachment = entity:GetAttachment( att );

		if ( attachment ) then

			start = attachment.Pos;

		end



	end

	

	return start;



end







local function GetRandomPositionInBox( mins, maxs, ang )

	return ang:Up() * math.random( mins.z, maxs.z ) + ang:Right() * math.random( mins.y, maxs.y ) + ang:Forward() * math.random( mins.x, maxs.x )

end



local function GenerateLightingSegs( from, to, deviations, segs, ent )

	local start = from

	if ( isentity( start ) ) then start = from:GetPos() end

	local endpos = to --:GetPos()

	if ( isentity( endpos ) ) then 

		endpos = to:GetPos() + GetRandomPositionInBox( to:OBBMins(), to:OBBMaxs(), to:GetAngles() )

	end



	local right = (start - endpos):Angle():Right()

	local up = (start - endpos):Angle():Up()

	local fwd = (start - endpos):Angle():Forward()

	local step = (1 / segs) * start:Distance( endpos )



	local lastpos = start

	local segments = {}

	for i = 1, segs do

		local a = lastpos - fwd * step

		table.insert( segments, { lastpos, a, ent } )

		lastpos = a

	end



	for k, v in pairs( segments ) do

		if ( k == 1 || k == #segments ) then continue end



		segments[ k ][ 1 ] = segments[ k ][ 1 ] + right * math.random( -deviations, deviations ) + up * math.random( -deviations, deviations )

		segments[ k - 1 ][ 2 ] = segments[ k ][ 1 ]

	end



	for k, v in pairs( segments ) do

		if ( k == 1 || k == #segments ) then continue end



		if ( math.random( 0, 100 ) > 75 ) then

			local dir = AngleRand():Forward()

			table.insert( segments, { segments[ k ][ 1 ], segments[ k ][ 1 ] + dir * ( step * math.Rand( 0.1, 0.2 ) ) } )

		end

	end



	return segments

end



local mats = {

	(Material( "lightning/force-lightning" )),

	/*(Material( "cable/hydra" )),

	(Material( "cable/redlaser" )),

	(Material( "cable/crystal_beam1" )),

	(Material( "cable/physbeam" )),

	(Material( "cable/smoke" )),

	(Material( "cable/xbeam" )),*/

}



local segments = {}

--local n = 0

local tiem = 0.4
local segStartTimes = {}

hook.Add( "PostDrawTranslucentRenderables", "ARCBlastRender", function()

	for id, t in pairs( segments ) do

		render.SetMaterial( t.mat )
		for id, seg in pairs( t.segs ) do
			if ( t.time < CurTime() ) then table.remove( segments, id ) continue end
			-- if ( (segStartTimes[id] + (tiem * id)) > CurTime() ) then 
			-- 	if segStartTimes[id] < CurTime() then
			-- 		local diffX = (seg[2].x - seg[1].x) * (1 - ((t.time - CurTime()) * (1 / tiem)))
			-- 		local diffY = (seg[2].y - seg[1].y) * (1 - ((t.time - CurTime()) * (1 / tiem)))
			-- 		local diffZ = (seg[2].Z - seg[1].z) * (1 - ((t.time - CurTime()) * (1 / tiem)))
			-- 		render.DrawBeam( seg[1], Vector(seg[1].x + diffX, seg[1].y + diffY, seg[1].z + diffZ ), ( math.max( t.startpos:Distance( t.endpos ) - seg[1]:Distance( t.endpos ), 20) / ( t.startpos:Distance( t.endpos ) ) * t.w ) * ( (t.time - CurTime() ) / tiem ), 0, seg[1]:Distance( seg[2] ) / 25, Color( 0, 0, 255 ) )	
			-- 	end
			-- else
			-- 	table.remove( t.segs, id ) 
			-- end

			local dlight = DynamicLight( LocalPlayer():EntIndex() )
			dlight.pos = seg[1]
			dlight.r = 22
			dlight.g = 18
			dlight.b = 83
			dlight.brightness = 2
			dlight.Decay = 1000
			dlight.Size = 256
			dlight.DieTime = CurTime() + 0.4
			if id == 1 then				
				seg[1] = GetTracerOrigin((seg[3].Owner:GetPos()) + Vector(0,0,30), 0x0002, seg[3], 1)
			end
			render.DrawBeam( seg[1], seg[2], ( math.max( t.startpos:Distance( t.endpos ) - seg[1]:Distance( t.endpos ), 20) / ( t.startpos:Distance( t.endpos ) ) * t.w ) * ( (t.time - CurTime() ) / tiem ), 0, seg[1]:Distance( seg[2] ) / 25, Color( 0, 0, 255 ) )
		end

	end

end )



function EFFECT:Init( data )

	local start = data:GetStart()

	local flags = data:GetFlags()

	local ent = data:GetEntity()

	local att = data:GetAttachment()



	self.StartPos = GetTracerOrigin(start,flags,ent,att);

	self.EndPos = data:GetOrigin();



	self.Entity:SetRenderBoundsWS( self.StartPos, self.EndPos );



	local diff = ( self.EndPos - self.StartPos );

	

	self.Normal = diff:GetNormal();

	self.StartTime = 0;

	--self.LifeTime = ( diff:Length() + self.Length ) / self.Speed;



	table.insert( segments, {

		segs = GenerateLightingSegs( self.StartPos, self.EndPos, math.random( 2, 5 ), self.StartPos:Distance( self.EndPos ) / 24, ent ), --math.random( 5, 10 ) ),

		mat = table.Random( mats ),

		time = CurTime() + tiem,

		w = math.random( 20, 50 ),

		startpos = self.StartPos,

		endpos = self.EndPos

	} )

	if ( math.random( 0, 100 ) > 90 ) then
		vPoint = self.EndPos
		local effectdata = EffectData()
		effectdata:SetOrigin( vPoint )
		effectdata:SetAngles(ent:GetAngles())
		effectdata:SetScale(1)
		effectdata:SetRadius(10)
		effectdata:SetMagnitude(0.1)
		util.Effect( "Sparks", effectdata )
		effectdata:SetMagnitude(1)
		util.Effect( "TeslaHitBoxes", effectdata )
	end

	for i = 1, self.StartPos:Distance( self.EndPos ) / 24 do
		segStartTimes[i] = CurTime() + ((i - 1) * tiem)
	end

end





function EFFECT:Think()

	return false

end





function EFFECT:Render()

end

