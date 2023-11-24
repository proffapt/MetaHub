--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function OnStartup()
	tCfg = {
		sBotName = "[BOT]Offliner",
		sBotDescription = "The database of newest additions to hub.",
		sBotEmail = "do-not@mail.me",
		sPath = Core.GetPtokaXPath().."scripts/",
		sExternalFile = "offliner.lua",
		sChatFile = "chatcore.lua",
		sHelpFile = "ohelp.txt",
		sRulesFile = "general.txt",
		sReportBot = "#[Hub-Feed]",
		iModProfile = 4,
		iRegProfile = 5,
	}
	tPaths = {
		sDependency = tCfg.sPath.."dependency/",
		sExternal = tCfg.sPath.."external/",
		sTexts = tCfg.sPath.."texts/",
	}
	tProfiles = {
		AllowVIP = {
			[0] = true,			-- Admin
			[1] = true,			-- God
			[2] = true,			-- OP
			[3] = true,			-- VIP
			[4] = false,		-- Mods
			[5] = false,		-- Reg
			[6] = false,		-- sVIP
			[7] = false,		-- gymkhana
		},
		AllowAdmin = {
			[0] = true,			-- Admin
			[1] = false,		-- God
			[2] = true,			-- OP
			[3] = false,		-- VIP
			[4] = false,		-- Mods
			[5] = false,		-- Reg
			[6] = false,		-- sVIP
			[7] = false,		-- gymkhana
		},
	}
	dofile( tPaths.sExternal..tCfg.sExternalFile )
	dofile( tPaths.sDependency.."functions.lua" )
	dofile( tPaths.sDependency..tCfg.sChatFile )
	local fHelp = io.open( tPaths.sTexts..tCfg.sHelpFile, "r" )
	local fRules = io.open( tPaths.sTexts..tCfg.sRulesFile, "r" )
	sHelp = fHelp:read( "*a" )
	sRules = fRules:read( "*a" )
	Core.RegBot( tCfg.sBotName, tCfg.sBotDescription, tCfg.sBotEmail, true )
	sAllModerators, sAllCategories = tFunction.Connect()
end

function ToArrival( tUser, sMessage )
	local sTo = sMessage:match "%$To: (%S+) From:"
	if sTo ~= tCfg.sBotName then return false end
	local sCmd, sData = sMessage:match "%b<> [-+*/?!#](%w+)%s?(.*)|"
	if not sCmd then return false end
	return ExecuteCommand( tUser, sCmd:lower(), sData )
end

function UserConnected( tUser )
	tOffliner.PassMessage( tUser.sNick )
end

RegConnected, OpConnected = UserConnected, UserConnected

function ExecuteCommand( tUser, sCmd, sData )
	if sCmd == "l" or sCmd == "latest" then
		if (not sData) or sData:len() == 0 then
			tOffliner.l( tUser, 35 )
			return true
		else
			local tBreak = Explode( sData )
			if tBreak[1] and tonumber( tBreak[1] ) then
				tOffliner.l( tUser, tonumber(tBreak[1]) )
				return true
			elseif tBreak[2] and tonumber( tBreak[2], 10 ) then
				tOffliner.l( tUser, tonumber(tBreak[2]), tBreak[1] )
				return true
			elseif not tonumber( tBreak[1] ) then
				tOffliner.l( tUser, 20, tBreak[1] )
				return true
			else
				Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("gen", 1) )
				return true
			end
			return true
		end
		return true

	elseif sCmd == "h" or sCmd == "help" then
		Core.SendPmToUser( tUser, tCfg.sBotName, sHelp )
		return true

	elseif sCmd == "r" or sCmd == "rules" then
		Core.SendPmToUser( tUser, tCfg.sBotName, sRules )
		return true

	elseif sCmd == "m" or sCmd == "msg" then
		if not sData or sData:len() < 20 then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Message was too short. Error raised." )
			return true
		elseif sData:len() > 300 then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Message must be less than 300 characters. Error raised." )
			return true
		end
		local tBreak = Explode( sData )
		return tOffliner.StoreMessage( tUser.sNick, tBreak[1], table.concat(tBreak, " ", 2) )

	elseif sCmd == "search" or sCmd == "s" then
		if (not sData) or sData:len() == 0 then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! No search string was given." )
			return true
		else
			tOffliner.s( tUser, sData )
			return true
		end
		return true

	elseif sCmd == "sc" or sCmd == "showctg" then
		Core.SendPmToUser( tUser, tCfg.sBotName, sAllCategories.."|" )
		return true

	elseif sCmd == "sm" or sCmd == "showmods" then
		Core.SendPmToUser( tUser, tCfg.sBotName, sAllModerators.."|" )
		return true
	end

	if tUser.iProfile == -1 then
		Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("gen", 2) )
		return true
	end

	if (not sData) or sData:len() == 0 then
		Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("gen", 4) )
		return true
	end

	local tBreak = Explode( sData )

	if sCmd == "al" or sCmd == "addlatest" then
		if #tBreak < 3 then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("gen", 4) )
			return true
		elseif not tFunction.CheckCategory( tBreak[1] ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! That category doesn't exist." )
			return true
		elseif not tFunction.CheckModerator( tUser.sNick ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 120)..sAllModerators )
			return true
		end
		if tOffliner.al( tUser, tBreak ) then
			local sChatMessage = "New "..tBreak[1]:upper()..": "..table.concat(tBreak, " ", 2).." added to latest database."
			tFunction.SendToAll( tUser.sNick, sChatMessage )
			SendToRoom( tUser.sNick, sChatMessage, tCfg.sReportBot, tCfg.iModProfile )
			return true
		else
			Core.SendPmToUser( tUser, tCfg.sBotName, "Some internal error occured." )
			return true
		end

	elseif sCmd == "dl" or sCmd == "dellatest" then
		for iIndex, iID in pairs( tBreak ) do
			if not tonumber( iID ) then
				Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("gen", 5) )
			end
			local iID, tRow = tonumber(iID), tFunction.FetchRow( tonumber(iID) )
			if not tRow then
				Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 2) )
			end
			if tRow and ( tProfiles.AllowVIP[tUser.iProfile] or tRow.nick:lower() == tUser.sNick:lower() ) then
				tOffliner.dl( tUser, iID, tRow.nick )
				local sRoomReply, sPersonalReply = "The entry #%d - %s was deleted.", "The following entry was deleted.\n%s"
				SendToRoom( tUser.sNick, sRoomReply:format(iID, tRow.msg), tCfg.sReportBot )
				Core.SendPmToUser( tUser, tCfg.sBotName, sPersonalReply:format(tFunction.CreateLatestReading( tRow )) )
			elseif tRow.nick:lower() ~= tUser.sNick:lower() then
				Core.SendPmToUser( tUser, tCfg.sBotName, "This entry was not added by you. You can not delete it." )
			end
		end
		return true

	elseif sCmd == "ul" or sCmd == "updatelatest" then
		local bSendToAll = false
		if tBreak[1] == "-m" then
			bSendToAll = true
			table.remove( tBreak, 1 )
		elseif tBreak[#tBreak] == "-m" then
			bSendToAll = true
			table.remove( tBreak, #tBreak )
		end
		if not tFunction.CheckModerator( tUser.sNick ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 120) )
			return true
		end
		if not tonumber( tBreak[1] ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("gen", 5) )
			return true
		end
		local tRow = tFunction.FetchRow( tonumber(tBreak[1]) )
		if not tRow then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 2) )
			return true
		end
		if tProfiles.AllowVIP[tUser.iProfile] or tRow.nick:lower() == tUser.sNick:lower() then
			if not tOffliner.ul( tUser, tBreak ) then return true end
			Core.SendPmToUser( tUser, tCfg.sBotName, "The message has been updated." )
			local sChatMessage = "Entry #"..tostring(tBreak[1]).." was updated. Older entry was: "..tRow.msg
			if bSendToAll then
				tFunction.SendToAll( tUser.sNick, sChatMessage )
			end
			SendToRoom( tUser.sNick, sChatMessage, tCfg.sReportBot, tCfg.iModProfile )
			return true
		elseif tRow.nick:lower() ~= tUser.sNick:lower() then
			Core.SendPmToUser( tUser, tCfg.sBotName, "This entry was not added by you. You do not have permission to edit it." )
			return true
		end
		return true

	elseif sCmd == "am" or sCmd == "addmagnet" then
		if not tFunction.CheckModerator( tUser.sNick ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 120) )
			return true
		end
		if not tonumber(tBreak[1]) then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("gen", 5) )
			return true
		end
		local iID, tRow = tonumber( tBreak[1] ), tFunction.FetchRow( tonumber(tBreak[1]) )
		if not tRow then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 2) )
			return true
		end
		for iIndex = 2, #tBreak do
			local sMagnet = tBreak[iIndex]
			local bFlag, Value = tOffliner.am( tUser, iID, sMagnet )
			if not bFlag then
				Core.SendPmToUser( tUser, tConfig.sBotName, "Something went wrong. Contact hjpotter92" )
			else
				local sRoomReply, sPersonalReply = "Magnet %s added for entry #%d - %s", "The magnet has been added at ID #%d to entry #%d."
				sRoomReply = sRoomReply:format(sMagnet, iID, tRow.msg)
				Core.SendPmToUser( tUser, tCfg.sBotName, sPersonalReply:format(Value, iID) )
				tFunction.SendToAll( tUser.sNick, sRoomReply )
				SendToRoom( tUser.sNick, sRoomReply, tCfg.sReportBot, tCfg.iModProfile )
			end
		end
		return true

	elseif sCmd == "em" or sCmd == "editmagnet" then
		if not tFunction.CheckModerator( tUser.sNick ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 120) )
			return true
		end
		if not tonumber(tBreak[1]) then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("gen", 5) )
			return true
		end
		local iMID, sMagnet, tRow = tonumber( tBreak[1] ), tBreak[2], tFunction.FetchMagnetRow( tonumber(tBreak[1]) )
		if not tRow then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 2) )
			return true
		end
		if tProfiles.AllowVIP[tUser.iProfile] or tRow.nick:lower() == tUser.sNick:lower() then
			if not tOffliner.em( tUser, iMID, sMagnet ) then return true end
			local sRoomReply, sPersonalReply = "Magnet %s edited for magnetID #%d.", "The magnet entry #%d has been updated."
			sRoomReply = sRoomReply:format( sMagnet, iMID )
			Core.SendPmToUser( tUser, tCfg.sBotName, sPersonalReply:format(iMID) )
			tFunction.SendToAll( tUser.sNick, sRoomReply )
			SendToRoom( tUser.sNick, sRoomReply, tCfg.sReportBot, tCfg.iModProfile )
			return true
		else
			Core.SendPmToUser( tUser, tCfg.sBotName, "Something went wrong. Contact hjpotter92" )
			return true
		end

	elseif sCmd == "rm" or sCmd == "removemagnet" then
		if not tFunction.CheckModerator( tUser.sNick ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 120) )
			return true
		end
		for iIndex, iMID in pairs( tBreak ) do
			if not tonumber(iMID) then
				Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("gen", 5) )
			end
			local iMID, tRow = tonumber( iMID ), tFunction.FetchMagnetRow( tonumber(iMID) )
			if not tRow then
				Core.SendPmToUser( tUser, tCfg.sBotName, tFunction.Report("off", 2) )
			end
			if tRow and ( tProfiles.AllowVIP[tUser.iProfile] or tRow.nick:lower() == tUser.sNick:lower() ) then
				if tOffliner.rm( tUser, iMID, tRow.nick ) then
					local sReply = ("Magnet removed for magnetID #%d attached to entry #%d."):format( iMID, tRow.eid )
					Core.SendPmToUser( tUser, tCfg.sBotName, sReply )
					SendToRoom( tUser.sNick, sReply, tCfg.sReportBot )
				end
			end
		end
		return true

	elseif sCmd == "addmod" then
		if not tProfiles.AllowVIP[tUser.iProfile] then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! You don't have access to this command." )
			return true
		end
		if not RegMan.GetReg( tBreak[1] ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! The user "..tBreak[1].." must register first." )
			return true
		elseif tFunction.CheckModerator( tBreak[1] ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! The user "..tBreak[1].." is already a moderator." )
			return true
		end
		RegMan.ChangeReg( tBreak[1], RegMan.GetReg(tBreak[1]).sPassword, tCfg.iModProfile )
		if tOffliner.addmod( tUser, tBreak[1] ) then
			sAllModerators, sAllCategories = tFunction.Connect()
			local sChatMessage = "New moderator: "..tBreak[1].." ."
			tFunction.SendToAll( tUser.sNick, sChatMessage )
			SendToRoom( tUser.sNick, sChatMessage, tCfg.sReportBot )
			return true
		else
			return true
		end

	elseif sCmd == "delmod" then
		if not tProfiles.AllowVIP[tUser.iProfile] then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! You don't have access to this command." )
			return true
		end
		if not tFunction.CheckModerator( tBreak[1] ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! The user "..tBreak[1].." is not a moderator." )
			return true
		end
		tOffliner.delmod( tUser, tBreak[1] )
		sAllModerators, sAllCategories = tFunction.Connect()
		local sChatMessage = "Moderator removed: "..tBreak[1].." ."
		tFunction.SendToAll( tUser.sNick, sChatMessage )
		SendToRoom( tUser.sNick, sChatMessage, tCfg.sReportBot )
		if not RegMan.GetReg( tBreak[1] ) then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! The user "..tBreak[1].." is unregistered at the moment." )
			return true
		elseif not tProfiles.AllowAdmin[tUser.iProfile] then
			RegMan.ChangeReg( tBreak[1], RegMan.GetReg(tBreak[1]).sPassword, tCfg.iRegProfile )
			return true
		end
		return true

	elseif sCmd == "addctg" then
		if not tProfiles.AllowAdmin[tUser.iProfile] then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! You don't have access to this command." )
			return true
		end
		tOffliner.addctg( tUser, tBreak[1] )
		return true

	elseif sCmd == "delctg" then
		if not tProfiles.AllowAdmin[tUser.iProfile] then
			Core.SendPmToUser( tUser, tCfg.sBotName, "Sorry! You don't have access to this command." )
			return true
		end
		return true

	else
		return false
	end
	return false
end
