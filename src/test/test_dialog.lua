local lunatest = require "lunatest"
local dialog = require "dialog"

-- it should get a shortened version of the current message
function test_dialog_message()
  local d = dialog.new('foo')
  lunatest.assert_equal(d:message(), '')
end

-- it should get the complete version of the current message
function test_dialog_whole_message()
  local d = dialog.new('foo')
  d.cursor = 3
  lunatest.assert_equal(d:message(), 'foo')
end

-- it should update the cursor
function test_dialog_update_cursor()
  local d = dialog.new('foo')
  lunatest.assert_equal(d:message(), '')
  d:update(1)
  lunatest.assert_equal(d:message(), 'foo')
end
