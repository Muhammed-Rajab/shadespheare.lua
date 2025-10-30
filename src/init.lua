---@param shader_path string
---@param watch boolean?
local function Init(shader_path, watch)
	---logical window dimensions
	WIDTH = nil
	HEIGHT = nil
	SCALE = nil
	I_SCALE = nil

	local settings = require("settings")
	local utils = require("src.utils")

	local LiveShader = require("src.live-shader")

	---@type LiveShader
	local shader

	---a few uniforms to set to shader that needs caching
	local resolution = { width = 0, height = 0 }
	local mouse = { x = 0, y = 0, click_x = 0, click_y = 0, dx = 0, dy = 0 }

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

		---load the shader and call update initially
		shader = LiveShader.new(shader_path, 0.25)
		shader:update(0)

		---set watch state (default: true)
		shader:set_watch(watch ~= false)
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

		if not shader:loaded() then
			return
		end

		--- NOTE: these methods return error, but most of them are "uniform not found" errors
		--- caused by shader code optimisation, when those uniforms are left unused.
		--- these can be ignored
		shader:set_uniform("iTime", love.timer.getTime())
		shader:set_uniform("iResolution", { resolution.width, resolution.height })
		shader:set_uniform("iMouse", { mouse.x, mouse.y, mouse.click_x, mouse.click_y })
		shader:set_uniform("iDelta", { mouse.dx, mouse.dy })
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
			love.graphics.setColor(0, 0, 0, 255)
			love.graphics.rectangle("fill", 7, 10, 157, 40)
			love.graphics.setColor(0, 255, 0, 255)
			love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
		end
	end
end

return Init
