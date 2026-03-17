local bit32 = require("bit32")

local utils = {}

function utils.pack_u32(n)
    local b1 = bit32.band(n , 0xff)
    local b2 = bit32.band(bit32.rshift(n , 8) , 0xff)
    local b3 = bit32.band(bit32.rshift(n , 16) , 0xff)
    local b4 = bit32.band(bit32.rshift(n , 24) , 0xff)
    return string.char(b1, b2, b3, b4)
end

function utils.pack_i32(n)
    local b1 = bit32.band(n , 0xff)
    local b2 = bit32.band(bit32.rshift(n , 8) , 0xff)
    local b3 = bit32.band(bit32.rshift(n , 16) , 0xff)
    local b4 = bit32.band(bit32.rshift(n , 24) , 0xff)
    return string.char(b1, b2, b3, b4)
end

function utils.pack_u16(n)
    local b1 = bit32.band(n , 0xff)
    local b2 = bit32.band(bit32.rshift(n , 8) , 0xff)
    return string.char(b1, b2)
end

function utils.unpack_u32(s, pos)
    pos = pos or 1
    local b1, b2, b3, b4 = s:byte(pos, pos + 3)
    local value =
        b1 +
        bit32.lshift(b2, 8) +
        bit32.lshift(b3, 16) +
        bit32.lshift(b4, 24)
    return value, pos + 4
end

function utils.unpack_u32_arr(s, pos, n)
    local arr = {}
    for i = 1, n do
        local u32; u32, pos = utils.unpack_u32(s, pos)
        table.insert(arr, u32)
    end
    return arr, pos
end

function utils.unpack_u16(s, pos)
    pos = pos or 1
    local b1, b2 = s:byte(pos, pos + 1)
    local value =
        b1 +
        bit32.lshift(b2, 8)
    return value, pos + 2
end

function utils.unpack_i32(s, pos)
    pos = pos or 1
    local b1, b2, b3, b4 = s:byte(pos, pos + 3)
    local value =
        b1 +
        bit32.lshift(b2, 8) +
        bit32.lshift(b3, 16) +
        bit32.lshift(b4, 24)
    if value >= 2^31 then
        value = value - 2^32
    end

    return value, pos + 4
end

function utils.unpack_string(s, pos, len)
    local value = string.sub(s, pos, pos + len - 2)
    return value, pos + len
end

function utils.unpack_RGBColor(s, pos)
    local rgb; rgb, pos = utils.unpack_u32(s, pos)
    local r = bit32.band(rgb, 0xff)
    local g = bit32.band(bit32.rshift(rgb, 8), 0xff)
    local b = bit32.band(bit32.rshift(rgb, 16), 0xff)
    return { r = r, g = g, b = b }, pos
end

function utils.unpack_RGBColorN(s, pos, num_colors)
    local colors = {}
    for i = 1, num_colors do
        local color; color, pos = utils.unpack_RGBColor(s, pos)
        table.insert(colors, color)
    end
    return colors, pos
end

function utils.pack_RGBColor(color)
    return string.char(color.r, color.g, color.b, 0)
end

function utils.pack_RGBColorN(color_list)
    local n = #color_list
    local value = ""

    for idx, color in ipairs(color_list) do
        value = value .. utils.pack_RGBColor(color)
    end
    return value
end

function utils.unpack_Mode_Data(s, pos, num_modes)
    local modes = {}
    for i = 1, num_modes do
        local mode = {}
        mode.mode_name_len, pos = utils.unpack_u16(s, pos)
        mode.mode_name, pos = utils.unpack_string(s, pos, mode.mode_name_len)
        mode.mode_value, pos = utils.unpack_i32(s, pos)
        mode.mode_flags, pos = utils.unpack_u32(s, pos)
        mode.mode_speed_min, pos = utils.unpack_u32(s, pos)
        mode.mode_speed_max, pos = utils.unpack_u32(s, pos)
        mode.mode_brightness_min, pos = utils.unpack_u32(s, pos)
        mode.mode_brightness_max, pos = utils.unpack_u32(s, pos)
        mode.mode_colors_min, pos = utils.unpack_u32(s, pos)
        mode.mode_colors_max, pos = utils.unpack_u32(s, pos)
        mode.mode_speed, pos = utils.unpack_u32(s, pos)
        mode.mode_brightness, pos = utils.unpack_u32(s, pos)
        mode.mode_direction, pos = utils.unpack_u32(s, pos)
        mode.mode_color_mode, pos = utils.unpack_u32(s, pos)
        mode.mode_num_colors, pos = utils.unpack_u16(s, pos)
        mode.mode_colors, pos = utils.unpack_RGBColorN(s, pos, mode.mode_num_colors)
        table.insert(modes,mode)
    end
    return modes, pos
end

function utils.unpack_Segment_Data(s, pos,  num_segments)
    local segments = {}
    for i = 1, num_segments do
        local segment = {}
        segment.segment_name_len, pos = utils.unpack_u16(s, pos)
        segment.segment_name, pos = utils.unpack_string(s, pos, segment.segment_name_len)
        segment.segment_type, pos = utils.unpack_i32(s, pos)
        segment.segment_start_idx, pos = utils.unpack_u32(s, pos)
        segment.segment_leds_count, pos = utils.unpack_u32(s, pos)
        table.insert(segments, segment)
    end
    return segments, pos
end

function utils.unpack_Zone_Data(s, pos, num_zones)
    local zones = {}
    for i = 1, num_zones do
        local zone = {}
        zone.zone_name_len, pos = utils.unpack_u16(s, pos)
        zone.zone_name, pos = utils.unpack_string(s, pos, zone.zone_name_len)
        zone.zone_type, pos = utils.unpack_i32(s, pos)
        zone.zone_leds_min, pos = utils.unpack_u32(s, pos)
        zone.zone_leds_max, pos = utils.unpack_u32(s, pos)
        zone.zone_leds_count, pos = utils.unpack_u32(s, pos)
        zone.zone_matrix_len, pos = utils.unpack_u16(s, pos)
        if zone.zone_matrix_len > 0 then
            zone.zone_matrix_height, pos = utils.unpack_u32(s, pos)
            zone.zone_matrix_width, pos = utils.unpack_u32(s, pos)
            zone.zone_matrix_data, pos = utils.unpack_u32_arr(s, pos, zone.zone_matrix_len - 8)
        end
        zone.num_segments, pos = utils.unpack_u16(s, pos)
        zone.segments, pos = utils.unpack_Segment_Data(s, pos, zone.num_segments)
        zone.zone_flags, pos = utils.unpack_u32(s, pos)
        table.insert(zones,zone)
    end
    return zones, pos
end

function utils.unpack_LED_Data(s, pos, num_leds)
    local leds = {}
    for i = 1, num_leds do
        local led = {}
        led.led_name_len, pos = utils.unpack_u16(s, pos)
        led.led_name, pos = utils.unpack_string(s, pos, led.led_name_len)
        led.led_value, pos = utils.unpack_u32(s, pos)
        table.insert(leds,led)
    end
    return leds, pos
end

function utils.unpack_LED_Alt_Names(s, pos, num_led_alt_names)
    local alt_names = {}
    for i = 1, num_led_alt_names do
        local alt_name = {}
        alt_name.led_alt_name_len, pos = utils.unpack_u16(s, pos)
        alt_name.led_alt_name, pos = utils.unpack_string(s, pos, alt_name.led_alt_name_len)
        table.insert(alt_names, alt_name)
    end
    return alt_names, pos
end

function utils.unpack_Controller_Data(data)
    local controller_data = {}
    local pos = 1
    controller_data.data_size, pos = utils.unpack_u32(data, pos)
    controller_data.type, pos = utils.unpack_i32(data, pos)
    controller_data.name_len, pos = utils.unpack_u16(data, pos)
    controller_data.name, pos = utils.unpack_string(data, pos, controller_data.name_len)
    controller_data.vendor_len, pos = utils.unpack_u16(data, pos)
    controller_data.vendor, pos = utils.unpack_string(data, pos, controller_data.vendor_len)
    controller_data.description_len, pos = utils.unpack_u16(data, pos)
    controller_data.description, pos = utils.unpack_string(data, pos, controller_data.description_len)
    controller_data.version_len, pos = utils.unpack_u16(data, pos)
    controller_data.version, pos = utils.unpack_string(data, pos, controller_data.version_len)
    controller_data.serial_len, pos = utils.unpack_u16(data, pos)
    controller_data.serial, pos = utils.unpack_string(data, pos, controller_data.serial_len)
    controller_data.location_len, pos = utils.unpack_u16(data, pos)
    controller_data.location, pos = utils.unpack_string(data, pos, controller_data.location_len)
    controller_data.num_modes, pos = utils.unpack_u16(data, pos)
    controller_data.active_mode, pos = utils.unpack_i32(data, pos)
    controller_data.modes, pos = utils.unpack_Mode_Data(data, pos, controller_data.num_modes)
    controller_data.num_zones, pos = utils.unpack_u16(data, pos)
    controller_data.zones, pos = utils.unpack_Zone_Data(data, pos, controller_data.num_zones)
    controller_data.num_leds, pos = utils.unpack_u16(data, pos)
    controller_data.leds, pos = utils.unpack_LED_Data(data, pos, controller_data.num_leds)
    controller_data.num_colors, pos = utils.unpack_u16(data, pos)
    controller_data.colors, pos = utils.unpack_RGBColorN(data, pos, controller_data.num_colors)
    controller_data.num_led_alt_names, pos = utils.unpack_u16(data, pos)
    controller_data.led_alt_names, pos = utils.unpack_LED_Alt_Names(data, pos, controller_data.num_led_alt_names)
    controller_data.flags, pos = utils.unpack_u32(data, pos)
    print(utils.dump(controller_data))
    return controller_data
end

function utils.dump(o, depth)
    depth = depth or 0
    if type(o) == 'table' then
        local s = "\n" .. string.rep("\t", depth) .. '{\n'
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. string.rep("\t",(depth+1)) .. '['..k..'] = ' .. utils.dump(v, depth + 1) .. ',\n'
        end
        return s .. string.rep("\t", depth) .. '}'
    elseif type(o) == "string" then
        return "\"" .. o .. "\""
    else
        return tostring(o)
    end
end

return utils