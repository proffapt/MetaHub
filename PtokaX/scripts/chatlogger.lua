--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

local tConfig, tChatHistory = {
	sBotName = SetMan.GetString( 21 ) or "PtokaX",
	sProfiles = "012",		-- No history for commands from users with profiles
	sLogsPath = "/www/ChatLogs/",
	sTimeFormat = "[%I:%M:%S %p] ",
	sPath = Core.GetPtokaXPath().."scripts/texts/",
	iMaxLines = 100,
    iTempProfile = 6,
}, { "Hi!" }
local tTickers = {
	tTopics = {},
	sTickerPrefix = "",
	sTickersList = "tickers.txt",
	sUpdated = ( "<%s> Hub topic was updated by [ %%s ] to %%s." ):format( tConfig.sBotName ),
	iTickerDelay = 6 * 60 * 60 * 10^3,		-- 6 hours to milliseconds
	iTickerID = false,
	iTopicIndex = 0,
}

function OnStartup()
	ExecuteCommand.reloadtickers()
end

function ChatArrival( tUser, sMessage )
	LogMessage( sMessage:sub(1, -2) )
	local sCmd, sData = sMessage:match "%b<> [-+*/?!#](%w+)%s?(.*)|"
	if not sCmd then
		return AddHistory( tUser, sMessage:sub(1, -2) )
	end
	sCmd = sCmd:lower()
	if ExecuteCommand[sCmd] then
		return ExecuteCommand[sCmd]( tUser, sData, false )
	end
	return AddHistory( tUser, sMessage:sub(1, -2), true )
end

function ToArrival( tUser, sMessage )
	local sTo, sFrom = sMessage:match "$To: (%S+) From: (%S+)"
	if sTo ~= tConfig.sBotName then return false end
	local sCmd, sData = sMessage:match "%b$$%b<> [-+*/?!#](%w+)%s?(.*)|"
	if not sCmd then
		return false
	end
	sCmd = sCmd:lower()
	if ExecuteCommand[sCmd] then
		return ExecuteCommand[sCmd]( tUser, sData, true )
	end
	return false
end

function RegConnected( tUser )
	if tUser.iProfile == -1 then return end
	local sLastLines = "<"..tConfig.sBotName.."> Here is what was happening a few moments ago:\n\t"
	sLastLines = sLastLines..History( 15 )
	Core.SendToUser( tUser, sLastLines )
end

OpConnected = RegConnected

function OnTimer( iTimerID )
	if tTickers.iTickerID ~= iTimerID then
		return false
	end
	local tTopics = tTickers.tTopics
	tTickers.iTopicIndex = ( tTickers.iTopicIndex % #tTopics ) + 1
	local tCurrentTopic = tTopics[ tTickers.iTopicIndex ]
	local sTopic, bHasPrefix = tCurrentTopic.sTopic, tTickers.sTickerPrefix:len() > 0
	if bHasPrefix then sTopic = tTickers.sTickerPrefix.." &#124; "..sTopic end
	SetMan.SetString( 10, sTopic )
	Core.SendToAll( tTickers.sUpdated:format(tCurrentTopic.sNick, sTopic) )
	return true
end

function AddHistory( tUser, sInput, bIsCommand )
    if tUser.iProfile == tConfig.iTempProfile then return false end
	local sChatLine = os.date( tConfig.sTimeFormat )..sInput
	if not( bIsCommand and tConfig.sProfiles:find(tUser.iProfile) ) then
		table.insert( tChatHistory, sChatLine )
		if tChatHistory[ tConfig.iMaxLines + 1 ] then
			table.remove( tChatHistory, 1 )
		end
	end
	return false
end

function History( iNumLines )
	local iStartIndex, iTotalLines = ( #tChatHistory - iNumLines ) + 1, #tChatHistory
	if iTotalLines < iNumLines then
		iStartIndex = 1
	end
	if iStartIndex > iTotalLines then
		iStartIndex = iTotalLines
	end
	return table.concat( tChatHistory, "\n\t", iStartIndex, iTotalLines )
end

function WriteFile( sFilePath, sLine )
	local fHandle = io.open( sFilePath, 'a' )
	fHandle:write( sLine, "\n" )
	fHandle:close()
end

function LogMessage( sLine )
	local sTime = os.date( tConfig.sTimeFormat )
	local sChatLine, sFileName = sTime..sLine, tConfig.sLogsPath..os.date( "%Y/%m/%d_%m_%Y" )..".txt"
	sChatLine = sChatLine:gsub( "&#(%d+);", string.char ):gsub( "[\n\r]+", "\n\t" ):gsub( "&amp;", "&" )
	return WriteFile( sFileName, sChatLine )
end

function CheckPermission( iProfile )
	if not ProfMan.GetProfilePermission( iProfile, 7 ) then return false end
	return true
end

function Reply( tUser, sMessage, bIsPM )
	if bIsPM then
		Core.SendPmToUser( tUser, tConfig.sBotName, sMessage )
	else
		Core.SendToUser( tUser, sMessage )
	end
	return true
end

ExecuteCommand = {
	history = ( function()
		local sPrefix = ( "<%s> \n\r\t\tChat history bot for HiT Hi FiT Hai\n\tShowing the mainchat history for past %%d messages\n\t" ):format( tConfig.sBotName )
		return function( tUser, sData, bIsPM )
			local iLimit = tonumber( sData )
			if (not iLimit) or iLimit > tConfig.iMaxLines or iLimit < 0 then iLimit = 15 end
			local sReply = sPrefix:format(iLimit)..History(iLimit)
			return Reply( tUser, sReply, bIsPM )
		end
	end )(),

	hubtopic = ( function()
		local sPrefix, sNoTopic = ( "<%s> Current hub topic is: %%s." ):format( tConfig.sBotName ), "Sorry! No hub topic exists."
		return function( tUser, sData, bIsPM )
			local sReply = sPrefix:format( SetMan.GetString(10) or sNoTopic )
			return Reply( tUser, sReply, bIsPM )
		end
	end )(),

	topic = ( function()
		local sErased, sUpdated = ( "<%s> Hub topic was erased by [ %%s ]." ):format( tConfig.sBotName ), ( "<%s> Hub topic was updated by [ %%s ] to %%s." ):format( tConfig.sBotName )
		return function( tUser, sData, bIsPM )
			if not CheckPermission( tUser.iProfile ) then return false end
			if sData:len() == 0 or sData:lower() == "off" then
				Core.SendToAll( sErased:format(tUser.sNick) )
				return ExecuteCommand.ticker( tUser, sData, bIsPM )
			end
			if tTickers.iTickerID then
				TmrMan.RemoveTimer( tTickers.iTickerID )
				tTickers.iTickerID = false
			end
			SetMan.SetString( 10, sData )
			Core.SendToAll( sUpdated:format(tUser.sNick, sData) )
			return true
		end
	end )(),

	ticker = ( function()
		local sReply = ( "<%s> Topics ticker has been activated." ):format( tConfig.sBotName )
		return function( tUser, sData, bIsPM )
			if not CheckPermission( tUser.iProfile ) then return false end
			if tTickers.iTickerID then return false end
			tTickers.iTickerDelay = ( tonumber(sData) or tTickers.iTickerDelay ) * 60 * 60 * 10^3
			tTickers.iTickerID = TmrMan.AddTimer( tTickers.iTickerDelay )
			OnTimer( tTickers.iTickerID )
			return Reply( tUser, sReply, bIsPM )
		end
	end )(),

	tickeradd = ( function()
		local sFilePath, sReply, sTemplate = tConfig.sPath..tTickers.sTickersList, ( "<%s> The topic has been added to tickers list." ):format( tConfig.sBotName ), "%s %s"
		return function( tUser, sData, bIsPM )
			if not CheckPermission( tUser.iProfile ) then return false end
			local sNick, sTopic = sData:match "%-u (%S+) (.+)"
			if not sNick then
				sNick, sTopic = tUser.sNick, sData
			end
			table.insert( tTickers.tTopics, {sNick = sNick, sTopic = sTopic} )
			WriteFile( sFilePath, sTemplate:format(sNick, sTopic) )
			return Reply( tUser, sReply, bIsPM )
		end
	end )(),

	reloadtickers = ( function()
		local sFilePath, sReply = tConfig.sPath..tTickers.sTickersList, ( "<%s> Tickers list reloaded." ):format( tConfig.sBotName )
		return function( tUser, sData, bIsPM )
			local fTickerHandle, tList = io.open( sFilePath, "r" ), {}
			if not fTickerHandle then
				return false
			end
			for sLine in fTickerHandle:lines "*l" do
				local sNick, sTopic = sLine:match "^(%S+) (.+)$"
				table.insert( tList, {sNick = sNick, sTopic = sTopic} )
			end
			fTickerHandle:close()
			tTickers.tTopics = tList
			if tUser then
				return Reply( tUser, sReply, bIsPM )
			end
			return true
		end
	end )(),

	tickerprefix = ( function()
		local sReply = ( "<%s> The ticker prefix has been updated to [ %%s ]." ):format( tConfig.sBotName )
		return function( tUser, sData, bIsPM )
			if not CheckPermission( tUser.iProfile ) then return false end
			if not sData then return false end
			if sData == "" or sData:lower() == "off" then
				tTickers.sTickerPrefix = ""
			else
				tTickers.sTickerPrefix = sData
			end
			OnTimer( tTickers.iTickerID )
			return Reply( tUser, sReply:format(sData), bIsPM )
		end
	end )(),
}
