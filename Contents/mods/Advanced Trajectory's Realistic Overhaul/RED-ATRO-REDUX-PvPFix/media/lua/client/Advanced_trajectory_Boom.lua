require "Advanced_trajectory_core"



function Advanced_trajectory.sqobject(sqa)
    local cell = getWorld():getCell();
	local sq = sqa
	if sq == nil then return false; end
	local sqObjs = sq:getObjects();
	local sqSize = sqObjs:size();
	local tbl = {}
	for i = sqSize-1, 0, -1 do 
		local obj = sqObjs:get(i);
		table.insert(tbl, obj)
	end
	return sq, sqObjs, tbl, cell
end
function Advanced_trajectory.Boom(sq,info)

    local player = getPlayer()
    if not sq or not info  or  not player then return end

    if info["zombie"] then
        info["zombie"]:knockDown(false)
        info["zombie"]:setHealth(info["zombie"]:getHealth()-info[8]*0.1)

        if info["zombie"]:getHealth() <0.1 then
            info["zombie"]:Kill(player)
        end
    end

    if info[9] and  info["pos"] then
        sq:AddWorldInventoryItem(info[10], info["pos"][1], info["pos"][2], 0)
    end


    -- player:setPrimaryHandItem(nil)
    -- player:setSecondaryHandItem(nil)
    -- local inventory = player:getInventory()
    -- -- local itemtype = handWeapon:getFullType()
    -- if inventory:contains(info[10]) then
    --     inventory:Remove(info[10])
    --     local item  = inventory:AddItem(info[10])

    --     player:setPrimaryHandItem(item)
    --     player:setSecondaryHandItem(item)
    -- end

    


    local SmokeRange = info[1]-2
    local ExplosionPower =info[2]
    local ExplosionRange = info[3]-2
    local FirePower =info[4]
    local FireRange =info[5]-2

    for i=-SmokeRange,SmokeRange do
        for k=-SmokeRange,SmokeRange do
            local square=getCell():getGridSquare(sq:getX()+i,sq:getY()+k,sq:getZ())
            if square then
                local corenumber = (i^2+k^2)
                if ZombRand(SmokeRange^2+SmokeRange^2) >= corenumber then
                    

                    if isClient() then
                        local args = { x = square:getX(), y = square:getY(), z = square:getZ() }
                        sendClientCommand('object', 'addSmokeOnSquare', args)
                        


                    else
                        IsoFireManager.StartSmoke(getCell(), square, true, 200, 3000)
                    end
                end
            end
        end
    end
    



    for zkl = 0,1 do
        for i=-ExplosionRange,ExplosionRange do
            for k=-ExplosionRange,ExplosionRange do
                local square=getCell():getGridSquare(sq:getX()+i,sq:getY()+k,sq:getZ()+zkl)
                if square then
                    local corenumber = (i^2+k^2)
                    if ExplosionPower>100 and ZombRand(ExplosionRange^2+ExplosionRange^2)/1.5 >= corenumber then
                        local sqz, sqObjs, objTbl, cell = Advanced_trajectory.sqobject(square)
                        local z = sq:getZ()
                        for izk = 1, #objTbl do
                            local obj = objTbl[izk]
                            local sprite = obj:getSprite()
                            if sprite and (zkl > 0 or sprite:getProperties():Is(IsoFlagType.solidfloor) ~= true) then
                                local stairObjects = buildUtil.getStairObjects(obj)
                                if #stairObjects > 0 then
                                    for i=1,#stairObjects do
                                        if isClient() then
                                            sledgeDestroy(stairObjects[i])
                                        else
                                            stairObjects[i]:getSquare():RemoveTileObject(stairObjects[i])
                                        end
                                    end
                                else
                                    if isClient() then
                                        sledgeDestroy(obj)
                                    else
                                        sqz:RemoveTileObject(obj);
                                        sqz:getSpecialObjects():remove(obj);
                                        sqz:getObjects():remove(obj);
                                    end
                                end
                            end
                        end

                        --suixie
    
                        -- if zkl == 0 then
                        --     if ZombRand(10)<=4 then
                        --         local objectz = IsoObject.new(square, "floors_burnt_01_0", "", false)
                        --         square:AddTileObject(objectz)
                        --         if isClient() then objectz:transmitCompleteItemToServer(); end
                        --     elseif ZombRand(10)<=6 then
                        --         local objectz = IsoObject.new(square, "floors_burnt_01_1", "", false)
                        --         square:AddTileObject(objectz)
                        --         if isClient() then objectz:transmitCompleteItemToServer(); end
                        --     else
                        --         local objectz = IsoObject.new(square, "floors_burnt_01_2", "", false)
                        --         square:AddTileObject(objectz)
                        --         if isClient() then objectz:transmitCompleteItemToServer(); end
                        --     end
                        -- end
                        
                    end
    
                    
                    local movingObjects = square:getMovingObjects()
                    for zz=1,movingObjects:size() do
                        local zombiez = movingObjects:get(zz-1)
                        if instanceof(zombiez,"IsoZombie") then
                            zombiez:knockDown(false)
                            if ZombRand(ExplosionRange^2+ExplosionRange^2) >= corenumber then
                                zombiez:Kill(player)
                               
                            end
                            
                        elseif getSandboxOptions():getOptionByName("Advanced_trajectory.playerdamage"):getValue() and instanceof(zombiez,"IsoPlayer") then
    
                            if isClient() then
                                sendClientCommand("ATY_reducehealth","true",{ExplosionPower,zombiez:getOnlineID()})
    
    
    
                            else
                                zombiez:getBodyDamage():ReduceGeneralHealth(ExplosionPower)
                            end
                            
    
                        end
                    end 
                    
                end
            end
        end
    end



    for i=-FireRange,FireRange do
        for k=-FireRange,FireRange do
            local square=getCell():getGridSquare(sq:getX()+i,sq:getY()+k,sq:getZ())
            if square then
                local corenumber = (i^2+k^2)
                if ZombRand(FireRange^2+FireRange^2) >= corenumber then

                    if isClient() then
                        local args = { x = square:getX(), y = square:getY(), z = square:getZ() }
                        sendClientCommand('object', 'addFireOnSquare', args)

                    else
                        IsoFireManager.StartFire(getCell(), square, true, 100, 500);
                    end

                
                    
                    
	
            
                end
            end
        end
    end




    
    -- getSoundManager():PlayWorldSoundWav(info[7],sq, 10, 2, 0.5, true);
    -- print(info[7])
    -- player:playSound(info[7])

    local sound = getSoundManager(): PlayWorldSound(info[7], sq, 0, 4, 1.0, false);
	sound:setVolume(0.7);

    -- print(info[7])


end
