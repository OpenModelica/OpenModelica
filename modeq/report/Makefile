# Makefile for the report

SHELL	= /bin/sh
LATEX	= latex
RMLDOC  = ../tools/rmldoc

SOURCES = inst.tex classinf.tex mod.tex connect.tex

.DEFAULT: report.dvi
.SUFFIXES:
.SUFFIXES: .rml .tex .dvi .ps

%.tex : ../%.rml
	$(RMLDOC) $< > $@

report.dvi: report.tex $(SOURCES)
	$(LATEX) $<

report.ps: report.dvi
	dvips -o $@ $<

clean:
	$(RM) $(SOURCES) report.dvi report.ps report.aux report.toc report.log
