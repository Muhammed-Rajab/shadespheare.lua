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

---Represents a config that supports live reloading during runtime.
---
---The **LiveConfig** class monitors a config file for changes and automatically
---reloads it after a short delay when modifications are detected. Very useful
---for rapid shader iteration and debugging without restarting the application.
---@class LiveConfig
---@field _config           any       the config
---@field _config_path      string    path to the config
---@field _last_modified    number    timestamp of when the config was last modified
---@field _reload_delay     number    delay before reloading the config
---@field _pending_reload   boolean   whether a reload is pending
---@field _reload_timer     number    keeps track of time before reloading
---@field _watch_enabled    boolean   whether watching is enabled
---@field _on_reload        nil | fun(): nil  call back function when reloaded
---@field _cached_textures  table<string, love.Image> cached images for textures
local LiveConfig = {}

LiveConfig.__index = LiveConfig

---create a new live config from `path` and reload only `reload_delay` seconds after change in config.
---@param path          string
---@param reload_delay? number
---@return LiveConfig
function LiveConfig.new(path, reload_delay)
	local obj = {
		_config = nil,
		_config_path = path,

		_last_modified = 0,
		_pending_reload = false,

		_reload_timer = 0,
		_reload_delay = reload_delay or 0.25,

		_watch_enabled = true,

		_on_reload = nil,
	}

	setmetatable(obj, LiveConfig)

	return obj
end

---check for changes in the config file and updates config table
---@param dt number
function LiveConfig:update(dt)
	local modtime = get_mod_time(self._config_path)
	if not modtime then
		return
	end

	-- First-time load
	if self._last_modified == 0 then
		self._last_modified = modtime
		self:_reload()
		return
	end

	if not self._watch_enabled then
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

	self:_reload()
end

---reload the shader based on current state
function LiveConfig:_reload()
	self._pending_reload = false

	---WARN: we'll be using dofile
	-- -- Remove from Lua module cache so require() loads fresh file
	-- local modName = self._config_path:gsub("/", "."):gsub("%.lua$", "")
	-- package.loaded[modName] = nil

	local ok, cfg = pcall(dofile, self._config_path)

	local _time_prefix = "[" .. os.date("%H:%M:%S") .. "] "

	if ok and type(cfg) == "table" then
		self._config = cfg
		print(_time_prefix .. "✅ config reloaded: " .. self._config_path)
		print((" "):rep(#_time_prefix) .. colorize("no errors 👍", 32))
	else
		self._config = nil

		local _err_msg_header = _time_prefix .. "❌ config reload failed: " .. self._config_path .. "\n"

		local _err_msg_cli = _err_msg_header
			.. (" "):rep(#_time_prefix)
			.. colorize("config error: \n" .. tostring(cfg), 31)

		io.write(_err_msg_cli)
	end

	---TODO: call the callback after reload
	if self._on_reload then
		self._on_reload()
	end
end

---set the live config to watch for changes
---@param enabled boolean
function LiveConfig:set_watch(enabled)
	self._watch_enabled = enabled
	local emoji = enabled and "✅" or "⛔"
	local state = enabled and "enabled" or "disabled"
	print(string.format("[%s] %s live config watch %s", os.date("%H:%M:%S"), emoji, state))
end

---returns whether the live config is watching
---@return boolean
function LiveConfig:is_watching()
	return self._watch_enabled
end

---returns whether the config is loaded
---@return boolean
function LiveConfig:loaded()
	return self._config ~= nil
end

---@param shader LiveShader
function LiveConfig:apply(shader)
	if not self._config or not shader:loaded() then
		return
	end

	local uniforms = self._config.uniforms
	local textures = self._config.textures

	-- Cache textures in the LiveConfig instance
	if not self._cached_textures then
		self._cached_textures = {}
	end

	if textures then
		for k, v in pairs(textures) do
			-- Only load if not already cached
			if not self._cached_textures[v.path] then
				local ok, img = pcall(love.graphics.newImage, v.path)
				if ok then
					self._cached_textures[v.path] = img
				else
					print(("❌ failed to load texture %s: %s"):format(v.path, img))
				end
			end

			-- Apply cached image
			if self._cached_textures[v.path] then
				shader:set_uniform(k, self._cached_textures[v.path])
			end
		end
	end

	if uniforms then
		for k, v in pairs(uniforms) do
			shader:set_uniform(k, v)
		end
	end
end

---@param fn fun(): nil
function LiveConfig:set_on_reload(fn)
	self._on_reload = fn
end

return LiveConfig
