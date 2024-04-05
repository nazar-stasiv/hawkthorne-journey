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

LUA_VERSION := "5.1"
LUA_PATH := "$(CURDIR)/lua_modules/share/lua/$(LUA_VERSION)/?.lua;$(CURDIR)/lua_modules/share/lua/$(LUA_VERSION)/?/init.lua;${LUA_PATH}"

count: ; cloc src --exclude-list-file=.gitignore

LOVEFILE=releases/$(NAME)-$(VERSION).love

$(LOVEFILE): $(LUA) $(SRC) $(LIBS) assets
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

.PHONY: clean contributors run productionize deploy love maps appcast lint count deps

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
  TMXTAR = tmx2lua.osx.tar
  LOVE = bin/love.app/Contents/MacOS/love
else
  TMXTAR = tmx2lua.linux.tar
  LOVE = bin/love
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
	cd src && zip --symlinks -q -r ../build/hawkthorne.love . -x ".*" \
		-x ".DS_Store" -x "*/full_soundtrack.ogg" -x "*.bak"

deps:
	luarocks --lua-version $(LUA_VERSION) init
	luarocks --lua-version $(LUA_VERSION) install hc
	luarocks --lua-version $(LUA_VERSION) install JSON4Lua
	luarocks --lua-version $(LUA_VERSION) install middleclass 3.0.0-1
	luarocks --lua-version $(LUA_VERSION) install anim8
	luarocks --lua-version $(LUA_VERSION) install inspect
	luarocks --lua-version $(LUA_VERSION) install tween
	luarocks --lua-version $(LUA_VERSION) install lunatest
	luarocks --lua-version $(LUA_VERSION) install luasocket
	luarocks --lua-version $(LUA_VERSION) install fennel
	luarocks --lua-version $(LUA_VERSION) install lume

run: $(tilemaps) $(LOVE)
	LUA_PATH=$(LUA_PATH) $(LOVE) src

src/maps/%.lua: src/maps/%.tmx bin/tmx2lua
	bin/tmx2lua $<

bin/tmx2lua:
	ln -s /usr/bin/tmx2lua bin/tmx2lua

bin/love.app/Contents/MacOS/love:
	mkdir -p bin
	$(wget) https://github.com/love2d/love/releases/download/11.3/love-11.3-macos.zip
	unzip -q love-11.3-macos.zip
	rm -f love-11.3-macos.zip
	mv love.app bin
	cp osx/Info.plist bin/love.app/Contents

bin/love:
	mkdir -p bin
	ln -s /usr/bin/love bin/love


######################################################
# THE REST OF THESE TARGETS ARE FOR RELEASE AUTOMATION
######################################################

CI_TARGET=test validate maps productionize binaries

ifeq ($(TRAVIS), true)
ifeq ($(TRAVIS_PULL_REQUEST), false)
ifeq ($(TRAVIS_BRANCH), release)
CI_TARGET=clean test validate maps productionize social
endif
endif
endif

positions: $(patsubst %.png,%.lua,$(wildcard src/positions/*.png))

src/positions/%.lua: psds/positions/%.png
	overlay2lua src/positions/config.json $<

win64/love.exe:
	$(wget) https://github.com/love2d/love/releases/download/11.3/love-11.3-win64.zip
	unzip -q love-11.3-win64.zip
	mv love-11.3-win64 win64
	rm -f love-11.3-win64.zip
	rm win64/changes.txt win64/game.ico win64/license.txt win64/love.ico win64/readme.txt

win64/hawkthorne.exe: build/hawkthorne.love win64/love.exe
	cat win64/love.exe build/hawkthorne.love > win64/hawkthorne.exe

build/hawkthorne-win-x86_64.zip: win64/hawkthorne.exe
	mkdir -p build
	rm -rf hawkthorne
	rm -f hawkthorne-win-x86_64.zip
	cp -r win64 hawkthorne
	zip --symlinks -q -r hawkthorne-win-x86_64 hawkthorne -x "*/love.exe"
	mv hawkthorne-win-x86_64.zip build

OSXAPP=Journey\ to\ the\ Center\ of\ Hawkthorne.app

$(OSXAPP): build/hawkthorne.love bin/love.app/Contents/MacOS/love
	cp -R bin/love.app $(OSXAPP)
	cp build/hawkthorne.love $(OSXAPP)/Contents/Resources/hawkthorne.love
	cp osx/Info.plist $(OSXAPP)/Contents/Info.plist
	cp osx/Hawkthorne.icns $(OSXAPP)/Contents/Resources/Love.icns

build/hawkthorne-osx.zip: $(OSXAPP)
	mkdir -p build
	zip --symlinks -q -r hawkthorne-osx $(OSXAPP)
	mv hawkthorne-osx.zip build

productionize: venv
	venv/bin/python scripts/productionize.py

binaries: build/hawkthorne-osx.zip build/hawkthorne-win-x86_64.zip

upload: binaries post.md venv
	venv/bin/python scripts/release.py

appcast: venv build/hawkthorne-osx.zip win64/hawkthorne.exe
	venv/bin/python scripts/sparkle.py
	cat sparkle/appcast.json | python -m json.tool > /dev/null
	venv/bin/python scripts/upload.py / sparkle/appcast.json

social: venv notes.html post.md
	venv/bin/python scripts/socialize.py post.md

notes.html: post.md
	venv/bin/python -m markdown post.md > notes.html

post.md:
	venv/bin/python scripts/create_post.py post.md

venv:
	virtualenv -q --python=python2.7 venv
	venv/bin/pip install -q -r requirements.txt

deploy: $(CI_TARGET)

contributors: venv
	venv/bin/python scripts/clean.py > CONTRIBUTORS
	venv/bin/python scripts/credits.py > src/credits.lua

validate: venv lint
	venv/bin/python scripts/validate.py src

lint:
	touch src/maps/init.lua
	find src -name "*.lua" | grep -v "src/vendor" | grep -v "src/test" | \
		xargs -I {} ./scripts/lualint.lua -r "{}"

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
reset:
	rm -rf ~/Library/Application\ Support/LOVE/hawkthorne/*.json
	rm -rf $(XDG_DATA_HOME)/love/ ~/.local/share/love/
	rm -rf src/maps/*.lua
