# Makefile for the report

SHELL	  = /bin/sh
LATEX	  = latex
MAKEINDEX = makeindex
RMLDOC    = pike ../tools/rmldoc

SOURCES = exp.tex \
	dae.tex \
	types.tex \
	absyn.tex \
	explode.tex \
	dump.tex \
	prefix.tex \
	mod.tex \
	env.tex \
	lookup.tex \
	builtin.tex \
	connect.tex \
	classinf.tex \
	staticexp.tex \
	inst.tex \
	main.tex

TEXJUNK = report.log report.toc report.stc report.dvi report.aux

.DEFAULT: report.dvi
.SUFFIXES:
.SUFFIXES: .rml .tex .dvi .ps

%.tex : ../%.rml
	$(RMLDOC) $< > $@

report.dvi: report.tex report.ind report.bbl $(SOURCES)
	$(LATEX) $<

report.ps: report.dvi
	dvips -o $@ $<

index report.ind:
	$(MAKEINDEX) report.idx

clean:
	$(RM) $(SOURCES) $(TEXJUNK)
