cmakeVS:
	mkdir -p ./_VS
	cd _VS && cmake ../ -G "Visual Studio 11"

cmakeVS10:
	mkdir -p ./_VS10
	cd _VS10 && cmake ../ -G "Visual Studio 10"

cmakeM:
	mkdir -p ./_Make
	cd _Make && cmake ../ -G "Unix Makefiles"

cmakeE:
	mkdir -p ./_Eclipse
	cd _Eclipse && cmake ../ -DCMAKE_BUILD_TYPE=Debug -G "Eclipse CDT4 - Unix Makefiles"

cmakeCB:
	mkdir -p ./_CodeBlocks
	cd _CodeBlocks && cmake ../ -G "CodeBlocks - Unix Makefiles"
