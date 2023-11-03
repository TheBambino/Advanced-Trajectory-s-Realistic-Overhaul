require "Advanced_trajectory_core"
Advanced_trajectory.fieldnum = nil


-- local function OnSave()
-- 	-- Your code here
-- end

-- Events.OnSave.Add(OnSave)

-- function Advanced_trajectory.getJavaFieldNum(object, fieldName)
--     for i = 0, getNumClassFields(object) - 1 do
--         local javaField = getClassField(object, i)
--         if luautils.stringEnds(tostring(javaField), '.' .. fieldName) then
--             return i
--         end
--     end
-- end

-- function Advanced_trajectory.initweapon()
--     local allweapon = ScriptManager.instance:getAllItems()
--     for i = 1,allweapon:size() do
--         local item= allweapon:get(i-1)
--         if Advanced_trajectory.fieldnum == nil  then
--             Advanced_trajectory.fieldnum = Advanced_trajectory.getJavaFieldNum(item, "SubCategory")
--         end

--         if getClassFieldVal(item, getClassField(item, Advanced_trajectory.fieldnum)) == "Firearm" then
--             -- item:DoParam("MaxRange = " .. "-100")
--             item:DoParam("MaxHitCount = " .. "0")
--         end
--     end
-- end


-- Events.OnGameBoot.Add(Advanced_trajectory.initweapon)

--getPlayer():getBodyDamage():setOverallBodyHealth(0.3)
-- getPlayer():getBodyDamage():ReduceGeneralHealth(19)

-- local BuddyDesc = ;

-- asdasd = IsoPlayer.new(getWorld():getCell(),SurvivorFactory.CreateSurvivor(),getPlayer():getCurrentSquare():getX(),getPlayer():getCurrentSquare():getY(),getPlayer():getCurrentSquare():getZ());
-- asdasd:setNPC(true);
-- asdasd:setBlockMovement(true);
-- asdasd:setSceneCulled(false)
-- asdasd:getBodyDamage():ReduceGeneralHealth(30)

-- instanceof(asdasd,"IsoPlayer")


-- [h1]Advanced trajectory[/h1] 

-- [b]This Mod modifies the ranged weapons and throwed weapons.[/b]

-- [b]Ranged weapon:[/b]
-- 1.You can see the trajectory of bullets.
-- 2.You can shoot the head, body and feet of zombies through the crosshair. (It is not perfect yet)
-- 3.Your aiming skill level and gun aimtime determine the action of the crosshair.You need to stay still to concentrated crosshair,and then hit the zombies.

-- [b]Throwed weapons:[/b]
-- 1.The function of the throwed weapon is related to the script. For example, if the throwed weapon can burn, it will generate fire. If the throwed weapon can explode, it can cause explosive damage. If the explosion damage reaches a certain limit (100), the tiles will be damaged.
-- 2.Like then ranged weapon, it needs to aim the ground or zombie and then throw.

-- [h1]There are some sandbox options to modify specific values.[/h1] 
-- [b]1.Enable The Aimpoint :[/b] Enable or disable the crosshair.
-- [b]2.Recoil Force :[/b] How much the size of the crosshair is increased for each shot.
-- [b]3.Initial Offset :[/b] Size of initial crosshair.
-- [b]4.Moving Effect :[/b] Moving will increase the size of crosshair.This can adjust the effect of movement.
-- [b]5.Turning Effect :[/b] Turning will increase the size of crosshair.This can adjust the effect of turning.
-- [b]6.Ballistic Concentrated Speed :[/b] The base speed at which the crosshair diminishes.
-- [b]7.Ballistic Speed :[/b] The speed ratio of a bullet or throwed weapon.Do not set too high, which will reduce the accuracy,For example. For example, there will be a problem that zombies cannot be shotted unless your computer is good enough.
-- [b]8.Ballistic Distance :[/b] Basic attack range ratio of your weapon.
-- [b]9.Shotgun Projectile Count :[/b] Raise it, more bullets will be shotted from the shotgun.
-- [b]10.Report Attacking Part :[/b] When you shotted a zombie, he will tell you where you shotted.
-- [b]11.Enable Ranged Weapon :[/b] If you want to use the original ranged weapon function, you can turn it off.
-- [b]12.Enable Throwed Weapon :[/b] If you want to use the original throwed weapon function, you can turn it off.
-- [b]13.Enable Damage To Player :[/b] When enabled, explosions and bullets will cause damage to players or NPCs.
-- [b]14.Shotgun Splitting Angle :[/b] Raise it, the bullets of shotgun will disperse more.

-- Addition: As higher the speed of the target, as more difficult it is to hit small parts of the target's body

-- Uroris 7 分钟以前 
-- Suggestion: if you aim at a zombie or a player and want to shoot, the bullet will hit the largest part of the target and the higher level of accuracy, the more vital parts of the body will be affected






-- Workshop ID: 2895102994
-- Mod ID: Advanced_trajectory