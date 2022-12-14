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
--SWEP.ViewModelFOV = 90
SWEP.ViewModelFlip = false
SWEP.UseHands = true
SWEP.ViewModel = Model( "models/weapons/c_lightning_hands.mdl" )
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true

sound.Add( {
	name = "lighting_intro",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 100,
	pitch = 100,
	sound = "weapons/force-lightning/frc_lightning_once_L2_03.wav"
} )

sound.Add( {
	name = "lighting_loop_first",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 100,
	pitch = 100,
	sound = "weapons/force-lightning/frc_lightning_lp_fadein_L3_05.wav"
} )

sound.Add( {
	name = "lighting_loop",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 100,
	pitch = 100,
	sound = "weapons/force-lightning/frc_lightning_lp_L3_05.wav"
} )

sound.Add( {
	name = "lighting_outro",
	channel = CHAN_AUTO,
	volume = 1.0,
	level = 100,
	pitch = 100,
	sound = "weapons/force-lightning/frc_lightning_end_L3_05.wav"
} )

function SWEP:SetupDataTables()

	self:NetworkVar( "Float", 0, "NextIdle" )

end

function SWEP:Reload()
end

function SWEP:Initialize()

	self:SetWeaponHoldType( "fist" )
	self:SetNextIdle( 0 )
	self.BaseClass.Initialize(self)

end

function SWEP:Deploy()

	local speed = GetConVarNumber( "sv_defaultdeployspeed" )

	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "fists_draw" ) )
	vm:SetPlaybackRate( speed )
	
	return true
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
		if tr.Entity == game.GetWorld() then continue end
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

local delay = 0.1
local nextOccurance = 0
local targetedEntity
-- local smokeParticles
game.AddParticles( "particles/fire_01.pcf" )
PrecacheParticleSystem( "smoke_gib_01" )

local heldTime = 0
local loopingSound

local startAngle = Angle(0, 0, 0)
local endAngle = Angle(0, 0, 0)
local tableStartBones = {}
local tableEndBones = {}

function SWEP:UpdateNextIdle()

	local vm = self.Owner:GetViewModel()
	self:SetNextIdle( CurTime() + vm:SequenceDuration() / vm:GetPlaybackRate() )

end

function SWEP:Think()

	local vm = self.Owner:GetViewModel()
	local curtime = CurTime()
	local idletime = self:GetNextIdle()

	if ( idletime > 0 && CurTime() > idletime ) then

		vm:SendViewModelMatchingSequence( vm:LookupSequence( "fists_idle_0" .. math.random( 1, 2 ) ) )

		self:UpdateNextIdle()

	end
	
	if SERVER then
		if self.Owner:KeyDown(IN_ATTACK) then
			if ( CurTime() < self:GetNextPrimaryFire() ) then return end
			local targ,tab = self:SelectTargets(1,dist)
			for k,v in pairs(targ) do
				if tab[v].dot < 0.8 then continue end

				if targetedEntity != v then
					targetedEntity = v
					v.startHeight = targetedEntity:GetPos().z
					tableStartBones = {}
				end
	
				local dmg = DamageInfo()
				dmg:SetAttacker( self.Owner || self )
				dmg:SetInflictor( self or self.Owner )
				dmg:SetDamage( 0.075 )
				v:TakeDamageInfo( dmg )
	
				local ed1 = EffectData()
				ed1:SetEntity(self)
				ed1:SetAttachment(1)
				ed1:SetStart( vm:GetAttachment(2).Pos  )
				ed1:SetOrigin( v:GetPos() + GetRandomPositionInBox( v:OBBMins(), v:OBBMaxs(), v:GetAngles() ) )
				ed1:SetFlags(0x0002)
				util.Effect( "effect_force_lightning", ed1, true, true )

				-- local ed2 = EffectData()
				-- ed2:SetEntity(self)
				-- ed2:SetAttachment(1)
				-- ed2:SetStart( self.Owner:GetPos() + Vector(50,-50,0) )
				-- ed2:SetOrigin( v:GetPos() + GetRandomPositionInBox( v:OBBMins(), v:OBBMaxs(), v:GetAngles() ) )
				-- ed2:SetFlags(0x0002)
				-- util.Effect( "effect_force_lightning", ed2, true, true )	


				local timeLeft = nextOccurance - CurTime()

				v.isLightningTarget = true
				if v:IsNPC() then
					v:StopMoving()
					v:SetNPCState(NPC_STATE_PLAYDEAD)
				end

				v:PointAtEntity(self.Owner)
				v:SetGravity(0.00001)
				if v:GetPos().z < v.startHeight + 100 then
					-- print(v:GetVelocity().z)
					-- if v:GetVelocity().z < 1 then

					-- v:SetPos(Vector(v:GetPos().x, v:GetPos().y, v:GetPos().z + 2))
						v:SetLocalVelocity(Vector(0, 0, (v.startHeight + 100 - v:GetPos().z)))
						-- v:SetLocalVelocity(Vector(0, 0, (v.startHeight + 100 - v:GetPos().z)))
					-- end
					if IsValid(v:GetPhysicsObject()) then
						v:GetPhysicsObject():SetVelocity(Vector(0, 0, (v.startHeight + 100 - v:GetPos().z)))
					end
				end

				-- if v.hasSmokeParticles != true then
				-- 	-- v:CreateParticleEffect("smoke_medium_02c", 0 {["entity"] = self, ["attachtype"]= PATTACH_ABSORIGIN_FOLLOW})
				-- 	v:CreateParticleEffect("smoke_medium_02c", 0)
				-- 	-- CreateParticleSystem( v, "smoke_medium_02c", PATTACH_ABSORIGIN_FOLLOW)
				-- 	v.hasSmokeParticles = true
				-- end

				if timeLeft < 0 then 
					nextOccurance = CurTime() + delay
					for i = 1, v:GetBoneCount() do
						if tableStartBones[i] == nil then
							tableStartBones[i] = Angle(0, 0, 0)
						else
							tableStartBones[i] = tableEndBones[i]
						end
						tableEndBones[i] = AngleRand(-30, 30)
						-- startAngle = endAngle
						-- endAngle = AngleRand(-30, 30)
					end
				end

				-- print(1 - math.abs(CurTime() - nextOccurance) * (1 / delay))
				if v:IsNPC() then
					for i = 1, v:GetBoneCount() do
						-- startAngle = v:GetManipulateBoneAngles(i)
						if tableStartBones[i] == nil then
							tableStartBones[i] = Angle(0, 0, 0)
						end
						if tableEndBones[i] == nil then
							tableStartBones[i] = AngleRand(-30, 30)
						end
						v:ManipulateBoneAngles( i,  LerpAngle( 1 - math.abs(CurTime() - nextOccurance) * (1 / delay), tableStartBones[i], tableEndBones[i] ) )
					end
				end
				timer.Simple( 1, function()
					if v:IsValid() then
						if v.isLightningTarget == true then
							v.isLightningTarget = false
							if v:IsNPC() then
								v:SetNPCState(NPC_STATE_IDLE) 
							end
							v:SetGravity(1)
							v:PhysWake()
						end
					end
				end )
				timer.Simple( 3.5, function()
					if v:IsValid() then
						if v.isLightningTarget == false then 
							if v:IsNPC() then
								if v:GetNPCState() == NPC_STATE_IDLE then
									for i = 1, v:GetBoneCount() do
										v:ManipulateBoneAngles( i,  AngleRand( 0, 0) )
										tableStartBones = {}
									end
								end
							end
							v:SetGravity(1)
							v:PhysWake()
							v:SetAngles(Angle(0, v:GetAngles().y, 0))
						end
					end
				end )
			end
			self:SetNextPrimaryFire( CurTime() + 0.001 )
		end
	end
	if CLIENT then
		if self.Owner:KeyDown(IN_ATTACK) then
			if ( CurTime() < self:GetNextPrimaryFire() ) then return end
			local targ,tab = self:SelectTargets(1,dist)
			vm:SendViewModelMatchingSequence( vm:LookupSequence( "lighting_start" ) )
			-- print(heldTime)
			if table.IsEmpty(tab) or table.GetFirstValue(tab).dot < 0.8 then
				-- print("cring")
				if heldTime > 30 then
					self:StopSound("lighting_loop_first")
				end
				if heldTime > 250 then
					self:StopLoopingSound(loopingSound)
				end
				if heldTime > 30 then
					self:EmitSound("lighting_outro")
					-- print("played outro")
				end
				heldTime = 0
			end
			for k,v in pairs(targ) do
				if tab[v].dot < 0.8 then continue end
				heldTime = heldTime + 1
				if heldTime == 1 then
					self:EmitSound("lighting_intro")
				end
				if heldTime == 30 then
					self:EmitSound("lighting_loop_first")
				end
				if heldTime == 250 then
					loopingSound = self:StartLoopingSound("weapons/force-lightning/frc_lightning_lp_L3_05.wav")
				end
				if v.hasSmokeParticles != true then
					v.smokeParticles = v:CreateParticleEffect("smoke_gib_01", 6, {{["entity"] = self, ["attachtype"]= PATTACH_ABSORIGIN_FOLLOW}})
					-- print("i added more particles :)")
					-- v:CreateParticleEffect("smoke_medium_02c", 0)
					-- smokeParticles = CreateParticleSystem( v, "smoke_burning_engine_01", PATTACH_ABSORIGIN_FOLLOW, 4)
					-- CreateParticleSystem( v, "smoke_medium_02c", PATTACH_ABSORIGIN_FOLLOW)
					v.hasSmokeParticles = true
				end
				timer.Simple( 3.5, function()
					-- print("blahahh")
					if v:IsValid() then
						if v.hasSmokeParticles == true then 
							v.hasSmokeParticles = false
							v.smokeParticles:StopEmission(false, false)
							-- print("blahahh")
						end
					end
				end )
			end
		end
		if self.Owner:KeyReleased(IN_ATTACK) then
			if heldTime > 30 then
				self:StopSound("lighting_loop_first")
			end
			if heldTime > 250 then
				self:StopLoopingSound(loopingSound)
			end
			if heldTime > 30 then
				self:EmitSound("lighting_outro")
				-- print("played outro")
			end
			heldTime = 0
		end
	end
end

function SWEP:SecondaryAttack()
	
	local vm = self.Owner:GetViewModel()
	vm:SendViewModelMatchingSequence( vm:LookupSequence( "lighting_start" ) )
	self:SetNextIdle( CurTime() + vm:SequenceDuration() )
	
end

--function SWEP:SecondaryAttack()
--end