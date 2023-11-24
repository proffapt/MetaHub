--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function RestrictSearch( sBotName, Error )
	local tBannedTTH, tBannedWords, sAllowedProfiles = {
			"RYLUZGTHGGUS6CE465VUTHT7TKWFJFZ55M6KPKY",
		}, {
			"pondy",
			"porn",
			"xxx",
			"rape",
			"sanhita",
		}, "0123"
	local function IsBanned( sData )
		for iIndex, sWord in ipairs( tBannedWords ) do
			if sData:find( "%?"..sWord ) then
				return iIndex
			end
		end
		for iIndex, sHash in ipairs( tBannedTTH ) do
			if sData:find( "TTH:"..sHash ) then
				return iIndex
			end
		end
		return false
	end
	return function( tUser, sQuery )
		if sAllowedProfiles:find( tUser.iProfile ) then
			return false
		end
		if IsBanned( sQuery ) then
			return true
		end
		return false
	end
end

return RestrictSearch
