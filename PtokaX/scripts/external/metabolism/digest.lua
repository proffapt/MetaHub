--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

dofile(mpath.."custcom.lua")
dofile(mpath.."modifiers.lua")
dofile(mpath.."expel.lua")
dofile(path.."dependency/pickle.lua" )

digest = function( user, data, isCmd, irc )
	if isCmd then
		msg = custcom(user,data)
	else
		msg = modifiers(user,data)
	end
	if msg then
		dcmcout(msg)
		if irc then
			ircout(msg)
		end
	end
end
