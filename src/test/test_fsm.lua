local lunatest = require "lunatest"
local machine = require 'hawk/statemachine'
local middle = require 'middleclass'

local _stoplight = {
  { name = 'warn',  from = 'green',  to = 'yellow' },
  { name = 'panic', from = 'yellow', to = 'red'    },
  { name = 'calm',  from = 'red',    to = 'yellow' },
  { name = 'clear', from = 'yellow', to = 'green'  }
}

local function stoplight()
  return machine.create({ initial = 'green', events = _stoplight })
end

-- it should start as green
function test_fsm_start_green()
  local fsm = stoplight()
  lunatest.assert_true(fsm:is('green'))
end

-- it should not let you get to the wrong state
function test_fsm_state_transition()
  local fsm = stoplight()
  lunatest.assert_false(fsm:panic())
  lunatest.assert_false(fsm:calm())
  lunatest.assert_false(fsm:clear())
end

-- it("should let you go to yellow
function test_fsm_no_yellow()
  local fsm = stoplight()
  lunatest.assert_true(fsm:warn())
  lunatest.assert_true(fsm:is('yellow'))
end

-- it should tell you what it can do
function test_fsm_can()
  local fsm = stoplight()
  lunatest.assert_true(fsm:can('warn'))
  lunatest.assert_false(fsm:can('panic'))
  lunatest.assert_false(fsm:can('calm'))
  lunatest.assert_false(fsm:can('clear'))
end

-- it should tell you what it can't do
function test_fsm_cannot()
  local fsm = stoplight()
  lunatest.assert_false(fsm:cannot('warn'))
  lunatest.assert_true(fsm:cannot('panic'))
  lunatest.assert_true(fsm:cannot('calm'))
  lunatest.assert_true(fsm:cannot('clear'))
end

-- it should support checking states
function test_fsm_check_states()
  local fsm = stoplight()
  lunatest.assert_true(fsm:is('green'))
  lunatest.assert_false(fsm:is('red'))
  lunatest.assert_false(fsm:is('yellow'))
end

-- it should cancel the warn event on leave
function test_fsm_canel_warn_event()
  local fsm = stoplight()

  fsm.onleavegreen = function(self, name, from, to) 
    return false
  end

  local result = fsm:warn()

  lunatest.assert_false(result)
  lunatest.assert_true(fsm:is('green'))
end

-- it should cancel the warn event on before
function test_fsm_cancel_onbefore_event()
  local fsm = stoplight()

  fsm.onbeforewarn = function(self, name, from, to) 
    return false
  end

  local result = fsm:warn()

  lunatest.assert_false(result)
  lunatest.assert_true(fsm:is('green'))
end

-- it should accept other arguments
function test_fsm_accept_arguments()
  local fsm = stoplight()

  fsm.onstatechange = function(self, name, from, to, foo)
    self.foo = foo
  end

  fsm:warn("bar")

  lunatest.assert_equal(fsm.foo, 'bar')
end

-- it should fire the onstatechange handler
function test_fsm_change_handler()
  local fsm = stoplight()

  fsm.onstatechange = function(self, name, from, to) 
    self.name = name
    self.from = from
    self.to = to
  end

  fsm:warn()

  lunatest.assert_equal(fsm.name, 'warn')
  lunatest.assert_equal(fsm.from, 'green')
  lunatest.assert_equal(fsm.to, 'yellow')
end

-- it should support mixins
function test_fsm_mixins()
  local Stoplight = middle.class('Stoplight')

  Stoplight:include(machine.mixin({ initial = 'green', events = _stoplight }))

  function Stoplight:onwarn(name, from, to) 
    self.name = name
    self.from = from
    self.to = to
  end

  local light = Stoplight()
  local light2 = Stoplight()

  light:warn()

  lunatest.assert_true(light:is('yellow'))
  lunatest.assert_equal(light.name, 'warn')
  lunatest.assert_equal(light.from, 'green')
  lunatest.assert_equal(light.to, 'yellow')

  lunatest.assert_true(light2:is('green'))
end

-- it should fire the onwarn handler
function test_fsm_fire_onwarn()
  local fsm = stoplight()

  fsm.onwarn = function(self, name, from, to) 
    self.name = name
    self.from = from
    self.to = to
  end

  fsm:warn()

  lunatest.assert_equal(fsm.name, 'warn')
  lunatest.assert_equal(fsm.from, 'green')
  lunatest.assert_equal(fsm.to, 'yellow')
end

