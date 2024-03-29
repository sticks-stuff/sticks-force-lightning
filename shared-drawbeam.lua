if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
else
	SWEP.PrintName			= "Force Lightning"
	SWEP.Author				= "stick"
	SWEP.Slot				= 2
	SWEP.SlotPos			= 3
end

SWEP.Base					= "weapon_base"
SWEP.Category				= "stick"
SWEP.Spawnable				= true
SWEP.AdminSpawnable			= true
SWEP.FireSound 			    = ""
SWEP.Weight					= 5
SWEP.AutoSwitchTo			= false
SWEP.AutoSwitchFrom			= false
SWEP.Primary.Recoil			= 2.5
SWEP.Primary.Damage			= 200
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0.010
SWEP.Primary.ClipSize		= -1
SWEP.Primary.Delay			= 0.25
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "none"
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo			= "none"
SWEP.Secondary.Delay = .1

SWEP.HoldType = "duel"
SWEP.ViewModelFOV = 90
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true


function SWEP:Reload()
end

function SWEP:SelectTargets( num, dist )

	local t = {}
	dist = dist or 512
	local p = {}

	for id, ply in pairs( ents.GetAll() ) do
		if ( !ply:GetModel() || ply:GetModel() == "" || ply == self.Owner || ply:Health() < 1 ) then continue end
		if ply.PlayerTeam then
			if players_only then continue end 
			if not friends and ply.PlayerTeam == self.Owner:Team() then 
				continue
			elseif friends and ply.PlayerTeam != self.Owner:Team() then 
				continue 
			end
		end

		if ply.Team then
			if not friends and ply:Team() == self.Owner:Team() then
				continue
			elseif friends and ply:Team() != self.Owner:Team() then
				continue 
			end
		end

		if ( string.StartWith( ply:GetModel() || "", "models/gibs/" ) ) then continue end
		if ( string.find( ply:GetModel() || "", "chunk" ) ) then continue end
		if ( string.find( ply:GetModel() || "", "_shard" ) ) then continue end
		if ( string.find( ply:GetModel() || "", "_splinters" ) ) then continue end

		local tr = util.TraceLine( {
			start = self.Owner:GetShootPos(),
			endpos = (ply.GetShootPos && ply:GetShootPos() || ply:GetPos()),
			filter = function(ent) return ent == ply or not ent.Nick end
		} )
		if not IsValid( tr.Entity ) or tr.Entity != ply or tr.Entity == game.GetWorld() then continue end
		local spos = self.Owner:GetShootPos()
		local pos1 = self.Owner:GetPos() + self.Owner:GetAimVector() * dist
		local pos2 = tr.HitPos
		local dot = self.Owner:GetAimVector():Dot( ( pos2 - self.Owner:GetShootPos() ):GetNormalized() )
		local dist2 = spos:Distance( pos2 )
		if ( dist2 <= dist && ply:EntIndex() > 0 && ply:GetModel() && ply:GetModel() != "" ) then
			table.insert( p, { ply = ply, dist = dist2, dot = dot, score = dot + ( ( dist - dist2 ) / dist ) * 50 } )
		end
	end

	local d = {}

	for id, ply in SortedPairsByMemberValue( p, "dist" ) do
		table.insert( t, ply.ply )
		d[ply.ply] = ply
		if ( #t >= num ) then break end
	end
	local f = {}
	for i = 1,num do
		f[i] = t[i]
	end
	return f,d
end

local dist = 800

local function GetRandomPositionInBox( mins, maxs, ang )

	return ang:Up() * math.random( mins.z, maxs.z ) + ang:Right() * math.random( mins.y, maxs.y ) + ang:Forward() * math.random( mins.x, maxs.x )

end


function SWEP:Think()
	if self.Owner:KeyDown(IN_ATTACK) then
		if SERVER then
			if ( CurTime() < self:GetNextPrimaryFire() ) then return end
			local targ,tab = self:SelectTargets(1,dist)
			for k,v in pairs(targ) do
				if tab[v].dot < 0.8 then continue end
	
				-- local dmg = DamageInfo()
				-- dmg:SetAttacker( self.Owner || self )
				-- dmg:SetInflictor( self or self.Owner )
				-- dmg:SetDamage( FrameTime() * 1333 )
				-- v:TakeDamageInfo( dmg )
	
				-- local ed = EffectData()
				-- ed:SetEntity(self)
				-- ed:SetAttachment(1)
				-- ed:SetStart( self.Owner:GetPos() + Vector(0,0,30) )
				-- ed:SetOrigin( v:GetPos() + GetRandomPositionInBox( v:OBBMins(), v:OBBMaxs(), v:GetAngles() ) )
				-- ed:SetFlags(0x0002)
				-- util.Effect( "effect_force_lightning", ed, true, true )	
			end
			self:SetNextPrimaryFire( CurTime() + 0.001 )
		end
	end
end

function SWEP:SecondaryAttack()
end

function SWEP:Initialize()
	self.BaseClass.Initialize(self)
end