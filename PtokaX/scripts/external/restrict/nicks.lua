--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function RestrictUser( sBotName, Error )
	local Error, sAsBot, sBotName, iBanTime = Error, "<"..sBotName.."> ", sBotName, 6
	return function( tUser )
		if tUser.sNick:find "^[^%w_%.]" then
			Core.SendToUser( tUser, sAsBot..Error("gen", 50) )
			BanMan.TempBan( tUser, iBanTime, Error("gen", 50), sBotName, true )
			Core.Disconnect( tUser )
		end
		if tUser.sNick:find "\160" then
			Core.SendToUser( tUser, sAsBot.."Certain characters are not allowed in nicks." )
			Core.Disconnect( tUser )
		end
	end
end

return RestrictUser
