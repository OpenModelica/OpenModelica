DIRS=01 02a 02b 03 04 05a 05b 06 09 10 11

HTLATEX=/usr/share/tex4ht/htlatex

pdf: MetaModelicaBuiltin.mo
	rm -f $(DIRS)
	for d in $(DIRS); do ln -s ../../$${d}_* $$d; done
	latex main.tex
	pdflatex main.tex
	rm -f $(DIRS)
html: MetaModelicaBuiltin.mo
	rm -f $(DIRS)
	for d in $(DIRS); do ln -s ../../$${d}_* $$d; done
	latex main.tex
	$(HTLATEX) main.tex
	rm -f $(DIRS)
MetaModelicaBuiltin.mo: ../../../../../Compiler/FrontEnd/MetaModelicaBuiltin.mo
	cpp -w $< | grep -v "^#" > $@.tmp
	mv $@.tmp $@
