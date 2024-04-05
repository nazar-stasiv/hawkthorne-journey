((fennel-mode . ((fennel-program . (concat "fennel --lua luajit --no-fennelrc --repl --add-package-path "
					   (expand-file-name (ffip-get-project-root-directory))
					   "lua_modules/share/lua/5.1/?.lua --add-package-path "
					   (expand-file-name (ffip-get-project-root-directory))
					   "lua_modules/share/lua/5.1/?/init.lua")))))

