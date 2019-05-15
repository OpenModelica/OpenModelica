Frequently Asked Questions (FAQ)
================================

Below are some frequently asked questions in three areas, with
associated answers.

OpenModelica General
--------------------

-  Q: OpenModelica does not read the MODELICAPATH environment variable,
       even though this is part of the Modelica Language Specification.

-  A: Use the OPENMODELICALIBRARY environment variable instead. We have
       temporarily switched to this variable, in order not to interfere
       with other Modelica tools which might be installed on the same
       system. In the future, we might switch to a solution with a
       settings file, that also allows the user to turn on the
       MODELICAPATH functionality if desired.

-  Q: How do I enter multi-line models into OMShell since it evaluates
       when typing the Enter/Return key?

-  A: There are basically three methods: 1) load the model from a file
       using the pull-down menu or the loadModel command. 2) Enter the
       model/function as one (possibly long) line. 3) Type in the model
       in another editor, where using multiple lines is no problem, and
       copy/paste the model into OMShell as one operation, then push
       Enter. Another option is to use OMNotebook instead to enter and
       evaluate models.

OMNotebook
----------

-  Q: OMNotebook hangs, what to do?

-  A: It is probably waiting for the omc.exe (compiler) process. (Under
       windows): Kill the processes omc.exe, g++.exe (C-compiler),
       as.exe (assembler), if present. If OMNotebook then asks whether
       to restart OMC, answer yes. If not, kill the process
       OMNotebook.exe and restart manually.

-  Q: After a previous session, when starting OMNotebook again, I get a
       strange message.

-  A: You probably quit the previous OpenModelica session in the wrong
       way, which left the process omc.exe running. Kill that process,
       and try starting OMNotebook again.

-  Q: I copy and paste a graphic figure from Word or some other
       application into OMNotebook, but the graphic does not appear.
       What is wrong?

-  A: OMNotebook supports the graphic picture formats supported by Qt 4,
       including the .png, .bmp (bitmap) formats, but not for example
       the gif format. Try to convert your picture into one of the
       supported formats, (e.g. in Word, first do paste as bitmap
       format), and then copy the converted version into a text cell in
       OMNotebook.

-  Q: I select a cell, copy it (e.g. Ctrl-C), and try to paste it at
       another place in the notebook. However, this does not work.
       Instead some other text that I earlier put on the clipboard is
       pasted into the nearest text cell.

-  A: The problem is wrong choice of cursor mode, which can be text
       insertion or cell insertion. If you click inside a cell, the
       cursor become vertical, and OMNotebook expects you to paste text
       inside the cell. To paste a cell, you must be in cell insertion
       mode, i.e., click between two cells (or after a cell), you will
       get a vertical line. Place the cursor carefully on that vertical
       line until you see a small horizontal cursor. Then you should
       past the cell.

-  Q: I am trying to click in cells to place the vertical character
       cursor, but it does not seem to react.

-  A: This seems to be a Qt feature. You have probably made a selection
       (e.g. for copying) in the output section of an evaluation cell.
       This seems to block cursor position. Click again in the output
       section to disable the selection. After that it will work
       normally.

-  Q: I have copied a text cell and start writing at the beginning of
       the cell. Strangely enough, the font becomes much smaller than it
       should be.

-  A: This seems to be a Qt feature. Keep some of the old text and start
       writing the new stuff inside the text, i.e., at least one
       character position to the right. Afterwards, delete the old text
       at the beginning of the cell.

OMDev - OpenModelica Development Environment
--------------------------------------------

-  Q: I get problems compiling and linking some files when using OMDev
       with the MINGW (Gnu) C compiler under Windows.

-  A: You probably have some Logitech software installed. There is a
       known bug/incompatibility in Logitech products. For example, if
       lvprcsrv.exe is running, kill it and/or prevent it to start again
       at reboot; it does not do anything really useful, not needed for
       operation of web cameras or mice.
