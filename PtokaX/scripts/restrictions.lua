--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function OnStartup()
	package.path = Core.GetPtokaXPath().."scripts/?.lua;"..package.path
	local tConfig = {
		sBotName = SetMan.GetString( 21 ) or "PtokaX",
		sRequirePath = "external.restrict.",
		sHubAddress = SetMan.GetString( 2 ) or "localhost",
		sProtocol = "http://",
	}
	tFlags, tList = {
		bChat = true,
		bShare = true,
	}, {
		"chat",
		"share",
		"nicks",
		"search",
		"passive",
	}
	tConfig.sHubFAQ = tConfig.sProtocol..tConfig.sHubAddress.."/faq/%s/%04d"
	local function Error( sCode, iNum )
		return tConfig.sHubFAQ:format( sCode:upper(), iNum )
	end
	for iIndex, sScript in ipairs( tList ) do
		local r = require( tConfig.sRequirePath..sScript )
		tList[sScript] = r( tConfig.sBotName, Error )
	end
end

function ChatArrival( tUser, sMessage )
	local sCmd, sData = sMessage:match "%b<> [-+/*?#](%a+) (%a+)|"
	if ExecuteCommand( tUser, sCmd, sData ) then
		return true
	else
		return tList.chat( tUser, sMessage, tFlags.bChat )
	end
end

function UserConnected( tUser )
	tList.nicks( tUser )
	tList.passive( tUser )
end

function SearchArrival( tUser, sQuery )
	return tList.passive( tUser ) or tList.share( tUser, sQuery, tFlags.bShare ) or tList.search( tUser, sQuery )
end

RegConnected, OpConnected = UserConnected, UserConnected
ConnectToMeArrival, MultiConnectToMeArrival, RevConnectToMeArrival = SearchArrival, SearchArrival, SearchArrival

ExecuteCommand = ( function()
	local sReply = ( "<%s> { %%s } status updated to: %%s" ):format( SetMan.GetString(21) )
	return function ( tUser, sCmd, sState )
		if not ProfMan.GetProfilePermission( tUser.iProfile, 0 ) then return false end
		if not ( sCmd and sState ) then return false end
		local sCmd, sState, bState = sCmd:lower(), sState:lower()
		if sCmd == "mainchat" then
			if sState == "on" then
				tFlags.bChat = false
			elseif sState == "off" then
				tFlags.bChat = true
			end
			bState = tFlags.bChat
		elseif sCmd == "minshare" then
			if sState == "on" then
				tFlags.bShare = true
			elseif sState == "off" then
				tFlags.bShare = false
			end
			bState = tFlags.bShare
		else
			return false
		end
		Core.SendToUser( tUser, sReply:format(sCmd:upper(), tostring( bState )) )
		return true
	end
end )()
