local function set_brightness()
	mp.set_property_number("brightness", -50)
	mp.commandv("seek", "20", "relative")
end

local function init()
	mp.set_property_bool("pause", true)
end

mp.add_key_binding(nil, "test", set_brightness)
init()
