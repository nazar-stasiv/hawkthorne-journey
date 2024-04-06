local lunatest = require "lunatest"
local mixpanel = require "vendor/mixpanel"

--should be -1 for a negative number
function test_random_id() 
  lunatest.assert_equal(#mixpanel.randomId(), 10)
end

function test_distinct_id() 
  love.filesystem.remove('mixpanel.txt')
  lunatest.assert_equal(mixpanel.distinctId(), mixpanel.distinctId())
end

function test_distinct_id_len() 
  love.filesystem.remove('mixpanel.txt')
  lunatest.assert_equal(#mixpanel.distinctId(), 10)
end

function test_distinct_id_source() 
  love.filesystem.write('mixpanel.txt', 'foo')
  lunatest.assert_equal(mixpanel.distinctId(), 'foo')
  love.filesystem.remove('mixpanel.txt')
end

function test_randomness()
  lunatest.assert_not_equal(mixpanel.randomId(), mixpanel.randomId())
end
