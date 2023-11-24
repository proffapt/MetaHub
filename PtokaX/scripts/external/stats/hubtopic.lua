--[[

	This file is part of HiT Hi FiT Hai's PtokaX scripts

	Copyright: © 2014 HiT Hi FiT Hai group
	Licence: GNU General Public Licence v3 https://www.gnu.org/licenses/gpl-3.0.html

--]]

NewHubTopic = (function()
	local sQuery = [[INSERT INTO hubtopics (topic, assignee, dated)
	VALUES( '%s', '%s', NOW() )]]
	return function ( sNick, sTopic )
		local sNick, sTopic = sqlCon:escape( sNick ), sqlCon:escape( sTopic )
		assert( sqlCon:execute(sQuery:format( sTopic, sNick )) )
	end
end)()
