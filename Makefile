.PHONY: generated_pdfs/dyOptInitialGuess.pdf
all: generated_pdfs/dyOptInitialGuess.pdf
generated_pdfs/dyOptInitialGuess.pdf:
	latexmk -outdir=generated_pdfs -pdf SimulationRuntime/DynamicOptimization/src/dyOptInitialGuess.tex
