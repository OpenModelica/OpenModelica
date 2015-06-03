Modelica3D
==========

Modelica3D is a lightweight, platform independent 3D-visualisation
library for Modelica. Read more about the Modelica3D library here
`*https://mlcontrol.uebb.tu-berlin.de/redmine/projects/modelica3d-public* <https://mlcontrol.uebb.tu-berlin.de/redmine/projects/modelica3d-public>`__.

Windows
-------

In order to run Modelica3D on windows you need following softwares;

-  Python – Install python from
       `*http://www.python.org/download/* <http://www.python.org/download/>`__.
       Python2.7.3 is recommended.

-  PyGTK – Install GTK+ for python from
       `*http://ftp.gnome.org/pub/GNOME/binaries/win32/pygtk/2.24/* <http://ftp.gnome.org/pub/GNOME/binaries/win32/pygtk/2.24/>`__.
       Download the all-in-one package. Recommmended is
       pygtk-all-in-one-2.24.2.win32-py2.7.msi.

Run the Modelica3D server by executing the dbus-server.py script located
at OPENMODELICAHOME/lib/omlibrary-modelica3d/osg-gtk.

python dbus-server.py

This will start the Modelica3D server and on success you should see the
output,

Running dbus-server...

Now run the simulation. The following commands will load the Modelica3D
library and simulates the DoublePendulum example,

loadModelica3D(); getErrorString();

loadString("model DoublePendulum

extends Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum;

inner ModelicaServices.Modelica3D.Controller m3d\_control;

end DoublePendulum;"); getErrorString();

simulate(DoublePendulum); getErrorString();

If everything goes fine a visualization window will pop-up. To visualize
any models from the MultiBody library you can use this script and change
the extends to point to the model you want. Note that you will need to
add visualisers to your model similarly to what Modelica.MultiBody
library has. See some documentation of the visualizers available here:
`*https://build.openmodelica.org/Documentation/Modelica.Mechanics.MultiBody.Visualizers.html* <https://build.openmodelica.org/Documentation/Modelica.Mechanics.MultiBody.Visualizers.html>`__

loadModelica3D(); getErrorString();

loadString("

model Visualize\_MyModel

inner ModelicaServices.Modelica3D.Controller m3d\_control;

extends **MyModel**;

end Visualize\_MyModel;

");

simulate(Visualize\_MyModel); getErrorString();

MacOS
-----

On MacOS you can use the 3d visualization like this. Note that on your
system the paths used here might vary. In one terminal type:

# start the dbus server (you only need to do this once)

> sudo launchctl load -w
/opt/openmodelica/Library/LaunchDaemons/org.freedesktop.dbus-system.plist

> launchctl load -w
/opt/openmodelica/Library/LaunchAgents/org.freedesktop.dbus-session.plist

# export python path

> export
PYTHONPATH=/opt/openmodelica/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/site-packages:$PYTHONPATH

# run the dbus-server.py

# go to your openmodelica installation /lib/omlibrary-modelica3d/osg-gtk

> python dbus-server.py

In another terminal type:

> cat > modelica3d.mos

loadModelica3D();getErrorString();

loadString("model DoublePendulum

extends Modelica.Mechanics.MultiBody.Examples.Elementary.DoublePendulum;

inner ModelicaServices.Modelica3D.Controller m3d\_control;

end DoublePendulum;");getErrorString();

instantiateModel(DoublePendulum); getErrorString();

simulate(DoublePendulum); getErrorString();

CTRL+D

> omc modelica3d.mos
