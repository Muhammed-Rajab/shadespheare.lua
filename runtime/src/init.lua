---@param shader_path string
---@param watch boolean?
---@param reload_delay number?
---@param config_path string
local function initialize(shader_path, watch, reload_delay, config_path)
	---logical window dimensions
	WIDTH = nil
	HEIGHT = nil
	SCALE = nil
	I_SCALE = nil

	local settings = require("runtime.settings")
	local utils = require("runtime.src.utils")

	local LiveShader = require("runtime.src.live-shader")
	local LiveConfig = require("runtime.src.live-config")

	---@type LiveShader
	local shader

	---@type LiveConfig
	local config

	---a few uniforms to set to shader that needs caching
	local resolution = { width = 0, height = 0 }
	local mouse = { x = 0, y = 0, click_x = 0, click_y = 0, dx = 0, dy = 0 }

	---WARN: setup ui config
	local ui_config = {}

	function love.load()
		---window setup
		WIDTH = love.graphics.getWidth()
		HEIGHT = love.graphics.getHeight()

		SCALE = settings.scale_factor
		I_SCALE = 1 / SCALE

		love.window.setMode(WIDTH * SCALE, HEIGHT * SCALE)

		---setup
		utils.loadDefaultFonts()

		---initialize width and height
		resolution.width, resolution.height = love.graphics.getDimensions()

		---initial mouse.x and mouse.y
		mouse.x = resolution.width / 2
		mouse.y = resolution.height / 2

		local function file_exists(path)
			local info = love.filesystem.getInfo(path)
			if info then
				return true
			end
			local f = io.open(path, "r")
			if f then
				f:close()
				return true
			end
			return false
		end

		---check for shader file existence
		if not file_exists(shader_path) then
			print(("[%s] ❌ shader file not found: %s"):format(os.date("%H:%M:%S"), shader_path))
			love.event.quit(1)
			return
		end

		---check for config file existence
		if not file_exists(config_path) then
			print(("[%s] ❌ config file not found: %s"):format(os.date("%H:%M:%S"), config_path))
			love.event.quit(1)
			return
		end

		---load the shader and call update initially
		shader = LiveShader.new(shader_path, reload_delay == nil and 0.25 or reload_delay)
		shader:set_watch(watch ~= false)
		shader:update(0)

		config = LiveConfig.new(config_path, reload_delay == nil and 0.25 or reload_delay)
		config:set_watch(watch ~= false)

		-- When config reloads, reload shader
		config:set_on_reload(function()
			shader:update(0) -- triggers immediate reload

			--- update ui configs
			if config:loaded() then
				ui_config = config._config.ui or {}
			end

			-- print the table
			utils.dump(config, 2)
		end)

		config:update(0)

		-- When shader reloads, reapply config
		shader:set_on_reload(function()
			if config:loaded() then
				config:apply(shader)
			end
		end)
	end

	---update resolution when window size changes
	function love.resize(w, h)
		resolution.width = w
		resolution.height = h
		print(w, h)
	end

	---update mouse position and deltas
	function love.mousemoved(x, y, dx, dy)
		mouse.x, mouse.y = x, y
		mouse.dx, mouse.dy = dx, dy
	end

	---update mouse press
	function love.mousepressed(x, y, button)
		if button == 1 then
			mouse.click_x, mouse.click_y = x, y
		end
	end

	function love.update(dt)
		shader:update(dt)
		config:update(dt)

		if shader:loaded() then
			--- NOTE: these methods return error, but most of them are "uniform not found" errors
			--- caused by shader code optimisation, when those uniforms are left unused.
			--- these can be ignored
			shader:set_uniform("iTime", love.timer.getTime())
			-- WARN: 2.0 is pixel ratio, which must be added later.
			shader:set_uniform("iResolution", { resolution.width, resolution.height, 2.0 })
			shader:set_uniform("iMouse", { mouse.x, mouse.y, mouse.click_x, mouse.click_y })
			shader:set_uniform("iDelta", { mouse.dx, mouse.dy })

			-- Apply config uniforms and textures
			if config:loaded() then
				config:apply(shader)
			end
		end
	end

	function love.draw()
		--- WARN: might mess up font rendering. use wisely.
		love.graphics.push()
		love.graphics.scale(SCALE, SCALE)
		love.graphics.setBackgroundColor(0.08, 0.08, 0.08, 1)

		---use the live shader if available and draw a rectangle filling the screen
		if shader:loaded() then
			shader:use()
			love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
			love.graphics.setShader()
		end

		love.graphics.pop()

		---render compilation errors to screen if there's any
		if shader:has_error() then
			shader:show_errors()
		---else render the fps
		else
			if ui_config.show_fps then
				love.graphics.setColor(0, 0, 0, 255)
				love.graphics.rectangle("fill", 7, 10, 157, 40)
				love.graphics.setColor(0, 255, 0, 255)
				love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
			end
		end
	end
end

return initialize
