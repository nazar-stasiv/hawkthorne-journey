local Player = require 'player'
Player.refreshPlayer = function() end -- Stubs refreshPlayer to avoid dependencies

local player = Player.factory() -- Create test player

local inv = player.inventory
local scroll = {name = 'fakescroll', type = 'scroll', select = function(self) return end}

-- it should add a scroll and select it
function test_add_scroll_to_inventory_and_select()
  lunatest.assert_true(inv:addItem(scroll))
  inv:selectCurrentScrollSlot()
  lunatest.assert_equal(15 ,inv.selectedWeaponIndex)
end

-- it should remove all items
function test_remove_all_items()
  inv:addItem(scroll)
  inv:removeAllItems()
  lunatest.assert_equal(0, #inv.pages.scrolls)
end
