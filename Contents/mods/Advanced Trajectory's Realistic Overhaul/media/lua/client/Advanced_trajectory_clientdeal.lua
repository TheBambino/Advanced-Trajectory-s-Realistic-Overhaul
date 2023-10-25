require "Advanced_trajectory_core"

function OldSearchAndDmgClothing(player, shotpart, damage)
    --local sayDamage = getSandboxOptions():getOptionByName("Advanced_trajectory.DebugSayClothingDmg"):getValue()

    local hasBulletProof= false
    local playerWornInv = player:getWornItems();

    -- use this to compare shot part and covered part
    local nameShotPart = BodyPartType.getDisplayName(shotpart)

    -- use this to find coveredPart
    local strShotPart = BodyPartType.ToString(shotpart)

    local shotBulletProofItems = {}
    local shotNormalItems = {}

    for i = 0, playerWornInv:size() - 1 do
        local item = playerWornInv:getItemByIndex(i)

        if item and instanceof(item, "Clothing") then
            local listBloodClothTypes = item:getBloodClothingType()

            -- arraylist of BloodBodyPartTypes
            local listOfCoveredAreas = BloodClothingType.getCoveredParts(listBloodClothTypes)
    
            -- size of list
            local areaCount = BloodClothingType.getCoveredPartCount(listBloodClothTypes)
    
            for i = 0, areaCount-1 do
                -- returns BloodBodyPartType
                local coveredPart = listOfCoveredAreas:get(i)
                local nameCoveredPart = coveredPart:getDisplayName()
    
                if nameCoveredPart == nameShotPart then
                    
                    -- check if has bullet proof armor
                    local bulletDefense = item:getBulletDefense()
                    print("Bullet Defense: ", bulletDefense)
                    if bulletDefense > 0 then
                        hasBulletProof = true
                        table.insert(shotBulletProofItems, item)
                    else
                        table.insert(shotNormalItems, item)
                    end
                end
            end
        end
    end

    print("*********Has Bullet Proof: ", hasBulletProof)
    if hasBulletProof then
        for i = 1, #shotBulletProofItems do
            local item = shotBulletProofItems[i]
            item:setCondition(item:getCondition()-damage)
            print(nameShotPart, " [", item:getName() ,"] clothing damaged.")
        end
    else
        for i = 1, #shotNormalItems do
            local item = shotNormalItems[i]
            item:setCondition(item:getCondition()-damage)
            print(nameShotPart, " [", item:getName() ,"] clothing damaged.")
        end
    end
end



function SearchAndDmgClothing(player, shotpart, damage)
    local hasBulletProof = false
    local playerWornInv = player:getWornItems()

    -- Convert the shotpart to its display name and string representation only once
    local nameShotPart = BodyPartType.getDisplayName(shotpart)
    local strShotPart = BodyPartType.ToString(shotpart)

    local shotBulletProofItems = {}
    local shotNormalItems = {}

    for i = 0, playerWornInv:size() - 1 do
        local item = playerWornInv:getItemByIndex(i)

        if item and instanceof(item, "Clothing") then
            local listBloodClothTypes = item:getBloodClothingType()
            print("listBloodClothTypes: ", listBloodClothTypes)
            local listOfCoveredAreas = BloodClothingType.getCoveredParts(listBloodClothTypes)
            print("listOfCoveredAreas: ", listOfCoveredAreas)
            local areaCount = BloodClothingType.getCoveredPartCount(listBloodClothTypes)
            print("areaCount: ", areaCount)

            for j = 0, areaCount - 1 do
                local coveredPart = listOfCoveredAreas:get(j)
                print("coveredPart: ", coveredPart)
                local nameCoveredPart = coveredPart:getDisplayName()
                print("nameCoveredPart: ", nameCoveredPart)

                if nameCoveredPart == nameShotPart then
                    print(nameCoveredPart , "==" , nameShotPart)
                    local bulletDefense = item:getBulletDefense()
                    print("Bullet Defense: ", bulletDefense)

                    if bulletDefense > 0 then
                        hasBulletProof = true
                        table.insert(shotBulletProofItems, item)
                    else
                        table.insert(shotNormalItems, item)
                    end
                end
            end
        end
    end

    print("*********Has Bullet Proof: ", hasBulletProof)

    local itemsToDamage = hasBulletProof and shotBulletProofItems or shotNormalItems

    for i = 1, #itemsToDamage do
        local item = itemsToDamage[i]
        item:setCondition(item:getCondition() - damage)
        print(nameShotPart, " [", item:getName(), "] clothing damaged.")
    end
end






function NewDamagePlayershot(player, damagepr, firearmdamage)

    print("NewDamagePlayershot - ", "player:", player, " damagepr:", damagepr, " firearmdamage:", firearmdamage)


    local highShot = {
        BodyPartType.Head, BodyPartType.Head,
        BodyPartType.Neck
    }
        
    local midShot = {
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.UpperArm_L, BodyPartType.UpperArm_R,
        BodyPartType.UpperArm_L, BodyPartType.UpperArm_R,
        BodyPartType.ForeArm_L,  BodyPartType.ForeArm_R,
        BodyPartType.Hand_L,     BodyPartType.Hand_R
    }
    
    local lowShot = {
        BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R,
        BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R,
        BodyPartType.LowerLeg_L, BodyPartType.LowerLeg_R,
        BodyPartType.Foot_L,     BodyPartType.Foot_R,
        BodyPartType.Groin
    }

    local shotpart = BodyPartType.Torso_Upper

    local incHeadChance = 0
    if damagepr == Advanced_trajectory.HeadShotDmgPlayerMultiplier then
        print(damagepr , " == " , Advanced_trajectory.HeadShotDmgPlayerMultiplier)
        incHeadChance = 20
    end

    local incFootChance = 0
    if damagepr == Advanced_trajectory.FootShotDmgPlayerMultiplier then
        print(damagepr , " == " , Advanced_trajectory.FootShotDmgPlayerMultiplier)
        incFootChance = 10
    end

    if damagepr > 0 then

        local randNum = ZombRand(100)

        -- lowShot
        if randNum <= (10 + incFootChance) then
            shotpart = lowShot[ZombRand(#lowShot)+1]

        -- highShot
        elseif randNum > (10 + incFootChance) and randNum <= (10 + incFootChance)+10+incHeadChance then
            shotpart = highShot[ZombRand(#highShot) + 1]

        -- midShot
        else
            shotpart = midShot[ZombRand(#midShot) + 1]
        end

    end

    local bodypart = player:getBodyDamage():getBodyPart(shotpart)
    print("bodypart: " , bodypart)

    -- Calculate clothing defense for the shot part

    --Bullet Defense
    local bulletDefense = player:getBodyPartClothingDefense(shotpart:index(), false, true);

    --Scratch Defense
    --local scratchDefense = player:getBodyPartClothingDefense(shotpart:index(), false, false)

    --Bite Defense
    --local biteDefense = player:getBodyPartClothingDefense(shotpart:index(), true, false)

    print("bulletDefense: " .. bulletDefense)
    --print("scratchDefense: " .. scratchDefense)
    --print("biteDefense: " .. biteDefense)

    --local alldefense = (scratchDefense * 0.5 + biteDefense * 0.5) / 150
    --local alldefense = (defense1 + scratchDefense * 0.5 + biteDefense * 0.5) / 150

    local alldefense = bulletDefense

	local originalDamage = firearmdamage
    print("originalDamage: " .. originalDamage)

    local playerDamageDealt = firearmdamage * damagepr
    print("playerDamageDealt: " .. playerDamageDealt)

    --Advanced_trajectory.dmgDealtToPlayer = playerDamageDealt


	--if SandboxVars.ImprovedProjectile.IPPJPVPEnableWound then
		if ZombRand(100) >= alldefense then
			if bodypart:haveBullet() then
				bodypart:generateDeepWound()
			else
				--bodypart:setHaveBullet(true, 3)
                bodypart:setHaveBullet(true, 0)
			end
		end
	--end





    -- bulletdefense is usually 100
    --local defense = player:getBodyPartClothingDefense(shotpart:index(),false,true)
    --print(defense)

    --[[
    if defense < 0.5 then
        print("WOUNDED")
        if bodypart:haveBullet() then
            local deepWound = bodypart:isDeepWounded()
            local deepWoundTime = bodypart:getDeepWoundTime()
            local bleedTime = bodypart:getBleedingTime()
            --bodypart:setHaveBullet(false, 0)
            bodypart:setDeepWoundTime(deepWoundTime)
            bodypart:setDeepWounded(deepWound)
            bodypart:setBleedingTime(bleedTime)
        else
            bodypart:setHaveBullet(true, 0)
        end
    end
    ]]--

    if alldefense > 0.9 then
        alldefense = 0.9
    end
    print("adjusted alldefense: " .. alldefense)
    --firearmdamage = firearmdamage / alldefense



    local hitDamage = playerDamageDealt * 0.6 * (1 - alldefense)
    print("hitDamage: " .. hitDamage)

    --local hitPlayerPart = player:getBodyDamage():getBodyPart(shotpart)

    bodypart:ReduceHealth(hitDamage)
	--local actualDamage = hitDamage * BodyPartType.getDamageModifyer(shotpart:index())


	local stats = player:getStats()
	local pain = math.min(stats:getPain() + player:getBodyDamage():getInitialBitePain() * BodyPartType.getPainModifyer(shotpart:index()), 100)
	stats:setPain(pain)

    player:addBlood(50)


    --player:getBodyDamage():ReduceGeneralHealth(firearmdamage * damagepr * 0.6 * (1 - defense))
    --sendClientCommand("IPPJ", "writePVPLog", {args[1], args[2], BodyPartType.ToString(hitPart), originalDamage, hitDamage, actualDamage, args[5], args[6], player:isDead()})

    local clothingDamage = 1
    SearchAndDmgClothing(player, shotpart, clothingDamage)
end

--getBiteDefenseFromItem
--getScratchDefenseFromItem
--getBiteDefense
--getBulletDefense
--getScratchDefense


--[[
local wornItems = getPlayer():getWornItems()
for i=1,wornItems:size() do
    local item = wornItems:get(i-1):getItem()
    print(item:getClothingItemName())
    print(item:getVisual():getBaseTexture())
    print(item:getVisual():getTextureChoice())
end

]]--


local function Advanced_trajectory_OnServerCommand(module, command, arguments)

    local clientPlayershot = getPlayer()
    if not clientPlayershot then return end

	if module == "ATY_shotplayer" then

        local playershotOnlineID = arguments[1] --Playershot:getOnlineID()
        local damagepr = arguments[2] --damagepr
        local firearmdamage = arguments[3] --firearmdamage

        if playershotOnlineID ~= clientPlayershot:getOnlineID() then return end

        if (getSandboxOptions():getOptionByName("ATY_nonpvp_protect"):getValue() and NonPvpZone.getNonPvpZone(clientPlayershot:getX(), clientPlayershot:getY())) or (getSandboxOptions():getOptionByName("ATY_safezone_protect"):getValue() and SafeHouse.getSafeHouse(clientPlayershot:getCurrentSquare())) then return end
        -- print(NonPvpZone.getNonPvpZone(getPlayer():getX(), getPlayer():getY()))
        -- print(SafeHouse.getSafeHouse(getPlayer():getCurrentSquare()))

        print("*-----------------------------------------------------------------------------*")
        print("damagepr: " .. damagepr)
        clientPlayershot:Say("damagepr: " .. damagepr)

        --local baseGunDmg = baseGun:getDamage()

        print("BEFORE DAMAGE: " , clientPlayershot, damagepr, firearmdamage)
        NewDamagePlayershot(clientPlayershot, damagepr, firearmdamage)
        print("*-----------------------------------------------------------------------------*")
    elseif module == "ATY_shotsfx" then

        local itemobj = arguments[1] --tablez[1] or item obj
        local characterOnlineID = arguments[2] --character:getOnlineID()

        if characterOnlineID == clientPlayershot:getOnlineID() then return end
        table.insert(Advanced_trajectory.table, itemobj)

    elseif module == "ATY_reducehealth" then

        local ExplosionPower = arguments[1] --ExplosionPower

        clientPlayershot:getBodyDamage():ReduceGeneralHealth(ExplosionPower)

    elseif module == "ATY_cshotzombie" then

        local zedOnlineID = arguments[1] --Zombie:getOnlineID()
        local playerOnlineID = arguments[2] --vt[19]:getOnlineID()

        if clientPlayershot:getOnlineID() == playerOnlineID then return end
        local zombies = getCell():getZombieList()

        for i = 1, zombies:size() do

            local zombiez = zombies:get(i - 1)
            if zombiez:getOnlineID() == zedOnlineID then

                -- if not string.find(tostring(zombiez:getCurrentState()), "Climb") and not string.find(tostring(zombiez:getCurrentState()), "Craw") then

                --     zombiez:changeState(ZombieIdleState.instance())

                -- end
                zombiez:setHitReaction("Shot")
            end
        end

    elseif module == "ATY_killzombie" then

        local zedOnlineID = arguments[1] --Zombie:getOnlineID()

        local zombies = getCell():getZombieList()

        for i=1,zombies:size() do

            local zombiez = zombies:get(i - 1)
            if zombiez:getOnlineID() == zedOnlineID then

                zombiez:Kill(zombiez)

            end
        end

    end

end

Events.OnServerCommand.Add(Advanced_trajectory_OnServerCommand)