require "Advanced_trajectory_core"

-- Define the body part arrays
local highShot = {
    BodyPartType.Head, BodyPartType.Head,
    BodyPartType.Neck
}

local midShot = {
    BodyPartType.Torso_Upper, BodyPartType.Torso_Lower,
    BodyPartType.UpperArm_L, BodyPartType.UpperArm_R,
    BodyPartType.UpperArm_L, BodyPartType.UpperArm_R,
    BodyPartType.ForeArm_L, BodyPartType.ForeArm_R,
    BodyPartType.Hand_L, BodyPartType.Hand_R
}

local lowShot = {
    BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R,
    BodyPartType.UpperLeg_L, BodyPartType.UpperLeg_R,
    BodyPartType.LowerLeg_L, BodyPartType.LowerLeg_R,
    BodyPartType.Foot_L, BodyPartType.Foot_R,
    BodyPartType.Groin
}

--[[
local function getPlayerBodyParts(player)
    -- Keys:[Hand_L, Hand_R, ForeArm_L, ForeArm_R, UpperArm_L, UpperArm_R, Torso_Upper, Torso_Lower, Head, Neck, Groin, UpperLeg_L, UpperLeg_R, LowerLeg_L, LowerLeg_R, Foot_L, Foot_R, Back, MAX]
    -- Returns: zombie.characters.BodyDamage.BodyPart
    local bloodBodyPartType = {}

    local bodyDamage = player:getBodyDamage()
    local bodyParts = bodyDamage:getBodyParts()
    for i = 0, bodyParts:size() - 1 do
        bloodBodyPartType[tostring(bodyParts:get(i):getType())] = bodyParts:get(i)
		print("bloodBodyPartType" , bodyParts:get(i):getDisplayName())
    end

    return bloodBodyPartType
end
]]--

function RevDamagePlayershot(attacker, target, damagepr, damagemod, firearm, aimnum)
    print("RevDamagePlayershot - attacker:", attacker, "target:", target, " damagepr:", damagepr, " damagemod:", damagemod, " firearm:", firearm)
    if attacker == nil or target == nil then
        return
    end
	if firearm ~= nil then
		print("firearm: " , firearm:getDisplayName())
	end

    local canCauseHole = true

	--local incHeadChance, incFootChance = Advanced_trajectory.calculateAdditionalChances(damagepr)
	if damagepr > 0 then

        local incHeadChance, incFootChance = Advanced_trajectory.calculateAdditionalChances(damagepr)

		local shotpart = Advanced_trajectory.determineShotPart(incFootChance, incHeadChance)

        local dist = Advanced_trajectory.calculateDistance(attacker, target)
        print("dist: " .. dist)
        local dist2 = attacker:DistToProper(target)
        print("dist2: " .. dist2)

		local bodypart = target:getBodyDamage():getBodyPart(shotpart)
		print("bodypart: ", bodypart)
		local bodyPartIndex = bodypart:getIndex()

        print("attacker, target, firearm, dist: " , attacker, "-", target, "-", firearm, "-", dist)
        local canEvade = Advanced_trajectory.canEvade(attacker, target, firearm, dist, bodypart, aimnum)
        print("canEvade: " .. tostring(canEvade))

        if canEvade == true then
            print("YOU HAVE EVADED THE ATTACK!!!!")
             return
        end

		-- Calculate clothing defense for the shot part
		local bulletDefense = target:getBodyPartClothingDefense(shotpart:index(), false, true)
		print("bulletDefense: " .. bulletDefense)
		bulletDefense = tonumber(bulletDefense)



		-- Check if the clothing defense prevents damage causing a hole? Or is it no hole at all
        local randBulletPower = ZombRand(0, 100)
        local randBulletChance = ZombRand(0, 100)
        print("FIRST CHECK: " .. randBulletPower .. " < " .. bulletDefense .. " and " .. randBulletChance .. " < 50")
        if randBulletPower < bulletDefense and randBulletChance < 50 then
			print("addHoleFromZombieAttacks - FIRST CHECK")
			attacker:Say("FIRST CHECK")
            canCauseHole = false
			target:addHoleFromZombieAttacks(BloodBodyPartType.FromIndex(bodyPartIndex), false);
			--target:addHoleFromZombieAttacks(getBloodBodyPartTypes():FromIndex(bodyPartIndex), false)
        end

		if canCauseHole == true then
			--local ebodyPart = getPlayerBodyParts(target)
			--print("ebodyPart" , ebodyPart)
			print("addHole - SECOND CHECK")
			target:Say("SECOND CHECK")
			-- Add a hole to the character's clothing
			target:addHole(BloodBodyPartType.FromIndex(bodyPartIndex));
			target:splatBloodFloorBig();
			target:splatBloodFloorBig();
			target:splatBloodFloorBig();

			-- Calculate the damage inflicted by the bullet
			--local damage = ZombRandFloat(firearm:getMinDamage(), firearm:getMaxDamage()) * 15.0

			attacker:setVariable("TargetDist", Advanced_trajectory.calculateDistance(attacker, target))

			Advanced_trajectory.setAttackVariation(attacker)
			--Advanced_trajectory.setFireMode(attacker, firearm)

            --attacker:setAttackFromBehind(attacker:isBehind(target))
            attacker:setAttackFromBehind(target:isBehind(attacker))
            local isBackAttack = attacker:isAttackFromBehind()

            local initialTargetCharacter = false
			if Advanced_trajectory.initialZomOrChar == target then
				initialTargetCharacter = true
			end

			local critChance = Advanced_trajectory.calculateCritChance(attacker, target, firearm)
            print("critChance: " .. critChance)
			local isCriticalHit = false
			if ZombRandFloat(0, 100) < critChance then
				isCriticalHit = true
			end


			Advanced_trajectory.handleHitReaction(attacker, target)

			if initialTargetCharacter == true and (isCriticalHit or isBackAttack) then
				Advanced_trajectory.handleCriticalHit(attacker, target, critChance)
				Advanced_trajectory.adjustCriticalHitRecoilDelay(attacker, firearm)

			else
                Advanced_trajectory.calculateRecoilDelay(attacker, firearm)
			end

			if not isServer() then
				Advanced_trajectory.handleNonServerSideEffects(attacker, target)
			end

			Advanced_trajectory.printDebugInfo(attacker, damagepr, damagemod)

			Advanced_trajectory.handleBodyDamage(attacker, target, damagepr, firearm, shotpart, damagemod, isCriticalHit, critChance, bodypart, bodyPartIndex, bulletDefense)
		end
	end
end


function Advanced_trajectory.determineShotPart(incFootChance, incHeadChance)
    local randNum = ZombRand(100)
    local shotpart

    if randNum <= (10 + incFootChance) then
        shotpart = lowShot[ZombRand(#lowShot) + 1]
    elseif randNum <= (10 + incFootChance) + 10 + incHeadChance then
        shotpart = highShot[ZombRand(#highShot) + 1]
    else
        shotpart = midShot[ZombRand(#midShot) + 1]
    end

    return shotpart
end

function Advanced_trajectory.calculateCritChance(attacker, target, firearm)
    local critChance = 0

	critChance = firearm:getCriticalChance()
    print("critChance: " .. critChance)

	--critChance = critChance + firearm:getAimingPerkCritModifier() * (attacker:getPerkLevel(Perks.Aiming) / 2.0)
    critChance = firearm:getAimingPerkCritModifier() + (attacker:getPerkLevel(Perks.Aiming) / 2.0)
    print("firearm:getAimingPerkCritModifier(): " , firearm:getAimingPerkCritModifier())
    print("attacker:getPerkLevel(Perks.Aiming): " , attacker:getPerkLevel(Perks.Aiming))    
    print("critChance + firearm:getAimingPerkCritModifier() * (attacker:getPerkLevel(Perks.Aiming) / 2.0): " .. critChance)


	if attacker:getBeenMovingFor() > firearm:getAimingTime() + attacker:getPerkLevel(Perks.Aiming) * 2 then
		critChance = critChance - (attacker:getBeenMovingFor() - (firearm:getAimingTime() + attacker:getPerkLevel(Perks.Aiming) * 2))
        print("critChance - (attacker:getBeenMovingFor() - (firearm:getAimingTime() + attacker:getPerkLevel(Perks.Aiming) * 2)): " .. critChance)
	end

	--critChance = critChance + attacker:getPerkLevel(Perks.Aiming) * 3
    --print("critChance + attacker:getPerkLevel(Perks.Aiming) * 3: " .. critChance)

	local playerDistance = attacker:DistToProper(target)

	if playerDistance < 4.0 then
		critChance = critChance + (4.0 - playerDistance) --* 7.0
	elseif playerDistance >= 4.0 then
		critChance = critChance - (playerDistance - 4.0) --* 7.0
	end
    print("playerDistance: " .. playerDistance)
    print("playerDistance - critChance: " .. critChance)

    --local shotsRow = attacker:getVariableString("shootInARow")
    local shotsRow = attacker:getVariable("shootInARow")
    if shotsRow ~= nil then
        shotsRow = tonumber(shotsRow)
    else
        shotsRow = 0
    end
    print("shotsRow: " , shotsRow)

	--if "Auto" == attacker:getVariableString("FireMode") and 1 < shotsRow then
    if "Auto" == firearm:getFireMode() and 1 < shotsRow then
		critChance = critChance - shotsRow * 10
	end

    return critChance
end

function Advanced_trajectory.calculateCritDamMod(attacker, target, firearm)
    local critChance = 0

	critChance = firearm:getCriticalChance()

	critChance = critChance + firearm:getAimingPerkCritModifier() * (attacker:getPerkLevel(Perks.Aiming) / 2.0)

	if attacker:getBeenMovingFor() > firearm:getAimingTime() + attacker:getPerkLevel(Perks.Aiming) * 2 then
		critChance = critChance - (attacker:getBeenMovingFor() - (firearm:getAimingTime() + attacker:getPerkLevel(Perks.Aiming) * 2))
	end

	critChance = critChance + attacker:getPerkLevel(Perks.Aiming) * 3

	local playerDistance = attacker:DistToProper(target)

	if playerDistance < 4.0 then
		critChance = critChance + (4.0 - playerDistance) * 7.0
	elseif playerDistance >= 4.0 then
		critChance = critChance - (playerDistance - 4.0) * 7.0
	end

    local shotsRow = attacker:getVariableString("shootInARow")

	if "Auto" == attacker:getVariableString("FireMode") and 1 < shotsRow then
		critChance = critChance - shotsRow * 10
	end

    return critChance
end


function Advanced_trajectory.handleHitReaction(attacker, target)
    if instanceof(target, "IsoPlayer") then
        local hitReaction = target:getHitReaction()
        if hitReaction and hitReaction ~= "" then
            target:reportEvent("wasHitPvPAgain")
        end
        target:reportEvent("wasHitPvP")
        target:setVariable("hitPvP", true)
    else
        target:reportEvent("wasHit")
    end

    -- AnimationPlayer
    --[[
    local targetAnim = target:getAnimationPlayer()
    print("targetAnim: " , targetAnim)
    --if (targetAnim ~= nil and targetAnim:isReady()) then
    if (targetAnim ~= nil) then
        targetAnim:UpdateDir(target)
        --targetAnim:Update()
        --targetAnim:Update(100)
        --targetAnim:dismember(100)
    end
    ]]--
end

function Advanced_trajectory.handleNonServerSideEffects(attacker, target)
	target:getXp():AddXP(Perks.Strength, 2.0)
    target:setHitForce(math.min(0.5, target:getHitForce()))
    target:setHitReaction("HitReaction")
    local hitDirection = attacker:testDotSide(target)
    target:setHitFromBehind(hitDirection == "BEHIND")
end

function Advanced_trajectory.calculateDistance(attacker, target)
    return IsoUtils.DistanceTo(target:getX(), target:getY(), attacker:getX(), attacker:getY())
end

function Advanced_trajectory.handleCriticalHit(attacker, initialTarget, critChance)
	-- attacker:setVariable("CombatSpeed", attacker:getCombatSpeedModifier() * 1.1)
	-- attacker.combatSpeed = attacker.combatSpeed * 1.1
	attacker:setCombatSpeedModifier(attacker:getCombatSpeedModifier() * 1.1)

    if Core.bDebug then
        DebugLog.Combat.debugln("PvP Hit player dist: " .. Advanced_trajectory.calculateDistance(attacker, initialTarget) .. " crit: " .. "true" .. " (" .. critChance .. "%) from behind: " .. attacker:isAttackFromBehind())
    end
end

function Advanced_trajectory.adjustCriticalHitRecoilDelay(attacker, firearm)
    attacker:setRecoilDelay(firearm:getRecoilDelay() - attacker:getPerkLevel(Perks.Aiming) * 2)
end

function Advanced_trajectory.calculateRecoilDelay(attacker, firearm)
    local recoilDelay = firearm:getRecoilDelay()
    local modifiedRecoilDelay = recoilDelay * (1.0 - attacker:getPerkLevel(Perks.Aiming) / 30.0)
    attacker:setRecoilDelay(modifiedRecoilDelay)
end

--[[
function Advanced_trajectory.setFireMode(attacker, firearm)
    if firearm then
        local fireMode = firearm:getFireMode()
        if fireMode ~= nil and fireMode ~= "" then
            attacker:setVariable("FireMode", fireMode)
        else
            attacker:clearVariable("FireMode")
        end
    else
        attacker:clearVariable("FireMode")
    end
end
]]--

function Advanced_trajectory.setAttackVariation(attacker)
    local randomValue = ZombRand(0, 3)

    if randomValue == 0 then
        attacker:setVariable("AttackVariationX", ZombRandFloat(-1.0, -0.5))
    elseif randomValue == 1 then
        attacker:setVariable("AttackVariationX", 0.0)
    elseif randomValue == 2 then
        attacker:setVariable("AttackVariationX", ZombRandFloat(0.5, 1.0))
    end

    attacker:setVariable("AttackVariationY", 0.0)
end

function Advanced_trajectory.printDebugInfo(attacker, damagepr, damagemod)
    print("NewDamagePlayershot - player:", attacker, " damagepr:", damagepr, " damagemod:", damagemod)
end

function Advanced_trajectory.calculateAdditionalChances(damagepr)
    local incHeadChance = (damagepr == Advanced_trajectory.HeadShotDmgPlayerMultiplier) and 20 or 0
    local incFootChance = (damagepr == Advanced_trajectory.FootShotDmgPlayerMultiplier) and 10 or 0
    return incHeadChance, incFootChance
end

function Advanced_trajectory.handleBodyDamage(attacker, target, damagepr, firearm, shotpart, damagemod, isCriticalHit, critChance, bodypart, bodyPartIndex, bulletDefense)

    --[[
	if bulletDefense < 0.5 then
		--print("WOUNDED")
		if bodypart:haveBullet() then
			local deepWound = bodypart:isDeepWounded()
			local deepWoundTime = bodypart:getDeepWoundTime()
			local bleedTime = bodypart:getBleedingTime()
			--bodypart:setHaveBullet(false, 0)
            bodypart:setDeepWounded(deepWound)
			bodypart:setDeepWoundTime(deepWoundTime)
			bodypart:setBleedingTime(bleedTime)
		else
			bodypart:setHaveBullet(true, 0)
		end
	end
    ]]--

	local damage = Advanced_trajectory.processHitDamage(attacker, target, damagepr, firearm, shotpart, damagemod, isCriticalHit, critChance, bodypart, bodyPartIndex)

    if bulletDefense > 0 then
        local randomValue = ZombRand(0, 100)
        if randomValue > 50 then
            if bodypart:haveBullet() and not bodypart:isDeepWounded() then
                damage = damage * 1.1
                bodypart:generateDeepWound()
            elseif bodypart:isDeepWounded() then
                damage = damage * 1.2
                bodypart:generateDeepWound()
            else
                damage = damage * 1
                bodypart:setHaveBullet(true, 0)
            end
        elseif randomValue <= 50 and randomValue > 15 then
            if bodypart:isCut() then
                damage = damage * 1
                bodypart:setHaveBullet(true, 0)
            else
                damage = damage * .75
                bodypart:setCut(true, false)
            end
        elseif randomValue <= 15 and randomValue >= 0 then
            if bodypart:scratched() then
                damage = damage * .75
                bodypart:setCut(true, false)
            else
                damage = damage * .5
                bodypart:setScratched(true, false)
            end
        end
    end

    if bulletDefense == nil or bulletDefense == 0 then
        local randomValue = ZombRand(0, 100)
        if randomValue > 50 then
            if bodypart:haveBullet() and not bodypart:isDeepWounded() then
                damage = damage * 2.00
                bodypart:generateDeepWound()
            elseif bodypart:isDeepWounded() then
                damage = damage * 2.25
                bodypart:generateDeepWound()
            else
                damage = damage * 1.75
                bodypart:setHaveBullet(true, 0)
            end
        elseif randomValue <= 50 and randomValue > 15 then
            if bodypart:isCut() then
                damage = damage * 1.75
                bodypart:setHaveBullet(true, 0)
            else
                damage = damage * 1.50
                bodypart:setCut(true, false)
            end
        elseif randomValue <= 15 and randomValue >= 0 then
            if bodypart:scratched() then
                damage = damage * 1.50
                bodypart:setCut(true, false)
            else
                damage = damage * 1.25
                bodypart:setScratched(true, false)
            end
        end
    end

    target:getBodyDamage():AddDamage(bodyPartIndex, damage)

    local characterStats = target:getStats()
    local currentpain = characterStats:getPain()
    local initialBitePain = target:getBodyDamage():getInitialBitePain()
    local painModifyer = BodyPartType.getPainModifyer(bodyPartIndex)
    characterStats:setPain(currentpain + initialBitePain * painModifyer)

    if target:getStats():getPain() > 100.0 then
        target:getStats():setPain(100.0)
    end

    target:addBlood(50)

	--if headshot
	if damagepr == Advanced_trajectory.HeadShotDmgPlayerMultiplier then
		--SwipeStatePlayer.splash(target, firearm, player)
		--SwipeStatePlayer.instance():splash(target, firearm, player)
		--SwipeStatePlayer.splash(target, firearm, player)
		--SwipeStatePlayer:splash(target, firearm, player)

		--SwipeStatePlayer.instance():splash(target, firearm, player)
		--SwipeStatePlayer.instance():splash(target, firearm, player)


		target:addBlood(BloodBodyPartType.Head, true, true, true)
		target:addBlood(BloodBodyPartType.Torso_Upper, true, false, false)
		target:addBlood(BloodBodyPartType.UpperArm_L, true, false, false)
		target:addBlood(BloodBodyPartType.UpperArm_R, true, false, false)
	end
end

-- Process hit damage function
function Advanced_trajectory.processHitDamage(attacker, target, damagepr, firearm, shotpart, damagemod, isCriticalHit, critChance, bodypart, bodyPartIndex)
    local useAimingLevel = true
    local useDistanceScaling = true

    --local baseDamage = ZombRandFloat(firearm:getMinDamage(), firearm:getMaxDamage()) * 15.0
	--local totalDamage = baseDamage * damagepr

    print("firearm:getMinDamage(): " .. firearm:getMinDamage())
    print("firearm:getMaxDamage(): " .. firearm:getMaxDamage())
    print("damagepr: " .. damagepr)
    local baseDamage = ZombRandFloat(firearm:getMinDamage(), firearm:getMaxDamage()) * damagepr
    local totalDamage = baseDamage
    print("baseDamage: " .. baseDamage)
    totalDamage = totalDamage * damagemod
    print("totalDamage * damagemod: " .. totalDamage)
    --totalDamage = totalDamage * 0.4
    --print("totalDamage * 0.4: " .. totalDamage)


   --local distance = IsoUtils.DistanceTo(attacker:getX(), attacker:getY(), target:getX(), target:getY())
    if useDistanceScaling == true then
        local playerDistance = attacker:DistToProper(target)
        local distanceDamageMult = Advanced_trajectory.calculateDistanceDamageMultiplier(attacker, firearm, playerDistance)
        --totalDamage = totalDamage + (totalDamage * distanceDamageMult)
        totalDamage = totalDamage * distanceDamageMult
        print("distanceDamageMult: " .. distanceDamageMult)
        print("totalDamage * distanceDamageMult: " .. totalDamage)
    end

    --if not firearm:isShareDamage() then
    --    totalDamage = 1.0
    --    print("not firearm:isShareDamage(): " , firearm:isShareDamage())
    --    print("totalDamage: " .. totalDamage)
    --end


    --if instanceof(attacker, "IsoPlayer") and not attacker.bDoShove then


    local dotProductDamageMultiplier = Advanced_trajectory.calculateDotProductDamageMultiplier(attacker, target, firearm)
    print("dotProductDamageMultiplier: " .. dotProductDamageMultiplier)
    --totalDamage = totalDamage + (totalDamage * dotProductDamageMultiplier)
    totalDamage = totalDamage * dotProductDamageMultiplier
    print("totalDamage * dotProductDamageMultiplier: " .. totalDamage)
        --if instanceof(attacker, "IsoPlayer") then

        --end
        --else
        --   totalDamage = totalDamage * 1.5
        --end

    if useAimingLevel == true then
        local aimingLevelDamageModifier = Advanced_trajectory.calculateAimingLevelDamageModifier(attacker)
        print("aimingLevelDamageModifier: " .. aimingLevelDamageModifier)
        totalDamage = totalDamage * aimingLevelDamageModifier
        print("totalDamage + (totalDamage * aimingLevelDamageModifier): " .. totalDamage)
    end

    --isAimAtFloor stuff WIP
    --consider the critical hit chance while looking at the floor
    if instanceof(attacker, "IsoPlayer") and attacker:isAimAtFloor() and not isCriticalHit and not attacker.bDoShove then
        --totalDamage = totalDamage * math.max(5.0, firearm:getCritDmgMultiplier())
        totalDamage = totalDamage + (totalDamage * math.max(5.0, firearm:getCritDmgMultiplier()))
        print("totalDamage + Floor Crit: " .. totalDamage)
    end

    if isCriticalHit then
        print("isCriticalHit:" , isCriticalHit)
        --totalDamage = totalDamage * (math.max(2.0, firearm:getCritDmgMultiplier()))
        --totalDamage = totalDamage + ((math.max(2.0, firearm:getCritDmgMultiplier()) * .1) * totalDamage)
        local critMod = math.max(1.1, firearm:getCritDmgMultiplier()) * .1
        print("critMod: " .. critMod)
        totalDamage = totalDamage * critMod
        print("totalDamage * critMod: " .. totalDamage)
        print("CRITICAL HIT - totalDamage: " .. totalDamage)
        --totalDamage = totalDamage * critChance
        --print("totalDamage * critChance: " .. totalDamage)
        --totalDamage = totalDamage + (totalDamage / 2.7) --For Setting HitForce
        --print("totalDamage + CRIT: " .. totalDamage)
    end

    print("firearm:isTwoHandWeapon(): " , firearm:isTwoHandWeapon())
    print("firearm:isRequiresEquippedBothHands(): " , firearm:isRequiresEquippedBothHands())

    --if firearm:isTwoHandWeapon() and not attacker:isItemInBothHands(firearm) then
    if not firearm:isTwoHandWeapon() and not firearm:isRequiresEquippedBothHands() then
        print("firearm:isTwoHandWeapon() and not attacker:isItemInBothHands(firearm): " , firearm:isTwoHandWeapon() and not attacker:isItemInBothHands(firearm))
        totalDamage = totalDamage * 0.9
        print("totalDamage * 0.9: " .. totalDamage)
    end


    if instanceof(attacker, "IsoPlayer") and not isCriticalHit then
        attacker:setHitForce(attacker:getHitForce() * 2.0)
    end

    print("FINAL - totalDamage: " .. totalDamage)
    return totalDamage
    --end
end


function Advanced_trajectory.calculateDistanceDamageMultiplier(attacker, firearm, playerDistance)
    -- Calculate distance
    --local distance = Advanced_trajectory.calculateDistance(attacker, target)
    local distance = playerDistance
    print("distance: " .. distance)

    -- Check if distance is within the firearm range
    if distance >= firearm:getMinRange() and distance <= firearm:getMaxRange(attacker) then
        print("calculateDistanceDamageMultiplier:   1.0")
        return 1.0 -- Target is within the range, so no damage reduction
    else
        local scaleDistance = 0.0

        -- Check if distance is below the minimum range
        if distance < firearm:getMinRange() then
            scaleDistance = firearm:getMinRange() - distance
        else
            -- Distance is above the maximum range
            scaleDistance = distance - firearm:getMaxRange(attacker)
        end

        -- Calculate the damage reduction factor, scaling linearly from 0.5 to 0.0
        local maxRangeHalf = 0.5 * firearm:getMaxRange(attacker)
        local minRangeHalf = -0.5 * firearm:getMinRange()
        local damageReductionFactor = 0.0

        if scaleDistance >= maxRangeHalf or scaleDistance <= minRangeHalf then
            damageReductionFactor = 0.0
        else
            damageReductionFactor = math.max(0.0, 1.0 - math.abs(scaleDistance) / maxRangeHalf)
        end

        print("calculateDistanceDamageMultiplier: " .. damageReductionFactor)

        return damageReductionFactor
    end
end

function Advanced_trajectory.calculateDistanceAccuracyModifier(attacker, firearm, playerDistance)
    -- Calculate distance
    local minRange = firearm:getMinRange()
    local maxRange = firearm:getMaxRange(attacker)

    if playerDistance >= minRange and playerDistance <= maxRange then
        return 1.0 -- Target is within the range, so no accuracy penalty
    else
        local scaleDistance = 0.0

        if playerDistance < minRange then
            scaleDistance = minRange - playerDistance
        else
            scaleDistance = playerDistance - maxRange
        end

        local maxRangeHalf = 0.5 * maxRange
        local minRangeHalf = -0.5 * minRange
        local accuracyPenaltyFactor = 1.0

        if scaleDistance <= minRangeHalf then
            accuracyPenaltyFactor = math.min(1.0, 1.0 - math.abs(scaleDistance) / math.abs(minRangeHalf))
        elseif scaleDistance >= maxRangeHalf then
            accuracyPenaltyFactor = math.min(1.0, 1.0 - math.abs(scaleDistance) / maxRangeHalf)
        else
            accuracyPenaltyFactor = 0.0
        end

        return accuracyPenaltyFactor
    end
end

 --Is attacker facing the target?
 function Advanced_trajectory.calculateDotProductDamageMultiplier(attacker, target, firearm)

        local damage = 1.0
        local v3 = Vector2.new()
        v3:set(attacker:getX(), attacker:getY())
        local v4 = Vector2.new()
        v4:set(target:getX(), target:getY())



        local v7 = Vector2.new()
        --v7:set(v3:getX() - v4:getX(), v3:getY() - v4:getY())
        v7:set(v4:getX() - v3:getX(), v4:getY() - v3:getY())

        local v5 = Vector2.new()
        v5 = attacker:getVectorFromDirection(v4);

        local isDirPerfect = false
        if (v5:getX() == 0.0 and v5:getY() == 0.0) then
            isDirPerfect = true
        end

        v7:normalize();
        local dotProduct = v7:dot(v5)
        --local anotherdotProduct = target:getDotWithForwardDirection(playerdir:getX(), playerdir:getY())
        --if (dotProduct > 1.0) then
        --    dotProduct = 1.0
        --end

        --if (dotProduct < -1.0) then
        --   dotProduct = -1.0
        --end
        print("dotProduct: " .. dotProduct)

        if (isDirPerfect) then
            dotProduct = 1.0
        end

        if (dotProduct <= firearm:getMinAngle() and dotProduct >= firearm:getMaxAngle()) then
            print("MinAngle: " .. firearm:getMinAngle())
            print("MaxAngle: " .. firearm:getMaxAngle())
            --Over/Under angled
        end

        --if (dotProduct > -0.3) then
        if (dotProduct > 0.93) then
            damage = 1.5
            --print("damage: " .. damage)
            --return damage
        end

    -- Return the calculated damage multiplier
    print("damage: " .. damage)
    return damage
 end

 function Advanced_trajectory.calculateAimingLevelDamageModifier(attacker)
    local damageModifier = 1.0  -- Default modifier

       local weaponLevel = attacker:getWeaponLevel()

       -- Calculate damage modifier based on firearm level
       if weaponLevel == -1 then
          damageModifier = 0.3
       elseif weaponLevel >= 0 and weaponLevel <= 10 then
          damageModifier = 0.3 + weaponLevel * 0.1
       end

    return damageModifier
 end


 function Advanced_trajectory.calculateAttackerCombatSpeed(attacker, target, firearm)
    local isPrimaryHandWeapon = true
    local combatSpeed = 1.0
    local primaryHandWeapon = nil

    --instanceof(attacker, "IsoPlayer")

    if attacker:getPrimaryHandItem() ~= nil and instanceof(attacker:getPrimaryHandItem(), "HandWeapon") then
        primaryHandWeapon = attacker:getPrimaryHandItem()
        combatSpeed = combatSpeed * primaryHandWeapon:getBaseSpeed()
    end

    --local weaponType = WeaponType.getWeaponType(attacker)
    local weaponType = firearm:getFullType()

    if primaryHandWeapon ~= nil and primaryHandWeapon:isTwoHandWeapon() and attacker:getSecondaryHandItem() ~= primaryHandWeapon then
        combatSpeed = combatSpeed * 0.77
    end

    if primaryHandWeapon ~= nil and attacker:HasTrait("Axeman") and primaryHandWeapon:getCategories():contains("Axe") then
        combatSpeed = combatSpeed * attacker:getChopTreeSpeed()
        isPrimaryHandWeapon = false
    end

    --attacker:getStats():getEndurance()
    --combatSpeed = combatSpeed - (attacker:getStats():getEndurance() * 0.07)
    combatSpeed = combatSpeed - (attacker:getMoodles():getMoodleLevel(MoodleType.Endurance) * 0.07)
    combatSpeed = combatSpeed - (attacker:getMoodles():getMoodleLevel(MoodleType.HeavyLoad) * 0.07)
    combatSpeed = combatSpeed + (attacker:getWeaponLevel() * 0.03)
    combatSpeed = combatSpeed + (attacker:getPerkLevel(Perks.Fitness) * 0.02)

    if attacker:getSecondaryHandItem() ~= nil and instanceof(attacker:getSecondaryHandItem(), "InventoryContainer") then
        combatSpeed = combatSpeed * 0.95
    end

    combatSpeed = combatSpeed * ZombRandFloat(1.1, 1.2)
    --combatSpeed = combatSpeed * self.combatSpeedModifier
    combatSpeed = combatSpeed * attacker:getCombatSpeedModifier()
    combatSpeed = combatSpeed * attacker:getArmsInjurySpeedModifier()

    if attacker:getBodyDamage() ~= nil and attacker:getBodyDamage():getThermoregulator() ~= nil then
        combatSpeed = combatSpeed * attacker:getBodyDamage():getThermoregulator():getCombatModifier()
    end

    combatSpeed = math.min(1.6, combatSpeed)
    combatSpeed = math.max(0.8, combatSpeed)

    if primaryHandWeapon ~= nil and primaryHandWeapon:isTwoHandWeapon() and string.lower(weaponType) == "heavy" then
        combatSpeed = combatSpeed * 1.2
    end

    print("ATTACKER - combatSpeed: " .. combatSpeed)
    return combatSpeed * (isPrimaryHandWeapon and GameTime.getAnimSpeedFix() or 1.0)
end

-- Calculate the combat speed of the target.
-- @param target The target character
-- @param shotpart The part of the body that was shot
-- @return The calculated combat speed
function Advanced_trajectory.calculateTargetCombatSpeed(target, shotpart)
    -- Initialize variables
    local isPrimaryHandWeapon = true
    local combatSpeed = 1.0
    local primaryHandWeapon = nil
    local weaponType = ""

    -- Check if the target's primary hand item is a hand weapon
    if target:getPrimaryHandItem() ~= nil and instanceof(target:getPrimaryHandItem(), "HandWeapon") then
        primaryHandWeapon = target:getPrimaryHandItem()
        combatSpeed = combatSpeed * primaryHandWeapon:getBaseSpeed()
    end

    -- If a primary hand weapon is present, get its full type
    if primaryHandWeapon ~= nil then
        weaponType = primaryHandWeapon:getFullType()
    end

    -- Adjust combat speed based on two-handed weapon and secondary hand item
    if primaryHandWeapon ~= nil and primaryHandWeapon:isTwoHandWeapon() and target:getSecondaryHandItem() ~= primaryHandWeapon then
        combatSpeed = combatSpeed * 0.77
    end

    -- Adjust combat speed based on moodles and fitness skill
    combatSpeed = combatSpeed - (target:getMoodles():getMoodleLevel(MoodleType.Endurance) * 0.07)
    combatSpeed = combatSpeed - (target:getMoodles():getMoodleLevel(MoodleType.HeavyLoad) * 0.07)
    combatSpeed = combatSpeed + (target:getPerkLevel(Perks.Fitness) * 0.02)

    -- Adjust combat speed based on secondary hand item
    if target:getSecondaryHandItem() ~= nil and instanceof(target:getSecondaryHandItem(), "InventoryContainer") then
        combatSpeed = combatSpeed * 0.95
    end

    -- Randomly adjust combat speed within a range
    combatSpeed = combatSpeed * ZombRandFloat(1.1, 1.2)

    -- Calculate injury speed and adjust combat speed accordingly
    local injurySpeed = Advanced_trajectory.calculateInjurySpeed(target, shotpart, false)
    if injurySpeed ~= nil and injurySpeed > 0 then
        combatSpeed = combatSpeed * injurySpeed
        print("injurySpeed: " .. injurySpeed)
    end

    -- Calculate combat speed based on the character's base speed
    local baseSpeed = target:calculateBaseSpeed()
    combatSpeed = combatSpeed * baseSpeed

    -- Adjust combat speed based on thermoregulator if present
    if target:getBodyDamage() ~= nil and target:getBodyDamage():getThermoregulator() ~= nil then
        combatSpeed = combatSpeed * target:getBodyDamage():getThermoregulator():getCombatModifier()
    end

    -- Adjust combat speed for heavy two-handed weapons
    if primaryHandWeapon ~= nil and primaryHandWeapon:isTwoHandWeapon() and string.lower(weaponType) == "heavy" then
        combatSpeed = combatSpeed * 1.2
    end

    -- Debug print statements
    print("TARGET - combatSpeed: " .. combatSpeed)
    print("TARGET END - combatSpeed: " .. combatSpeed * (isPrimaryHandWeapon and GameTime.getAnimSpeedFix() or 1.0))

    -- Return the final combat speed, considering animation speed fix
    return combatSpeed * (isPrimaryHandWeapon and GameTime.getAnimSpeedFix() or 1.0)
end


--combatSpeed = combatSpeed * Advanced_trajectory.calculateTargetEvasion(target)

function Advanced_trajectory.calculateEvasion(player, shotpart)
    local lightfooted = player:getPerkLevel(Perks.Lightfooted) -- 0 min to 10 max
    print("lightfooted: " .. lightfooted)
    local nimbleLevel = player:getPerkLevel(Perks.Nimble) -- 0 min to 10 max
    print("nimbleLevel: " .. nimbleLevel)
    local sprintingLevel = player:getPerkLevel(Perks.Sprinting) -- 0 min to 10 max
    print("sprintingLevel: " .. sprintingLevel)
    local endurance = player:getStats():getEndurance() -- 1.0 max to 0.0 min
    print("endurance: " .. endurance)
    local weight = player:getNutrition():getWeight() -- 0 to infinite integer
    print("weight: " .. weight)
    local combatSpeed = Advanced_trajectory.calculateTargetCombatSpeed(player, shotpart) -- 0.0 to 1.0
    print("combatSpeed: " .. combatSpeed)

    -- Calculate the impact of weight on Evasion (75-84)
    local weightImpact = 0.0

    if weight >= 84 or weight <= 75 then
        weightImpact = 10.0
    elseif weight >= 96 or weight <= 63 then
        weightImpact = 0.0
    elseif weight >= 85 then
        weightImpact = 10.0 - (weight - 85)
    elseif weight <= 74 then
        weightImpact = 10.0 - (weight - 74)
    end
    print("weightImpact: " .. weightImpact)

    -- Scale the impact of endurance and combatSpeed
    local enduranceImpact = endurance * 10.0
    print("enduranceImpact: " .. enduranceImpact)
    local combatSpeedImpact = combatSpeed * 10.0
    print("combatSpeedImpact: " .. combatSpeedImpact)

    -- Calculate total Evasion
    local totalEvasion = 40 + lightfooted + nimbleLevel + sprintingLevel + weightImpact + enduranceImpact + combatSpeedImpact

    print("totalEvasion: " .. totalEvasion)
    return totalEvasion
end

function Advanced_trajectory.calculateEvasionOld(player, shotpart)
    local lightfooted = player:getPerkLevel(Perks.Lightfooted) --0 min to 10 max
    --local endurance = player:getPerkLevel("Endurance")
    --local endurancetry = player:getMoodles():getMoodleLevel(MoodleType.Endurance)
    --print("endurancetry: " , endurancetry)
    local endurance = player:getStats():getEndurance() --1.0 max to 0.0 min
    print("endurance: " .. endurance)
    local nimbleLevel = player:getPerkLevel(Perks.Nimble) --0 min to 10 max
    local sprintingLevel = player:getPerkLevel(Perks.Sprinting) --0 min to 10 max
    --[[
    Name                     Weight Range
    Obese                    100 or more
    Overweight               85 - 99
    Normal                   76 - 84
    Underweight              66 - 75
    Very Underweight         51 - 65
    Emaciated                50 or less
    Degeneration (Damage)   35
    --]]
    local weight = player:getWeight() --0 to infinite integer 
    print("weight: " .. weight)
    local combatSpeed = Advanced_trajectory.calculateTargetCombatSpeed(player, shotpart) --0.0 to 1.0   
    print("combatSpeed: " .. combatSpeed)

    local baseEvasion = (nimbleLevel + lightfooted) * 2
    print("baseEvasion: " .. baseEvasion)
    local enduranceScaling = (endurance / 10)
    print("enduranceScaling: " .. enduranceScaling)
    local sprintingScaling = (sprintingLevel * 5)  -- Adjust as needed
    print("sprintingScaling: " .. sprintingScaling)

    local scaledEvasion = baseEvasion + (1 + enduranceScaling + sprintingScaling)
    print("scaledEvasion: " .. scaledEvasion)

    if weight >= 100 then
        scaledEvasion = scaledEvasion * 0.7
    elseif weight >= 85 then
        scaledEvasion = scaledEvasion * 0.85
    elseif weight >= 66 then
        -- No change in evasion for normal and underweight players
    elseif weight >= 51 then
        scaledEvasion = scaledEvasion * 1.1
    else
        scaledEvasion = scaledEvasion * 1.2
    end
    print("weight - scaledEvasion: " .. scaledEvasion)

    -- Adjust evasion based on combat speed
    if combatSpeed >= 3 then
        scaledEvasion = scaledEvasion * 1.2
    elseif combatSpeed >= 2 then
        scaledEvasion = scaledEvasion * 1.1
    elseif combatSpeed >= 1 then
        scaledEvasion = scaledEvasion * 1.05
    end
    print("combatSpeed - scaledEvasion: " .. scaledEvasion)

    local totalEvasion = scaledEvasion

    print("totalEvasion: " .. totalEvasion)
    return totalEvasion
end


--firearm:getMaxRange(attacker, firearm)


-- Define a function to calculate attacker's accuracy
function Advanced_trajectory.calculateAccuracy(attacker, firearm, distance, aimnumBeforeShot)
    local baseAccuracy = 60  -- Base accuracy value (adjust as needed)
    local aiming = attacker:getPerkLevel(Perks.Aiming)  -- Assuming you have a skill or perk for aiming
    print("aiming: " .. aiming)
    --local firearmParts = firearm:getAllWeaponParts()  -- Assuming you have a function to get equipped firearms
    --print("firearmParts: " , firearmParts:size(), "-", firearmParts)
    local distanceModifier = Advanced_trajectory.calculateDistanceAccuracyModifier(attacker, firearm, distance)
    print("distanceModifier: " .. distanceModifier)

    --local firearmMaxRange = firearm:getMaxRange()
    --print("firearmMaxRange: " .. firearmMaxRange)
    --local firearmMinRange = firearm:getMinRange()
    --print("firearmMinRange: " .. firearmMinRange)

    -- Calculate accuracy based on the attacker's aiming skill
    --local accuracy = baseAccuracy + aiming --* 2
    --print("accuracy: " .. accuracy)

    -- Check for any equipment or modifiers affecting accuracy
    --[[
    for i = 0, firearmParts:size() - 1 do
        local firearmP = firearmParts:get(i)
        print("Firearm Part: " , firearmP)
        --getPartType()
        --getMaxRange()
        --getMinRangeRanged()

        if firearmP:getMaxRange() ~= nil and firearmP:getMaxRange() > 0 then
            --accuracy = accuracy + firearmP:getModData("AccuracyModifier")
            firearmMaxRange = firearm:getMaxRange() + firearmMaxRange
            print("firearmMaxRange: " .. firearmMaxRange)
        end
        if firearmP:getMinRangeRanged() ~= nil and firearmP:getMinRangeRanged() > 0 then
            firearmMinRange = firearm:getMinRangeRanged() + firearmMinRange
            print("firearmMinRange: " .. firearmMinRange)
        end
    end
    ]]--

    --condition
    local firearmCond = (firearm:getCondition() / firearm:getConditionMax()) * 10
    print("firearmCond: " .. firearmCond)

    print("aimnumBeforeShot: " .. aimnumBeforeShot)
    --local aimnumAcc = Advanced_trajectory.aimnumBeforeShot
    --print("aimnumAcc: " .. aimnumAcc)
    local aimnumAcc = (100 - aimnumBeforeShot) * .1
    --local aimnumAcc = Advanced_trajectory.aimnum * .1
    --local aimnumAcc = Advanced_trajectory.aimnum * .01
    print("aimnumAcc: " .. aimnumAcc)

    -- Apply distance modifier to accuracy
    local accuracy = (baseAccuracy + (aiming * 2) + firearmCond + aimnumAcc) * distanceModifier

    -- Ensure accuracy is within a reasonable range (e.g., between 0 and 100)
    --accuracy = math.max(0, math.min(accuracy, 100))

    print("FINAL accuracy: " .. accuracy)
    return accuracy
end

function Advanced_trajectory.canEvade(attacker, target, firearm, distance, shotpart, aimnum)
	local accuracy = Advanced_trajectory.calculateAccuracy(attacker, firearm, distance, aimnum)
    local evasion = Advanced_trajectory.calculateEvasion(target, shotpart)
    local randomValue = ZombRandFloat(0, 100) + 1
    print("randomValue: " .. randomValue)

    print("accuracy <= evasion: " .. accuracy .. " <= " .. evasion)
    if accuracy <= evasion then
        --Failed Evasion
        local randomValue1 = ZombRandFloat(0, 100) + 1
        print("randomValue: " .. randomValue1)
        if randomValue1 <= evasion then
            --Successfull Evasion
            print("Successfull Evasion: 1")
            return true
        else
            --Failed Evasion
            return false
        end
    else
        local randomValue2 = ZombRandFloat(0, 100) + 1
        print("randomValue: " .. randomValue2)
        if randomValue2 <= accuracy then
            --Failed Evasion
            return false
        else
            --Successfull Evasion
            print("Successfull Evasion: 2")
            return true
        end
    end
end

function Advanced_trajectory.calculateInjurySpeed(target, bodyPart, isPainful)
    local scratchSpeedModifier = bodyPart:getScratchSpeedModifier()
    local cutSpeedModifier = bodyPart:getCutSpeedModifier()
    local burnSpeedModifier = bodyPart:getBurnSpeedModifier()
    local deepWoundSpeedModifier = bodyPart:getDeepWoundSpeedModifier()
    local injurySpeed = 0.0

    if (bodyPart:getType() == BodyPartType.Foot_L or bodyPart:getType() == BodyPartType.Foot_R) and
       (bodyPart:getBurnTime() > 5.0 or bodyPart:getBiteTime() > 0.0 or bodyPart:deepWounded() or bodyPart:isSplint() or bodyPart:getFractureTime() > 0.0 or bodyPart:haveGlass()) then
        injurySpeed = 1.0

        if bodyPart:bandaged() then
            injurySpeed = 0.7
        end

        if bodyPart:getFractureTime() > 0.0 then
            injurySpeed = Advanced_trajectory.calcFractureInjurySpeed(bodyPart)
        end
    end

    if bodyPart:haveBullet() then
        return 1.0
    else
        if (bodyPart:getScratchTime() > 2.0 or bodyPart:getCutTime() > 5.0 or bodyPart:getBurnTime() > 0.0 or bodyPart:getDeepWoundTime() > 0.0 or bodyPart:isSplint() or bodyPart:getFractureTime() > 0.0 or bodyPart:getBiteTime() > 0.0) then
            injurySpeed = injurySpeed + bodyPart:getScratchTime() / scratchSpeedModifier + bodyPart:getCutTime() / cutSpeedModifier + bodyPart:getBurnTime() / burnSpeedModifier + bodyPart:getDeepWoundTime() / deepWoundSpeedModifier
            injurySpeed = injurySpeed + bodyPart:getBiteTime() / 20.0

            if bodyPart:bandaged() then
                injurySpeed = injurySpeed / 2.0
            end

            if bodyPart:getFractureTime() > 0.0 then
                injurySpeed = Advanced_trajectory.calcFractureInjurySpeed(bodyPart)
            end
        end

        if isPainful and bodyPart:getPain() > 20.0 then
            injurySpeed = injurySpeed + bodyPart:getPain() / 10.0
        end

        return injurySpeed
    end
end

function Advanced_trajectory.calcFractureInjurySpeed(bodyPart)
    local fractureInjurySpeed = 0.4

    if bodyPart:getFractureTime() > 10.0 then
        fractureInjurySpeed = 0.7
    end

    if bodyPart:getFractureTime() > 20.0 then
        fractureInjurySpeed = 1.0
    end

    if bodyPart:getSplintFactor() > 0.0 then
        fractureInjurySpeed = fractureInjurySpeed - 0.2
        fractureInjurySpeed = fractureInjurySpeed - math.min(bodyPart:getSplintFactor() / 10.0, 0.8)
    end

    return math.max(0.0, fractureInjurySpeed)
end

--Only calls PlayerShot maybe we need Attacker!?
local function Advanced_trajectory_OnServerCommand(module, command, arguments)

    local clientPlayershot = getPlayer()
    if not clientPlayershot then return end

	if module == "ATY_shotplayer" then
		print("OnServerCommand: ATY_shotplayer - START")

        local playershotOnlineID = arguments[1] --Playershot:getOnlineID()
		local playershot = getPlayerByOnlineID(playershotOnlineID)
        local attackerOnlineID = arguments[2] --attacker:getOnlineID()  
		local attacker = getPlayerByOnlineID(attackerOnlineID)
        local damagepr = arguments[3] --damagepr
        --local firearmdamage = arguments[3] --firearmdamage
        local damagemod = arguments[4] --damagemod
        local firearm = arguments[5] --firearm
        local aimnum = arguments[6] --aimnum

        if playershot:getOnlineID() ~= clientPlayershot:getOnlineID() then return end

        if (getSandboxOptions():getOptionByName("ATY_nonpvp_protect"):getValue() and NonPvpZone.getNonPvpZone(clientPlayershot:getX(), clientPlayershot:getY())) or (getSandboxOptions():getOptionByName("ATY_safezone_protect"):getValue() and SafeHouse.getSafeHouse(clientPlayershot:getCurrentSquare())) then return end
        -- print(NonPvpZone.getNonPvpZone(getPlayer():getX(), getPlayer():getY()))
        -- print(SafeHouse.getSafeHouse(getPlayer():getCurrentSquare()))

        print("*-----------------------------------------------------------------------------*")
        clientPlayershot:Say("damagepr: " .. damagepr)
        print("BEFORE DAMAGE: " , attacker, clientPlayershot, damagepr, damagemod, firearm, aimnum)
        --NewDamagePlayershot(clientPlayershot, damagepr, firearmdamage)
        --RevDamagePlayershot(clientPlayershot, damagepr, firearmdamage)
        RevDamagePlayershot(attacker, clientPlayershot, damagepr, damagemod, firearm, aimnum)
        print("*-----------------------------------------------------------------------------*")
    elseif module == "ATY_killedplayer" then

        local playershotOnlineID = arguments[1] --Playershot:getOnlineID()
		local playershot = getPlayerByOnlineID(playershotOnlineID)
        local attackerOnlineID = arguments[2] --attacker:getOnlineID()
		local attacker = getPlayerByOnlineID(attackerOnlineID)
        if playershot:getOnlineID() ~= clientPlayershot:getOnlineID() then return end
        --if attacker:getOnlineID() ~= clientPlayershot:getOnlineID() then return end

        if (getSandboxOptions():getOptionByName("ATY_nonpvp_protect"):getValue() and NonPvpZone.getNonPvpZone(clientPlayershot:getX(), clientPlayershot:getY())) or (getSandboxOptions():getOptionByName("ATY_safezone_protect"):getValue() and SafeHouse.getSafeHouse(clientPlayershot:getCurrentSquare())) then return end

        if not clientPlayershot:isOnKillDone() and clientPlayershot:shouldDoInventory() then
            attacker:Kill(clientPlayershot)
        end

		local upTheKillCount = attacker:getVariableString("upKillCount")
		if instanceof(playershot, "IsoPlayer") and upTheKillCount then
            attacker:setSurvivorKills(attacker:setSurvivorKills() + 1)
        end

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