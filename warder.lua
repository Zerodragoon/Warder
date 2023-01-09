_addon.name = 'Warder'
_addon.version = '1.0'
_addon.author = 'Zerodragoon'
_addon.commands = {'warder','ward'}

defaults = {}
defaults.favor = true
defaults.favor_avatar = 'Carbuncle'
defaults.wards = {}

settings = config.load(defaults)

auto_smn = false

local commands = {}

windower.register_event('load', function()
    settings = config.load(defaults)
end)

local function start()
	windower.add_to_chat(1,'Started warding')                           
	auto_smn = true
end

local function stop()
	windower.add_to_chat(1,'Stopped warding')                           
	auto_smn = false
end

local function favor()
	if settings.favor == false then
		settings.favor = true
		windower.add_to_chat(7,'You will now maintain a favor avatar when not warding')
	elseif settings.favor == true then
		settings.favor = false
		windower.add_to_chat(7,'You will no longer maintain a favor avatar when not warding')
	end
	config.save(settings)
end

local function help()
	local messages_str = 'Welcome to Warder, a tool for automaticly buffing as summoner \n \n '
	
	messages_str = messages_str..'Commands: \n'
	messages_str = messages_str..'  Start: Starts warding (the addon loads off by default) \n'
	messages_str = messages_str..'  Stop: Stops warding \n'
	messages_str = messages_str..'  Favor: Toggles between maintaing favor with an avatar when not warding \n'
	messages_str = messages_str..'  Help: Brings up this help menu \n'

	windower.add_to_chat(1,''..messages_str..'')	
end

commands['start'] = start
commands['stop'] = stop
commands['favor'] = stop
commands['help'] = help


windower.register_event('addon command', handle_command)