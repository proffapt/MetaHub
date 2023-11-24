--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

local tFiles, tSettings = {
	lostnfound = "lost.txt",
	notices = "notice.txt",
	trainplace = "tnp.txt",
}, {
	sBotName = SetMan.GetString( 21 ) or "PtokaX",
	sTextPath = tPaths.sTextPath,
}

function CreateMessage( tInput )
	if not tInput or not tInput.sTitle then
		return false, "Creation error"
	end
	local sReply, sTemplate, tTemp = "\n\n"..tInput.sTitle:upper().."\n"..("="):rep(24).."\n\n", "ID: %d \t\t\t Date added: \t %s \nMessage: %s", {}
	for iIndex, tBody in pairs( tInput.tMain ) do
		table.insert( tTemp, sTemplate:format(iIndex, tBody.sDate, tBody.sBody) )
	end
	return ( sReply..table.concat(tTemp, "\n\t\t"..("-"):rep(100).."\n\n").."\n" )
end

function RemoveMessage( sName, iMessageID )
	if not tFiles[sName] then
		return false, "Removal error"
	end
	local fHandle = io.open( tSettings.sTextPath..tFiles[sName], "r+" )
	if fHandle then
		local sReply = "Message removed from [ %s ] at ID #%02d"
		dofile( tSettings.sTextPath..tFiles[sName] )
		fHandle:close()
		table.remove( tTemp.tMain, iMessageID )
		pickle.store( tSettings.sTextPath..tFiles[sName], { tTemp = tTemp } )
		tTemp = nil
		return sReply:format( sName, iMessageID )
	end
	return false, "Removal error"
end

function SendFile( sName )
	if not tFiles[sName] then
		return false, "Sending error"
	end
	local fHandle = io.open( tSettings.sTextPath..tFiles[sName], "r+" )
	if fHandle then
		dofile( tSettings.sTextPath..tFiles[sName] )
		fHandle:close()
		return CreateMessage( tTemp )
	else
		return false, "File not found"
	end
end

function StoreMessage( sName, sMessage )
	if not tFiles[sName] then
		return false, "Storage error"
	end
	local fHandle = io.open( tSettings.sTextPath..tFiles[sName], "r+" )
	if fHandle then
		dofile(tSettings.sTextPath..tFiles[sName])
		fHandle:close()
		table.insert( tTemp.tMain, {sDate = os.date("%Y-%m-%d"), sBody = sMessage } )
		pickle.store( tSettings.sTextPath..tFiles[sName], { tTemp = tTemp } )
		sReply = ( "Message stored at ID #%02d of [ %s ]"):format( #(tTemp.tMain), sName )
		tTemp = nil
		return sReply
	end
	return false, "Storage error"
end

function InformAll()
	for sName, sFile in pairs( tFiles ) do
		local fHandle = io.open( tSettings.sTextPath..sFile, "r+" )
		if fHandle then
			dofile( tSettings.sTextPath..tFiles[sName] )
			fHandle:close()
			Core.SendPmToAll( tSettings.sBotName, CreateMessage(tTemp) )
			tTemp = nil
		end
	end
end
