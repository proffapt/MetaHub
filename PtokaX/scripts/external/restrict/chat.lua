--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function RestrictChat( sBotName, Error )
	local sError = ( "<%s> %s" ):format( sBotName, Error("gen", 2) )
	return function( tUser, sMessage, bFlag )
		if not bFlag then return bFlag end
		if tUser.iProfile == -1 or tUser.iProfile == 6 then
			Core.SendToUser( tUser, sError )
			return true
		end
		return false
	end
end

return RestrictChat
