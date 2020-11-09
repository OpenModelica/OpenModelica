---
name: Bug report
about: "Create a report to help us improve \U0001F680 "
title: Title
labels: ''
assignees: ''

---

### Description
A clear and concise description of what the bug is.

### Steps to reproduce
Steps to reproduce the behavior:
This could either be a list of actions or a Modelica script file (mos) that uses the [OpenModelica scripting API](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/scripting_api.html).

We really 💖 minimal working examples. With these reproducing a bug is straightforward and we can respond faster.

Example minimalExample.mos:
```modelica
getVersion(); getErrorString();
loadModel(Modelica,{"4.0"}); getErrorString();
simulate(Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum); getErrorString();
```
Run with `$ omc minimalExample.mos` on your favourit unix-like shell or use CMD `>"C:\Program Files\OpenModelica1.17.0-dev-64bit\bin\omc.exe" minimalExample.mos`

### Expected behavior
A clear and concise description of what you expected to happen.

### Screenshots
If applicable, add screenshots to help explain your problem.

### Version and OS
 - OS: [e.g. Windows 10, 64 bit]
 - Version [run `omc --version` or check `Help->About OMEdit` from OMEdit]

### Additional context
Add any other context about the problem here.
