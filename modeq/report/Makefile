# Makefile for the report

SHELL	= /bin/sh
LATEX	= latex

.DEFAULT: report.dvi

report.dvi: report.tex report.aux
	$(LATEX) $<

report.ps: report.dvi
	dvips -o $@ $<
