# Makefile for the report

SHELL	  = /bin/sh
LATEX	  = latex
MAKEINDEX = makeindex
BIBTEX    = bibtex
RMLDOC    = pike ../tools/rmldoc
PIC       = gpic

SOURCES = exp.tex \
	dae.tex \
	types.tex \
	absyn.tex \
	explode.tex \
	dump.tex \
	prefix.tex \
	mod.tex \
	algorithm.tex \
	env.tex \
	lookup.tex \
	builtin.tex \
	connect.tex \
	classinf.tex \
	values.tex \
	staticexp.tex \
	inst.tex \
	main.tex \
	transfig.tex

TEXJUNK = report.log report.toc report.stc report.dvi report.aux

.DEFAULT: report.dvi
.SUFFIXES:
.SUFFIXES: .rml .tex .dvi .ps

%.tex : ../%.rml
	$(RMLDOC) $< > $@

%.tex : %.pic
	$(PIC) -t $< > $@

report.dvi: report.tex report.ind report.bbl $(SOURCES)
	$(LATEX) $<

report.ps: report.dvi
	dvips -o $@ $<

index report.ind:
	$(MAKEINDEX) report.idx

report.bbl: report.bib
	$(BIBTEX) report

clean:
	$(RM) $(SOURCES) $(TEXJUNK)
