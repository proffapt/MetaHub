--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]


function UpdateUserToks( tUser )
        local sNick = sqlCon:escape(tUser.sNick)
	local sQuery = [[INSERT INTO `toks`(`username`, `toks`,`maxtoks`,`maxtoksdate`)
		VALUES( '%s','%.3f','%.3f',CURDATE() )
		ON DUPLICATE KEY
		UPDATE toks = toks + %f
		]]
	local iSharesize = Core.GetUserValue(tUser,16)/(1024*1024*1024) 	-- Sharesize in GiB
	if iSharesize < tToksConfig.iMinShareLimit then
		return
	end
	iLogSharesize = math.log(iSharesize)
	local SQLCur = assert( sqlCon:execute(string.format(sQuery, sNick,iLogSharesize,iLogSharesize,iLogSharesize)) )
end

function UpdateToks()
	local tRegUsers = Core.GetOnlineRegs(true)
	for iIndex,tUser in ipairs(tRegUsers) do
		if (tUser.sMode == "A") then					-- Only update for those users who are in active mode
			UpdateUserToks(tUser)
		end
	end
end

function Inflation()
	local sQuery = [[UPDATE `toks`
		SET `toks` = %f*`toks`]]
	local SQLCur = assert( sqlCon:execute(sQuery:format(tToksConfig.fInflationConstant)) )
end

function GrantAllowance()
	local sQuery1=[[UPDATE `toks` SET `allowance` = CASE WHEN %f*toks < 100 then 100 else %f*toks end ]]
	assert( sqlCon:execute(string.format(sQuery1,tToksConfig.fRegUserAllowanceFactor,tToksConfig.fRegUserAllowanceFactor)) )
	local sQuery2= [[UPDATE `toks` SET `allowance` = `allowance` + %.3f WHERE username = '%s']]
	local tModerators=RegMan.GetRegsByProfile(4)
	for i,tMod in ipairs(tModerators) do
		assert( sqlCon:execute(sQuery2:format(tToksConfig.fModAllowance,tMod.sNick)) )
	end
	local tVips = RegMan.GetRegsByProfile(3)
	for i,tVip in ipairs(tVips) do
		assert( sqlCon:execute(sQuery2:format(tToksConfig.fVipAllowance,tVip.sNick)) )
	end
	local tOperators = RegMan.GetOps()
	for i,tOp in ipairs(tOperators) do
		assert( sqlCon:execute(sQuery2:format(tToksConfig.fOpAllowance,tOp.sNick)) )
	end
end

local function GetAttribute (sNick ,sAttribute)
	local sQuery =  "SELECT `%s` FROM toks WHERE username='%s'"
	sNick = sqlCon:escape( sNick)
	tSQLResults = assert( sqlCon:execute(sQuery:format(sAttribute,sNick)) )
	tRow = tSQLResults:fetch( {}, "a" )
	if tRow and tRow[sAttribute] then
		return tRow[sAttribute]
	else
		return nil
	end
end

function gift(sDonorNick,sDoneeNick,fAmount,sMessage)
	sDonorNick=sqlCon:escape(sDonorNick)
	sDoneeNick=sqlCon:escape(sDoneeNick)
	fAmount=math.abs(fAmount)
	if sDonorNick == sDoneeNick then
		return "You cant gift toks to yourself !!"
	end
	local fAllowance = tonumber(GetAttribute(sDonorNick,"allowance"))
	local sDonorReply,sDoneeReply = "",""
	if fAmount > fAllowance then
		fAmount = fAllowance
		sDonorReply="\nYou didn't have enough allowance to transfer the requested sum.Whatever was left was transferred"
	end
	local sQuery1 =  "UPDATE `toks` SET allowance = allowance - %f, toks = toks + %f WHERE username = '%s'"
	assert( sqlCon:execute(sQuery1:format(fAmount, fAmount, sDonorNick)) )
	local sQuery2 = "INSERT INTO `transactions`(`from`,`to`,`amount`,`date`) VALUES ('%s','%s',%.3f,CURRENT_TIMESTAMP)"
	assert( sqlCon:execute(sQuery2:format(sDonorNick,sDoneeNick,fAmount)) )

	sDonorReply=sDonorReply..string.format("\n %.2f toks were gifted to %s. You have %.2f allowance left",fAmount,sDoneeNick,fAllowance-fAmount)
	if string.len(sMessage)~= 0 then
		sDoneeReply=string.format("You received %.2f toks from %s accompanied with this message - %s .",fAmount,sDonorNick,sMessage)
	else
		sDoneeReply=string.format("You received %.2f toks from %s .",fAmount,sDonorNick)
	end
	Core.SendPmToNick(sDoneeNick,tConfig.tBot.sName,sDoneeReply)
	return sDonorReply
end

 function CurrentTopToks( iLimit )
	local sList = "\n\r\t\tRichest Users on HiT Hi FiT Hai \n"
	sList = sList..string.format( "\t%03s\t%-32s\t%-7s\n\t", "S. No.", "UserName", "Toks" )
	local sQuery = [[SELECT username, toks FROM toks ORDER BY toks DESC LIMIT %d]]
	tSQLResults = assert( sqlCon:execute(sQuery:format( iLimit )) )
	tRow = tSQLResults:fetch ({}, "a")
	i = 1
	while tRow do
		sTemp = string.format( "%-3s\t%-25s\t%-7d", tostring(i), tRow.username, tRow.toks )
		sList = sList..sTemp.."\n\t"
		tRow = tSQLResults:fetch ({}, "a")
		i = i + 1
	end
	return sList
end

function AllTimeTopToks( iLimit )
	local sList = "\n\r\t\tRichest Users of all time on HiT Hi FiT Hai \n"
	sList = sList..string.format( "\t%10s\t%-30s\t%-10s\t%-25s\n\t", "S. No.", "UserName", "MaxToks" ,"Date")
	local sQuery = [[SELECT username, maxtoks,maxtoksdate FROM toks ORDER BY maxtoks DESC LIMIT %d]]
	tSQLResults = assert( sqlCon:execute( string.format( sQuery, iLimit ) ) )
	tRow = tSQLResults:fetch ({}, "a")
	i = 1
	while tRow do
		sTemp = string.format( "%-10s\t%-30s\t%-10d\t%-25s", tostring(i), tRow.username, tRow.maxtoks,tRow.maxtoksdate )
		sList = sList..sTemp.."\n\t"
		tRow = tSQLResults:fetch ({}, "a")
		i = i + 1
	end
	return sList
end

function Transactions( tUser, sNick )
	local sQuery ="SELECT * FROM transactions WHERE `From`='%s' or`To`='%s' "
	sNick=sqlCon:escape(sNick)
	if tUser.sNick == sNick or tUser.iProfile == 0  then
		tSQLResults = assert( sqlCon:execute( string.format( sQuery, sNick,sNick ) ) )
		sList = "Showing transactions for "..sNick
		sList= sList..string.format( "\n\t%-5s\t%-25s\t%-25s\t%-10s\t%-15s\n\t", "ID","From","To","Amount","Date")
		tRow = tSQLResults:fetch ({}, "a")
		while tRow do
			sTemp = string.format( "%-5s\t%-25s\t%-25s\t%-10s\t%-15s", tRow.ID, tRow.From, tRow.To,tRow.Amount,tRow.Date )
			sList = sList..sTemp.."\n\t"
			tRow = tSQLResults:fetch ({}, "a")
		end
		return sList
	else
		return ("You cant check transactions of other users")
	end
end

function NickToks( tUser, sNick )
	local sQuery = "SELECT * FROM toks WHERE username='%s'"
	sNick = sqlCon:escape(sNick)
	tSQLResults = assert( sqlCon:execute( string.format( sQuery, sNick ) ) )
	tRow = tSQLResults:fetch ({}, "a")
	if tRow then
		if tUser.sNick == sNick then
			return ("\nYou have "..tRow.toks.." toks.\nMaxtoks ="..tRow.maxtoks.."  on "..tRow.maxtoksdate.."\nAllowance left = "..tRow.allowance)
		else
			if tUser.iProfile == 0 then
				return ("\n"..sNick.." has "..tRow.toks.." toks.\nMaxtoks ="..tRow.maxtoks.."  on "..tRow.maxtoksdate.."\nAllowance left = "..tRow.allowance)
			else
				return ("\n"..sNick.." has "..tRow.toks.." toks.\nMaxtoks ="..tRow.maxtoks.."  on "..tRow.maxtoksdate)
			end
		end
	else
		return ("Toks record for "..sNick.." not found.Wait for some time.")
	end
end
