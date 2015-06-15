How to edit reST
================

Above is how to mark a chapter heading.
The next levels use dashes (-), tilde (~), and circumflex (^).
Really, any format works, but this is the default for editing the
OpenModelica User's Guide (except for some files that include other
rst-files, where other characters are used).

Syntax highlighting and running commands
----------------------------------------

In order to mark something as code, use \`some code\`, i.e. `some code`.
It is also possible to mark commands being run:

  >>> 1+1
  2

You can create a code block that is syntax-highlighted according to the
programming language of your choice by using a code-block block.

.. code-block :: modelica

  model M
    Real r(start=0, fixed=true);
  equation
    der(r) = 1.0;
  end M;

It is also possible to load a model into OMC.

.. omc-loadString ::

  model M
    Real r(start=2, fixed=true);
  equation
    der(r) = -r^2;
  end M;

You can then run the commands using the omc-mos block. It takes the same
options as a code-block (on the generated code). It also takes a few
custom options:

noerror
  Does not call getErrorString after each command.
clear
  Calls clear() before the first command.
parsed
  Uses the OMPython parser to create Python data types instead of strings.
combine-lines
  Used to merge multiple lines of input into a single command.
erroratend
  Calls getErrorString at the end, generating a sphinx Error box.
hidden
  Does not generate output (can be used to generate some data for later
  inclusion.
ompython-output
  Special commands for generating OMPython documentation.

.. omc-mos ::
  :name: simulate-command
  :caption: A simulate command.

  simulate(M, stopTime=10)

You can also plot the generated results using an omc-gnuplot block.
This takes one argument (the name to use for the generated plot), and
has a few custom options:

filename
  The path of the file to plot (default: last successful simulation)
caption
  Generates a caption for the plot figure.
name
  Generates a label for the plot figure.
parametric
  Do a parametric plot.
plotall
  Plot all variables.

.. omc-gnuplot :: aplot
  :caption: A plot.
  :name: plot

  r

At the end of the page, restart OMPython to ensure that the same results
are given every time you compile the document.

.. omc-reset ::

.. _cross-refs :

Cross-References
----------------

It is possible to references figures and sections given that there is a
label. Reference sections such as :ref:`cross-refs` using the ref role.
Figures, Tables, and Listings can be referenced using the ref and numref
roles :ref:`plot` is :numref:`plot`. :ref:`simulate-command` refers to
:numref:`simulate-command`.

Marking a word for the index is simple; use the index role.
:index:`cross-reference`.
