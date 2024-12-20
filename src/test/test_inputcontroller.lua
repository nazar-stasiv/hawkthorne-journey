local lunatest = require "lunatest"
local InputController = require 'inputcontroller'

local DEFAULT_ACTIONMAP = {
  UP = 'up',
  DOWN = 'down',
  LEFT = 'left',
  RIGHT = 'right',
  SELECT = 's',
  START = 'escape',
  JUMP = 'space',
  ATTACK = 'a',
  INTERACT = 'd',
}

function test_init_no_args()
  local controls = InputController.new()
  for action, key in pairs(DEFAULT_ACTIONMAP) do
    lunatest.assert_equal(key, controls.actionmap[action])
  end
end

function test_get()
  local c1 = InputController.get('somename')
  local c2 = InputController.get('somename')
  local c3 = InputController.new()

  lunatest.assert_equal(c1, c2)
  lunatest.assert_not_equal(c1, c3)
  lunatest.assert_not_equal(c2, c3)

  c1:newAction('x', 'ATTACK')
  lunatest.assert_equal('ATTACK', c2:getAction('x'))
  lunatest.assert_equal('a', c3:getKey('ATTACK'), "Unrelated controller affected by side effects")
end

function test_get_action()
  local controls = InputController.new()
  lunatest.assert_equal('INTERACT', controls:getAction('d'))
end

function test_get_key()
  local controls = InputController.new()
  lunatest.assert_equal('d', controls:getKey('INTERACT'))
end

function test_keymap()
  local controls = InputController.new()
  for action, key in pairs(DEFAULT_ACTIONMAP) do
    lunatest.assert_equal(action, controls.keymap[key])
  end
end

function test_remap_persistence()
  local c1 = InputController.new()
  local c2 = InputController.new()

  lunatest.assert_false(c1:isRemapping())
  lunatest.assert_false(c2:isRemapping())

  c1:enableRemap()
  lunatest.assert_true(c1:isRemapping())
  lunatest.assert_true(c2:isRemapping())

  c2:disableRemap()
  lunatest.assert_false(c1:isRemapping())
  lunatest.assert_false(c2:isRemapping())
end

function test_keyinuse()
  local controls = InputController.new()
  for _, key in pairs(DEFAULT_ACTIONMAP) do
    lunatest.assert_false(controls:keyIsNotInUse(key), key)
  end
  lunatest.assert_true(controls:keyIsNotInUse('x'))
end
