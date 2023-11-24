--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

package.path = Core.GetPtokaXPath().."scripts/dependency/?.lua;"..package.path
local Connection = require 'config'
local tConfig = {
	sBotName = "[BOT]Offliner",
	sHub = SetMan.GetString( 2 ) or "localhost"
}
tConfig.sHubFAQ = "http://"..tConfig.sHub.."/faq/%s/%04d"
tConfig.sLatestPage = "http://"..tConfig.sHub.."/latest/"

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
		return tFunction.CheckModerator(), tFunction.CheckCategory()
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

	FindMagnet = function( sInput, tUser )
		local sTTH, sSize, sName = sInput:match "^.*magnet[:]%?xt=urn[:]tree[:]tiger[:](%w+)&xl=(%d+)&dn=(.+)$"
		if not ( sTTH and sSize and sName ) then return false end
		if sTTH:len() == 0 or sSize:len() == 0 or sName:len() == 0 then
			return false
		elseif sTTH:len() ~= 39 then
			Core.SendPmToUser( tUser, tConfig.sBotName, tFunction.Report("off", 80) )
		elseif sName:len() > 255 then
			Core.SendPmToUser( tUser, tConfig.sBotName, "Filename length should be less than 250 characters." )
		end
		return { tth = sTTH, size = sSize, name = SQLCon:escape(sName) }
	end,

	CreateLatestReading = function( tEntry )
		local sMagnets = tFunction.FetchMagnets( tonumber(tEntry.id) )
		local sEntry = string.format( "%d. [%s] - %s (Added by %s on %s)", tEntry.id, tEntry.ctg, tEntry.msg, tEntry.nick, tEntry.date )
		if sMagnets then
			return sEntry.."\n\t"..sMagnets
		else
			return sEntry
		end
	end,

	GetCategories = function()
		local tReturn, sCategoryQuery = {}, [[SELECT name FROM ctgtable]]
		local SQLCur = tFunction.Execute( sCategoryQuery )
		local tRow = SQLCur:fetch( {}, "a" )
		while tRow do
			table.insert( tReturn, tRow.name )
			tRow = SQLCur:fetch( {}, "a" )
		end
		SQLCur:close()
		return tReturn
	end,

	GetSize = function( iSize )
		local iSizeTemp, sPrefix, i = tonumber(iSize) or 0, {"", "Ki", "Mi", "Gi", "Ti", "Pi"}, 1
		while iSizeTemp > 1024 do
			iSizeTemp, i = iSizeTemp/1024, i+1
		end
		return string.format( "%.2f %sB", iSizeTemp, sPrefix[i] )
	end,

	GetModerators = function()
		local tReturn, sCategoryQuery = {}, "SELECT nick FROM modtable WHERE active = 'Y' AND deletions < 11 ORDER BY id ASC"
		local SQLCur = tFunction.Execute( sCategoryQuery )
		local tRow = SQLCur:fetch( {}, "a" )
		while tRow do
			table.insert( tReturn, tRow.nick )
			tRow = SQLCur:fetch( {}, "a" )
		end
		SQLCur:close()
		return tReturn
	end,

	InsertProcedure = function( sProcName, tInput )
		local sInsertQuery, sIDQuery = "", ""
		if sProcName:lower() == "newmagnet" then
			sInsertQuery, sIDQuery = [[CALL NewMagnet('%s', '%s', '%s', '%s', '%s', @mgid)]], [[SELECT @mgid AS magnetID]]
			sInsertQuery = sInsertQuery:format( tInput.nick, tInput.tth, tInput.name, tInput.size, tInput.eid )
		elseif sProcName:lower() == "newentry" then
			sInsertQuery, sIDQuery = [[CALL NewEntry( '%s', '%s', '%s', '%s', '%s', '%s', @eid, @mgid )]], [[SELECT @eid AS entryID, @mgid AS magnetID]]
			sInsertQuery = sInsertQuery:format( tInput.ctg, tInput.msg, tInput.nick, tInput.tth, tInput.name, tInput.size )
		end
		local SQLCur = tFunction.Execute( sInsertQuery )
		SQLCur = tFunction.Execute( sIDQuery )
		if type( SQLCur ) ~= "string" then
			local tRow = SQLCur:fetch( {}, "a" )
			SQLCur:close()
			return tRow
		end
		return false
	end,

	FetchRow = function( iID )
		local tReturn, sQuery = {}, string.format( "SELECT e.id, c.name AS ctg, e.msg, m.nick AS nick, e.date FROM entries e INNER JOIN ctgtable c ON c.id = e.ctg INNER JOIN modtable m ON m.id = e.nick WHERE e.id = %d LIMIT 1", iID )
		local SQLCur = tFunction.Execute( sQuery )
		tReturn = SQLCur:fetch( {}, "a" )
		SQLCur:close()
		return tReturn
	end,

	FetchMagnetRow = function( iMID )
		local tReturn, sQuery = {}, string.format( [[SELECT m.id AS id,
			m.eid AS eid,
			m.tth AS tth,
			m.size AS size,
			m2.nick AS nick,
			m.date AS `date`,
			e.msg AS msg
		FROM magnets m
		INNER JOIN entries e
			ON e.id = m.eid
		INNER JOIN modtable m2
			ON m2.id = m.nick
		WHERE m.id = %d
		LIMIT 1]], iMID )
		local SQLCur = tFunction.Execute( sQuery )
		tReturn = SQLCur:fetch( {}, "a" )
		SQLCur:close()
		return tReturn
	end,

	FetchMagnets = function( iEID )
		local tReturn, sQuery, sTemplate = {}, [[SELECT m.id,
			m.tth,
			m.size,
			m2.nick AS nick,
			m.date,
			f.filename AS name
		FROM magnets m
		INNER JOIN modtable m2
			ON m2.id = m.nick
		LEFT JOIN filenames f
			ON f.magnet_id = m.id
		WHERE eid = %d
		ORDER BY date DESC
		LIMIT 5]], "%s. [%s] magnet:?xt=urn:tree:tiger:%s&xl=%s (Added by %s on %s)"
		local SQLCur = tFunction.Execute(sQuery:format( iEID ))
		if SQLCur:numrows() == 0 then
			return nil
		end
		local tRow = SQLCur:fetch( {}, "a" )
		while tRow do
			local sSize = tFunction.GetSize( tRow.size )
			if tRow.name then
				tRow.size = ("%s&dn=%s"):format(tRow.size, tRow.name)
			end
			table.insert( tReturn, sTemplate:format(tRow.id, sSize, tRow.tth, tRow.size, tRow.nick, tRow.date) )
			tRow = SQLCur:fetch( {}, "a" )
		end
		SQLCur:close()
		return table.concat( tReturn, "\n\t" )
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
	local sReturn, tTemporary, bFlag = "The following %02d categories are allowed: %s\n", tFunction.GetCategories(), false
	sReturn = sReturn:format( #tTemporary, table.concat(tTemporary, ", ") )
	if not sInput then return sReturn end
	sInput = sInput:lower()
	for iIndex, sValue in ipairs( tTemporary ) do
		if sValue:lower() == sInput then
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

tFunction.CheckModerator = function( sInput )
	local sReturn, tTemporary, bFlag = "There are %03d moderators active: \n\n%s\n", tFunction.GetModerators(), false
	sReturn = sReturn:format( #tTemporary, table.concat(tTemporary, ", ") )
	if not sInput then return sReturn end
	if sInput then
		for iIndex, sValues in ipairs( tTemporary ) do
			if sValues:lower() == sInput:lower() then
				bFlag = true
				break
			end
		end
	end
	if bFlag then
		return bFlag
	else
		return bFlag, sReturn
	end
end

_G.tOffliner = {
	l = function( tUser, iLimit, sCategory )
		local sLatestQuery, tTemporary, sSuffix = [[SELECT id,
			ctg,
			msg,
			nick,
			date
		FROM ( SELECT e.id,
				c.name AS ctg,
				e.msg,
				m.nick AS nick,
				e.date
			FROM entries e
			INNER JOIN ctgtable c
				ON c.id = e.ctg
			INNER JOIN modtable m
				ON m.id = e.nick
			WHERE c.name %s
			ORDER BY id DESC
			LIMIT %d ) AS temp
		ORDER BY id ASC]], {}, "get_latest.php"
		local sPMToUser = "Welcome to HiT Hi FiT Hai - The IIT Kgp's Official hub.\n\n\t[BOT]Offliner fetched following information:\n\n"
		if not iLimit and not sCategory then
			iLimit = 35
			sCategory = "<> 'sdmovie' OR (c.name = 'sdmovie' AND e.msg LIKE '%[DVDRIP]%')"

		else
			if iLimit > 50 or iLimit < 5 then
				iLimit = 5
			else
				iLimit = iLimit
			end
			if not sCategory then
				sCategory = "<> 'sdmovie' OR (c.name = 'sdmovie' AND e.msg LIKE '%[DVDRIP]%')"
			else
				if not tFunction.CheckCategory(sCategory) then
				   sCategory = "<> 'sdmovie' OR (c.name = 'sdmovie' AND e.msg LIKE '%[DVDRIP]%')"
				else
					sSuffix = sCategory
					sCategory = "= '"..sCategory.."'"
				end
			end
		end
		sSuffix = tConfig.sLatestPage..sSuffix
		sLatestQuery = sLatestQuery:format( sCategory, iLimit )
		local SQLCur = tFunction.Execute( sLatestQuery )
		if SQLCur:numrows() == 0 then
			Core.SendPmToUser( tUser, tConfig.sBotName, sPMToUser.."No result was obtained for your query.|" )
			return
		end
		local tRow = SQLCur:fetch( {}, "a" )
		while tRow do
			table.insert( tTemporary, tFunction.CreateLatestReading(tRow) )
			tRow = SQLCur:fetch( {}, "a" )
		end
		sPMToUser = sPMToUser..table.concat( tTemporary, "\n\n" )
		Core.SendPmToUser( tUser, tConfig.sBotName, sPMToUser.."\n\nThese results are displayed on the hub-webpage: "..sSuffix.."|" )
		if type( SQLCur ) ~= "number" then SQLCur:close() end
		return true
	end,

	s = function( tUser, sSearchString )
		local sSearchQuery, sSuffix, sPMToUser, tTemporary = [[SELECT id,
			ctg,
			msg,
			nick,
			date
		FROM ( SELECT e.id,
				c.name AS ctg,
				e.msg,
				m.nick AS nick,
				e.date
			FROM entries e
			INNER JOIN ctgtable c
				ON c.id = e.ctg
			INNER JOIN modtable m
				ON m.id = e.nick
			WHERE e.msg LIKE '%%%s%%']], "s/", "Welcome to HiT Hi FiT Hai - The IIT Kgp's Official hub.\n\n\t[BOT]Offliner fetched following information for the search:\n\n", {}
		for sTemp in sSearchString:gmatch( "%{(.-)%}" ) do
			table.insert( tTemporary, sTemp )
		end
		if #tTemporary > 0 then
			sSearchString = sSearchString:gsub("[%s+]?%{.-%}[%s+]?", '')
			sSearchQuery = sSearchQuery.." AND c.name IN (%s) "
		end
		if sSearchString:len() < 3 then
			Core.SendPmToUser( tUser, tConfig.sBotName, tFunction.Report("off", 1) )
			return true
		end
		sSearchQuery = sSearchQuery..[[
			ORDER BY e.id DESC
			LIMIT 20 ) AS temp
		ORDER BY id ASC]]

		if #tTemporary == 0 then
			sSearchQuery = sSearchQuery:format( SQLCon:escape(sSearchString) )
		else
			sSearchQuery = sSearchQuery:format( SQLCon:escape(sSearchString), "'"..table.concat(tTemporary, "', '").."'" )
		end
		tTemporary = {}
		local SQLCur = tFunction.Execute( sSearchQuery )
		if SQLCur:numrows() == 0 then
			Core.SendPmToUser( tUser, tConfig.sBotName, sPMToUser.."No result was obtained for your query.|" )
			return true
		end
		sSuffix = tConfig.sLatestPage..sSuffix..sSearchString:gsub( "%s+", "+" )
		local tRow = SQLCur:fetch( {}, "a" )
		while tRow do
			table.insert( tTemporary, tFunction.CreateLatestReading(tRow) )
			tRow = SQLCur:fetch( {}, "a" )
		end
		sPMToUser = sPMToUser..table.concat( tTemporary, "\n\n" )
		Core.SendPmToUser( tUser, tConfig.sBotName, sPMToUser.."\n\nThese search results are linked to: "..sSuffix.."|" )
		if type( SQLCur ) ~= "number" then SQLCur:close() end
		return true
	end,

	al = function( tUser, tInput )
		local sCategory, sEntry, sMagnet = tInput[1], table.concat( tInput, " ", 2, #tInput - 1 ), tInput[#tInput]
		local tMagnet, sError = tFunction.FindMagnet( sMagnet, tUser ), "Something went wrong. Contact hjpotter92"
		if not tMagnet then
			return false
		end
		if sEntry:len() > 255 then
			Core.SendPmToUser( tUser, tConfig.sBotName, "Too long entry" )
			return false
		end
		tMagnet.ctg, tMagnet.msg, tMagnet.nick = sCategory, SQLCon:escape( sEntry ), SQLCon:escape( tUser.sNick )
		local tOutput = tFunction.InsertProcedure( 'newentry', tMagnet )
		if not tOutput then
			Core.SendPmToUser( tUser, tConfig.sBotName, sError )
			return false
		end
		if tOutput.entryID == -1 or tOutput.magnetID == -1 then
			Core.SendPmToUser( tUser, tConfig.sBotName, sError )
			return false
		end
		local sReply = ("Your message has been added to database at entry ID #%s and magnet ID #%s."):format( tOutput.entryID, tOutput.magnetID )
		Core.SendPmToUser( tUser, tConfig.sBotName, sReply )
		return true
	end,

	dl = function( tUser, iID, sModNick )
		local sDeleteQuery = string.format( [[DELETE e.*, m.*, f.*
			FROM entries e
			LEFT JOIN magnets m
				ON m.eid = e.id
			LEFT JOIN filenames f
				ON m.id = f.magnet_id
			WHERE e.id = %d]], iID )
		local SQLCur = tFunction.Execute( sDeleteQuery )
		if sModNick:lower() ~= tUser.sNick:lower() then
			local SQLCur = tFunction.Execute( "UPDATE modtable SET deletions = deletions + 2 WHERE nick = '"..SQLCon:escape(sModNick).."'" )
		end
		if type( SQLCur ) ~= "number" then SQLCur:close() end
		return true
	end,

	ul = function( tUser, tInput )
		local iID, sContent, sUpdateQuery = tonumber(tInput[1]), table.concat(tInput, " ", 2), [[UPDATE entries
		SET msg = '%s'
		WHERE id = %d]]
		sUpdateQuery = sUpdateQuery:format( SQLCon:escape(sContent), iID )
		if not sContent:find( "magnet%:%?" ) then
			local SQLCur = tFunction.Execute( sUpdateQuery )
			if type( SQLCur ) ~= "number" then SQLCur:close() end
			return true
		else
			Core.SendPmToUser( tUser, tConfig.sBotName, "Sorry! You must remove magnet when updating." )
			return false
		end
	end,

	addmod = function( tUser, sModNick )
		local sAddModerator = [[INSERT INTO modtable (nick, added_by, active, date)
		VALUES( '%s', '%s', 'Y', NOW() )
		ON DUPLICATE KEY
		UPDATE
			active = 'Y',
			added_by = '%s',
			deletions = 0,
			date = NOW() ]]
		sAddModerator = sAddModerator:format( SQLCon:escape(sModNick), SQLCon:escape(tUser.sNick), SQLCon:escape(tUser.sNick) )
		local SQLCur = tFunction.Execute( sAddModerator )
		if type( SQLCur ) ~= "number" then SQLCur:close() end
		return true
	end,

	delmod = function( tUser, sModNick )
		local sRemoveModerator = [[UPDATE modtable
		SET active = 'N',
			deletions = 50,
			date = NOW()
		WHERE nick = '%s' ]]
		sRemoveModerator = sRemoveModerator:format( SQLCon:escape(sModNick) )
		local SQLCur = tFunction.Execute( sRemoveModerator )
		return true
	end,

	addctg = function( tUser, sCategory )
		local sAddCategory = string.format( "INSERT INTO ctgtable (name) VALUES( '%s')", SQLCon:escape(sCategory) )
		local SQLCur = tFunction.Execute( sAddCategory )
		if type( SQLCur ) ~= "number" then SQLCur:close() end
		return true
	end,

	delctg = function( tUser, sCategory )
		local sRemoveCategory = "DELETE FROM ctgtable WHERE name = '"..sCategory.."'"
		local SQLCur = tFunction.Execute( sRemoveCategory )
		if type( SQLCur ) ~= "number" then SQLCur:close() end
		return true
	end,

	am = function( tUser, iID, sMagnet )
		local sModNick = SQLCon:escape( tUser.sNick )
		local tMagnet = tFunction.FindMagnet( sMagnet, tUser )
		if not tMagnet then
			return false
		end
		tMagnet.eid, tMagnet.nick = iID, sModNick
		local tOutput = tFunction.InsertProcedure( 'newmagnet', tMagnet )
		if not tOutput or tOutput.magnetID == -1 then
			return false
		end
		return true, tOutput.magnetID
	end,

	em = function( tUser, iMID, sMagnet )
		local tMagnet = tFunction.FindMagnet( sMagnet )
		local sMagnetQuery, sNameQuery = [[UPDATE magnets
		SET tth = '%s',
			size = %s,
			date = NOW()
		WHERE id = %d ]], [[INSERT INTO filenames
		VALUES (
			%d,
			'%s'
		)
		ON DUPLICATE KEY
		UPDATE
			filename = '%s']]
		if not tMagnet then
			return false
		end
		sMagnetQuery, sNameQuery = sMagnetQuery:format( tMagnet.tth, tMagnet.size, iMID ), sNameQuery:format( iMID, tMagnet.name, tMagnet.name )
		local SQLCur = tFunction.Execute(sMagnetQuery)
		SQLCur = tFunction.Execute(sNameQuery)
		if type( SQLCur ) ~= "number" then SQLCur:close() end
		return true
	end,

	rm = function( tUser, iMID, sModNick )
		local sMagnetQuery = [[DELETE m.*, f.*
		FROM magnets m
		LEFT JOIN filenames f
			ON m.id = f.magnet_id
		WHERE m.id = %d ]]
		local SQLCur = tFunction.Execute(sMagnetQuery:format(iMID))
		if sModNick:lower() ~= tUser.sNick:lower() then
			local SQLCur = tFunction.Execute( "UPDATE modtable SET deletions = deletions + 1 WHERE nick = '"..SQLCon:escape(sModNick).."'" )
		end
		if type( SQLCur ) ~= "number" then SQLCur:close() end
		return true
	end,

	StoreMessage = function( sSender, sRecipient, sMessage )
		local tRecipient = Core.GetUser( sRecipient )
		if tRecipient then
			Core.SendPmToUser( tRecipient, sSender, sMessage )
			Core.SendPmToNick( sSender, tConfig.sBotName, "User was online. Message delivered." )
			return false
		end
		local sStorageQuery = [[INSERT INTO messages (message, `from`, `to`, dated)
		VALUES ( '%s', '%s', '%s', NOW() ) ]]
		sStorageQuery = sStorageQuery:format( SQLCon:escape(sMessage), SQLCon:escape(sSender), SQLCon:escape(sRecipient) )
		local SQLCur = tFunction.Execute( sStorageQuery )
		local sReply = "The message has been stored with ID: #%d. It'll be delivered to %s when they connect to hub."
		Core.SendPmToNick( sSender, tConfig.sBotName, sReply:format(SQLCon:getlastautoid(), sRecipient) )
		return true
	end,

	PassMessage = function( sNick )
		local sSearchUserQuery = [[SELECT id,
			`from`,
			dated,
			message
		FROM messages
		WHERE `to` = '%s'
			AND delivered = 'N' ]]
		sSearchUserQuery = sSearchUserQuery:format( SQLCon:escape(sNick) )
		local SQLCur = tFunction.Execute(sSearchUserQuery)
		if SQLCur:numrows() == 0 then
			SQLCur:close()
			return false
		end
		local tRow, sMessage, sEditMessage = SQLCur:fetch( {}, "a" ), "An offline message with ID #%04d was sent to you by %s on %s. The message is: \n\t%s\n\n\tThank you for using offline message services.", "UPDATE messages SET delivered = 'Y' WHERE id = %d"
		while tRow do
			local SQLTemp = tFunction.Execute( sEditMessage:format(tRow.id) )
			Core.SendPmToNick( sNick, tConfig.sBotName, sMessage:format(tRow.id, tRow.from, tRow.dated, tRow.message) )
			tRow = SQLCur:fetch( {}, "a" )
			SQLTemp:close()
		end
		tRow = nil
		SQLCur:close()
	end
}

function OnExit()
	Core.UnregBot( tConfig.sBotName )
	SQLCon:close()
	SQLEnv:close()
end
