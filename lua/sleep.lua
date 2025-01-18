local mp = require 'mp'
--local utils = require 'mp.utils'

local config = {
	file = "/storage/emulated/0/Android/media/is.xyz.mpv/scripts/sleep.json",
	logging = true,
}

local time = {
	minutes = 0,
	format = "%02d:%02d:%02d",
	remaining = 0,
	display_time = true,
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
		log(json_obj .. "does not exist or " .. config.file "is formatted incorrectly")
		return nil
	end

	local substr = string.sub(file_str, b_obj, e_obj)
	local key_val = string.match(substr, obj_key)

	if not key_val then
		log("could not extract \"" .. string.match(obj_key, "\"([^\"]+)\"") .. "\"" .. " from " .. config.file)
		return nil
	end

	return key_val
end

local function read_config()
	log("opening" .. config.file .. "...")

	local openf, err = io.open(config.file, "r")
	if openf == nil then
		log("failed to open" .. config.file .. "! " .. err)
		return
	end

	local file_str = openf:read("*all")
	if file_str == nil or file_str == "" then
		log("Failed to read config.file into string or config.file is empty" .. config.file .. "!")
		openf:close()
		return
	end

	log("config:\n" .. file_str)
	log("closing" .. config.file .. ".")
	io.close(openf)

	local default_time = read_jsonkey_value(file_str, "\"config\"", "\"default_time\"%s*:%s*([%d%.]+)")
	local display_time = read_jsonkey_value(file_str, "\"config\"", "\"display_time\"%s*:%s*(%a+)")

	log("default_time " .. default_time)
	time.minutes = default_time
	time.display_time = display_time
	log("time.minutes " .. time.minutes)
	log("time.display_time " .. (time.display_time or "nil"))
end

---------------------------
--     Sleep / Timer     --
---------------------------

local function set_timer()
	time.active = true
	time.remaining = time.minutes * 60

	local update_timer
	update_timer = mp.add_periodic_timer(1, function()
		if not time.active then
			update_timer:kill()
			return
		end

		if mp.get_property("pause") == "no" then
			time.remaining = time.remaining - 1
		end

		if time.display_time then
			local hrs = math.floor(time.remaining / 3600)
			local min = math.floor((time.remaining % 3600) / 60)
			local sec = time.remaining % 60
			local rem = string.format(time.format, hrs, min, sec)

			log("time remaining: " .. rem)
			if not gesture_state.actions.pending then
				mp.osd_message("Sleep Timer: " .. rem, 3)
			end
		end

		if time.remaining <= 0 then
			log("time expired. Killing timer")
			update_timer:kill()
			time.active = false
			time.remaining = nil

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
        mp.osd_message("Action cancelled", 3)
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
	local current_time = mp.get_time()
	gesture_state.triggers.last_action_time = current_time
	gesture_state.triggers.count = gesture_state.triggers.count + 1

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
			mp.osd_message("Timer already exists", 4)
			log("timer already exists.")
			gesture_state.actions.pending = false
		end
	elseif gesture_state.triggers.count == ActionType.REMOVE_TIMER then
		local confirmed = confirm_action(ActionType.REMOVE_TIMER)
		if confirmed then
			gesture_state.actions.callback = function()
				remove_timer()
				mp.osd_message("Timer has been removed.")
			end
		end
	else
		gesture_state.triggers.count = 0
	end
end

-- called immediately upon opening a media config.file
local function main()
	log("script has been loaded")
	read_config()
	log("script has initialized defaults")
end

mp.add_key_binding(nil, "sleep", handle_gesture) -- the user invokes this by gesturing (user-set in input.conf)
main() -- this is run upon opening a media file
