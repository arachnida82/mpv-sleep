local config_file = "../sleep.json" -- TODO: update path to . (since sleep.json should be in is.xyz.mpv)

local time = {
	minutes = 25,
	active = false,
	format = "%02d:%02d:%02d", -- (HH:MM:SS)
	remaining = nil,

	prev_state = {
		timestamp = "",
		remaining = nil,
		was_active = false,
		last_update = "", -- ISO 8601
	},
}

local gesture_state = {
	last_trigger_sec = 0,
	trigger_count = 0,
	latency = 3, -- seconds
}


--[[ todo:
perhaps instead of using a json file, we simply write the state attributes at the top of sleep.lua.
then have test.lua edit itself as need be.
]]

---------------------------
--      JSON PARSER      --
---------------------------
local function read_jsonkey_value(file_str, json_obj, obj_key)
	local b_obj = string.find(file_str, json_obj)
	local e_obj = string.find(file_str, "}", b_obj)

	if not (b_obj or e_obj) then
		print(json_obj .. "does not exist or " .. config_file "is formatted incorrectly")
		return nil
	end

	local substr = string.sub(file_str, b_obj, e_obj)
	local key_val = string.match(substr, obj_key)

	if not key_val then
		print("could not extract \"" .. string.match(obj_key, "\"([^\"]+)\"") .. "\"" .. " from " .. file)
		return nil
	end

	return key_val
end

local function read_config()
	print("opening", config_file .. "...")

	local openf = io.input(config_file)
	if openf == nil then
		print("failed to open", config_file .. "!")
		-- TODO: we should make sure it exists, otherwise should create it
	end

	local file_str = openf:read("*all")
	if file_str == nil or file_str == "" then
		print("failed to read config_file into string or config_file is empty")
	end

	local default_time = read_jsonkey_value(file_str, "\"config\"", "\"default_time\"%s*:%s*(%d+)")
	local prevstate_tstamp = read_jsonkey_value(file_str, "\"previous_state\"", "\"timestamp\"%s*:%s*\"(.-)\"")
	local prevstate_lastup = read_jsonkey_value(file_str, "\"previous_state\"", "\"last_updated\"%s*:%s*\"(.-)\"")
	local prevstate_active = read_jsonkey_value(file_str, "\"previous_state\"", "\"was_active\"%s*:%s*([a-zA-Z]+)")

	if (default_time and prevstate_tstamp and prevstate_lastup and prevstate_active) then
		--[[ print("default_time: " .. default_time)
		print("prevstate_tstamp: " .. prevstate_tstamp)
		print("prevstate_lastup: " .. prevstate_lastup)
		print("prevstate_active: " .. prevstate_active) ]]
	else
		-- print("something went wrong")
	end

	print("closing", config_file .. ".")
	io.close(openf)
end

local function reinstate_tstamp(time)
	-- according to a gesture, this should be called, and seek to @param in file
end

local function export_time()
	-- we should retrieve the current time stamp and export it to sleep.json
	-- at this point, mpv should be paused or terminated.
end

local function stop_timer()
end

local function reset_timer()
end

local function set_timer()
	timer.minutes = read_config() or timer.minutes
	timer.active = true
	mp.osd_message("Timer has been set for " .. timer.minutes .. " minutes.", 3)
end

local function display_time()
end

-- user calls this
local function handle_gesture()
	    mp.osd_message("Gesture Received.", 3)
		set_timer()

		-- TODO:
		-- the firs time handle_gestures() is called, timer should be set
		-- if handle_gestures() is called a second time within a short period, then we should cycle timer off
		-- if handle_gestures() is called again a third time within a short period, then we should reinstate the last time export
		-- should include debouncing logic for clean gesture input (eg. ignore calls made within some tiny time before each other)
end

-- called immediately upon opening a media config_file
function main()
	    mp.osd_message("Sleep timer script initialized!", 3)
end

mp.add_key_binding(nil, "sleep", handle_gesture) -- the user invokes this by gesturing (user-set in input.conf)
main() -- this is run upon opening a media config_file
