---safely reads a file and returns. returns `nil` if there's any error.
---@param path string path to file to read
---@return any
local function safe_read(path)
	-- Try LÖVE’s virtual FS first
	local ok, data = pcall(love.filesystem.read, path)
	if ok and data then
		return data
	end

	-- Normalize "./" or similar prefixes
	local real_path = path:gsub("^%./", "")

	-- Try reading from the actual OS filesystem
	local f = io.open(real_path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

---get modification time of a file, works for both love fs and OS paths
---@param path string
---@return number|nil
local function get_mod_time(path)
	-- Try LOVE’s virtual filesystem
	local info = love.filesystem.getInfo(path)
	if info and info.modtime then
		return info.modtime
	end

	-- Try OS filesystem
	local f = io.open(path, "r")
	if f then
		f:close()

		-- Use system stat command (no lfs required)
		local ok, modtime = pcall(function()
			local quoted = string.format("%q", path) -- safely quoted for shell
			local pipe = io.popen("stat -c %Y " .. quoted .. " 2>/dev/null")
			if not pipe then
				return nil
			end
			local out = pipe:read("*a")
			pipe:close()
			return tonumber(out)
		end)
		if ok and modtime then
			return modtime
		end
	end

	return nil
end

---format compile errors
---@param text    string input error string
---@param prefix  string the prefix to add
---@return string
local function format_compile_errors(text, prefix)
	local result = {}

	-- Split by newline and process each line
	for line in text:gmatch("([^\n]*)\n?") do
		if line ~= "" then
			table.insert(result, prefix .. line .. "\n")
		end
	end

	-- Concatenate back with newlines
	return table.concat(result)
end

---only applies color if the terminal supports ANSI colors
---@param text string
---@param code number
---@return string
local function colorize(text, code)
	if os.getenv("TERM") then
		return "\27[" .. code .. "m" .. text .. "\27[0m"
	else
		return text
	end
end

---Represents a shader that supports live reloading during runtime.
---
---The **LiveShader** class monitors a shader file for changes and automatically
---reloads it after a short delay when modifications are detected. Very useful
---for rapid shader iteration and debugging without restarting the application.
---@class LiveShader
---@field _shader           any     LÖVE2D shader
---@field _shader_path      string  path to the shader
---@field _last_modified    number  timestamp of when the shader was last modified
---@field _reload_delay     number  delay before recompiling the shader
---@field _pending_reload   boolean whether a reload is pending
---@field _reload_timer     number  keeps track of time before reloading
---@field _compile_error    string  errors that occured while compilation
---@field _watch_enabled    boolean  whether watching is enabled
local LiveShader = {}

LiveShader.__index = LiveShader

---create a new live shader from `path` and reload only `reload_delay` seconds after change in shader.
---@param path          string
---@param reload_delay? number
---@return LiveShader
function LiveShader.new(path, reload_delay)
	local obj = {
		_shader = nil,
		_shader_path = path,

		_last_modified = 0,
		_pending_reload = false,

		_reload_timer = 0,
		_reload_delay = reload_delay or 0.25,

		_compile_error = nil,
		_watch_enabled = true,
	}

	setmetatable(obj, LiveShader)

	return obj
end

---check for changes in the shader file and recompile if there's any.
---@param dt number
function LiveShader:update(dt)
	if not self._watch_enabled then
		return
	end

	local modtime = get_mod_time(self._shader_path)
	if not modtime then
		return
	end

	if modtime > self._last_modified then
		self._last_modified = modtime -- stops this block from executing till next modification
		self._pending_reload = true
		self._reload_timer = 0
	end

	if not self._pending_reload then
		return
	end

	self._reload_timer = self._reload_timer + dt

	if self._reload_timer < self._reload_delay then
		return
	end

	local code = safe_read(self._shader_path)

	self._pending_reload = false
	if not code then
		return
	end

	---@type boolean, string | love.Shader
	local ok, s = pcall(love.graphics.newShader, code)

	local _time_prefix = "[" .. os.date("%H:%M:%S") .. "] "

	if ok then
		self._shader = s
		print(_time_prefix .. "✅ shader reloaded: " .. self._shader_path)
		print((" "):rep(#_time_prefix) .. colorize("no compilation errors 👍", 32))
		self._compile_error = nil

	--- NOTE: this string is added to avoid warnings from the LSP. this makes sure that 's' is an error string
	elseif type(s) == "string" then
		self._shader = nil

		local _err_msg_header = _time_prefix .. "❌ shader compilation failed: " .. self._shader_path .. "\n"

		local _err_msg_cli = _err_msg_header
			.. (" "):rep(#_time_prefix)
			.. colorize("compile error: \n" .. format_compile_errors(s, (" "):rep(#_time_prefix)), 31)
		io.write(_err_msg_cli)

		local _err_msg_screen = _err_msg_header .. s

		self._compile_error = _err_msg_screen
	end
end

---checks whether the shader has a uniform
---@param name string
---@return boolean
function LiveShader:has_uniform(name)
	if self._shader then
		return self._shader:hasUniform(name)
	end
	return false
end

---set a value for a given uniform in the shader
---@param name  string
---@param value any
function LiveShader:set_uniform(name, value)
	if not self._shader then
		-- Optional: silent fail or warn once
		return false, "no shader loaded"
	end

	if not self._shader:hasUniform(name) then
		-- Optional: print warning or skip silently
		return false, ("uniform '%s' does not exist"):format(name)
	end

	local ok, err = pcall(self._shader.send, self._shader, name, value)
	if not ok then
		return false, err
	end

	return true
end

---use the shader for rendering
function LiveShader:use()
	if self._shader then
		love.graphics.setShader(self._shader)
	else
		love.graphics.setShader()
	end
end

---renders errors to the screen
function LiveShader:show_errors()
	love.graphics.push()
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.print(self._compile_error, 10, 10)
	love.graphics.pop()
end

---checks if there's any error
---@return boolean
function LiveShader:has_error()
	return self._compile_error ~= nil
end

---checks if the shader is loaded
---@return boolean
function LiveShader:loaded()
	return self._shader ~= nil
end

---set the live shader to watch for changes
---@param enabled boolean
function LiveShader:set_watch(enabled)
	self._watch_enabled = enabled
	local state = enabled and "enabled ✅" or "disabled ⛔"
	print(string.format("[%s] live shader watch %s", os.date("%H:%M:%S"), state))
end

---returns whether the live shader is watching
---@return boolean
function LiveShader:is_watching()
	return self._watch_enabled
end

return LiveShader
