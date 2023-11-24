--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function RestrictSearch( sBotName, Error )
	local sAllowedProfiles, iBanTime, iShareLimit, iDivisionFactor = "01236", 6, 90, ( 2^10 )^3
	local sError = ( "<%s> Minimum sharesize required to search and download is %d GiB." ):format( sBotName, iShareLimit )
	return function( tUser, sQuery, bFlag )
		if not bFlag then return bFlag end
		tUser.iShareSize = Core.GetUserValue( tUser, 16 ) / iDivisionFactor
		if tUser.iShareSize < iShareLimit and not sAllowedProfiles:find( tUser.iProfile ) then
			Core.SendToUser( tUser, sError )
			return true
		end
		return false
	end
end

return RestrictSearch
