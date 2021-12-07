.PHONY: lib-for-testing clean

include Makefile.version

lib-for-testing: .openmodelica/libraries/$(STAMP)

clean:
	rm -rf .openmodelica/libraries

.openmodelica/libraries/$(STAMP): index.json index.mos
	$(MAKE) clean
	mkdir -p .openmodelica/libraries
	ls -l .openmodelica/libraries
	../../build/bin/omc index.mos
