local socket = require("socket")
local utils = require("utils")

local OpenRGB = {}
OpenRGB.__index = OpenRGB

local MAGIC = "ORGB"
local PORT = 6742

-- Packet IDs enum
local PKT = {
    NET_PACKET_ID_REQUEST_CONTROLLER_COUNT = 0,
    NET_PACKET_ID_REQUEST_CONTROLLER_DATA = 1,
    NET_PACKET_ID_REQUEST_PROTOCOL_VERSION = 40,
    NET_PACKET_ID_SET_CLIENT_NAME = 50,
    NET_PACKET_ID_RGBCONTROLLER_UPDATELEDS = 1050,
    NET_PACKET_ID_RGBCONTROLLER_UPDATESINGLELED = 1052,
}

local function build_header(pkt_dev_idx, pkt_id, pkt_size)
    return MAGIC ..
        utils.pack_u32(pkt_dev_idx) ..
        utils.pack_u32(pkt_id) ..
        utils.pack_u32(pkt_size)
end

function OpenRGB.connect(host, port)
    local self = setmetatable({}, OpenRGB)

    self.host = host or "127.0.0.1"
    self.port = port or PORT

    local sock, err = socket.tcp()
    if err then
        return nil, err
    end
    self.sock = sock
    _, err = self.sock:connect(self.host, self.port)
    if err then
        return nil, err
    end
    self.protocol_version = 0

    return self, nil
end

function OpenRGB:send_packet(dev_idx, pkt_id, payload)
    payload = payload or ""

    local header = build_header(dev_idx, pkt_id, #payload)

    local _, err = self.sock:send(header .. payload)
    if err then
        return err
    end
end

function OpenRGB:recv_header()
    local data, err = self.sock:receive(16)
    if not data then return nil, err end

    local magic = data:sub(1,4)

    if magic ~= MAGIC then
        return nil, "Invalid OpenRGB packet"
    end

    local pos = 5
    local dev; dev, pos = utils.unpack_u32(data, pos)
    local pkt; pkt, pos = utils.unpack_u32(data, pos)
    local size; size, pos = utils.unpack_u32(data, pos)

    return {
        dev = dev,
        pkt = pkt,
        size = size
    }, nil
end

function OpenRGB:recv_payload(size)
    if size == 0 then
        return "", nil
    end

    return self.sock:receive(size)
end

function OpenRGB:negotiate_protocol(max_version)
    max_version = max_version or 5

    local payload = utils.pack_u32(max_version)

    self:send_packet(0, PKT.NET_PACKET_ID_REQUEST_PROTOCOL_VERSION, payload)

    self.sock:settimeout(1)

    local header = self:recv_header()

    if not header then
        self.protocol_version = 0
        return 0
    end

    payload = self:recv_payload(header.size)

    local server_ver = utils.unpack_u32(payload)

    self.protocol_version = math.min(server_ver, max_version)

    return self.protocol_version
end

function OpenRGB:set_client_name(name)
    local payload = name .. "\0"
    self:send_packet(0, PKT.NET_PACKET_ID_SET_CLIENT_NAME, payload)
end

function OpenRGB:get_controller_count()
    self:send_packet(0, PKT.NET_PACKET_ID_REQUEST_CONTROLLER_COUNT, "")

    local header = self:recv_header()
    local payload = self:recv_payload(header.size)

    local count = utils.unpack_u32(payload)

    return count
end

function dump(o, depth)
    depth = depth or 0
    if type(o) == 'table' then
        local s = "\n" .. string.rep("\t", depth) .. '{\n'
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. string.rep("\t",(depth+1)) .. '['..k..'] = ' .. dump(v, depth + 1) .. ',\n'
        end
        return s .. string.rep("\t", depth) .. '}'
    elseif type(o) == "string" then
        return "\"" .. o .. "\""
    else
        return tostring(o)
    end
end

function OpenRGB:get_controller_data(idx)

    local payload = ""

    if self.protocol_version > 0 then
        payload = utils.pack_u32(self.protocol_version)
    end

    self:send_packet(idx, PKT.NET_PACKET_ID_REQUEST_CONTROLLER_DATA, payload)

    local header, err = self:recv_header()
    if not header then
        return nil, err
    end
    payload, err = self:recv_payload(header.size)
    if err then
        return nil, err
    end

    local controller_data = utils.unpack_Controller_Data(payload)

    return controller_data, nil
end

function OpenRGB:UpdateLEDs(pkt_dev_idx, led_color)
    local payload = ""
    local n = #led_color
    payload = payload .. utils.pack_u32(4 + 2 + 4*n) -- data_size
    payload = payload .. utils.pack_u16(n) -- num_colors
    payload = payload .. utils.pack_RGBColorN(led_color) -- led_color

    self:send_packet(pkt_dev_idx, PKT.NET_PACKET_ID_RGBCONTROLLER_UPDATELEDS, payload)
end

function OpenRGB:UpdateSingleLEDs(pkt_dev_idx, led_idx, led_color)
    local payload = ""
    payload = payload .. utils.pack_i32(led_idx)
    payload = payload .. utils.pack_RGBColor(led_color)

    self:send_packet(pkt_dev_idx, PKT.NET_PACKET_ID_RGBCONTROLLER_UPDATESINGLELED, payload)
end

return OpenRGB