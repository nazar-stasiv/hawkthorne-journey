(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))
(local utils (require :utils))
(local app (require :app))
(local tween (require :vendor/tween))
(local Gamestate (require :vendor/gamestate))
(local sound (require :TEsound))
(local timer (require :vendor/timer))
(local cli (require :cliargs))
(local mixpanel (require :vendor/mixpanel))
(local debugger (require :debugger))
(local camera (require :camera))
(local fonts (require :fonts))
(local window (require :window))
(local controls ((. (require :inputcontroller) :get)))
(local hud (require :hud))
(local character (require :character))
(local cheat (require :cheat))
(local player (require :player))
(local Dialog (require :dialog))
(local Prompt (require :prompt))
(local lovetest (require :test/lovetest))
(var testing false)
(local paused false)

(fn get-version []
  (. (utils.split (love.window.getCaption) :v) 2))

(fn love.load [arg]
  (when (not (= (type love._version) :string))
    (error "invalid version label"))
  (local version (utils.split (love._version:gsub "%." "/") "/"))
  (local major (tonumber (. version 1)))
  (local minor (tonumber (. version 2)))
  (local revision (tonumber (. version 3)))
  (set-forcibly! arg (utils.cleanarg arg))
  (local mixpanel (require :vendor/mixpanel))
  (var (state door position) (values :update nil nil))
  (mixpanel.init app.config.iteration)
  (mixpanel.track :game.opened)
  (local options (require :options))
  (options:init)
  (cli:add_option :--console "Displays print info")
  (cli:add_option :--fused "Passed in when the app is running in fused mode")
  (cli:add_option :--reset-saves "Resets all the saves")
  (cli:add_option "-b, --bbox"
                  "Draw all bounding boxes ( enables memory debugger )")
  (cli:add_option "-c, --character=NAME" "The character to use in the game")
  (cli:add_option "-d, --debug" "Enable Memory Debugger")
  (cli:add_option "-l, --level=NAME" "The level to display")
  (cli:add_option "-m, --money=COINS"
                  "Give your character coins ( requires level flag )")
  (cli:add_option "-n, --locale=LOCALE" "Local, defaults to en-US")
  (cli:add_option "-o, --costume=NAME" "The costume to use in the game")
  (cli:add_option "-p, --position=X,Y"
                  "The positions to jump to ( requires level )")
  (cli:add_option "-r, --door=NAME" "The door to jump to ( requires level )")
  (cli:add_option "-t, --test" "Run all the unit tests")
  (cli:add_option "-w, --wait" "Wait for three seconds")
  (cli:add_option "-v, --vol-mute=CHANNEL" "Disable sound: all, music, sfx")
  (cli:add_option "-x, --cheat=ALL/CHEAT1,CHEAT2"
                  "Enable certain cheats ( some require level to function, else will crash with collider is nil )")
  (local args (cli:parse arg))
  (when (not args) (error "Could not parse command line arguments"))
  (when testing (lovetest.run) (lua "return "))
  (when (. args :wait) (love.timer.sleep 3))
  (when (not= (. args :level) "") (set state (. args :level))
    (set Gamestate.home :update))
  (when (not= (. args :door) "") (set door (. args :door)))
  (when (not= (. args :position) "") (set position (. args :position)))
  (var char :abed)
  (var costume :base)
  (when (not= (. args :character) "") (set char (. args :c)))
  (when (not= (. args :costume) "") (set costume (. args :o)))
  (character.pick char costume)
  (if (= (. args :vol-mute) :all) (set sound.disabled true)
      (= (. args :vol-mute) :music) (sound.volume :music 0)
      (= (. args :vol-mute) :sfx) (sound.volume :sfx 0))
  (when (not= (. args :money) "")
    (set player.startingMoney (tonumber (. args :money))))
  (when (. args :d) (debugger.set true false))
  (when (. args :b) (debugger.set true true))
  (when (. args :reset-saves) (options:reset_saves))
  (when (not= (. args :locale) "") (app.i18n:setLocale args.locale))
  (var argcheats false)
  (var cheats {})
  (when (not= (. args :cheat) "")
    (set argcheats true)
    (if (string.find (. args :cheat) ",")
        (do
          (var from 1)
          (var (delim-from delim-to) (string.find (. args :cheat) "," from))
          (while delim-from
            (table.insert cheats
                          (string.sub (. args :cheat) from (- delim-from 1)))
            (set from (+ delim-to 1))
            (set (delim-from delim-to) (string.find (. args :cheat) "," from)))
          (table.insert cheats (string.sub (. args :cheat) from)))
        (if (= (. args :cheat) :all)
            (set cheats [:jump_high
                         :super_speed
                         :god
                         :slide_attack
                         :give_money
                         :max_health
                         :give_gcc_key
                         :give_weapons
                         :give_materials
                         :give_potions
                         :give_scrolls
                         :give_taco_meat
                         :unlock_levels
                         :give_master_key
                         :give_armor
                         :give_recipes])
            (set cheats [(. args :cheat)]))))
  (love.graphics.setDefaultFilter :nearest :nearest)
  (Gamestate.switch state door position)
  (when argcheats
    (each [k arg (ipairs cheats)] (cheat:on arg))))

(fn love.update [dt]
  (when (or paused testing) (lua "return "))
  (when debugger.on (debugger:update dt))
  (set-forcibly! dt (math.min 0.033333333 dt))
  (when Prompt.currentPrompt (Prompt.currentPrompt:update dt))
  (when Dialog.currentDialog (Dialog.currentDialog:update dt))
  (Gamestate.update dt)
  (tween.update (or (and (> dt 0) dt) 0.001))
  (timer.update dt)
  (sound.cleanup)
  (when debugger.on (collectgarbage :collect)))

(fn love.keyreleased [key]
  (when testing (lua "return "))
  (local action (controls:getAction key))
  (when action (Gamestate.keyreleased action))
  (when (not action) (lua "return "))
  (if (or Prompt.currentPrompt Dialog.currentDialog) nil
      (Gamestate.keyreleased action)))

(fn love.keypressed [key]
  (controls:switch)
  (when testing (lua "return "))
  (when (controls:isRemapping) (Gamestate.keypressed key)
        (lua "return "))
  (when (= key :f5) (debugger:toggle))
  (when (and (= key :f6) debugger.on) (debug.debug))
  (local action (controls:getAction key))
  (local state (or (. (Gamestate.currentState) :name) ""))
  (when (and (not action) (not= state :welcome)) (lua "return "))
  (if Prompt.currentPrompt
      (Prompt.currentPrompt:keypressed action)
      Dialog.currentDialog
      (Dialog.currentDialog:keypressed action)
      (Gamestate.keypressed action)))

(fn love.gamepadreleased [joystick key]
  (love.keyreleased key))

(fn love.gamepadpressed [joystick key]
  (controls:switch joystick)
  (love.keypressed key))

(fn love.joystickremoved [joystick] (controls:switch))

(fn love.joystickreleased [joystick key]
  (when (joystick:isGamepad) (lua "return "))
  (love.keyreleased (tostring key)))

(fn love.joystickpressed [joystick key]
  (when (joystick:isGamepad) (lua "return "))
  (controls:switch joystick)
  (love.keyressed (tostring key)))

(fn love.joystickaxis [joystick axis value]
  (when (joystick:isGamepad) (lua "return "))
  (global (axis-dir1 axis-dir2 _) (joystick:getAxes))
  (controls:switch joystick)
  (when (< axis-dir1 0) (love.keypressed :dpleft))
  (when (> axis-dir1 0) (love.keypressed :dpright))
  (when (< axis-dir2 0) (love.keypresssed :dpup))
  (when (> axis-dir2 0) (love.keypressed :dpdown)))

(fn love.draw []
  (when testing (lua "return "))
  (camera:set)
  (Gamestate.draw)
  (fonts.set :arial)
  (when Dialog.currentDialog (Dialog.currentDialog:draw))
  (when Prompt.currentPrompt (Prompt.currentPrompt:draw))
  (fonts.revert)
  (camera:unset)
  (when paused (love.graphics.setColor 0.29 0.29 0.29 0.49)
    (love.graphics.rectangle :fill 0 0 (love.graphics:getWidth)
                             (love.graphics:getHeight))
    (love.graphics.setColor 1 1 1 1))
  (when debugger.on (debugger:draw))
  (when (and window.showfps window.dressing_visible)
    (love.graphics.setColor 1 1 1 1)
    (fonts.set :big)
    (love.graphics.print (.. (love.timer.getFPS) " FPS")
                         (- (love.graphics.getWidth) 100) 5 0 1 1)
    (fonts.revert)))


