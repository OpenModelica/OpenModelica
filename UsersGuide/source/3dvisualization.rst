3D Visualization
================

.. highlight:: modelica

New in OpenModelica 1.11 is that OMEdit has built-in 3D visualization,
which replaces third-party libraries (such as `Modelica3D
<https://github.com/OpenModelica/Modelica3D>`_) for 3D visualization.

Running a Visualization
-----------------------

The 3d visualization is based on OpenSceneGraph. In order to run the
visualization simply right click the class in Libraries Browser and
choose “\ **Simulate with Animation**\ ” as shown in :numref:`omedit-simulate-animation`.

.. figure :: media/omedit_simulate_animation.png
  :name: omedit-simulate-animation

  OMEdit Simulate with Animation.

One can also run the visualization via Simulation > Simulate with Animation from the menu.

Viewing a Visualization
-----------------------

After the successful simulation of the class the visualization window will
show up automatically as shown in :numref:`omedit-visualization`.

.. figure :: media/omedit_visualization.png
  :name: omedit-visualization

  OMEdit 3D Visualization.

The 3D view can be manipulated as follows:

===============  ======================== ========================
  Operation       Key                      Mouse Action
===============  ======================== ========================
Zoom In/Out       none                     Wheel
Zoom In/Out       Right Mouse Hold         Up/Down
Move              Middle Mouse Hold        Move Mouse
Rotate            Left Mouse Hold          Move Mouse
===============  ======================== ========================

Predefined views (Isometric, Side, Front, Top) can be selected and the scene can be tilted by 90° either clock or anticlockwise with the rotation buttons.