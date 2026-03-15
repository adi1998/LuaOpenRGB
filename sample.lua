local OpenRGB = require("openrgb")
local socket  = require("socket")
local client, err = OpenRGB.connect("127.0.0.1", 6742)
if client == nil then
    -- retry once
    client, err = OpenRGB.connect("127.0.0.1", 6742)
    assert(client, err)
end
local version = client:negotiate_protocol(5) -- 1.0 protocol version
print("Protocol:", version)

client:set_client_name("luaopenrgb sample")

local count = client:get_controller_count()
print("Controllers:", count)

for i = 0, count - 1 do
    local data = client:get_controller_data(i)
    print("Controller", i, "data size:", data.data_size, "name:", data.name)
    client:UpdateLEDs(i,{ {r = 0, g = 0, b = 110} })
    socket.sleep(3)
    client:UpdateSingleLEDs(i, 0, {r = i*110, g = 110, b = 10})
end

print(_VERSION)