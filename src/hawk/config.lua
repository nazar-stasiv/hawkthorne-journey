local json = require 'json'

local config = {}

function config.load(filepath)
  local contents, _  = love.filesystem.read(filepath)
  return json.decode(contents)
end

return config
