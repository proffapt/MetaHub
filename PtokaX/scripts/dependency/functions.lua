--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function Explode( sInput )
	local tReturn = {}
	for sWord in sInput:gmatch( "(%S+)" ) do
		table.insert( tReturn, sWord )
	end
	return tReturn
end

function Trim( sInput )
	return sInput:gsub( "^%s*(.-)%s*$", "%1" )
end
