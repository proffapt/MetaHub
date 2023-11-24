--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function VerifyBots( sInput )
	if sInput:find "^%[BOT%]" then
		return true
	elseif sInput:find "^#%[" then
		return true
	elseif sInput:find "OpChat" then
		return true
	elseif sInput == SetMan.GetString( 21 ) then
		return true
	else
		return false
	end
end

function UpdateStats()
	for sDate, tTemporary in pairs( tUserStats ) do
		for sNick, tTemp in pairs( tTemporary ) do
			UpdateUserScore( sNick, sDate, tTemp.main, tTemp.msg )
		end
	end
	for sDate, tTemporary in pairs( tBotStats ) do
		for sName, tTemp in pairs( tTemporary ) do
			UpdateBotStats( sName, sDate, tTemp.regs, tTemp.unregs )
		end
	end
	tUserStats, tBotStats = {}, {}
end

local tFormat = {
	sHeader = ( "\t%05s\t%-32s\t%-7s\n\t" ):format( "S.No.", "UserName", "Score" ),
	sTemplate = "%3d.\t%-25s\t%-7d",
}

local function List( sqlCur )
	local tRow, tTemp, iCounter = {},{}, 1
	tRow = sqlCur:fetch( tRow, "a" )
	while tRow do
		table.insert( tTemp, tFormat.sTemplate:format(iCounter, tRow.nick, tRow.total) )
		tRow, iCounter = sqlCur:fetch( tRow, "a" ), iCounter + 1
	end
	sqlCur = nil
	return tTemp
end

function IncreaseBotCount( sBot, bIsRegUser )
	local sDate = os.date( "%Y-%m-%d" )
	if type( tBotStats[sDate] ) ~= "table" then
		tBotStats[sDate] = {}
	end
	if not tBotStats[sDate][sBot] then tBotStats[sDate][sBot] = { regs = 0, unregs = 0 } end
	if bIsRegUser then
		tBotStats[sDate][sBot].regs = (tBotStats[sDate][sBot].regs or 0) + 1
	else
		tBotStats[sDate][sBot].unregs = (tBotStats[sDate][sBot].unregs or 0) + 1
	end
end

function IncreasePMCount( tUser )
	local sDate = os.date( "%Y-%m-%d" )
	if type( tUserStats[sDate] ) ~= "table" then
		tUserStats[sDate] = {}
	end
	if not tUserStats[sDate][tUser.sNick] then tUserStats[sDate][tUser.sNick] = { msg = 0, main = 0 } end
	tUserStats[sDate][tUser.sNick].msg = ( tUserStats[sDate][tUser.sNick].msg or 0 ) + 1
end

function IncreaseChatCount( tUser )
	local sDate = os.date( "%Y-%m-%d" )
	if type( tUserStats[sDate] ) ~= "table" then
		tUserStats[sDate] = {}
	end
	if not tUserStats[sDate][tUser.sNick] then tUserStats[sDate][tUser.sNick] = { main = 0, msg = 0 } end
	tUserStats[sDate][tUser.sNick].main = ( tUserStats[sDate][tUser.sNick].main or 0 ) + 1
end

function UpdateUserScore( sNick, sDate, iMain, iPM )
	local sQuery = [[INSERT INTO scores (nick, `count`, messages, dated)
	VALUES ('%s', %d, %d, '%s')
	ON DUPLICATE KEY
		UPDATE `count` = `count` + %d,
			messages = messages + %d]]
	sQuery = sQuery:format( sqlCon:escape(sNick), iMain, iPM, sDate, iMain, iPM )
	local sqlCur = assert( sqlCon:execute(sQuery) )
	sqlCur = nil
end

function UpdateBotStats( sBotName, sDate, iRegs, iUnregs )
	local sQuery = [[INSERT INTO botStats (name, regs, unregs, dated)
	VALUES ('%s', %d, %d, '%s')
	ON DUPLICATE KEY
		UPDATE regs = regs + %d,
			unregs = unregs + %d]]
	sQuery = sQuery:format( sqlCon:escape(sBotName), iRegs, iUnregs, sDate, iRegs, iUnregs )
	local sqlCur = assert( sqlCon:execute(sQuery) )
	sqlCur = nil
end

function AllTimeTop( iLimit )
	local sQuery= [[SELECT nick,
		SUM(`count`) AS `total`
	FROM scores
	GROUP BY nick
	ORDER BY `total` DESC
	LIMIT %d]]
	local tTemp, iCounter ={}, 1
	local sqlCur, sResult = assert( sqlCon:execute(sQuery:format(iLimit)) ), ( "\n\n\t\tShowing %d of all time top chatterers\n\n" ):format( iLimit )
	tTemp = List( sqlCur )
	return sResult..tFormat.sHeader..table.concat( tTemp, "\n\t" )
end

function DailyTop( iLimit, sDate )
	local sResult, tTemp = "\n\n\t\tShowing %d of %s\n\n", {}
	sResult = sResult:format( iLimit, sDate or "today" )
	local sQuery= [[SELECT nick,
		`count` AS `total`
	FROM scores
	WHERE dated = %s
	ORDER BY `total` DESC
	LIMIT %d]]
	local sDate = ( sDate and "'"..sDate.."'" ) or "CURDATE()"
	local sqlCur = assert( sqlCon:execute(sQuery:format(sDate, iLimit)) )
	tTemp = List( sqlCur )
	return sResult..tFormat.sHeader..table.concat( tTemp, "\n\t" )
end

function NickStats( sNick )
	local tRow, sQuery, sResult = {}, [[SELECT s.nick AS nick,
		s.`count` AS recent,
		t.`total` AS `total`,
		t.avrg AS avrg,
		t.pm AS pm,
		t.max AS highest,
		ss.dated AS dated,
		t.dated AS rcntdate
	FROM (
		SELECT nick,
			SUM(`count`) AS `total`,
			AVG(`count`) AS avrg,
			SUM(messages) AS pm,
			MAX(`count`) AS max,
			MAX(dated) AS dated
		FROM scores
		WHERE nick = '%s'
	) AS t
	INNER JOIN scores s
		ON s.nick = t.nick
			AND s.dated = t.dated
	INNER JOIN scores ss
		ON ss.nick = t.nick
			AND t.max = ss.count
	LIMIT 1]], [[

	HiT Hi FiT Hai: Mainchat stats for %s
	-------------------------------------

	User: %s
	Total count: %d
	Average count: %d
	PMs sent: %d
	Most recent score of %d on %s
	Highest activity on %s (with score of %d)
	-------------------------------------]].."\n\n"
	local sqlCur = assert( sqlCon:execute(sQuery:format( sqlCon:escape(sNick) )) )
	tRow = sqlCur:fetch( tRow, "a" )
	if not tRow then
		return  "No record was obtained. This user might never have used mainchat/sent a PM."
	else
		return sResult:format( tRow.nick, tRow.nick, tRow.total, tRow.avrg, tRow.pm, tRow.recent, tRow.rcntdate, tRow.dated, tRow.highest )
	end
end
