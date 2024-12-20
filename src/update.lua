local app = require 'app'

local middle = require 'middleclass'
local sound = require 'TEsound'
local Gamestate = require 'vendor/gamestate'
local window = require 'window'

local screen = Gamestate.new()

function screen:init()
end

function screen:enter()
  self.message = ""
  self.progress = 100
  self.time = 0
  self.logo = love.graphics.newImage('images/menu/splash.png')
  self.bg = sound.playMusic("ending")
end

function screen:update(dt)
  self.time = self.time + dt

  if self.time < 2.5 then
    return
  end

  Gamestate.switch('welcome')
end

function screen:leave()
  self.logo = nil
  love.graphics.setColor(255, 255, 255, 255)
end

function screen:keypressed(button)
end

function screen:draw()
  love.graphics.setColor(255, 255, 255, math.min(255, self.time * 100))
  love.graphics.draw(self.logo, window.width / 2 - self.logo:getWidth() / 2,
                     window.height / 2 - self.logo:getHeight() / 2)

  if self.progress > 0 then
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("line", 40, window.height - 75, window.width - 80, 10)
    love.graphics.rectangle("fill", 40, window.height - 75, 
                            (window.width - 80) * self.progress / 100, 10)
    love.graphics.printf(self.message, 40, window.height - 55,
                         window.width - 80, 'center')
  end
end

return screen
