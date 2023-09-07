MDT - The OpenModelica Development Tooling Eclipse Plugin
=========================================================

.. role:: bash(code)
   :language: bash

Introduction
------------

The Modelica Development Tooling (MDT) Eclipse Plugin as part of OMDev -
The OpenModelica Development Environment integrates the OpenModelica
compiler with Eclipse. MDT, together with the OpenModelica compiler,
provides an environment for working with Modelica and MetaModelica
development projects. This plugin is primarily intended for tool
developers rather than application Modelica modelers.

The following features are available:

-  Browsing support for Modelica projects, packages, and classes

-  Wizards for creating Modelica projects, packages, and classes

-  Syntax color highlighting

-  Syntax checking

-  Browsing of the Modelica Standard Library or other libraries

-  Code completion for class names and function argument lists

-  Goto definition for classes, types, and functions

-  Displaying type information when hovering the mouse over an
   identifier.

Installation
------------

The installation of MDT is accomplished by following the below
installation instructions. These instructions assume that you have
successfully downloaded and installed Eclipse (http://www.eclipse.org).

The latest installation instructions are available through the `OpenModelica Trac <https://trac.openmodelica.org/MDT>`_.

1. Start Eclipse

2. Select Help->Software Updates->Find and Install.\ **..** from the
   menu

3. Select 'Search for new features to install' and click 'Next'

4. Select 'New Remote Site...'

5. Enter 'MDT' as name and
   http://www.ida.liu.se/labs/pelab/modelica/OpenModelica/MDT
   as URL and click 'OK'

6. Make sure 'MDT' is selected and click 'Finish'

7. In the updates dialog select the 'MDT' feature and click 'Next'

8. Read through the license agreement, select 'I accept...' and click
   'Next'

9. Click 'Finish' to install MDT

Getting Started
---------------

Configuring the OpenModelica Compiler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MDT needs to be able to locate the binary of the compiler. It uses the
environment variable OPENMODELICAHOME to do so.

If you have problems using MDT, make sure that OPENMODELICAHOME is
pointing to the folder where the OpenModelica Compiler is installed. In
other words, OPENMODELICAHOME must point to the folder that contains the
Open Modelica Compiler (OMC) binary. On the Windows platform it's called
omc.exe and on Unix platforms it's called omc.

Using the Modelica Perspective
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The most convenient way to work with Modelica projects is to use to the
Modelica perspective. To switch to the Modelica perspective, choose the
Window menu item, pick Open Perspective followed by Other\ **...**
Select the Modelica option from the dialog presented and click OK..

Selecting a Workspace Folder
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Eclipse stores your projects in a folder called a workspace. You need to
choose a workspace folder for this session, see :numref:`mdt-switch-workspace`.

.. figure :: media/mdt-switch-workspace.png
  :name: mdt-switch-workspace

  Eclipse Setup - Switching Workspace.

Creating one or more Modelica Projects
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To start a new project, use the New Modelica Project Wizard. It is
accessible through File->New-> Modelica Project or by right-clicking in
the Modelica Projects view and selecting New->Modelica Project.

.. figure :: media/mdt-create-project.png

  Eclipse Setup - creating a Modelica project in the workspace.

You need to disable automatic build for the project(s) (:numref:`mdt-disable-automatic-build`).

.. figure :: media/mdt-disable-automatic-build.png
  :name: mdt-disable-automatic-build

  Eclipse Setup - disable automatic build for the projects.

Repeat the procedure for all the projects you need, e.g. for the
exercises described in the MetaModelica users guide: 01\_experiment,
02a\_exp1, 02b\_exp2, 03\_assignment, 04a\_assigntwotype, etc.

NOTE: Leave open only the projects you are working on! Close all the
others!

Building and Running a Project
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After having created a project, you eventually need to build the project
(:numref:`mdt-build-project`).

.. figure :: media/mdt-build-project.png
  :name: mdt-build-project

  Eclipse MDT - Building a project.

The build options are the same as the make targets: you can build,
build from scratch (clean), or run simulations depending on how the
project is setup. See :numref:`mdt-build-prompt` for an example of how omc
can be compiled (:bash:`make omc` builds OMC).

.. figure :: media/mdt-build-prompt.png
  :name: mdt-build-prompt

  Eclipse - building a project.

.. figure :: media/mdt-build-log.png

  Eclipse - building a project, resulting log.

Switching to Another Perspective
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you need, you can (temporarily) switch to another perspective, e.g.
to the Java perspective for working with an OpenModelica Java client as
in :numref:`mdt-switch-perspective`.

.. figure :: media/mdt-switch-perspective.png
  :name: mdt-switch-perspective

  Eclipse - Switching to another perspective - e.g. the Java Perspective.

Creating a Package
~~~~~~~~~~~~~~~~~~

To create a new package inside a Modelica project, select
File->New->Modelica Package\ **.** Enter the desired name of the package
and a description of what it contains. Note: for the exercises we
already have existing packages.

.. figure :: media/mdt-create-package.png

  Creating a new Modelica package.

Creating a Class
~~~~~~~~~~~~~~~~

To create a new Modelica class, select where in the hierarchy that you
want to add your new class and select File->New->Modelica Class. When
creating a Modelica class you can add different restrictions on what the
class can contain. These can for example be model, connector, block,
record, or function. When you have selected your desired class type, you
can select modifiers that add code blocks to the generated code.
'Include initial code block' will for example add the line 'initial
equation' to the class.

.. figure :: media/mdt-create-class.png

  Creating a new Modelica class.

Syntax Checking
~~~~~~~~~~~~~~~

Whenever a build command is given to the MDT environment, modified and
saved Modelica (.mo) files are checked for syntactical errors. Any
errors that are found are added to the Problems view and also marked in
the source code editor. Errors are marked in the editor as a red circle
with a white cross, a squiggly red line under the problematic construct,
and as a red marker in the right-hand side of the editor. If you want to
reach the problem, you can either click the item in the Problems view or
select the red box in the right-hand side of the editor.

.. figure :: media/mdt-syntax-checking.png

  Syntax checking.

Automatic Indentation Support
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MDT currently has support for automatic indentation. When typing the
Return (Enter) key, the next line is indented correctly. You can also
correct indentation of the current line or a range selection using
CTRL+I or “Correct Indentation” action on the toolbar or in the Edit
menu.

Code Completion
~~~~~~~~~~~~~~~

MDT supports Code Completion in two variants. The first variant, code
completion when typing a dot after a class (package) name, shows
alternatives in a menu. Besides the alternatives, Modelica documentation
from comments is shown if is available. This makes the selection easyer.

.. figure :: media/mdt-code-completion.png

  Code completion when typing a dot.

The second variant is useful when typing a call to a function. It shows
the function signature (formal parameter names and types) in a popup
when typing the parenthesis after the function name, here the signature
Real sin(SI.Angle u) of the sin function:

.. figure :: media/mdt-code-completion-call.png

  Code completion at a function call when typing left parenthesis.

Code Assistance on Identifiers when Hovering
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When hovering with the mouse over an identifier a popup with information
about the identifier is displayed. If the text is too long, the user can
press F2 to focus the popup dialog and scroll up and down to examine all
the text. As one can see the information in the popup dialog is
syntax-highlighted.

.. figure :: media/mdt-info-on-hover.png

  Displaying information for identifiers on hovering.

Go to Definition Support
~~~~~~~~~~~~~~~~~~~~~~~~

Besides hovering information the user can press CTRL+click to go to the
definition of the identifier. When pressing CTRL the identifier will be
presented as a link and when pressing mouse click the editor will go to
the definition of the identifier.

Code Assistance on Writing Records
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When writing records, the same functionality as for function calls is
used. This is useful especially in MetaModelica when writing cases in
match constructs.

.. figure :: media/mdt-assist-mm-record.png

  Code assistance when writing cases with records in MetaModelica.

Using the MDT Console for Plotting
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. figure :: media/mdt-console.png

  Activate the MDT Console.

.. figure :: media/mdt-console-simulate.png

  Simulation from MDT Console.
