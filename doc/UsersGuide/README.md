# Users Guide
OpenModelica users guide using Sphinx (Python Documentation Generator).

## Dependencies
 - Inkscape
 - Sphinx
 - Python3 and packages from [requirements.txt](https://raw.githubusercontent.com/OpenModelica/OpenModelica-doc/master/UsersGuide/source/requirements.txt)

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
- Install `pandoc` and make sure its in PATH.
- Install `gnuplot` and make sure its in PATH.
- Install `inkscape` and make sure its in PATH.

## Build instructions
```bash
make html
```
