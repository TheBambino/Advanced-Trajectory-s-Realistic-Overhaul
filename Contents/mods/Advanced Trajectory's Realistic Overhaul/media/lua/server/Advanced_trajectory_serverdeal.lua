-- require "Advanced_trajectory_core"

if not isServer() then return end


local function Advanced_trajectory_OnClientCommand(module, command, player, args)

    if module == "ATY_shotplayer" then

        -- make sure the first parameter is for TARGET PLAYER
        sendServerCommand(getPlayerByOnlineID(args[2]),"ATY_shotplayer", "true", args)

    elseif module == "ATY_writePVPLog" then

        sendServerCommand("ATY_writePVPLog", "true", args)

    elseif module == "ATY_shotsfx" then

        sendServerCommand("ATY_shotsfx", "true", args)

    elseif module == "ATY_reducehealth" then

        sendServerCommand(getPlayerByOnlineID(args[2]),"ATY_reducehealth", "true", args)

    elseif module == "ATY_cshotzombie" then

        sendServerCommand("ATY_cshotzombie", "true", args)

    elseif  module == "ATY_killzombie" then

        sendServerCommand("ATY_killzombie", "true", args)

    end


	-- Your code here
end

Events.OnClientCommand.Add(Advanced_trajectory_OnClientCommand)