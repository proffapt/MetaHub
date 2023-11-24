local tDatabase = {
	latest = {
		'latest',
		'offliner',
		'latest@hhfh',
		'localhost'
	},
	ptokax = {
		'ptokax',
		'ptokax',
		'ptokax@hhfh',
		'localhost'
	},
	stats = {
		'stats',
		'stat',
		'stats@hhfh',
		'localhost'
	},
}

local function Handle( sName )
	return unpack( tDatabase[sName] )
end

return Handle
