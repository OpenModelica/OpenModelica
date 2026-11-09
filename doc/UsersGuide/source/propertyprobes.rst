.. _property-probes :

Property Probes and CodeProber
==============================

`CodeProber <https://github.com/lu-cs-sde/codeprober>`_, from Lund University,
is a *property probing* tool: it shows the source code of a program in a
browser editor, and a right-click on any part of it creates a *probe*, a small
window with a property of that part, as the compiler computes it. Probes stay
open and are updated whenever the code is edited, so they show live how a
change affects what the compiler does with the code.

OpenModelica provides what such a tool needs through two scripting functions:

-  :ref:`getProbeTree <getProbeTree>` returns the *probe tree* of a file: its
   classes, elements, equations, statements and names, with their positions in
   the file and the properties that can be asked for each of them.

-  :ref:`evaluateProbe <evaluateProbe>` evaluates one property of one node of
   that tree.

All the knowledge is in omc. A client, like the CodeProber one, only maps the
tree and the results to its user interface, so a new property only has to be
added to the compiler.

The Probe Tree
--------------

The tree follows the structure of the parsed file. Its nodes have a ``kind``:
``StoredDefinition`` (the file), ``ClassDefinition``, ``ComponentDeclaration``,
``ComponentClause`` (several components declared together),
``ExtendsClause``, ``ImportClause``, ``Equation`` and ``Statement``, and the
names in them, declared or used, are ``Ident`` leaves. Every node has an
``id``, the indices of the children on the way from the root, e.g.
``0.0.2.3`` for the fourth element of the third class of the first class of the
file, its span in the file, and the names of its ``properties``. For a file
that does not parse, ``root`` is ``null`` and ``errors`` has the syntax errors.

The file has to be loaded first. The examples below use a small circuit,
ProbeCircuit.mo:

.. literalinclude :: ProbeCircuit.mo
  :language: modelica
  :linenos:

.. omc-mos ::
  :hidden:

  system("cp ../source/ProbeCircuit.mo .")
  loadFile("ProbeCircuit.mo")

``getProbeTree("ProbeCircuit.mo", prettyPrint = true)`` returns the tree as JSON.
This is the node of the equation ``p.v - n.v = r*p.i`` of ``R``, with only the
first of its seven children, the ``Ident`` of the first ``p``:

.. code-block :: json

  {
    "id": "0.0.2.3",
    "kind": "Equation",
    "label": "=",
    "lineStart": 10,
    "columnStart": 5,
    "lineEnd": 10,
    "columnEnd": 22,
    "properties": ["simEquations", "jacobianEquations", "bltBlock", "cCode", "text", "hover"],
    "children": [
      {
        "id": "0.0.2.3.0",
        "kind": "Ident",
        "label": "p",
        "lineStart": 10,
        "columnStart": 5,
        "lineEnd": 10,
        "columnEnd": 5,
        "properties": ["definition", "role", "text", "hover"],
        "children": []
      }
    ]
  }

Properties
----------

``evaluateProbe(fileName, nodeId, property, contextModel)`` returns the
property as a JSON list of items. An item is a ``text``, a ``node`` (a link to
another node of the tree), a diagnostic (``severity``, span and ``message``)
or an ``arrow`` between two spans.

.. omc-mos ::
  :parsed:

  evaluateProbe("ProbeCircuit.mo", "0.0.5.4", "connectionEquations")

The properties are:

-  On every node: ``text`` and ``hover``.

-  On the file: ``errors`` (names that cannot be found and the messages of
   :ref:`checkModel <checkModel>` of its models, at their positions),
   ``topClasses``, ``contextModel`` and ``omcVersion``.

-  On names: ``definition`` (the node that declares the name), ``uses``,
   ``useArrows`` and ``role``.

-  On classes: ``dependsOn``, ``checkModel``, ``flatModelica`` (the class as
   Base Modelica) and ``modelInstance`` (the JSON of
   :ref:`getModelInstance <getModelInstance>`).

-  From the translation of a model: ``simVariables``, ``simEquations``,
   ``jacobianEquations``, ``cCode`` (the generated C function of each
   simulation equation), ``translationMessages``, ``flatDeclarations`` and
   ``connectionEquations``. The simulation equations are shown with the
   symbolic operations that made them, e.g. how an equation was solved.

-  ``blt`` of a class: the blocks of the initial and the regular equations in
   the order they are solved, assignments and systems of equations with their
   iteration variables and torn and residual equations, each linked to the
   equation of the file it comes from. ``bltBlock`` of an equation or a
   statement: the blocks its simulation equations are in, which shows the other
   equations of the same algebraic loop.

-  ``stateSelection`` of a class or component: the states, the dummy states
   chosen by index reduction, with the variable they equal and the steps that
   made them so, and the ``stateSelect`` attributes.

The translation properties need a model to translate. It is ``contextModel``
if given, otherwise the model the node is in. An equation of ``R`` is
translated as part of the whole circuit with ``contextModel = "EQ.B"``:

.. omc-mos ::
  :parsed:

  evaluateProbe("ProbeCircuit.mo", "0.0.2.3", "hover", "EQ.B")

The translation is kept in the temporary directory, under a hash of the name
and the contents of the file, so a model is translated once for each version of
the file, and probes on an unchanged file are answered right away.

Using CodeProber
----------------

CodeProber runs as a local web server, given a jar file that connects it to a
compiler. A prototype that connects it to omc can be downloaded from
https://build.openmodelica.org/omc/codeprober/, with instructions. It needs
Java 11 or newer and an OpenModelica nightly build.

In the browser, a right-click on a name or an equation, *Create Probe*, and the
choice of a property opens a probe. Diagnostics like the ``errors`` of the file
are shown as squiggles in the editor and arrows like ``useArrows`` as arrows
between the lines.

.. figure :: media/codeprober-definition-uses.png
  :name: figure-codeprober-definition-uses

  Probes on the parameter ``r``: its definition, its uses drawn as arrows, the
  simulation variables it becomes in the translated model, and the flat
  declarations of the component ``r1`` that modifies it.

.. figure :: media/codeprober-equation.png
  :name: figure-codeprober-equation

  The simulation equations of an equation of ``R``, with the symbolic
  operations that made them, and the C functions generated for them.

.. figure :: media/codeprober-errors.png
  :name: figure-codeprober-errors

  The errors of a file: a connector that does not exist, as a probe and as a
  squiggle in the editor.

CodeProber also has *text probes*: a comment like

.. code-block :: modelica

  connect(src.p, r1.p); // [[Equation.connectionEquations~="'src.p.v' = 'r1.p.v';"]]

asserts that a property of the node on that line contains the given text.
CodeProber checks these assertions in the editor, and ``codeprober.jar --test``
checks them from the command line, which turns them into regression tests of
what the compiler does with a model.
