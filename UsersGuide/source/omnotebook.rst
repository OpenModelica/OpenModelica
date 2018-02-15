.. _omnotebook :

OMNotebook with DrModelica and DrControl
========================================

This chapter covers the OpenModelica electronic notebook subsystem,
called OMNotebook, together with the DrModelica tutoring system for
teaching Modelica, and DrControl for teaching control together with
Modelica. Both are using such notebooks.

Interactive Notebooks with Literate Programming
-----------------------------------------------

Interactive Electronic Notebooks are active documents that may contain
technical computations and text, as well as graphics. Hence, these
documents are suitable to be used for teaching and experimentation,
simulation scripting, model documentation and storage, etc.

Mathematica Notebooks
~~~~~~~~~~~~~~~~~~~~~

Literate Programming :cite:`Knuth84literateprogramming` is a form of
programming where programs are integrated with documentation in the same
document. Mathematica notebooks :cite:`mathematicbook:third` is one of the first
|WYSIWYG| systems that support Literate
Programming. Such notebooks are used, e.g., in the MathModelica modeling
and simulation environment, see e.g. :numref:`mathematica-notebooks` below
and Chapter 19 in :cite:`openmodelica.org:fritzson:2004`.

OMNotebook
~~~~~~~~~~

The OMNotebook software :cite:`openmodelica.org:axelsson:msc:2005,openmodelica.org:fernstroem:msc:2006`
is a new open source free software that gives an
interactive |WYSIWYG| realization of
Literate Programming, a form of programming where programs are
integrated with documentation in the same document.

The OMNotebook facility is actually an interactive |WYSIWYG|
realization of Literate Programming, a form of programming where programs are
integrated with documentation in the same document.
OMNotebook is a simple open-source software tool for an electronic notebook supporting Modelica.

A more advanced electronic notebook tool, also supporting mathematical
typesetting and many other facilities, is provided by Mathematica
notebooks in the MathModelica environment, see :numref:`mathematica-notebooks`.

.. figure :: media/mathematica-notebooks.*
  :name: mathematica-notebooks

  Examples of Mathematica notebooks in the MathModelica modeling and
  simulation environment.

Traditional documents, e.g. books and reports, essentially always have a
hierarchical structure. They are divided into sections, subsections,
paragraphs, etc. Both the document itself and its sections usually have
headings as labels for easier navigation. This kind of structure is also
reflected in electronic notebooks. Every notebook corresponds to one
document (one file) and contains a tree structure of cells. A cell can
have different kinds of contents, and can even contain other cells. The
notebook hierarchy of cells thus reflects the hierarchy of sections and
subsections in a traditional document such as a book.

DrModelica Tutoring System – an Application of OMNotebook
---------------------------------------------------------

Understanding programs is hard, especially code written by someone else.
For educational purposes it is essential to be able to show the source
code and to give an explanation of it at the same time.

Moreover, it is important to show the result of the source code’s
execution. In modeling and simulation it is also important to have the
source code, the documentation about the source code, the execution
results of the simulation model, and the documentation of the simulation
results in the same document. The reason is that the problem solving
process in computational simulation is an iterative process that often
requires a modification of the original mathematical model and its
software implementation after the interpretation and validation of the
computed results corresponding to an initial model.

Most of the environments associated with equation-based modeling
languages focus more on providing efficient numerical algorithms rather
than giving attention to the aspects that should facilitate the learning
and teaching of the language. There is a need for an environment
facilitating the learning and understanding of Modelica. These are the
reasons for developing the DrModelica teaching material for Modelica and
for teaching modeling and simulation.

An earlier version of DrModelica was developed using the MathModelica
(now Wolfram SystemModeler) environment. The rest of this chapter is
concerned with the OMNotebook version of DrModelica and on the
OMNotebook tool itself.

DrModelica has a hierarchical structure represented as notebooks. The
front-page notebook is similar to a table of contents that holds all
other notebooks together by providing links to them. This particular
notebook is the first page the user will see (:numref:`omnotebook-drmodelica`).

.. figure :: media/omnotebook-drmodelica.png
  :name: omnotebook-drmodelica

  The front-page notebook of the OMNotebook version of the DrModelica
  tutoring system.

In each chapter of DrModelica the user is presented a short summary of
the corresponding chapter of the Modelica book :cite:`openmodelica.org:fritzson:2004`. The
summary introduces some *keywords*, being hyperlinks that will lead the
user to other notebooks describing the keywords in detail.

.. figure :: media/omnotebook-helloworld.png
  :name: omnotebook-helloworld

  The HelloWorld class simulated and plotted using the OMNotebook version of DrModelica.

Now, let us consider that the link “\ *HelloWorld*\ ” in DrModelica
Section is clicked by the user. The new HelloWorld notebook (see :numref:`omnotebook-helloworld`),
to which the user is being linked, is not only a textual
description but also contains one or more examples explaining the
specific keyword. In this class, HelloWorld, a differential equation is
specified.

No information in a notebook is fixed, which implies that the user can
add, change, or remove anything in a notebook. Alternatively, the user
can create an entirely new notebook in order to write his/her own
programs or copy examples from other notebooks. This new notebook can be
linked from existing notebooks.

.. figure :: media/omnotebook-drmodelica-ch9.png
  :name: omnotebook-drmodelica-ch9

  DrModelica Chapter on Algorithms and Functions in the main page of the
  OMNotebook version of DrModelica.

When a class has been successfully evaluated the user can simulate and
plot the result, as previously depicted in :numref:`omnotebook-helloworld` for the simple
HelloWorld example model.

After reading a chapter in DrModelica the user can immediately practice
the newly acquired information by doing the exercises that concern the
specific chapter. Exercises have been written in order to elucidate
language constructs step by step based on the pedagogical assumption
that a student learns better “\ *using the strategy of learning by
doing*\ ”. The exercises consist of either theoretical questions or
practical programming assignments. All exercises provide answers in
order to give the user immediate feedback.

:numref:`omnotebook-drmodelica-ch9` shows part of Chapter 9 of the
DrModelica teaching material.
Here the user can read about language constructs, like algorithm sections,
when-statements, and reinit equations, and then practice these constructs
by solving the exercises corresponding to the recently studied section.

.. figure :: media/omnotebook-drmodelica-ex1.png
  :name: omnotebook-drmodelica-ex1

  Exercise 1 in Chapter 9 of DrModelica.

Exercise 1 from Chapter 9 is shown in :numref:`omnotebook-drmodelica-ex1`.
In this exercise the user has the opportunity to practice different
language constructs and then compare the solution to the answer for the exercise.
Notice that the answer is not visible until the *Answer* section is expanded.
The answer is shown in :numref:`omnotebook-drmodelica-ex1-answer`.

.. figure :: media/omnotebook-drmodelica-ex1-answer.png
  :name: omnotebook-drmodelica-ex1-answer

  The answer section to Exercise 1 in Chapter 9 of DrModelica.

DrControl Tutorial for Teaching Control Theory
----------------------------------------------

DrControl is an interactive OMNotebook document aimed at teaching
control theory. It is included in the OpenModelica distribution and
appears under the directory:

.. omc-mos ::

  getInstallationDirectoryPath() + "/share/omnotebook/drcontrol"

The front-page of DrControl resembles a linked table of content that can
be used as a navigation center. The content list contains topics like:

-  Getting started

-  The control problem in ordinary life

-  Feedback loop

-  Mathematical modeling

-  Transfer function

-  Stability

-  Example of controlling a DC-motor

-  Feedforward compensation

-  State-space form

-  State observation

-  Closed loop control system.

-  Reconstructed system

-  Linear quadratic optimization

-  Linearization

Each entry in this list leads to a new notebook page where either the
theory is explained with Modelica examples or an exercise with a
solution is provided to illustrate the background theory. Below we show
a few sections of DrControl.

Feedback Loop
~~~~~~~~~~~~~

One of the basic concepts of control theory is using feedback loops
either for neutralizing the disturbances from the surroundings or a
desire for a smoother output.

In :numref:`omnotebook-feedback`, control of a simple car model is illustrated where the
car velocity on a road is controlled, first with an open loop control,
and then compared to a closed loop system with a feedback loop. The car
has a mass m, velocity y, and aerodynamic coefficient α. The θ is the
road slope, which in this case can be regarded as noise.

.. figure :: media/omnotebook-feedback.png
  :name: omnotebook-feedback

  Feedback loop.

Lets look at the Modelica model for the open loop controlled car:

.. math::
  m \dot y = u - \alpha y - m g * sin(\theta)

.. omc-loadString ::

  model noFeedback
    import SI = Modelica.SIunits;
    SI.Velocity y;                              // output signal without noise, theta = 0 -> v(t) = 0
    SI.Velocity yNoise;                         // output signal with noise,    theta <> 0 -> v(t) <> 0
    parameter SI.Mass m = 1500;
    parameter Real alpha = 200;
    parameter SI.Angle theta = 5*3.141592/180;
    parameter SI.Acceleration g = 9.82;
    SI.Force u;
    SI.Velocity r=20;
  equation
    m*der(y)=u-alpha*y;                          // signal without noise
    m*der(yNoise)=u-alpha*yNoise-m*g*sin(theta); // with noise
    u = 250*r;
  end noFeedback;

By applying a road slope angle different from zero the car velocity is
influenced which can be regarded as noise in this model. The output
signal in :numref:`omnotebook-open-loop` is stable but an overshoot can be observed
compared to the reference signal. Naturally the overshoot is not desired
and the student will in the next exercise learn how to get rid of this
undesired behavior of the system.

.. omc-mos ::
  :erroratend:

  loadModel(Modelica)
  simulate(noFeedback, stopTime=100)

.. omc-gnuplot :: omnotebook-open-loop
  :caption: Open loop control example.
  :name: omnotebook-open-loop

  y
  yNoise

The closed car model with a proportional regulator is shown below:

.. math::
  u = K*(r-y)

.. omc-loadString ::

  model withFeedback
    import SI = Modelica.SIunits;
    SI.Velocity y;                                // output signal with feedback link and without noise, theta = 0 -> v(t) = 0
    SI.Velocity yNoise;                           // output signal with feedback link and noise,    theta <> 0 -> v(t) <> 0
    parameter SI.Mass m = 1500;
    parameter Real alpha = 250;
    parameter SI.Angle theta = 5*3.141592/180;
    parameter SI.Acceleration g = 9.82;
    SI.Force u;
    SI.Force uNoise;
    SI.Velocity r=20;
  equation
    m*der(y)=u-alpha*y;
    m*der(yNoise)=uNoise-alpha*yNoise-m*g*sin(theta);
    u = 5000*(r-y);
    uNoise = 5000*(r-yNoise);
  end withFeedback;

By using the information about the current level of the output signal
and re-tune the regulator the output quantity can be controlled towards
the reference signal smoothly and without an overshoot, as shown in
:numref:`omnotebook-closed-loop`.

In the above simple example the flat modeling approach was adopted since
it was the fastest one to quickly obtain a working model. However, one
could use the object oriented approach and encapsulate the car and
regulator models in separate classes with the Modelica connector
mechanism in between.

.. omc-mos ::
  :erroratend:

  loadModel(Modelica)
  simulate(withFeedback, stopTime=10)

.. omc-gnuplot :: omnotebook-closed-loop
  :caption: Closed loop control example.
  :name: omnotebook-closed-loop

  y
  yNoise

Mathematical Modeling with Characteristic Equations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In most systems the relation between the inputs and outputs can be
described by a linear differential equation. Tearing apart the solution
of the differential equation into homogenous and particular parts is an
important technique taught to the students in engineering courses, also
illustrated in :numref:`omnotebook-mathematical-modeling-with-characteristic-equation`.

.. math ::

  {{\partial ^{n}y}\over{\partial t^n}} + a_1 {{\partial ^{n-1}y}\over{\partial t^{n-1}}} + \ldots + a_n y
  =
  b_0 {{\partial ^{m}u} \over {\partial t^m}} + \ldots + b_{m-1} {{\partial u}\over{\partial t}} + b_m u

Now let us examine a second order system:

.. math ::

  \ddot y + a_1 \dot y + a_2 y = 1

.. omc-loadstring ::

  model NegRoots
    Real y;
    Real der_y;
    parameter Real a1 = 3;
    parameter Real a2 = 2;
  equation
    der_y = der(y);
    der(der_y) + a1*der_y + a2*y = 1;
  end NegRoots;

Choosing different values for a\ :sub:`1` and a\ :sub:`2` leads to
different behavior as shown in :numref:`omnotebook-drcontrol-negroots` and :numref:`omnotebook-drcontrol-imgposroots`.

.. figure :: media/omnotebook-mathematical-modeling-with-characteristic-equation.png
  :name: omnotebook-mathematical-modeling-with-characteristic-equation

  Mathematical modeling with characteristic equation.

In the first example the values of a\ :sub:`1` and a\ :sub:`2` are
chosen in such way that the characteristic equation has negative real
roots and thereby a stable output response, see :numref:`omnotebook-drcontrol-negroots`.

.. omc-mos ::

  simulate(NegRoots, stopTime=10)

.. omc-gnuplot :: omnotebook-drcontrol-negroots
  :name: omnotebook-drcontrol-negroots
  :caption: Characteristic equation with real negative roots.

  y

The importance of the sign of the roots in the characteristic equation
is illustrated in :numref:`omnotebook-drcontrol-negroots` and
:numref:`omnotebook-drcontrol-imgposroots`, e.g., a stable system
with negative real roots and an unstable system with positive imaginary
roots resulting in oscillations.

.. omc-loadstring ::

  model ImgPosRoots
    Real y;
    Real der_y;
    parameter Real a1 = -2;
    parameter Real a2 = 10;
  equation
    der_y = der(y);
    der(der_y) + a1*der_y + a2*y = 1;
  end ImgPosRoots;

.. omc-mos ::

  simulate(ImgPosRoots, stopTime=10)

.. omc-gnuplot :: omnotebook-drcontrol-imgposroots
  :name: omnotebook-drcontrol-imgposroots
  :caption: Characteristic equation with imaginary roots with positive real part.

  y

.. figure :: media/omnotebook-step-pulse.png

  Step and pulse (weight function) response.

The theory and application of Kalman filters is also explained in the
interactive course material.

.. figure :: media/omnotebook-theory-kalman.png

  Theory background about Kalman filter.

In reality noise is present in almost every physical system under study
and therefore the concept of noise is also introduced in the course
material, which is purely Modelica based.

.. figure :: media/omnotebook-kalman-noisy-feedback.png

  Comparison of a noisy system with feedback link in DrControl.

OpenModelica Notebook Commands
------------------------------

OMNotebook currently supports the commands and concepts that are
described in this section.

Cells
~~~~~

Everything inside an OMNotebook document is made out of cells. A cell
basically contains a chunk of data. That data can be text, images, or
other cells. OMNotebook has four types of cells: headercell, textcell,
inputcell, and groupcell. Cells are ordered in a tree structure, where
one cell can be a parent to one or more additional cells. A tree view is
available close to the right border in the notebook window to display
the relation between the cells.

-  *Textcell* – This cell type is used to display ordinary text and
       images. Each textcell has a style that specifies how text is
       displayed. The cell´s style can be changed in the menu
       Format->Styles, example of different styles are: Text, Title, and
       Subtitle. The Textcell type also has support for following links
       to other notebook documents.

-  *Inputcell* – This cell type has support for syntax highlighting and
       evaluation. It is intended to be used for writing program code,
       e.g. Modelica code. Evaluation is done by pressing the key
       combination Shift+Return or Shift+Enter. All the text in the cell
       is sent to OMC (OpenModelica Compiler/interpreter), where the
       text is evaluated and the result is displayed below the
       inputcell. By double-clicking on the cell marker in the tree
       view, the inputcell can be collapsed causing the result to be
       hidden.
       
-  *Latexcell* – This cell type has support for evaluation of latex scripts.
       It is intended to be mainly used for writing mathematical equations and 
       formulas for advanced documentation in OMNotebook. Each Latexcell supports 
       a maximum of one page document output.To evaluate this cell, latex must be 
       installed in your system.The users can copy and paste the latex scripts and 
       start the evaluation.Evaluation is done by pressing the key
       combination Shift+Return or Shift+Enter or the green color eval button 
       present in the toolbar. The script in the cell is sent to latex compiler, where it
       is evaluated and the output is displayed hiding the latex source. By double-clicking 
       on the cell marker in the tree view,the latex source is displayed for further modification.
       
-  *Groupcell* – This cell type is used to group together other cell. A
       groupcell can be opened or closed. When a groupcell is opened all
       the cells inside the groupcell are visible, but when the
       groupcell is closed only the first cell inside the groupcell is
       visible. The state of the groupcell is changed by the user
       double-clicking on the cell marker in the tree view. When the
       groupcell is closed the marker is changed and the marker has an
       arrow at the bottom.

Cursors
~~~~~~~

An OMNotebook document contains cells which in turn contain text. Thus,
two kinds of cursors are needed for positioning, text cursor and cell
cursor:

-  *Textcursor* – A cursor between characters in a cell, appearing as a
       small vertical line. Position the cursor by clicking on the text
       or using the arrow buttons.

-  *Cellcursor* – This cursor shows which cell currently has the input
       focus. It consists of two parts. The main cellcursor is basically
       just a thin black horizontal line below the cell with input
       focus. The cellcursor is positioned by clicking on a cell,
       clicking between cells, or using the menu item Cell->Next Cell or
       Cell->Previous Cell. The cursor can also be moved with the key
       combination Ctrl+Up or Ctrl+Down. The dynamic cellcursor is a
       short blinking horizontal line. To make this visible, you must
       click once more on the main cellcursor (the long horizontal
       line). NOTE: In order to paste cells at the cellcursor, the
       *dynamic cellcursor must be made active* by clicking on the main
       cellcursor (the horizontal line).

Selection of Text or Cells
~~~~~~~~~~~~~~~~~~~~~~~~~~

To perform operations on text or cells we often need to select a range
of characters or cells.

-  *Select characters* – There are several ways of selecting characters,
       e.g. double-clicking on a word, clicking and dragging the mouse,
       or click followed by a shift-click at an adjacent positioin
       selects the text between the previous click and the position of
       the most recent shift-click.

-  *Select cells* – Cells can be selected by clicking on them. Holding
       down Ctrl and clicking on the cell markers in the tree view
       allows several cells to be selected, one at a time. Several cells
       can be selected at once in the tree view by holding down the
       Shift key. Holding down Shift selects all cells between last
       selected cell and the cell clicked on. This only works if both
       cells belong to the same groupcell.

File Menu
~~~~~~~~~

The following file related operations are available in the file menu:

-  *Create a new noteboo*\ k – A new notebook can be created using the
       menu File->New or the key combination Ctrl+N. A new document
       window will then open, with a new document inside.

-  *Open a notebook* – To open a notebook use File->Open in the menu or
       the key combination Ctrl+O. Only files of the type .onb or .nb
       can be opened. If a file does not follow the OMNotebook format or
       the FullForm Mathematica Notebook format, a message box is
       displayed telling the user what is wrong. Mathematica Notebooks
       must be converted to fullform before they can be opened in
       OMNotebook.

-  *Save a notebook* – To save a notebook use the menu item File->Save
       or File->Save As. If the notebook has not been saved before the
       save as dialog is shown and a filename can be selected.
       OMNotebook can only save in xml format and the saved file is not
       compatible with Mathematica. Key combination for save is Ctrl+S
       and for save as Ctrl+Shift+S. The saved file by default obtains
       the file extension .onb.

-  *Print* – Printing a document to a printer is done by pressing the
       key combination Ctrl+P or using the menu item File->Print. A
       normal print dialog is displayed where the usually properties can
       be changed.

-  *Import old document* – Old documents, saved with the old version of
       OMNotebook where a different file format was used, can be opened
       using the menu item File->Import->Old OMNotebook file. Old
       documents have the extension .xml.

-  *Export text* – The text inside a document can be exported to a text
       document. The text is exported to this document without almost
       any structure saved. The only structure that is saved is the cell
       structure. Each paragraph in the text document will contain text
       from one cell. To use the export function, use menu item
       File->Export->Pure Text.

-  *Close a notebook window* – A notebook window can be closed using the
       menu item File->Close or the key combination Ctrl+F4. Any unsaved
       changes in the document are lost when the notebook window is
       closed.

-  *Quitting OMNotebook* – To quit OMNotebook, use menu item File->Quit
       or the key combination Crtl+Q. This closes all notebook windows;
       users will have the option of closing OMC also. OMC will not
       automatically shutdown because other programs may still use it.
       Evaluating the command quit() has the same result as exiting
       OMNotebook.

Edit Menu
~~~~~~~~~

-  *Editing cell text* – Cells have a set of of basic editing functions.
       The key combination for these are: Undo (Ctrl+Z), Redo (Ctrl+Y),
       Cut (Ctrl+X), Copy (Ctrl+C) and Paste (Ctrl+V). These functions
       can also be accessed from the edit menu; Undo (Edit->Undo), Redo
       (Edit->Redo), Cut (Edit->Cut), Copy (Edit->Copy) and Paste
       (Edit->Paste). Selection of text is done in the usual way by
       double-clicking, triple-clicking (select a paragraph), dragging
       the mouse, or using (Ctrl+A) to select all text within the cell.

-  *Cut cell* – Cells can be cut from a document with the menu item
       Edit->Cut or the key combination Ctrl+X. The cut function will
       always cut cells if cells have been selected in the tree view,
       otherwise the cut function cuts text.

-  *Copy cell* – Cells can be copied from a document with the menu item
       Edit->Copy or the key combination Ctrl+C. The copy function will
       always copy cells if cells have been selected in the tree view,
       otherwise the copy function copy text.

-  *Paste cell* – To paste copied or cut cells the cell cursor must be
       selected in the location where the cells should be pasted. This
       is done by clicking on the cell cursor. Pasteing cells is done
       from the menu Edit->Paste or the key combination Ctrl+V. If the
       cell cursor is selected the paste function will always paste
       cells. OMNotebook share the same application-wide clipboard.
       Therefore cells that have been copied from one document can be
       pasted into another document. Only pointers to the copied or cut
       cells are added to the clipboard, thus the cell that should be
       pasted must still exist. Consequently a cell can not be pasted
       from a document that has been closed.

-  *Find* – Find text string in the current notebook, with the options
       match full word, match cell, search within closed cells. Short
       command Ctrl+F.

-  *Replace –* Find and replace text string in the current notebook,
       with the options match full word, match cell, search+replace
       within closed cells. Short command Ctrl+H.

-  *View expression* – Text in a cell is stored internally as a subset
       of HTML code and the menu item Edit->View Expression let the user
       switch between viewing the text or the internal HTML
       representation. Changes made to the HTML code will affect how the
       text is displayed.

Cell Menu
~~~~~~~~~

-  *Add textcell* – A new textcell is added with the menu item Cell->Add
       Cell (previous cell style) or the key combination Alt+Enter. The
       new textcell gets the same style as the previous selected cell
       had.

-  *Add inputcell* – A new inputcell is added with the menu item
       Cell->Add Inputcell or the key combination Ctrl+Shift+I.

-  *Add latexcell* – A new latexcell is added with the menu item
       Cell->Add Latexcell or the key combination Ctrl+Shift+E.
       
-  *Add groupcell* – A new groupcell is inserted with the menu item
       Cell->Groupcell or the key combination Ctrl+Shift+G. The selected
       cell will then become the first cell inside the groupcell.

-  *Ungroup groupcell* – A groupcell can be ungrouped by selecting it in
       the tree view and using the menu item Cell->Ungroup Groupcell or
       by using the key combination Ctrl+Shift+U. Only one groupcell at
       a time can be ungrouped.

-  *Split cell* – Spliting a cell is done with the menu item Cell->Split
       cell or the key combination Ctrl+Shift+P. The cell is splited at
       the position of the text cursor.

-  *Delete cell* – The menu item Cell->Delete Cell will delete all cells
       that have been selected in the tree view. If no cell is selected
       this action will delete the cell that have been selected by the
       cellcursor. This action can also be called with the key
       combination Ctrl+Shift+D or the key Del (only works when cells
       have been selected in the tree view).

-  *Cellcursor* – This cell type is a special type that shows which cell
       that currently has the focus. The cell is basically just a thin
       black line. The cellcursor is moved by clicking on a cell or
       using the menu item Cell->Next Cell or Cell->Previous Cell. The
       cursor can also be moved with the key combination Ctrl+Up or
       Ctrl+Down.

Format Menu
~~~~~~~~~~~

-  *Textcell* – This cell type is used to display ordinary text and
       images. Each textcell has a style that specifies how text is
       displayed. The cells style can be changed in the menu
       Format->Styles, examples of different styles are: Text, Title,
       and Subtitle. The Textcell type also have support for following
       links to other notebook documents.

-  *Text manipulation* – There are a number of different text
       manipulations that can be done to change the appearance of the
       text. These manipulations include operations like: changing font,
       changing color and make text bold, but also operations like:
       changing the alignment of the text and the margin inside the
       cell. All text manipulations inside a cell can be done on single
       letters, words or the entire text. Text settings are found in the
       Format menu. The following text manipulations are available in
       OMNotebook:

> Font family

> Font face (Plain, Bold, Italic, Underline)

> Font size

> Font stretch

> Font color

> Text horizontal alignment

> Text vertical alignment

> Border thickness

> Margin (outside the border)

> Padding (inside the border)

Insert Menu
~~~~~~~~~~~

-  *Insert image* – Images are added to a document with the menu item
       Insert->Image or the key combination Ctrl+Shift+M. After an image
       has been selected a dialog appears, where the size of the image
       can be chosen. The images actual size is the default value of the
       image. OMNotebook stretches the image accordantly to the selected
       size. All images are saved in the same file as the rest of the
       document.

-  *Insert link* – A document can contain links to other OMNotebook file
       or Mathematica notebook and to add a new link a piece of text
       must first be selected. The selected text make up the part of the
       link that the user can click on. Inserting a link is done from
       the menu Insert->Link or with the key combination Ctrl+Shift+L. A
       dialog window, much like the one used to open documents, allows
       the user to choose the file that the link refers to. All links
       are saved in the document with a relative file path so documents
       that belong together easily can be moved from one place to
       another without the links failing.

Window Menu
~~~~~~~~~~~

-  *Change window* – Each opened document has its own document window.
       To switch between those use the Window menu. The window menu
       lists all titles of the open documents, in the same order as they
       were opened. To switch to another document, simple click on the
       title of that document.

Help Menu
~~~~~~~~~

-  *About OMNotebook* – Accessing the about message box for OMNotebook
       is done from the menu Help->About OMNotebook.

-  *About Qt* – To access the message box for Qt, use the menu
       Help->About Qt.

-  *Help Text* – Opening the help text (document OMNotebookHelp.onb) for
       OMNotebook can be done in the same way as any OMNotebook document
       is opened or with the menu Help->Help Text. The menu item can
       also be triggered with the key F1.

Additional Features
~~~~~~~~~~~~~~~~~~~

-  *Links* – By clicking on a link, OMNotebook will open the document
       that is referred to in the link.

-  *Update link* – All links are stored with relative file path.
       Therefore OMNotebook has functions that automatically updating
       links if a document is resaved in another folder. Every time a
       document is saved, OMNotebook checks if the document is saved in
       the same folder as last time. If the folder has changed, the
       links are updated.
       
-  \ *Evaluate whole Notebook* – All the cells present in the Notebook can 
       be evaluated in one step by pressing the red color evalall button
       in the toolbar. The cells are evaluated in the same order as they 
       are in the Notebook.However the latexcells cannot be evaluated by 
       this feature.        
       
-  \ *Evaluate several cells* – Several inputcells can be evaluated at
       the same time by selecting them in the treeview and then pressing
       the key combination Shift+Enter or Shift+Return. The cells are
       evaluated in the same order as they have been selected. If a
       groupcell is selected all inputcells in that groupcell are
       evaluated, in the order they are located in the groupcell.
       
-  \ *Moving and Reordering cells in a Notebook* – It is possible to shift cells
       to a new position and change the hierarchical order of the document.This can 
       be done by clicking the cell and press the Up and Down arrow button in 
       the tool bar to move either Up or Down. The cells are moved one cell
       above or below.It is also possible to move a cell directly to a new
       position with one single click by pressing the red color bidirectional 
       UpDown arrow button in the toolbar. To do this the user has to place
       the cell cursor to a position where the selected cells must be moved. 
       After selecting the cell cursor position, select the cells you want to 
       shift and press the bidirectional UpDown arrow button. The cells are 
       shifted in the same order as they are selected.This is especially very
       useful when shifting a group cell.              
       
-  *Command completion* – Inputcells have command completion support,
       which checks if the user is typing a command (or any keyword
       defined in the file commands.xml) and finish the command. If the
       user types the first two or three letters in a command, the
       command completion function fills in the rest. To use command
       completion, press the key combination Ctrl+Space or Shift+Tab.
       The first command that matches the letters written will then
       appear. Holding down Shift and pressing Tab (alternative holding
       down Ctrl and pressing Space) again will display the second
       command that matches. Repeated request to use command completion
       will loop through all commands that match the letters written.
       When a command is displayed by the command completion
       functionality any field inside the command that should be edited
       by the user is automatically selected. Some commands can have
       several of these fields and by pressing the key combination
       Ctrl+Tab, the next field will be selected inside the command. >
       Active Command completion: Ctrl+Space / Shift+Tab > Next command:
       Ctrl+Space / Shift+Tab > Next field in command: Ctrl+Tab’

-  *Generated plot* – When plotting a simulation result, OMC uses the
       program Ptplot to create a plot. From Ptplot OMNotebook gets an
       image of the plot and automatically adds that image to the output
       part of an inputcell. Like all other images in a document, the
       plot is saved in the document file when the document is saved.

-  *Stylesheet* –OMNotebook follows the style settings defined in
       stylesheet.xml and the correct style is applied to a cell when
       the cell is created.

-  *Automatic Chapter Numbering* – OMNotebook automatically numbers
       different chapter, subchapter, section and other styles. The user
       can specify which styles should have chapter numbers and which
       level the style should have. This is done in the stylesheet.xml
       file. Every style can have a <chapterLevel> tag that specifies
       the chapter level. Level 0 or no tag at all, means that the style
       should not have any chapter numbering.

-  *Scrollarea* – Scrolling through a document can be done by using the
       mouse wheel. A document can also be scrolled by moving the cell
       cursor up or down.

-  *Syntax highlighter* – The syntax highlighter runs in a separated
       thread which speeds up the loading of large document that
       contains many Modelica code cells. The syntax highlighter only
       highlights when letters are added, not when they are removed. The
       color settings for the different types of keywords are stored in
       the file modelicacolors.xml. Besides defining the text color and
       background color of keywords, whether or not the keywords should
       be bold or/and italic can be defined.

-  *Change indicator* – A star (\*) will appear behind the filename in
       the title of notebook window if the document has been changed and
       needs saving. When the user closes a document that has some
       unsaved change, OMNotebook asks the user if he/she wants to save
       the document before closing. If the document never has been saved
       before, the save-as dialog appears so that a filename can be
       choosen for the new document.

-  *Update menus* – All menus are constantly updated so that only menu
       items that are linked to actions that can be performed on the
       currently selected cell is enabled. All other menu items will be
       disabled. When a textcell is selected the Format menu is updated
       so that it indicates the text settings for the text, in the
       current cursor position.

References
----------

.. todo ::

  Add these into extrarefs.bib and cite them somewhere

Eric Allen, Robert Cartwright, Brian Stoler. DrJava: A lightweight
pedagogic environment for Java. In Proceedings of the 33rd ACM Technical
Symposium on Computer Science Education (SIGCSE 2002) (Northern Kentucky
– The Southern Side of Cincinnati, USA, February 27 – March 3, 2002).

Anders Fernström, Ingemar Axelsson, Peter Fritzson, Anders Sandholm,
Adrian Pop. OMNotebook – Interactive WYSIWYG Book Software for Teaching
Programming. In Proc. of the Workshop on Developing Computer Science
Education – How Can It Be Done?. Linköping University, Dept. Computer &
Inf. Science, Linköping, Sweden, March 10, 2006.

Eva-Lena Lengquist-Sandelin, Susanna Monemar, Peter Fritzson, and Peter
Bunus. DrModelica – A Web-Based Teaching Environment for Modelica. In
Proceedings of the 44th Scandinavian Conference on Simulation and
Modeling (SIMS’2003), available at www.scan-sims.org. Västerås, Sweden.
September 18-19, 2003.

.. |WYSIWYG| replace:: :abbr:`WYSIWYG (What-You-See-Is-What-You-Get)`

.. omc-reset ::

.. bibliography:: openmodelica.bib extrarefs.bib
  :cited:
  :filter: docname in docnames
