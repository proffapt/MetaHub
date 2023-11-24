--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function RestrictUser( sBotName, Error )
	local sAllowedProfiles, sBotName, iBanTime = "012", sBotName, 60
	local sError = ( "<%s> Connection in passive mode is not allowed: %s" ):format( sBotName, Error("gen", 3) )
	return function( tUser )
		if sAllowedProfiles:find( tUser.iProfile ) then return end
		local sMode = Core.GetUserValue( tUser, 0 ) or "P"
		if sMode:lower() == "p" then
			Core.SendToUser( tUser, sError )
			BanMan.TempBan( tUser, iBanTime, sError, sBotName, true )
			Core.Disconnect( tUser )
			return true
		end
		return false
	end
end

return RestrictUser
