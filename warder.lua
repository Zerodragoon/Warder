_addon.name = 'Warder'
_addon.version = '1.0'
_addon.author = 'Zerodragoon'
_addon.commands = {'warder','ward'}

require('luau')
inspect = require('inspect')
res = require 'resources'

defaults = {}
defaults.auto_smn = false
defaults.favor = true
defaults.favor_avatar = 'Carbuncle'
defaults.wards = {}

settings = config.load(defaults)

avatars = {'Carbuncle', 'Diabolos', 'Fenrir', 'Siren', 'Cait Sith', 'Garuda', 'Ifrit', 'Leviathan', 'Ramuh', 'Shiva', 'Titan'}

local commands = {}

windower.register_event('load', function()
    settings = config.load(defaults)
end)

function ward()
	windower.add_to_chat(7,'Warding')    

	if settings.auto_smn then
		windower.add_to_chat(7,'Auto Smn')    
		local player = windower.ffxi.get_player()
		
		if player.main_job == 'SMN' or player.sub_job == 'SMN' then
			windower.add_to_chat(7,'Summoner')    
			local pet = windower.ffxi.get_mob_by_target('pet')

			if settings.favor then
				windower.add_to_chat(7,'Favor')    

				if not pet then
					windower.send_command('input /ma "'..settings.favor_avatar..'" <me>')
				elseif pet and pet.name:lower() ~= settings.favor_avatar:lower() then
					windower.send_command('input /pet "Release" <me>')
				else
					if not checkBuff(player, "Avatar's Favor") then
						windower.send_command('input /ja "Avatar\'s Favor" <me>')
					end
				end
			end
		end
		
	end
end

function checkBuff(player, buff)
	if player ~= nil and player.buffs ~= nil then
		for index, buffid in pairs(player.buffs) do
			if res.buffs[buffid].en:lower() == buff:lower() then
				return true
			end
		end
	end
	return false
end

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value:lower() == val:lower() then
            return true
        end
    end

    return false
end

local function start()
	windower.add_to_chat(7,'Started warding')                           
	settings.auto_smn = true
	config.save(settings)
end

local function stop()
	windower.add_to_chat(7,'Stopped warding')                           
	settings.auto_smn = false
	config.save(settings)
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

local function favor_avatar(avatar)
	if has_value(avatars, avatar) then
		windower.add_to_chat(1,'Favor Avatar Set to '..avatar..'')
		settings.favor_avatar = avatar
		config.save(settings)
	else
		windower.add_to_chat(7,'Invalid Favor Avatar')
	end
end

local function print_settings()
	local messages_str = 'Warder Settings: '
	
	messages_str = messages_str..'\n Enabled : '..tostring(settings.auto_smn)..''
	messages_str = messages_str..'\n Favor Enabled : '..tostring(settings.favor)..''
	messages_str = messages_str..'\n Favor Avatar : '..tostring(settings.favor_avatar)..''
	
	--TODO Implement Ward Settings
	
	windower.add_to_chat(7,''..messages_str..'')	
end

local function help()
	local messages_str = 'Welcome to Warder, a tool for automaticly buffing as summoner \n \n '
	
	messages_str = messages_str..'Commands: \n'
	messages_str = messages_str..'  Start: Starts warding (the addon loads off by default) \n'
	messages_str = messages_str..'  Stop: Stops warding \n'
	messages_str = messages_str..'  Favor: Toggles between maintaing favor with an avatar when not warding \n'
	messages_str = messages_str..'  Favor Avatar: Sets the avatar to use for favor, Options : Carbuncle, Diabolos, Fenrir, Cait Sith, Garuda, Ifrit, Leviathan, Ramuh, Shiva, Titan \n'
	messages_str = messages_str..'  Settings: Print the current saved settings \n'
	messages_str = messages_str..'  Help: Brings up this help menu \n'

	windower.add_to_chat(7,''..messages_str..'')	
end

local function handle_command(...)
    local cmd  = (...) and (...):lower()
    local args = {select(2, ...)}
    if commands[cmd] then
        local msg = commands[cmd](unpack(args))
        if msg then
            windower.add_to_chat(7,'Error running command: '..tostring(msg)..'')                           
        end
    else
		windower.add_to_chat(7,'Unknown command: '..cmd..'')                           
    end
end

commands['start'] = start
commands['stop'] = stop
commands['favor'] = favor
commands['favoravatar'] = favor_avatar
commands['settings'] = print_settings
commands['help'] = help

windower.register_event('addon command', handle_command)

ward:loop(3)