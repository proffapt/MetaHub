--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function OnStartup()
	tConfig = {
		tTemplates = {
			sHistory = "Past %d messages: \n\n\t%s\n\n",
			sList = "There are currently %d users in { %s }:\n\n\t",
		},
		sGlobalPath = "/www/ChatLogs/",
		sTimeFormat = "[%Y-%m-%d %H:%M:%S] ",
		iMaxHistory = 35,
		iTotalProfiles = #ProfMan.GetProfiles(),
		iTimerID = 0,					-- This will store the ID of timer set by PtokaX
		iRefreshRate = 20 * 1000,			-- Time in ms when the MyINFO will be refreshed. Right now, 20 seconds.
	}
	tChatRooms = {
		["#[ModzChat]"] = {
			BOT = {
				sDescription = "Chatroom for moderators.",
				sEmail = "donot@mail.me"
			},
			tChatHistory = { "Hi" },
			tUsers = {},
			sFileName = "ModsChat.txt",
			iMaxProfile = 4,			-- The maximum profile number allowed to access this chatroom.
		},
		["#[VIPChat]"] = {
			BOT = {
				sDescription = "Chatroom for usage by VIPs.",
				sEmail = "donot@mail.me"
			},
			tChatHistory = { "Hi" },
			tUsers = {},
			sFileName = "VIPChat.txt",
			iMaxProfile = 3,
		},
	}
	for sRoom, tRoom in pairs( tChatRooms ) do
		Core.RegBot( sRoom, tRoom.BOT.sDescription, tRoom.BOT.sEmail, true )
		for iIterate = 0, tRoom.iMaxProfile do
			local tRoomUsers = Core.GetOnlineUsers( iIterate )
			if tRoomUsers then
				for iIndex, tUser in pairs( tRoomUsers ) do
					table.insert( tRoom.tUsers, tUser.sNick )
				end
			end
		end
	end
	if tConfig.iTimerID == 0 then
		tConfig.iTimerID = TmrMan.AddTimer( tConfig.iRefreshRate )
	end
	Hide()
end

function UserConnected( tUser )
	Hide( tUser )
end

function RegConnected( tUser )
	local bIsSubscribed = false
	for sRoom, tRoom in pairs( tChatRooms ) do
		if tRoom.iMaxProfile >= tUser.iProfile then
			table.insert( tRoom.tUsers, tUser.sNick )
			bIsSubscribed = true
		end
	end
	if not bIsSubscribed then
		Hide( tUser )
	end
end

function RegDisconnected( tUser )
	for sRoom, tRoom in pairs( tChatRooms ) do
		if tRoom.iMaxProfile >= tUser.iProfile then
			DeleteNick( tRoom.tUsers, tUser.sNick )
		end
	end
end

OpConnected, OpDisconnected = RegConnected, RegDisconnected

function OnTimer( iID )
	Hide()
end

function ToArrival( tUser, sMessage )
	local sTo = sMessage:match "%$To: (%S+)"
	if not tChatRooms[sTo] or tUser.iProfile == -1 then
		return false
	end
	local tRoom = tChatRooms[sTo]
	if tUser.iProfile > tRoom.iMaxProfile then
		Core.SendPmToUser( tUser, sTo, "Sorry! You don't have access to the chatroom.|" )
		return true
	end
	local sChat = sMessage:match "%b$$(.*)|"
	local sCmd, sData = sChat:match "%b<>%s+[-+*/?!#](%w+)%s?(.*)"
	SaveToFile( sChat, sTo )
	if not sCmd then
		return SendToRoom( tUser, sTo, sChat )
	end
	local sCmd = sCmd:lower()
	if sCmd == "h" or sCmd == "history" then
		local sReply, iLimit = tConfig.tTemplates.sHistory, tonumber( sData )
		if (not iLimit) or iLimit > tConfig.iMaxHistory or iLimit < 0 then iLimit = 15 end
		sReply = sReply:format( iLimit, History(iLimit, sTo) )
		Core.SendPmToUser( tUser, sTo, sReply )
	elseif sCmd == "l" or sCmd == "list" then
		local sList = tConfig.tTemplates.sList:format( #tRoom.tUsers, sTo )
		Core.SendPmToUser( tUser, sTo, sList..table.concat(tRoom.tUsers, ", ") )
	else
		return SendToRoom( tUser, sTo, sChat )
	end
	return true
end

function History( iNumLines, sBotName )
	local tChatHistory = tChatRooms[sBotName].tChatHistory
	local iStartIndex = ( #tChatHistory - iNumLines ) + 1
	if #tChatHistory < iNumLines then
		iStartIndex = 1
	end
	if iStartIndex > #tChatHistory then
		iStartIndex = #tChatHistory
	end
	return table.concat( tChatHistory, "\n\t", iStartIndex, #tChatHistory )
end

function Hide( tUser )
	for sRoom, tRoom in pairs( tChatRooms ) do
		local sQuitINFO = "$Quit "..sRoom.."|"
		if tUser then
			Core.SendToUser( tUser, sQuitINFO )
		else
			Core.SendToProfile( -1, sQuitINFO )
			for iIterate = (tRoom.iMaxProfile + 1), (tConfig.iTotalProfiles - 1) do
				Core.SendToProfile( iIterate, sQuitINFO )
			end
		end
	end
end

function DeleteNick( tTable, sDeleteNick )
	local sDeleteNick = sDeleteNick:lower()
	for iIndex, sNick in ipairs( tTable ) do
		if sNick:lower() == sDeleteNick then
			table.remove( tTable, iIndex )
			break
		end
	end
end

function SaveToFile( sChatMessage, sRoom )
	local sChatMessage = sChatMessage:gsub( "&#(%d+);", string.char ):gsub( "[\n\r]+", "\n\t" ):gsub( "&amp;", "&" )
	local sStoreMessage = os.date( tConfig.sTimeFormat )..sChatMessage
	local fWrite = io.open( tConfig.sGlobalPath..os.date("%Y/%m/")..tChatRooms[sRoom].sFileName, "a" )
	fWrite:write( sStoreMessage, '\n' )
	fWrite:flush()
	fWrite:close()
	return true
end

function SendToRoom( tSelfUser, sRoom, sIncoming )
	local tCurrentHistory, tUsers, sSelfNick = tChatRooms[sRoom].tChatHistory, tChatRooms[sRoom].tUsers, tSelfUser.sNick:lower()
	table.insert( tCurrentHistory, os.date(tConfig.sTimeFormat)..sIncoming )
	if #tCurrentHistory > tConfig.iMaxHistory then
		table.remove( tCurrentHistory, 1 )
	end
	for iIndex, sNick in ipairs( tUsers ) do
		if sNick:lower() ~= sSelfNick then
			Core.SendToNick( sNick, "$To: "..sNick.." From: "..sRoom.." $"..sIncoming.."|" )
		end
	end
	return true
end

function OnExit()
	for sRoom in pairs( tChatRooms ) do
		Core.UnregBot( sRoom )
	end
	TmrMan.RemoveTimer( tConfig.iTimerID )
end
