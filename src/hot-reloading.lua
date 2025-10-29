---@param path string
---@return any
local function safe_read(path)
	local ok, data = pcall(love.filesystem.read, path)
	if ok and data then
		return data
	else
		return nil
	end
end

---@class LiveShader
---@field _shader          any
---@field _shader_path     string
---@field _last_modified   number
---@field _reload_delay    number
---@field _pending_reload  boolean
---@field _reload_timer    number
local LiveShader = {}

LiveShader.__index = LiveShader

---@param path string
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
	}

	setmetatable(obj, LiveShader)
	return obj
end

---@param dt number
function LiveShader:update(dt)
	local info = love.filesystem.getInfo(self._shader_path)
	if not info then
		return
	end

	if info.modtime > self._last_modified then
		self._last_modified = info.modtime -- stops this block from executing till next modification
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

	local ok, s = pcall(love.graphics.newShader, code)

	-- compilation goes well
	if ok then
		self._shader = s
		print("shader reloaded at", os.date("%H:%M:%S"))
		--compilation goes wrong
	else
		-- set the current shader nil
		-- TODO: show error on screen?
		self._shader = nil
		print("shader compile error:\n", s)
	end
end

---@param name string
function LiveShader:has_uniform(name)
	if self._shader then
		return self._shader:hasUniform(name)
	end
	return false
end

---@param name string
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

function LiveShader:use()
	if self._shader then
		love.graphics.setShader(self._shader)
	else
		love.graphics.setShader()
	end
end

---@return boolean
function LiveShader:loaded()
	return self._shader ~= nil
end

return LiveShader
