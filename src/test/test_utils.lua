local lunatest = require "lunatest"
local utils = require "utils"

--should be -1 for a negative number
function test_sign_negvative() 
  lunatest.assert_equal(utils.sign(-100), -1)
end

--should be 0 for a 0
function test_sign_zero()
  lunatest.assert_equal(utils.sign(0), 0)
end
    
--should be 1 for a positive number
function test_sign_positive()
  lunatest.assert_equal(utils.sign(100), 1)
end
    
--should round 1.4 to 1
function test_round_down()
  lunatest.assert_equal(utils.round(1.4), 1)
end

--should round 1.5 to 2
function test_round_up()
  lunatest.assert_equal(utils.round(1.5), 2)
end

--should split a string
function test_split_string()
  local output = utils.split("a a", " ")
  lunatest.assert_equal(output[1], "a")
  lunatest.assert_equal(output[2], "a")
end

--should remove first and last values if they are the same
function test_remove_duplicate_args()
  local output = utils.cleanarg({"src", "--level=forest", "src"})
  lunatest.assert_equal(output[1], "--level=forest")
  lunatest.assert_equal(#output, 1)
end

--should remove first value
function test_remove_first_args()
  local output = utils.cleanarg({"src", "--level=forest"})
  lunatest.assert_equal(output[1], "--level=forest")
  lunatest.assert_equal(#output, 1)
end

function test_string_endswith()
  lunatest.assert_true(utils.endswith(".lua.lua", ".lua"))
  lunatest.assert_true(utils.endswith("main.lua", ".lua"))
  lunatest.assert_false(utils.endswith(".lua.luap", ".lua"))
end

function test_string_startswith()
  lunatest.assert_true(utils.startswith(".lua.lua", ".lua"))
  lunatest.assert_true(utils.startswith(".lua.luap", ".lua"))
  lunatest.assert_false(utils.startswith("main.lua", ".lua"))
end
