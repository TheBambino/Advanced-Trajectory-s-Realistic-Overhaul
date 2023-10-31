require "Advanced_trajectory_core"

-------------------------------------------------
--DAMAGE CLOTHING COVERING THE SHOT BODY PART--
--------------------------------------------------
function searchAndDmgClothing(playerShot, shotpart)

    local hasBulletProof= false
    local playerWornInv = playerShot:getWornItems();

    -- use this to compare shot part and covered part
    local nameShotPart = BodyPartType.getDisplayName(shotpart)

    -- use this to find coveredPart
    local strShotPart = BodyPartType.ToString(shotpart)

    local shotBloodPart = nil

    local shotBulletProofItems = {}
    local shotNormalItems = {}

    for i=0, playerWornInv:size()-1 do
        local item = playerWornInv:getItemByIndex(i);

        if item and instanceof(item, "Clothing") then
            local listBloodClothTypes = item:getBloodClothingType()

            -- arraylist of BloodBodyPartTypes
            local listOfCoveredAreas = BloodClothingType.getCoveredParts(listBloodClothTypes)   
    
            -- size of list
            local areaCount = BloodClothingType.getCoveredPartCount(listBloodClothTypes)   
    
            for i=0, areaCount-1 do
                -- returns BloodBodyPartType
                local coveredPart = listOfCoveredAreas:get(i)
                local nameCoveredPart = coveredPart:getDisplayName()
    
                if nameCoveredPart == nameShotPart then
                    shotBloodPart = coveredPart
                    
                    -- check if has bullet proof armor
                    local bulletDefense = item:getBulletDefense()
                    --print("Bullet Defense: ", bulletDefense)
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

    --print("HAS BULLET PROOF: ", hasBulletProof)
    if hasBulletProof then
        for i = 1, #shotBulletProofItems do
            local item = shotBulletProofItems[i]

            -- Minimum reduction value is 1 due to integer type
            item:setCondition(item:getCondition() - 1)          

            print(item:getName(), "'s MaxCondition / Curr: ", item:getConditionMax(), " / ", item:getCondition())
        end
    else
        for i = 1, #shotNormalItems do
            local item = shotNormalItems[i]

            -- hole is added only if the shot part initially had no hole. added hole means damage to clothing
            -- decided to add holes only so players can still wear their battlescarred clothing
            if item:getHolesNumber() < item:getNbrOfCoveredParts() then
                playerShot:addHole(shotBloodPart, true)
            end

            print(item:getName(), "'s MaxCondition / Curr: ", item:getConditionMax(), " / ", item:getCondition())
            --print(nameShotPart, " [", item:getName() ,"] clothing damaged.")
        end
    end

    if getSandboxOptions():getOptionByName("Advanced_trajectory.DebugSayShotPart"):getValue() then
        playerShot:Say("Ow! My " .. nameShotPart .. "!")
    end
end

-------------------------------
--DAMAGE PLAYER THAT WAS SHOT--
--------------------------------
function damagePlayershotPVP(player, playerShot, damage, baseGunDmg, headShotDmg, bodyShotDmg, footShotDmg)

    print("DamagePlayershotPVP - ", "playerShot:", playerShot, " damagepr:", damage, " firearmdamage:", baseGunDmg)

    local highShot = {
        BodyPartType.Head, BodyPartType.Head,
        BodyPartType.Neck
    }
        
    -- chest is biggest target so increase its chances of being wounded; will make vest armor useful
    local midShot = {
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
        BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
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

    local footChance = 5
    local headChance = 10

    local incHeadChance = 0
    if damage == headShotDmg then
        incHeadChance = getSandboxOptions():getOptionByName("Advanced_trajectory.headShotIncChance"):getValue()
    end

    local incFootChance = 0
    if damage == footShotDmg then
        incFootChance = getSandboxOptions():getOptionByName("Advanced_trajectory.footShotIncChance"):getValue()
    end

    if damage > 0 then

        local randNum = ZombRand(100)

        -- lowShot
        if randNum <= (footChance + incFootChance) then                   
            shotpart = lowShot[ZombRand(#lowShot) + 1]
        
        -- highShot
        elseif randNum > (footChance + incFootChance) and randNum <= (footChance + incFootChance) + (headChance + incHeadChance) then
            shotpart = highShot[ZombRand(#highShot)+1]
        
        -- midShot
        else
            shotpart = midShot[ZombRand(#midShot)+1]
        end

    end

    print("DmgMult / BaseDmg: ", damage, " / ", baseGunDmg)
    searchAndDmgClothing(playerShot, shotpart)
    
    local bodypart = playerShot:getBodyDamage():getBodyPart(shotpart)
    local nameShotPart = BodyPartType.getDisplayName(shotpart)

    -- float (part, isBite, isBullet)
    -- bulletdefense is usually 100
    local defense = playerShot:getBodyPartClothingDefense(shotpart:index(),false,true)

    --print("BodyPartClothingDefense: ", defense)

    if defense < 0.5 then
        --print("WOUNDED")
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

        -- Destroy bandage if bandaged
        if bodypart:bandaged() then
            bodypart:setBandaged(false, 0)
        end
    end

    local maxDefense = getSandboxOptions():getOptionByName("Advanced_trajectory.maxDefenseReduction"):getValue()
    if defense > maxDefense then
        defense = maxDefense
    end

    local playerDamageDealt = baseGunDmg * damage * (1 - defense)

    playerShot:getBodyDamage():ReduceGeneralHealth(playerDamageDealt)

    local stats = playerShot:getStats()
	local pain = math.min(stats:getPain() + playerShot:getBodyDamage():getInitialBitePain() * BodyPartType.getPainModifyer(shotpart:index()), 100)
	stats:setPain(pain)

    --playerShot:updateMovementRates()
    --playerShot:getBodyDamage():Update()

    playerShot:addBlood(50)

    local isDead = playerShot:isDead()

    Advanced_trajectory.writePVPLog({player, playerShot, nameShotPart, damage, baseGunDmg, playerDamageDealt, isDead})   
end

----------------------
--CREDITS TO LISOLA--
----------------------
function Advanced_trajectory.writePVPLog(arguments)    
    local shooter                   = arguments[1]
    local target                    = arguments[2]
    local strShotPart               = arguments[3]   
    local damagepr                  = arguments[4]                 
    local baseGunDmg                = arguments[5]     
    local damageDealtToTarget       = arguments[6]     
    local targetIsDead              = arguments[7]   

	local log1 = string.format(("[ATROPVP] \"%s\" shot \"%s\" (PartShot: \"%s\" || HitDmg: \"%s\" || BaseGunDmg: \"%s\"  || ActDmg: \"%s\")"), shooter:getUsername(), target:getUsername(), strShotPart, damagepr, baseGunDmg, damageDealtToTarget)
	writeLog("ATROPVP", log1)

	if targetIsDead == true then
		local killLog = string.format(("[ATROPVP] \"%s\" was killed by \"%s\""), target:getUsername(), shooter:getUsername())
		writeLog("ATROPVP", killLog)
	end
end



local function Advanced_trajectory_OnServerCommand(module, command, arguments)

    local clientPlayershot = getPlayer()
    if not clientPlayershot then return end


    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- sendClientCommand("ATY_shotplayer", "true", {vt[19]:getOnlineID(), Playershot:getOnlineID(), damagepr, vt[6], Advanced_trajectory.HeadShotDmgPlayerMultiplier, Advanced_trajectory.BodyShotDmgPlayerMultiplier, Advanced_trajectory.FootShotDmgPlayerMultiplier})--
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	if module == "ATY_shotplayer" then

        local playerOnlineID        = arguments[1]  
        local playershotOnlineID    = arguments[2]         
        local damagepr              = arguments[3]                 
        local baseGunDmg            = arguments[4]               
        local headShotDmgMultiplier = arguments[5]
        local bodyShotDmgMultiplier = arguments[6]
        local footShotDmgMultiplier = arguments[7]

        local player     = getPlayerByOnlineID(playerOnlineID)
        local playershot = getPlayerByOnlineID(playershotOnlineID)

        --print(player:getUsername(), " -> ", playershot:getUsername())

        if playershotOnlineID ~= clientPlayershot:getOnlineID() then return end

        if (getSandboxOptions():getOptionByName("ATY_nonpvp_protect"):getValue() and NonPvpZone.getNonPvpZone(clientPlayershot:getX(), clientPlayershot:getY())) or (getSandboxOptions():getOptionByName("ATY_safezone_protect"):getValue() and SafeHouse.getSafeHouse(clientPlayershot:getCurrentSquare())) then return end
        -- print(NonPvpZone.getNonPvpZone(getPlayer():getX(), getPlayer():getY()))
        -- print(SafeHouse.getSafeHouse(getPlayer():getCurrentSquare()))

        --print("*-----------------------------------------------------------------------------*")
        --print("damagepr: " .. damagepr)
        clientPlayershot:Say("damagepr: " .. damagepr)

        --print("BEFORE DAMAGE: " , clientPlayershot, damagepr, baseGunDmg)

        --damagePlayershotPVP(player, playerShot, damage, baseGunDmg, headShotDmg, bodyShotDmg, footShotDmg)
        damagePlayershotPVP(player, playershot, damagepr, baseGunDmg, headShotDmgMultiplier, bodyShotDmgMultiplier, footShotDmgMultiplier)   --ERROR
        --print("*-----------------------------------------------------------------------------*")
    


    ----------------------------------------------------------------------------
    --sendClientCommand("ATY_shotsfx", "true", {tablez, character:getOnlineID()})--
    ----------------------------------------------------------------------------
    elseif module == "ATY_shotsfx" then

        local itemobj = arguments[1]            --tablez[1] or item obj
        local characterOnlineID = arguments[2]  --character:getOnlineID()

        if characterOnlineID == clientPlayershot:getOnlineID() then return end
        table.insert(Advanced_trajectory.table, itemobj)



    -----------------------------------
    -- Can't find module in core file--
    -----------------------------------
    elseif module == "ATY_reducehealth" then

        local ExplosionPower = arguments[1]     --ExplosionPower

        clientPlayershot:getBodyDamage():ReduceGeneralHealth(ExplosionPower)



    -------------------------------------------------------------------------------------------
    --sendClientCommand("ATY_cshotzombie", "true", {Zombie:getOnlineID(),vt[19]:getOnlineID()})--
    -------------------------------------------------------------------------------------------
    elseif module == "ATY_cshotzombie" then

        local zedOnlineID = arguments[1]        --Zombie:getOnlineID()
        local playerOnlineID = arguments[2]     --vt[19]:getOnlineID()

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


        
    -------------------------------------------------------------------
    --sendClientCommand("ATY_killzombie", "true", {Zombie:getOnlineID()})--
    --------------------------------------------------------------------
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