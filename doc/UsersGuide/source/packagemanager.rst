.. _packagemanagement :

Package Management
==================

Overview of Basic Modelica Package Management Concepts
------------------------------------------------------

The Modelica language promotes the orderly reuse of component models by means of packages  that contain
structured libraries of reusable models. The most prominent example is the Modelica Standard Library (MSL),
that contains basic models covering many fields of engineering. Other libraries, both open-source and
commercial, are available to cover specific applications domains.

When you start a simulation project using Modelica, it is common practice to collect all related system models
in a project-specific package that you develop. The models in this package are often instantiated (e.g. by drag-and-drop
in OMEdit) from released libraries, which are read-only for your project. This establishes a dependency between your
project package and a certain version of a read-only package (or library), which is the one you have loaded in OMEdit
and that you drag-and-drop components from.

This dependency is automatically marked in your package by adding a `uses annotation
<https://specification.modelica.org/maint/3.6/annotations.html#version-handling>`_ at the top level. For example, if you
drag and drop components from MSL 4.0.0 into models of your package, the ``annotation(uses(Modelica(version="4.0.0")));``
will be added automatically to it. This information allows OpenModelica to automatically load all the libraries
that are required to compile the models in your own package next time you (or someone else, possibly on a different
computer) loads your package, provided they are installed in places on the computer's file system where OpenModelica
can find them.

The default place where OpenModelica looks for packages is the so-called
`MODELICAPATH <https://specification.modelica.org/maint/3.6/packages.html#the-modelica-library-path-modelicapath>`_.
You can check where it is by typing ``getModelicaPath()`` in the Interactive Environment (Tools | OpenModelica Compiler CLI in OMEdit).
Installed read-only libraries are all placed by default in the MODELICAPATH.

However, when you open a package from the file system, before looking into MODELICAPATH, OpenModelica will first look for
packages it depends upon in the same directory that contains the package you just opened. For example, if you open
``/home/John/ModelicaPackages/MoonShot/package.mo``, and your MoonShot package contains ``annotation(uses(Rockets));``,
before looking into MODELICAPATH, OpenModelica will try to load ``/home/John/ModelicaPackages/Rockets/package.mo`` or
``/home/John/ModelicaPackages/Rockets.mo``, if the package is stored in a single file. So, if you are developing
several packages with dependencies among them, you can place them in the same common root directory to make sure
that all the dependencies are loaded automatically. 

Please note that if the ``uses`` annotation refers to a specific version of a package, that package will only be loaded
if the name of the directory or of the single file that contains it also indicates the version number. For example,
if MoonShot contains ``annotation(uses(Rockets(version = "2.0.0"));``, OpenModelica will try to load
``/home/John/ModelicaPackages/Rockets 2.0.0/package.mo`` or ``/home/John/ModelicaPackages/Rockets 2.0.0.mo``;
in this case, packages without the version number in their root directory, such as 
``/home/John/ModelicaPackages/Rockets/package.mo``, will be ignored. All installed packages in the MODELICAPATH
include version numbers in their directory name, which also allows to install multiple versions of the same library.

When a new version of certain package comes out, `conversion annotations
<https://specification.modelica.org/maint/3.5/annotations.html#version-handling>`_ in it declare whether your models using
a certain older version of it can be used as they are with the new one, which is then 100% backwards-compatible, or whether
they need to be upgraded by running a conversion script, provided with the new version of the package. The former case
is declared explicitly by a ``conversion(noneFromVersion)`` annotation. For example, a ``conversion(noneFromVersion="3.0.0")``
annotation in version ``3.1.0`` of a certain package means that all packages using version ``3.0.0`` can use ``3.1.0``
without any change. Of course it is preferrable to use a newer, backwards-compatible version, as it contains bugfixes
and possibly new features.

Hence, if you install a new version of a library which is 100% backwards-compatible with the previous ones, all your models that
used the old one will automatically load and use the new one, without the need of any further action.

If the new version is not backwards-compatible, instead, you will need to create a new version of
your library that uses it, by running the provided conversion scripts.

OpenModelica has a package manager that can be used to install and update libraries on your computer, and is able to run
conversion scripts. Keep in mind there are three stages in package usage: *available* packages are indexed on the
OSMC servers and can be downloaded from public repositories;
*installed* packages are stored in the MODELICAPATH of your computer; *loaded* packages are loaded in memory
in an active OMC session, either via the Interactive Environment, or via the OMEdit GUI, where they are shown in the
Libraries Browser. When you load a package, OpenModelica tries to load the best possible installed versions of all
the dependencies declared in the uses annotation.

The Package Manager
-------------------

The Open Source Modelica Consortium (OSMC) maintains a collection of publicly available, open-source Modelica libraries
on its servers, see https://github.com/OpenModelica/OMPackageManager. These libraries are routinely tested with past
released versions of OpenModelica, as well as with the current development version on the master branch, see
the `overview report <https://libraries.openmodelica.org/branches/overview-combined.html>`_.
Based on the testing results and on information gathered from the library developers, these packages are classified
in terms of level of support in OpenModelica. Backwards-compatibility information is also collected from the
conversion annotations.

The OpenModelica Package Manager relies on this information to install the best versions of the library dependencies of your
own, locally developed Modelica packages and models. It can be run both from the OMEdit GUI and from the command-line interactive environment. The libraries
and their ``index.json`` index file with all the library metadata are installed in the ``~/.openmodelica/libraries`` directory under
Linux and in the ``%AppData%\.openmodelica\libraries`` directory on Windows. Note that these directories are user-specific, so if there are
multiple users on the same computer, each of them will install and manage his/her own set of libraries independently from the others.

The Package Manager may install multiple builds of the same library version in your own package manager directory,
if they are indexed on the OSMC servers. When this happens, they are distinguished among each other by means of
`semver <https://semver.org/#semantic-versioning-specification-semver>`_-style pre- or post-release metadata in the
top directory name on the file system. Post-release builds are denoted by a plus sign (e.g. ``2.0.0+build.02``)
and have higher priority over the corresponding plain release
(e.g. ``2.0.0``), while pre-release builds are denoted by a minus sign (e.g. ``2.0.0-dev.30``) and have a lower priority.

When loading a certain version of a library, unless a specific build is explicitly referenced, the one with higher
precedence will always be loaded. For example, if the versions ``2.0.0-beta.01``, ``2.0.0``, and ``2.0.0+build.01``
are installed, the latter is loaded by libraries with uses annotation requiring version ``2.0.0``. Unless, of course,
there are later backwards-compatible versions installed, e.g., ``2.0.1``, in which case the one with the highest release
number and priority is installed.

In any case, semver version semantics is only used to order the releases, while backwards-compatibility
is determined exclusively on the basis of ``noneFromVersion`` annotations.

When installing OpenModelica, a cached version of the latest versions of the Modelica Standard Library is included in the
installation files. As soon as a user starts any OpenModelica tool (e.g., OMEdit, OMNotebook, OMShell, or direct command-line
invocation of omc), if the user's ``.openmodelica`` directory is empty the Modelica Standard Library will be installed
automatically using this cached version. This happens when using OpenModelica for the first time, or if the contents of the
``.openmodelica`` directory have been deleted to get rid of all installed libraries. This automatic installation needs no
Internet connection, so it also works behind firewalls or in set-ups with limited available bandwidth. Therefore, the Modelica
Standard Library is immediately available without the need of using the package manager explicitly. It is then possible
to install and manage other libraries using the package manager, as explained previously.

As a final remark, please note that the version numbers of the various Modelica packages have no relation with the version
numbers of the OpenModelica tool itself. Since version 1.19.0, OpenModelica is no longer shipped with built-in installed
libraries, that are instead managed independently by the user with the online Package Manager. You can install and use old and new
versions of a certain open source Modelica library using the latest released version of OpenModelica, by using the
Package Manager. We strive to make sure that new released versions of OpenModelica are backwards-compatible, meaning that you should
always be able to run the same models/libraries with a new version of OpenModelica if you could with an older version of the
tool. Hence, we strongly advise you to always use the latest released version of OpenModelica, even if you are running old
models; by doing so, you benefit from faster performance, more robust numerical performance, new tool features, and a
lot of bug fixes.

You should never find yourself in a situation where you are forced to stick to an old version of OpenModelica to run your models.
If that happens to you, please open a ticket on the `issue tracker <https://github.com/OpenModelica/OpenModelica/issues/new/choose>`_, so we can hopefully fix the problem and allow you to keep using the latest OpenModelica release.

Package Management in OMEdit
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

:ref:`Installing a new library in OMEdit <omedit-install-library-label>`.

Running Conversion Scripts in OMEdit
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

:ref:`Converting a library in OMEdit <omedit-convert-library-label>`.

Automatically Loaded Packages in OMEdit
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

When you start OMEdit, some packages can be automatically loaded into the environment, and shown in the Libraries
Browser. You can configure which ones are loaded from the Tools|Options|Libraries menu.

Please note that automatically loaded libraries may be in conflict with the dependencies of packages that you may
later load from the File menu. For example, if you automatically load Modelica ``4.0.0``, and then load a library XYZ that
still uses MSL ``3.2.3``, you get a conflict, because Modelica ``4.0.0`` is not backwards-compatible with Modelica ``3.2.3``,
so XYZ cannot be used.

In this case you have two options:

- Cancel Operation: this means XYZ is not actually loaded, and all previously loaded libraries remain in place.
- Unload all and Reload XYZ: in this case, all previously loaded libraries, that may generate conflicts, are unloaded first;
  then XYZ is loaded, and finally the right versions of the libraries XYZ uses, as declared in its ``uses`` annotation,
  will be loaded automatically.

If you are normally working with only one version of the Modelica standard library, you can set it to be automatically loaded
from the Tools|Options|Libraries menu; in case you need to work with a library that uses a previous, non-backwards compatible
version, the Unload all and Reload option comes handy. Otherwise, you can avoid loading the Modelica library automatically
upon starting OMEdit, and let the right version of the Modelica library be loaded automatically when you open the library you
want to work with. In this case, if you want to get the Modelica library into the Package Browser to start developing a new library,
you can do so easily from the Welcome tab, by clicking on the System Libraries button and selecting the version that you want to load.

Manually Loading Packages
^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to maintain full control over which library dependencies are loaded, you can use the File | Open Model/Library Files(s)
menu command in OMEdit to open the libraries one by one from specific locations in your file system. Note,
however, that whenever a library is loaded, its dependencies, that are declared in its ``uses`` annotation, will automatically
be loaded. If you want to avoid that, you need to load the library dependencies in reverse order, so that the
intended library dependencies are already loaded when you open the library that needs them.

If you are using the Interactive Environment, you can use the ``loadFile()`` command to load libraries from
specific locations on the file system, also in reverse dependency order, unless you also set the optional
``uses = false`` input argument to disable the automatic loading of dependencies.

Using the Package Manager from the Interactive Environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The Package Manager can also be used from the Interactive Environment command line shell. Here is a list
of examples of relevant commands; please type them followed by :ref:`getErrorString() <getErrorString>`,
e.g., :ref:`updatePackageIndex() <updatePackageIndex>`; :ref:`getErrorString() <getErrorString>`, in order to get additional information,
notifications and error messages.

- :ref:`updatePackageIndex() <updatePackageIndex>` - this command puts the Package Manager in contact with the OSMC servers and updates
  the internally stored list of available packages;
- :ref:`getAvailablePackageVersions(Building, "") <getAvailablePackageVersions>` - lists all available versions of the Buildings library on the OSMC server,
  starting from the most recent one, in descending order of priority. Note that pre-release versions have lower priority
  than all other versions;
- :ref:`getAvailablePackageVersions(Building, "7.0.0") <getAvailablePackageVersions>` - lists all available versions of the Buildings library on
  the OSMC server that are backwards-compatible with version ``7.0.0``, in descending order of priority;
- :ref:`installPackage(Buildings, "") <installPackage>` - install the most recent version of the Building libraries, *and all its dependencies*;
- :ref:`installPackage(Buildings, "7.0.0") <installPackage>` - install the most recent version of the Building libraries which is backwards-compatible
  with version ``7.0.0``, *and all its dependencies*;
- :ref:`installPackage(Buildings, "7.0.0", exactMatch = true) <installPackage>` - install version ``7.0.0`` even if there are more recent
  backwards-compatible versions available, *and all its dependencies*;
- :ref:`upgradeInstalledPackages(installNewestVersions = true) <upgradeInstalledPackages>` - installs the latest available version of all installed packages.

How the package index works
---------------------------

The package index is generated by `OMPackageManager <https://github.com/OpenModelica/OMPackageManager>`_ on an OSMC server,
based on `these settings <https://github.com/OpenModelica/OMPackageManager/blob/master/repos.json>`_.
See its documentation to see how to add new packages to the index, change support level, and so on.

The index is generated by scanning git repositories on github.
All tags and optionally some specific branches are scanned.
The tag name is parsed as if it was a semantic version, with prerelease and metadata of the tag added to the version of Modelica packages in the repository.
If the tag name is not a semantic version, it is sorted differently.

Packages are sorted as follows:

* Support level: each package is given a level of support in the index
* Semantic version: according to the semver specification, but build metadata is also considered (sorted the same way as pre-releases)
* Non-semantic versions: alphabetically
