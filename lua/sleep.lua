local mp = require 'mp'

local config_file = "/storage/emulated/0/Android/media/is.xyz.mpv/scripts/sleep.json"

local time = {
	minutes = 0.1,
	active = false,
	format = "%02d:%02d:%02d", -- (HH:MM:SS)
	remaining = nil,
	display_time = true,

	prev_state = {
		timestamp = "",
		remaining = nil,
		was_active = false,
		last_update = "", -- ISO 8601
		-- file_name = ""
	},
}

local gesture_state = {
	triggers = {
		count = 0,
		last_action_time = 0,
	},
	actions = {
		pending = false,
		confirm_timeout = 5, -- seconds
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
		mp.msg.error("[sleep.lua]" .. json_obj .. "does not exist or " .. config_file "is formatted incorrectly")
		return nil
	end

	local substr = string.sub(file_str, b_obj, e_obj)
	local key_val = string.match(substr, obj_key)

	if not key_val then
		mp.msg.error("[sleep.lua]: could not extract \"" .. string.match(obj_key, "\"([^\"]+)\"") .. "\"" .. " from " .. config_file)
		return nil
	end

	return key_val
end

local function read_config()
	mp.msg.info("[sleep.lua]: opening", config_file .. "...")

	local openf = io.input(config_file)
	if openf == nil then
		mp.msg.error("[sleep.lua]: failed to open", config_file .. "!")
		-- TODO: we should make sure it exists, otherwise should create it
	end


	local file_str = openf:read("*all")
	if file_str == nil or file_str == "" then
		mp.msg.error("[sleep.lua]: Failed to read config_file into string or config_file is empty", config_file .. "!")
	end

	mp.msg.info("[sleep.lua]: closing", config_file .. ".")
	io.close(openf)

	-- TODO: put in table, then index with @param and return it
	-- TODO: add display_time boolean
	local default_time = read_jsonkey_value(file_str, "\"config\"", "\"default_time\"%s*:%s*(%d+)")
	local prevstate_tstamp = read_jsonkey_value(file_str, "\"previous_state\"", "\"timestamp\"%s*:%s*\"(.-)\"")
	local prevstate_lastup = read_jsonkey_value(file_str, "\"previous_state\"", "\"last_updated\"%s*:%s*\"(.-)\"")
	local prevstate_active = read_jsonkey_value(file_str, "\"previous_state\"", "\"was_active\"%s*:%s*([a-zA-Z]+)")

	mp.msg.info("default_time: " .. default_time or "[sleep.lua]: could not extract default_time from")
	mp.msg.info("prevstate_tstamp: " .. prevstate_tstamp)
	mp.msg.info("prevstate_lastup: " .. prevstate_lastup)
	mp.msg.info("prevstate_active: " .. prevstate_active)
end

---------------------------
--     Sleep / Timer     --
---------------------------

local function reinstate_tstamp(time)
	-- according to a gesture, this should be called, and seek to @param in file
	-- we also need to verify that we're in the correct file.
end

local function export_time()
	mp.msg.info("[sleep.lua]: exporting date and timestamp")
	time.prev_state.timestamp = mp.get_property_number("time-pos")
	time.prev_state.was_active = false
	time.prev_state.last_update = os.date("!%Y-%m-%dT%H:%M:%SZ")  -- ISO 8601 UTC

	-- TODO: EXPORT TO sleep.json
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
			mp.msg.info("[sleep.lua]: time remaining: " .. rem)
		end

		if time.remaining <= 0 then
			mp.msg.info("[sleep.lua]: time expired. Killing timer")
			update_timer:kill()
			time.active = false
			time.remaining = nil

			export_time()
			mp.osd_message("Sleep timer expired - pausing playback", 3)
			mp.msg.info("[sleep.lua]: pausing playback.")
			mp.set_property("pause", "yes")
		end
	end)
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
		[ActionType.SET_TIMER] = "Timer will be set for " .. time.minutes .. " minutes in " .. gesture_state.actions.confirm_timeout .. " seconds.\nGesture again to cancel",
		[ActionType.REMOVE_TIMER] = "Timer will be removed in " .. gesture_state.actions.confirm_timeout .. " seconds.\nGesture again to cancel",
		[ActionType.REINSTATE] = "Timer will be reinstated in " .. gesture_state.actions.confirm_timeout .. " seconds.\nGesture again to cancel",
		[ActionType.RESET] = "Timer will be reset in " .. gesture_state.actions.confirm_timeout .. " seconds.\nGesture again to cancel"
	}

	mp.osd_message(messages[action_t], gesture_state.actions.confirm_timeout)

	gesture_state.actions.timer = mp.add_timeout(gesture_state.actions.confirm_timeout, function()
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
				mp.msg.info("[sleep.lua]: sleep action confirmed. Setting timer for " .. time.minutes .. " minutes")
				set_timer()
				mp.osd_message("Timer has been set!")
			end
		else
			-- TODO:
			mp.osd_message("Timer already exists. [duration remaining]\nGesture again to reset the timer")
			mp.msg.info("[sleep.lua]: timer already exists.")
		end
	elseif gesture_state.triggers.count == ActionType.REMOVE_TIMER then
		local confirmed = confirm_action(ActionType.REMOVE_TIMER)
		if confirmed then
			gesture_state.actions.callback = function()
				--remove_timer()
				mp.osd_message("Timer has been removed.")
			end
		end
	elseif gesture_state.triggers.count == ActionType.REINSTATE then
		local confirmed = confirm_action(ActionType.REINSTATE)
		if confirmed then
			gesture_state.actions.callback = function()
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
	mp.msg.info("[sleep.lua]: script has been loaded")
	mp.osd_message("script has been loaded")

	--read_config()
end

mp.add_key_binding(nil, "sleep", handle_gesture) -- the user invokes this by gesturing (user-set in input.conf)
main() -- this is run upon opening a media config_file
