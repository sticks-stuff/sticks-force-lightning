AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include('shared.lua')

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

local heldTime = 0
local loopingSound

-- function SWEP:Think()
-- 	if self.Owner:KeyDown(IN_ATTACK) then
-- 		heldTime = heldTime + 1
-- 		print(heldTime)
-- 		self:EmitSound("lighting_intro")
-- 		if heldTime == 30 then
-- 			self:EmitSound("lighting_intro")
-- 		end
-- 		if heldTime == 250 then
-- 			loopingSound = self:StartLoopingSound("weapons/force-lightning/frc_lightning_lp_L3_05.wav")
-- 		end
-- 	end

-- 	if self.Owner:KeyReleased(IN_ATTACK) then
-- 		if heldTime > 30 then
-- 			self:EmitSound("lighting_outro")
-- 		end
-- 		heldTime = 0
-- 	end
-- end

