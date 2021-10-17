function love.conf(t)
	t.title = "L\195\150VE " .. love._version .. " (" .. love._version_codename .. ")"
	t.gammacorrect = true
	t.modules.audio = false
	t.modules.sound = false
	t.modules.physics = false
	t.modules.joystick = false
	t.modules.video = false
	t.window.resizable = true
	t.window.highdpi = true

	if love._os == "iOS" then
		t.window.borderless = true
	elseif love._os == "Android" then
		t.window.fullscreen = true
	end
end