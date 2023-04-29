_addon.name = 'Warder'
_addon.version = '1.0'
_addon.author = 'Zerodragoon'
_addon.commands = {'warder', 'ward'}

require('luau')
require('packets')
inspect = require('inspect')
res = require 'resources'

defaults = {}
defaults.auto_smn = false
defaults.favor = true
defaults.favor_avatar = 'Carbuncle'
defaults.rebuff_seconds = 45
defaults.wards = L {}

settings = config.load(defaults)

avatars = {
    ['Carbuncle'] = {'Shining Ruby'},
    ['Diabolos'] = {'Noctoshield', 'Dream Shroud'},
    ['Fenrir'] = {'Ecliptic Growl', 'Ecliptic Howl', 'Heavenward Howl'},
    ['Siren'] = {'Katabatic Blade', 'Chinook', "Wind's Blessing"},
    ['Cait Sith'] = {'Reraise II'},
    ['Garuda'] = {'Hastega', 'Hastega II', 'Aerial Armor', 'Fleet Wind'},
    ['Ifrit'] = {'Crimson Howl', 'Inferno Howl'},
    ['Leviathan'] = {'Soothing Current'},
    ['Ramuh'] = {'Rolling Thunder', 'Lightning Armor'},
    ['Shiva'] = {'Frost Armor', 'Crystal Blessing'},
    ['Titan'] = {'Earthen Ward', 'Earthen Armor'}
}

ward_buff_names = {
    ['Shining Ruby'] = 'Shining Ruby',
    ['Crimson Howl'] = 'Warcry',
    ['Inferno Howl'] = 'Enfire',
    ['Frost Armor'] = 'Ice Spikes',
    ['Crystal Blessing'] = 'TP Bonus',
    ['Noctoshield'] = 'Phalanx',
    ['Dream Shroud'] = 'Magic Def. Boost',
    ['Ecliptic Growl'] = 'CHR Boost',
    ['Ecliptic Howl'] = 'Evasion Boost',
    ['Heavenward Howl'] = 'Endrain',
    ['Katabatic Blade'] = 'Enaero',
    ['Chinook'] = 'Aquaveil',
    ["Wind's Blessing"] = "Wind's Blessing",
    ["Reraise II"] = "Reraise",
    ["Hastega"] = "Haste",
    ["Hastega II"] = "Haste",
    ["Fleet Wind"] = "Quickening",
    ["Aerial Armor"] = "Blink",
    ["Soothing Current"] = "Curing Conduit",
    ["Rolling Thunder"] = "Enthunder",
    ["Lightning Armor"] = "Shock Spikes",
    ["Earthen Ward"] = "Stoneskin",
    ["Earthen Armor"] = "Earthen Armor"
}

local commands = {}

windower.register_event('load', function()
    settings = config.load(defaults)
end)

local player_buffs = {}
blank_0x063_v9_inc = false
vana_offset = 572662306 + 1009810800

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    -- deduce vana_offset used in calculation of buff duration
    if not zoning and id == 0x037 then
        vana_offset = os.time() - (((original:unpack("I", 0x41) * 60 - original:unpack("I", 0x3D)) % 0x100000000) / 60)

        -- Keep track of player buff durations (credit: gearswap development team)
    elseif not zoning and id == 0x063 then
        if original:byte(0x05) == 0x09 and blank_0x063_v9_inc then
            -- After zoning, players receive a blank 0x063 v9 packet
            -- (because their buff line is temporarily empty)
            -- So this flag is set in 0x00A
            blank_0x063_v9_inc = false
            -- However, players can also reload gearswap and fail to get a 0x063 v9 packet from
            -- windower.packets.last_incoming, which leaves them without buff information but with a
            -- informative 0x063 v9 packet coming next. So this step checks confirms the packet is
            -- empty before returning
            if original:sub(0x49, 0xC8) == string.char(0):rep(128) then
                return
            end
        end

        -- Clear out any buff information and recalculate
        player_buffs = {}

        for i = 1, 32 do
            local buff_id = original:unpack('H', i * 2 + 7)
            if buff_id ~= nil and buff_id ~= 255 and buff_id ~= 0 then -- 255 is used for "no buff"
                local t_in_minutes = original:unpack('I', i * 4 + 0x45)
                local t = 0
                if t_in_minutes ~= nil then
                    t = t_in_minutes / 60
                end
                player_buffs[buff_id] = setmetatable({
                    id = buff_id,
                    time = t
                }, {
                    __index = function(t, k)
                        if k and k == 'duration' then
                            return rawget(t, 'time') - os.time() + (vana_offset or 0)
                        else
                            return rawget(t, k)
                        end
                    end
                })
            end
        end
    elseif id == 0xA and zoning then
        zoning = false
        blank_0x063_v9_inc = true
    end
end)

function ward()
    if not settings.auto_smn then
        return
    end

    local player = windower.ffxi.get_player()

    if not (player.main_job == 'SMN' or player.sub_job == 'SMN') then
        return
    end

    local pet = windower.ffxi.get_mob_by_target('pet')
    local skipfavor = false

    for index, value in ipairs(settings.wards) do
        local buff = get_ward_buff_name(value)

        if not checkBuff(player, buff) then
            skipfavor = true
            local avatar = get_ward_avatar(value)

            if not pet then
                windower.send_command('input /ma "' .. avatar .. '" <me>')
                return
            elseif pet and pet.name:lower() ~= avatar:lower() then
                windower.send_command('input /pet "Release" <me>')
                return
            else
                local abil_recasts = windower.ffxi.get_ability_recasts()
                local available_ja = S(windower.ffxi.get_abilities().job_abilities)

                if available_ja:contains(172) and abil_recasts[174] == 0 then
                    if available_ja:contains(385) and abil_recasts[108] == 0 then
                        windower.send_command('wait 1.5;input /ja "Apogee" <me>;wait 5;input /ja "' .. value .. '" <me>')
                    else
                        windower.send_command('input /ja "' .. value .. '" <me>')
                    end
                end
                return
            end
        end
    end

    if settings.favor then
        if not pet then
            windower.send_command('input /ma "' .. settings.favor_avatar .. '" <me>')
        elseif pet and pet.name:lower() ~= settings.favor_avatar:lower() then
            windower.send_command('input /pet "Release" <me>')
        else
            if not checkBuff(player, "Avatar's Favor") then
                windower.send_command('input /ja "Avatar\'s Favor" <me>')
            end
        end
    end
end

--- Check whether the player currently has a given buff with sufficient duration
---@param player any
---@param buff any
---@return true when the player has the given buff, with more than rebuff_seconds left; false otherwise
function checkBuff(player, buff)
    if player ~= nil and player.buffs ~= nil then
        for index, buffid in pairs(player.buffs) do
            if res.buffs[buffid].en:lower() == buff:lower() then
                -- Check the duration of the ward against the rebuff duration.
                -- If we don't have duration information, then assume that plenty of time is left.
                if player_buffs[buffid] ~= nil then
                    return player_buffs[buffid].duration > settings.rebuff_seconds
                else
                    return true
                end
            end
        end
    end
    return false
end

function valid_avatar(val)
    for index, value in pairs(avatars) do
        if index:lower() == val:lower() then
            return true
        end
    end

    return false
end

function valid_ward(val)
    for index, value in pairs(avatars) do
        for index2, value2 in ipairs(value) do
            if value2:lower() == val:lower() then
                return true
            end
        end
    end

    return false
end

function get_ward_avatar(val)
    for index, value in pairs(avatars) do
        for index2, value2 in ipairs(value) do
            if value2:lower() == val:lower() then
                return index
            end
        end
    end
end

function get_ward_buff_name(val)
    for index, value in pairs(ward_buff_names) do
        if index:lower() == val:lower() then
            return value
        end
    end
end

function tableSize(tab)
    local count = 0

    for k, i in ipairs(tab) do
        count = count + 1
    end

    return count
end

local function start()
    windower.add_to_chat(7, 'Started warding')
    settings.auto_smn = true
    config.save(settings)
end

local function stop()
    windower.add_to_chat(7, 'Stopped warding')
    settings.auto_smn = false
    config.save(settings)
end

local function favor()
    if settings.favor == false then
        settings.favor = true
        windower.add_to_chat(7, 'You will now maintain a favor avatar when not warding')
    elseif settings.favor == true then
        settings.favor = false
        windower.add_to_chat(7, 'You will no longer maintain a favor avatar when not warding')
    end
    config.save(settings)
end

local function favor_avatar(avatar)
    if valid_avatar(avatar) then
        windower.add_to_chat(7, 'Favor Avatar Set to ' .. avatar .. '')
        settings.favor_avatar = avatar
        config.save(settings)
    else
        windower.add_to_chat(7, 'Invalid Favor Avatar')
    end
end

local function add_ward(ward)
    if valid_ward(ward) then
        windower.add_to_chat(7, 'Added ward: ' .. ward .. '')
        settings.wards:append(ward)
        config.save(settings)
    else
        windower.add_to_chat(7, 'Invalid Ward')
    end
end

local function remove_ward(ward)
    local remove_index = nil
    for index, value in ipairs(settings.wards) do
        if value:lower() == ward:lower() then
            remove_index = index
            break
        end
    end

    if remove_index then
        windower.add_to_chat(7, 'Removed ward: ' .. ward .. '')
        list.remove(settings.wards, remove_index)
        config.save(settings)
    else
        windower.add_to_chat(7, '' .. ward .. ' not found in the list of current wards to buff')
    end
end

local function clear_wards()
    windower.add_to_chat(7, 'Cleared all wards')
    settings.wards = {}
    config.save(settings)
end

local function print_settings()
    local messages_str = 'Warder Settings: '

    messages_str = messages_str .. '\n Enabled : ' .. tostring(settings.auto_smn) .. ''
    messages_str = messages_str .. '\n Favor Enabled : ' .. tostring(settings.favor) .. ''
    messages_str = messages_str .. '\n Favor Avatar : ' .. tostring(settings.favor_avatar) .. ''

    messages_str = messages_str .. '\n Wards : '

    for index, value in ipairs(settings.wards) do
        messages_str = messages_str .. '\n   ' .. value .. ''
    end

    windower.add_to_chat(7, '' .. messages_str .. '')
end

local function help()
    local messages_str = 'Welcome to Warder, a tool for automaticly buffing as summoner \n \n '

    messages_str = messages_str .. 'Commands: \n'
    messages_str = messages_str .. '  Start: Starts warding (the addon loads off by default) \n'
    messages_str = messages_str .. '  Stop: Stops warding \n'
    messages_str = messages_str .. '  Settings: Print the current saved settings \n'
    messages_str = messages_str .. '  Help: Brings up this help menu \n'
    messages_str = messages_str .. '  Favor: Toggles between maintaing favor with an avatar when not warding \n'
    messages_str = messages_str ..
                       '  FavorAvatar: Sets the avatar to use for favor, Options : Carbuncle, Diabolos, Fenrir, Cait Sith, Garuda, Ifrit, Leviathan, Ramuh, Shiva, Titan \n'
    messages_str = messages_str .. '  AddWard:  Adds a ward to use, valid wards are listed by avatar before\n'
    messages_str = messages_str .. '    Carbuncle: Shining Ruby\n'
    messages_str = messages_str .. '  RemoveWard:  Removes a ward to buff\n'
    messages_str = messages_str .. '  ClearWards:  Clears the list of wards to use\n'

    windower.add_to_chat(7, '' .. messages_str .. '')
end

local function handle_command(...)
    local cmd = (...) and (...):lower()
    local args = {select(2, ...)}
    if commands[cmd] then
        local msg = commands[cmd](unpack(args))
        if msg then
            windower.add_to_chat(7, 'Error running command: ' .. tostring(msg) .. '')
        end
    else
        windower.add_to_chat(7, 'Unknown command: ' .. cmd .. '')
    end
end

commands['start'] = start
commands['stop'] = stop
commands['favor'] = favor
commands['favoravatar'] = favor_avatar
commands['settings'] = print_settings
commands['help'] = help
commands['addward'] = add_ward
commands['removeward'] = remove_ward
commands['clearwards'] = clear_wards

windower.register_event('addon command', handle_command)

ward:loop(5)
