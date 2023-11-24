--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

modifiers = function( user, data )
	if isthere( user.sNick, muted ) then
		if user.sNick ~= "IRC" then
			Core.SendToUser( user, "<PtokaX> You are muted.|" )
		end
		return false
	end
	 if isthere_key( user.sNick, unsubbed ) then
		Core.SendToUser( user, "<PtokaX> You have unsubscribed from mainchat. To subscribe again enter !sub|" )
		return false
	end
	local msg, nick = data:match "%b<>(.*)", user.sNick
	if isthere( user.sNick, nickc ) then
		nick = nickc[user.sNick]
	end
	if isthere( user.sNick:lower(), lunarised ) then
		msg = GarbleMessage( msg ):gsub( '[$]', '&#36;' ):gsub( '|', '&#124;' )
	end
	if desu then
		msg = msg.." desu"
	end
	--allow only 1 at a time
	if san then
		nick = nick.."-san"
	end
	if chan then
		nick = nick.."-chan"
	end
	local finalmsg = "<"..nick..">"..msg
	if isthere( user.sNick, falone ) then
		Core.SendToUser( user, finalmsg )
		return false
	end
	return finalmsg
end

GarbleMessage = (function()
	local tGarble = {
		a = "4",
		e = "3",
		l = "1",
		o = "0",
		s = "5",
		t = "7",
		v = "\\/",
		w = "\\/\\/",
		x = "><",
		y = "j",
		z = "2",
		A = "/-\\",
		B = "|3",
		C = "\(",
		D = "|\)",
		E = "3",
		F = "|=",
		G = "6",
		H = "|-|",
		I = "|",
		J = "_|",
		K = "|<",
		L = "|_",
		M = "|\\/|",
		N = "|\\|",
		O = "0",
		P = "|>",
		Q = "(,)",
		R = "|2",
		S = "5",
		T = "7`",
		U = "|_|",
		V = "\\/",
		W = "\\/\\/",
		X = "}{",
		Y = "`/",
		Z = "2",
	}	-- if & is present in tGarble, use gsub( '&', '&amp;' ) for GarbleMessage
	return function( sLine )
		return sLine:gsub( '.', tGarble )
	end
end)()
