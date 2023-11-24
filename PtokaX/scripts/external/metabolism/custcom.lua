--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

--custom commands

dofile( dpath.."chatcore.lua" )
dofile( dpath.."functions.lua" )
local tokenize = Explode

function chkpriv( tUser, n )
	local profile = tUser.iProfile
	if n == -1 then return true end
	if profile == -1 then return false end
	if profile > n then return false end
	return true
end

function isHigherRanked( tUser, tVictim )
	local userprofile = tUser.iProfile
	local victimprofile = tVictim.iProfile
	if victimprofile == -1 and userprofile ~= -1  then return true end
	if ( userprofile < victimprofile or tUser.sNick == tVictim.sNick ) then return true end
	return false
end

function isthere( sUser, tTable )
	return tTable[sUser:lower()]
end

function isthere_key( key, tTable )
	local q = key:lower()
	for k, v in ipairs( tTable ) do
		if v:lower() == q then
			return k
		end
	end
	return nil
end

function check( user, regprofile, tokens, numofargs, victimid, viconline )
	if not chkpriv( user, regprofile ) then
		notify( user, "You dont have access to this command" )
		return false
	end
	if tokens and numofargs then
		if not tokens[numofargs] then
			notify( user, "Insufficient arguments" )
			return false
		end
	end
	if victimid then -- command has a victim
		local victimnick = tokens[victimid]
		local victim = Core.GetUser( victimnick ) or RegMan.GetReg( victimnick )
		if viconline and not victim then
			notify( user, victimnick.." not online" )
			return false
		end
		if not victim then -- victim is an offline unregistered user , create fake user table with profile for them
			victim = {}
			victim.iProfile = -1
		end
		if not isHigherRanked( user, victim ) then
			notify( user, "You dont have the permission to use this command on "..victim.sNick )
			return false
		end

	end
	return true
end
function notify( user, msg )
	if inPM then
		Core.SendPmToUser( user, bot, msg )
	else
		Core.SendToUser( user, "<"..bot.."> "..msg )
	end
end
--[[

--~ *******************    MAINTAINER'S NOTE    *******************

--~ I think the following method of execution can be improved
--~ drastically. If you have any ideas as to how, feel free to share
--~ them as a new issue on https://github.com/HiT-Hi-FiT-Hai/hhfh-issues/issues

]]--

-- each function in this table should have a line of the type "if not user then return <profile_number>, , syntax, comment end"
--this is for the custhelp function which calls each function in the table without any argument and using the returned values constructs the customised help file
--profile_number is the profile to which this command should be available (According to rules defined in chkpriv function)
CustomCommands = {
	say = function( user, tokens )
		if not user then return 3, "!say <nick>  <message>", "Send a message on mainchat as someone else " end
		if not check( user, 3, tokens, 3 ) then return false end
		local msg = table.concat( tokens, " ", 4 )
		msg = "<"..tokens[3].."> "..msg
		SendToRoom( bot, user.sNick.." send a mainchat message saying "..msg, "#[Hub-Feed]" , 3 )
		return msg
	end,
	drop = function( user, tokens )
		if not user then return 3, "!drop <nick>", "Disconnect (drop) a user  " end
		if not check( user, 3, tokens, 3, 3, true ) then return false end
		Core.Disconnect( tokens[3] )
		SendToRoom( bot, user.sNick.." dropped " ..tokens[3] , "#[Hub-Feed]" , 3 )
		return false
	end,
	warn = function( user, tokens )
		if not user then return 3, "!warn <nick> <reason>", "Send a warning on mainchat as the mainbot " end
		if not check( user, 3, tokens, 3, 3 ) then return false end
		local reason = table.concat( tokens, " ", 4 )
		local warning = ( "<%s> %s has been warned for: %s. If it doesnt calm down it WILL BE kicked from the hub." ):format( bot, tokens[3], reason )
		return warning
	end,
	kick = function( user, tokens )
		if not user then return 3, "!kick <nick> <reason>", "Disconnect the victim and tempban him/her for 10 mins " end
		if not check( user, 3, tokens, 3, 3, true ) then return false end
		local victim = tokens[3]
		local reason = table.concat( tokens, " ", 4 )
		if reason == "" then reason = "No reason provided" end
		BanMan.TempBanNick( victim, 10, reason, user.sNick )
		SendToRoom( user.sNick, "Kicking "..victim.." for: "..reason, "#[Hub-Feed]" , 3 )
		return false
	end,
	mute = function( user, tokens )
		if not user then return 3, "!mute <nick>", "Mute the  victim indefinitely, preventing him/her from posting on mainchat  " end
		if not check( user, 3, tokens, 3, 3 ) then return false end
		victim = tokens[3]
		muted[tokens[3]] = true
		SendToRoom( user.sNick, "Muting "..victim.." .", "#[Hub-Feed]" , 3 )
		return false
	end,
	unmute = function( user, tokens )
		if not user then return 3, "!unmute <nick>", "Unmute the person  " end
		if not check( user, 3, tokens, 3, 3 ) then return false end
		if isthere( tokens[3], muted ) then
			muted[tokens[3]] = nil
			SendToRoom( user.sNick, "Unmuting "..tokens[3], "#[Hub-Feed]" , 3 )
		else
			notify( user, tokens[3].." is not muted.|" )
		end
		return false
	end,
	foreveralone = function( user, tokens )
		if not user then return 1, "!foreveralone <nick>", "Hellban the person i.e only he/she can see their posts on mainchat  " end
		if not check( user, 3, tokens, 3, 3 ) then return false end
		falone[tokens[3]] = true
		SendToRoom( bot, tokens[3].." was aloned by ".. user.sNick, "#[Hub-Feed]" , 3 )
		return false
	end,
	nomorealone = function( user, tokens )
		if not user then return 1, "!nomorealone <nick>", "Remove the hellban  " end
		if not check( user, 3, tokens, 3, 3 ) then return false end
		if isthere( tokens[3], falone ) then
			falone[tokens[3]] = nil
			SendToRoom( bot, tokens[3].." was un-aloned by ".. user.sNick, "#[Hub-Feed]" , 3 )
		else
			notify( user, tokens[3].." has not been aloned.|" )
		end
		return false
	end,
	changenick = function( user, tokens )
		if not user then return 1, "!changenick <original_nick> <new_nick>", "Change the nick of the vicitim on mainchat " end
		if not check( user, 0, tokens, 4, 3 ) then return false end
		nickc[tokens[3]] = tokens[4]
		SendToRoom( bot, user.sNick.." changed nick of "..tokens[3].." to "..tokens[4], "#[Hub-Feed]" , 3 )
		return false
	end,
	revertnick = function( user, tokens )
		if not user then return 1, "!revertnick <original_nick>", "Undo the effect of !changenick  " end
		if not check( user, 0, tokens, 3, 3 ) then return false end
		if isthere( tokens[3], nickc ) then
			nickc[tokens[3]] = nil
			notify( user, tokens[3].."'s nick has been changed back.|" )
			SendToRoom( bot, user.sNick.." changed back "..tokens[3].."'s nick.", "#[Hub-Feed]" , 3 )
		else
			notify( user, tokens[3].."'s nick has not been changed.|" )
		end
		return false
	end,
	-- General Commands
	unsub = function( user, tokens )
		if not user then return -1, "!unsub", "Unsubscribe from mainchat " end
		if not isthere_key( user.sNick, unsubbed ) then
		key = isthere_key( user.sNick, subbed )
		while key do
			table.remove( subbed, key )
			key = isthere_key( user.sNick, subbed )
		end
		table.insert( unsubbed, user.sNick )
		pickle.store( path.."texts/mcunsubs.txt", {unsubbed = unsubbed} )
		notify( user, "You have unsubscribed from mainchat.|" )
		end
		return false
	end,
	sub = function( user, tokens )
		if not user then return -1, "!sub", "Subscribe back to mainchat " end
		if not isthere_key( user.sNick, subbed ) then
		key = isthere_key( user.sNick, unsubbed )
		while key do
			table.remove( unsubbed, key )
			key = isthere_key(user.sNick, unsubbed )
		end
		table.insert( subbed, user.sNick )
		pickle.store( path.."texts/mcunsubs.txt", {unsubbed = unsubbed} )
		notify( user, "You have subscribed back" )
		end
		return false
	end,
      	me = function( user, tokens )
		if not user then return -1, "!me <message>", "Speak in third person. Identical to /me command on IRC" end
		local msg = table.concat( tokens, " ", 3 )
		msg = user.sNick.." "..msg
		return msg
	end,
	--For fun
	desu = function( user )
		if not user then return 0, "!desu", "Toggles desu variable. if desu is true, appends desu to every message on mainchat " end
		if not check( user, 0 ) then return false end
		desu = not desu
		return false
	end,
	san = function( user )
		if not user then return 0, "!san", "Toggles san variable.If san is true, appends -san to every nick on mainchat. Example - Brick -> Brick-san  " end
		if not check(user, 0) then return false end
		san = not san
		return false
	end,
	chan = function( user )
		if not user then return 0, "!chan", "Toggles chan variable. If chan is true, appends -chan to every nick on mainchat. Example - Brick -> Brick-chan " end
		if not check( user, 0 ) then return false end
		chan = not chan
		return false
	end,
	--blocking related
	block = function( user, tokens )
		if not user then return 4, "!block <nick> <reason>", "Prevent the victim from downloading from the users" end
		if not check( user, 4, tokens, 3, 3 ) then return false end
		local victim = tokens[3]
		local nickpair = string.lower( user.sNick.."$"..victim )
		local reason = table.concat( tokens, " ", 4 )
		if reason == "" then reason = "No reason provided" end
		blocked[nickpair] = reason
		pickle.store( path.."texts/blocks.txt", {blocked = blocked} )
		local msg = victim.." has been blocked by you for: "..reason
		notify( user, msg )
		return false
	end,
	unblock = function( user, tokens )
		if not user then return 4, "!unblock <nick>", "Unblock the user " end
		if not check( user, 4, tokens, 3, 3 ) then return false end
		local victim = tokens[3]
		local nickpair = user.sNick.."$"..victim
		if isthere( nickpair, blocked ) then
			blocked[nickpair] = nil
			pickle.store( path.."texts/blocks.txt", {blocked = blocked} )
			notify( user, "Unblocking "..victim )
		else
			notify( user, victim.." is not blocked.|" )
		end
		return false
	end,
	getblocks = function( user, tokens )
		if not user then return 0, "!getblocks", "Get all blocks " end
		if not check( user, 0 ) then return false end
		local msg = "The block pairs are\n\t"
		for nickpair, reason in pairs( blocked ) do
			msg = msg..nickpair.."\t"..reason.."\n\t"
		end
		notify( user, msg )
		return false
	end,
	getmyblocks = function( user, tokens )
		if not user then return 4, "!getmyblocks", "Get your blocks " end
		if not check( user, 4 ) then return false end
		local msg = "The users blocked by you are\n\t"
		for nickpair, reason in pairs( blocked ) do
			local blocker, blocked = nickpair:match "([^$]+)$(%S+)"
			if blocker == user.sNick then
				msg = msg..blocked.."\t"..reason.."\n\t"
			end
		end
		notify( user, msg )
		return false
	end,
	--adminstrative shortcuts
	send = function( user, tokens )
		if not user then return 0, "!send <message>", "Send message to all in the form of raw data(without adding any dcprotocol keywords) " end
		if not check( user, 0 ) then return false end
		local msg = table.concat( tokens, " ", 3 )
		return msg
	end,
	changereg = function( user, tokens )
		if not user then return 0, "!changereg <user_nick> <profile_num>", "Change the profile of a registered user." end
		if not check( user, 0, tokens, 4 ) then return false end
		local account = RegMan.GetReg( tokens[3] )
		local profile = ProfMan.GetProfile( tonumber(tokens[4]) )
		if not account then
			notify( user, "No registered user with nick "..tokens[3] )
			return false
		end
		if not profile then
			notify( user, "No profile with number "..tokens[4] )
			return false
		end
		RegMan.ChangeReg( account.sNick, account.sPassword, tonumber(tokens[4]) )
		Core.Disconnect( tokens[3] )
		notify( user, "Profile of "..tokens[3].." changed to "..profile.sProfileName )
		return false
	end,
	getpass = function( user, tokens )
		if not user then return 0, "!getpass <nick>", "Get the password of a registered user " end
		if not check( user, 0, tokens, 3 ) then return false end
		account = RegMan.GetReg( tokens[3] )
		if not account then
		notify( user, "No registered user with nick "..tokens[3] )
		return false
		end
		notify( user, "Nick = "..account.sNick.." Password: "..account.sPassword )
		return false
	end,
        clrpassbans = function( user, tokens )
		if not user then return 0, "!clrpassbans", "Clear the automatic bans done due to incorrect password imput" end
		if not check( user, 0 ) then return false end
		local bans = BanMan.GetPermBans()
		for k, v in ipairs( bans ) do
		if v.sReason and v.sReason:find( "3x bad password" ) then
			BanMan.UnbanPerm( v.sIP )
		end
		end
		notify( user, "Password Bans Cleared" )
		return false
	end,
	getprofiles = function( user, tokens )
		if not user then return 0, "!getprofiles", "Gives a list of all profiles" end
		if not check( user, 0 ) then return false end
		local profiles = ProfMan.GetProfiles()
		local msg = "\n\tProfile name\t\tNumber"
		for k, profile in ipairs( profiles ) do
		msg = msg.."\n\t"..profile.sProfileName.."\t\t"..profile.iProfileNumber
		end
		notify( user, msg )
		return false
	end,
	lunarise = function( user, tokens )
		if not user then return 3, "!lunarise <nick>", "Lunarise a user." end
		if not check(user, 3, tokens, 3, 3, true) then return false end
		lunarised[tokens[3]:lower()] = true
		SendToRoom( bot, user.sNick.." lunarised "..tokens[3].." .", "#[Hub-Feed]", 3 )
		return false
	end,
	unlunarise = function( user, tokens )
		if not user then return 4, "!unlunarise <nick>", "Unlunarise a lunarised user." end
		if not check(user, 4, tokens, 3, 3, true) then return false end
		if isthere( tokens[3], lunarised ) then
			lunarised[tokens[3]:lower()] = nil
			SendToRoom( bot, user.sNick.." unlunarised "..tokens[3].." .", "#[Hub-Feed]", 3 )
			return false
		else
			notify( user, "Sorry, the user was not lunarised." )
			return false
		end
	end,
	custhelp = function( user, tokens )
		-- To get a list of additional help commands available to a given profile
		if not user then return -1, "!custhelp", "Returns this additional help." end
		local msg, tempList = "List of additional commands available to you\n\t", {}
		table.insert( tempList, msg )
		for function_name, func in pairs( CustomCommands ) do
			local profile, syntax, comment = func()	-- --call each function in this table without any arguments , so that user = nil and that special case of each function is invoked
			if chkpriv( user, profile ) then
				table.insert( tempList, syntax.."\t\t"..comment.."\n\t" )
			end
		end
		notify( user, msg..table.concat(tempList, "") )
		return false
	end,
}

custcom = function( user, data )
	local tokens = tokenize( data )
	tokens[2] = tokens[2]:match ".(%S+)"
	local msg = CustomCommands[tokens[2]]( user, tokens )
	return msg
end
