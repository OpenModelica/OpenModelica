all: manual.ps

manual.dvi: manual.tex
	latex manual.tex
manual.ps: manual.dvi
	dvips manual.dvi -o manual.ps

