--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function OnStartup()
	tConfig = {
		sBotName = SetMan.GetString( 21 ),
		sReportBot = "#[VIPChat]",
		sChatFilePath = Core.GetPtokaXPath().."scripts/dependency/chatcore.lua"
	}
	tConfig.sAsBot = "<"..tConfig.sBotName.."> "
	dofile( tConfig.sChatFilePath )
	local fCommand = io.open( Core.GetPtokaXPath().."scripts/texts/reportMenu.txt", "r+" )
	sFileCommand = fCommand:read "*a"
	sFileCommand = sFileCommand:gsub( "%%%[bot%]", tConfig.sBotName )
	Core.SendToAll( sFileCommand )
	fCommand:close()
end

function ToArrival( tUser, sMessage )
	local sTo, sCommand, sData = sMessage:match "^%$To: (%S+) From:.-%b<> [-+/*?!#](%w+)%s?(.*)|"
	if sTo ~= tConfig.sBotName then return false end
	if sCommand and sCommand:lower() == "report" then
		return ExecuteCommand( tUser, sData, true )
	end
	return false
end

function ChatArrival( tUser, sMessage )
	local sCommand, sData = sMessage:match "%b<> [-+/*?!#](%w+)%s?(.*)|"
	if not sCommand then return false end
	if sCommand:lower() == "report" then
		return ExecuteCommand( tUser, sData, false )
	end
	return false
end

function UserConnected( tUser )
	Core.SendToUser( tUser, sFileCommand )
end

RegConnected, OpConnected = UserConnected, UserConnected

function Notify( tUser, sMessage, bIsPM )
	if bIsPM then
		Core.SendPmToUser( tUser, tConfig.sBotName, sMessage )
	else
		Core.SendToUser( tUser, tConfig.sAsBot..sMessage )
	end
end

function ExecuteCommand( tUser, sData, bIsPM )
	if sData:len() < 20 then
		local sReply = "The report text should be more than 20 characters in length."
		Notify( tUser, sReply, bIsPM )
		return true
	end
	local sReport, sReply = "(Report): "..sData, "Your message [ %s ] has been reported to %s."
	SendToRoom( tUser.sNick, sReport, tConfig.sReportBot )
	Notify( tUser, sReply:format(sData, tConfig.sReportBot), bIsPM )
	return true
end
