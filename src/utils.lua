local utils = {}

local settings = require("settings")
local fontman = require("src.fontmanager")

local I_SCALE = 1 / settings.scale_factor

-- converts hsl to rgba
function utils.HSL(h, s, l, a)
	if s <= 0 then
		return l, l, l, a
	end
	h, s, l = h * 6, s, l
	local c = (1 - math.abs(2 * l - 1)) * s
	local x = (1 - math.abs(h % 2 - 1)) * c
	local m, r, g, b = (l - 0.5 * c), 0, 0, 0
	if h < 1 then
		r, g, b = c, x, 0
	elseif h < 2 then
		r, g, b = x, c, 0
	elseif h < 3 then
		r, g, b = 0, c, x
	elseif h < 4 then
		r, g, b = 0, x, c
	elseif h < 5 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end
	return r + m, g + m, b + m, a
end

-- returns scaled mouse positions based on scale factor
function utils.getMousePositionScaled()
	local x, y = love.mouse.getPosition()
	return x * I_SCALE, y * I_SCALE
end

function utils.loadDefaultFonts()
	fontman:load("jbmono-bolditalic", "assets/fonts/jbmono/JetBrainsMono-BoldItalic.ttf")
	fontman:load("jbmono-bold", "assets/fonts/jbmono/JetBrainsMono-Bold.ttf")
	fontman:load("jbmono-extrabolditalic", "assets/fonts/jbmono/JetBrainsMono-ExtraBoldItalic.ttf")
	fontman:load("jbmono-extrabold", "assets/fonts/jbmono/JetBrainsMono-ExtraBold.ttf")
	fontman:load("jbmono-extralightitalic", "assets/fonts/jbmono/JetBrainsMono-ExtraLightItalic.ttf")
	fontman:load("jbmono-extralight", "assets/fonts/jbmono/JetBrainsMono-ExtraLight.ttf")
	fontman:load("jbmono-italic", "assets/fonts/jbmono/JetBrainsMono-Italic.ttf")
	fontman:load("jbmono-lightitalic", "assets/fonts/jbmono/JetBrainsMono-LightItalic.ttf")
	fontman:load("jbmono-light", "assets/fonts/jbmono/JetBrainsMono-Light.ttf")
	fontman:load("jbmono-mediumitalic", "assets/fonts/jbmono/JetBrainsMono-MediumItalic.ttf")
	fontman:load("jbmono-medium", "assets/fonts/jbmono/JetBrainsMono-Medium.ttf")
	fontman:load("jbmono-regular", "assets/fonts/jbmono/JetBrainsMono-Regular.ttf")
	fontman:load("jbmono-semibolditalic", "assets/fonts/jbmono/JetBrainsMono-SemiBoldItalic.ttf")
	fontman:load("jbmono-semibold", "assets/fonts/jbmono/JetBrainsMono-SemiBold.ttf")
	fontman:load("jbmono-thinitalic", "assets/fonts/jbmono/JetBrainsMono-ThinItalic.ttf")
	fontman:load("jbmono-thin", "assets/fonts/jbmono/JetBrainsMono-Thin.ttf")

	fontman:set("jbmono-regular", 32)
end

return utils
