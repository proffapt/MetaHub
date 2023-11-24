--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function OnStartup()
	tConfig = {
		bRegFlag = false,
		iRegProfile = 5,
		sRegProfileName = "Reg",
		sBotName = SetMan.GetString(21),
		sPrefix = "[-+/?#!]",
		tTemplates = {
			sRegSuccess = "\n\n\tYou have successfully registered yourself.\n\t"..
				string.rep( "¯",40 ).."\n"..
				"\tUser Name:\t %-32s \n"..
				"\tPassword:\t %s \n\t"..
				"\tProfile:\t %s \n\t"..
				string.rep( "_",40 ).."\n"..
				"\tPlease make a note of this information.\n\tPlease reconnect to activate your status.\n",
			sPassChange = "\n\n\tYou've changed your password successfully\n\t"..
				"from %s to %s . Update your favorite hub\n\t"..
				"settings to use the new password.",
			sHelpMenu = "\n\n\tRegMe Command Help\n\n\tCommand\t\tDescription\n\t"..string.rep( "¯",40 ).."\n"
		}
	}
end

function ToArrival( tUser, sData )
	local sTo = sData:match( "$To: (%S+)" )
	if sTo ~= tConfig.sBotName then
		return false
	end
	local sCmd = sData:match( "%b<> "..tConfig.sPrefix.."(%w+)" )
	if sCmd then
		sCmd = sCmd:lower()
		if sCmd and tRegCmds[sCmd] then
			Core.SendPmToUser( tUser, tConfig.sBotName, tRegCmds[sCmd](tUser, sData, sCmd) )
			return true
		end
	end
	return false
end

function PasswordCheck( sPassword )
	if sPassword:find( "[%c$|<>:?*\"/\\]" ) then
		return true
	end
	return false
end
tRegCmds = {
	regme = function( tUser, sData, sCmd )
		if tConfig.bRegFlag then
			if tUser then
				local sNick = tUser.sNick
				if tUser.iProfile ~= -1 then
					return "Don't be silly "..sNick..". you're already registered here."
				else
					local sPassword = sData:match "%b<> .%w+ (%S+)|$"
					if not sPassword then
						return "Error! Usage: "..tConfig.sPrefix..sCmd.." <password>"
					end
					if PasswordCheck(sPassword) then
						return "Your password contains invalid characters. Please choose a new one."
					end
					RegMan.AddReg( sNick, sPassword, tConfig.iRegProfile )
					RegMan.Save()
					return tConfig.tTemplates.sRegSuccess:format( sNick, sPassword, tConfig.sRegProfileName )
				end
			else
				return "Register yourself"
			end
		else
			return "Registrations not open yet"
		end
	end,

	passwd = function( tUser, sData, sCmd )
		if tUser then
			if tUser.iProfile == -1 then
				return "Don't be silly "..tUser.sNick.." you're not registered here."
			else
				local sOldPass, sNewPass = sData:match "%b<> .%w+ (%S+) (%S+)|$"
				if sOldPass and sNewPass then
					local sPassword, iProfile = RegMan.GetReg( tUser.sNick ).sPassword, tUser.iProfile
					if sPassword and iProfile then
						if sOldPass:lower() ~= sPassword:lower() then
							return "That is not your correct password. Please try again. [case insensitive]"
						end
						if PasswordCheck( sNewPass ) then
							return "Your password contains invalid characters. Please choose a new one."
						end
						if sNewPass == sOldPass then
							return "Your cannot change to the same password. Please choose a different one."
						end
						RegMan.ChangeReg( tUser.sNick, sNewPass, iProfile )
						RegMan.Save()
						return tConfig.tTemplates.sPassChange:format( sOldPass, sNewPass )
					end
				else
					return "Error! Usage: ."..tConfig.sPrefix..sCmd.." <old password> <new password>"
				end
			end
		else
			return "Change your password"
		end
	end,

	rmhelp = function( tUser, sData, sCmd )
		if tUser then
			local sReply = tConfig.tTemplates.sHelpMenu
			for i, v in pairs(tRegCmds) do
				local sDescription = tRegCmds[i]()
				sReply = sReply.."\t!"..("%-15s"):format( i ).."\t"..sDescription.."\n"
			end
			return sReply.."\n\t"..string.rep("¯",40).."\n\n"
		else
			return "Registration help menu","",""
		end
	end,

	regflag = function( tUser, sData, sCmd )
		local sReturn = "The registration flag is set to: "..tostring( tConfig.bRegFlag )
		if not tUser then
			return sReturn, "", ""
		end
		if tUser.iProfile == 0 then
			tConfig.bRegFlag = not tConfig.bRegFlag
			sReturn = "Registration flag changed to: "..tostring( tConfig.bRegFlag )
		end
		return sReturn
	end,
}
