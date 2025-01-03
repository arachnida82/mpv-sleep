local config_file = "../sleep.json" -- TODO: update path to .

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
perhaps instead of using a json config_file, we simply write the state attributes at the top of this config_file.
then have test.lua edit itself as need be.
]]

--[[
TODO: merge `read_default_time()` and `read_prev_state`
      into `read_jsonkey_value(file_str, block_key, value_key)`
      then have called by `reinstate_prevstate()` to retrieve keys (timestamp, last_updated, etc.)
      and also wherever read_default_time shoudl be called, will retrieve default_time in config block

	  (parsing logic is the same, so we should reduce the code)
]]

---------------------------
--      JSON PARSER      --
---------------------------

local function read_default_time(file_str)
	local config_block_i = string.find(file_str, "\"config\"")
	if not config_block_i then
		print("\"config\" not found in " .. config_file)
		return nil
	end

	local end_config_i = string.find(file_str, "}", config_block_i)
	if not end_config_i then
		print("formatting error in " .. config_file)
		return nil
	end

	local substr = string.sub(file_str, config_block_i, end_config_i)
	local def_time = string.match(substr, "\"default_time\"%s*:%s*(%d+)")

	if not def_time then
		print("could not extract \"default_time\" value in \"config\" key from " .. config_file)
		return nil
	end

	return tonumber(def_time)
end

local function read_prev_state(file_str)
	-- we want to extract under previous_state:
	      -- timestamp
	      -- last_updated
	      -- was_active
	      -- last_update

	  local prevstate_block_i = string.find(file_str, "\"previous_state\"")
	  if not prevstate_block_i then
		  print("\"previous_state\" block not found in " .. config_file)
		  return nil
	  end

	  local end_prevstate_i = string.find(file_str, "}", prevstate_block_i)
	  if not end_prevstate_i then
		  print("formatting error in " .. config_file)
		  return nil
	  end

	  local substr = string.sub(file_str, prevstate_block_i, end_prevstate_i)
	  local tstamp = string.match(substr, "\"timestamp\"%s*:%s*\"(.-)\"")
	  local lastup = string.match(substr, "\"last_updated\"%s*:%s*\"(.-)\"")
	  local was_active = string.match(substr, "\"was_active\"%s*:%s*([a-zA-Z]+)")

	  if not tstamp then
		print("could not extract \"timestamp\" value in \"previous_state\" key from " .. config_file)
		return nil
	  end

	  if not lastup then
		print("could not extract \"last_updated\" value in \"previous_state\" key from " .. config_file)
		return nil
	  end

	  if not was_active then
		print("could not extract \"was_active\" value in \"previous_state\" key from " .. config_file)
		return nil
	  end
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

	read_default_time(file_str)
	read_prev_state(file_str)

	print("closing", config_file .. ".")
	io.close(openf)
end

local function reinstate_tstamp()
	-- call read_config and grab the exported time stamp, then seek to that position in the config_file
	-- config_file is, timer
end

local function export_time()
	-- we should retrieve the current time stamp and export it to sleep.json
	-- at this point, mpv should be paused or terminated.
end

local function stop_timer()
end

local function reset_timer()
end

local function format_time(seconds)
	-- return string format hours minutes seconds
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
