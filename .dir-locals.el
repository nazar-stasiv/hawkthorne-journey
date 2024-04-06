((fennel-mode . ((eval . (setq fennel-program
			       (let ((p (expand-file-name (ffip-get-project-root-directory))))
				 (concat "fennel --add-package-path " p
					 "lua_modules/share/lua/5.1/?.lua --add-package-path " p
					 "lua_modules/share/lua/5.1/?/init.lua --lua luajit --repl")))))))

