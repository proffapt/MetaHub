--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

package.path = Core.GetPtokaXPath().."scripts/dependency/?.lua;"..package.path
local Connection = require "config", require "functions"
local tConfig = {
	sBotName = "[BOT]Info",
	sHub = SetMan.GetString( 2 ) or "localhost",
}
tConfig.sHubFAQ = "http://"..tConfig.sHub.."/faq/%s/%04d"

function OnError( sError )
	Core.SendToOpChat( sError )
end

_G.tFunction = {
	Connect = function()
		local luasql = luasql or require "luasql.mysql"
		if not ( SQLEnv and SQLCon ) then
			_G.SQLEnv = assert( luasql.mysql() )
			_G.SQLCon = assert( SQLEnv:connect(Connection 'latest') )
		end
		return tFunction.CheckCategory()
	end,

	Execute = function( sQuery )
		local luasql = luasql or require "luasql.mysql"
		local bSuccess, SQLCur = pcall( SQLCon.execute, SQLCon, sQuery )
		if not bSuccess then
			_G.SQLEnv = assert( luasql.mysql() )
			_G.SQLCon = assert( SQLEnv:connect(Connection 'latest') )
			SQLCur = assert( SQLCon:execute(sQuery) )
		end
		return SQLCur
	end,

	Report = ( function()
		local sReturn = ( "ERROR (%%s#%%04d): You should check %s for more information." ):format( tConfig.sHubFAQ )
		return function( sErrorCode, iErrorNumber )
			return sReturn:format( sErrorCode:upper(), iErrorNumber, sErrorCode:upper(), iErrorNumber )
		end
	end )(),

	CheckBnS = function( sInput )
		local tAvailable = { "buy", "sell", "loan", "hire" }
		for _, sCategories in ipairs( tAvailable ) do
			if sCategories:lower() == sInput:lower() then
				return sCategories:sub( 1, 1 ):upper()
			end
		end
		return false, table.concat( tAvailable, ", " )
	end,

	GetCategories = function()
           local tReturn, sCategoryQuery = {}, [[SELECT `name` FROM `ctgtable`]]
		local SQLCur = tFunction.Execute( sCategoryQuery )
		local tRow = SQLCur:fetch( {}, "a" )
		while tRow do
			table.insert( tReturn, tRow.name )
			tRow = SQLCur:fetch( {}, "a" )
		end
		SQLCur:close()
		return tReturn
	end,

	FetchRow = function( sTable, iID )
		local sFields, sQuery, tReturn = "msg, nick", "SELECT %s FROM `%s` WHERE id = %d LIMIT 1", {}

		if sTable == "requests" or sTable == "suggestions" then
			sFields = "`ctg`, "..sFields
		elseif sTable == "buynsell" then
			sFields = sFields..", CASE `type` WHEN 'B' THEN UPPER('buy') WHEN 'S' THEN UPPER('sell') WHEN 'H' THEN UPPER('hire') WHEN 'L' THEN UPPER('loan') WHEN 'T' THEN UPPER('bought') WHEN 'D' THEN UPPER('sold') END `type`"
		end
		sQuery = sQuery:format( sFields, sTable, iID )
		local SQLCur = tFunction.Execute( sQuery )
		tReturn = SQLCur:fetch( {}, "a" )
		SQLCur:close()
		return tReturn
	end,

	FetchReplies = function( iID )
		local sReturn, tTemporary, sQuery = "", {}, ([[SELECT id, nick, msg, dated FROM replies WHERE bns_id = %d ORDER BY id ASC]]):format( iID )
		local SQLCur = tFunction.Execute( sQuery )
		local tRow = SQLCur:fetch( {}, "a" )
		if tRow then
			while tRow do
				table.insert( tTemporary, ("%d. %s (From %s on %s)"):format(tRow.id, tRow.msg, tRow.nick, tRow.dated) )
				tRow = SQLCur:fetch( {}, "a" )
			end
			sReturn = "\n\t"..table.concat( tTemporary, "\n\t" ).."\n"
		else
			sReturn = ""
		end
		SQLCur:close()
		return sReturn
	end,

	SendToAll = function( sAsUser, sMessage )
		local sFileName = "/www/ChatLogs/"..os.date( "%Y/%m/%d_%m_%Y" )..".txt"
		local fWrite = io.open( sFileName, "a" )
		local sChatLine = "<"..sAsUser.."> "..sMessage
		if fWrite then
			fWrite:write( os.date("[%I:%M:%S %p]").." "..sChatLine.."\n" )
			fWrite:flush()
			fWrite:close()
		end
		Core.SendToAll( sChatLine )
		return sChatLine
	end
}

tFunction.CheckCategory = function( sInput )
	local sReturn, tTemporary, bFlag = "The possible categories are: ", tFunction.GetCategories(), false
	sReturn = sReturn..table.concat( tTemporary, ", " ).."\n"
	if not sInput then return sReturn end
	for iIndex, sValues in ipairs( tTemporary ) do
		if sValues:lower() == sInput:lower() then
			bFlag = true
			break
		end
	end
	if bFlag then
		return bFlag
	else
		return bFlag, sReturn
	end
end

_G.tInfobot = {
	readAll = function( iLimit )
		local sEntireList, tAllTables, sReadQuery, tList = "Welcome to HiT Hi FiT Hai - The IIT Kgp's Official hub.\n The following list was fetched by "..tConfig.sBotName.."\n\n", { "requests", "suggestions", "deletions", "guestbook", "news", "buynsell" }, [[SELECT %s
			FROM (
				SELECT %s
				FROM `%s`
				ORDER BY id DESC
				LIMIT %d
			) `temp`
			ORDER BY id ASC]], {}
		for iIndex, sTableName in pairs( tAllTables ) do
			local sList = tInfobot.readOne( sTableName:lower(), iLimit, true )
			if sList then
				table.insert( tList, sList )
				sList = nil
			end
		end
		return sEntireList..table.concat( tList, "\n\n\n" )
	end,

	readOne = function( sTable, iLimit, bReadAll )
		local sReturnList, sFields, sReadQuery, tTemporary, sEntry = "Welcome to HiT Hi FiT Hai - The IIT Kgp's Official hub.\n The following list was fetched by "..tConfig.sBotName.."\n\nTable: "..sTable:upper().."\t\t\tLimit: "..tostring(iLimit).."\n\n", "`id`, `msg`, `nick`, `dated`", [[SELECT *
			FROM (
				SELECT %s
				FROM `%s`
				ORDER BY id DESC
				LIMIT %d
			) `temp`
			ORDER BY id ASC]], {}, "%d. %s (Added by %s on %s)"
		if bReadAll then
			sReturnList = "Table: "..sTable:upper().."\t\t\tLimit: "..tostring(iLimit).."\n\n"
		end
		if sTable == "suggestions" then
			sFields = "`ctg`, "..sFields
			SQLCur = tFunction.Execute( sReadQuery:format( sFields, sTable, iLimit ))
			local tRow = SQLCur:fetch( {}, "a" )
			while tRow do
				table.insert( tTemporary, sEntry:format(tRow.id, ("[%s] - %s"):format(tRow.ctg, tRow.msg), tRow.nick, tRow.dated) )
				tRow = SQLCur:fetch( {}, "a" )
			end

		elseif sTable == "requests" then
			sFields = sFields:gsub( "`msg`", "CASE `filled` WHEN 'Y' THEN CONCAT(`msg`, ' (Filled by ', `filledby`, ' on ', filldate, ')') WHEN 'C' THEN CONCAT(`msg`, ' (Closed by ', `filledby`, ' on ', filldate, ')') WHEN 'N' THEN `msg` END `msg`" )..", `ctg`, CASE `filled` WHEN 'Y' THEN UPPER('filled') WHEN 'N' THEN UPPER('empty') WHEN 'C' THEN UPPER('closed') END `filled`"
			sReadQuery = sReadQuery:format( sFields, sTable, iLimit )
			SQLCur = tFunction.Execute( sReadQuery )
			local tRow = SQLCur:fetch( {}, "a" )
			while tRow do
				table.insert( tTemporary, sEntry:format(tRow.id, ("[%s] [%s] - %s"):format(tRow.filled, tRow.ctg, tRow.msg), tRow.nick, tRow.dated) )
				tRow = SQLCur:fetch( {}, "a" )
			end

		elseif sTable == "buynsell" then
			sFields = sFields..", CASE `type` WHEN 'B' THEN UPPER('buy') WHEN 'S' THEN UPPER('sell') WHEN 'H' THEN UPPER('hire') WHEN 'L' THEN UPPER('loan') WHEN 'T' THEN UPPER('bought') WHEN 'D' THEN UPPER('sold') END `type`"
			sReadQuery = sReadQuery:format( sFields, sTable, iLimit )
			SQLCur = tFunction.Execute( sReadQuery )
			local tRow = SQLCur:fetch( {}, "a" )
			while tRow do
				table.insert( tTemporary, sEntry:format(tRow.id, ("[%s] - %s"):format(tRow.type, tRow.msg), tRow.nick, tRow.dated)..tFunction.FetchReplies(tRow.id) )
				tRow = SQLCur:fetch( {}, "a" )
			end

		else
			SQLCur = tFunction.Execute( sReadQuery:format( sFields, sTable, iLimit ))
			local tRow = SQLCur:fetch( {}, "a" )
			while tRow do
				table.insert( tTemporary, sEntry:format(tRow.id, tRow.msg, tRow.nick, tRow.dated) )
				tRow = SQLCur:fetch( {}, "a" )
			end
		end
		return ( sReturnList..table.concat(tTemporary, "\n") )
	end,

	add = function( tUser, tInput )
		if tInput.sMsg:len() < 20 then
			Core.SendPmToUser( tUser, tConfig.sBotName, "The string to be added must be at least 20 characters." )
			return false
		end
		local sFields, sValues = "`msg`, `nick`, `dated`", ("'%s', '%s', NOW()"):format( SQLCon:escape(tInput.sMsg), SQLCon:escape(tUser.sNick) )
		if tInput.sTable:lower() == "requests" or tInput.sTable:lower() == "suggestions" then
			sFields, sValues = "`ctg`, "..sFields, ("'%s', %s"):format( SQLCon:escape(tInput.sCtg), sValues )
		elseif tInput.sTable:lower() == "buynsell" then
			sFields, sValues = "`type`, "..sFields, ("'%s', %s"):format( tInput.sType, sValues )
		elseif tInput.sTable:lower() == "replies" then
			sFields, sValues = "`bns_id`, "..sFields, ("%d, %s"):format( tInput.iID, sValues )
		end
		local sQuery = [[INSERT IGNORE INTO `%s`(%s)
			VALUES (%s) ]]
		sQuery = sQuery:format( tInput.sTable, sFields, sValues )
		local SQLCur = tFunction.Execute( sQuery )
		if type( SQLCur ) ~= "number" then
			SQLCur:close()
		else
			SQLCur = nil
		end
		return SQLCon:getlastautoid()
	end,

	StoreMessage = function( sSender, sRecipient, sMessage )
		if Core.GetUser( sRecipient ) then
			Core.SendPmToNick( sRecipient, sSender, sMessage )
			return 0, "Message delivered"
		end
		local sStorageQuery = [[INSERT INTO messages(message, `from`, `to`, dated)
			VALUES ( '%s', '%s', '%s', NOW() ) ]]

		sStorageQuery = sStorageQuery:format( SQLCon:escape(sMessage), SQLCon:escape(sSender), SQLCon:escape(sRecipient) )
		local SQLCur = tFunction.Execute( sStorageQuery )
		return SQLCon:getlastautoid()
	end,

	del = function( tUser, tInput )
		if tInput.sTable == "buynsell" then
			local sDeleteQuery = string.format( "DELETE b.*, r.* FROM `buynsell` b LEFT JOIN `replies` r ON r.`bns_id` = b.`id` WHERE b.`id` = %d", tInput.iID )
			local SQLCur = tFunction.Execute( sDeleteQuery )
			if type( SQLCur ) ~= "number" then SQLCur:close() end
			return true
		end
		local sDeleteQuery = string.format( "DELETE FROM `%s` WHERE `id` = %d", SQLCon:escape(tInput.sTable), tInput.iID )
		local SQLCur = tFunction.Execute( sDeleteQuery )
		if type( SQLCur ) ~= "number" then SQLCur:close() end
		return true
	end,

	fill = function( tUser, iID, bClosure )
		local sUpdateQuery = [[UPDATE requests
			SET filled = '%s',
				filldate = NOW(),
				filledby = '%s'
			WHERE id = %d
			LIMIT 1]]
		sUpdateQuery = sUpdateQuery:format( (bClosure and 'C') or 'Y', SQLCon:escape(tUser.sNick), iID )
		local SQLCur = tFunction.Execute( sUpdateQuery )
		if type( SQLCur ) ~= "number" then
			SQLCur:close()
		else
			SQLCur = nil
		end
		return true
	end,

	switch = function( iID )
		local sUpdateQuery = [[UPDATE `buynsell`
			SET `type` = CASE `type` WHEN 'B' THEN 'T' WHEN 'S' THEN 'D' END
			WHERE `id` = %d
			LIMIT 1]]
		sUpdateQuery = sUpdateQuery:format( iID )
		local SQLCur = tFunction.Execute( sUpdateQuery )
		if type( SQLCur ) ~= "number" then
			SQLCur:close()
		else
			SQLCur = nil
		end
		return true
	end
}

function OnExit()
	Core.UnregBot( tConfig.sBotName )
	SQLCon:close()
	SQLEnv:close()
end
