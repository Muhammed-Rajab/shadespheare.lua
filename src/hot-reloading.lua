---@class LiveShader
---@field shader          any
---@field shader_path     string
---@field last_modified   number
---@field reload_delay    number
---@field pending_reload  boolean
---@field reload_timer    number
local LiveShader = {}

LiveShader.__index = LiveShader

---@param path string
---@param reload_delay? number
---@return LiveShader
function LiveShader.new(path, reload_delay)
	local obj = {
		shader = nil,
		shader_path = path,

		last_modified = 0,
		pending_reload = false,

		reload_timer = 0,
		reload_delay = reload_delay or 0.25,
	}

	setmetatable(obj, LiveShader)
	return obj
end

return LiveShader
