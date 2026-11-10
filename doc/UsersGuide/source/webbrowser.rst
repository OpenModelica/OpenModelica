.. _webbrowser :

OpenModelica in the Web Browser
===============================

OpenModelica also runs in a web browser, with nothing to install. The compiler
and its clients are compiled to WebAssembly and run on your computer, inside the
browser. The web build of this version of OpenModelica is at

  |playground|

The web build is new and does not have all the features of the desktop version.
It simulates with the WebAssembly simulation target, ``wasm-jit``.

The Clients
-----------

The sidebar of the page opens the clients:

- **OMEdit**, the graphical model editor, see :doc:`omedit`.
- **OMShell**, an interactive session with the compiler, in several variants.
- **Simulator**, a page that edits, simulates and plots one model, shows a 3D
  animation of MultiBody models and exports FMUs.
- **FMI**, a page that simulates FMUs.
- **OMPlot**, a page that plots and compares result files.
- **OMNotebook**, see :ref:`omnotebook`.

Your Files
----------

A file that you open is copied into the memory of the page. To keep your work,
save it to your computer (the browser downloads the file) or to cloud storage.
When you reload or close the page, the files in its memory are lost. The
settings of OMEdit stay in the storage of the browser.

What the Browser Connects To
----------------------------

The browser connects to:

- The web server of the web build. It only sends the files of the build. It
  runs no OpenModelica code and receives no models or results.
- ``libraries.openmodelica.org``, when a page installs a Modelica library. From
  there it downloads the package index, the libraries, and WebAssembly binaries
  for the external functions of some libraries. The browser can install only
  the libraries that are there. The simulator installs the Modelica Standard
  Library when it starts.
- Google Drive or OneDrive, only if you sign in to cloud storage in OMEdit. The
  browser connects directly to Google or Microsoft. Your files and your sign-in
  do not go through an OpenModelica server.

The pages send nothing to other places. Links that you click, for example to
documentation, open other web sites as usual.

Hosting Your Own Copy
---------------------

Each version of the web build is also available as a zip file,
``OpenModelicaCompiler-web-<version>.zip``, at
https://playground.openmodelica.org/. The ``README.md`` in the zip file tells
how to serve it with Python on your own computer or with Apache on a server,
and which files you can change, for example the examples of the simulator. The
same file is `in the OpenModelica repository
<https://github.com/OpenModelica/OpenModelica/blob/master/OMCompiler/Compiler/OpenModelica.rs/wasm/README.md>`__.
