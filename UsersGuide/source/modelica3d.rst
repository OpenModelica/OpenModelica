Modelica3D
==========

.. highlight:: modelica

Modelica3D is a lightweight, platform independent 3D-visualisation
library for Modelica. Read more about the Modelica3D library `here <https://mlcontrol.uebb.tu-berlin.de/redmine/projects/modelica3d-public>`__.

Installing Modelica3D
---------------------

Windows
~~~~~~~

In order to run Modelica3D on windows you need following softwares;

-  Python – Install python from
       http://www.python.org/download/.
       Python2.7.3 is recommended.

-  PyGTK – Install GTK+ for python from
       http://ftp.gnome.org/pub/GNOME/binaries/win32/pygtk/2.24/.
       Download the all-in-one package. Recommmended is
       pygtk-all-in-one-2.24.2.win32-py2.7.msi.

MacOS
~~~~~

On MacOS you can use the 3d visualization like this. Note that on your
system the paths used here might vary. In one terminal type:

.. code-block :: bash

  # start the dbus server (you only need to do this once)
  sudo launchctl load -w /opt/openmodelica/Library/LaunchDaemons/org.freedesktop.dbus-system.plist
  launchctl load -w /opt/openmodelica/Library/LaunchAgents/org.freedesktop.dbus-session.plist
  # export python path
  export PYTHONPATH=/opt/openmodelica/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages:$PYTHONPATH

Running Modelica3D
------------------

Run the Modelica3D server by executing the dbus-server.py script located
in your OpenModelica or Modelica3D installation, for example:

.. omc-mos ::

  "python " + getInstallationDirectoryPath() + "/lib/omlibrary-modelica3d/osg-gtk/dbus-server.py"

Running this command in a command prompt will start the Modelica3D
server and on success you should see the output:

Running dbus-server...

Now run the simulation. The following commands will load the Modelica3D
library and the modified DoublePendulum example:

.. omc-mos ::

  loadModelica3D()

.. omc-loadstring ::

  model DoublePendulum
    extends Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum;
    inner ModelicaServices.Modelica3D.Controller m3d_control;
  end DoublePendulum;

Then simulate the DoublePendulum:

>>> simulate(DoublePendulum)

If everything goes fine a visualization window as shown below will pop-up.

.. figure :: media/modelica3d.png

  3D visualization of DoublePendulum.

To visualize any models from the MultiBody library you can use this script and change
the extends to point to the model you want. Note that you will need to
add visualisers to your model similarly to what Modelica.MultiBody
library has. The documentation of the visualizers is available `here <https://build.openmodelica.org/Documentation/Modelica.Mechanics.MultiBody.Visualizers.html>`__.

.. omc-loadstring ::

  model Visualize_MyModel
    inner ModelicaServices.Modelica3D.Controller m3d_control;
    extends MyModel;
  end Visualize_MyModel;

>>> simulate(Visualize_MyModel)
