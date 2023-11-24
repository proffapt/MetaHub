--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

unsubbed={}
subbed={}
dofile( path.."texts/mcunsubs.txt" )
tabUsers = Core.GetOnlineUsers()

for k,v in ipairs(tabUsers) do
	if not isthere_key(v.sNick,unsubbed) then
		table.insert(subbed,v.sNick)
	end
end

ircout = function (data)
	data = data:gsub( "|", "" )			--	Removing the terminating '|' character only.
	data = data:gsub( "&#124;", "|" )
	data = data:gsub( "&#036;", "$" )
	local file= io.open( path.."texts/DCout.txt","a+")
	file:write(data.."\n")
	file:flush()
	file:close()
end

dcmcout = function(data)
	local sForward = Trim( data )
	for k, v in ipairs(subbed) do
		Core.SendToNick( v, sForward )
	end
end

UserConnected = function (tUser)
	if not isthere_key(tUser.sNick, unsubbed) then
		if not isthere_key(tUser.sNick, subbed) then
			table.insert(subbed,tUser.sNick)
		end
	end
end

UserDisconnected = function (tUser)
	key = isthere_key(tUser.sNick,subbed)
	while key do
		table.remove( subbed, key)
		key = isthere_key(tUser.sNick,subbed)
	end
end

RegConnected, OpConnected = UserConnected, UserConnected
RegDisconnected, OpDisconnected = UserDisconnected, UserDisconnected
