# User's Guide

OpenModelica User's Guide using Sphinx (Python Documentation Generator).

## Dependencies

Getting all dependencies right is a nightmare. Just use the dev container
`build-deps:v1.22.0` from
[.devcontainer/README.md](./../../.devcontainer/README.md) and set
`GITHUB_AUTH`.

- omc, omc-diff and omsimulator
- Inkscape > v1.0
- [Sphinx](http://sphinx-doc.org/)
- pandoc
- gnuplot
- Python3 and packages from [source/requirements.txt](./source/requirements.txt)

   ```bash
   pip install --upgrade -r source/requirements.txt
   ```

- Python PyGithub package

   ```bash
   pip install PyGithub
   ```

### GITHUB_AUTH

Create a read-only personal access token (API token) on GitHub.com and define an
environment variable `GITHUB_AUTH` with your secret API token.

```bash
export GITHUB_AUTH=XXXXXXXXXXX
```

This is needed to read release information from
<https://github.com/OpenModelica/OpenModelica> with the PyGithub package.

## Build instructions

```bash
make html
```

## Preview build

```bash
python -m http.server --directory build/html
```
