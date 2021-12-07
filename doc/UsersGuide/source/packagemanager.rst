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
<https://specification.modelica.org/maint/3.5/annotations.html#version-handling>`_ at the top level. For example, if you
drag and drop components from MSL 4.0.0 into models of your package, the ``annotation(uses(Modelica(version="4.0.0")));``
will be added automatically to it. This information allows OpenModelica to automatically load all the libraries
that are required to compile the models in your own package next time you (or someone else, possibly on a different
computer) loads your package, provided they are installed in places on the computer's file system where OpenModelica
can find them.

The default place where OpenModelica looks for packages is the so-called
`MODELICAPATH <https://specification.modelica.org/maint/3.5/packages.html#the-modelica-library-path-modelicapath>`_.
You can check where it is by typing ``getModelicaPath()`` in the Interactive Environment. Installed
read-only libraries are placed by default in the MODELICAPATH.

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

The Open Source Modelica Consortium (OSMC) maintains a collection of publicly available, open-source Modelica packages
on its servers. They are routinely tested with past released versions of OpenModelica, as well as with the current development
version on the master branch, see the `overview report <https://libraries.openmodelica.org/branches/overview-combined.html>`_.
Based on the testing results and on information gathered from the library developers, these packages are classified
in terms of level of support in OpenModelica. Backwards-compatibility information is also collected from the
conversion annotations.

The OpenModelica Package Manager relies on this information to install the best versions of the library dependencies of your
own Modelica packages. It can be run both from the OMEdit GUI and from the command-line interactive environment.

Note that the Package Manager may install multiple builds of the same library version on your PC, if they are indexed on the
OSMC servers. When this happens, they are distinguished among each other by means of
`semver <https://https://semver.org/#semantic-versioning-specification-semver>`_-style pre- or post-release metadata in the
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

Package Management in OMEdit
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TBD: Show how to install new packages and manage installed ones

Running Conversion Scripts in OMEdit
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
TBD: Show how to run conversion scripts in OMEdit

Automatically Loaded Packages in OMEdit
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
When you start OMEdit, some packages are automatically loaded into the environment, and shown in the Libraries
Browser. You can configure which ones are loaded from the Tools|Options|Libraries menu.

Please note that automatically loaded libraries may be in conflict with the dependencies of packages that you may
then load from the File menu. For example, if you automatically load MSL ``4.0.0``, and then open a library that
uses MSL ``3.2.3``, you get a conflict, because the former is not backwards-compatible with the latter. In this
case you have three options:

- cancel the operation;
- unload the conflicting library, i.e., MSL ``4.0.0``, and load the most recent one compatible with the one
  declared in the uses annotation of the opened library, i.e., MSL ``3.2.3``;
- upgrade the library you just opened to use the already loaded one, i.e. MSL ``4.0.0``, by running the automatic
  conversion script; note that this operation is irreversible and must be carefully planned, considering all the
  users of the library that is undergoing automatic conversion.

Manually Loading Packages
^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to maintain full control over which libraries are opened, you can use the File | Open Model/Library Files(s)
menu command in OMEdit to open the libraries one by one from specific locations in your file system. Note,
however, that whenever a library is loaded, its dependencies as declared in the uses annotation will automatically
be loaded. If you want to avoid that, you need to load the library dependencies in reverse order, so that the
intended library dependencies are already loaded when you open the library that needs them.

If you are using the Interactive Environment, you can use the ``loadFile()`` command to load libraries from
specific locations on the file system, also in reverse dependency order, unless you also set the optional
``uses = false`` input argument to disable the automatic loading of dependencies.

Using the Package Manager from the Interactive Environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The Package Manager can also be used from the Interactive Environment command line shell. Here is a list
of examples of relevant commands; please type them followed by ``getErrorString()``,
e.g., ``updatePackageIndex();getErrorString()``, in order to get additional information,
notifications and error messages.

- ``updatePackageIndex()``: this command puts the Package Manager in contact with the OSMC servers and updates
    the internally stored list of available packages;
- ``getAvailablePackageVersions(Buildings, "")``: lists all available versions of the Buildings library on the OSMC server,
   starting from the most recent one, in descending order of priority. Note that pre-release versions have lower priority
   than all other versions;
- ``getAvailablePackageVersions(Buildings, "7.0.0")``: lists all available versions of the Buildings library on
   the OSMC server that are backwards-compatible with version ``7.0.0``, in descending order of priority;
- ``installPackage(Buildings, "")``:install the most recent version of the Building libraries, *and all its dependencies*;
- ``installPackage(Buildings, "7.0.0")``: install the most recent version of the Building libraries which is backwards-compatible
    with version ``7.0.0``, *and all its dependencies*;
- ``installPackage(Buildings, "7.0.0", exactMatch = true)``: install version ``7.0.0`` even if there are more recent
    backwards-compatible versions available, *and all its dependencies*;
- ``upgradeInstalledPackages(installNewestVersions = true)``: installs the latest available version of all installed packages.

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
