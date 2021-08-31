Small Overview of Simulation Flags
==================================

This chapter contains a :ref:`short overview of simulation flags <cruntime-simflags>`
as well as additional details of the :ref:`numerical integration methods <cruntime-integration-methods>`.

.. _cruntime-simflags :


Repetition of Simulation Flags and Options
-------------------------------------------------
Unless it is explicitly specified otherwise, it **is an error** to specify any of the simulation Flags/Options more than once.


Repetition policies for specific flags
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
If a Flag/Option is allowed to be repeated, there are three different policies under which it can be processed.

- **Ignore**: Repeated instances of the Flag/Option will be ignored with a warning. For example

    .. code-block:: bash

       $ sim_exe -cx=file1 -cx=file2
       $ sim_exe -cx=file1

    are equivalent except for the warning issued in the first case.

- **Replace**: Repeated instances of an option will override the current value. (Not applicable for Flags.)

    .. code-block:: bash

       $ sim_exe -cx=file1 -cx=file2
       $ sim_exe -cx=file2

    are equivalent except for the warning issued in the first case.


- **Combine**: Repeated instances of the option's values will be combined as if they were given as values for a single specification of the option. (Not applicable for Flags.)

    .. code-block:: bash

       $ sim_exe -cx=file1 -cx=file2
       $ sim_exe -cx=file1,file2

    are equivalent except for the warning issued in the first case. Assuming the option supports multiple values.


Please check the entry below (or the help messages) for each flag/option to find out if a it is allowed to be repeated and what the specific repetition rules are for it.

Order of flags/options from OpenModelica tools
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The final order of flag/option specifications are dependent on where they are specified.

If you are running the simulation executable directly then you have complete control of how the flags are ordered as it will be exactly the way you pass them on the command line.

If you are instead using the different OpenModelica tools to perform simulation or if you are using scripts, the order is as follows:

1. Flags/options from annotations in Modelica code are applied.

2. Flags/options specified in the script are applied.

3. Flags/options specified outside the script on the command line are applied.



OpenModelica (C-runtime) Simulation Flags
-----------------------------------------

.. include :: simoptions.inc

