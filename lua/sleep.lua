local timer = {
	minutes = 25,
	active = false,
	format = "%02d:%02d:%02d", -- (HH:MM:SS)
	remaining = nil,
	prev_state = {
		timestamp = nil,
		was_active = false,
	},
	config_file = "sleep.json"
}

local gesture_state = {
	last_trigger_sec = 0,
	trigger_count = 0,
	latency = 3, -- seconds
}

local function reinstate_tstamp()
	-- call read_config and grab the exported time stamp, then seek to that position in the file
end

local function read_config()
	-- if failed, then return mock/default settings defined here
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

-- called immediately upon opening a media file
function main()
	    mp.osd_message("Sleep timer script initialized!", 3)
end

mp.add_key_binding(nil, "sleep", handle_gesture) -- the user invokes this by gesturing (user-set in input.conf)
main() -- this is run upon opening a media file
