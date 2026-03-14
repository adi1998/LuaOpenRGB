local OpenRGB = require("openrgb")
local socket  = require("socket")
local client = OpenRGB.connect("127.0.0.1", 6742)

local version = client:negotiate_protocol(5) -- 1.0 protocol version
print("Protocol:", version)

client:set_client_name("luaopenrgb sample")

local count = client:get_controller_count()
print("Controllers:", count)

for i = 0, count - 1 do
    local data = client:get_controller_data(i)
    print("Controller", i, "data size:", data.data_size, "name:", data.name)
    client:UpdateLEDs(i,{ {r = 10, g = 120, b = 180} })
end

print(_VERSION)