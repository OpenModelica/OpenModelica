.PHONY: lib-for-testing lib-for-installing clean update clean-test clean-install

include Makefile.version

lib-for-testing: .openmodelica/$(STAMP)
lib-for-installing: installing/.openmodelica/$(STAMP)
	mkdir -p ../build/share/omlibrary/cache
	cp -u install-index.json ../build/share/omlibrary/cache/index.json
	cp -ur installing/.openmodelica/cache/* ../build/share/omlibrary/cache/

clean: clean-test clean-install
clean-test:
	rm -rf .openmodelica/libraries .openmodelica/*.stamp
clean-install:
	rm -rf installing/.openmodelica/libraries installing/.openmodelica/*.stamp

.openmodelica/$(STAMP): index.json index.mos
	$(MAKE) clean-test
	mkdir -p .openmodelica/libraries
	ls -l .openmodelica/libraries
	cp index.json .openmodelica/libraries
	../build/bin/omc index.mos

installing/.openmodelica/$(STAMP): install-index.json install-index.mos
	$(MAKE) clean-install
	mkdir -p installing/.openmodelica/libraries
	ls -l installing/.openmodelica/libraries
	cp install-index.json installing/.openmodelica/libraries/index.json
	(cd installing && ../../build/bin/omc ../install-index.mos)

update:
	./update.py --test ""
	./update.py install-
