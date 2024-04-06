local lunatest = require "lunatest"
local json = require "json"
local tracker = require "tracker"
local player = require "player"
local HC = require 'vendor/hardoncollider'

function test_filename() 
  local t = tracker.new('foo', {})
  lunatest.assert_match("replays/%d+_foo%.json", t.filename)
end

function test_track_row() 
  local t = tracker.new('foo', player.new(HC(100)))
  t:update(100)

  local entry = t.rows[1]
  lunatest.assert_equal(entry[1], 0)
  lunatest.assert_equal(entry[2], 0)
  lunatest.assert_equal(entry[3], 'right')
  lunatest.assert_equal(entry[4], 'idle')
end

function test_flush_row() 
  local t = tracker.new('foo', player.new(HC(100)))
  t:update(100)
  t:flush()

  local contents, _ = love.filesystem.read(t.filename)
  local entry = json.decode(contents)[1]
  love.filesystem.remove(t.filename)

  lunatest.assert_equal(0, entry[1])
  lunatest.assert_equal(0, entry[2])
  lunatest.assert_equal('right', entry[3])
  lunatest.assert_equal('idle', entry[4])
end
