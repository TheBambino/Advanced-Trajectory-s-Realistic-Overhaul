Advanced_trajectory = {}
Advanced_trajectory.table={}
Advanced_trajectory.boomtable={}
Advanced_trajectory.aimcursor=nil
Advanced_trajectory.aimcursorsq = nil
Advanced_trajectory.panel = {}
Advanced_trajectory.panel.instance = nil
Advanced_trajectory.aimnum = 100
Advanced_trajectory.aimnumBeforeShot = 0
Advanced_trajectory.maxaimnum = 100
Advanced_trajectory.minaimnum = 0
Advanced_trajectory.inhaleCounter = 0
Advanced_trajectory.exhaleCounter = 0
Advanced_trajectory.maxFocusCounter = 100

-- for aimtex
Advanced_trajectory.alpha = 0
Advanced_trajectory.stressEffect = 0

Advanced_trajectory.aimtexwtable ={} 
Advanced_trajectory.aimtexdistance = 0 --包含准星的武器

Advanced_trajectory.Advanced_trajectory = {}

-- PVP 
Advanced_trajectory.dmgDealtToPlayer = 0
Advanced_trajectory.playerKilled = ""



----------------------------------------------------------------
--REMOVE ITEM (ex. bullet projectile when collide) FUNC SECT---
----------------------------------------------------------------
function Advanced_trajectory.itemremove(worlditem)
    if worlditem==nil then return end
    -- worlditem:getWorldItem():getSquare():transmitRemoveItemFromSquare(worlditem:getWorldItem())
    worlditem:getWorldItem():removeFromSquare()
end

-------------------------
--MATH FLOOR FUNC SECT---
-------------------------
function Advanced_trajectory.mathfloor(number)
    return number-math.floor(number)
end

-----------------------------
--ADD TEXTURE FX FUNC SECT---
-----------------------------
function Advanced_trajectory.additemsfx(square,itemname,x,y,z)
    if square:getZ()>7 then return end
    local iteminv = InventoryItemFactory.CreateItem(itemname)
    local itemin = IsoWorldInventoryObject.new(iteminv,square,Advanced_trajectory.mathfloor(x),Advanced_trajectory.mathfloor(y),Advanced_trajectory.mathfloor(z));
    iteminv:setWorldItem(itemin)
    square:getWorldObjects():add(itemin)
    square:getObjects():add(itemin)
    local chunk = square:getChunk()
    
    if chunk then
        square:getChunk():recalcHashCodeObjects()
    else return end
    -- iteminv:setAutoAge();
    -- itemin:setKeyId(iteminv:getKeyId());
    -- itemin:setName(iteminv:getName());
    return iteminv
end

-------------------------
--TABLE ?? FUNC SECT---
-------------------------
function Advanced_trajectory.twotable(table2)
    local table1={}

    for i,k in pairs(table2) do
        table1[i]=table2[i]
    end
    -- print(table1)
    return table1
end

-- print(Advanced_trajectory.additemsfx(getPlayer():getCurrentSquare(),"Base.Apple",getPlayer():getCurrentSquare():getX(),getPlayer():getCurrentSquare():getY(),0):getWorldItem())


----------------------------------------------------
--BULLET HIT ZOMBIE/PLAYER DETECTION ?? FUNC SECT---
----------------------------------------------------
-- NOTES: postable (position table of offsets xyz {}); damage (is either 1,2 or 3 where 1 is head, 2 is body, 3 is feet); isshotplayer (bool for if players can shoot each other)
function Advanced_trajectory.getShootzombie(postable,damage,isshotplayer)

    local zbtable = {}  -- zombie table
    local prtable = {}  -- player table

    for kz = -1,1 do
        for vz = -1,1 do
            local sq = getCell():getGridSquare(postable[1]+kz*0.5,postable[2]+vz*0.5,postable[3])
            if sq then

                local movingObjects = sq:getMovingObjects()
             --print(movingObjects)

                for zz=1,movingObjects:size() do
                    local zombiez = movingObjects:get(zz-1)
                     --print(zombiez)
                    if instanceof(zombiez,"IsoZombie") then
                         --print("addzombie")
                        zbtable[zombiez] = 1
                    elseif isshotplayer and  instanceof(zombiez,"IsoPlayer") then
                        prtable[zombiez] = 1
                    end
                end
            end
        end
    end

    -- minimum distance from player to target
    local mindistance = 0

    -- is target in bullet cell? mindistance = 1
    local minzb = {false,1}
    local minpr = {false,1}


    -- zombie table
    -- what is mindistance?
    for sz,bz in pairs(zbtable) do

        -- use euclidian distance to find distance between target and bullet
        mindistance = (postable[1] - sz:getX())^2 + (postable[2] - sz:getY())^2
        --print(mindistance)
        if  mindistance<=0.42*damage then
            -- update minzb if mindistance is closer
            if mindistance < minzb[2] then
                minzb = {sz,mindistance}
            end
        end
    end

    -- player table
    for sz,bz in pairs(prtable) do
        mindistance = (postable[1] - sz:getX())^2 + (postable[2] - sz:getY())^2

        if  mindistance<=0.4*damage then
            if mindistance < minpr[2] then
                minpr = {sz,mindistance}
            end
        end
    end


    -- if minpr[1] and minpr[1]   then
    --     minpr[1]:getBodyDamage():ReduceGeneralHealth(30*damage)
    -- end

    --print('mindistance: ', mindistance)
    --print('minzb/minpr: ', minzb[1], '/', minpr[1])

    -- returns BOOL on whether zombie or player was hit
    return minzb[1],minpr[1]


end


----------------------------------------------------
--BULLET COLLISION WITH STATIC OBJECTS FUNC SECT---
----------------------------------------------------
-- checks the squares that the bullet travels
-- this function determines whether bullets should "break" meaning they stop, pretty much a collision checker
-- bullet square, dirc, bullet offset, player offset, nonsfx
function Advanced_trajectory.checkiswallordoor(square,angle,bulletPosition,playerPosition,nosfx)
    --print("----SQUARE---: ",   square:getX(), "  //  ", square:getY())

    local bulletPosFloorX = math.floor(bulletPosition[1])
    local bulletPosFloorY = math.floor(bulletPosition[2])

    local playerPosFloorX = math.floor(playerPosition[1])
    local playerPosFloorY = math.floor(playerPosition[2])

    local bulletPosX = bulletPosition[1]
    local bulletPosY = bulletPosition[2]
    local playerPosX = playerPosition[1]
    local playerPosY = playerPosition[2]

    -- direction from -pi to pi OR -180 to 180 deg
    -- N (top left corner): pi,-pi  (180, -180)
    -- W (bottom left): pi/2 (90)
    -- E (top right): -pi/2 (-90)
    -- S (bottom right corner): 0
    --print("angle: ",          angle)
    --print("bulletPosFl: ", bulletPosFloorX, "  //  ", bulletPosFloorY)

    -- walk towards bot right means X+
    -- walk towards bot left means  Y+
    -- walk towards top left means  X-
    -- walk towards top right means Y-
    --print("playerPosFl: ",     playerPosFloorX , "  //  ", playerPosFloorY)

    --print("bulletPos: ",   bulletPosX, "  //  ", bulletPosY)
    --print("playerPos: ",   playerPosX , "  //  ", playerPosY)
    --print("------------------------------------------------------------------")

    -- returns an array of objects in that square, for loop and filter it to get what you want
    local objects = square:getObjects()
    if objects then
        for i=1,objects:size() do

            local locobject = objects:get(i-1)
            local sprite = locobject:getSprite()
            if sprite  then
                local Properties = sprite:getProperties()
                if Properties then

                    local wallN = Properties:Is(IsoFlagType.WallN)
                    local doorN = Properties:Is(IsoFlagType.doorN)

                    local wallNW = Properties:Is(IsoFlagType.WallNW)
                    local wallSE = Properties:Is(IsoFlagType.WallSE)

                    local wallW = Properties:Is(IsoFlagType.WallW)
                    local doorW = Properties:Is(IsoFlagType.doorW)
                    
                    
                    --local doorWallN = Properties:Is(IsoFlagType.doorWallN)
                    --local doorWallW = Properties:Is(IsoFlagType.doorWallW)

                    --[[
                    if wallN or wallNW or wallSE or wallW then
                        print("****Wall N/NW/SE/W****: ", wallN, "/", wallNW, "/", wallSE, "/", wallW)
                        --return true
                    end
                    
                    if doorN or doorW then
                        print("****Door N/W****: ", doorN, "/", doorW)
                    end

                    if doorWallN or doorWallW then
                        print("****doorWallN/doorWallW****: ", doorWallN, "/", doorWallW)
                        --return true
                    end
                    ]]

                    -- if the locoobject is "IsoWindow" which is a class and it's not smashed, smash it
                    if instanceof(locobject,"IsoWindow") and not locobject:isSmashed() and not locobject:IsOpen() then

                        if nosfx then return true end
                        locobject:setSmashed(true)
                        getSoundManager():PlayWorldSoundWav("SmashWindow",square, 0.5, 2, 0.5, true);
                        return true
                    end

                    local isAngleTrue = false

                    if wallNW then
                        --if shooting into corner, then break
                        -- - means player > sq
                        -- + means player < sq
                        if 
                        (angle<=135 and angle>=90) and (playerPosY  < square:getY() or playerPosX  > square:getX()) or
                        (angle<=90 and angle>=0) and (playerPosY  < square:getY() or playerPosX  < square:getX()) or
                        (angle<=0 and angle>=-45) and (playerPosY  > square:getY() or playerPosX  < square:getX())
                        then
                            --print("----Facing outside into wallNW----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        if 
                        (angle>=135 and angle<=180) and (playerPosY  < square:getY() or playerPosX  > square:getX()) or
                        (angle>=-180 and angle<=-90) and (playerPosY  > square:getY() or playerPosX  > square:getX()) or
                        (angle>=-90 and angle<=-45) and (playerPosY  > square:getY() or playerPosX  < square:getX()) 
                        then
                            --print("----Facing inside into wallNW----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end
                    elseif wallSE then
                        if 
                        (angle<=135 and angle>=90) and (playerPosY  < square:getY() or playerPosX  > square:getX()) or
                        (angle<=90 and angle>=0) and (playerPosY  < square:getY() or playerPosX  < square:getX()) or
                        (angle<=0 and angle>=-45) and (playerPosY  > square:getY() or playerPosX  < square:getX())
                        then
                            --print("----Facing inside into wallSE----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        if 
                        (angle>=135 and angle<=180) and (playerPosY  < square:getY() or playerPosX  > square:getX()) or
                        (angle>=-180 and angle<=-90) and (playerPosY  > square:getY() or playerPosX  > square:getX()) or
                        (angle>=-90 and angle<=-45) and (playerPosY  > square:getY() or playerPosX  < square:getX()) 
                        then
                            --print("----Facing outside into wallSE----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end
                    elseif wallN or (doorN and not locobject:IsOpen()) then
                        isAngleTrue = angle <=0 and angle >= -180
                        -- facing east into wallN
                        if (isAngleTrue) and playerPosY  > square:getY() then
                            --print("----Facing EAST into wallN----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        isAngleTrue = angle >=0 and angle <= 180
                        -- facing west into wallN
                        if (isAngleTrue) and playerPosY < square:getY() then
                            --print("----Facing WEST into wallN----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        --print("++++Angle was true for wallN++++")
                    elseif wallW or (doorW and  not locobject:IsOpen()) then
                        isAngleTrue = (angle >=0 and angle <= 90) or (angle <=0 and angle >= -90)
                        -- facing south into wallW
                        if (isAngleTrue) and playerPosX  < square:getX() then
                            --print("----Facing SOUTH into wallW----")

                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        isAngleTrue = (angle >=90 and angle <= 180) or (angle <=-90 and angle >= -180)
                        -- facing north into wallW
                        if (isAngleTrue) and playerPosX  > square:getX() then
                            --print("----Facing NORTH into wallW----")
                            if nosfx then return true end
                            getSoundManager():PlayWorldSoundWav("BreakObject",square, 0.5, 2, 0.5, true);
                            return true
                        end

                        --print("++++Angle was true for wallW++++")
                    end
                    

                end
            end
        end
    end

    local player = getPlayer()
    local playervehicle 
    if player then
        playervehicle = player:getVehicle()
    end

    local squarecar = playervehicle or square:getVehicleContainer()
    -- local squarecar2
    -- local player = getPlayer()
    -- if player then
    --     local vehsq = player:getCurrentSquare()
    --     if vehsq then
    --         squarecar2 = vehsq:getVehicleContainer()
    --     end
    -- end
    
    if squarecar and ((squarecar:getX() -playerPosition[1] )^2  + (squarecar:getY() -playerPosition[2])^2)  >8 then


        if nosfx then return true end


        if ((squarecar:getX() -bulletPosition[1] )^2  + (squarecar:getY() -bulletPosition[2])^2) < 2.8  then

            if getSandboxOptions():getOptionByName("AT_VehicleDamageenable"):getValue() then

                
                squarecar:HitByVehicle(squarecar, 0.3)
                
            end
            return true
            
        end 
        
        
    end

    
end

-----------------------------------
--EXPLOSION LOGIC ?? FUNC SECT---
-----------------------------------
function Advanced_trajectory.boomontick()

    local tablenow = Advanced_trajectory.boomtable
    for kt,vt in pairs(tablenow) do

        for kz,vz in pairs(vt[12]) do
            Advanced_trajectory.itemremove(vt[12][vt[3] - vt[13]])
        end

        if vt[3] > vt[2] + vt[13] then
            tablenow[kt] = nil
            break
        end

        if vt[3]== 1 and  vt[7]==0 then 


            local itemornone = Advanced_trajectory.additemsfx(vt[5],vt[1]..tostring(vt[3]),vt[4][1],vt[4][2],vt[4][3])
            table.insert(vt[12],itemornone)
            vt[3]=vt[3]+1
        elseif vt[7] > vt[6] and vt[3] <= vt[2] then
            vt[7] = 0

            local itemornone = Advanced_trajectory.additemsfx(vt[5],vt[1]..tostring(vt[3]),vt[4][1],vt[4][2],vt[4][3])
            table.insert(vt[12],itemornone)
            vt[3]=vt[3]+1
        elseif vt[7] > vt[6] then
            vt[7] = 0 
            vt[3]=vt[3]+1
        end
            
        vt[7] = vt[7] + getGameTime():getMultiplier()

    end


end

-----------------------------------
--EXPLOSION FX ?? FUNC SECT---
-----------------------------------
function Advanced_trajectory.boomsfx(sq,sfxName,sfxNum,ticktime)
    -- print(sq)
    local sfxname = sfxName or"Base.theMH_MkII_SFX"
    local sfxnum = sfxNum or 12
    local nowsfxnum =1
    local sfxcount = 0
    local pos = {sq:getX(), sq:getY() ,sq:getZ()}
    local square = sq
    local ticktime = ticktime or 3.5
    local func = function() return end
    local varz1,varz2,varz3
    local item = {}
    local offset = 3

    local tablesfx = {

        sfxname,         ---1
        sfxnum,          ---2
        nowsfxnum,       ---3
        pos,             ---4
        square,          ---5
        ticktime,        ---6
        sfxcount,        ---7
        func,            ---8
        varz1,           ---9
        varz2,           ---10
        varz3,           ---11
        item,            ---12
        offset           ---13滞后
    }

    table.insert(Advanced_trajectory.boomtable,tablesfx)
end

-----------------------------------
--AIMNUM/BLOOM LOGIC FUNC SECT---
-----------------------------------
function Advanced_trajectory.OnPlayerUpdate()

    

    local player = getPlayer() 
    if not player then return end
    local weaitem = player:getPrimaryHandItem()

    -- local isspwaepon = 



    if  player:isAiming() and instanceof(weaitem,"HandWeapon") and (((weaitem:isRanged() and getSandboxOptions():getOptionByName("Advanced_trajectory.Enablerange"):getValue()) or (weaitem:getSwingAnim() =="Throw" and getSandboxOptions():getOptionByName("Advanced_trajectory.Enablethrow"):getValue())) or Advanced_trajectory.Advanced_trajectory[weaitem:getFullType()]) then
       
        if getSandboxOptions():getOptionByName("Advanced_trajectory.showOutlines"):getValue() then
            weaitem:setMaxHitCount(1)
        else
            weaitem:setMaxHitCount(0)
        end

        Mouse.setCursorVisible(false)
        

        -- print(getPlayer():getCoopPVP())

        local hasChainsaw = string.contains(weaitem:getAmmoType() or "","FlameFuel")

        local level = 11-player:getPerkLevel(Perks.Aiming)
        local realLevel = player:getPerkLevel(Perks.Aiming)

        local gametimemul = getGameTime():getMultiplier() * 16/(level+10)
        Advanced_trajectory.maxaimnum = weaitem:getAimingTime() + level*7 + getSandboxOptions():getOptionByName("Advanced_trajectory.maxaimnum"):getValue() 

        -- max level = 10 - x * 3 = 27
        -- x = 1 (max)
        -- x = 11 (min)
        -- level is reversed (low to high level is 11 to 1)
        -- 4 is a good modifier, lv 7 and above and guns are very useful for long range, below and you're stuck with shotguns or close range
        local minaimnumModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.minaimnumModifier"):getValue() 

        local realMin = (level - 1) * minaimnumModifier
        if realLevel > 8 then
            realMin = 0 
        end

        ------------------------
        -- MOODLE LEVELS SECT--
        ------------------------
        -- level 0 to 4 (least to severe)
        local stressLv = player:getMoodles():getMoodleLevel(MoodleType.Stress) -- inc minaimnum
        local enduranceLv = player:getMoodles():getMoodleLevel(MoodleType.Endurance) -- inc minaimnum, dec aim speed
        local panicLv = player:getMoodles():getMoodleLevel(MoodleType.Panic) -- transparency
        local drunkLv = player:getMoodles():getMoodleLevel(MoodleType.Drunk) -- scaling and pos

        
        local hyperLv = player:getMoodles():getMoodleLevel(MoodleType.Hyperthermia) -- dec aim speed
        local hypoLv = player:getMoodles():getMoodleLevel(MoodleType.Hypothermia) -- dec aim speed
        local tiredLv = player:getMoodles():getMoodleLevel(MoodleType.Tired) -- dec aim speed

        -----------------------------------
        --TRUE CROUCH/CRAWL (FIRST) SECT---
        -----------------------------------
        if player:getVariableBoolean("IsCrouchAim") and realLevel < 3 then
            realMin = realMin - 15
        end

        if player:getVariableBoolean("isCrawling") and realLevel < 3 then
            realMin = realMin - 25
        end

        ------------------------
        ------ STRESS SECT------
        ------------------------
        local stressBloomModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.stressBloomModifier"):getValue() 
        local stressVisualModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.stressVisualModifier"):getValue() 
        -- no effects for lv 1 stress
        if stressLv > 1 then
            Advanced_trajectory.stressEffect = stressVisualModifier * stressLv * (1/((realLevel+1)/2))
        else
            Advanced_trajectory.stressEffect = 0
        end

        if stressLv > 1 and realLevel < 3 then
            realMin = realMin + (stressBloomModifier * stressLv)
        end

        ------------------------
        ------ DRUNK SECT------
        ------------------------
        local drunkModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.drunkModifier"):getValue() 
        local tmpMaxaimnum = Advanced_trajectory.maxaimnum + drunkModifier*drunkLv
        if drunkLv > 0 then
            Advanced_trajectory.maxaimnum = tmpMaxaimnum
        end

        ----------------------------
        -- HYPER, HYPO, TIRED SECT--
        ----------------------------
        -- SPEED EFFECTS (must be greater than 0, higher number means less effect)
        -- considering that you can only get hypo or hyper, there are mainly 2 moodles that can stack (temp and tired)
        -- can either stack to -100% if full severity with 0s
        -- all 1s mean stack -66%
        -- all 0s mean stack -100%
        local hyperHypoModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.hyperHypoModifier"):getValue() 
        local tiredModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.tiredModifier"):getValue() 

        -- with default modifiers of 1, it should total up to 1
        local speed = getSandboxOptions():getOptionByName("Advanced_trajectory.reducespeed"):getValue() 
        local reduceSpeed = speed 

        -- needs to subtract at most 1/3 --> 1/(x-4) = 1/3
        -- no effects for lv 1 temp serverity
        if hyperLv > 1 then
            reduceSpeed = reduceSpeed - (speed * 1/(hyperHypoModifier + 6-hyperLv))
        end

        if hypoLv > 1 then
            reduceSpeed = reduceSpeed - (speed * 1/(hyperHypoModifier + 6-hypoLv))
        end

        if tiredLv > 0 then
            reduceSpeed = reduceSpeed - (speed * 1/(tiredModifier + 6-tiredLv))
        end

        ----------------------------
        -- ARMS, HANDS DAMAGE SECT--
        ----------------------------
        local bodyDamage = player:getBodyDamage()
        
        -- PAIN VARIABLES float values (0 - 200)
        -- 30 lv1, 50 lv2, 100 lv3, 150-200 lv 4
        -- def reduceSpeed for all aim levels: 1.1
        local handPainL = bodyDamage:getBodyPart(BodyPartType.Hand_L):getPain()   
        local forearmPainL = bodyDamage:getBodyPart(BodyPartType.ForeArm_L):getPain()  
        local upperarmPainL = bodyDamage:getBodyPart(BodyPartType.UpperArm_L):getPain()  

        local handPainR = bodyDamage:getBodyPart(BodyPartType.Hand_R):getPain()  
        local forearmPainR = bodyDamage:getBodyPart(BodyPartType.ForeArm_R):getPain()  
        local upperarmPainR = bodyDamage:getBodyPart(BodyPartType.UpperArm_R):getPain()  

        local totalPain = handPainL + forearmPainL + upperarmPainL + handPainR + forearmPainR + upperarmPainR
        local painModifider = getSandboxOptions():getOptionByName("Advanced_trajectory.painModifier"):getValue() 
        reduceSpeed =  reduceSpeed - painModifider * totalPain/2 

        local minReduceSpeed = 0.1
        if reduceSpeed < minReduceSpeed then
            reduceSpeed = minReduceSpeed
        end 

        ------------------------
        -- SNEEZE, COUGH SECT---
        ------------------------
        -- returns 1 (sneeze) or 2 (cough)  
        local isSneezeCough = bodyDamage:getSneezeCoughActive() 
        local coughModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.coughModifier"):getValue() 

        -- COUGHING: Add onto aimnum, adds way too much for some reason (goes over maxaimnum ex. goes to 64 when max is 50)
        -- use gametime or else value goes wild (value would be added through framerate and not gametimewhich is not accurate)
        --print("coughEffect: ", coughEffect)
        if isSneezeCough == 2 then
            if Advanced_trajectory.aimnum < Advanced_trajectory.maxaimnum then
                Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + coughModifier*gametimemul
            end
            Advanced_trajectory.maxFocusCounter = 100
        end

        -- SNEEEZING: Reset aimnum
        if isSneezeCough == 1 then
            if Advanced_trajectory.aimnum < Advanced_trajectory.maxaimnum then
                Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + 4*gametimemul
            end
            Advanced_trajectory.maxFocusCounter = 100
        end

        ------------------------ ------------------------ ------------------------ 
        -- AIMNUM LIMITER SECT [ALL REALMIN CHANGES MUST BE DONE BEFORE THIS LINE]-
        ------------------------ ------------------------ ------------------------ 
        if hasChainsaw then
            reduceSpeed = 100
            realMin = 0
            Advanced_trajectory.maxaimnum = 1
            realLevel = 10
        end

        -- if counter is not used, keep minaimnum as is
        if Advanced_trajectory.maxFocusCounter >= 100 and Advanced_trajectory.minaimnum ~= realMin  then
            Advanced_trajectory.minaimnum = Advanced_trajectory.minaimnum + 2*gametimemul
            if Advanced_trajectory.minaimnum > realMin then
                Advanced_trajectory.minaimnum = realMin
            end
        end

        if Advanced_trajectory.minaimnum > Advanced_trajectory.maxaimnum then
            Advanced_trajectory.minaimnum = Advanced_trajectory.maxaimnum
        end

        if Advanced_trajectory.aimnum > Advanced_trajectory.maxaimnum then
            Advanced_trajectory.aimnum = Advanced_trajectory.maxaimnum
        end

        ------------------------
        ----- ENDURANCE SECT----
        ------------------------
        --local isInhale = false
        --local isExhale = false

        local enduranceBreathModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.enduranceBreathModifier"):getValue() 
        local inhaleModifier1 = getSandboxOptions():getOptionByName("Advanced_trajectory.inhaleModifier1"):getValue() 
        local inhaleModifier2 = getSandboxOptions():getOptionByName("Advanced_trajectory.inhaleModifier2"):getValue() 
        local inhaleModifier3 = getSandboxOptions():getOptionByName("Advanced_trajectory.inhaleModifier3"):getValue() 
        local inhaleModifier4 = getSandboxOptions():getOptionByName("Advanced_trajectory.inhaleModifier4"):getValue() 

        local exhaleModifier1 = getSandboxOptions():getOptionByName("Advanced_trajectory.exhaleModifier1"):getValue() 
        local exhaleModifier2 = getSandboxOptions():getOptionByName("Advanced_trajectory.exhaleModifier2"):getValue() 
        local exhaleModifier3 = getSandboxOptions():getOptionByName("Advanced_trajectory.exhaleModifier3"):getValue() 
        local exhaleModifier4 = getSandboxOptions():getOptionByName("Advanced_trajectory.exhaleModifier4"):getValue() 

        if enduranceLv > 0 and Advanced_trajectory.aimnum < Advanced_trajectory.minaimnum+(enduranceLv*3) and Advanced_trajectory.inhaleCounter <= 0 and Advanced_trajectory.exhaleCounter <= 0 then
            Advanced_trajectory.inhaleCounter = 100
        end

        -- inhale, count from 100 to 0
        local constantTime = getGameTime():getMultiplier() * 16/(1+10)
        if Advanced_trajectory.inhaleCounter > 0 then
            --isInhale = true
            --isExhale = false

            -- three diff levels of inhale and exhale speed
            if enduranceLv == 1 then
                Advanced_trajectory.inhaleCounter = Advanced_trajectory.inhaleCounter - inhaleModifier1*constantTime
            end
            if enduranceLv == 2 then
                Advanced_trajectory.inhaleCounter = Advanced_trajectory.inhaleCounter - inhaleModifier2*constantTime
            end
            if enduranceLv == 3 then
                Advanced_trajectory.inhaleCounter = Advanced_trajectory.inhaleCounter - inhaleModifier3*constantTime
            end
            if enduranceLv == 4 then
                Advanced_trajectory.inhaleCounter = Advanced_trajectory.inhaleCounter - inhaleModifier4*constantTime
            end

            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + enduranceBreathModifier*constantTime

        elseif Advanced_trajectory.inhaleCounter <= 0 and Advanced_trajectory.exhaleCounter <= 0 then
            Advanced_trajectory.exhaleCounter = 100
        end

        -- exhale, steady aim
        if Advanced_trajectory.exhaleCounter > 0 then
            --isInhale = false
            --isExhale = true

            -- higher endurance level means less time to have steady aim
            -- three diff levels of inhale and exhale speed
            if enduranceLv == 1 then
                Advanced_trajectory.exhaleCounter = Advanced_trajectory.exhaleCounter - exhaleModifier1*constantTime
            end
            if enduranceLv == 2 then
                Advanced_trajectory.exhaleCounter = Advanced_trajectory.exhaleCounter - exhaleModifier2*constantTime
            end
            if enduranceLv == 3 then
                Advanced_trajectory.exhaleCounter = Advanced_trajectory.exhaleCounter - exhaleModifier3*constantTime
            end
            if enduranceLv == 4 then
                Advanced_trajectory.exhaleCounter = Advanced_trajectory.exhaleCounter - exhaleModifier4*constantTime
            end
        end
      
        if enduranceLv == 0 then
            Advanced_trajectory.inhaleCounter = 0
            Advanced_trajectory.exhaleCounter = 0
        end

        --print("inhaleCounter / exhaleCounter: ", Advanced_trajectory.inhaleCounter, " / ", Advanced_trajectory.exhaleCounter)
        --print("isInhale / isExhale: ", isInhale, " / ", isExhale)
        
        ----------------------------
        -- TURNING AND MOVING SECT--
        ----------------------------
        local drunkActionEffectModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.drunkActionEffectModifier"):getValue() 
        if player:getVariableBoolean("isMoving") then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum +gametimemul*getSandboxOptions():getOptionByName("Advanced_trajectory.moveeffect"):getValue()*((drunkLv*drunkActionEffectModifier)+1)
            Advanced_trajectory.maxFocusCounter = 100
        end
        

        if player:getVariableBoolean("isTurning") then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum +gametimemul*getSandboxOptions():getOptionByName("Advanced_trajectory.turningeffect"):getValue()*((drunkLv*drunkActionEffectModifier)+1)
            Advanced_trajectory.maxFocusCounter = 100
        end

        ----------------------------------
        -----RELOADING AND RACKING SECT---
        ----------------------------------
        local reloadlevel = 11-player:getPerkLevel(Perks.Reload)
        local reloadEffectModifier =  getSandboxOptions():getOptionByName("Advanced_trajectory.reloadEffectModifier"):getValue() 
        if player:getVariableBoolean("isUnloading") or player:getVariableBoolean("isLoading") or player:getVariableBoolean("isLoadingMag") or player:getVariableBoolean("isRacking") then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum +constantTime*reloadEffectModifier*reloadlevel
            Advanced_trajectory.alpha = Advanced_trajectory.alpha - gametimemul*0.1
            Advanced_trajectory.maxFocusCounter = 100
        end           

        ----------------------------
        ------- AIMNUM SECT---------
        ----------------------------
        if player:getVariableBoolean("IsCrouchAim") then
            reduceSpeed = reduceSpeed + getSandboxOptions():getOptionByName("Advanced_trajectory.crouchReduceSpeedBuff"):getValue() 
        end

        if player:getVariableBoolean("isCrawling") then
            reduceSpeed = reduceSpeed + getSandboxOptions():getOptionByName("Advanced_trajectory.proneReduceSpeedBuff"):getValue() 
        end

        ----------------------
        --REDDOT AIMING BUFF--
        ----------------------
        local scope = weaitem:getScope()
        if scope then
            if scope:getAimingTime() > 0 then
                reduceSpeed = reduceSpeed * 1.3
            end
        end

        if Advanced_trajectory.aimnum > Advanced_trajectory.minaimnum then
            Advanced_trajectory.aimnum = Advanced_trajectory.aimnum -gametimemul*reduceSpeed
            -- print(gametimemul)
        end

        
        if Advanced_trajectory.aimnum < Advanced_trajectory.minaimnum then
            Advanced_trajectory.aimnum = Advanced_trajectory.minaimnum
        end

        ------------------------
        ---FOCUS MECHANIC SECT---
        ------------------------
        -- if minaimnum is reached, start counting down to 0
        -- If player moves or shoots (aimnum increases), reset counter and minaimnum.
        local maxFocusSpeed = getSandboxOptions():getOptionByName("Advanced_trajectory.maxFocusSpeed"):getValue() 

        -- max recoil delay is 100 (sniper), 50 (shotgun), 20-30 (pistol), 0 (m16/m14)
        -- lower means slower
        local recoilDelay = weaitem:getRecoilDelay() 
        local recoilDelayModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.recoilDelayModifier"):getValue() 
        local focusCounterSpeed = getSandboxOptions():getOptionByName("Advanced_trajectory.focusCounterSpeed"):getValue() 
        focusCounterSpeed = focusCounterSpeed - (recoilDelay * recoilDelayModifier)
        local focusLevelGained = 3

        -- player starts focusing faster once reaching level 5
        if realLevel >= 5 then
            focusCounterSpeed = (2 + level/10)*focusCounterSpeed
        end

        ----------------------
        --LASER SPEED BUFF----
        ----------------------
        local canon = weaitem:getCanon()
        if canon then
            if canon:getHitChance() > 0 then
                focusCounterSpeed = focusCounterSpeed * 1.3
            end
        end

        ----------------------
        --STOCK SPEED BUFF----
        ----------------------
        local stock = weaitem:getStock()
        if stock then
            if stock:getHitChance() > 0 then
                focusCounterSpeed = focusCounterSpeed * 1.3
            end
        end

        ----------------------
        --RECOIL PAD BUFF-----
        ----------------------
        local recoilPad = weaitem:getRecoilpad()
        if recoilPad then
            focusCounterSpeed = focusCounterSpeed * 1.3
        end

        local focusLimit = 0
        if stressLv > 1 and realLevel >= focusLevelGained then
            focusLimit = realMin * (1/(5-stressLv))
        end

        --print('realMin: ', realMin)

        -- Prone stance means faster focus time
        local proneFocusCounterSpeedBuff = getSandboxOptions():getOptionByName("Advanced_trajectory.proneFocusCounterSpeedBuff"):getValue() 
        if player:getVariableBoolean("isCrawling") and realLevel >= focusLevelGained then
            focusCounterSpeed = focusCounterSpeed * 1.5
            focusLimit = focusLimit * 0.30
        end

        if player:getVariableBoolean("IsCrouchAim") and realLevel >= focusLevelGained then
            focusLimit = focusLimit * 0.60
        end

        -- coruching means no need to wait to get to 0 when below minaimnum (helpful when bursting)
        if (player:getVariableBoolean("IsCrouchAim") or player:getVariableBoolean("isCrawling")) and realLevel >= focusLevelGained then
            if Advanced_trajectory.aimnum < (20 - (recoilDelay/10)) then
                Advanced_trajectory.maxFocusCounter = 0
            end
        end
        
        --print('canBurst: ', canBurst)

        -- if player crouches or prones (True Crawl and True Prone), then max focus
        -- player unlocks max focus skill for stnading when reaching certain level
        if Advanced_trajectory.aimnum <= Advanced_trajectory.minaimnum and Advanced_trajectory.maxFocusCounter > 0 and realLevel >= focusLevelGained then
            Advanced_trajectory.maxFocusCounter = Advanced_trajectory.maxFocusCounter -focusCounterSpeed*constantTime
        end

        -- counter can not go below 0
        if Advanced_trajectory.maxFocusCounter < 0 then
            Advanced_trajectory.maxFocusCounter = 0
        end

        -- if counter reaches 0, reduce minaimnum until its no longer greater than 0
        if Advanced_trajectory.maxFocusCounter <= 0  and Advanced_trajectory.minaimnum > focusLimit then
            Advanced_trajectory.minaimnum = Advanced_trajectory.minaimnum -gametimemul*maxFocusSpeed
        end

        --print('maxFocusCounter: ', Advanced_trajectory.maxFocusCounter)

        if Advanced_trajectory.minaimnum < focusLimit then
            Advanced_trajectory.minaimnum = Advanced_trajectory.minaimnum + gametimemul

            if Advanced_trajectory.minaimnum > focusLimit then
                Advanced_trajectory.minaimnum = focusLimit
            end
        end

        -------------------------------
        -------- PANIC (END) SECT-----
        -------------------------------
        -- needs to be between max and min or else crosshair just disappears if ur aim is dog
        -- place after other minaimnum effects
        local panicModifierAlpha = 1

        local limit = 0
        if panicLv == 4 then
            limit = 0
        elseif panicLv == 3 then
            limit = realMin
        else
            limit = realMin + (Advanced_trajectory.maxaimnum - realMin)*panicModifierAlpha*(1/panicLv)
        end

        if panicLv > 1 then
            if Advanced_trajectory.aimnum <= limit then
                Advanced_trajectory.alpha = Advanced_trajectory.alpha + gametimemul*0.05
            else
                Advanced_trajectory.alpha = Advanced_trajectory.alpha - gametimemul*0.1
            end
        else
            Advanced_trajectory.alpha = Advanced_trajectory.alpha + gametimemul*0.025
        end
    
        if Advanced_trajectory.alpha > 0.6 then
            Advanced_trajectory.alpha = 0.6
        end

        if Advanced_trajectory.alpha < 0 then
            Advanced_trajectory.alpha = 0
        end

        --print("Trans/Alpha: ", Advanced_trajectory.alpha)

        --print("TotalPain/Effected: ", totalPain, "/", totalPain * painModifider, ", HL", handPainL ,", FL", forearmPainL ,", UL", upperarmPainL ,", HR", handPainR ,", FR", forearmPainR ,", UR", upperarmPainR)
        --print("isSneezeCough: ", isSneezeCough)
        --print("P", panicLv, ", E", enduranceLv ,", H", hyperLv ,", H", hypoLv ,", S", stressLv,", T", tiredLv)
        --print("Aim Level (code): ", level)
        --print("Aim Level (real): ", realLevel)
        --print("Def/Curr ReduceSpeed: ", speed, "/", reduceSpeed)
        --print("Min/Max/Aimnum: ",Advanced_trajectory.minaimnum, " / ", Advanced_trajectory.maxaimnum, " / ", Advanced_trajectory.aimnum)   
        --------------------------------------------------------------------
        if not Advanced_trajectory.panel.instance and  getSandboxOptions():getOptionByName("Advanced_trajectory.aimpoint"):getValue()  then
            Advanced_trajectory.panel.instance = Advanced_trajectory.panel:new(0,0,200,200)
            Advanced_trajectory.panel.instance:initialise()
            Advanced_trajectory.panel.instance:addToUIManager() 
        end

        local isspwaepon = Advanced_trajectory.Advanced_trajectory[weaitem:getFullType()]

        if weaitem:getSwingAnim() =="Throw"  or (isspwaepon and isspwaepon["islightsq"]) then

            weaitem:setPhysicsObject(nil)  
            weaitem:setMaxHitCount(0)

            --getPlayer():getPrimaryHandItem():getSmokeRange()

            if not Advanced_trajectory.aimcursor then
                -- Advanced_trajectory.thorwerinfo = {
                --     weaitem:getSmokeRange(),
                --     weaitem:getExplosionPower(),
                --     weaitem:getExplosionRange(),
                --     weaitem:getFirePower(),
                --     weaitem:getFireRange()
                -- }
                Advanced_trajectory.aimcursor = ISThorowitemToCursor:new("", "", player,weaitem)
                getCell():setDrag(Advanced_trajectory.aimcursor, 0)
            end
        end 


        local dx = getMouseXScaled();
        local dy = getMouseYScaled();
        local playerZ = math.floor(player:getZ())


        local isaimobject =false

        for Z=0,7 do

            -- print(dx,"---",x)
            local deldis = Z - playerZ


            local wx, wy = ISCoordConversion.ToWorld(dx-3*deldis, dy-3*deldis, Z);
            wx = math.floor(wx);
            wy = math.floor(wy);
        
            
        
            local cell = getWorld():getCell();
            


            for yz=-1,1 do




                for lz = -1 ,1 do


                    local sq = cell:getGridSquare(wx+2.2 + yz, wy+2.2 + lz, Z);
                    if sq then

                        local movingObjects = sq:getMovingObjects()
                        -- print(movingObjects)
        
                        for zz=1,movingObjects:size() do
                            local zombiez = movingObjects:get(zz-1)
                            -- print(zombiez)
                            if instanceof(zombiez,"IsoZombie") then
        
        
                                -- player:Say("get"..tostring(Z))
        
                                Advanced_trajectory.aimlevels = Z
        
                                isaimobject = true
        
                                return 
        
        
        
                            
                            elseif instanceof(zombiez,"IsoPlayer") then
        
                                -- player:Say("get"..tostring(Z))
        
                                Advanced_trajectory.aimlevels = Z
                                isaimobject = true
                                return
                                
        
        
        
                            end
                        end
                    end
                

                end
            

            end

            

            

            if not isaimobject then
                Advanced_trajectory.aimlevels = nil
                
            end

        

        end

        -- print(Advanced_trajectory.aimlevels)
        





      

        
        
    else 
        if Advanced_trajectory.aimcursor then
            getCell():setDrag(nil, 0);
            Advanced_trajectory.aimcursor=nil
            Advanced_trajectory.thorwerinfo={}
        end
        if Advanced_trajectory.panel.instance then
            Advanced_trajectory.panel.instance:removeFromUIManager()
            Advanced_trajectory.panel.instance=nil
        end
        local constantTime = getGameTime():getMultiplier() * 16/(1+10)
        local nonAdsEffect = 2
        Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + constantTime
        Advanced_trajectory.maxFocusCounter = 100
        Advanced_trajectory.alpha = 0
        

    end
end

Advanced_trajectory.damagedisplayer = {}

-----------------------------------
--BODY PART LOGIC FUNC SECT---
-----------------------------------
function Advanced_trajectory.checkontick()

    Advanced_trajectory.boomontick()
    Advanced_trajectory.OnPlayerUpdate()


    local timemultiplier = getGameTime():getMultiplier()

    for la,lb in pairs(Advanced_trajectory.damagedisplayer) do

        lb[1] = lb[1] - timemultiplier
        if lb[1] < 0 then
            lb = nil
        else

            lb[3] = lb[3] + timemultiplier
            lb[4] = lb[4] - timemultiplier
            lb[2]:AddBatchedDraw(lb[3], lb[4], true)

            -- print(Advanced_trajectory.damagedisplayer[3] - Advanced_trajectory.damagedisplayer[5])
            
        end
    
    
    end


    -- if  then

    --     -- Advanced_trajectory.damagedisplayer = {1,damagea,sx,sy,1,1}



    --     Advanced_trajectory.damagedisplayer[1] = Advanced_trajectory.damagedisplayer[1] 


    --     if Advanced_trajectory.damagedisplayer[1] < 0 then
    --         Advanced_trajectory.damagedisplayer = nil
    --     else

    --         Advanced_trajectory.damagedisplayer[3] = Advanced_trajectory.damagedisplayer[3] + timemultiplier
    --         Advanced_trajectory.damagedisplayer[4] = Advanced_trajectory.damagedisplayer[4] - timemultiplier

    --         -- if (Advanced_trajectory.damagedisplayer[3] - Advanced_trajectory.damagedisplayer[5])<15 then
                
                
    --         -- end
            
    
    --         Advanced_trajectory.damagedisplayer[2]:AddBatchedDraw(Advanced_trajectory.damagedisplayer[3], Advanced_trajectory.damagedisplayer[4], true)

    --         -- print(Advanced_trajectory.damagedisplayer[3] - Advanced_trajectory.damagedisplayer[5])
            
    --     end

        
        
    -- end


    


    local tablenow = Advanced_trajectory.table
    -- print(#tablenow)
    -- print(getGameTime():getMultiplier())
    for kt,vt in pairs(tablenow) do

        



        Advanced_trajectory.itemremove(vt[1])
        

        local tablenowz12_ = vt[12]*0.35


        
        -- local avenfps = getAverageFPS()
        -- if avenfps >=60 then
        --     avenfps=60   
        -- end
        -- tablenowz12_ = vt[12]*60/avenfps
        
        -- RADON NOTES: PERHAPS THIS DETERMINES IF BULLET SHOULD DISAPPEAR/BREAK IF COLLIDE WITH SOMETHING
        vt[2]=getWorld():getCell():getOrCreateGridSquare(vt[4][1],vt[4][2],vt[4][3])
        vt[22]["pos"] = {Advanced_trajectory.mathfloor(vt[4][1]),Advanced_trajectory.mathfloor(vt[4][2])}
        if vt[2] then
            -- bullet square, dirc, offset, offset, nonsfx
            if Advanced_trajectory.checkiswallordoor(vt[2],vt[5],vt[4],vt[20],vt["nonsfx"]) and not vt[15] then

                --print("Wallcarmouse: ", vt["wallcarmouse"])
                --print("Wallcarzombie: ", vt["wallcarzombie"])
                --print("Cell: ", vt[4][1],", ",vt[4][2],", ",vt[4][3])
                if  vt[9] =="Grenade" or vt["wallcarmouse"] or vt["wallcarzombie"]then

                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    if not vt["nonsfx"]  then
                        -- print("Boom")
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                    
                end
                Advanced_trajectory.itemremove(vt[1]) 
                tablenow[kt]=nil
                break
            end

            local mathfloor = Advanced_trajectory.mathfloor


            vt[1] = Advanced_trajectory.additemsfx(vt[2],vt[14]..tostring(vt[8]),mathfloor(vt[4][1]),mathfloor(vt[4][2]),mathfloor(vt[4][3]))
            local spnumber = (vt[3][1]^2 + vt[3][2]^2)^0.5*tablenowz12_
            vt[7]=vt[7]-spnumber
            vt[17] = vt[17]+ spnumber

            if vt[9] == "flamethrower" then

                -- print(vt[17])
                if vt[17] >3 then
                    vt[17] = 0
                    vt[21]=vt[21]+1
                    vt[4] = Advanced_trajectory.twotable(vt[20])
                end
                -- print(vt[21])
                if vt[21] >4 then
                    Advanced_trajectory.itemremove(vt[1]) 
                    tablenow[kt]=nil
                    break
                end
            
            elseif vt[7]<0 and vt[9] ~= "Grenade"  then

                -- if (vt[22][2]or 0 )> 0 then 
                --     Advanced_trajectory.boomsfx(vt[2])
                -- end


                if vt["wallcarmouse"] or vt["wallcarzombie"]then

                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    if not vt["nonsfx"]  then
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                end



                Advanced_trajectory.itemremove(vt[1])
                tablenow[kt]=nil
                break
            end

            vt[5] = vt[5]+vt[10]
            if vt[1] then
                vt[1]:setWorldZRotation(vt[5])
            -- elseif vt[9] ~= "Grenade" then
            --     -- Advanced_trajectory.itemremove(vt[1]) 
            --     tablenow[kt]=nil
            --     break
            end

            vt[4][1] = vt[4][1]+tablenowz12_*vt[3][1]
            vt[4][2] = vt[4][2]+tablenowz12_*vt[3][2]

            -- print(kt,"a-----a",vt[4])
            -- print(kt,"a-----a",vt[3][1])

            -- print(kt,"-=--",tablenowz12_*vt[3][2])
            -- vt[21]= vt[21]+tablenowz12_*vt[3][2]
            -- print(kt,"-=--",vt[21])
            -- -- vt[21] = vt[21]+1


            if  vt["isparabola"]  then

                vt[4][3] = 0.5-vt["isparabola"]*vt[17]*(vt[17]-vt[18])
                
                if vt[4][3]<=0.3  then
                    if not vt["nonsfx"]  then
                        Advanced_trajectory.Boom(vt[2],vt[22])
                    end
                    
                    if vt[22][2] > 0 then
                        Advanced_trajectory.boomsfx(vt[2],vt["boomsfx"][1],vt["boomsfx"][2],vt["boomsfx"][3])
                    end
                    Advanced_trajectory.itemremove(vt[1])
                    tablenow[kt]=nil
                    break
                end

            -- elseif  vt[9] =="GrenadeLauncher" then
            --     vt[4][3] = 0.5-0.02*vt[17]*(vt[17]-vt[18])
            --     if vt[4][3] <=0.5  then
            --         Advanced_trajectory.boomsfx(vt[2])
            --         Advanced_trajectory.itemremove(vt[1])
            --         tablenow[kt]=nil
            --         break
            --     end
            end

            --print("Wallcarmouse: ", vt["wallcarmouse"])
            --print("Wallcarzombie: ", vt["wallcarzombie"])
            --print("Cell: ", vt[4][1],", ",vt[4][2],", ",vt[4][3])

            -- NOTES IMPORTANT, WORK HERE: Headshot, Bodypart, Footpart
            if  (vt[9] ~= "Grenade" or (vt[22][8]or 0) > 0 or vt["wallcarzombie"]) and  not vt["wallcarmouse"]then
                
                -- bool value of whether players can damage each other with bullets
                local isshotplayer = getSandboxOptions():getOptionByName("Advanced_trajectory.EnablePlayerDamage"):getValue()

                -- direction of bullet
                local angleammo = vt[5]

                -- offset of bullet
                local angleammooff = 0

                if angleammo >=135 and angleammo<=180 then
                    angleammooff = angleammo - 135
                elseif angleammo >=-180 and angleammo<=-135 then
                    angleammooff = angleammo+180 +45
                elseif angleammo >=-135 and angleammo<=-45 then
                    angleammooff = -angleammo - 45 
                end

                angleammooff = angleammooff/30

                --print('angleammo: ', angleammo)
                --print('angleammooff: ', angleammooff)
               

                local admindel = vt["animlevels"] - math.floor(vt[4][3])
                local shootlevel =  vt[4][3] + admindel

                if  vt["isparabola"] then
                    
                    shootlevel  = vt[4][3]
                end
                    
                --print('admindel (for x and y): ', admindel)
                --print('shootlevel (z): ', shootlevel)

                local Playershot

                -- returns object zombie and player that was shot
                local Zombie,Playershot =  Advanced_trajectory.getShootzombie({vt[4][1] + admindel*3,vt[4][2]  + admindel*3,shootlevel},1 +angleammooff ,isshotplayer)
                
                -- NOTES: damagezb is the damage done to zombies
                local headShotDmgZomMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.headShotDmgZomMultiplier"):getValue()
                local bodyShotDmgZomMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.bodyShotDmgZomMultiplier"):getValue()
                local footShotDmgZomMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.footShotDmgZomMultiplier"):getValue()

                local headShotDmgPlayerMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.headShotDmgPlayerMultiplier"):getValue()
                local bodyShotDmgPlayerMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.bodyShotDmgPlayerMultiplier"):getValue()
                local footShotDmgPlayerMultiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.footShotDmgPlayerMultiplier"):getValue()

                -- headshot on zombie
                local damagezb = 0

                -- headshot damage multiplier on player (will be multiplied by vt6 in player's if statement)
                local damagepr = 0

                local saywhat = ""

                -- steady aim wins the game, else bodyshot damage 
                if Advanced_trajectory.aimnumBeforeShot <= 5 then
                    damagezb = headShotDmgZomMultiplier * vt[6]*0.1
                    damagepr = headShotDmgPlayerMultiplier
                    saywhat = "IGUI_Headshot (STRONG): " .. Advanced_trajectory.aimnumBeforeShot 
                else
                    damagezb = bodyShotDmgZomMultiplier*vt[6]*0.1
                    damagepr = bodyShotDmgPlayerMultiplier
                    saywhat = "IGUI_Headshot (WEAK): " .. Advanced_trajectory.aimnumBeforeShot 
                end

                -- vt[4] is offset xyz
                if not Zombie and not Playershot  then
                    Zombie,Playershot = Advanced_trajectory.getShootzombie({vt[4][1]-0.9 +angleammooff*0.45+admindel*3,vt[4][2]-0.9+angleammooff*0.45+admindel*3,shootlevel},2,isshotplayer)
                    damagezb = bodyShotDmgZomMultiplier*vt[6]*0.1    -- zombie bodyshot
                    saywhat = "IGUI_Bodyshot" 
                    damagepr = bodyShotDmgPlayerMultiplier               -- player bodyshot
                end
                if not Zombie and not Playershot then
                    Zombie,Playershot = Advanced_trajectory.getShootzombie({vt[4][1]-1.8+0.9*angleammooff+admindel*3,vt[4][2]-1.8+0.9*angleammooff+admindel*3,shootlevel},3,isshotplayer)
                    damagezb = footShotDmgZomMultiplier*vt[6]*0.1      -- zombie footshot
                    saywhat = "IGUI_Footshot" 
                    damagepr = footShotDmgPlayerMultiplier                -- player footshot
                end


                -- if not Zombie and not Playershot and vt[2]:getObjects():size() <2 and vt[20][3]>0 then
                --     Zombie,Playershot =  Advanced_trajectory.getShootzombie({vt[4][1]-3,vt[4][2]-3,vt[4][3]-1},4,isshotplayer)
                --     damagezb = 10 * vt[6]*0.1
                --     damagepr = 20
                -- end

                -- print(Playershot)
                
                -- NOTES: if it's a non friendly player is shot at, determine damage done and which body part is affected
                -- vt[19] is the player itself (you)
                -- the player shot can not be the client player (you can't shoot you)
                if not vt["nonsfx"] and Playershot and vt[19] and Playershot ~= vt[19] and (Faction.getPlayerFaction(Playershot)~=Faction.getPlayerFaction(vt[19]) or not Faction.getPlayerFaction(Playershot))     then
                    
                    Playershot:setX(Playershot:getX()+0.15*vt[3][1])
                    Playershot:setY(Playershot:getY()+0.15*vt[3][2])
                    Playershot:addBlood(100)


                    -- isClient() returns true if the code is being run in MP
                    if isClient() then
                        sendClientCommand("ATY_shotplayer","true",{damagepr,vt[6],Playershot:getOnlineID()})
                    else


                        local headpart = {
                            BodyPartType.Neck,
                            BodyPartType.Head
                        }
                        local midpart = {
                            BodyPartType.Torso_Upper,
                            BodyPartType.Torso_Lower,
                            BodyPartType.ForeArm_L,
                            BodyPartType.ForeArm_R,
                            BodyPartType.UpperArm_L,
                            BodyPartType.UpperArm_R,
                            BodyPartType.Groin,
                            BodyPartType.Back
                        }
                        local lowpart = {
                            BodyPartType.UpperLeg_L,
                            BodyPartType.UpperLeg_R,
                            BodyPartType.LowerLeg_L,
                            BodyPartType.LowerLeg_R,
                            BodyPartType.Foot_L,
                            BodyPartType.Foot_R
                        }

                        local shotpart = BodyPartType.Foot_R

                        -- takes a random bodypart type from the table and adds injury to it
                        if damagepr == headShotDmgPlayerMultiplier then
                            shotpart = headpart[ZombRand(#headpart)+1]
                        elseif damagepr == bodyShotDmgPlayerMultiplier then
                            shotpart = midpart[ZombRand(#midpart)+1]
                        elseif damagepr == footShotDmgPlayerMultiplier then
                            shotpart = lowpart[ZombRand(#lowpart)+1]
                        end

                        local bodypart = Playershot:getBodyDamage():getBodyPart(shotpart)

                        if bodypart:haveBullet() then
                            local deepWound = bodypart:isDeepWounded()
                            local deepWoundTime = bodypart:getDeepWoundTime()
                            local bleedTime = bodypart:getBleedingTime()
                            bodypart:setHaveBullet(false, 0)
                            bodypart:setDeepWoundTime(deepWoundTime)
                            bodypart:setDeepWounded(deepWound)
                            bodypart:setBleedingTime(bleedTime)
                        else
                            bodypart:setHaveBullet(true, 0)
                        end

                        local playerDamageDealt = vt[6]*damagepr
                        Advanced_trajectory.dmgDealtToPlayer = playerDamageDealt
                        --local playerDmgMsg = "PlayerDmgDealt:"..tostring(math.floor(playerDamageDealt)) .."|| CH:"..tostring(math.floor(Playershot:getBodyDamage():getHealth()))

                        --vt[19]:Say(playerDmgMsg)

                        Playershot:getBodyDamage():ReduceGeneralHealth(playerDamageDealt)
                    end

                    -- assume player's dead at this point
                    if Playershot:getHealth()<=0.1 then 
                        if isClient() then
                            sendServerCommand("ATY_killedplayer","true",{Playershot:getOnlineID()})
                        end
                        Advanced_trajectory.playerKilled = Playershot:getUsername() .. "("..Playershot:getOnlineID()..")"
                    end

                    Advanced_trajectory.itemremove(vt[1])
                    tablenow[kt]=nil
                    break
                end

                if Zombie and Zombie:isAlive() then

                    -- if zombies alive, player says what body part it hits
                    if vt[19] and getSandboxOptions():getOptionByName("Advanced_trajectory.callshot"):getValue() then
                        vt[19]:Say(getText(saywhat))
                    end

                    if vt["wallcarzombie"] or vt[9] == "Grenade"then

                        vt[22]["zombie"] = Zombie
                        if vt[22][2]> 0 then
                            Advanced_trajectory.boomsfx(vt[2])
                        end
                        if not vt["nonsfx"] then
                            Advanced_trajectory.Boom(vt[2],vt[22])
                        end
                        
                        Advanced_trajectory.itemremove(vt[1])
                        tablenow[kt]=nil
                        break
                    


                    elseif not vt["nonsfx"]  then
                        if vt[9] == "flamethrower" then
                            Zombie:setOnFire(true)
    
                        -- elseif vt[9] == "GrenadeLauncher" then
                            -- tanksuperboom(vt[2])
                        end

                        if isClient() then

                            sendClientCommand("ATY_cshotzombie","true",{Zombie:getOnlineID(),vt[19]:getOnlineID()})
                            -- Zombie:Kill(vt[19])
                            
                        end


                        -- if not string.find(tostring(Zombie:getCurrentState()), "Climb") and not string.find(tostring(Zombie:getCurrentState()), "Craw") then
                       
                        --     Zombie:changeState(ZombieIdleState.instance())
                        -- end

                        -- give xp upon hit
                        local hitXP = getSandboxOptions():getOptionByName("Advanced_trajectory.XPHitModifier"):getValue()
                        triggerEvent("OnWeaponHitCharacter", vt[19], Zombie, vt[19]:getPrimaryHandItem(), damagezb) -- OnWeaponHitXp From "KillCount",used(wielder,victim,weapon,damage)
                        if isServer() == false then
                            Events.OnWeaponHitXp.Add(vt[19]:getXp():AddXP(Perks.Aiming, hitXP));
                        end

                        -- DONT USE THIS, ONLY TRIGGER EVENT
                        --vt[19]:getXp():AddXP(Perks.Aiming, vt[6]*getSandboxOptions():getOptionByName("Advanced_trajectory.XPHitModifier"):getValue(), false, false, false)




                        -- display damage done to zombie from bullet or whatever
                        if getSandboxOptions():getOptionByName("ATY_damagedisplay"):getValue() then
                            local damagea = TextDrawObject.new()
                            damagea:setDefaultColors(1,1,0.1,0.7)
                            damagea:setOutlineColors(0,0,0,1)
                            damagea:ReadString(UIFont.Middle, "-" ..tostring(math.floor(damagezb*100)), -1)
                            local sx = IsoUtils.XToScreen(Zombie:getX(), Zombie:getY(), Zombie:getZ(), 0);
                            local sy = IsoUtils.YToScreen(Zombie:getX(), Zombie:getY(), Zombie:getZ(), 0);
                            sx = sx - IsoCamera.getOffX() - Zombie:getOffsetX();
                            sy = sy - IsoCamera.getOffY() - Zombie:getOffsetY();
                            sy = sy - 64
                            sx = sx / getCore():getZoom(0)
                            sy = sy / getCore():getZoom(0)
                            sy = sy - damagea:getHeight()
    
    
                            table.insert(Advanced_trajectory.damagedisplayer,{60,damagea,sx,sy,sx,sy})
                            
                        end
                        
                        -- damagea:AddBatchedDraw(sx, sy, true)
                        -- Advanced_trajectory.damagedisplayer = 
                        -- print("-" ..tostring(math.floor(damagezb*100)))

                        -- subtract health from zombie 
                        Zombie:setHealth(Zombie:getHealth()-damagezb)
                        Zombie:setHitReaction("Shot")
                        Zombie:addBlood(getSandboxOptions():getOptionByName("AT_Blood"):getValue())
                        
    
    
                        -- if zombie's health is very low, just kill it (recall full health is over 140) and give xp like usual
                        if Zombie:getHealth()<=0.1 then 
                                
                            if vt[19] then

                                if isClient() then

                                    sendClientCommand("ATY_killzombie","true",{Zombie:getOnlineID()})
                                    -- Zombie:Kill(vt[19])
                                end
                                Zombie:Kill(vt[19])

                                
                                    


                            

                                
                                
                                vt[19]:setZombieKills(vt[19]:getZombieKills()+1)
                                vt[19]:setLastHitCount(1)

                                local killXP = getSandboxOptions():getOptionByName("Advanced_trajectory.XPKillModifier"):getValue()
                                 -- multiplier to 0.67
                                triggerEvent("OnWeaponHitXp",vt[19], vt[19]:getPrimaryHandItem(), Zombie, damagezb) -- OnWeaponHitXp From "KillCount",used(wielder,weapon,victim,damage)
                                
                                if isServer() == false then
                                    Events.OnWeaponHitXp.Add(vt[19]:getXp():AddXP(Perks.Aiming, killXP));
                                end

                            end
                                
                        end
    
    
                        -- Zombie:setHealth(Zombie:getHealth()-damagezb)
                        -- Zombie:setX(Zombie:getX()+0.15*vt[3][1])
                        -- Zombie:setY(Zombie:getY()+0.15*vt[3][2])
                        -- Zombie:addBlood(100)
                        -- -- print(Zombie:isAlive())
                        -- if Zombie:getHealth()<=0.1 then 
                            
                        --     if vt[19] then
                        --         Zombie:Kill(vt[19])
                        --         vt[19]:setZombieKills(vt[19]:getZombieKills()+1)
                        --         vt[19]:getXp():AddXP(Perks.Aiming, 1);
    
                        --     end
                            
                        --     -- local playerz = getPlayer()
                            
                        -- end
                        
                    end
                    

                    Advanced_trajectory.itemremove(vt[1])

                    if not vt["ThroNumber"] then vt["ThroNumber"] = 1 end
                    vt["ThroNumber"] = vt["ThroNumber"]-1
                    vt[6] = 0.36*vt[6]

                    if not vt[11] and (vt["ThroNumber"] <= 0  )then
                        tablenow[kt]=nil
                        break
                        
                    end  
                end

                
                
            end  
        end

    end

    -- print(Advanced_trajectory.table == tablenow)

    -- Advanced_trajectory.table =  tablenow

    


end

Events.OnTick.Add(Advanced_trajectory.checkontick)

-----------------------------------
--SHOOTING PROJECTILE FUNC SECT---
-----------------------------------
function Advanced_trajectory.OnWeaponSwing(character, handWeapon)
    
    if getSandboxOptions():getOptionByName("Advanced_trajectory.showOutlines"):getValue() and instanceof(handWeapon,"HandWeapon") and (handWeapon:isRanged() and getSandboxOptions():getOptionByName("Advanced_trajectory.Enablerange"):getValue()) then
        handWeapon:setMaxHitCount(0)
    end

    -- print(character)
    local item
    local winddir=1
    local weaponname = ""
    local rollspeed = 0
    local iscanthrough = false
    local ballisticspeed = 0.15  
    local ballisticdistance = handWeapon:getMaxRange(character)*1.5
    local itemtypename = ""
    local iscanbigger = 0
    local sfxname = ""
    local isthroughwall =true
    local distancez = 0

    local player=character

    -- player position
    local offx = character:getX()
    local offy = character:getY()
    local offz = character:getZ()

    local deltX
    local deltY
    local ProjectileCount = 1

    local throwinfo ={}
    local ispass =false


    local square
    local _damage

    -- direction from -pi to pi OR -180 to 180 deg
    -- N (top left corner): pi,-pi  (180, -180)
    -- W (bottom left): pi/2 (90)
    -- E (top right): -pi/2 (-90)
    -- S (bottom right corner): 0
    local dirc = player:getForwardDirection():getDirection()
    local dircOg = player:getForwardDirection():getDirection()

    -- pi/250 = .7 degrees
    -- aimnum can go up to (77-9+40) 108 
    -- max/min -+96 degrees, and even more when drunk (6*24+108 = 252 => 208 deg)
    local aimrate = Advanced_trajectory.aimnum * math.pi / 250
    
    -- NOTES: I'm assuming aimrate, which is affected by aimnum, determines how wide the bullets can spread.
    -- adding dirc (direction player is facing) will cause bullets to go towards the direction of where player is looking
    dirc = dirc + ZombRandFloat(-aimrate,aimrate)
    deltX=math.cos(dirc)
    deltY=math.sin(dirc)

    



    local tablez = 
    {
        item,                                      --1物品obj
        square,                                    --2方格obj
        {deltX,deltY},                             --3向量
        {offx, offy, offz},                        --4偏移量
        dirc,                                      --5方向
        _damage,                                   --6伤害
        ballisticdistance,                         --7距离
        winddir,                                   --8弹道小类别
        weaponname,                                --9种类
        rollspeed,                                 --10旋转速度
        iscanthrough,                              --11是否能够穿透
        ballisticspeed,                            --12弹道速度
        iscanbigger,                               --13是否可以变大
        sfxname,                                   --14弹道名称
        isthroughwall,                             --15是否能穿墙
        1,                                         --16尺寸
        0,                                         --17当前距离
        distancez,                                 --18距离常数
        player,                                    --19玩家
        {offx, offy, offz},                        --20原始偏移量
        0,                                         --21计数 
        throwinfo                                  --22投掷物属性                                                          
    }

    tablez["boomsfx"] = {}
    tablez["animlevels"] = Advanced_trajectory.aimlevels or math.floor(tablez[4][3])

    -- if Advanced_trajectory.thorwerinfo then
    --     tablez[22] = Advanced_trajectory.twotable(Advanced_trajectory.thorwerinfo)
    -- end
    -- Advanced_trajectory.thorwerinfo = {
        
    -- }

    tablez[22] = {
        handWeapon:getSmokeRange(),
        handWeapon:getExplosionPower(),
        handWeapon:getExplosionRange(),
        handWeapon:getFirePower(),
        handWeapon:getFireRange()
    }




    tablez[22][7] = handWeapon:getExplosionSound()

    tablez["ThroNumber"] = 1


    local isspweapon = Advanced_trajectory.Advanced_trajectory[handWeapon:getFullType()] 
    if isspweapon then
        for lk,pk in pairs(isspweapon) do
            if lk == 4 then
                tablez[4][1] = tablez[4][1]+pk[1]*tablez[3][1]
                tablez[4][2] = tablez[4][2]+pk[2]*tablez[3][2]
                tablez[4][3] = tablez[4][3]+pk[3]
            else 
                tablez[lk] = pk
            end
            
        end
        ispass = true
    end

    if Advanced_trajectory.aimcursorsq then
        tablez[18] = ((Advanced_trajectory.aimcursorsq:getX()+0.5-offx)^2+(Advanced_trajectory.aimcursorsq:getY()+0.5-offy)^2)^0.5
    else
        tablez[18] =handWeapon:getMaxRange(character)
    end

    local isHoldingShotgun = false
    if not ispass then  
        if getSandboxOptions():getOptionByName("Advanced_trajectory.Enablethrow"):getValue() and handWeapon:getSwingAnim() =="Throw" then  --投掷物

            
    
            
            
            if tablez[22][1] ==0 and tablez[22][2] ==0 and tablez[22][4]==0 then
                tablez[22][6] = 0.016
                
            else
                tablez[22][6] = 0.04--弧度
            end
    
            
            tablez[22][9] = handWeapon:canBeReused()
    
    
            tablez[7] = tablez[18]
            tablez[9]="Grenade"
            tablez[14] = handWeapon:getFullType()
            tablez[8] = ""
            tablez[11] = false
            tablez[15] = false

            tablez[4][1] = tablez[4][1]+0.3*tablez[3][1]
            tablez[4][2] = tablez[4][2]+0.3*tablez[3][2]

            tablez[10] = 6
            tablez[12] = 0.3
    
            tablez[22][10] = tablez[14]
            tablez["isparabola"] = tablez[22][6]
        
            -- disabling enable range means guns don't work (no projectiles)
        elseif getSandboxOptions():getOptionByName("Advanced_trajectory.Enablerange"):getValue() and handWeapon:getSubCategory() =="Firearm" then ----枪

            local hideTracer = getSandboxOptions():getOptionByName("Advanced_trajectory.hideTracer"):getValue()
            --print("Tracer hidden: ", hideTracer)

            --string.contains(weaitem:getAmmoType() or "","Arrow") or string.contains(weaitem:getAmmoType() or "","Bolt")

            local offset = getSandboxOptions():getOptionByName("Advanced_trajectory.DebugOffset"):getValue()
            local spawnOffset = getSandboxOptions():getOptionByName("Advanced_trajectory.DebugSpawnOffset"):getValue()

            if  (string.contains(handWeapon:getAmmoType() or "","Shotgun") or string.contains(handWeapon:getAmmoType() or "","shotgun") or string.contains(handWeapon:getAmmoType() or "","shell") or string.contains(handWeapon:getAmmoType() or "","Shell")) then
                local shotgunDistanceModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgunDistanceModifier")
                
                tablez[9]="Shotgun" --weapon name

                --wpn sndfx
                if hideTracer then
                    --print("Empty")
                    tablez[14] = "Empty.aty_Shotguna"    
                else
                    --print("Base")
                    tablez[14] = "Base.aty_Shotguna"  
                end

                tablez[12] = 1.6    --ballistic speed
                tablez[7] = tablez[7]*0.75  --ballistic distance
                tablez[15] = false --isthroughwall

                tablez[4][1] = tablez[4][1] + spawnOffset*math.cos(dircOg)
                tablez[4][2] = tablez[4][2] + spawnOffset*math.sin(dircOg)

                tablez[4][1] = tablez[4][1]+offset*tablez[3][1]    --offsetx=offsetx +.6 * deltX; deltX is cos of dirc
                tablez[4][2] = tablez[4][2]+offset*tablez[3][2]    --offsety=offsety +.6 * deltY; deltY is sin of dirc
                tablez[4][3] = tablez[4][3]+0.5                 --offsetz=offsetz +.5

                isHoldingShotgun = true
            elseif  (string.contains(handWeapon:getAmmoType() or "","Round") or string.contains(handWeapon:getAmmoType() or "","round")) then 
                -- The idea here is to solve issue of Brita's launchers spawning a bullet along with their grenade.
                return
            elseif  (string.contains(handWeapon:getAmmoType() or "","FlameFuel") and string.contains(handWeapon:getName() or "","Thrower")) then 
                -- Break bullet if flamethrower
                return
            else
                tablez[9]="revolver"

                --wpn sndfx
                -- The idea here is to solve issue of Brita's chainsaw problem (it's a gun in disguise but with very short range).
                local hasChainsaw = string.contains(handWeapon:getAmmoType() or "","FlameFuel") and string.contains(handWeapon:getName() or "","Chainsaw")
                if hideTracer or hasChainsaw then
                    --print("Empty")
                    tablez[14] = "Empty.aty_revolversfx"  
                else
                    --print("Base")
                    tablez[14] = "Base.aty_revolversfx" 
                end

                tablez[12] = 1.8
                tablez[15]  = false
            
                tablez[4][1] = tablez[4][1] + spawnOffset*math.cos(dircOg)
                tablez[4][2] = tablez[4][2] + spawnOffset*math.sin(dircOg)

                tablez[4][1] = tablez[4][1] + offset*tablez[3][1]
                tablez[4][2] = tablez[4][2] + offset*tablez[3][2]
                tablez[4][3] = tablez[4][3]+0.5

                tablez["ThroNumber"] = ScriptManager.instance:getItem(handWeapon:getFullType()):getMaxHitCount()

                isHoldingShotgun = false
            end
        else
            return
            
        end
        

    end

    tablez[2] = tablez[2] or getWorld():getCell():getGridSquare(offx,offy,offz)
    if tablez[2] == nil then return end

    local playerlevel = character:getPerkLevel(Perks.Aiming)

    -- NOTES: tablez[6] is damage, firearm damages vary from 0 to 2. Example, M16 has min to max: 0.8 to 1.4 (source wiki)
    tablez[6] = tablez[6] or (handWeapon:getMinDamage() + ZombRandFloat(0.1,1.3)*(0.5+handWeapon:getMaxDamage()-handWeapon:getMinDamage()))
    
    -- firearm crit chance can vary from 0 to 30. Ex, M16 has a crit chance of 30 (source wiki)
    -- Rifles - 25 to 30
    -- M14 - 0 crit but higher hit chance
    -- Pistols - 20
    -- Shotguns - 60 to 80
    -- Lower aimnum (to reduce spamming crits with god awful bloom) and higher player level means higher crit chance.
    local critChanceModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.critChanceModifier"):getValue() 
    local critChanceAdd = (Advanced_trajectory.aimnumBeforeShot*critChanceModifier) + (11-playerlevel)

    -- higher = higher crit chance
    local critIncreaseShotgun = getSandboxOptions():getOptionByName("Advanced_trajectory.critChanceModifierShotgunsOnly"):getValue() 
    if isHoldingShotgun then
        critChanceAdd = (critChanceAdd * 0) - (critIncreaseShotgun - playerlevel)
    end
    if ZombRand(100+critChanceAdd) <= handWeapon:getCriticalChance() then
        tablez[6]=tablez[6]*2
    end


    -- throwinfo[8] = tablez[6]
    tablez[22][8] = handWeapon:getMinDamage()

    -- tablez[5] is dirc
    local dirc1 = tablez[5]
    tablez[5] = tablez[5]*360/(2*math.pi)

    -- ballistic speed
    tablez[12] = tablez[12]*getSandboxOptions():getOptionByName("Advanced_trajectory.bulletspeed"):getValue() 

    -- bullet distance
    -- apparently chainsaws have different ranges, wow!
    if string.contains(handWeapon:getAmmoType() or "","FlameFuel") and string.contains(handWeapon:getName() or "","Chainsaw") then
        tablez[7] = tablez[7]*1   -- nerf range of chainsaw
    else
        tablez[7] = tablez[7]*getSandboxOptions():getOptionByName("Advanced_trajectory.bulletdistance"):getValue() 
    end

    ---------------------------
    -----SCOPE RANGE BUFF------
    ---------------------------
    local scope = handWeapon:getScope()
    if scope then
        tablez[7] = tablez[7] + (scope:getMaxRange() * 0.20)
    end


    local bulletnumber = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgunnum"):getValue() 


    local damagemutiplier = getSandboxOptions():getOptionByName("Advanced_trajectory.ATY_damage"):getValue()  or 1

    -- print(damagemutiplier)
    -- _damage = tablez[6]/4 * damagemutiplier
    -- tablez[6] = 

    -- NOTES: damage is multiplied by user setting (default 1)
    tablez[6] = tablez[6]*damagemutiplier

    local damageer = tablez[6]

    -- print(tablez[5])
    if tablez[9]== "Shotgun" then

        -- tablez[12] = tablez[12]*1.5
        --    if getPlayer():getPerkLevel(Perks.Aiming)


        local aimtable = {}
        
        -- aimtable[0] = bulletnumber
        -- aimtable[1] = bulletnumber
        -- aimtable[2] = bulletnumber+1
        -- aimtable[3] = bulletnumber+1
        -- aimtable[4] = bulletnumber+1
        -- aimtable[5] = bulletnumber+1
        -- aimtable[6] = bulletnumber+1
        -- aimtable[7] = bulletnumber+1
        -- aimtable[8] = bulletnumber+1
        -- aimtable[9] = bulletnumber+1
        -- aimtable[10] = bulletnumber+1

        for shot =1,bulletnumber do
            local adirc

            -- lower value means tighter spread
            local numpi = getSandboxOptions():getOptionByName("Advanced_trajectory.shotgundivision"):getValue() *0.7

            ---------------------------
            -----CHOKE RANGE BUFF------
            ---------------------------
            local choke = handWeapon:getCanon()
            if choke then
                local angle = choke:getAngle()
                -- two types of chokes, one that increases spread and one that decreases it
                if angle > 0 then
                    numpi = numpi * 0.5
                else
                    numpi = numpi * 1.5
                end
            end

            adirc = dirc1 +ZombRandFloat(-math.pi * numpi,math.pi*numpi)

            tablez[3] = {math.cos(adirc),math.sin(adirc)}
            tablez[4] = {tablez[4][1], tablez[4][2], tablez[4][3]}
            tablez[5] = adirc*360/(2*math.pi)
            tablez[20] = {tablez[4][1], tablez[4][2], tablez[4][3]}

            tablez[6] = damageer/4
            

            if isClient() then
                tablez["nonsfx"] = 1
                sendClientCommand("ATY_shotsfx","true",{tablez,character:getOnlineID()})
            end
            tablez["nonsfx"] = nil
            table.insert(Advanced_trajectory.table,Advanced_trajectory.twotable(tablez))
        end
    else

        -- print(tablez[9])
        if tablez["wallcarmouse"] then
            tablez[7] = Advanced_trajectory.aimtexdistance - 1
        end
        tablez[20] = {offx, offy, tablez[4][3]}
        table.insert(Advanced_trajectory.table,Advanced_trajectory.twotable(tablez))
        if isClient() then
            tablez["nonsfx"] = 1
            sendClientCommand("ATY_shotsfx","true",{tablez,character:getOnlineID()})
        end

        -- print(Advanced_trajectory.aimtexdistance)
        
    end

    ----------------------
    --RECOIL PAD BUFF-----
    ----------------------
    local recoilModifier = getSandboxOptions():getOptionByName("Advanced_trajectory.recoilModifier"):getValue()
    -- recoils range from 0.5 to 2.7
    Advanced_trajectory.aimnumBeforeShot = Advanced_trajectory.aimnum
    local recoil = handWeapon:getMaxDamage()*recoilModifier

    local weaitem = player:getPrimaryHandItem()
    local recoilPad = weaitem:getRecoilpad()
    if recoilPad then
        recoil = recoil * 0.5
    end

    -- Prone stance means less recoil
    if character:getVariableBoolean("isCrawling") then
        recoil = recoil * 0.5
    end

    Advanced_trajectory.aimnum = Advanced_trajectory.aimnum + ((14 - 0.8*playerlevel)*1.8 + recoil)
    Advanced_trajectory.maxFocusCounter = 100

    
end

Events.OnWeaponSwingHitPoint.Add(Advanced_trajectory.OnWeaponSwing)

