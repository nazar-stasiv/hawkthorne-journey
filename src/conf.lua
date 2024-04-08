function love.conf(t)
  t.title             = "Journey to the Center of Hawkthorne v0.0.0"
  t.url               = "http://projecthawkthorne.com"
  t.author            = "https://github.com/hawkthorne?tab=members"
  t.version           = "11.5"
  t.identity          = "hawkthorne"
  t.window.width      = 640
  t.window.height     = 480
  t.window.fullscreentype = "exclusive"
  t.window.fullscreen = true
  t.console           = false
  t.modules.physics   = false
  t.modules.joystick  = true
  t.release           = false
  t.gammacorrect      = true
  t.window.vsync      = false
end
