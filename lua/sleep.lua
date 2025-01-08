-- TODO:
	-- refactor: remove redundant file i/o

local mp = require 'mp'

local config_file = "/storage/emulated/0/Android/media/is.xyz.mpv/scripts/sleep.json"

local config = {
	file = "/storage/emulated/0/Android/media/is.xyz.mpv/scripts/sleep.json",
	logging = true,
}

local time = {
	minutes = 0,
	active = false,
	format = "%02d:%02d:%02d", -- (HH:MM:SS)
	remaining = nil,
	display_time = true,

	prev_state = {
		timestamp = "",
		remaining = nil,
		was_active = false,
		last_update = "", -- ISO 8601
		file_name = nil,
	},
}

local gesture_state = {
	triggers = {
		count = 0,
		last_action_time = 0,
	},

	actions = {
		pending = false,
		confirm_timeout = 1, -- seconds
		timer = nil,
		callback = nil,
	}
}

local ActionType = {
    SET_TIMER = 1,
    REMOVE_TIMER = 2,
    REINSTATE = 3,
    RESET = 4
}


local function log(msg_str)
	if config.logging then
		mp.msg.info("[sleep.lua]: " .. msg_str)
	end
end

---------------------------
--      JSON PARSER      --
---------------------------

local function read_jsonkey_value(file_str, json_obj, obj_key)
	local b_obj = string.find(file_str, json_obj)
	local e_obj = string.find(file_str, "}", b_obj)

	if not (b_obj and e_obj) then
		log(json_obj .. "does not exist or " .. config_file "is formatted incorrectly")
		return nil
	end

	local substr = string.sub(file_str, b_obj, e_obj)
	local key_val = string.match(substr, obj_key)

	if not key_val then
		log("could not extract \"" .. string.match(obj_key, "\"([^\"]+)\"") .. "\"" .. " from " .. config_file)
		return nil
	end

	return key_val
end

local function read_config()
	log("opening" .. config_file .. "...")

	local openf, err = io.open(config_file, "r")
	if openf == nil then
		log("failed to open" .. config_file .. "! " .. err)
		return
	end

	local file_str = openf:read("*all")
	if file_str == nil or file_str == "" then
		log("Failed to read config_file into string or config_file is empty" .. config_file .. "!")
		openf:close()
		return
	end

	log("config:\n" .. file_str)
	log("closing" .. config_file .. ".")
	io.close(openf)

	local default_time = read_jsonkey_value(file_str, "\"config\"", "\"default_time\"%s*:%s*([%d%.]+)")
	local display_time = read_jsonkey_value(file_str, "\"config\"", "\"display_time\"%s*:%s*(%a+)")
	local prevstate_tstamp = read_jsonkey_value(file_str, "\"previous_state\"", "\"time_stamp\"%s*:%s*\"(.-)\"")
	local prevstate_lastup = read_jsonkey_value(file_str, "\"previous_state\"", "\"last_updated\"%s*:%s*\"(.-)\"")
	local prevstate_active = read_jsonkey_value(file_str, "\"previous_state\"", "\"was_active\"%s*:%s*(%a+)")

	log("default_time " .. default_time)
	time.minutes = default_time
	time.display_time = display_time
	time.prev_state.timestamp = prevstate_tstamp
	time.prev_state.last_update = prevstate_lastup
	time.prev_state.was_active = prevstate_active

	log("time.minutes " .. time.minutes)
	log("time.display_time " .. (time.display_time or "nil"))
	log("time.prev_state.timestamp " .. (time.prev_state.timestamp or "nil"))
	log("time.prev_state.last_update " .. (time.prev_state.last_update or "nil"))
	log("time.prev_state.was_active " .. (time.prev_state.was_active or "nil"))
end

---------------------------
--     Sleep / Timer     --
---------------------------


-- TODO:
local function reinstate_tstamp(t)
	-- according to a gesture, this should be called, and seek to @param in file
	-- we also need to verify that we're in the correct file.
end

local function export_time()
	log("exporting date and timestamp")
	log("opening " .. config_file .. "...")

	local openf, err = io.open(config_file, "r")
	if openf == nil then
		log("failed to open " .. config_file .. "!" .. err)
		return
	end

	local fstr = {}
	for line in openf:lines() do
		table.insert(fstr, line)
	end
	log("closing " .. config_file .. "...")
	io.close(openf)

	local in_prevblock = false
	for i, line in ipairs(fstr) do
		if line:find('"previous_state"') then
			log("in previous_state block")
			log("" .. tostring(line))
			in_prevblock = true

		elseif in_prevblock then
			if line:find('"time_stamp"') then
				log("found time_stamp:")
				log(tostring(line))
				fstr[i] = '		"time_stamp": ' .. tostring(mp.get_property_number("time-pos")) .. '",'
			elseif line:find('"last_updated"') then
				log("found last_updated:")
				log(tostring(line))
				fstr[i] = '		"last_updated": ' .. os.date("!%Y-%m-%dT%H:%M:%SZ") .. '",'
			elseif line:find('"was_active"') then
				log("found was_active:")
				log(tostring(line))
				fstr[i] = '		"was_active": ' .. tostring(time.prev_state.was_active)
			end

		elseif line:find('}') then
			in_prevblock = false
			log("left previous_state block:")
		end
	end

	log("updated config file string:\n")
	for i, line in ipairs(fstr) do
		log("line " .. i .. ": " .. tostring(line))
	end

	openf, err = io.open(config_file, "w")
	if openf == nil then
		log("failed to open" .. config_file .. "!" .. err)
		return
	end

	log("writing to file")
	for _, line in ipairs(fstr) do
		openf:write(line .. "\n")
	end
	log("closing" .. config_file .. "...")
	io.close(openf)
end

local function set_timer()
	time.active = true
	time.remaining = time.minutes * 60

	local update_timer
	update_timer = mp.add_periodic_timer(1, function()
		if not time.active then
			update_timer:kill()
			return
		end
		time.remaining = time.remaining - 1

		if time.display_time then
			local hrs = math.floor(time.remaining / 3600)
			local min = math.floor((time.remaining % 3600) / 60)
			local sec = time.remaining % 60
			local rem = string.format(time.format, hrs, min, sec)

			mp.osd_message("Sleep Timer: " .. rem, 3)
			log("time remaining: " .. rem)
		end

		if time.remaining <= 0 then
			log("time expired. Killing timer")
			update_timer:kill()
			time.active = false
			time.remaining = nil

			export_time()
			mp.osd_message("Sleep timer expired - pausing playback", 3)
			log("pausing playback.")
			mp.set_property("pause", "yes")
		end
	end)
end

local function remove_timer()
	time.active = false
	time.remaining = 0
end

---------------------------
--    Action / Gestures  --
---------------------------

local function cancel_pending_action()
    if gesture_state.actions.timer then
        gesture_state.actions.timer:kill()
        gesture_state.actions.timer = nil
        gesture_state.actions.callback = nil
        gesture_state.actions.pending = false
        mp.osd_message("Action cancelled")
    end
end

local function confirm_action(action_t)
	cancel_pending_action()
	gesture_state.actions.pending = true

	local messages = {
		[ActionType.SET_TIMER] = "Timer will be set for " ..
			time.minutes .. " minutes in " ..
			gesture_state.actions.confirm_timeout ..
			" seconds.\nGesture again to cancel",

		[ActionType.REMOVE_TIMER] = "Timer will be removed in " ..
			gesture_state.actions.confirm_timeout ..
			" seconds.\nGesture again to cancel",

		[ActionType.REINSTATE] = "Timer will be reinstated in " ..
			gesture_state.actions.confirm_timeout ..
			" seconds.\nGesture again to cancel",

		[ActionType.RESET] = "Timer will be reset in " ..
			gesture_state.actions.confirm_timeout ..
			" seconds.\nGesture again to cancel"
	}

	mp.osd_message(messages[action_t], gesture_state.actions.confirm_timeout)

	gesture_state.actions.timer = mp.add_timeout(gesture_state.actions.confirm_timeout,
	function()
		if gesture_state.actions.callback then
			gesture_state.actions.callback()
		end

		gesture_state.actions.timer = nil
		gesture_state.actions.callback = nil
		gesture_state.actions.pending = false
	end)

	return true
end

-- user calls this
local function handle_gesture()
	mp.osd_message("Gesture Received. (" .. gesture_state.triggers.count .. ")", 3)
	gesture_state.triggers.count = gesture_state.triggers.count + 1

	local current_time = mp.get_time()
	gesture_state.triggers.last_action_time = current_time

	if gesture_state.actions.pending then
		cancel_pending_action()
		return
	end

	if gesture_state.triggers.count == ActionType.SET_TIMER then
		local confirmed = confirm_action(ActionType.SET_TIMER)
		if confirmed and not time.active then
			gesture_state.actions.callback = function()
				log("sleep action confirmed. Setting timer for " .. time.minutes .. " minutes")
				set_timer()
				mp.osd_message("Timer has been set!")
			end
		else
			-- TODO:
			mp.osd_message("Timer already exists. [duration remaining]\nGesture again to reset the timer")
			log("timer already exists.")
		end
	elseif gesture_state.triggers.count == ActionType.REMOVE_TIMER then
		local confirmed = confirm_action(ActionType.REMOVE_TIMER)
		if confirmed then
			gesture_state.actions.callback = function()
				remove_timer()
				mp.osd_message("Timer has been removed.")
			end
		end
	elseif gesture_state.triggers.count == ActionType.REINSTATE then
		local confirmed = confirm_action(ActionType.REINSTATE)
		if confirmed then
			gesture_state.actions.callback = function()
				-- TODO:
				-- reinstate_timer(t)
				mp.osd_message("Reinstating [time stamp] from [FILE].")
			end
		end
	else
		gesture_state.triggers.count = 0
	end
end

-- called immediately upon opening a media config_file
local function main()
	log("script has been loaded")
	read_config()
	log("script has initialized defaults")
end

mp.add_key_binding(nil, "sleep", handle_gesture) -- the user invokes this by gesturing (user-set in input.conf)
main() -- this is run upon opening a media config_file
