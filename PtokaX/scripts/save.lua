--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

function OnStartup()
	tConfig = {
	   iTimer = TmrMan.AddTimer( 10 * 60 * 10^3, "save" )			-- Execute save() every 10 minutes
	}
end

function OnExit()
	TmrMan.RemoveTimer( tConfig.iTimer )
end

function save()
	SetMan.Save()
	RegMan.Save()
	BanMan.Save()
	ProfMan.Save()
end
