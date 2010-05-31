package Modelica "Modelica Standard Library (Version 3.1)"
extends Modelica.Icons.Library;
annotation (
preferredView="info",
version="3.1",
versionBuild=4,
versionDate="2009-08-14",
dateModified = "2009-08-28 08:30:00Z",
revisionId="$Id: package.mo,v 1.1.1.2 2009/09/07 15:17:14 Dag Exp $",
conversion(
 noneFromVersion="3.0.1",
 noneFromVersion="3.0",
 from(version="2.1", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos"),
 from(version="2.2", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos"),
 from(version="2.2.1", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos"),
 from(version="2.2.2", script="Scripts/ConvertModelica_from_2.2.2_to_3.0.mos")),
__Dymola_classOrder={"UsersGuide","Blocks","StateGraph","Electrical","Magnetic","Mechanics","Fluid","Media","Thermal",
      "Math","Utilities","Constants", "Icons", "SIunits"},
Settings(NewStateSelection=true),
Documentation(info="<HTML>
<p>
Package <b>Modelica</b> is a <b>standardized</b> and <b>free</b> package
that is developed together with the Modelica language from the
Modelica Association, see
<a href=\"http://www.Modelica.org\">http://www.Modelica.org</a>.
It is also called <b>Modelica Standard Library</b>.
It provides model components in many domains that are based on
standardized interface definitions. Some typical examples are shown
in the next figure:
</p>

<p>
<img src=\"../Images/UsersGuide/ModelicaLibraries.png\">
</p>

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"Modelica://Modelica.UsersGuide.Overview\">Overview</a>
  provides an overview of the Modelica Standard Library
  inside the <a href=\"Modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
<li><a href=\"Modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
 summarizes the changes of new versions of this package.</li>
<li> <a href=\"Modelica://Modelica.UsersGuide.Contact\">Contact</a>
  lists the contributors of the Modelica Standard Library.</li>
<li> <a href=\"../help/Documentation/ModelicaStandardLibrary.pdf\">ModelicaStandardLibrary.pdf</a>
  is the complete documentation of the library in pdf format.
<li> The <b>Examples</b> packages in the various libraries, demonstrate
  how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
This version of the Modelica Standard Library consists of
</p>
<ul>
<li> <b>922</b> models and blocks, and</li>
<li> <b>615</b> functions
</ul>
<p>
that are directly usable (= number of public, non-partial classes).
</p>


<p>
<b>Licensed by the Modelica Association under the Modelica License 2</b><br>
Copyright &copy; 1998-2009, ABB, arsenal research, T.&nbsp;Bödrich, DLR, Dynasim, Fraunhofer, Modelon,
TU Hamburg-Harburg, Politecnico di Milano.
</p>

<p>
<i>This Modelica package is <u>free</u> software and
the use is completely at <u>your own risk</u>;
it can be redistributed and/or modified under the terms of the
Modelica license 2, see the license conditions (including the
disclaimer of warranty)
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense2\">here</a></u>
or at
<a href=\"http://www.Modelica.org/licenses/ModelicaLicense2\">
http://www.Modelica.org/licenses/ModelicaLicense2</a>.
</p>

</HTML>
"));

  package Blocks
  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
  import SI = Modelica.SIunits;
  extends Modelica.Icons.Library2;
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
        graphics={
        Rectangle(extent={{-32,-6},{16,-35}}, lineColor={0,0,0}),
        Rectangle(extent={{-32,-56},{16,-85}}, lineColor={0,0,0}),
        Line(points={{16,-20},{49,-20},{49,-71},{16,-71}}, color={0,0,0}),
        Line(points={{-32,-72},{-64,-72},{-64,-21},{-32,-21}}, color={0,0,0}),
        Polygon(
          points={{16,-71},{29,-67},{29,-74},{16,-71}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid),
        Polygon(
          points={{-32,-21},{-46,-17},{-46,-25},{-32,-21}},
          lineColor={0,0,0},
          fillColor={0,0,0},
          fillPattern=FillPattern.Solid)}),
                            Documentation(info="<html>
<p>
This library contains input/output blocks to build up block diagrams.
</p>

<dl>
<dt><b>Main Author:</b>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
    Oberpfaffenhofen<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
</dl>
<p>
Copyright &copy; 1998-2009, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p>
</HTML>
",   revisions="<html>
<ul>
<li><i>June 23, 2004</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Introduced new block connectors and adapated all blocks to the new connectors.
       Included subpackages Continuous, Discrete, Logical, Nonlinear from
       package ModelicaAdditions.Blocks.
       Included subpackage ModelicaAdditions.Table in Modelica.Blocks.Sources
       and in the new package Modelica.Blocks.Tables.
       Added new blocks to Blocks.Sources and Blocks.Logical.
       </li>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New subpackage Examples, additional components.
       </li>
<li><i>June 20, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
       Michael Tiller:<br>
       Introduced a replaceable signal type into
       Blocks.Interfaces.RealInput/RealOutput:
<pre>
   replaceable type SignalType = Real
</pre>
       in order that the type of the signal of an input/output block
       can be changed to a physical type, for example:
<pre>
   Sine sin1(outPort(redeclare type SignalType=Modelica.SIunits.Torque))
</pre>
      </li>
<li><i>Sept. 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Renamed to Blocks. New subpackages Math, Nonlinear.
       Additional components in subpackages Interfaces, Continuous
       and Sources. </li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>"));

    package Continuous
    "Library of continuous control blocks with internal states"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
      extends Modelica.Icons.Library;
      annotation (
        Documentation(info="<html>
<p>
This package contains basic <b>continuous</b> input/output blocks
described by differential equations.
</p>

<p>
All blocks of this package can be initialized in different
ways controlled by parameter <b>initType</b>. The possible
values of initType are defined in
<a href=\"Modelica://Modelica.Blocks.Types.Init\">Modelica.Blocks.Types.Init</a>:
</p>

<table border=1 cellspacing=0 cellpadding=2>
  <tr><td valign=\"top\"><b>Name</b></td>
      <td valign=\"top\"><b>Description</b></td></tr>

  <tr><td valign=\"top\"><b>Init.NoInit</b></td>
      <td valign=\"top\">no initialization (start values are used as guess values with fixed=false)</td></tr>

  <tr><td valign=\"top\"><b>Init.SteadyState</b></td>
      <td valign=\"top\">steady state initialization (derivatives of states are zero)</td></tr>

  <tr><td valign=\"top\"><b>Init.InitialState</b></td>
      <td valign=\"top\">Initialization with initial states</td></tr>

  <tr><td valign=\"top\"><b>Init.InitialOutput</b></td>
      <td valign=\"top\">Initialization with initial outputs (and steady state of the states if possibles)</td></tr>
</table>

<p>
For backward compatibility reasons the default of all blocks is
<b>Init.NoInit</b>, with the exception of Integrator and LimIntegrator
where the default is <b>Init.InitialState</b> (this was the initialization
defined in version 2.2 of the Modelica standard library).
</p>

<p>
In many cases, the most useful initial condition is
<b>Init.SteadyState</b> because initial transients are then no longer
present. The drawback is that in combination with a non-linear
plant, non-linear algebraic equations occur that might be
difficult to solve if appropriate guess values for the
iteration variables are not provided (i.e. start values with fixed=false).
However, it is often already useful to just initialize
the linear blocks from the Continuous blocks library in SteadyState.
This is uncritical, because only linear algebraic equations occur.
If Init.NoInit is set, then the start values for the states are
interpreted as <b>guess</b> values and are propagated to the
states with fixed=<b>false</b>.
</p>

<p>
Note, initialization with Init.SteadyState is usually difficult
for a block that contains an integrator
(Integrator, LimIntegrator, PI, PID, LimPID).
This is due to the basic equation of an integrator:
</p>

<pre>
  <b>initial equation</b>
     <b>der</b>(y) = 0;   // Init.SteadyState
  <b>equation</b>
     <b>der</b>(y) = k*u;
</pre>

<p>
The steady state equation leads to the condition that the input to the
integrator is zero. If the input u is already (directly or indirectly) defined
by another initial condition, then the initialization problem is <b>singular</b>
(has none or infinitely many solutions). This situation occurs often
for mechanical systems, where, e.g., u = desiredSpeed - measuredSpeed and
since speed is both a state and a derivative, it is always defined by
Init.InitialState or Init.SteadyState initializtion.
</p>

<p>
In such a case, <b>Init.NoInit</b> has to be selected for the integrator
and an additional initial equation has to be added to the system
to which the integrator is connected. E.g., useful initial conditions
for a 1-dim. rotational inertia controlled by a PI controller are that
<b>angle</b>, <b>speed</b>, and <b>acceleration</b> of the inertia are zero.
</p>

</html>
"));

      block Integrator "Output the integral of the input signal"
        import Modelica.Blocks.Types.Init;
        parameter Real k=1 "Integrator gain";

        /* InitialState is the default, because it was the default in Modelica 2.2
     and therefore this setting is backward compatible
  */
        parameter Modelica.Blocks.Types.Init initType=Modelica.Blocks.Types.Init.InitialState
        "Type of initialization (1: no init, 2: steady state, 3,4: initial output)"
                                                                                          annotation(Evaluate=true,
            Dialog(group="Initialization"));
        parameter Real y_start=0 "Initial or guess value of output (= state)" 
          annotation (Dialog(group="Initialization"));
        extends Interfaces.SISO(y(start=y_start));

        annotation (
          Documentation(info="<html>
<p>
This blocks computes output <b>y</b> (element-wise) as
<i>integral</i> of the input <b>u</b> multiplied with
the gain <i>k</i>:
</p>
<pre>
         k
     y = - u
         s
</pre>

<p>
It might be difficult to initialize the integrator in steady state.
This is discussed in the description of package
<a href=\"Modelica://Modelica.Blocks.Continuous#info\">Continuous</a>.
</p>

</html>
"),       Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{-80,78},{-80,-90}}, color={192,192,192}),
              Polygon(
                points={{-80,90},{-88,68},{-72,68},{-80,90}},
                lineColor={192,192,192},
                fillColor={192,192,192},
                fillPattern=FillPattern.Solid),
              Line(points={{-90,-80},{82,-80}}, color={192,192,192}),
              Polygon(
                points={{90,-80},{68,-72},{68,-88},{90,-80}},
                lineColor={192,192,192},
                fillColor={192,192,192},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{0,-10},{60,-70}},
                lineColor={192,192,192},
                textString="I"),
              Text(
                extent={{-150,-150},{150,-110}},
                lineColor={0,0,0},
                textString="k=%k"),
              Line(points={{-80,-80},{80,80}}, color={0,0,127})}),
          Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Rectangle(extent={{-60,60},{60,-60}}, lineColor={0,0,255}),
              Line(points={{-100,0},{-60,0}}, color={0,0,255}),
              Line(points={{60,0},{100,0}}, color={0,0,255}),
              Text(
                extent={{-36,60},{32,2}},
                lineColor={0,0,0},
                textString="k"),
              Text(
                extent={{-32,0},{36,-58}},
                lineColor={0,0,0},
                textString="s"),
              Line(points={{-46,0},{46,0}}, color={0,0,0})}));

      initial equation
        if initType == Init.SteadyState then
           der(y) = 0;
        elseif initType == Init.InitialState or 
               initType == Init.InitialOutput then
          y = y_start;
        end if;
      equation
        der(y) = k*u;
      end Integrator;
    end Continuous;

    package Interfaces
    "Library of connectors and partial models for input/output blocks"
      import Modelica.SIunits;
        extends Modelica.Icons.Library;
        annotation (
          Documentation(info="<HTML>
<p>
This package contains interface definitions for
<b>continuous</b> input/output blocks with Real,
Integer and Boolean signals. Furthermore, it contains
partial models for continuous and discrete blocks.
</p>

</HTML>
",     revisions="<html>
<ul>
<li><i>Oct. 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Added several new interfaces. <a href=\"../Documentation/ChangeNotes1.5.html\">Detailed description</a> available.
<li><i>Oct. 24, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       RealInputSignal renamed to RealInput. RealOutputSignal renamed to
       output RealOutput. GraphBlock renamed to BlockIcon. SISOreal renamed to
       SISO. SOreal renamed to SO. I2SOreal renamed to M2SO.
       SignalGenerator renamed to SignalSource. Introduced the following
       new models: MIMO, MIMOs, SVcontrol, MVcontrol, DiscreteBlockIcon,
       DiscreteBlock, DiscreteSISO, DiscreteMIMO, DiscreteMIMOs,
       BooleanBlockIcon, BooleanSISO, BooleanSignalSource, MI2BooleanMOs.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>
"));

    connector RealInput = input Real "'input Real' as connector" 
      annotation (defaultComponentName="u",
      Icon(graphics={Polygon(
            points={{-100,100},{100,0},{-100,-100},{-100,100}},
            lineColor={0,0,127},
            fillColor={0,0,127},
            fillPattern=FillPattern.Solid)},
           coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.2)),
      Diagram(coordinateSystem(
            preserveAspectRatio=true, initialScale=0.2,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={Polygon(
            points={{0,50},{100,0},{0,-50},{0,50}},
            lineColor={0,0,127},
            fillColor={0,0,127},
            fillPattern=FillPattern.Solid), Text(
            extent={{-10,85},{-10,60}},
            lineColor={0,0,127},
            textString="%name")}),
        Documentation(info="<html>
<p>
Connector with one input signal of type Real.
</p>
</html>"));

    connector RealOutput = output Real "'output Real' as connector" 
      annotation (defaultComponentName="y",
      Icon(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={Polygon(
            points={{-100,100},{100,0},{-100,-100},{-100,100}},
            lineColor={0,0,127},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid)}),
      Diagram(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={Polygon(
            points={{-100,50},{0,0},{-100,-50},{-100,50}},
            lineColor={0,0,127},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid), Text(
            extent={{30,110},{30,60}},
            lineColor={0,0,127},
            textString="%name")}),
        Documentation(info="<html>
<p>
Connector with one output signal of type Real.
</p>
</html>"));

        partial block BlockIcon "Basic graphical layout of input/output block"

          annotation (
            Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},
                {100,100}}), graphics={Rectangle(
              extent={{-100,-100},{100,100}},
              lineColor={0,0,127},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid), Text(
              extent={{-150,150},{150,110}},
              textString="%name",
              lineColor={0,0,255})}),
          Documentation(info="<html>
<p>
Block that has only the basic icon for an input/output
block (no declarations, no equations). Most blocks
of package Modelica.Blocks inherit directly or indirectly
from this block.
</p>
</html>"));

        end BlockIcon;

        partial block SISO
      "Single Input Single Output continuous control block"
          extends BlockIcon;

          RealInput u "Connector of Real input signal" 
            annotation (Placement(transformation(extent={{-140,-20},{-100,20}},
                rotation=0)));
          RealOutput y "Connector of Real output signal" 
            annotation (Placement(transformation(extent={{100,-10},{120,10}},
                rotation=0)));
          annotation (
          Documentation(info="<html>
<p>
Block has one continuous Real input and one continuous Real output signal.
</p>
</html>"));
        end SISO;

        partial block SI2SO
      "2 Single Input / 1 Single Output continuous control block"
          extends BlockIcon;

          RealInput u1 "Connector of Real input signal 1" 
            annotation (Placement(transformation(extent={{-140,40},{-100,80}},
                rotation=0)));
          RealInput u2 "Connector of Real input signal 2" 
            annotation (Placement(transformation(extent={{-140,-80},{-100,-40}},
                rotation=0)));
          RealOutput y "Connector of Real output signal" 
            annotation (Placement(transformation(extent={{100,-10},{120,10}},
                rotation=0)));

          annotation (
            Documentation(info="<html>
<p>
Block has two continuous Real input signals u1 and u2 and one
continuous Real output signal y.
</p>
</html>"),  Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics));

        end SI2SO;
    end Interfaces;

    package Math "Library of mathematical functions as input/output blocks"
      import Modelica.SIunits;
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.Library;
      annotation (
        Documentation(info="
<HTML>
<p>
This package contains basic <b>mathematical operations</b>,
such as summation and multiplication, and basic <b>mathematical
functions</b>, such as <b>sqrt</b> and <b>sin</b>, as
input/output blocks. All blocks of this library can be either
connected with continuous blocks or with sampled-data blocks.
</p>
</HTML>
",     revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       New blocks added: RealToInteger, IntegerToReal, Max, Min, Edge, BooleanChange, IntegerChange.</li>
<li><i>August 7, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized (partly based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist).
</li>
</ul>
</html>"));

          block Feedback
      "Output difference between commanded and feedback input"

            input Interfaces.RealInput u1 annotation (Placement(transformation(
                extent={{-100,-20},{-60,20}}, rotation=0)));
            input Interfaces.RealInput u2 
              annotation (Placement(transformation(
              origin={0,-80},
              extent={{-20,-20},{20,20}},
              rotation=90)));
            output Interfaces.RealOutput y annotation (Placement(transformation(
                extent={{80,-10},{100,10}}, rotation=0)));
            annotation (
              Documentation(info="
<HTML>
<p>
This blocks computes output <b>y</b> as <i>difference</i> of the
commanded input <b>u1</b> and the feedback
input <b>u2</b>:
</p>
<pre>
    <b>y</b> = <b>u1</b> - <b>u2</b>;
</pre>
<p>
Example:
</p>
<pre>
     parameter:   n = 2

  results in the following equations:

     y = u1 - u2
</pre>

</HTML>
"),           Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Ellipse(
                extent={{-20,20},{20,-20}},
                lineColor={0,0,127},
                fillColor={235,235,235},
                fillPattern=FillPattern.Solid),
              Line(points={{-60,0},{-20,0}}, color={0,0,127}),
              Line(points={{20,0},{80,0}}, color={0,0,127}),
              Line(points={{0,-20},{0,-60}}, color={0,0,127}),
              Text(
                extent={{-14,0},{82,-94}},
                lineColor={0,0,0},
                textString="-"),
              Text(
                extent={{-150,94},{150,44}},
                textString="%name",
                lineColor={0,0,255})}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Ellipse(
                extent={{-20,20},{20,-20}},
                pattern=LinePattern.Solid,
                lineThickness=0.25,
                fillColor={235,235,235},
                fillPattern=FillPattern.Solid,
                lineColor={0,0,255}),
              Line(points={{-60,0},{-20,0}}, color={0,0,255}),
              Line(points={{20,0},{80,0}}, color={0,0,255}),
              Line(points={{0,-20},{0,-60}}, color={0,0,255}),
              Text(
                extent={{-12,10},{84,-84}},
                lineColor={0,0,0},
                textString="-")}));

          equation
            y = u1 - u2;
          end Feedback;

          block Add "Output the sum of the two inputs"
            extends Interfaces.SI2SO;
            parameter Real k1=+1 "Gain of upper input";
            parameter Real k2=+1 "Gain of lower input";
            annotation (
              Documentation(info="
<HTML>
<p>
This blocks computes output <b>y</b> as <i>sum</i> of the
two input signals <b>u1</b> and <b>u2</b>:
</p>
<pre>
    <b>y</b> = k1*<b>u1</b> + k2*<b>u2</b>;
</pre>
<p>
Example:
</p>
<pre>
     parameter:   k1= +2, k2= -3

  results in the following equations:

     y = 2 * u1 - 3 * u2
</pre>

</HTML>
"),           Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Text(
                extent={{-98,-52},{7,-92}},
                lineColor={0,0,0},
                textString="%k2"),
              Text(
                extent={{-100,90},{5,50}},
                lineColor={0,0,0},
                textString="%k1"),
              Text(
                extent={{-150,150},{150,110}},
                textString="%name",
                lineColor={0,0,255}),
              Line(points={{-100,60},{-40,60},{-30,40}}, color={0,0,255}),
              Ellipse(extent={{-50,50},{50,-50}}, lineColor={0,0,255}),
              Line(points={{-100,-60},{-40,-60},{-30,-40}}, color={0,0,255}),
              Line(points={{-15,-25.99},{15,25.99}}, color={0,0,0}),
              Rectangle(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Line(points={{50,0},{100,0}}, color={0,0,255}),
              Line(points={{-100,60},{-74,24},{-44,24}}, color={0,0,127}),
              Line(points={{-100,-60},{-74,-28},{-42,-28}}, color={0,0,127}),
              Ellipse(extent={{-50,50},{50,-50}}, lineColor={0,0,127}),
              Line(points={{50,0},{100,0}}, color={0,0,127}),
              Text(
                extent={{-38,34},{38,-34}},
                lineColor={0,0,0},
                textString="+"),
              Text(
                extent={{-100,52},{5,92}},
                lineColor={0,0,0},
                textString="%k1"),
              Text(
                extent={{-100,-52},{5,-92}},
                lineColor={0,0,0},
                textString="%k2")}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Rectangle(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-98,-52},{7,-92}},
                lineColor={0,0,0},
                textString="%k2"),
              Text(
                extent={{-100,90},{5,50}},
                lineColor={0,0,0},
                textString="%k1"),
              Line(points={{-100,60},{-40,60},{-30,40}}, color={0,0,255}),
              Ellipse(extent={{-50,50},{50,-50}}, lineColor={0,0,255}),
              Line(points={{-100,-60},{-40,-60},{-30,-40}}, color={0,0,255}),
              Line(points={{-15,-25.99},{15,25.99}}, color={0,0,0}),
              Rectangle(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Line(points={{50,0},{100,0}}, color={0,0,255}),
              Line(points={{-100,60},{-74,24},{-44,24}}, color={0,0,127}),
              Line(points={{-100,-60},{-74,-28},{-42,-28}}, color={0,0,127}),
              Ellipse(extent={{-50,50},{50,-50}}, lineColor={0,0,127}),
              Line(points={{50,0},{100,0}}, color={0,0,127}),
              Text(
                extent={{-38,34},{38,-34}},
                lineColor={0,0,0},
                textString="+"),
              Text(
                extent={{-100,52},{5,92}},
                lineColor={0,0,0},
                textString="k1"),
              Text(
                extent={{-100,-52},{5,-92}},
                lineColor={0,0,0},
                textString="k2")}));

          equation
            y = k1*u1 + k2*u2;
          end Add;

          block Product "Output product of the two inputs"
            extends Interfaces.SI2SO;
            annotation (
              Documentation(info="
<HTML>
<p>
This blocks computes the output <b>y</b> (element-wise)
as <i>product</i> of the corresponding elements of
the two inputs <b>u1</b> and <b>u2</b>:
</p>
<pre>
    y = u1 * u2;
</pre>

</HTML>
"),           Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{-100,60},{-40,60},{-30,40}}, color={0,0,127}),
              Line(points={{-100,-60},{-40,-60},{-30,-40}}, color={0,0,127}),
              Line(points={{50,0},{100,0}}, color={0,0,127}),
              Line(points={{-30,0},{30,0}}, color={0,0,0}),
              Line(points={{-15,25.99},{15,-25.99}}, color={0,0,0}),
              Line(points={{-15,-25.99},{15,25.99}}, color={0,0,0}),
              Ellipse(extent={{-50,50},{50,-50}}, lineColor={0,0,127})}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Rectangle(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Line(points={{-100,60},{-40,60},{-30,40}}, color={0,0,255}),
              Line(points={{-100,-60},{-40,-60},{-30,-40}}, color={0,0,255}),
              Line(points={{50,0},{100,0}}, color={0,0,255}),
              Line(points={{-30,0},{30,0}}, color={0,0,0}),
              Line(points={{-15,25.99},{15,-25.99}}, color={0,0,0}),
              Line(points={{-15,-25.99},{15,25.99}}, color={0,0,0}),
              Ellipse(extent={{-50,50},{50,-50}}, lineColor={0,0,255})}));

          equation
            y = u1*u2;
          end Product;

          block Division "Output first input divided by second input"
            extends Interfaces.SI2SO;
            annotation (
              Documentation(info="
<HTML>
<p>
This block computes the output <b>y</b> (element-wise)
by <i>dividing</i> the corresponding elements of
the two inputs <b>u1</b> and <b>u2</b>:
</p>
<pre>
    y = u1 / u2;
</pre>

</HTML>
"),           Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Line(points={{50,0},{100,0}}, color={0,0,127}),
              Line(points={{-30,0},{30,0}}, color={0,0,0}),
              Ellipse(
                extent={{-5,20},{5,30}},
                lineColor={0,0,0},
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-5,-20},{5,-30}},
                lineColor={0,0,0},
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid),
              Ellipse(extent={{-50,50},{50,-50}}, lineColor={0,0,127}),
              Text(
                extent={{-150,150},{150,110}},
                textString="%name",
                lineColor={0,0,255}),
              Line(points={{-100,60},{-66,60},{-40,30}}, color={0,0,127}),
              Line(points={{-100,-60},{0,-60},{0,-50}}, color={0,0,127})}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Rectangle(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Line(points={{50,0},{100,0}}, color={0,0,255}),
              Line(points={{-30,0},{30,0}}, color={0,0,0}),
              Ellipse(
                extent={{-5,20},{5,30}},
                lineColor={0,0,0},
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-5,-20},{5,-30}},
                lineColor={0,0,0},
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid),
              Ellipse(extent={{-50,50},{50,-50}}, lineColor={0,0,255}),
              Line(points={{-100,60},{-66,60},{-40,30}}, color={0,0,255}),
              Line(points={{-100,-60},{0,-60},{0,-50}}, color={0,0,255})}));

          equation
            y = u1/u2;
          end Division;

      block Min "Pass through the smallest signal"
        extends Interfaces.SI2SO;
        annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={Text(
                extent={{-90,36},{90,-36}},
                lineColor={160,160,164},
                textString="min()")}),
                                Documentation(info="<html>
<p>
This block computes the output <b>y</b> as <i>minimum</i> of
the two Real inputs <b>u1</b> and <b>u2</b>:
</p>
<pre>    y = <b>min</b> ( u1 , u2 );
</pre>
</html>
"));
      equation
         y = min(u1, u2);
      end Min;
    end Math;

    package Types
    "Library of constants and types with choices, especially to build menus"
      extends Modelica.Icons.Library;
      annotation ( Documentation(info="<HTML>
<p>
In this package <b>types</b> and <b>constants</b> are defined that are used
in library Modelica.Blocks. The types have additional annotation choices
definitions that define the menus to be built up in the graphical
user interface when the type is used as parameter in a declaration.
</p>
</HTML>"));

      type Init = enumeration(
        NoInit
          "No initialization (start values are used as guess values with fixed=false)", 

        SteadyState
          "Steady state initialization (derivatives of states are zero)",
        InitialState "Initialization with initial states",
        InitialOutput
          "Initialization with initial outputs (and steady state of the states if possibles)")
      "Enumeration defining initialization of a block" 
          annotation (Evaluate=true, Documentation(info="<html>

</html>"));
    end Types;
  end Blocks;

  package Icons "Library of icons"
    annotation (
      Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={
          Rectangle(
            extent={{-100,-100},{80,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{-120,135},{120,70}},
            lineColor={255,0,0},
            textString="%name"),
          Text(
            extent={{-90,40},{70,10}},
            lineColor={160,160,164},
            textString="Library"),
          Rectangle(
            extent={{-100,-100},{80,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{-90,40},{70,10}},
            lineColor={160,160,164},
            textString="Library"),
          Polygon(
            points={{-64,-20},{-50,-4},{50,-4},{36,-20},{-64,-20},{-64,-20}},
            lineColor={0,0,0},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-64,-20},{36,-84}},
            lineColor={0,0,0},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Text(
            extent={{-60,-24},{32,-38}},
            lineColor={128,128,128},
            textString="Library"),
          Polygon(
            points={{50,-4},{50,-70},{36,-84},{36,-20},{50,-4}},
            lineColor={0,0,0},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid)}),
                              Documentation(info="<html>
<p>
This package contains definitions for the graphical layout of
components which may be used in different libraries.
The icons can be utilized by inheriting them in the desired class
using \"extends\" or by directly copying the \"icon\" layer.
</p>

<dl>
<dt><b>Main Author:</b>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)<br>
    Oberpfaffenhofen<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
</dl>

<p>
Copyright &copy; 1998-2009, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p><br>
</HTML>
",   revisions="<html>
<ul>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Added new icons <b>Function</b>, <b>Enumerations</b> and <b>Record</b>.</li>
<li><i>June 6, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Replaced <b>model</b> keyword by <b>package</b> if the main
       usage is for inheriting from a package.<br>
       New icons <b>GearIcon</b> and <b>MotorIcon</b>.</li>
<li><i>Sept. 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Renaming package Icon to Icons.
       Model Advanced removed (icon not accepted on the Modelica meeting).
       New model Library2, which is the Library icon with enough place
       to add library specific elements in the icon. Icon also used in diagram
       level for models Info, TranslationalSensor, RotationalSensor.</li>
<li><i>July 15, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Model Caution renamed to Advanced, model Sensor renamed to
       TranslationalSensor, new model RotationalSensor.</li>
<li><i>June 30, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version.</li>
</ul>
<br>
</html>"));

    partial package Library "Icon for library"

      annotation (             Icon(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={
          Rectangle(
            extent={{-100,-100},{80,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{-85,35},{65,-85}},
            lineColor={0,0,255},
            textString="Library"),
          Text(
            extent={{-120,122},{120,73}},
            lineColor={255,0,0},
            textString="%name")}),
        Documentation(info="<html>
<p>
This icon is designed for a <b>library</b>.
</p>
</html>"));
    end Library;

    partial package Library2
    "Icon for library where additional icon elements shall be added"

      annotation (             Icon(coordinateSystem(
            preserveAspectRatio=true,
            extent={{-100,-100},{100,100}},
            grid={1,1}), graphics={
            Rectangle(
              extent={{-100,-100},{80,50}},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Polygon(
              points={{-100,50},{-80,70},{100,70},{80,50},{-100,50}},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Polygon(
              points={{100,70},{100,-80},{80,-100},{80,50},{100,70}},
              fillColor={235,235,235},
              fillPattern=FillPattern.Solid,
              lineColor={0,0,255}),
            Text(
              extent={{-120,125},{120,70}},
              lineColor={255,0,0},
              textString="%name"),
            Text(
              extent={{-90,40},{70,10}},
              lineColor={160,160,164},
              textString="Library")}),
        Documentation(info="<html>
<p>
This icon is designed for a <b>package</b> where a package
specific graphic is additionally included in the icon.
</p>
</html>"));
    end Library2;
  end Icons;

  package SIunits
  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Library2;
    annotation (
      Invisible=true,
      Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={Text(
            extent={{-63,-13},{45,-67}},
            lineColor={0,0,0},
            textString="[kg.m2]")}),
      Documentation(info="<html>
<p>This package provides predefined types, such as <i>Mass</i>,
<i>Angle</i>, <i>Time</i>, based on the international standard
on units, e.g.,
</p>

<pre>   <b>type</b> Angle = Real(<b>final</b> quantity = \"Angle\",
                     <b>final</b> unit     = \"rad\",
                     displayUnit    = \"deg\");
</pre>

<p>
as well as conversion functions from non SI-units to SI-units
and vice versa in subpackage
<a href=\"Modelica://Modelica.SIunits.Conversions\">Conversions</a>.
</p>

<p>
For an introduction how units are used in the Modelica standard library
with package SIunits, have a look at:
<a href=\"Modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
</p>

<p>
Copyright &copy; 1998-2009, Modelica Association and DLR.
</p>
<p>
<i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified
under the terms of the <b>Modelica license</b>, see the license conditions
and the accompanying <b>disclaimer</b>
<a href=\"Modelica://Modelica.UsersGuide.ModelicaLicense\">here</a>.</i>
</p>

</html>",   revisions="<html>
<ul>
<li><i>Dec. 14, 2005</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Add User's Guide and removed \"min\" values for Resistance and Conductance.</li>
<li><i>October 21, 2002</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
       Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
<li><i>June 6, 2000</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Introduced the following new types<br>
       type Temperature = ThermodynamicTemperature;<br>
       types DerDensityByEnthalpy, DerDensityByPressure,
       DerDensityByTemperature, DerEnthalpyByPressure,
       DerEnergyByDensity, DerEnergyByPressure<br>
       Attribute \"final\" removed from min and max values
       in order that these values can still be changed to narrow
       the allowed range of values.<br>
       Quantity=\"Stress\" removed from type \"Stress\", in order
       that a type \"Stress\" can be connected to a type \"Pressure\".</li>
<li><i>Oct. 27, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New types due to electrical library: Transconductance, InversePotential,
       Damping.</li>
<li><i>Sept. 18, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Renamed from SIunit to SIunits. Subpackages expanded, i.e., the
       SIunits package, does no longer contain subpackages.</li>
<li><i>Aug 12, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Type \"Pressure\" renamed to \"AbsolutePressure\" and introduced a new
       type \"Pressure\" which does not contain a minimum of zero in order
       to allow convenient handling of relative pressure. Redefined
       BulkModulus as an alias to AbsolutePressure instead of Stress, since
       needed in hydraulics.</li>
<li><i>June 29, 1999</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Bug-fix: Double definition of \"Compressibility\" removed
       and appropriate \"extends Heat\" clause introduced in
       package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
<li><i>April 8, 1998</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and Astrid Jaschinski:<br>
       Complete ISO 31 chapters realized.</li>
<li><i>Nov. 15, 1997</i>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>:<br>
       Some chapters realized.</li>
</ul>
</html>"),
      Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={
          Rectangle(
            extent={{169,86},{349,236}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{169,236},{189,256},{369,256},{349,236},{169,236}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Polygon(
            points={{369,256},{369,106},{349,86},{349,236},{369,256}},
            fillColor={235,235,235},
            fillPattern=FillPattern.Solid,
            lineColor={0,0,255}),
          Text(
            extent={{179,226},{339,196}},
            lineColor={160,160,164},
            textString="Library"),
          Text(
            extent={{206,173},{314,119}},
            lineColor={0,0,0},
            textString="[kg.m2]"),
          Text(
            extent={{163,320},{406,264}},
            lineColor={255,0,0},
            textString="Modelica.SIunits")}));
  end SIunits;
end Modelica;

package QHP

  package Library

    constant Real SecPerMin(unit="s/min") = 60;

    package Factors

      model SimpleMultiply
       extends QHP.Library.Interfaces.BaseFactorIcon;
       QHP.Library.Interfaces.RealInput_ u 
                    annotation (Placement(transformation(extent={{-102,-24},{-62,16}}),
              iconTransformation(extent={{-108,-10},{-88,10}})));

       Modelica.Blocks.Math.Product product  annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={0,-32})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      equation
        connect(yBase, product.u1) annotation (Line(
            points={{6,80},{6,30},{6,-20},{6,-20}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(product.y, y) annotation (Line(
            points={{-2.02067e-015,-43},{-2.02067e-015,-55.5},{0,-55.5},{0,-60}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(u, product.u2) annotation (Line(
            points={{-82,-4},{-6,-4},{-6,-20}},
            color={0,0,127},
            smooth=Smooth.None));
      end SimpleMultiply;

      model SplineDelayByDay3
       extends QHP.Library.Interfaces.BaseFactorIcon3;
       QHP.Library.Interfaces.RealInput_ u 
                    annotation (Placement(transformation(extent={{-118,44},{-78,
                  84}}),
              iconTransformation(extent={{-108,-10},{-88,10}})));
       parameter Real Tau;
       parameter Real[3,3] data;
        Curves.Curve3 curve(
          x=data[:, 1],
          y=data[:, 2],
          slope=data[:, 3]) 
          annotation (Placement(transformation(extent={{-68,58},{-48,78}})));
        Modelica.Blocks.Math.Product product annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={0,-32})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
        Modelica.Blocks.Continuous.Integrator integrator(
            y_start=1, k=(1/(Tau*1440))/Library.SecPerMin) 
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={-26,12})));
        Modelica.Blocks.Math.Feedback feedback annotation (Placement(
              transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={-26,44})));
      equation
        connect(curve.u, u) annotation (Line(
            points={{-68,68},{-83,68},{-83,64},{-98,64}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(yBase, product.u1) annotation (Line(
            points={{6,80},{6,30},{6,-20},{6,-20}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(product.y, y) annotation (Line(
            points={{-2.02067e-015,-43},{-2.02067e-015,-55.5},{0,-55.5},{0,-60}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(curve.val, feedback.u1) annotation (Line(
            points={{-47.8,68},{-26,68},{-26,52}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(feedback.y, integrator.u) annotation (Line(
            points={{-26,35},{-26,29.5},{-26,24},{-26,24}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(integrator.y, feedback.u2) annotation (Line(
            points={{-26,1},{-26,-8},{-50,-8},{-50,44},{-34,44}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(integrator.y, product.u2) annotation (Line(
            points={{-26,1},{-26,-8},{-6,-8},{-6,-20}},
            color={0,0,127},
            smooth=Smooth.None));
      end SplineDelayByDay3;
    end Factors;

    package Curves

      model Curve3
      // extends Library.BaseModel;
       parameter Real x[3];
       parameter Real y[3];
       parameter Real slope[3];

       QHP.Library.Interfaces.RealInput_ u 
                    annotation (Placement(transformation(extent={{-100,-60},{-60,-20}}),
              iconTransformation(extent={{-120,-20},{-80,20}})));
       QHP.Library.Interfaces.RealOutput_ val 
                       annotation (Placement(transformation(extent={{60,-20},{100,20}}),
              iconTransformation(extent={{82,-20},{122,20}})));

       //parameter Integer iconNP = 20;
       //Real iconU[iconNP];
       //Real iconPoint[iconNP,2](final unit="mm"); // = {{-70,-42},{-22,38},{32,36},{82,-74},{72,-36}};
       //Real iconActualPoint[2,2](final unit="mm");

    protected
       Real a[size(x,1)-1,4];
       Real c1;
       Real c2;
       Integer iFrom;

       //Integer iconFrom[20];

      equation
       // only icon drawing
       /*
       iconPoint[1,1] = -80;
       iconU[1]=min(x[j] for j in 1:size(x,1));
       iconPoint[1,2] = (-50 +
                        (100/(max(y[j] for j in 1:size(y,1))-min(y[j] for j in 1:size(y,1)))) *
                          (a[iconFrom[1],1]*(min(x[j] for j in 1:size(x,1)))^3 +
                           a[iconFrom[1],2]*(min(x[j] for j in 1:size(x,1)))^2 +
                           a[iconFrom[1],3]*(min(x[j] for j in 1:size(x,1))) +
                           a[iconFrom[1],4]
                           - min(y[j] for j in 1:size(y,1))));
       iconFrom[1] = if (size(x,1)==4) then (if (min(x[j] for j in 1:size(x,1)))<=x[2] then 1 else 
                          if (min(x[j] for j in 1:size(x,1)))<=x[3] then 2 else 3) else 
                     if (size(x,1)==3) then (if (min(x[j] for j in 1:size(x,1)))<=x[2] then 1 else 2) else 
                     1;

       for i in 1:(iconNP-1) loop
          iconPoint[i+1,1] = i*(160/(iconNP-1)) - 80;
      //x.. min(x)+ (i*(max(x)-min(x)))/(iconNP-1);
          iconU[i+1]=(min(x[j] for j in 1:size(x,1))+(i*(max(x[j] for j in 1:size(x,1))-min(x[j] for j in 1:size(x,1))))/(iconNP-1));
          iconPoint[i+1,2] = (-50 +
                        (100/(max(y[j] for j in 1:size(y,1))-min(y[j] for j in 1:size(y,1)))) *
                          (a[iconFrom[i],1]*iconU[i+1]^3 +
                           a[iconFrom[i],2]*iconU[i+1]^2 +
                           a[iconFrom[i],3]*iconU[i+1] +
                           a[iconFrom[i],4]
                           - min(y[j] for j in 1:size(y,1))));
          iconFrom[i+1] = if (size(x,1)==8) then (if iconU[i+1]<=x[2] then 1 else if iconU[i+1]<=x[3] then 2 else if iconU[i+1]<x[4] then 3 else if iconU[i+1]<x[5] then 4 else if iconU[i+1]<x[6] then 5 else if iconU[i+1]<x[7] then 6 else 7) else 
                          if (size(x,1)==7) then (if iconU[i+1]<=x[2] then 1 else if iconU[i+1]<=x[3] then 2 else if iconU[i+1]<x[4] then 3 else if iconU[i+1]<x[5] then 4 else if iconU[i+1]<x[6] then 5 else 6) else 
                          if (size(x,1)==6) then (if iconU[i+1]<=x[2] then 1 else if iconU[i+1]<=x[3] then 2 else if iconU[i+1]<x[4] then 3 else if iconU[i+1]<x[4] then 4 else 5) else 
                          if (size(x,1)==5) then (if iconU[i+1]<=x[2] then 1 else if iconU[i+1]<=x[3] then 2 else if iconU[i+1]<x[4] then 3 else 4) else 
                          if (size(x,1)==4) then (if iconU[i+1]<=x[2] then 1 else if iconU[i+1]<=x[3] then 2 else 3) else 
                          if (size(x,1)==3) then (if iconU[i+1]<=x[2] then 1 else 2) else 
                             1;
       end for;

       iconActualPoint[1,1]=(u-min(x[j] for j in 1:size(x,1)))*160/(max(x[j] for j in 1:size(x,1))-min(x[j] for j in 1:size(x,1))) - 80 -2;
       iconActualPoint[1,2]=(val-min(y[j] for j in 1:size(y,1)))*100/(max(y[j] for j in 1:size(y,1))-min(y[j] for j in 1:size(y,1))) - 50 -2;
       iconActualPoint[2,1]=iconActualPoint[1,1]+4;
       iconActualPoint[2,2]=iconActualPoint[1,2]+4;
*/
      //main equations
       for i in 1:size(x,1)-1 loop
         a[i,1]*x[i]^3 + a[i,2]*x[i]^2 + a[i,3]*x[i] + a[i,4] = y[i];
         3*a[i,1]*x[i]^2 + 2*a[i,2]*x[i] + a[i,3] = slope[i];
         a[i,1]*x[i+1]^3 + a[i,2]*x[i+1]^2 + a[i,3]*x[i+1] + a[i,4] = y[i+1];
         3*a[i,1]*x[i+1]^2 + 2*a[i,2]*x[i+1] + a[i,3] = slope[i+1];
       end for;
       slope[1]*x[1]+c1 = y[1];
       slope[size(x,1)]*x[size(x,1)]+c2 = y[size(x,1)];

       val = if (u<x[1]) then slope[1]*u + c1 else 
              if (u>x[size(x,1)]) then slope[size(x,1)]*u + c2 else 
              a[iFrom,1]*u^3 + a[iFrom,2]*u^2 + a[iFrom,3]*u + a[iFrom,4];

       iFrom =   //if (size(x,1)==8) then (if u<=x[2] then 1 else if u<=x[3] then 2 else if u<x[4] then 3 else if u<x[5] then 4 else if u<x[6] then 5 else if u<x[7] then 6 else 7) else 
                 //if (size(x,1)==7) then (if u<=x[2] then 1 else if u<=x[3] then 2 else if u<x[4] then 3 else if u<x[5] then 4 else if u<x[6] then 5 else 6) else 
                 //if (size(x,1)==6) then (if u<=x[2] then 1 else if u<=x[3] then 2 else if u<x[4] then 3 else if u<x[4] then 4 else 5) else 
                 //if (size(x,1)==5) then (if u<=x[2] then 1 else if u<=x[3] then 2 else if u<x[4] then 3 else 4) else 
                 //if (size(x,1)==4) then (if u<=x[2] then 1 else if u<=x[3] then 2 else 3) else 
                 //if (size(x,1)==3) then (if u<=x[2] then 1 else 2) else 
                 //    1;
                 if u<=x[2] then 1 else 2;
                 
        annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={
              Rectangle(
                extent={{-100,100},{100,-100}},
                lineColor={0,0,0},
                fillPattern=FillPattern.Solid,
                fillColor={255,255,255}),
              Text(
                extent={{-94,-44},{100,-100}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                textString="%name"),
              Text(
                extent={{-100,100},{100,50}},
                lineColor={0,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                textString="curve"),
              Line(
                points=DynamicSelect({{-100,0},{100,0}}, iconPoint),
                color={0,0,0},
                smooth=Smooth.None),
              Ellipse(
                extent=DynamicSelect({{0,0},{0,0}}, iconActualPoint),
                lineColor={0,0,0},
                fillColor={255,0,0},
                fillPattern=FillPattern.Solid)}),
       Diagram(coordinateSystem(preserveAspectRatio=false,
                         extent={{-100,-100},{100,100}}), graphics));

      end Curve3;
    end Curves;

    package VolumeFlow

      connector VolumeFlow
        Real volume(  final quantity="Volume", final unit="ml");
        flow Real q(  final quantity="Flow", final unit="ml/min");
      end VolumeFlow;

      connector PositiveVolumeFlow
        extends VolumeFlow;

      annotation (
          defaultComponentName="q_in",
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[1, 1],
            component=[20, 20],
            scale=0.2),
          Icon(coordinateSystem(extent=[-100, -100; 100, 100]), Polygon(points=[-50,-5;
                  0,40; 50,-5; 0,-51; -50,-5],            style(
                color=74,
                rgbcolor={0,0,0},
                fillColor=0,
                rgbfillColor={0,0,0}))),
          Diagram(Polygon(points=[-21,-3; 5,23; 31,-3; 5,-29; -21,-3],   style(
                color=74,
                rgbcolor={0,0,0},
                fillColor=0,
                rgbfillColor={0,0,0})), Text(
              extent=[-105,-38; 115,-83],
              string="%name",
              style(color=0, rgbcolor={0,0,0}))),
          Documentation(info="<html>
<p>
Connector with one flow signal of type Real.
</p>
</html>"));
      end PositiveVolumeFlow;

      connector NegativeVolumeFlow
         extends VolumeFlow;

      annotation (
          defaultComponentName="q_out",
          Coordsys(
            extent=[-100, -100; 100, 100],
            grid=[1, 1],
            component=[20, 20],
            scale=0.2),
          Icon(coordinateSystem(extent=[-100, -100; 100, 100]), Polygon(points=[-50,-5;
                  0,40; 50,-5; 0,-51; -50,-5],            style(
                color=74,
                rgbcolor={0,0,0},
                fillColor=0,
                rgbfillColor={255,255,255}))),
          Diagram(Polygon(points=[-21,-3; 5,23; 31,-3; 5,-29; -21,-3],   style(
                color=74,
                rgbcolor={0,0,0},
                fillColor=0,
                rgbfillColor={255,255,255})), Text(
              extent=[-105,-38; 115,-83],
              string="%name",
              style(color=0, rgbcolor={0,0,0}))),
          Documentation(info="<html>
<p>
Connector with one flow signal of type Real.
</p>
</html>"));
      end NegativeVolumeFlow;

      model InputPump

        NegativeVolumeFlow q_out 
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{90,-10},{110,10}})));
        QHP.Library.Interfaces.RealInput desiredFlow(   final quantity="Flow", final unit
          =                                                                               "ml/min") 
                                      annotation ( extent = [-10,50;10,70], rotation = -90);

       annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={
              Rectangle(
                extent={{-100,-50},{100,50}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-80,25},{80,0},{-80,-25},{-80,25}},
                lineColor={0,0,127},
                fillColor={0,0,127},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-150,-100},{150,-60}},
                textString="%name",
                lineColor={0,0,255})}), Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics));

      equation
        q_out.q = - desiredFlow;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end InputPump;

      model OutputPump

        PositiveVolumeFlow q_in 
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{90,-10},{110,10}}), iconTransformation(
                extent={{-110,-10},{-90,10}})));
        QHP.Library.Interfaces.RealInput desiredFlow(   final quantity="Flow", final unit
          =                                                                               "ml/min") 
                                      annotation ( extent = [-10,50;10,70], rotation = -90);

       annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={
              Rectangle(
                extent={{-100,-50},{100,50}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-80,25},{80,0},{-80,-25},{-80,25}},
                lineColor={0,0,127},
                fillColor={0,0,127},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-150,-100},{150,-60}},
                textString="%name",
                lineColor={0,0,255})}), Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics));

      equation
        q_in.q = desiredFlow;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end OutputPump;

      model VolumeCompartment
        extends QHP.Library.Interfaces.BaseModel;

        PositiveVolumeFlow inflow 
                              annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{-110,-10},{-90,10}})));
        NegativeVolumeFlow outflow 
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{90,-10},{110,10}})));
        parameter Real initialVolume(   final quantity="Volume", final unit="ml");

        Modelica.Blocks.Interfaces.RealOutput Volume(   final quantity="Volume", final unit
          =                                                                                 "ml") 
          annotation (Placement(transformation(extent={{-50,-110},{-30,-90}}, rotation=-90)));
      initial equation
        Volume = initialVolume;
      equation
        der(Volume) = ( inflow.q + outflow.q)  / Library.SecPerMin;

        inflow.volume = Volume;
        outflow.volume = Volume;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end VolumeCompartment;

      model Clearance

        PositiveVolumeFlow inflow 
                              annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{-110,-10},{-90,10}})));
        parameter Real partFromVolumePerDay(   final quantity="DayFraction", final unit
          =                                                                             "1/d");

      equation
        inflow.q = inflow.volume * (1/1440)*partFromVolumePerDay;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics), Icon(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics={
              Rectangle(
                extent={{-100,-50},{100,50}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-80,25},{80,0},{-80,-25},{-80,25}},
                lineColor={0,0,127},
                fillColor={0,0,127},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-150,-100},{150,-60}},
                textString="%name",
                lineColor={0,0,255})}));
      end Clearance;
    end VolumeFlow;

    package Interfaces

      partial model BaseModel

        annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                -100},{100,100}}), graphics={Rectangle(
              extent={{-100,100},{100,-100}},
              lineColor={0,127,0},
              fillColor={215,215,215},
              fillPattern=FillPattern.Sphere), Text(
              extent={{-100,-74},{100,-52}},
              lineColor={0,0,177},
              fillPattern=FillPattern.VerticalCylinder,
              fillColor={215,215,215},
              textString="%name")}));
      end BaseModel;

      partial model BaseFactorIcon

       annotation (
          Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,20},{100,-20}},
                lineColor={95,95,95},
                fillColor={255,255,255},
                fillPattern=FillPattern.Sphere), Text(
                extent={{-90,-10},{92,10}},
                textString="%name",
                lineColor={0,0,0})}), Diagram(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics));
        RealInput_ yBase annotation (Placement(transformation(extent={{-20,-20},{
                  20,20}},
              rotation=270,
              origin={6,80}),
              iconTransformation(extent={{-10,10},{10,30}}, rotation=-90)));
        RealOutput_ y annotation (Placement(transformation(extent={{-20,-20},{20,
                  20}},
              rotation=270,
              origin={0,-60}),
              iconTransformation(extent={{-10,-30},{10,-10}}, rotation=-90)));

      end BaseFactorIcon;

      partial model BaseFactorIcon3

       annotation (
          Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,20},{100,-20}},
                lineColor={0,127,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Sphere), Text(
                extent={{-90,-10},{92,10}},
                textString="%name",
                lineColor={0,0,0})}), Diagram(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics));
        RealInput_ yBase annotation (Placement(transformation(extent={{-20,-20},{
                  20,20}},
              rotation=270,
              origin={6,80}),
              iconTransformation(extent={{-10,10},{10,30}}, rotation=-90)));
        RealOutput_ y annotation (Placement(transformation(extent={{-20,-20},{20,
                  20}},
              rotation=270,
              origin={0,-60}),
              iconTransformation(extent={{-10,-30},{10,-10}}, rotation=-90)));

      end BaseFactorIcon3;

      partial connector SignalBusBlue "Icon for signal bus"

        annotation (
          Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2},
              initialScale=0.2), graphics={
            Rectangle(
              extent={{-20,2},{20,-2}},
              lineColor={255,204,51},
              lineThickness=0.5),
            Polygon(
              points={{-80,50},{80,50},{100,30},{80,-40},{60,-50},{-60,-50},{-80,
                  -40},{-100,30},{-80,50}},
              lineColor={0,0,0},
              fillColor={0,0,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-65,25},{-55,15}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-5,25},{5,15}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{55,25},{65,15}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-35,-15},{-25,-25}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{25,-15},{35,-25}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid)}),
          Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2},
              initialScale=0.2), graphics={
            Polygon(
              points={{-40,25},{40,25},{50,15},{40,-20},{30,-25},{-30,-25},{-40,
                  -20},{-50,15},{-40,25}},
              lineColor={0,0,0},
              fillColor={0,0,255},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-32.5,7.5},{-27.5,12.5}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-2.5,12.5},{2.5,7.5}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{27.5,12.5},{32.5,7.5}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{-17.5,-7.5},{-12.5,-12.5}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Ellipse(
              extent={{12.5,-7.5},{17.5,-12.5}},
              lineColor={0,0,0},
              fillColor={0,0,0},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-150,70},{150,40}},
              lineColor={0,0,0},
              textString="%name")}),
          Documentation(info="<html>
<p>
This icon is designed for a <b>signal bus</b> connector.
</p>
</html>"));

      end SignalBusBlue;

      connector RealInput = input Real "'input Real' as connector" 
        annotation (defaultComponentName="u",
        Icon(graphics={Polygon(
            points={{-100,100},{100,0},{-100,-100},{-100,100}},
            lineColor={0,0,127},
            fillColor={0,0,127},
            fillPattern=FillPattern.Solid), Text(
            extent={{98,-50},{724,58}},
            lineColor={0,0,127},
            textString="%name")},
             coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.2)),
        Diagram(coordinateSystem(
              preserveAspectRatio=true, initialScale=0.2,
              extent={{-100,-100},{100,100}},
              grid={1,1}), graphics={Polygon(
            points={{0,50},{100,0},{0,-50},{0,50}},
            lineColor={0,0,127},
            fillColor={0,0,127},
            fillPattern=FillPattern.Solid), Text(
            extent={{-10,85},{-10,60}},
            lineColor={0,0,127},
            textString="%name")}),
          Documentation(info="<html>
<p>
Connector with one input signal of type Real.
</p>
</html>"));

      connector RealInput_ =input Real "'input Real' as connector" 
        annotation (defaultComponentName="u",
        Icon(graphics={Polygon(
              points={{-100,100},{100,0},{-100,-100},{-100,100}},
              lineColor={0,0,127},
              fillColor={0,0,127},
              fillPattern=FillPattern.Solid)},
             coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.2)),
        Diagram(coordinateSystem(
              preserveAspectRatio=true, initialScale=0.2,
              extent={{-100,-100},{100,100}},
              grid={1,1}), graphics={Polygon(
              points={{0,50},{100,0},{0,-50},{0,50}},
              lineColor={0,0,127},
              fillColor={0,0,127},
              fillPattern=FillPattern.Solid), Text(
              extent={{-10,85},{-10,60}},
              lineColor={0,0,127},
              textString="%name")}),
          Documentation(info="<html>
<p>
Connector with one input signal of type Real.
</p>
</html>"));

      connector RealOutput_ =output Real "'output Real' as connector" 
        annotation (defaultComponentName="u",
        Icon(graphics={Polygon(
            points={{-100,100},{100,0},{-100,-100},{-100,100}},
            lineColor={0,0,127},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid)},
             coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=true, initialScale=0.2)),
        Diagram(coordinateSystem(
              preserveAspectRatio=true, initialScale=0.2,
              extent={{-100,-100},{100,100}},
              grid={1,1}), graphics={Polygon(
            points={{0,50},{100,0},{0,-50},{0,50}},
            lineColor={0,0,127},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid)}),
          Documentation(info="<html>
<p>
Connector with one input signal of type Real.
</p>
</html>"));

        expandable connector BusConnector
      "Empty control bus that is adapted to the signals connected to it"
          extends QHP.Library.Interfaces.SignalBusBlue;

          annotation (
            Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},
                {100,100}}), graphics={Rectangle(
              extent={{-20,2},{22,-2}},
              lineColor={0,0,255},
              lineThickness=0.5)}),
            Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                -100},{100,100}}),
                    graphics),
            Documentation(info="<html>
<p>
This connector defines the \"expandable connector\" ControlBus that
is used as bus in the
<a href=\"Modelica://Modelica.Blocks.Examples.BusUsage\">BusUsage</a> example.
Note, this connector is \"empty\". When using it, the actual content is
constructed by the signals connected to this bus.
</p>
</html>"));

        end BusConnector;
    end Interfaces;

    package Blocks

          block Constant "Generate constant signal of type Real"
            parameter Real k(start=1) "Constant output value";

            QHP.Library.Interfaces.RealOutput_ y
        "Connector of Real output signal" 
              annotation (Placement(transformation(extent={{100,-10},{120,10}},
                  rotation=0)));

            annotation (
              Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2},
              initialScale=0.04), graphics={Rectangle(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,255},
              fillPattern=FillPattern.Solid,
              fillColor={255,255,255}), Text(
              extent={{-100,-40},{100,46}},
              lineColor={0,0,0},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid,
              textString="%k")}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2},
              initialScale=0.04), graphics={Text(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,0},
                textString="%k")}),
          Documentation(info="<html>
<p>
The Real output y is a constant signal:
</p>
</html>"));
          equation
            y = k;
          end Constant;

          block FlowConstant "Generate constant signal in units ml/min"
            parameter Real k(start=1, final quantity="Flow", final unit="ml/min")
        "Constant output value";

            QHP.Library.Interfaces.RealOutput_ y( final quantity="Flow", final unit =     "ml/min")
        "Connector of Real output signal" 
              annotation (Placement(transformation(extent={{100,-10},{120,10}},
                  rotation=0)));

            annotation (
              Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2},
              initialScale=0.04), graphics={
              Rectangle(
                extent={{-100,100},{100,-100}},
                lineColor={0,0,255},
                fillPattern=FillPattern.Solid,
                fillColor={255,255,255}),
              Text(
                extent={{-100,0},{100,100}},
                lineColor={0,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                textString="%k"),
              Text(
                extent={{-100,-100},{100,-40}},
                lineColor={0,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                textString="min"),
              Text(
                extent={{-100,-46},{100,30}},
                lineColor={0,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                textString="____"),
              Text(
                extent={{-100,-38},{100,16}},
                lineColor={0,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                textString="ml")}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2},
              initialScale=0.04), graphics={Text(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,0},
                textString="%k")}),
          Documentation(info="<html>
<p>
The Real output y is a constant signal:
</p>
</html>"));
          equation
            y = k;
          end FlowConstant;
    end Blocks;
  end Library;

  package Blood

    package BlooodVolume

      model RedCells
        extends QHP.Library.Interfaces.BaseModel;
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
        Library.VolumeFlow.Clearance RBCClearance(partFromVolumePerDay=1/120) 
          annotation (Placement(transformation(extent={{48,-8},{68,12}})));
        Library.VolumeFlow.VolumeCompartment RBCVolume(initialVolume=2516) 
          annotation (Placement(transformation(extent={{0,-8},{20,12}})));
        Library.VolumeFlow.InputPump transfusion 
          annotation (Placement(transformation(extent={{-48,28},{-28,48}})));
        Library.VolumeFlow.OutputPump hemmorrhage 
          annotation (Placement(transformation(extent={{48,28},{68,48}})));
        Modelica.Blocks.Math.Add add 
          annotation (Placement(transformation(extent={{16,-70},{24,-62}})));
        Modelica.Blocks.Math.Min min 
          annotation (Placement(transformation(extent={{48,-84},{56,-76}})));
        Modelica.Blocks.Math.Division division 
          annotation (Placement(transformation(extent={{36,-82},{44,-74}})));
        QHP.Library.Blocks.Constant const(
                               k=1) 
          annotation (Placement(transformation(extent={{36,-94},{44,-86}})));
        Modelica.Blocks.Math.Division HtcFract 
          annotation (Placement(transformation(extent={{30,-48},{38,-40}})));
        Library.Curves.Curve3 HtcOnVisc(
          x={0,.44,.8},
          y={.5,1,5},
          slope={.8,3,30}) 
          annotation (Placement(transformation(extent={{44,-54},{64,-34}})));
        Modelica.Blocks.Math.Division division1 
          annotation (Placement(transformation(extent={{76,-40},{84,-32}})));
        QHP.Library.Blocks.Constant const1(
                               k=1) 
          annotation (Placement(transformation(extent={{62,-30},{70,-22}})));
        QHP.Library.Factors.SplineDelayByDay3 EPOEffect(
          Tau=3,
          data={{0.0,0.0,0},{1.3,1.0,1.0},{4.0,4.0,0}}) 
          annotation (Placement(transformation(extent={{-76,6},{-56,26}})));
        QHP.Library.Blocks.FlowConstant RBCBaseSecretionRate(k=0.013889) 
          annotation (Placement(transformation(extent={{-80,22},{-70,32}})));
        Library.VolumeFlow.InputPump RBCSecretion 
          annotation (Placement(transformation(extent={{-76,-8},{-56,12}})));
        Library.Interfaces.BusConnector busConnector 
          annotation (Placement(transformation(extent={{-98,56},{-78,76}})));
        QHP.Library.Blocks.Constant const2(
                               k=1) 
          annotation (Placement(transformation(extent={{14,-30},{22,-22}})));
        Modelica.Blocks.Math.Feedback PVCrit 
          annotation (Placement(transformation(extent={{28,-30},{36,-22}})));
        Library.Blocks.Constant Constant4(k=8.4) 
          annotation (Placement(transformation(extent={{-14,-34},{-22,-26}})));
        Library.Blocks.Constant Constant1(k=0.44) 
          annotation (Placement(transformation(extent={{-68,-50},{-60,-42}})));
        Library.Factors.SimpleMultiply hematocritEffect 
          annotation (Placement(transformation(extent={{-34,-52},{-14,-32}})));
        Modelica.Blocks.Math.Division division2 
          annotation (Placement(transformation(extent={{-52,-46},{-44,-38}})));
        Library.Blocks.Constant Constant5(k=5.4) 
          annotation (Placement(transformation(extent={{24,90},{16,98}})));
        Library.Blocks.Constant Constant6(k=0.005) 
          annotation (Placement(transformation(extent={{24,82},{16,90}})));
        Library.Blocks.Constant Constant7(k=0.005) 
          annotation (Placement(transformation(extent={{24,74},{16,82}})));
      equation
        connect(RBCVolume.outflow, RBCClearance.inflow) 
                                                     annotation (Line(
            points={{20,2},{48,2}},
            color={0,0,0},
            smooth=Smooth.None));
        connect(busConnector.Transfusion_RBCRate, transfusion.desiredFlow) 
                                                            annotation (Line(
            points={{-88,66},{-86,66},{-86,60},{-38,60},{-38,44}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(transfusion.q_out, RBCVolume.inflow) 
                                                   annotation (Line(
            points={{-28,38},{-14,38},{-14,2},{0,2}},
            color={0,0,0},
            smooth=Smooth.None));
        connect(hemmorrhage.q_in, RBCVolume.outflow) 
                                                    annotation (Line(
            points={{48,38},{34,38},{34,2},{20,2}},
            color={0,0,0},
            smooth=Smooth.None));
        connect(busConnector.Hemorrhage_RBCRate, hemmorrhage.desiredFlow) 
                                                            annotation (Line(
            points={{-88,66},{-86,66},{-86,60},{58,60},{58,44}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(busConnector.PlasmaVol_Vol, add.u2) annotation (Line(
            points={{-88,66},{-86,66},{-86,-68.4},{15.2,-68.4}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(RBCVolume.Volume, add.u1) annotation (Line(
            points={{6,-8},{6,-63.6},{15.2,-63.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(add.y, busConnector.BloobVolume) annotation (Line(
            points={{24.4,-66},{88,-66},{88,66},{-88,66}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(division.y,min. u1) annotation (Line(
            points={{44.4,-78},{45.8,-78},{45.8,-77.6},{47.2,-77.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(busConnector.Vesseles_V0, division.u2) annotation (Line(
            points={{-88,66},{-86,66},{-86,-80.4},{35.2,-80.4}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(add.y, division.u1) annotation (Line(
            points={{24.4,-66},{26,-66},{26,-75.6},{35.2,-75.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(const.y,min. u2) annotation (Line(
            points={{44.4,-90},{46,-90},{46,-82.4},{47.2,-82.4}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(min.y, busConnector.BloodVol_CollapsedEffect) annotation (Line(
            points={{56.4,-80},{88,-80},{88,66},{-88,66}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(HtcFract.u2, add.y) annotation (Line(
            points={{29.2,-46.4},{26,-46.4},{26,-66},{24.4,-66}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(HtcFract.u1, RBCVolume.Volume) annotation (Line(
            points={{29.2,-41.6},{6,-41.6},{6,-8}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(HtcFract.y, HtcOnVisc.u) annotation (Line(
            points={{38.4,-44},{44,-44}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(const1.y, division1.u1) annotation (Line(
            points={{70.4,-26},{72,-26},{72,-33.6},{75.2,-33.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(HtcOnVisc.val, division1.u2) annotation (Line(
            points={{64.2,-44},{73.5,-44},{73.5,-38.4},{75.2,-38.4}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(division1.y, busConnector.Viscosity_ConductanceEffect) annotation (Line(
            points={{84.4,-36},{88,-36},{88,66},{-88,66}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(RBCBaseSecretionRate.y, EPOEffect.yBase)              annotation (
            Line(
            points={{-69.5,27},{-66,27},{-66,18}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(EPOEffect.u, busConnector.EPOPool_Log10Conc)              annotation (Line(
            points={{-75.8,16},{-86.9,16},{-86.9,66},{-88,66}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(RBCSecretion.desiredFlow, EPOEffect.y) 
                                                 annotation (Line(
            points={{-66,8},{-66,14}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(RBCSecretion.q_out, RBCVolume.inflow) annotation (Line(
            points={{-56,2},{0,2}},
            color={0,0,0},
            smooth=Smooth.None));
        connect(HtcFract.y, busConnector.BloodVol_Hct) annotation (Line(
            points={{38.4,-44},{40,-44},{40,-16},{88,-16},{88,66},{-88,66}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(RBCVolume.Volume, busConnector.RBCVol_Vol) annotation (Line(
            points={{6,-8},{6,-16},{88,-16},{88,66},{-88,66}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,-5},{6,-5}}));
        connect(const2.y, PVCrit.u1) annotation (Line(
            points={{22.4,-26},{28.8,-26}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(HtcFract.y, PVCrit.u2) annotation (Line(
            points={{38.4,-44},{40,-44},{40,-32},{32,-32},{32,-29.2}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(PVCrit.y, busConnector.BloodVol_PVCrit) annotation (Line(
            points={{35.6,-26},{40,-26},{40,-16},{88,-16},{88,66},{-88,66}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
        connect(Constant4.y, hematocritEffect.yBase) annotation (Line(
            points={{-22.4,-30},{-24,-30},{-24,-40}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(hematocritEffect.y, busConnector.ctHb) annotation (Line(
            points={{-24,-44},{-24,-52},{-88,-52},{-88,66}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
        connect(division2.y, hematocritEffect.u) annotation (Line(
            points={{-43.6,-42},{-33.8,-42}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(Constant1.y, division2.u2) annotation (Line(
            points={{-59.6,-46},{-57.2,-46},{-57.2,-44.4},{-52.8,-44.4}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(HtcFract.y, division2.u1) annotation (Line(
            points={{38.4,-44},{40,-44},{40,-36},{-60,-36},{-60,-39.6},{-52.8,
                -39.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(busConnector.cDPG,Constant5. y) annotation (Line(
            points={{-88,66},{-6,66},{-6,94},{15.6,94}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
        connect(busConnector.FMetHb,Constant6. y) annotation (Line(
            points={{-88,66},{-6,66},{-6,86},{15.6,86}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
        connect(busConnector.FHbF,Constant7. y) annotation (Line(
            points={{-88,66},{-6,66},{-6,78},{15.6,78}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
      end RedCells;
    end BlooodVolume;
  end Blood;
  annotation (uses(Modelica(version="3.1")));

  package test

    model TestRedCells

      Blood.BlooodVolume.RedCells redCells 
        annotation (Placement(transformation(extent={{8,-12},{28,8}})));
      Library.Blocks.Constant PlasmaVol(k=3500) 
        annotation (Placement(transformation(extent={{-84,-20},{-76,-12}})));
      Library.Blocks.Constant const4(
                              k=0) 
        annotation (Placement(transformation(extent={{-82,-6},{-76,0}})));
      Library.Blocks.Constant const5(
                              k=1.3) 
        annotation (Placement(transformation(extent={{-82,2},{-76,8}})));
      Library.Interfaces.BusConnector busConnector 
        annotation (Placement(transformation(extent={{-34,-8},{-22,4}})));
      Library.Blocks.Constant const1(
                              k=0) 
        annotation (Placement(transformation(extent={{-82,12},{-76,18}})));
      Library.Blocks.Constant PlasmaVol1(k=3300) 
        annotation (Placement(transformation(extent={{-78,-40},{-70,-32}})));
      annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
              -100},{100,100}}),        graphics));
    equation
      connect(const5.y, busConnector.EPOPool_Log10Conc) annotation (Line(
          points={{-75.7,5},{-47.85,5},{-47.85,-2},{-28,-2}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(const4.y, busConnector.Transfusion_RBCRate) annotation (Line(
          points={{-75.7,-3},{-46.85,-3},{-46.85,-2},{-28,-2}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(const1.y, busConnector.Hemorrhage_RBCRate) annotation (Line(
          points={{-75.7,15},{-46.85,15},{-46.85,-2},{-28,-2}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(PlasmaVol.y, busConnector.PlasmaVol_Vol) annotation (Line(
          points={{-75.6,-16},{-52,-16},{-52,-2},{-28,-2}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(PlasmaVol1.y, busConnector.Vesseles_V0) annotation (Line(
          points={{-69.6,-36},{-48,-36},{-48,-2},{-28,-2}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(busConnector, redCells.busConnector) annotation (Line(
          points={{-28,-2},{-10,-2},{-10,4.6},{9.2,4.6}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
    end TestRedCells;
  end test;
end QHP;
model QHP_test_TestRedCells
 extends QHP.test.TestRedCells;
  annotation(experiment(
    StopTime=1000,
    NumberOfIntervals=500,
    Tolerance=0.0001,
    Algorithm="dassl"));
end QHP_test_TestRedCells;
