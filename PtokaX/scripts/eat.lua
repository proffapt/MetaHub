--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

path = Core.GetPtokaXPath().."scripts/"
bot = SetMan.GetString(21)
mpath, dpath = path.."external/metabolism/", path.."dependency/"
dofile(mpath.."digest.lua")
nickc = {}
falone = {}
muted = {}
blocked = {}
lunarised = {}
dofile( path.."texts/blocks.txt" )
desu, san, chan, inPM = false, false, false, false
local temp = {					 -- built in commands ,bypass these commands if typed in mainchat
"ban", "banip", "fullban", "fullbanip", "nickban", "tempban", "tempbanip", "fulltempban", "fulltempbanip", "nicktempban", "unban",
"permunban", "tempunban", "getbans", "getpermbans", "gettempbans", "clrpermbans", "clrtempbans", "rangeban", "fullrangeban",
"rangetempban", "fullrangetempban", "rangeunban", "rangepermunban", "rangetempunban", "getrangebans", "getrangepermbans",
"getrangetempbans", "clrrangepermbans", "clrrangetempbans", "checknickban", "checkipban", "checkrangeban", "getinfo", "op",
"gag", "ungag", "restart", "startscript", "stopscript", "restartscript", "restartscripts", "getscripts", "reloadtxt", "addreguser", "delreguser",
"topic", "massmsg", "opmassmsg", "myip", "help"
}

PtokaxCommands = {}
for k,v in ipairs(temp) do
	PtokaxCommands[v] = true
end
tmr = TmrMan.AddTimer(400, "fileread")

fileread = function()
	local file = io.open(path.."texts/IRCout.txt","r")
	if not file then return end
	local msg = file:read("*a")
	file:close();
	if msg ~= "" then
		local user = {
			sNick = "IRC",
			sIP = "127.0.0.1",
			iProfile = 6
			}
		local file = io.open( path.."texts/IRCout.txt","w+")
		file:close()
		digest(user,msg,true)
	end
end

ChatArrival = function(user,data)
	local tempdata = data:gsub( "|", " " )			--remove terminating |
	local cmd = tempdata:match( "%b<> [-+*/!#?](%S+)%s")
	local isCmd, irc = false, false
	if not cmd then
		isCmd = false
		digest(user,tempdata,isCmd,irc)
		return true
	end
	if isthere(cmd, PtokaxCommands) then		-- let ptokax handle inbuilt commands
		if cmd == "help" then				-- hack to have custhelp executed each time help is executed
			tempdata = tempdata:gsub("help","custhelp")
			inPM = false
			isCmd = true
			digest(user,tempdata,isCmd,irc)
		end
		return
	end
	if isthere(cmd, CustomCommands) then
		isCmd = true
		inPM = false
		digest(user,tempdata,isCmd,irc)
		return true
	end
	--message begins with a command character but the command is not found . Treat it as a normal message
	isCmd = false
	digest(user,tempdata,isCmd,irc)
	return true
end

ToArrival = function( user, data )
	local tempdata = data:gsub( "|", " " )			-- remove terminating |
	local to, from = tempdata:match "$To: (%S+) From: (%S+)"
	if  to ~= bot then
		return
	end
	--Remove the To and From parts 
	tempdata=tempdata:match("$.*$(.*)")
	
	local cmd= tempdata:match( "%b<> [-+*/!#?](%S+)%s")
	if  not cmd then
		return
	end
	if isthere(cmd,CustomCommands) then
		local isCmd, irc = true, false
		inPM = true
		digest(user,tempdata,isCmd,irc)
		return true
	end
	if cmd == "help" then
		local irc = false
		tempdata = tempdata:gsub("help", "custhelp")
		isCmd = true
		inPM = true
		digest(user,tempdata,isCmd,irc)
	end
	return
end

ConnectToMeArrival = function(user,data)
	local uploader = data:match("$ConnectToMe%s(%S+)")
	local nickpair = uploader.."$"..user.sNick
	if blocked[nickpair] then
		local msg = uploader.." has blocked you from downloading from them for the reason: "..blocked[nickpair]
		Core.SendPmToNick(user.sNick, bot, msg)
		return true
	end
end
