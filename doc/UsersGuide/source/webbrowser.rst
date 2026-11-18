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
- **Files**, your files in ``/persist``, see `Your Files`_.
- **Storage**, what the clients keep in the storage of the browser: installed
  libraries, caches and your files.

Your Files
----------

A file that you open is copied into the memory of the page. When you reload or
close the page, the files in its memory are lost. To keep your work, save it to
your computer (the browser downloads the file), to cloud storage, or to
``/persist``. The settings of OMEdit stay in the storage of the browser.

The files in the folder ``/persist`` stay in the storage of the browser. All
clients see the same files, and a change that one client makes shows at once
in the other clients that are open. Use ``/persist`` for the files that your
models and scripts read and write, for example the data file of a table block:

.. code-block:: modelica

  Modelica.Blocks.Sources.CombiTimeTable table(
    tableOnFile = true, tableName = "tab", fileName = "/persist/table.txt");

In OMShell, ``loadFile("/persist/MyPackage/package.mo")`` loads a package from
there, and a file that omc writes below ``/persist``, for example with
``writeFile``, is kept.

The **Files** page shows ``/persist``. Drop files or folders on the page to
add them. You can also make folders, move, rename and delete files, and
extract .zip files. To save a file to your computer, drag it to your desktop.
**Save folder to...** saves a folder into a folder that you select, or as a
.zip file in browsers that cannot select a folder.

The storage of the browser is not a backup:

- When you clear the data of the site in the browser, or remove it on the
  **Storage** page, your files are deleted.
- When the disk is almost full, the browser can remove the data. On the
  **Storage** page, **Ask the browser to keep this data** asks the browser not
  to do this.
- A private window keeps nothing after you close it.

Save a copy of important files to your computer or to cloud storage.

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
- The server of the language model that you set in the assistant of OMEdit,
  only when you use the assistant, see `The Assistant in OMEdit`_.

The pages send nothing to other places. Links that you click, for example to
documentation, open other web sites as usual.

.. _omedit-web-assistant:

The Assistant in OMEdit
-----------------------

OMEdit in the web browser has an assistant panel on its right side: a chat with
a language model that can use the tools of OMEdit. The model can read the
classes that are loaded, make and change models, and simulate and plot them.
Its changes show in OMEdit at once.

OpenModelica does not supply a language model. You connect the assistant to a
model that you select. Click the gear button of the assistant and set the
provider, the server URL, the API key and the model. **List** gets the models
of the server. The settings and the API key are kept in the storage of the
browser, and the browser sends your messages directly to the server that you
set.

Select a model that supports tool calls. We recommend a model that also accepts
images (a vision or multimodal model): OMEdit is visual, and with **Send
images**, which is on by default, the model sees the diagrams and plots that
the tools return. Turn off **Send images** if the model does not accept images.

A Local Model
~~~~~~~~~~~~~

A model that runs on your computer is free, and your models stay on your
computer. Use the provider **OpenAI-compatible** with a local server, for
example Ollama, llama.cpp (``llama-server``), LM Studio, MLX (``mlx_lm.server``,
on a Mac with Apple silicon) or vLLM. A local server needs no API key, but it
must accept requests from the web page (CORS). For
Ollama, set ``OLLAMA_ORIGINS`` to the address of the web page before you start
it:

.. code-block:: bash

  OLLAMA_ORIGINS=https://playground.openmodelica.org ollama serve
  ollama pull qwen3.8:27b

Then keep the default server URL, ``http://localhost:11434/v1``, and set the
model to ``qwen3.8:27b``. This model works well for Modelica and accepts
images. It is an 18 GB download, and it needs about as much free memory,
preferably on the GPU. Other servers have a similar option; see their
documentation. The browser can ask if the page can connect to devices on your
local network. Allow it. Small models make more mistakes with the tools than
large models.

A Service with an API Key
~~~~~~~~~~~~~~~~~~~~~~~~~

Many services give access to models through an API. You get an API key on the
web site of the service, and usually you pay for each token (the text that the
model reads and writes). Use the provider **Anthropic** for the Anthropic API,
and **OpenAI-compatible** with the server URL of the service for most other
services. Anyone who can use your browser profile can read the API key, so
set a spending limit for the key if the service lets you.

For example, `OpenRouter <https://openrouter.ai>`__ gives access to the models
of many providers, and some of the models are free:

- Provider: **OpenAI-compatible**
- Server URL: ``https://openrouter.ai/api/v1``
- API key: a key from your OpenRouter account
- Model: a model ID from the list, for example one that ends in ``:free``.
  On the OpenRouter web site, you can find the models that support tools and
  image input.

.. warning::

  Most free models are free because the provider can keep your prompts, and
  the models and data that the tools send, and use them to train models. Do not
  send what you must keep secret, and read the terms of the service first.
  Services, their free models and their terms change often. A service in this
  guide can change its terms or stop at any time.

A subscription to a chat service, for example a monthly plan for ChatGPT,
Claude or Gemini, usually does not include API tokens. The API is sold
separately, with its own key. Thus you cannot connect a subscription to the
assistant through the OpenAI-compatible interface. In the future, it can
become possible through WebMCP, when more chat applications support it.

WebMCP
~~~~~~

`WebMCP <https://github.com/webmachinelearning/webmcp>`__ is a proposed web
standard that lets a web page give tools to an AI agent in the browser. When
the browser supports WebMCP, OMEdit registers its tools there. A browser
extension or a browser with an agent can then use OMEdit with its own chat and
model, instead of the assistant panel, which then needs no settings. The
models and data that the tools return go to the agent and to its service,
under the terms of that service.

Few browsers support WebMCP yet. Some have it as an experimental feature that
you must turn on, and some extensions add it. Reload OMEdit after you install
such an extension. Through WebMCP the tools return only text: the agent gets no
images of diagrams and plots, and not the tools that load files and libraries
and reset OMEdit.

Hosting Your Own Copy
---------------------

Each version of the web build is also available as a zip file,
``OpenModelicaCompiler-web-<version>.zip``, at
https://playground.openmodelica.org/. The ``README.md`` in the zip file tells
how to serve it with Python on your own computer or with Apache on a server,
and which files you can change, for example the examples of the simulator. The
same file is `in the OpenModelica repository
<https://github.com/OpenModelica/OpenModelica/blob/master/OMCompiler/Compiler/OpenModelica.rs/wasm/README.md>`__.
