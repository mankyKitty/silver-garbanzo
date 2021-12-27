
idrisid:
	@echo "Launching idrisid"
	pwd
	echo src/main.idr | entr sh -c 'make build'

build:	build/exec/main.js

build/exec/main.js:	src/main.idr
	idris2 -p dom --build silver-garbanzo.ipkg

web:
	live-server