VERSION=0.1.0
LOVE_VERSION=11.5
NAME=change-me
ITCH_ACCOUNT=change-me-too
URL=https://gitlab.com/alexjgriffith/min-love2d-fennel
AUTHOR="Your Name"
DESCRIPTION="Minimal setup for trying out Phil Hagelberg's fennel/love game design process."
GITHUB_USERNAME := "liberodark"
GITHUB_PAT := "hawkthorne-journey"
LIBS := $(wildcard lua_modules/share/lua/5.1/*)
LUA := $(wildcard src/*.lua)
SRC := $(wildcard src/*.fnl)
OUT := $(patsubst src/%.fnl,src/%.lua,$(SRC))
FENNEL := fennel --lua lua
LUA_VERSION := "5.1"
LUA_PATH := "$(CURDIR)/lua_modules/share/lua/$(LUA_VERSION)/?.lua;$(CURDIR)/lua_modules/share/lua/$(LUA_VERSION)/?/init.lua;${LUA_PATH}"
LUA_CPATH := "$(CURDIR)/lua_modules/lib/lua/$(LUA_VERSION)/?.so;$(CURDIR)/lua_modules/lib/lua/$(LUA_VERSION)/?/?.so;${LUA_CPATH}"

count: ; cloc src --exclude-list-file=.gitignore

LOVEFILE=releases/$(NAME)-$(VERSION).love

src/%.lua: src/%.fnl
	${FENNEL} --require-as-include --compile $< >> $@

$(LOVEFILE): $(LUA) $(SRC) $(LIBS) $(OUT)
	mkdir -p releases/
	find $^ -type f | LC_ALL=C sort | env TZ=UTC zip -r -q -9 -X $@ -@

love: $(LOVEFILE)

# platform-specific distributables

REL=$(PWD)/buildtools/love-release.sh # https://p.hagelb.org/love-release.sh
FLAGS=-a "$(AUTHOR)" --description $(DESCRIPTION) \
	--love $(LOVE_VERSION) --url $(URL) --version $(VERSION) --lovefile $(LOVEFILE)

releases/$(NAME)-$(VERSION)-x86_64.AppImage: $(LOVEFILE)
	cd buildtools/appimage && \
	./build.sh $(LOVE_VERSION) $(PWD)/$(LOVEFILE) $(GITHUB_USERNAME) $(GITHUB_PAT)
	mv buildtools/appimage/game-x86_64.AppImage $@

releases/$(NAME)-$(VERSION)-macos.zip: $(LOVEFILE)
	$(REL) $(FLAGS) -M
	mv releases/$(NAME)-macos.zip $@

releases/$(NAME)-$(VERSION)-win.zip: $(LOVEFILE)
	$(REL) $(FLAGS) -W32
	mv releases/$(NAME)-win32.zip $@

releases/$(NAME)-$(VERSION)-web.zip: $(LOVEFILE)
	buildtools/love-js/love-js.sh releases/$(NAME)-$(VERSION).love $(NAME) -v=$(VERSION) -a=$(AUTHOR) -o=releases

linux: releases/$(NAME)-$(VERSION)-x86_64.AppImage
mac: releases/$(NAME)-$(VERSION)-macos.zip
windows: releases/$(NAME)-$(VERSION)-win.zip
web: releases/$(NAME)-$(VERSION)-web.zip


runweb: $(LOVEFILE)
	buildtools/love-js/love-js.sh $(LOVEFILE) $(NAME) -v=$(VERSION) -a=$(AUTHOR) -o=releases -r -n
# If you release on itch.io, you should install butler:
# https://itch.io/docs/butler/installing.html

uploadlinux: releases/$(NAME)-$(VERSION)-x86_64.AppImage
	butler push $^ $(ITCH_ACCOUNT)/$(NAME):linux --userversion $(VERSION)
uploadmac: releases/$(NAME)-$(VERSION)-macos.zip
	butler push $^ $(ITCH_ACCOUNT)/$(NAME):mac --userversion $(VERSION)
uploadwindows: releases/$(NAME)-$(VERSION)-win.zip
	butler push $^ $(ITCH_ACCOUNT)/$(NAME):windows --userversion $(VERSION)
uploadweb: releases/$(NAME)-$(VERSION)-web.zip
	butler push $^ $(ITCH_ACCOUNT)/$(NAME):web --userversion $(VERSION)

upload: uploadlinux uploadmac uploadwindows

release: linux mac windows upload cleansrc

.PHONY: clean contributors run productionize deploy love maps lint count deps patch

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
  TMXTAR = tmx2lua.osx.tar
  LOVE = bin/love.app/Contents/MacOS/love
else
  TMXTAR = tmx2lua.linux.tar
  LOVE = /usr/bin/love
endif

ifeq ($(shell which wget),)
  wget = curl -s -O -L
else
  wget = wget -q --no-check-certificate
endif

tilemaps := $(patsubst %.tmx,%.lua,$(wildcard src/maps/*.tmx))

maps: $(tilemaps)

love: build/hawkthorne.love

build/hawkthorne.love: $(tilemaps) src/*
	mkdir -p build
	(cd src && zip --symlinks -q -r ../build/hawkthorne.love . -x ".*" -x ".DS_Store" -x "*/full_soundtrack.ogg" -x "*.bak")
	(cd lua_modules/share/lua/$(LUA_VERSION)/ && zip --symlinks -q -r -u ../../../../build/hawkthorne.love . -x ".*" -x ".DS_Store" -x "*/full_soundtrack.ogg" -x "*.bak")
	(cd lua_modules/lib/lua/$(LUA_VERSION)/ && zip --symlinks -q -r -u ../../../../build/hawkthorne.love . -x ".*" -x ".DS_Store" -x "*/full_soundtrack.ogg" -x "*.bak")

deps:
	luarocks --lua-version $(LUA_VERSION) init
	luarocks --lua-version $(LUA_VERSION) install hc
	luarocks --lua-version $(LUA_VERSION) install JSON4Lua
	luarocks --lua-version $(LUA_VERSION) install middleclass 3.0.0-1
	luarocks --lua-version $(LUA_VERSION) install anim8
	luarocks --lua-version $(LUA_VERSION) install lunatest 0.9.5
	luarocks --lua-version $(LUA_VERSION) install fennel
	luarocks --lua-version $(LUA_VERSION) install lua_cliargs 2.0-1
	luarocks --lua-version $(LUA_VERSION) install inspect 1.2-2
	luarocks --lua-version $(LUA_VERSION) install hump
patch: deps
	cp patches/*.patch lua_modules/share/lua/$(LUA_VERSION)/
	rm -f lua_modules/share/lua/$(LUA_VERSION)/TEsound.lua
	wget -O lua_modules/share/lua/$(LUA_VERSION)/TEsound.lua https://github.com/drhayes/TESound/raw/master/tesound.lua
	wget -O lua_modules/share/lua/$(LUA_VERSION)/tween.lua https://github.com/kikito/tween.lua/raw/v1.0.1/tween.lua
	patch -d lua_modules/share/lua/$(LUA_VERSION) -i tesound.patch
	patch -d lua_modules/share/lua/$(LUA_VERSION) -i cliargs.patch
	patch -d lua_modules/share/lua/$(LUA_VERSION) -i lunatest.patch

run: $(tilemaps) $(LOVE)
	LUA_PATH=$(LUA_PATH) LUA_CPATH=$(LUA_CPATH) $(LOVE) src

src/maps/%.lua: src/maps/%.tmx
	$$HOME/.local/bin/tmx2lua $<

bin/love.app/Contents/MacOS/love:
	mkdir -p bin
	$(wget) https://github.com/love2d/love/releases/download/11.3/love-11.3-macos.zip
	unzip -q love-11.3-macos.zip
	rm -f love-11.3-macos.zip
	mv love.app bin
	cp osx/Info.plist bin/love.app/Contents

clean:
	rm -rf build
	rm -f release.md
	rm -f post.md
	rm -f notes.html
	rm -rf src/maps/*.lua
	rm -rf $(OSXAPP)
	rm -rf releases/*
	rm -rf lua_modules
	rm -rf .luarocks
	rm -f lua
	rm -f luarocks
	rm -f game-dev-1.rockspec
	rm -rf target

reset:
	rm -rf ~/Library/Application\ Support/LOVE/hawkthorne/*.json
	rm -rf $(XDG_DATA_HOME)/love/ ~/.local/share/love/
	rm -rf src/maps/*.lua

target/Ludo-Linux-x11-x86_64-0.17.1.tar.gz:
	mkdir -p emu
	wget -c -P target https://github.com/libretro/ludo/releases/download/v0.17.1/Ludo-Linux-x11-x86_64-0.17.1.tar.gz

target/ludo: target/Ludo-Linux-x11-x86_64-0.17.1.tar.gz
	tar xf target/Ludo-Linux-x11-x86_64-0.17.1.tar.gz -C target --strip 1

target/hawkthorne.lutro: target/ludo build/hawkthorne.love
	cp build/hawkthorne.love target/hawkthorne.lutro

emu: target/hawkthorne.lutro
	(cd target && ./ludo -L cores/lutro_libretro.so hawkthorne.lutro)


wasm: build/hawkthorne.love
	mkdir -p wasm
	(cd wasm && npm i love.js)
	(cd wasm && npx love.js ../build/hawkthorne.love game -c -m 100000000)
	(cd wasm && python3 -m http.server --bind 127.0.0.1 8080)

arm: build/hawkthorne.love
	(cd build && SDL_VIDEODRIVER=directfb qemu-arm  -L . love hawkthorne.love)
