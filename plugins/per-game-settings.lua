local MIN_VOLUME = 0
local MAX_VOLUME = 100

local nds_layouts = {
	"Natural",
	"Vertical",
	"Horizontal",
	"Hybrid",
	"Top",
	"Bottom",
}

local nds_rotation_labels = {
	"0°",
	"90°",
	"180°",
	"270°",
}

local nds_rotations = {
	[nds_rotation_labels[1]] = "Rotate0",
	[nds_rotation_labels[2]] = "Rotate90",
	[nds_rotation_labels[3]] = "Rotate180",
	[nds_rotation_labels[4]] = "Rotate270",
}

local plugin = {}
plugin.name = "Per-Game Settings"
plugin.author = "kalimag"
plugin.settings = {
	{ name='remember_volume', type='boolean', label='Remember audio volume', default=true },
	{ name='default_volume', type='number', datatype='UNSIGNED', label='Default Volume (0-100)', default=MAX_VOLUME },
	{ name='remember_nds_screen', type='boolean', label='Remember NDS screen settings', default=true },
	{ name='default_nds_layout', type='select', options=nds_layouts, ordered=true, label='Default layout', default=nds_layouts[1] },
	{ name='default_nds_gap', type='number', datatype='UNSIGNED', label='Default gap (0-128)', default=0 },
	{ name='default_nds_rotation', type='select', options=nds_rotation_labels, ordered=true, label='Default rotation', default=nds_rotation_labels[1] },
	{ name='default_nds_invert', type='boolean', label='Default top/bottom inversion', default=false },
}
plugin.description =
[[
	Remembers some BizHawk settings for each game separately and restores them when swapping back to the game.

	Bind Volume Up/Volume Down in the BizHawk hotkey menu to use the volume feature effectively.
]]

local default_nds_rotation

local function sanitize_volume(volume)
	if type(volume) ~= 'number' then return nil end
	return math.floor(math.max(math.min(volume, MAX_VOLUME), MIN_VOLUME))
end

local function get_volume()
	return sanitize_volume(client.getconfig().SoundVolume)
end

local function set_volume(volume)
	volume = sanitize_volume(volume)
	if volume then
		client.getconfig().SoundVolume = volume
	end
end

local function get_gamedata(data, create)
	local gamedata = data[config.current_game]
	if not gamedata and create then
		gamedata = {}
		data[config.current_game] = gamedata
	end
	return gamedata
end

function plugin.on_setup(data, settings)
	settings.default_volume = sanitize_volume(settings.default_volume) or MAX_VOLUME
	default_nds_rotation = nds_rotations[settings.default_nds_rotation] or "Rotate0"
end

function plugin.on_game_load(data, settings)
	local gamedata = get_gamedata(data) or {}

	if settings.remember_volume then
		set_volume(gamedata.volume or settings.default_volume)
	end

	if settings.remember_nds_screen and emu.getsystemid() == "NDS" then
		nds.setscreenlayout(gamedata.nds_layout or settings.default_nds_layout)
		nds.setscreengap(gamedata.nds_gap or settings.default_nds_gap)
		nds.setscreenrotation(gamedata.nds_rotation or default_nds_rotation)
		nds.setscreeninvert(gamedata.nds_invert ~= nil and gamedata.nds_invert or settings.default_nds_invert)
	end
end

function plugin.on_game_save(data, settings)
	local gamedata

	if settings.remember_volume then
		gamedata = gamedata or get_gamedata(data, true)
		gamedata.volume = get_volume()
	end

	if settings.remember_nds_screen and emu.getsystemid() == "NDS" then
		gamedata = gamedata or get_gamedata(data, true)
		gamedata.nds_layout = nds.getscreenlayout()
		gamedata.nds_gap = nds.getscreengap()
		gamedata.nds_rotation = nds.getscreenrotation()
		gamedata.nds_invert = nds.getscreeninvert()
	end
end

return plugin
