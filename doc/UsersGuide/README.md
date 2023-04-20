# User's Guide

OpenModelica User's Guide using Sphinx (Python Documentation Generator).

## Dependencies

Getting all dependencies right is a nightmare. Just use the dev container
`build-deps:v1.16.4` from [.devcontainer/README.md](./../../.devcontainer/README.md) and
set `GITHUB_AUTH`.

 - omc, omc-diff and omsimulator
 - Inkscape
 - Sphinx
 - Python3 and packages from [requirements.txt](https://raw.githubusercontent.com/OpenModelica/OpenModelica-doc/master/UsersGuide/source/requirements.txt)
 - Python PyGithub package

### GITHUB_AUTH

Create a read-only personal access token (API token) on GitHub.com and define an
environment variable `GITHUB_AUTH` with your secret API token.
```bash
export GITHUB_AUTH=XXXXXXXXXXX
```
This is needed to read release information from
https://github.com/OpenModelica/OpenModelica with the PyGithub package.

### Unix

- Install the Python dependencies using `pip3 install -r source/requirements.txt`

### Windows MinGW

- Install `Python 2.7`.
- Install `pip 7.1.2`.
- Install `bibtexparser` using `pip install bibtexparser`.
- Install `gitpython` using `pip install gitpython`.
- Install `sphinx` using `pip install sphinx`.
- Install `sphinxcontrib-bibtex` using `pip install sphinxcontrib-bibtex`.
- Install `sphinxcontrib-inlinesyntaxhighlight` using `pip install sphinxcontrib-inlinesyntaxhighlight`.
- Install `ompython`. See [OpenModelica OMPython instructions](https://github.com/OpenModelica/OMPython#installation) on how to install OMPython.
- Install `pandoc` and make sure it's in PATH.
- Install `gnuplot` and make sure it's in PATH.
- Install `inkscape` and make sure it's in PATH.

## Build instructions
```bash
make html
```
