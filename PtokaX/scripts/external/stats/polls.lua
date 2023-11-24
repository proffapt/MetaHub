--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

AddPoll = ( function()
	local tErrors, tQuery = {
		sNoTitle = "A poll should have a valid title.",
		sFewChoices = "A poll should have at least 2 valid options. At most 10 choices are allowed.",
	}, {
		sQuestion = [[INSERT INTO questions (question, nick, dated) VALUES ( TRIM('%s'), '%s', NOW() )]],
		sChoice = [[INSERT INTO options (option_id, poll_id, `option`) VALUES ( %d, %d, TRIM('%s') )]],
	}
	local function Insert( tInput, sInput, iBegin, iEnd )
		if not iEnd then iEnd = #sInput end
		if iBegin >= iEnd then return end
		local sChoice = sqlCon:escape( sInput:sub(iBegin, iEnd) )
		table.insert( tInput, sChoice )
	end
	local function FindChoices( sInput )
		local tChoices = {}
		local iStart, iEnd, iTemp = sInput:find "%[%]"
		while iEnd do
			iStart, iTemp = sInput:find( "%[%]", iEnd )
			if not iStart then break end
			Insert( tChoices, sInput, iEnd + 1, iStart - 1 )
			iEnd = iTemp
		end
		Insert( tChoices, sInput, iEnd + 1 )
		return tChoices
	end
	local function ParseTitle( sInput )
		local iStart, iEnd = sInput:find "%[%]"
		if not iStart or iStart == 1 then return end
		return sInput:sub( 1, iStart - 1 ), FindChoices( sInput:sub(iStart) )
	end
	return function ( sNick, sData )
		local sNick = sqlCon:escape( sNick )
		local sTitle, tChoices = ParseTitle( sData )
		if not sTitle then
			return tErrors.sNoTitle
		end
		if #tChoices < 2 or #tChoices > 10 then
			return tErrors.sFewChoices
		end
		local sQuery = tQuery.sQuestion:format( sqlCon:escape(sTitle), sNick )
		local sqlCur = assert( sqlCon:execute(sQuery) )
		local iID = sqlCon:getlastautoid() or -1
		if iID == -1 then
			return "Some error occurred."
		end
		for iIndex, sChoice in ipairs( tChoices ) do
			local sQuery = tQuery.sChoice:format( iIndex, iID, sChoice )
			assert( sqlCon:execute(sQuery) )
		end
		return "New poll created with poll ID #"..iID
	end
end )()

DeletePoll = ( function()
	local sQuery = [[UPDATE questions SET deleted = 1 WHERE poll_id = %d AND nick = '%s']]
	local sNotNumber = "The provided argument was not a number."
	return function ( sNick, sData )
		local sNick, iID = sqlCon:escape( sNick ), tonumber( sData )
		if not iID then
			return sNotNumber
		end
		assert( sqlCon:execute(sQuery:format( iID, sNick )) )
		return "Poll with ID #"..iID.." has been deleted."
	end
end )()

Vote = ( function()
	local sQuery = [[INSERT INTO votes (poll_id, option_id, nick, dated)
		SELECT
			o.poll_id,
			o.option_id,
			'%s',
			NOW()
		FROM options o
		WHERE o.poll_id = %d
			AND o.option_id = %d]]
	return function ( sNick, iPollID, iChoiceID )
		local sNick = sqlCon:escape( sNick )
		local iPollID, iChoiceID = tonumber( iPollID ), tonumber( iChoiceID )
		if not ( iPollID and iChoiceID ) then
			return "The provided argument was not a number."
		end
		assert( sqlCon:execute(sQuery:format( sNick, iPollID, iChoiceID )) )
		return "Your vote has been cast. Thank you!"
	end
end )()

List = ( function()
	local sQuery = [[SELECT
			q.poll_id AS poll_id,
			q.question AS question,
			q.nick AS nick,
			q.dated AS dated,
			COUNT(v.poll_id) AS total
		FROM questions q
		LEFT JOIN votes v
			USING (poll_id)
		WHERE deleted = 0
		GROUP BY q.poll_id
		ORDER BY q.poll_id DESC
		LIMIT %d]]
	local function Format( tInput )
		return ( "%03d. [%03d] %s (Created by %s on %s)" ):format( tInput.poll_id, tInput.total, tInput.question, tInput.nick, tInput.dated )
	end
	return function ( iLimit )
		local iLimit = tonumber( iLimit ) or 15
		if iLimit > 35 then iLimit = 35 end
		if iLimit < 5 then iLimit = 5 end
		local sqlCur = assert( sqlCon:execute(sQuery:format( iLimit )) )
		local tResult, tRow = {}, sqlCur:fetch( {}, 'a' )
		while tRow do
			table.insert( tResult, 1, Format(tRow) )
			tRow = sqlCur:fetch( tRow, 'a' )
		end
		return ( "List with recent %02d polls follows:\n\n%s\n" ):format( iLimit, table.concat(tResult, "\n") )
	end
end )()

View = ( function()
	local tQuery = {
		sList = [[SELECT
			o.option_id AS option_id,
			o.`option` AS `option`,
			COUNT(v.nick) AS total
		FROM options o
		LEFT JOIN votes v
			ON o.poll_id = v.poll_id
			AND v.option_id = o.option_id
		WHERE o.poll_id = %d
		GROUP BY o.option_id
		ORDER BY total DESC, o.option_id ASC]],
		sQuestion = [[SELECT question, nick, dated FROM questions WHERE poll_id = %d AND deleted = 0]],
	}
	local function CopyTable( tInput )
		local tReturn = {}
		for Key, Value in pairs( tInput ) do
			tReturn[ Key ] = Value
		end
		return tReturn
	end
	local function Format( tInput )
		return ( "%02d. [ %-30s ] (%02d) %s" ):format( tInput.option_id, ('='):rep(tInput.total)..'>', tInput.total, tInput.option )
	end
	return function ( iPollID )
		local iPollID = tonumber( iPollID )
		if not iPollID then
			return "The provided argument was not a number."
		end
		local sList, sQuestion = tQuery.sList:format( iPollID ), tQuery.sQuestion:format( iPollID )
		local sqlCur = assert( sqlCon:execute(sQuestion) )
		local tList, tRow = {}, sqlCur:fetch( {}, 'a' )
		if not tRow then
			return "No poll with the given ID exists."
		end
		local tQuestion = CopyTable( tRow )
		sqlCur = assert( sqlCon:execute(sList) )
		tRow = sqlCur:fetch( {}, 'a' )
		while tRow do
			table.insert( tList, Format(tRow) )
			tRow = sqlCur:fetch( tRow, 'a' )
		end
		return ( "\n\t%03d. %s\n\t\t - by %s (%s)\n\n%s\n" ):format( iPollID, tQuestion.question, tQuestion.nick, tQuestion.dated, table.concat(tList, '\n') )
	end
end )()
