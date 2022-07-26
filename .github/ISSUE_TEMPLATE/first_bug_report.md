---
name: First Bug Report
about: Detailed guideline for your first bug report
title: ''
labels: ''
assignees: ''

---

### Description
A clear and concise description of what the bug is.

### Steps to reproduce
Please provide us with enough information to reproduce the issue on our side, otherwise it's hard to fix it. You can either provide a list of actions, or possibly attach a Modelica script file (mos) that uses the [OpenModelica scripting API](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html).

Example script `reproduceBug.mos`:
```modelica
getVersion(); getErrorString();
loadModel(Modelica,{"4.0"}); getErrorString();
loadFile("path/to/MyLibrary");getErrorString();
setCompilerFlags("-d=optdaedump");getErrorString();
simulate(MyLibrary.MyModel); getErrorString();
```
You need to run the script from the command line interface. On Linux, you can use your favourite shell, cd to the directory where the .mos file is located and run
```
$ omc reproduceBug.mos
```
On Windows, start the command line interface (right-click on the start menu, then run the CMD program), cd to the directory where the .mos file is located and type
```
C:\MyDirectory>"C:\Program Files\OpenModelica1.18.0\bin\omc.exe" reproduceBug.mos
```
You may need to adapt the path based on the actual installed version of OpenModelica.

We really 💖 [minimal working examples](https://en.wikipedia.org/wiki/Minimal_working_example). If you can provide a MWE that shows the problem, instead of your original model, reproducing the bug is more straightforward and we can respond faster.

### Expected behavior
A clear and concise description of what you expected to happen.

### Screenshots
If applicable, add screenshots to help explain your problem.

### Additional files
You can add additional files via drag-and-drop, e.g. for your minimal working example. Please note that GitHub does not accept .mo and .mos attachments, so you can either zip the example files and attach the .zip file, or add .txt to the extension of a simple .mo or .mos file.

You can also use `File->Save Total` in OMEdit to save a model and all its dependencies to a single file, so you don't need to provide all the libraries you are using. If your model is sensitive or confidential, you can use the obfuscation option, that removes all documentation and scrambles the variable names, preventing reverse-engineering.

### Version and OS
 - OpenModelica Version [run `omc --version` or check `Help->About OMEdit` from OMEdit]
 - Versions of used Modelica libraries if applicable
 - OS: [e.g. Windows 10, 64 bit]

### Additional context
Add any other context about the problem here.
