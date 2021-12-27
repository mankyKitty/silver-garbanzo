
idrisid:
	@echo "Launching idrisid"
	pwd
	echo src/Main.idr | entr sh -c 'make build'

build:	build/exec/main.js

build/exec/main.js:	src/Main.idr
	idris2 --build silver-garbanzo.ipkg

web:
	live-server