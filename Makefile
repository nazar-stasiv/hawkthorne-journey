LUA_VERSION := "5.1"
LUA_PATH := "$(CURDIR)/lua_modules/share/lua/$(LUA_VERSION)/?.lua;$(CURDIR)/lua_modules/share/lua/$(LUA_VERSION)/?/init.lua;${LUA_PATH}"
LUA_CPATH := "$(CURDIR)/lua_modules/lib/lua/$(LUA_VERSION)/?.so;$(CURDIR)/lua_modules/lib/lua/$(LUA_VERSION)/?/?.so;${LUA_CPATH}"

.PHONY: maps deps patch clean count run

tilemaps := $(patsubst %.tmx,%.lua,$(wildcard src/maps/*.tmx))
src/maps/%.lua: src/maps/%.tmx
	tmx2lua $<

maps: $(tilemaps)

deps: maps
	luarocks --lua-version $(LUA_VERSION) init
	luarocks --lua-version $(LUA_VERSION) install hc
	luarocks --lua-version $(LUA_VERSION) install JSON4Lua
	luarocks --lua-version $(LUA_VERSION) install middleclass 3.0.0-1
	luarocks --lua-version $(LUA_VERSION) install anim8
	luarocks --lua-version $(LUA_VERSION) install lunatest 0.9.5
	luarocks --lua-version $(LUA_VERSION) install lua_cliargs 2.0-1
	luarocks --lua-version $(LUA_VERSION) install inspect 1.2-2
	luarocks --lua-version $(LUA_VERSION) install hump

patch: deps
	cp patches/*.patch lua_modules/share/lua/$(LUA_VERSION)/
	patch -d lua_modules/share/lua/$(LUA_VERSION) -i cliargs.patch
	patch -d lua_modules/share/lua/$(LUA_VERSION) -i lunatest.patch
	wget -O lua_modules/share/lua/$(LUA_VERSION)/tween.lua https://github.com/kikito/tween.lua/raw/v1.0.1/tween.lua
	wget -O lua_modules/share/lua/$(LUA_VERSION)/TEsound.lua https://github.com/drhayes/TESound/raw/master/tesound.lua
	patch -d lua_modules/share/lua/$(LUA_VERSION) -i tesound.patch

target/hawkthorne.love: patch
	mkdir -p target
	(cd $(CURDIR)/src && zip --symlinks -q -r $(CURDIR)/target/hawkthorne.love . -x ".*" -x "*/full_soundtrack.ogg")
	(cd $(CURDIR)/lua_modules/share/lua/$(LUA_VERSION)/ && zip --symlinks -q -r -u $(CURDIR)/target/hawkthorne.love .)

clean:
	rm -rf src/maps/*.lua
	rm -rf .luarocks
	rm -rf target
	rm -rf lua_modules
	rm -f game-dev-1.rockspec
	rm -f luarocks
	rm -f lua

count:
	cloc src --exclude-list-file=.gitignore

test:
	LUA_PATH=$(LUA_PATH) LUA_CPATH=$(LUA_CPATH) love src --test

run:
	LUA_PATH=$(LUA_PATH) LUA_CPATH=$(LUA_CPATH) love src

