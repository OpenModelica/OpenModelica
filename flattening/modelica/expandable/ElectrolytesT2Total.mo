within ;
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
Copyright &copy; 1998-2009, ABB, arsenal research, T.&nbsp;BÃ¶drich, DLR, Dynasim, Fraunhofer, Modelon,
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
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
              100}}), graphics={
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

        partial block MISO
        "Multiple Input Single Output continuous control block"

          extends BlockIcon;
          parameter Integer nin=1 "Number of inputs";
          RealInput u[nin] "Connector of Real input signals"
            annotation (Placement(transformation(extent={{-140,-20},{-100,20}},
                rotation=0)));
          RealOutput y "Connector of Real output signal"
            annotation (Placement(transformation(extent={{100,-10},{120,10}},
                rotation=0)));
          annotation (Documentation(info="<HTML>
<p>
Block has a vector of continuous Real input signals and
one continuous Real output signal.
</p>
</HTML>
"));
        end MISO;
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

          block Gain "Output the product of a gain value with the input signal"

            parameter Real k(start=1) "Gain value multiplied with input signal";
      public
            Interfaces.RealInput u "Input signal connector"
              annotation (Placement(transformation(extent={{-140,-20},{-100,20}},
                rotation=0)));
            Interfaces.RealOutput y "Output signal connector"
              annotation (Placement(transformation(extent={{100,-10},{120,10}},
                rotation=0)));
            annotation (
              Documentation(info="
<HTML>
<p>
This block computes output <i>y</i> as
<i>product</i> of gain <i>k</i> with the
input <i>u</i>:
</p>
<pre>
    y = k * u;
</pre>

</HTML>
"),           Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Polygon(
                points={{-100,-100},{-100,100},{100,0},{-100,-100}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-150,-140},{150,-100}},
                lineColor={0,0,0},
                textString="k=%k"),
              Text(
                extent={{-150,140},{150,100}},
                textString="%name",
                lineColor={0,0,255})}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Polygon(
                points={{-100,-100},{-100,100},{100,0},{-100,-100}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid), Text(
                extent={{-76,38},{0,-34}},
                textString="k",
                lineColor={0,0,255})}));

          equation
            y = k*u;
          end Gain;

          block Sum "Output the sum of the elements of the input vector"
            extends Interfaces.MISO;
            parameter Real k[nin]=ones(nin) "Optional: sum coefficients";
            annotation (defaultComponentName="sum1",
              Documentation(info="
<HTML>
<p>
This blocks computes output <b>y</b> as
<i>sum</i> of the elements of the input signal vector
<b>u</b>:
</p>
<pre>
    <b>y</b> = <b>u</b>[1] + <b>u</b>[2] + ...;
</pre>
<p>
Example:
</p>
<pre>
     parameter:   nin = 3;

  results in the following equations:

     y = u[1] + u[2] + u[3];
</pre>

</HTML>
"),           Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Line(
                points={{26,42},{-34,42},{6,2},{-34,-38},{26,-38}},
                color={0,0,0},
                thickness=0.25), Text(
                extent={{-150,150},{150,110}},
                textString="%name",
                lineColor={0,0,255})}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid), Line(
                points={{26,42},{-34,42},{6,2},{-34,-38},{26,-38}},
                color={0,0,0},
                thickness=0.25)}));
          equation
            y = k*u;
          end Sum;

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

          block Add3 "Output the sum of the three inputs"
            extends Interfaces.BlockIcon;

            parameter Real k1=+1 "Gain of upper input";
            parameter Real k2=+1 "Gain of middle input";
            parameter Real k3=+1 "Gain of lower input";
            input Interfaces.RealInput u1 "Connector 1 of Real input signals"
              annotation (Placement(transformation(extent={{-140,60},{-100,100}},
                rotation=0)));
            input Interfaces.RealInput u2 "Connector 2 of Real input signals"
              annotation (Placement(transformation(extent={{-140,-20},{-100,20}},
                rotation=0)));
            input Interfaces.RealInput u3 "Connector 3 of Real input signals"
              annotation (Placement(transformation(extent={{-140,-100},{-100,-60}},
                rotation=0)));
            output Interfaces.RealOutput y "Connector of Real output signals"
              annotation (Placement(transformation(extent={{100,-10},{120,10}},
                rotation=0)));
            annotation (
              Documentation(info="
<HTML>
<p>
This blocks computes output <b>y</b> as <i>sum</i> of the
three input signals <b>u1</b>, <b>u2</b> and <b>u3</b>:
</p>
<pre>
    <b>y</b> = k1*<b>u1</b> + k2*<b>u2</b> + k3*<b>u3</b>;
</pre>
<p>
Example:
</p>
<pre>
     parameter:   k1= +2, k2= -3, k3=1;

  results in the following equations:

     y = 2 * u1 - 3 * u2 + u3;
</pre>

</HTML>
"),           Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Text(
                extent={{-100,50},{5,90}},
                lineColor={0,0,0},
                textString="%k1"),
              Text(
                extent={{-100,-20},{5,20}},
                lineColor={0,0,0},
                textString="%k2"),
              Text(
                extent={{-100,-50},{5,-90}},
                lineColor={0,0,0},
                textString="%k3"),
              Text(
                extent={{2,36},{100,-44}},
                lineColor={0,0,0},
                textString="+")}),
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
                extent={{-100,50},{5,90}},
                lineColor={0,0,0},
                textString="%k1"),
              Text(
                extent={{-100,-20},{5,20}},
                lineColor={0,0,0},
                textString="%k2"),
              Text(
                extent={{-100,-50},{5,-90}},
                lineColor={0,0,0},
                textString="%k3"),
              Text(
                extent={{2,36},{100,-44}},
                lineColor={0,0,0},
                textString="+"),
              Rectangle(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-100,50},{5,90}},
                lineColor={0,0,0},
                textString="k1"),
              Text(
                extent={{-100,-20},{5,20}},
                lineColor={0,0,0},
                textString="k2"),
              Text(
                extent={{-100,-50},{5,-90}},
                lineColor={0,0,0},
                textString="k3"),
              Text(
                extent={{2,36},{100,-44}},
                lineColor={0,0,0},
                textString="+")}));

          equation
            y = k1*u1 + k2*u2 + k3*u3;
          end Add3;

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

  package Library "Physical domains library"

    package Interfaces "Abstract Interfaces"

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
                textString="%name")}), Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));
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

      partial model BaseFactorIcon4

       annotation (
          Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,20},{100,-20}},
                lineColor={127,0,0},
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

      end BaseFactorIcon4;

      partial model BaseFactorIcon5

       annotation (
          Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,20},{100,-20}},
                lineColor={0,0,255},
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

      end BaseFactorIcon5;

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
                points={{-80,50},{80,50},{100,30},{80,-40},{60,-50},{-60,-50},{
                    -80,-40},{-100,30},{-80,50}},
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
              fillPattern=FillPattern.Solid), Text(
              extent={{-100,-50},{358,-92}},
              lineColor={0,0,255},
              textString="%name")}),
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

    package Curves "Empirical Dependence of Two Variables"

     function SplineSlope

          input Real[:] x;
          input Real[:] y;
          input Real[:] slope;
          input Real xVal;

          output Real yVal;

      protected
        Integer index;
        Real a1;
        Real a2;
        Real a3;
        Real a4;
        Real x1;
        Real x2;

        Real y1;
        Real y2;
        Real slope1;
        Real slope2;

     algorithm
            // Najdi interval, ve kterem se nachazi xVal

            if (xVal<= x[1]) then

              yVal :=(xVal)*slope[1] + y[1]- x[1]*slope[1];

            elseif (xVal>=x[size(x,1)]) then

             yVal :=(xVal)*slope[size(slope,1)] + y[size(y,1)]-(x[size(x,1)]*slope[size(slope,1)]);

            else
              index :=1;
              while ( xVal>x[index] and index<=size(x,1)) loop
                index:=index+1;
              end while;

              x1:=x[index-1];
              x2:=x[index];
              y1:=y[index-1];
              y2:=y[index];
              slope1:=slope[index-1];
              slope2:=slope[index];

              a1:=-(-x2*slope2 - x2*slope1 + slope2*x1 + slope1*x1 + 2*y2 - 2*y1)/(x2 - x1)^3;
              a2:=(-x2^2*slope2-2*x2^2*slope1-3*x2*y1+x2*slope1*x1+3*x2*y2-x2*slope2*x1-3*y1*x1+slope1*x1^2+3*y2*x1+2*slope2*x1^2)/(x2-x1)^3;
              a3:=-(-slope1*x2^3-2*x2^2*slope2*x1-x2^2*slope1*x1+x2*slope2*x1^2+2*x2*slope1*x1^2+6*x2*x1*y2-6*x2*x1*y1+slope2*x1^3)/(x2-x1)^3;
              a4:=(-slope1*x2^3*x1+y1*x2^3-slope2*x1^2*x2^2+slope1*x1^2*x2^2-3*y1*x2^2*x1+3*y2*x1^2*x2+slope2*x1^3*x2-y2*x1^3)/(x2-x1)^3;

              yVal :=a1*(xVal)^3 + a2*(xVal)^2 + a3*(xVal) + a4;

            end if;

            annotation (Documentation(revisions="<html>
<p>author: Ondrej Vacek</p>
</html>"));
     end SplineSlope;

           model Curve
        "2D natural cubic interpolation spline defined with (x,y,slope) points"

               parameter Real x[:];
               parameter Real y[:];
               parameter Real slope[:];

               QHP.Library.Interfaces.RealInput_ u
                            annotation (Placement(transformation(extent={{-100,-60},{-60,-20}}),
                      iconTransformation(extent={{-120,-20},{-80,20}})));
               QHP.Library.Interfaces.RealOutput_ val
                               annotation (Placement(transformation(extent={{60,-20},{100,20}}),
                      iconTransformation(extent={{82,-20},{122,20}})));

           equation
             val = SplineSlope(
               x,
               y,
               slope,
               u);

           end Curve;

    end Curves;

    package Factors "Multiplication Effect Types"

      model SimpleMultiply "multiplication"
       extends QHP.Library.Interfaces.BaseFactorIcon;
       QHP.Library.Interfaces.RealInput_ u
                    annotation (Placement(transformation(extent={{-102,-24},{-62,16}}),
              iconTransformation(extent={{-108,-10},{-88,10}})));

       Modelica.Blocks.Math.Product product  annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={0,-32})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics), Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>", info="<html>
<p><h4>y = yBase * u</h4></p>
</html>"));
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

      model SplineValue "calculate multiplication factor from spline value"
       extends QHP.Library.Interfaces.BaseFactorIcon4;
       QHP.Library.Interfaces.RealInput_ u
                    annotation (Placement(transformation(extent={{-102,-24},{-62,16}}),
              iconTransformation(extent={{-108,-10},{-88,10}})));

       parameter Real[:,3] data;
        Curves.Curve curve(
          x=data[:, 1],
          y=data[:, 2],
          slope=data[:, 3])
          annotation (Placement(transformation(extent={{-46,-10},{-26,10}})));
        Modelica.Blocks.Math.Product product annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={0,-32})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics), Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));
      equation
        connect(curve.u, u) annotation (Line(
            points={{-46,0},{-64,0},{-64,-4},{-82,-4}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(yBase, product.u1) annotation (Line(
            points={{6,80},{6,30},{6,-20},{6,-20}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(curve.val, product.u2) annotation (Line(
            points={{-25.8,0},{-6,0},{-6,-20}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(product.y, y) annotation (Line(
            points={{-2.02067e-015,-43},{-2.02067e-015,-55.5},{0,-55.5},{0,-60}},
            color={0,0,127},
            smooth=Smooth.None));
      end SplineValue;

      model DelayedToSpline
        "adapt the signal, from which is by curve multiplication coeficient calculated"
       extends QHP.Library.Interfaces.BaseFactorIcon5;
       QHP.Library.Interfaces.RealInput_ u
                    annotation (Placement(transformation(extent={{-118,44},{-78,
                  84}}),
              iconTransformation(extent={{-108,-10},{-88,10}})));
       parameter Real Tau = 40;
       parameter Real initialValue = 1; //40;
       parameter Real[:,3] data;
        Curves.Curve curve(
          x=data[:, 1],
          y=data[:, 2],
          slope=data[:, 3])
          annotation (Placement(transformation(extent={{-38,-16},{-18,4}})));
        Modelica.Blocks.Math.Product product annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={0,-32})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics), Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));
        Modelica.Blocks.Continuous.Integrator integrator(k=(1/Tau)/Library.SecPerMin,
            y_start=initialValue)
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={-60,14})));
        Modelica.Blocks.Math.Feedback feedback annotation (Placement(
              transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={-60,46})));
      equation
        connect(yBase, product.u1) annotation (Line(
            points={{6,80},{6,30},{6,-20},{6,-20}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(product.y, y) annotation (Line(
            points={{-2.02067e-015,-43},{-2.02067e-015,-55.5},{0,-55.5},{0,-60}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(feedback.y, integrator.u) annotation (Line(
            points={{-60,37},{-60,26}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(integrator.y, feedback.u2) annotation (Line(
            points={{-60,3},{-60,-6},{-84,-6},{-84,46},{-68,46}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(feedback.u1, u) annotation (Line(
            points={{-60,54},{-60,64},{-98,64}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(integrator.y, curve.u) annotation (Line(
            points={{-60,3},{-60,-6},{-38,-6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(curve.val, product.u2) annotation (Line(
            points={{-17.8,-6},{-6,-6},{-6,-20}},
            color={0,0,127},
            smooth=Smooth.None));
      end DelayedToSpline;

      model SplineDelayByDay
        "adapt the value of multiplication coeficient calculated from curve"
       extends QHP.Library.Interfaces.BaseFactorIcon3;
       QHP.Library.Interfaces.RealInput_ u
                    annotation (Placement(transformation(extent={{-118,44},{-78,
                  84}}),
              iconTransformation(extent={{-108,-10},{-88,10}})));
       parameter Real Tau;
       parameter Real[:,3] data;
        Curves.Curve curve(
          x=data[:, 1],
          y=data[:, 2],
          slope=data[:, 3])
          annotation (Placement(transformation(extent={{-68,58},{-48,78}})));
        Modelica.Blocks.Math.Product product annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={0,-32})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics), Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));
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
      end SplineDelayByDay;
    end Factors;

    package Blocks "Base Signal Blocks Library"

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

          block FractConstant "Generate constant signal in part from 1"
            parameter Real k(start=1, final unit="%") "Part in percent";

            QHP.Library.Interfaces.RealOutput_ y( final unit =     "1")
          "Connector of Real output signal"
              annotation (Placement(transformation(extent={{100,-10},{120,10}},
                  rotation=0)));

            annotation (
              Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,100},{100,-100}},
                lineColor={0,0,255},
                fillPattern=FillPattern.Solid,
                fillColor={255,255,255}), Text(
                extent={{-94,-50},{94,56}},
                lineColor={0,0,0},
                fillColor={0,0,0},
                fillPattern=FillPattern.Solid,
                textString="%k%%")}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Text(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,0},
                textString="%k")}),
          Documentation(info="<html>
<p>
The Real output y is a constant signal:
</p>
</html>"));
          equation
            y = k/100;
          end FractConstant;

          block OsmolarityConstant "Generate constant signal of type mOsm"
            parameter Real k(start=1, final quantity="Osmolarity", final unit="mOsm")
          "Constant output value";

            QHP.Library.Interfaces.RealOutput_ y( final quantity="Osmolarity", final unit
            =                                                                             "mOsm")
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
                extent={{-98,6},{100,86}},
                lineColor={0,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                textString="%k"),
              Text(
                extent={{-100,-80},{100,-18}},
                lineColor={0,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                textString="mOsm")}),
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
          end OsmolarityConstant;

          block ElectrolytesMassConstant
        "Generate constant signal of type Mass_mEq"
            parameter Real k(start=1, final quantity="Mass", final unit="mEq")
          "Constant output value";

            QHP.Library.Interfaces.RealOutput_ y( final quantity="Mass", final unit
            =                                                                       "mEq")
          "Connector of Real output signal"
              annotation (Placement(transformation(extent={{100,-10},{120,10}},
                  rotation=0)));

            annotation (
              Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,100},{100,-100}},
                lineColor={0,0,255},
                fillPattern=FillPattern.Solid,
                fillColor={255,255,255}), Text(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                textString="%k mEq")}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Text(
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
          end ElectrolytesMassConstant;

          block ElectrolytesFlowConstant
        "Generate constant signal of type Mass_mEq_per_min"
            parameter Real k(start=1, final quantity="Flow", final unit="mEq/min")
          "Constant output value";

            QHP.Library.Interfaces.RealOutput_ y( final quantity="Flow", final unit
            =                                                                       "mEq/min")
          "Connector of Real output signal"
              annotation (Placement(transformation(extent={{100,-10},{120,10}},
                  rotation=0)));

            annotation (
              Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={
              Rectangle(
                extent={{-100,100},{100,-100}},
                lineColor={0,0,255},
                fillPattern=FillPattern.Solid,
                fillColor={255,255,255}),
              Text(
                extent={{-100,-6},{100,100}},
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
                textString="mEq")}),
              Diagram(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Text(
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
          end ElectrolytesFlowConstant;
    end Blocks;

    package ConcentrationFlow "Concentration Physical Domain"

      replaceable type Concentration = Real (final quantity="Concentration");

      replaceable type SoluteFlow = Real (final quantity="Flow");

      connector ConcentrationFlow "Concentration and Solute flow"
        Concentration conc;
        flow SoluteFlow q;
        annotation (Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));
      end ConcentrationFlow;

      connector PositiveConcentrationFlow "Concentration and Solute inflow"
        extends QHP.Library.ConcentrationFlow.ConcentrationFlow;

      annotation (
          defaultComponentName="q_in",
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={Rectangle(
                extent={{-20,10},{20,-10}},
                lineColor={200,0,0},
                lineThickness=1), Polygon(
                points={{0,100},{100,0},{0,-100},{-100,0},{0,100}},
                lineColor={200,0,0},
                smooth=Smooth.None,
                fillPattern=FillPattern.Solid,
                fillColor={200,0,0})}),
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
</html>", revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));

      end PositiveConcentrationFlow;

      connector NegativeConcentrationFlow
        "Concentration and negative Solute outflow"
        extends QHP.Library.ConcentrationFlow.ConcentrationFlow;

      annotation (
          defaultComponentName="q_out",
          Icon(coordinateSystem(extent={{-100,-100},{100,100}}, preserveAspectRatio=false),
              graphics={Rectangle(
                extent={{-20,10},{20,-10}},
                lineColor={200,0,0},
                lineThickness=1), Polygon(
                points={{-100,0},{0,100},{100,0},{0,-100},{-100,0}},
                lineColor={200,0,0},
                smooth=Smooth.None,
                fillPattern=FillPattern.Solid,
                fillColor={255,240,240})}),
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
</html>", revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));

      end NegativeConcentrationFlow;

      model FlowMeasure

        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{18,-10},{38,10}}), iconTransformation(
                extent={{30,-10},{50,10}})));

       annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={Rectangle(
                extent={{-40,30},{40,-30}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid)}),
                                        Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics),
          Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));

        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in
                                  annotation (Placement(
              transformation(extent={{-120,-20},{-80,20}}), iconTransformation(extent={{-50,-10},
                  {-30,10}})));
        QHP.Library.Interfaces.RealOutput_ actualFlow
                               annotation (Placement(transformation(extent={{-20,30},{20,70}}),
              iconTransformation(extent={{-20,-20},{20,20}},
                                                           rotation=90,
              origin={0,50})));
      equation
        q_in.q + q_out.q = 0;
        q_out.conc = q_in.conc;

        actualFlow = q_in.q;

      end FlowMeasure;

      model ConcentrationMeasure
        parameter String unitsString="";
        parameter Real toAnotherUnitCoef=1;

       annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={Text(
                extent={{-48,-24},{48,-40}},
                lineColor={0,0,0},
                textString="%unitsString"), Rectangle(
                extent={{-20,20},{20,-20}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid)}),
                                        Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics),
          Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));

        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in
                                  annotation (Placement(
              transformation(extent={{-120,-20},{-80,20}}), iconTransformation(extent={{-10,-10},
                  {10,10}})));
        QHP.Library.Interfaces.RealOutput_ actualConc
                               annotation (Placement(transformation(extent={{-20,30},{20,70}}),
              iconTransformation(extent={{-20,-20},{20,20}},
                                                           rotation=90,
              origin={0,40})));
      equation

        actualConc =  toAnotherUnitCoef * q_in.conc;
        q_in.q = 0;
      end ConcentrationMeasure;

      model SolventFlowPump

        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out
          "second side connector with value of q (solute mass flow) and conc (concentration)"
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{90,-10},{110,10}})));

        Interfaces.RealInput_ solventFlow
          "solvent flow (solution volume flow = solventFlow + solute volume flow)"
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
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-150,-100},{150,-60}},
                textString="%name",
                lineColor={0,0,255})}), Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics),
          Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
</table>
</html>",       info="<html>
<p><h4><font color=\"#008000\">Bidirectional mass flow by concentration</font></h4></p>
<p>Possible field values: </p>
<table cellspacing=\"2\" cellpadding=\"0\" border=\"0.1\"><tr>
<td></td>
<td><p align=\"center\">forward flow</p></td>
<td><p align=\"center\">backward flow</p></td>
</tr>
<tr>
<td><p align=\"center\"><h4>solventFlow</h4></p></td>
<td><p align=\"center\">&GT;=0</p></td>
<td><p align=\"center\">&LT;0</p></td>
</tr>
<tr>
<td><p align=\"center\"><h4>q_in.q</h4></p></td>
<td><p align=\"center\">=solventFlow*q_in.conc</p></td>
<td><p align=\"center\">=solventFlow*q_out.conc</p></td>
</tr>
<tr>
<td><p align=\"center\"><h4>q_out.q</h4></p></td>
<td><p align=\"center\">=-q_in.q</p></td>
<td><p align=\"center\">=-q_in.q</p></td>
</tr>
</table>
</html>"));

        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in
          "first side connector with value of q (solute mass flow) and conc (concentration)"
                                  annotation (Placement(
              transformation(extent={{-120,-20},{-80,20}}), iconTransformation(extent=
                 {{-110,-10},{-90,10}})));

      equation
        if ( solventFlow>=0) then
          q_in.q + q_out.q = 0;
          q_in.q = solventFlow*q_in.conc;
        else
          q_in.q + q_out.q = 0;
          q_in.q = solventFlow*q_out.conc;
        end if;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end SolventFlowPump;

      model SolventOutflowPump

        QHP.Library.Interfaces.RealInput solventFlow "solvent outflow"
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
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-150,-100},{150,-60}},
                textString="%name",
                lineColor={0,0,255}),
              Text(
                extent={{-100,-30},{100,-50}},
                lineColor={0,0,0},
                textString="K=%K")}),   Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics),
          Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
</table>
</html>"));

        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in
          "solute outflow"        annotation (Placement(
              transformation(extent={{-120,-20},{-80,20}}), iconTransformation(extent=
                 {{-110,-10},{-90,10}})));

        parameter Real K=1 "part of real mass flow in solution outflow";
      equation
        q_in.q = K*solventFlow*q_in.conc;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end SolventOutflowPump;

      model InputPump

        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{90,-10},{110,10}}), iconTransformation(extent={
                  {50,-10},{70,10}})));
        QHP.Library.Interfaces.RealInput_ desiredFlow "speed of solute flow"
                                                                      annotation ( extent = [-10,30;10,50], rotation = -90);

       annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={
              Rectangle(
                extent={{-60,-30},{60,30}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-48,20},{50,0},{-48,-21},{-48,20}},
                lineColor={0,0,127},
                fillColor={0,0,127},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-92,-54},{80,-30}},
                textString="%name",
                lineColor={0,0,255})}), Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics),
          Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));

      equation
        q_out.q = - desiredFlow;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end InputPump;

      model OutputPump

        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{-110,-8},{-90,12}}), iconTransformation(extent={{-70,-10},
                  {-50,10}})));
        QHP.Library.Interfaces.RealInput_ desiredFlow
                                       annotation ( extent = [-10,30;10,50], rotation = -90);

       annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={
              Rectangle(
                extent={{-60,-32},{60,30}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-48,18},{50,-2},{-48,-26},{-48,18}},
                lineColor={0,0,127},
                fillColor={0,0,127},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-78,-54},{72,-32}},
                textString="%name",
                lineColor={0,0,255})}), Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics),
          Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));

      equation
        q_in.q = desiredFlow;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end OutputPump;

      model SoluteFlowPump

        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{90,-10},{110,10}})));
        QHP.Library.Interfaces.RealInput soluteFlow
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
                         extent={{-100,-100},{100,100}}), graphics),
          Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));

        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in
                                  annotation (Placement(
              transformation(extent={{-120,-20},{-80,20}}), iconTransformation(extent=
                 {{-110,-10},{-90,10}})));
      equation
        q_in.q + q_out.q = 0;
        q_in.q = soluteFlow;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end SoluteFlowPump;

      model FractReabsorbtion

        Library.ConcentrationFlow.PositiveConcentrationFlow Inflow
                                                       annotation (Placement(
              transformation(extent={{-120,-18},{-80,22}}), iconTransformation(
                extent={{-110,-10},{-90,10}})));
        Library.ConcentrationFlow.NegativeConcentrationFlow Outflow
          annotation (Placement(transformation(extent={{0,-100},{40,-60}}),
              iconTransformation(extent={{90,-10},{110,10}})));
        annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={
              Rectangle(
                extent={{-100,40},{100,-40}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Line(
                points={{-70,14},{-70,-18},{-52,-12},{-36,-14},{-18,-20},{-2,-28},
                    {6,-36},{8,-40},{6,-22},{0,-12},{-8,-6},{-22,2},{-40,8},{-58,
                    12},{-70,14}},
                color={0,0,255},
                smooth=Smooth.None),
              Text(
                extent={{12,-54},{166,-84}},
                lineColor={0,0,255},
                textString="%name"),
              Text(
                extent={{-100,-40},{-4,-62}},
                lineColor={0,0,255},
                textString="%MaxReab = MaxReab")}),
                                       Diagram(coordinateSystem(preserveAspectRatio=true,
                        extent={{-100,-100},{100,100}}), graphics),
          Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));

        Library.ConcentrationFlow.NegativeConcentrationFlow Reabsorbtion
                                                         annotation (Placement(
              transformation(extent={{-20,-100},{20,-60}}),iconTransformation(
                extent={{-10,-50},{10,-30}})));
        QHP.Library.Interfaces.RealInput_ Normal(final unit="1")
                                     annotation (Placement(transformation(extent={{-20,20},{20,
                  60}}), iconTransformation(extent={{-20,-20},{20,20}},
                                                                      rotation=-90,
              origin={-60,40})));
        QHP.Library.Interfaces.RealInput_ Effects(final unit="1")
                                     annotation (Placement(transformation(extent={{-20,20},{20,
                  60}}), iconTransformation(extent={{60,20},{100,60}},rotation=-90)));

      parameter SoluteFlow MaxReab=14 "maximum reabsorbtion solute flow";
        Interfaces.RealOutput_ ReabFract(final unit="1") annotation (Placement(transformation(extent={{80,-60},
                  {120,-20}}), iconTransformation(extent={{80,-60},{120,-20}})));
      equation
        Outflow.q + Inflow.q + Reabsorbtion.q = 0;
        Outflow.conc = Inflow.conc;
        Reabsorbtion.q = -min(ReabFract * Inflow.q, MaxReab);
        ReabFract = if (Normal<=0) or (Effects<=0) then 0 else if Normal>1 then 1 else Normal^(1/Effects);
      end FractReabsorbtion;

      model FractReabsorbtion2

        Library.ConcentrationFlow.PositiveConcentrationFlow Inflow
                                                       annotation (Placement(
              transformation(extent={{-120,-18},{-80,22}}), iconTransformation(
                extent={{-110,-10},{-90,10}})));
        Library.ConcentrationFlow.NegativeConcentrationFlow Outflow
          annotation (Placement(transformation(extent={{0,-100},{40,-60}}),
              iconTransformation(extent={{90,-10},{110,10}})));
        annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={
              Rectangle(
                extent={{-100,40},{100,-40}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Line(
                points={{-70,14},{-70,-18},{-52,-12},{-36,-14},{-18,-20},{-2,-28},
                    {6,-36},{8,-40},{6,-22},{0,-12},{-8,-6},{-22,2},{-40,8},{-58,
                    12},{-70,14}},
                color={0,0,255},
                smooth=Smooth.None),
              Text(
                extent={{12,-42},{166,-72}},
                lineColor={0,0,255},
                textString="%name")}), Diagram(coordinateSystem(preserveAspectRatio=true,
                        extent={{-100,-100},{100,100}}), graphics),
          Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));
        Library.ConcentrationFlow.NegativeConcentrationFlow Reabsorbtion
                                                         annotation (Placement(
              transformation(extent={{-20,-100},{20,-60}}),iconTransformation(
                extent={{-10,-50},{10,-30}})));
        QHP.Library.Interfaces.RealInput_ Normal(final unit="1")
                                     annotation (Placement(transformation(extent={{-20,20},{20,
                  60}}), iconTransformation(extent={{-20,-20},{20,20}},
                                                                      rotation=-90,
              origin={-60,40})));
        QHP.Library.Interfaces.RealInput_ Effects(final unit="1")
                                     annotation (Placement(transformation(extent={{-20,20},{20,
                  60}}), iconTransformation(extent={{-20,-20},{20,20}},
                                                                      rotation=-90,
              origin={80,40})));
        Real ReabFract(final unit="1");
        QHP.Library.Interfaces.RealInput_ MaxReab
                                     annotation (Placement(transformation(extent={{-20,20},{20,
                  60}}), iconTransformation(extent={{-20,-20},{20,20}},
                                                                      rotation=90,
              origin={-60,-42})));
      equation
        Outflow.q + Inflow.q + Reabsorbtion.q = 0;
        Outflow.conc = Inflow.conc;
        Reabsorbtion.q = -min(ReabFract * Inflow.q, MaxReab);
        ReabFract = if (Normal<=0) or (Effects<=0) then 0 else if Normal>1 then 1 else Normal^(1/Effects);
      end FractReabsorbtion2;

      model ConcentrationCompartment
        //extends QHP.Library.Interfaces.BaseModel;

        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out
                                   annotation (Placement(
              transformation(extent={{62,-32},{102,8}}),  iconTransformation(extent={{-10,-10},
                  {10,10}})));
        parameter Real initialSoluteMass;

        QHP.Library.Interfaces.RealInput_ SolventVolume(final quantity="Volume", final unit
            =                                                                               "ml")
                                 annotation (Placement(transformation(extent={{-120,68},{-80,108}}),
              iconTransformation(extent={{-100,40},{-60,80}})));
        QHP.Library.Interfaces.RealOutput_ SoluteMass
          annotation (Placement(transformation(extent={{-20,-120},{20,-80}}, rotation=
                 -90,
              origin={102,-102}), iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={0,-78})));

      initial equation
        SoluteMass = initialSoluteMass;
      equation
        q_out.conc = if (SolventVolume>0) then SoluteMass / SolventVolume else 0;
        der(SoluteMass) = q_out.q / Library.SecPerMin;
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics), Icon(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics={Bitmap(extent={{-100,100},{100,-100}}, fileName=
                    "icons/concentrationCompartement.png"), Text(
                extent={{-22,-102},{220,-136}},
                lineColor={0,0,255},
                textString="%name")}),
          Documentation(revisions="<html>
<p><i>2009-2010</i></p>
<p>Marek Matejak, Charles University, Prague, Czech Republic </p>
</html>"));

      end ConcentrationCompartment;
    end ConcentrationFlow;

    constant Real SecPerMin(unit="s/min") = 60
      "Conversion coeficient from minutes to seconds";
    annotation (Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2008-2009</td>
</tr>
</table>
</html>"));
  end Library;

  package Electrolytes "Body Electrolytes"

    package Sodium "Body Sodium Distribution"

      model GlomerulusCationFiltration

        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{90,-10},{110,10}})));

       annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={
              Rectangle(
                extent={{-100,-50},{100,50}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-150,-100},{150,-60}},
                textString="%name",
                lineColor={0,0,255}),
              Line(
                points={{0,42},{0,26}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5),
              Line(
                points={{0,20},{0,4}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5),
              Line(
                points={{0,-4},{0,-20}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5),
              Line(
                points={{0,-26},{0,-42}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5)}),       Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics));

        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in
                                  annotation (Placement(
              transformation(extent={{-120,-20},{-80,20}}), iconTransformation(extent=
                 {{-110,-10},{-90,10}})));

        Library.Interfaces.RealInput_ otherCations( final quantity="Concentration", final unit
            =                                                                                  "mEq/l") annotation (Placement(
              transformation(extent={{-78,30},{-38,70}}), iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={-60,50})));
        Library.Interfaces.RealInput_ ProteinAnions(final quantity="Concentration",
            final unit="mEq/l")                                                                               annotation (Placement(
              transformation(extent={{-40,30},{0,70}}), iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={-20,50})));
        Real KAdjustment;
        Real Cations( final quantity="Concentration", final unit = "mEq/l");
        Real Anions( final quantity="Concentration", final unit = "mEq/l");
      equation
        q_in.q + q_out.q = 0;
        Cations = q_in.conc*1000+otherCations;
        Anions = Cations;
        KAdjustment = (Cations-(Anions-ProteinAnions))/(Cations+(Anions-ProteinAnions));
        q_out.conc = (1-KAdjustment)*q_in.conc;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end GlomerulusCationFiltration;

      model Sodium2
        //extends Library.Interfaces.BaseModel;
        Library.ConcentrationFlow.ConcentrationCompartment NaPool(
            initialSoluteMass=2170.0)
          annotation (Placement(transformation(extent={{-86,14},{-66,34}})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}),       graphics), Icon(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics={Bitmap(extent={{-100,100},{100,-100}}, fileName=
                    "icons/Na.jpg"), Text(
                extent={{-110,-104},{110,-130}},
                lineColor={0,0,255},
                textString="%name")}),
          Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
<tr>
<td>References:</td>
<td>Tom Coleman: QHP 2008 beta 3, University of Mississippi Medical Center</td>
</tr>
</table>
</html>"));
        Library.ConcentrationFlow.ConcentrationCompartment GILumen(
            initialSoluteMass=80.0)
          annotation (Placement(transformation(extent={{-82,-36},{-62,-16}})));
        Library.ConcentrationFlow.SoluteFlowPump Absorbtion
          annotation (Placement(transformation(extent={{-44,-10},{-56,-22}})));
        Modelica.Blocks.Math.Gain Perm(k=.0015)
          annotation (Placement(transformation(extent={{-62,-46},{-56,-40}})));
        Library.ConcentrationFlow.OutputPump Hemorrhage
          annotation (Placement(transformation(extent={{-58,64},{-38,84}})));
        Library.ConcentrationFlow.OutputPump DialyzerActivity
          annotation (Placement(transformation(extent={{-58,50},{-38,70}})));
        Library.ConcentrationFlow.OutputPump SweatDuct
          annotation (Placement(transformation(extent={{-58,76},{-38,96}})));
        Library.ConcentrationFlow.InputPump IVDrip
          annotation (Placement(transformation(extent={{-78,70},{-58,90}})));
        Library.ConcentrationFlow.InputPump Transfusion
          annotation (Placement(transformation(extent={{-78,56},{-58,76}})));
        Library.ConcentrationFlow.SolventFlowPump glomerulusSudiumRate
          annotation (Placement(transformation(extent={{-16,14},{4,34}})));
        QHP.Electrolytes.Sodium.GlomerulusCationFiltration glomerulus
          annotation (Placement(transformation(extent={{-40,14},{-20,34}})));
        Library.ConcentrationFlow.FractReabsorbtion PT
          annotation (Placement(transformation(extent={{8,14},{28,34}})));
        Library.Blocks.FractConstant const1(k=58)
          annotation (Placement(transformation(extent={{2,34},{8,40}})));
        QHP.Library.Factors.SplineValue IFPEffect(
                                              data={{1.0,1.4,0},{4.0,1.0,-0.2},
              {7.0,0.3,0}})
          annotation (Placement(transformation(extent={{14,32},{34,52}})));
        QHP.Library.Factors.SplineValue ANPEffect(
                                              data={{0.0,1.2,0},{1.3,1.0,-0.2},
              {2.7,0.6,0}})
          annotation (Placement(transformation(extent={{14,40},{34,60}})));
        QHP.Library.Factors.SplineValue SympsEffect(
                                                data={{0.6,0.6,0},{1.0,1.0,0.5},
              {4.0,1.5,0}})
          annotation (Placement(transformation(extent={{14,48},{34,68}})));
        QHP.Library.Factors.SplineValue A2Effect(
                                             data={{0.7,0.8,0},{1.3,1.0,0.8},{
              1.6,1.2,0}})
          annotation (Placement(transformation(extent={{14,56},{34,76}})));
        Library.ConcentrationFlow.FractReabsorbtion LH(MaxReab=7)
          annotation (Placement(transformation(extent={{68,14},{88,34}})));
        Library.Blocks.FractConstant const2(k=75)
          annotation (Placement(transformation(extent={{64,30},{70,36}})));
        Library.ConcentrationFlow.FractReabsorbtion2 DT
          annotation (Placement(transformation(extent={{80,-74},{60,-54}})));
        Library.ConcentrationFlow.FractReabsorbtion CD(MaxReab=.7)
          annotation (Placement(transformation(extent={{30,-74},{10,-54}})));
        Library.Blocks.FractConstant const3(k=75)
          annotation (Placement(transformation(extent={{18,-58},{24,-52}})));
        Library.Blocks.FractConstant const4(k=75)
          annotation (Placement(transformation(extent={{68,-58},{74,-52}})));
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(
            initialSoluteMass=0)
          annotation (Placement(transformation(extent={{-28,-26},{-8,-6}})));
        QHP.Library.Factors.SplineValue Furosemide(
                                               data={{0.0,1.0,-1},{0.1,0.0,0}})
          annotation (Placement(transformation(extent={{64,62},{84,82}})));
        Library.Factors.DelayedToSpline AldoEffect(
                                               data={{0.0,0.7,0},{10.0,1.0,0}},
          Tau=3*60,
          initialValue=11)
          annotation (Placement(transformation(extent={{76,40},{96,60}})));
        QHP.Library.Factors.SplineValue LoadEffect(
                                               data={{0.0,3.0,0},{7.2,1.0,-0.2},
              {20.0,0.5,0}})
          annotation (Placement(transformation(extent={{76,32},{96,52}})));
        QHP.Library.Factors.SimpleMultiply FurosemideEffect
          annotation (Placement(transformation(extent={{76,48},{96,68}})));
        QHP.Library.Factors.SimpleMultiply Filtering_xNormal
          annotation (Placement(transformation(extent={{64,54},{84,74}})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure
          annotation (Placement(transformation(extent={{50,14},{70,34}})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure1
          annotation (Placement(transformation(extent={{98,-74},{78,-54}})));
        QHP.Library.Factors.SplineValue LoadEffect1(
                                                data={{0.0,2.0,0},{1.6,1.0,0}})
          annotation (Placement(transformation(extent={{72,-56},{52,-36}})));
         QHP.Library.Factors.SplineValue ThiazideEffect(
                                                   data={{0.0,1.0,-2.0},{0.6,
              0.2,0.0}})
          annotation (Placement(transformation(extent={{72,-48},{52,-28}})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure2
          annotation (Placement(transformation(extent={{58,-74},{38,-54}})));
        QHP.Library.Factors.SplineValue LoadEffect2(
                                                data={{0.0,2.0,0},{0.4,1.0,0}})
          annotation (Placement(transformation(extent={{22,-58},{2,-38}})));
        QHP.Library.Factors.SplineValue ANPEffect2(
                                               data={{0.0,1.2,0},{1.3,1.0,-0.4},
              {2.7,0.2,0}})
          annotation (Placement(transformation(extent={{22,-50},{2,-30}})));
        Library.Factors.SimpleMultiply AldoEffect2
          annotation (Placement(transformation(extent={{10,-10},{-10,10}},
              rotation=270,
              origin={84,-78})));
        QHP.Library.Blocks.Constant const5(
                                k=2)
          annotation (Placement(transformation(extent={{94,-80},{90,-76}})));
        Library.ConcentrationFlow.InputPump Diet
          annotation (Placement(transformation(extent={{-100,-42},{-80,-22}})));
        Library.ConcentrationFlow.OutputPump Diarrhea
          annotation (Placement(transformation(extent={{-10,-10},{10,10}},
              rotation=180,
              origin={-90,-44})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure3
          annotation (Placement(transformation(extent={{10,-54},{-10,-74}})));
        Library.ConcentrationFlow.ConcentrationCompartment Medulla(initialSoluteMass=13)
          annotation (Placement(transformation(extent={{28,-102},{48,-82}})));
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={46,-92})));
        Library.ConcentrationFlow.SolventFlowPump VasaRectaOutflow
          annotation (Placement(transformation(extent={{-4,-100},{-20,-84}})));
        Modelica.Blocks.Math.Gain gain(k=.03)
          annotation (Placement(transformation(extent={{-28,-88},{-20,-80}})));
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(
            unitsString="mEq/l", toAnotherUnitCoef=1000)
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=0,
              origin={-92,36})));
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid
          annotation (Placement(transformation(extent={{12,-22},{24,-10}})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure4
          annotation (Placement(transformation(extent={{64,-68},{44,-88}})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure5
          annotation (Placement(transformation(extent={{80,16},{60,-4}})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure6
          annotation (Placement(transformation(extent={{10,10},{-10,-10}},
              rotation=90,
              origin={18,12})));
        Library.Interfaces.BusConnector busConnector
          annotation (Placement(transformation(extent={{-98,86},{-86,98}}),
              iconTransformation(extent={{60,60},{100,100}})));
        Modelica.Blocks.Math.Gain Osm(k=2)
          annotation (Placement(transformation(extent={{68,-100},{74,-94}})));
        Library.Factors.DelayedToSpline AldoEffect1(
          Tau=3*60,
          initialValue=11,
          data={{0.0,0.5,0},{12.0,1.0,0.08},{50.0,3.0,0}})
          annotation (Placement(transformation(extent={{52,-40},{72,-20}})));
      equation

      connect(NaPool.SolventVolume, busConnector. ECFV_Vol) annotation (Line(
            points={{-84,30},{-97,30},{-97,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(GILumen.SolventVolume, busConnector. GILumenVolume_Mass) annotation (Line(
            points={{-80,-20},{-97,-20},{-97,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(GILumen.q_out, Absorbtion.q_in) annotation (Line(
            points={{-72,-26},{-40,-26},{-40,-16},{-44,-16}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Absorbtion.q_out, NaPool.q_out) annotation (Line(
            points={{-56,-16},{-100,-16},{-100,24},{-76,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Hemorrhage.q_in, NaPool.q_out) annotation (Line(
            points={{-54,74},{-58,74},{-58,24},{-76,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(DialyzerActivity.q_in, NaPool.q_out) annotation (Line(
            points={{-54,60},{-58,60},{-58,24},{-76,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(NaPool.q_out, SweatDuct.q_in) annotation (Line(
            points={{-76,24},{-58,24},{-58,86},{-54,86}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Transfusion.q_out, NaPool.q_out) annotation (Line(
            points={{-62,66},{-58,66},{-58,24},{-76,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(IVDrip.q_out, NaPool.q_out) annotation (Line(
            points={{-62,80},{-58,80},{-58,24},{-76,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(glomerulusSudiumRate.solventFlow, busConnector. GlomerulusFiltrate_GFR)
          annotation (Line(
            points={{-6,30},{-6,38},{-32,38},{-32,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(glomerulus.q_in, NaPool.q_out) annotation (Line(
            points={{-40,24},{-76,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(glomerulus.q_out, glomerulusSudiumRate.q_in) annotation (Line(
            points={{-20,24},{-16,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(glomerulusSudiumRate.q_out, PT.Inflow) annotation (Line(
            points={{4,24},{8,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(const1.y, PT.Normal) annotation (Line(
            points={{8.3,37},{12,37},{12,28}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(A2Effect.yBase, busConnector. KidneyFunctionEffect) annotation (Line(
            points={{24,68},{24,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(A2Effect.y, SympsEffect.yBase) annotation (Line(
            points={{24,64},{24,60}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(SympsEffect.y, ANPEffect.yBase) annotation (Line(
            points={{24,56},{24,52}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(ANPEffect.y, IFPEffect.yBase) annotation (Line(
            points={{24,48},{24,44}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(IFPEffect.y, PT.Effects) annotation (Line(
            points={{24,40},{24,28},{26,28}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(busConnector.A2Pool_Log10Conc, A2Effect.u) annotation (Line(
            points={{-92,92},{-18.9,92},{-18.9,66},{14.2,66}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-6,3},{-6,3}}));
        connect(SympsEffect.u, busConnector. KidneyAlpha_PT_NA) annotation (Line(
            points={{14.2,58},{-18.9,58},{-18.9,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(busConnector.NephronANP_Log10Conc, ANPEffect.u) annotation (Line(
            points={{-92,92},{-18.9,92},{-18.9,50},{14.2,50}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-6,3},{-6,3}}));
        connect(busConnector.NephronIFP_Pressure, IFPEffect.u) annotation (Line(
            points={{-92,92},{-18.9,92},{-18.9,42},{14.2,42}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-6,3},{-6,3}}));
        connect(const2.y, LH.Normal) annotation (Line(
            points={{70.3,33},{72,33},{72,28}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(const3.y, CD.Normal) annotation (Line(
            points={{24.3,-55},{26,-55},{26,-60}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(const4.y, DT.Normal) annotation (Line(
            points={{74.3,-55},{76,-55},{76,-60}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(Bladder.SolventVolume, busConnector. BladderVolume_Mass) annotation (Line(
            points={{-26,-10},{-98,-10},{-98,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(busConnector.Aldo_conc_in_nG_per_dl, AldoEffect.u)
                                             annotation (Line(
            points={{-92,92},{48,92},{48,50},{76.2,50}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-6,3},{-6,3}}));
        connect(Furosemide.u, busConnector. FurosemidePool_Furosemide_conc)
                                                  annotation (Line(
            points={{64.2,72},{48,72},{48,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(AldoEffect.y, LoadEffect.yBase) annotation (Line(
            points={{86,48},{86,44}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(LoadEffect.y, LH.Effects) annotation (Line(
            points={{86,40},{86,28}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(FurosemideEffect.y, AldoEffect.yBase) annotation (Line(
            points={{86,56},{86,52}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(Filtering_xNormal.u, busConnector. Kidney_NephronCount_Filtering_xNormal)
          annotation (Line(
            points={{64.2,64},{48,64},{48,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(Filtering_xNormal.y, FurosemideEffect.u) annotation (Line(
            points={{74,62},{74,58},{76.2,58}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(Furosemide.y, Filtering_xNormal.yBase) annotation (Line(
            points={{74,70},{74,66}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(busConnector.KidneyFunctionEffect, Furosemide.yBase) annotation (Line(
            points={{-92,92},{74,92},{74,74}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-6,3},{-6,3}}));
        connect(FurosemideEffect.yBase, busConnector. KidneyFunctionEffect) annotation (Line(
            points={{86,60},{86,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(PT.Outflow, flowMeasure.q_in) annotation (Line(
            points={{28,24},{56,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(flowMeasure.q_out, LH.Inflow) annotation (Line(
            points={{64,24},{68,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(flowMeasure.actualFlow, LoadEffect.u) annotation (Line(
            points={{60,29},{60,42},{76.2,42}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(DT.Inflow, flowMeasure1.q_out) annotation (Line(
            points={{80,-64},{84,-64}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(flowMeasure1.q_in, LH.Outflow) annotation (Line(
            points={{92,-64},{98,-64},{98,24},{88,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(LoadEffect1.y, DT.Effects) annotation (Line(
            points={{62,-48},{62,-60}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(LoadEffect1.u, flowMeasure1.actualFlow) annotation (Line(
            points={{71.8,-46},{88,-46},{88,-59}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(ThiazideEffect.u, busConnector. ThiazidePool_Thiazide_conc) annotation (Line(
            points={{71.8,-38},{99.9,-38},{99.9,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(CD.Inflow, flowMeasure2.q_out) annotation (Line(
            points={{30,-64},{44,-64}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(flowMeasure2.q_in, DT.Outflow) annotation (Line(
            points={{52,-64},{60,-64}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(LoadEffect2.y, CD.Effects) annotation (Line(
            points={{12,-50},{12,-60}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(LoadEffect2.u, flowMeasure2.actualFlow) annotation (Line(
            points={{21.8,-48},{48,-48},{48,-59}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(ANPEffect2.y, LoadEffect2.yBase) annotation (Line(
            points={{12,-42},{12,-46}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(ANPEffect2.yBase, busConnector. KidneyFunctionEffect) annotation (Line(
            points={{12,-38},{12,-36},{48,-36},{48,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(ANPEffect2.u, busConnector. NephronANP_Log10Conc) annotation (Line(
            points={{21.8,-40},{48,-40},{48,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(IVDrip.desiredFlow, busConnector. IVDrip_NaRate) annotation (Line(
            points={{-68,84},{-68,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(Transfusion.desiredFlow, busConnector. Transfusion_NaRate) annotation (Line(
            points={{-68,70},{-60,70},{-60,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(SweatDuct.desiredFlow, busConnector. SweatDuct_NaRate) annotation (Line(
            points={{-48,90},{-48,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(const5.y, AldoEffect2.yBase) annotation (Line(
            points={{89.8,-78},{86,-78}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(AldoEffect2.y, DT.MaxReab) annotation (Line(
            points={{82,-78},{76,-78},{76,-68.2}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(busConnector.Hemorrhage_NaRate, Hemorrhage.desiredFlow) annotation (Line(
            points={{-92,92},{-47.5,92},{-47.5,78},{-48,78}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-6,3},{-6,3}}));
        connect(DialyzerActivity.desiredFlow, busConnector. DialyzerActivity_Na_Flux)
          annotation (Line(
            points={{-48,64},{-48,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(glomerulus.otherCations, busConnector. KPool) annotation (Line(
            points={{-36,29},{-36,38},{-32,38},{-32,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(glomerulus.ProteinAnions, busConnector. BloodIons_ProteinAnions) annotation (
            Line(
            points={{-32,29},{-32,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(Diet.desiredFlow, busConnector. DietIntakeElectrolytes_Na)
                                                   annotation (Line(
            points={{-90,-28},{-98,-28},{-98,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(Diet.q_out, GILumen.q_out) annotation (Line(
            points={{-84,-32},{-80,-32},{-80,-26},{-72,-26}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Diarrhea.desiredFlow, busConnector. GILumenDiarrhea_NaLoss)
                                                         annotation (Line(
            points={{-90,-48},{-90,-50},{-98,-50},{-98,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(GILumen.q_out, Diarrhea.q_in) annotation (Line(
            points={{-72,-26},{-80,-26},{-80,-44},{-84,-44}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(GILumen.SoluteMass, Perm.u) annotation (Line(
            points={{-72,-33.8},{-72,-43},{-62.6,-43}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(Perm.y, Absorbtion.soluteFlow) annotation (Line(
            points={{-55.7,-43},{-50,-43},{-50,-19.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(CD.Outflow, flowMeasure3.q_in) annotation (Line(
            points={{10,-64},{4,-64}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(flowMeasure3.q_out, Bladder.q_out) annotation (Line(
            points={{-4,-64},{-6,-64},{-6,-16},{-18,-16}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(CD.Reabsorbtion, Medulla.q_out) annotation (Line(
            points={{20,-68},{20,-92},{38,-92}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Medulla.q_out, concentrationMeasure.q_in) annotation (Line(
            points={{38,-92},{46,-92}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(concentrationMeasure.actualConc, busConnector. MedullaNa_conc)
        annotation (Line(
            points={{50,-92},{101,-92},{101,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));                                                 //fix: it was  busConnector. MedullaNa_Conc
        connect(Medulla.q_out, VasaRectaOutflow.q_in) annotation (Line(
            points={{38,-92},{-4,-92}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(VasaRectaOutflow.q_out, NaPool.q_out) annotation (Line(
            points={{-20,-92},{-100,-92},{-100,24},{-76,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(gain.y, VasaRectaOutflow.solventFlow) annotation (Line(
            points={{-19.6,-84},{-12,-84},{-12,-87.2}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(busConnector.VasaRecta_Outflow, gain.u) annotation (Line(
            points={{-92,92},{-98.4,92},{-98.4,-84},{-28.8,-84}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-6,3},{-6,3}}));
        connect(Medulla.SolventVolume, busConnector. Medulla_Volume) annotation (Line(
            points={{30,-86},{26,-86},{26,-78},{-98,-78},{-98,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(NaPool.SoluteMass, busConnector. NaPool_mass) annotation (Line(
            points={{-76,16.2},{-76,14},{-98,14},{-98,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(concentrationMeasure1.q_in, NaPool.q_out) annotation (Line(
            points={{-92,36},{-76,36},{-76,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Bladder.q_out, bladderVoid.q_in) annotation (Line(
            points={{-18,-16},{12,-16}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(bladderVoid.solventFlow, busConnector. BladderVoidFlow) annotation (Line(
            points={{18,-12.4},{18,-6},{-98,-6},{-98,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(GILumen.SoluteMass, busConnector. GILumenSodium_Mass) annotation (Line(
            points={{-72,-33.8},{-72,-50},{-98,-50},{-98,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(AldoEffect1.y, busConnector. DT_AldosteroneEffect) annotation (Line(
            points={{62,-32},{62,-34},{100,-34},{100,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(DT.Reabsorbtion, flowMeasure4.q_in) annotation (Line(
            points={{70,-68},{70,-78},{58,-78}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(flowMeasure4.q_out, NaPool.q_out) annotation (Line(
            points={{50,-78},{-100,-78},{-100,24},{-76,24}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(flowMeasure5.actualFlow, busConnector. LH_Na_Reab) annotation (Line(
            points={{70,1},{100,1},{100,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(LH.Reabsorbtion, flowMeasure5.q_in) annotation (Line(
            points={{78,20},{78,6},{74,6}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(flowMeasure5.q_out, NaPool.q_out) annotation (Line(
            points={{66,6},{-100,6},{-100,24},{-76,24}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(flowMeasure6.actualFlow, busConnector. PT_Na_Reab) annotation (Line(
            points={{23,12},{47.5,12},{47.5,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(PT.Reabsorbtion, flowMeasure6.q_in) annotation (Line(
            points={{18,20},{18,16}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(flowMeasure6.q_out, NaPool.q_out) annotation (Line(
            points={{18,8},{18,6},{-100,6},{-100,24},{-76,24}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));

        connect(concentrationMeasure1.actualConc, busConnector.NaPool_conc_per_liter)
          annotation (Line(
            points={{-92,40},{-92,46},{-98,46},{-98,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
        connect(concentrationMeasure.actualConc, Osm.u) annotation (Line(
            points={{50,-92},{60,-92},{60,-97},{67.4,-97}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(Osm.y, busConnector.MedullaNa_Osmolarity) annotation (Line(
            points={{74.3,-97},{100,-97},{100,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
        connect(busConnector.Aldo_conc_in_nG_per_dl, AldoEffect1.u)
                                             annotation (Line(
            points={{-92,92},{48,92},{48,-30},{52.2,-30}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-6,3},{-6,3}}));
        connect(busConnector.KidneyFunctionEffect, AldoEffect1.yBase) annotation (
            Line(
            points={{-92,92},{48,92},{48,-28},{62,-28}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
        connect(AldoEffect1.y, ThiazideEffect.yBase) annotation (Line(
            points={{62,-32},{62,-36}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(ThiazideEffect.y, LoadEffect1.yBase) annotation (Line(
            points={{62,-40},{62,-44}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(AldoEffect1.y, AldoEffect2.u) annotation (Line(
            points={{62,-32},{62,-34},{96,-34},{96,-90},{84,-90},{84,-87.8}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(LH.ReabFract, busConnector. LH_Na_FractReab) annotation (Line(
            points={{88,20},{100,20},{100,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(PT.ReabFract, busConnector. PT_Na_FractReab) annotation (Line(
            points={{28,20},{48,20},{48,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(flowMeasure2.actualFlow, busConnector. DT_Na_Outflow) annotation (Line(
            points={{48,-59},{48,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(flowMeasure3.actualFlow, busConnector. CD_Na_Outflow) annotation (Line(
            points={{0,-69},{0,-72},{-98,-72},{-98,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(flowMeasure4.actualFlow, busConnector. DT_Na_Reab) annotation (Line(
            points={{54,-83},{54,-92},{100,-92},{100,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{6,3},{6,3}}));
        connect(concentrationMeasure.actualConc, busConnector.MedullaNa_conc)
          annotation (Line(
            points={{50,-92},{100,-92},{100,92},{-92,92}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
      end Sodium2;
    end Sodium;

    package Potassium "Body Potassium Distribution"

      model IkedaPotasiumIntoICFFactor

       annotation (
          Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}},
              grid={2,2}), graphics={Rectangle(
                extent={{-100,50},{100,-50}},
                lineColor={127,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Sphere), Text(
                extent={{-86,-36},{100,40}},
                textString="%name",
                lineColor={0,0,0},
                fillPattern=FillPattern.Sphere)}), Diagram(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics));
        Library.Interfaces.RealInput_ yBase
                         annotation (Placement(transformation(extent={{-20,-20},{
                  20,20}},
              rotation=270,
              origin={6,100}),
              iconTransformation(extent={{-10,-10},{10,10}},rotation=270,
              origin={0,50})));
        Library.Interfaces.RealOutput_ y
                      annotation (Placement(transformation(extent={{-20,-20},{20,
                  20}},
              rotation=270,
              origin={0,-80}),
              iconTransformation(extent={{-10,-10},{10,10}},  rotation=270,
              origin={0,-52})));

        Library.Interfaces.RealInput_ Artys_pH annotation (Placement(transformation(
                extent={{-118,10},{-78,50}}), iconTransformation(extent={{-120,10},{-80,
                  50}})));
        Library.Interfaces.RealInput_ PotasiumECF_conc annotation (Placement(
              transformation(extent={{-118,-28},{-78,12}}),iconTransformation(extent={
                  {-120,-50},{-80,-10}})));

        Real effect;
      equation
        effect = 1+0.5*log(PotasiumECF_conc/(56.744-7.06*Artys_pH));
        y = yBase*effect;
      end IkedaPotasiumIntoICFFactor;

      model Potassium2
        //extends Library.Interfaces.BaseModel;
        Library.ConcentrationFlow.ConcentrationCompartment KPool(
            initialSoluteMass=66.0)
          annotation (Placement(transformation(extent={{-34,14},{-14,34}})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}),       graphics), Icon(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics={Bitmap(extent={{-100,100},{100,-100}}, fileName=
                    "icons/K.jpg"), Text(
                extent={{-112,-102},{108,-128}},
                lineColor={0,0,255},
                textString="%name")}),
          Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
<tr>
<td>References:</td>
<td>Tom Coleman: QHP 2008 beta 3, University of Mississippi Medical Center</td>
</tr><tr>
<td></td>
<td>Noriaki Ikeda: A model of overall regulation of body fluids (1979), Kitasato University</td>
</tr>
</table>
</html>"));
        Library.ConcentrationFlow.ConcentrationCompartment GILumen(
            initialSoluteMass=25)
          annotation (Placement(transformation(extent={{-18,-36},{2,-16}})));
        Library.ConcentrationFlow.SoluteFlowPump Absorbtion
          annotation (Placement(transformation(extent={{6,-20},{18,-32}})));
        Modelica.Blocks.Math.Gain Perm(k=.002)
          annotation (Placement(transformation(extent={{0,-48},{6,-42}})));
        Library.ConcentrationFlow.OutputPump Hemorrhage
          annotation (Placement(transformation(extent={{20,-86},{40,-66}})));
        Library.ConcentrationFlow.OutputPump DialyzerActivity
          annotation (Placement(transformation(extent={{20,-100},{40,-80}})));
        Library.ConcentrationFlow.OutputPump SweatDuct
          annotation (Placement(transformation(extent={{20,-72},{40,-52}})));
        Library.ConcentrationFlow.InputPump IVDrip
          annotation (Placement(transformation(extent={{0,-80},{20,-60}})));
        Library.ConcentrationFlow.InputPump Transfusion
          annotation (Placement(transformation(extent={{0,-94},{20,-74}})));
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(
            initialSoluteMass=0)
          annotation (Placement(transformation(extent={{94,12},{74,32}})));
        QHP.Library.Factors.SplineValue NaEffect(data={{0.0,0.3,0},{0.4,1.0,1.5},
              {4.0,3.0,0}})
          annotation (Placement(transformation(extent={{44,30},{24,50}})));
        Library.Factors.DelayedToSpline AldoEffect(
          data={{0.0,0.5,0},{12.0,1.0,0.08},{50.0,3.0,0}},
          Tau=3*60,
          initialValue=11)
          annotation (Placement(transformation(extent={{44,38},{24,58}})));
        QHP.Library.Factors.SplineValue ThiazideEffect(data={{0.0,1.0,2.0},{0.6,
              2.0,0}})
          annotation (Placement(transformation(extent={{44,46},{24,66}})));
        Library.ConcentrationFlow.InputPump Diet
          annotation (Placement(transformation(extent={{-66,-42},{-46,-22}})));
        Library.ConcentrationFlow.OutputPump Diarrhea
          annotation (Placement(transformation(extent={{-10,-10},{10,10}},
              rotation=180,
              origin={-56,-44})));
        Library.ConcentrationFlow.ConcentrationCompartment KCell(
            initialSoluteMass=3980)
          annotation (Placement(transformation(extent={{-30,70},{-10,90}})));
        Library.ConcentrationFlow.SoluteFlowPump KFluxToCell
          annotation (Placement(transformation(extent={{-6,-6},{6,6}},
              rotation=90,
              origin={-30,58})));
        Modelica.Blocks.Math.Gain Perm1(k=.002)
          annotation (Placement(transformation(extent={{-3,-3},{3,3}},
              rotation=90,
              origin={-55,53})));
        Library.ConcentrationFlow.SoluteFlowPump KFluxToPool
          annotation (Placement(transformation(extent={{-6,-6},{6,6}},
              rotation=270,
              origin={-12,48})));
        Modelica.Blocks.Math.Feedback feedback
          annotation (Placement(transformation(extent={{-10,62},{-2,54}})));
        QHP.Library.Blocks.ElectrolytesMassConstant KCell_CaptiveMass(k=2180)
          annotation (Placement(transformation(extent={{8,76},{-2,66}})));
        Modelica.Blocks.Math.Gain Perm2(k=7.4e-5)
          annotation (Placement(transformation(extent={{-3,-3},{3,3}},
              rotation=270,
              origin={3,53})));
        Library.Blocks.ElectrolytesFlowConstant electrolytesFlowConstant(k=.05)
          annotation (Placement(transformation(extent={{18,76},{30,88}})));
        Library.ConcentrationFlow.SoluteFlowPump DT_K
          annotation (Placement(transformation(extent={{-6,-6},{6,6}},
              rotation=0,
              origin={34,22})));
        QHP.Library.Factors.SplineValue KEffect(data={{0.0,0.0,0},{4.4,1.0,0.5},
              {5.5,3.0,0}})
          annotation (Placement(transformation(extent={{24,22},{44,42}})));
        Modelica.Blocks.Math.Gain mEq_per_L(k=1000)
          annotation (Placement(transformation(extent={{-3,-3},{3,3}},
              rotation=0,
              origin={15,31})));
        Modelica.Blocks.Math.Division division
          annotation (Placement(transformation(extent={{-18,6},{-14,10}})));
        Library.Factors.SimpleMultiply KidneyFunction
          annotation (Placement(transformation(extent={{44,54},{24,74}})));
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={30,6})));
        Modelica.Blocks.Math.Gain gain(k=1000)
          annotation (Placement(transformation(extent={{40,4},{44,8}})));
        Library.Factors.SplineDelayByDay splineDelayByDay(              data={{
              0,0.9,0.0},{300,1.0,0.00025},{1500,1.1,0.0}}, Tau=120*1440)
                                                            annotation (
            Placement(transformation(
              extent={{10,-10},{-10,10}},
              rotation=90,
              origin={-48,58})));
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid
          annotation (Placement(transformation(extent={{82,-20},{94,-8}})));
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(
            unitsString="mEq/l", toAnotherUnitCoef=1000)
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=0,
              origin={-8,80})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure annotation (Placement(
              transformation(
              extent={{-8,8},{8,-8}},
              rotation=90,
              origin={-24,34})));
        Library.ConcentrationFlow.SoluteFlowPump KFluxToCellWithGlucose
          annotation (Placement(transformation(extent={{-6,-6},{6,6}},
              rotation=90,
              origin={-68,60})));
        Modelica.Blocks.Math.Gain CGL3(k=.03)
          "glucose flow into cells to potassium flow into cells"
          annotation (Placement(transformation(extent={{-2,-2},{2,2}},
              rotation=0,
              origin={-78,60})));
        IkedaPotasiumIntoICFFactor IkedaIntoICF annotation (Placement(
              transformation(
              extent={{-10,-10},{10,10}},
              rotation=90,
              origin={-40,58})));
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure2(
            unitsString="mEq/l", toAnotherUnitCoef=1000)
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=0,
              origin={-48,24})));
        Library.Interfaces.BusConnector busConnector
          annotation (Placement(transformation(extent={{-94,88},{-82,100}}),
              iconTransformation(extent={{60,60},{100,100}})));
        Modelica.Blocks.Math.Add3 YGLS "Ikeda glucose to cells flow"
          annotation (Placement(transformation(extent={{-84,66},{-74,76}})));
      equation

      connect(KPool.SolventVolume, busConnector. ECFV_Vol)  annotation (Line(
            points={{-32,30},{-95,30},{-95,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(GILumen.SolventVolume, busConnector. GILumenVolume_Mass) annotation (Line(
            points={{-16,-20},{-96,-20},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(GILumen.q_out, Absorbtion.q_in) annotation (Line(
            points={{-8,-26},{-1,-26},{-1,-26},{6,-26}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Absorbtion.q_out, KPool.q_out)  annotation (Line(
            points={{18,-26},{22,-26},{22,24},{-24,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Hemorrhage.q_in, KPool.q_out)  annotation (Line(
            points={{24,-76},{22,-76},{22,24},{-24,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(DialyzerActivity.q_in, KPool.q_out)  annotation (Line(
            points={{24,-90},{22,-90},{22,24},{-24,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(KPool.q_out, SweatDuct.q_in)  annotation (Line(
            points={{-24,24},{22,24},{22,-62},{24,-62}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Transfusion.q_out, KPool.q_out)  annotation (Line(
            points={{16,-84},{22,-84},{22,24},{-24,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(IVDrip.q_out, KPool.q_out)  annotation (Line(
            points={{16,-70},{22,-70},{22,24},{-24,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Bladder.SolventVolume, busConnector. BladderVolume_Mass) annotation (Line(
            points={{92,28},{98,28},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(AldoEffect.y, NaEffect.yBase)     annotation (Line(
            points={{34,46},{34,42}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(ThiazideEffect.y, AldoEffect.yBase)  annotation (Line(
            points={{34,54},{34,50}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(ThiazideEffect.u, busConnector. ThiazidePool_Thiazide_conc) annotation (Line(
            points={{43.8,56},{98,56},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(IVDrip.desiredFlow, busConnector. IVDrip_KRate)  annotation (Line(
            points={{10,-66},{10,-64},{-96,-64},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Transfusion.desiredFlow, busConnector. Transfusion_KRate)  annotation (Line(
            points={{10,-80},{-96,-80},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(SweatDuct.desiredFlow, busConnector. SweatDuct_KRate)  annotation (Line(
            points={{30,-58},{30,-54},{98,-54},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(busConnector.Hemorrhage_KRate, Hemorrhage.desiredFlow)  annotation (Line(
            points={{-88,94},{98,94},{98,-72},{30,-72}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-3,1},{-3,1}}));
        connect(DialyzerActivity.desiredFlow, busConnector. DialyzerActivity_K_Flux)
          annotation (Line(
            points={{30,-86},{98,-86},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Diet.desiredFlow, busConnector. DietIntakeElectrolytes_K)
                                                   annotation (Line(
            points={{-56,-28},{-56,-26},{-96,-26},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Diet.q_out, GILumen.q_out) annotation (Line(
            points={{-50,-32},{-16,-32},{-16,-26},{-8,-26}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Diarrhea.desiredFlow, busConnector. GILumenDiarrhea_KLoss)
                                                         annotation (Line(
            points={{-56,-48},{-96,-48},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(GILumen.q_out, Diarrhea.q_in) annotation (Line(
            points={{-8,-26},{-16,-26},{-16,-44},{-50,-44}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(KCell.SolventVolume, busConnector. CellH2O_Vol) annotation (Line(
            points={{-28,86},{-95,86},{-95,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Perm.y, Absorbtion.soluteFlow) annotation (Line(
            points={{6.3,-45},{12,-45},{12,-29.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(Perm.u, GILumen.SoluteMass) annotation (Line(
            points={{-0.6,-45},{-8,-45},{-8,-33.8}},
            color={0,0,127},
            smooth=Smooth.None));

        connect(KFluxToCell.q_out, KCell.q_out) annotation (Line(
            points={{-30,64},{-30,80},{-20,80}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(KCell.q_out, KFluxToPool.q_in) annotation (Line(
            points={{-20,80},{-12,80},{-12,54}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(KPool.SoluteMass, Perm1.u) annotation (Line(
            points={{-24,16.2},{-24,10},{-55,10},{-55,49.4}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(KCell.SoluteMass, feedback.u1) annotation (Line(
            points={{-20,72.2},{-20,58},{-9.2,58}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(KCell_CaptiveMass.y, feedback.u2) annotation (Line(
            points={{-2.5,71},{-6,71},{-6,61.2}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(feedback.y, Perm2.u) annotation (Line(
            points={{-2.4,58},{3.3,58},{3.3,56.6},{3,56.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(KFluxToPool.soluteFlow, Perm2.y) annotation (Line(
            points={{-8.4,48},{3,48},{3,49.7}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(AldoEffect.u, busConnector.Aldo_conc_in_nG_per_dl)   annotation (Line(
            points={{43.8,48},{98,48},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(NaEffect.u, busConnector. DT_Na_Outflow) annotation (Line(
            points={{43.8,40},{98,40},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(KPool.q_out, DT_K.q_in) annotation (Line(
            points={{-24,24},{22,24},{22,22},{28,22}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(NaEffect.y, KEffect.yBase) annotation (Line(
            points={{34,38},{34,34}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(KEffect.y, DT_K.soluteFlow) annotation (Line(
            points={{34,30},{34,25.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(mEq_per_L.y, KEffect.u) annotation (Line(
            points={{18.3,31},{21.15,31},{21.15,32},{24.2,32}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(division.u1, KPool.SoluteMass) annotation (Line(
            points={{-18.4,9.2},{-24,9.2},{-24,16.2}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(busConnector.ECFV_Vol, division.u2) annotation (Line(
            points={{-88,94},{-96,94},{-96,6.8},{-18.4,6.8}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-3,1},{-3,1}}));
        connect(division.y, mEq_per_L.u) annotation (Line(
            points={{-13.8,8},{-8,8},{-8,31},{11.4,31}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(electrolytesFlowConstant.y, KidneyFunction.yBase) annotation (
            Line(
            points={{30.6,82},{34,82},{34,66}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(KidneyFunction.y, ThiazideEffect.yBase) annotation (Line(
            points={{34,62},{34,58}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(KidneyFunction.u, busConnector. KidneyFunctionEffect) annotation (Line(
            points={{43.8,64},{98,64},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(DT_K.q_out, Bladder.q_out) annotation (Line(
            points={{40,22},{84,22}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(busConnector.KCell_Mass, KCell.SoluteMass) annotation (Line(
            points={{-88,94},{-4,94},{-4,72},{-20,72},{-20,72.2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-3,1},{-3,1}}));
        connect(KPool.SoluteMass, busConnector. KPool_mass) annotation (Line(
            points={{-24,16.2},{-24,10},{-96,10},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure.q_in, KPool.q_out) annotation (Line(
            points={{30,6},{22,6},{22,24},{-24,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(concentrationMeasure.actualConc, gain.u) annotation (Line(
            points={{34,6},{36.8,6},{36.8,6},{39.6,6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(gain.y, busConnector. KPool_conc_per_liter) annotation (Line(
            points={{44.2,6},{98,6},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Perm1.y, splineDelayByDay.yBase) annotation (Line(
            points={{-55,56.3},{-55,58},{-50,58}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(splineDelayByDay.u, busConnector. AldoPool_Aldo) annotation (Line(
            points={{-48,67.8},{-48,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Bladder.q_out, bladderVoid.q_in) annotation (Line(
            points={{84,22},{66,22},{66,-14},{82,-14}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(bladderVoid.solventFlow, busConnector. BladderVoidFlow) annotation (Line(
            points={{88,-10.4},{88,-6},{98,-6},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(GILumen.SoluteMass, busConnector. GILumenPotassium_Mass)
        annotation (Line(
            points={{-8,-33.8},{-8,-54},{-96,-54},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));                                           //fix: it was busConnector. GILumenPotasium_Mass
        connect(KCell.q_out, concentrationMeasure1.q_in) annotation (Line(
            points={{-20,80},{-8,80}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(concentrationMeasure1.actualConc, busConnector. KCell_conc) annotation (Line(
            points={{-8,84},{-8,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(KPool.q_out, flowMeasure.q_in) annotation (Line(
            points={{-24,24},{-24,30.8}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(flowMeasure.q_out, KFluxToPool.q_out) annotation (Line(
            points={{-24,37.2},{-24,38},{-12,38},{-12,42}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(flowMeasure.q_out, KFluxToCell.q_in) annotation (Line(
            points={{-24,37.2},{-24,38},{-30,38},{-30,52}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(flowMeasure.actualFlow, busConnector. PotassiumToCells) annotation (Line(
            points={{-20,34},{-95,34},{-95,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(flowMeasure.q_out, KFluxToCellWithGlucose.q_in) annotation (
            Line(
            points={{-24,37.2},{-24,38},{-68,38},{-68,54}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(KFluxToCellWithGlucose.q_out, KCell.q_out) annotation (Line(
            points={{-68,66},{-68,80},{-20,80}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(CGL3.y, KFluxToCellWithGlucose.soluteFlow) annotation (Line(
            points={{-75.8,60},{-71.6,60}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(IkedaIntoICF.y, KFluxToCell.soluteFlow) annotation (Line(
            points={{-34.8,58},{-33.6,58}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(splineDelayByDay.y, IkedaIntoICF.yBase) annotation (Line(
            points={{-46,58},{-45,58}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(IkedaIntoICF.Artys_pH, busConnector. Artys_pH) annotation (Line(
            points={{-43,48},{-44,46},{-44,42},{-96,42},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure2.q_in, KPool.q_out) annotation (Line(
            points={{-48,24},{-24,24}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(concentrationMeasure2.actualConc, IkedaIntoICF.PotasiumECF_conc)
          annotation (Line(
            points={{-48,28},{-48,40},{-37,40},{-37,48}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(concentrationMeasure2.actualConc, busConnector. KPool_per_liter) annotation (
            Line(
            points={{-48,28},{-48,30},{-96,30},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));

        connect(busConnector.skeletalMuscle_GlucoseToCellStorageFlow,YGLS. u2)
                   annotation (Line(
            points={{-88,94},{-96,94},{-96,71},{-85,71}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
        connect(busConnector.liver_GlucoseToCellStorageFlow,YGLS. u1)
          annotation (Line(
            points={{-88,94},{-96,94},{-96,75},{-85,75}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
        connect(busConnector.respiratoryMuscle_GlucoseToCellStorageFlow,YGLS. u3)
          annotation (Line(
            points={{-88,94},{-96,94},{-96,67},{-85,67}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
        connect(YGLS.y, CGL3.u) annotation (Line(
            points={{-73.5,71},{-72,71},{-72,64},{-82,64},{-82,60},{-80.4,60}},
            color={0,0,127},
            smooth=Smooth.None));

        connect(KEffect.y, busConnector. CD_K_Outflow) annotation (Line(
            points={{34,30},{98,30},{98,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure2.actualConc, busConnector.KPool)
          annotation (Line(
            points={{-48,28},{-96,28},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
        connect(GILumen.SoluteMass, busConnector.GILumenPotassium_Mass)
          annotation (Line(
            points={{-8,-33.8},{-8,-54},{-96,-54},{-96,94},{-88,94}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
      end Potassium2;
    end Potassium;

    package Chloride "Body Chloride Distribution"

      model Chloride2
       // extends Library.Interfaces.BaseModel;
        Library.ConcentrationFlow.ConcentrationCompartment ClPool(
            initialSoluteMass=1562.23)
          annotation (Placement(transformation(extent={{-78,14},{-58,34}})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}),       graphics), Icon(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics={Bitmap(extent={{-100,100},{100,-100}}, fileName=
                    "icons/Cl.jpg"), Text(
                extent={{-112,-102},{108,-128}},
                lineColor={0,0,255},
                textString="%name")}),
          Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
<tr>
<td>References:</td>
<td>Tom Coleman: QHP 2008 beta 3, University of Mississippi Medical Center</td>
</tr>
</table>
</html>"));
        Library.ConcentrationFlow.ConcentrationCompartment GILumen(
            initialSoluteMass=90)
          annotation (Placement(transformation(extent={{-82,-36},{-62,-16}})));
        Library.ConcentrationFlow.SoluteFlowPump Absorbtion
          annotation (Placement(transformation(extent={{-58,-20},{-46,-32}})));
        Modelica.Blocks.Math.Gain Perm(k=.0015)
          annotation (Placement(transformation(extent={{-64,-48},{-58,-42}})));
        Library.ConcentrationFlow.OutputPump Hemorrhage
          annotation (Placement(transformation(extent={{-44,-86},{-24,-66}})));
        Library.ConcentrationFlow.OutputPump DialyzerActivity
          annotation (Placement(transformation(extent={{-44,-100},{-24,-80}})));
        Library.ConcentrationFlow.OutputPump SweatDuct
          annotation (Placement(transformation(extent={{-44,-72},{-24,-52}})));
        Library.ConcentrationFlow.InputPump IVDrip
          annotation (Placement(transformation(extent={{-64,-80},{-44,-60}})));
        Library.ConcentrationFlow.InputPump Transfusion
          annotation (Placement(transformation(extent={{-64,-94},{-44,-74}})));
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(
            initialSoluteMass=0)
          annotation (Placement(transformation(extent={{50,14},{70,34}})));
        Library.ConcentrationFlow.InputPump Diet
          annotation (Placement(transformation(extent={{-100,-42},{-80,-22}})));
        Library.ConcentrationFlow.OutputPump Diarrhea
          annotation (Placement(transformation(extent={{-10,-10},{10,10}},
              rotation=180,
              origin={-90,-44})));
        Library.ConcentrationFlow.SoluteFlowPump CD_Cl
          annotation (Placement(transformation(extent={{-6,-6},{6,6}},
              rotation=0,
              origin={26,24})));
        QHP.Library.Factors.SplineValue KEffect1(data={{7.00,1.00,0},{7.45,0.93,
              -0.5},{7.80,0.00,0}})
          annotation (Placement(transformation(extent={{16,36},{36,56}})));
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={-56,40})));
        Modelica.Blocks.Math.Gain gain(k=1000)
          annotation (Placement(transformation(extent={{-46,38},{-42,42}})));
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid
          annotation (Placement(transformation(extent={{58,-14},{70,-2}})));
        Library.Interfaces.BusConnector busConnector
          annotation (Placement(transformation(extent={{-92,-4},{-80,8}}),
              iconTransformation(extent={{62,62},{100,100}})));
      equation
       connect(ClPool.SolventVolume, busConnector. ECFV_Vol) annotation (Line(
            points={{-76,30},{-81,30},{-81,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(GILumen.SolventVolume, busConnector. GILumenVolume_Mass) annotation (Line(
            points={{-80,-20},{-87,-20},{-87,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(GILumen.q_out, Absorbtion.q_in) annotation (Line(
            points={{-72,-26},{-65,-26},{-65,-26},{-58,-26}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Absorbtion.q_out, ClPool.q_out) annotation (Line(
            points={{-46,-26},{-44,-26},{-44,24},{-68,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Hemorrhage.q_in, ClPool.q_out) annotation (Line(
            points={{-40,-76},{-44,-76},{-44,24},{-68,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(DialyzerActivity.q_in, ClPool.q_out) annotation (Line(
            points={{-40,-90},{-44,-90},{-44,24},{-68,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(ClPool.q_out, SweatDuct.q_in) annotation (Line(
            points={{-68,24},{-44,24},{-44,-62},{-40,-62}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Transfusion.q_out, ClPool.q_out) annotation (Line(
            points={{-48,-84},{-44,-84},{-44,24},{-68,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(IVDrip.q_out, ClPool.q_out) annotation (Line(
            points={{-48,-70},{-44,-70},{-44,24},{-68,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Bladder.SolventVolume, busConnector. BladderVolume_Mass) annotation (Line(
            points={{52,30},{46,30},{46,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(IVDrip.desiredFlow, busConnector. IVDrip_ClRate) annotation (Line(
            points={{-54,-66},{-54,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Transfusion.desiredFlow, busConnector. Transfusion_ClRate) annotation (Line(
            points={{-54,-80},{-76,-80},{-76,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(SweatDuct.desiredFlow, busConnector. SweatDuct_ClRate) annotation (Line(
            points={{-34,-58},{-34,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(busConnector.Hemorrhage_ClRate, Hemorrhage.desiredFlow) annotation (Line(
            points={{-86,2},{-33.5,2},{-33.5,-72},{-34,-72}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-3,1},{-3,1}}));
        connect(DialyzerActivity.desiredFlow, busConnector. DialyzerActivity_Cl_Flux)
          annotation (Line(
            points={{-34,-86},{-34,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Diet.desiredFlow, busConnector.DietIntakeElectrolytes_Cl)
                                                   annotation (Line(
            points={{-90,-28},{-90,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Diet.q_out, GILumen.q_out) annotation (Line(
            points={{-84,-32},{-80,-32},{-80,-26},{-72,-26}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Diarrhea.desiredFlow, busConnector.GILumenVomitus_ClLoss)
                                                         annotation (Line(
            points={{-90,-48},{-90,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(GILumen.q_out, Diarrhea.q_in) annotation (Line(
            points={{-72,-26},{-80,-26},{-80,-44},{-84,-44}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Perm.y, Absorbtion.soluteFlow) annotation (Line(
            points={{-57.7,-45},{-52,-45},{-52,-29.6}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(Perm.u, GILumen.SoluteMass) annotation (Line(
            points={{-64.6,-45},{-72,-45},{-72,-33.8}},
            color={0,0,127},
            smooth=Smooth.None));

        connect(busConnector.CollectingDuct_NetSumCats, KEffect1.yBase) annotation (Line(
            points={{-86,2},{26,2},{26,48}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-3,1},{-3,1}}));
        connect(CD_Cl.soluteFlow, KEffect1.y) annotation (Line(
            points={{26,27.6},{26,44}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(CD_Cl.q_out, Bladder.q_out) annotation (Line(
            points={{32,24},{46,24},{46,24},{60,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(CD_Cl.q_in, ClPool.q_out) annotation (Line(
            points={{20,24},{-68,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(ClPool.SoluteMass, busConnector. ClPool_mass) annotation (Line(
            points={{-68,16.2},{-68,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure.actualConc, gain.u) annotation (Line(
            points={{-52,40},{-46.4,40}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(gain.y, busConnector. ClPool_conc_per_liter) annotation (Line(
            points={{-41.8,40},{-69.9,40},{-69.9,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(ClPool.q_out, concentrationMeasure.q_in) annotation (Line(
            points={{-68,24},{-62,24},{-62,40},{-56,40}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(Bladder.q_out, bladderVoid.q_in) annotation (Line(
            points={{60,24},{42,24},{42,-8},{58,-8}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(bladderVoid.solventFlow, busConnector. BladderVoidFlow) annotation (Line(
            points={{64,-4.4},{64,2},{-86,2}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));

        connect(busConnector.Artys_pH, KEffect1.u) annotation (Line(
            points={{-86,2},{-90,2},{-90,46},{16.2,46}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
      end Chloride2;
    end Chloride;

    package Phosphate "Body Phosphate Distribution"

      model GlomerulusStrongAnionFiltration

        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{90,-10},{110,10}})));

       annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={
              Rectangle(
                extent={{-100,-50},{100,50}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-150,-100},{150,-60}},
                textString="%name",
                lineColor={0,0,255}),
              Line(
                points={{0,42},{0,26}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5),
              Line(
                points={{0,20},{0,4}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5),
              Line(
                points={{0,-4},{0,-20}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5),
              Line(
                points={{0,-26},{0,-42}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5)}),       Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics));

        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in
                                  annotation (Placement(
              transformation(extent={{-120,-20},{-80,20}}), iconTransformation(extent=
                 {{-110,-10},{-90,10}})));

        Library.Interfaces.RealInput_ Cations( final quantity="Concentration", final unit =    "mEq/l") annotation (Placement(
              transformation(extent={{-80,30},{-40,70}}), iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={-60,50})));
        Library.Interfaces.RealInput_ otherStrongAnions(final quantity=
              "Concentration", final unit="mEq/l")                                                            annotation (Placement(
              transformation(extent={{-40,30},{0,70}}), iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={-20,50})));
        Real KAdjustment;
        //Real Cations( final quantity="Concentration", final unit = "mEq/l");
        Real Anions( final quantity="Concentration", final unit = "mEq/l");
        Real ProteinAnions( final quantity="Concentration", final unit = "mEq/l");
        Library.Interfaces.RealInput_ HCO3(final quantity="Concentration",
            final unit="mEq/l")                                                                               annotation (Placement(
              transformation(extent={{0,30},{40,70}}),  iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={20,50})));
      equation
        q_in.q + q_out.q = 0;
        //Cations = q_in.conc*1000+otherCations;
        Anions = Cations;
        ProteinAnions = Anions - otherStrongAnions - q_in.conc*1000 - HCO3;
        KAdjustment = (Cations-(Anions-ProteinAnions))/(Cations+(Anions-ProteinAnions));
        q_out.conc = (1+KAdjustment)*q_in.conc;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end GlomerulusStrongAnionFiltration;

      model Phosphate2
       // extends Library.Interfaces.BaseModel;
        Library.ConcentrationFlow.ConcentrationCompartment PO4Pool(
            initialSoluteMass=2.6)
          annotation (Placement(transformation(extent={{-64,14},{-44,34}})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}),       graphics), Icon(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics={Bitmap(extent={{-100,100},{100,-100}}, fileName=
                    "icons/fosfat.png"), Text(
                extent={{-108,-98},{112,-124}},
                lineColor={0,0,255},
                textString="%name")}));
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(
            initialSoluteMass=0)
          annotation (Placement(transformation(extent={{50,14},{70,34}})));
        Library.ConcentrationFlow.InputPump Diet
          annotation (Placement(transformation(extent={{-84,-4},{-64,16}})));
        Library.ConcentrationFlow.SolventFlowPump glomerulusPhosphateRate
          annotation (Placement(transformation(extent={{0,14},{20,34}})));
        GlomerulusStrongAnionFiltration glomerulus
          annotation (Placement(transformation(extent={{-28,14},{-8,34}})));
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={-28,2})));
        Modelica.Blocks.Math.Gain gain(k=1000)
          annotation (Placement(transformation(extent={{-18,0},{-14,4}})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure
          annotation (Placement(transformation(extent={{20,34},{40,14}})));
        Modelica.Blocks.Math.Gain gain1(k=.5)
          annotation (Placement(transformation(extent={{-50,-14},{-46,-10}})));
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid
          annotation (Placement(transformation(extent={{66,-20},{78,-8}})));
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure1(
            unitsString="mmol/l", toAnotherUnitCoef=1000) annotation (Placement(
              transformation(
              extent={{-10,-10},{10,10}},
              rotation=0,
              origin={-60,60})));
        Library.Interfaces.BusConnector busConnector
          annotation (Placement(transformation(extent={{-90,76},{-78,88}}),
              iconTransformation(extent={{60,60},{100,100}})));
      equation
       connect(PO4Pool.SolventVolume, busConnector. ECFV_Vol)
                                                annotation (Line(
            points={{-62,30},{-67,30},{-67,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Bladder.SolventVolume, busConnector. BladderVolume_Mass) annotation (Line(
            points={{52,30},{46,30},{46,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Diet.desiredFlow, busConnector. DietIntakeElectrolytes_PO4)
                                                   annotation (Line(
            points={{-74,10},{-74,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));

        connect(Diet.q_out, PO4Pool.q_out) annotation (Line(
            points={{-68,6},{-60,6},{-60,24},{-54,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(glomerulusPhosphateRate.solventFlow, busConnector. GlomerulusFiltrate_GFR)
          annotation (Line(
            points={{10,30},{10,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(glomerulus.q_out, glomerulusPhosphateRate.q_in)
                                                             annotation (Line(
            points={{-8,24},{0,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(PO4Pool.q_out, glomerulus.q_in) annotation (Line(
            points={{-54,24},{-41,24},{-41,24},{-28,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(glomerulus.HCO3, busConnector. CO2Veins_cHCO3)  annotation (Line(
            points={{-16,29},{-16,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure.actualConc, gain.u) annotation (Line(
            points={{-24,2},{-21.2,2},{-21.2,2},{-18.4,2}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(gain.y, busConnector. PO4Pool_conc_per_liter) annotation (Line(
            points={{-13.8,2},{-48.9,2},{-48.9,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure.q_in, PO4Pool.q_out) annotation (Line(
            points={{-28,2},{-34,2},{-34,24},{-54,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(flowMeasure.actualFlow, busConnector. CD_PO4_Outflow) annotation (Line(
            points={{30,19},{30,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(flowMeasure.q_out, Bladder.q_out) annotation (Line(
            points={{34,24},{50,24},{50,24},{60,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(glomerulusPhosphateRate.q_out, flowMeasure.q_in) annotation (
            Line(
            points={{20,24},{26,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(busConnector.BloodIons_StrongAnionsLessPO4, glomerulus.otherStrongAnions)
          annotation (Line(
            points={{-84,82},{-20,82},{-20,29}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-3,1},{-3,1}}));
        connect(busConnector.BloodIons_Cations, glomerulus.Cations) annotation (Line(
            points={{-84,82},{-24,82},{-24,29}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-3,1},{-3,1}}));
        connect(PO4Pool.SoluteMass, gain1.u) annotation (Line(
            points={{-54,16.2},{-54,-12},{-50.4,-12}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(gain1.y, busConnector. PO4Pool_Osmoles) annotation (Line(
            points={{-45.8,-12},{-64.9,-12},{-64.9,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Bladder.q_out, bladderVoid.q_in) annotation (Line(
            points={{60,24},{50,24},{50,-14},{66,-14}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(bladderVoid.solventFlow, busConnector. BladderVoidFlow) annotation (Line(
            points={{72,-10.4},{72,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure1.actualConc, busConnector. ctPO4) annotation (Line(
            points={{-60,64},{-60,82},{-84,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure1.q_in, PO4Pool.q_out) annotation (Line(
            points={{-60,60},{-54,60},{-54,24}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));

      end Phosphate2;
    end Phosphate;

    package Sulphate "Body Sulphate Distribution"

      model GlomerulusStrongAnionFiltration

        QHP.Library.ConcentrationFlow.NegativeConcentrationFlow q_out
                               annotation (extent=[-10, -110; 10, -90], Placement(
              transformation(extent={{90,-10},{110,10}})));

       annotation (
          Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={
              Rectangle(
                extent={{-100,-50},{100,50}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-150,-100},{150,-60}},
                textString="%name",
                lineColor={0,0,255}),
              Line(
                points={{0,42},{0,26}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5),
              Line(
                points={{0,20},{0,4}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5),
              Line(
                points={{0,-4},{0,-20}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5),
              Line(
                points={{0,-26},{0,-42}},
                color={0,0,255},
                smooth=Smooth.None,
                thickness=0.5)}),       Diagram(coordinateSystem(preserveAspectRatio=true,
                         extent={{-100,-100},{100,100}}), graphics));

        QHP.Library.ConcentrationFlow.PositiveConcentrationFlow q_in
                                  annotation (Placement(
              transformation(extent={{-120,-20},{-80,20}}), iconTransformation(extent=
                 {{-110,-10},{-90,10}})));

        Library.Interfaces.RealInput_ Cations( final quantity="Concentration", final unit =    "mEq/l") annotation (Placement(
              transformation(extent={{-80,30},{-40,70}}), iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={-60,50})));
        Library.Interfaces.RealInput_ otherStrongAnions(final quantity=
              "Concentration", final unit="mEq/l")                                                            annotation (Placement(
              transformation(extent={{-40,30},{0,70}}), iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={-20,50})));
        Real KAdjustment;
        //Real Cations( final quantity="Concentration", final unit = "mEq/l");
        Real Anions( final quantity="Concentration", final unit = "mEq/l");
        Real ProteinAnions( final quantity="Concentration", final unit = "mEq/l");
        Library.Interfaces.RealInput_ HCO3(final quantity="Concentration",
            final unit="mEq/l")                                                                               annotation (Placement(
              transformation(extent={{0,30},{40,70}}),  iconTransformation(
              extent={{-20,-20},{20,20}},
              rotation=270,
              origin={20,50})));
      equation
        q_in.q + q_out.q = 0;
        //Cations = q_in.conc*1000+otherCations;
        Anions = Cations;
        ProteinAnions = Anions - otherStrongAnions - q_in.conc*1000 - HCO3;
        KAdjustment = (Cations-(Anions-ProteinAnions))/(Cations+(Anions-ProteinAnions));
        q_out.conc = (1+KAdjustment)*q_in.conc;

        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics));
      end GlomerulusStrongAnionFiltration;

      model Sulphate2
        //extends Library.Interfaces.BaseModel;
        Library.ConcentrationFlow.ConcentrationCompartment SO4Pool(
            initialSoluteMass=4.2)
          annotation (Placement(transformation(extent={{-64,14},{-44,34}})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}),       graphics), Icon(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics={Text(
                extent={{-110,-104},{110,-130}},
                lineColor={0,0,255},
                textString="%name"), Bitmap(extent={{-100,100},{100,-100}},
                  fileName="icons/sulfat02.png")}));
        Library.ConcentrationFlow.ConcentrationCompartment Bladder(
            initialSoluteMass=0)
          annotation (Placement(transformation(extent={{50,14},{70,34}})));
        Library.ConcentrationFlow.InputPump Diet
          annotation (Placement(transformation(extent={{-84,-4},{-64,16}})));
        Library.ConcentrationFlow.SolventFlowPump glomerulusPhosphateRate
          annotation (Placement(transformation(extent={{-2,14},{18,34}})));
        GlomerulusStrongAnionFiltration glomerulus
          annotation (Placement(transformation(extent={{-28,14},{-8,34}})));
        Library.ConcentrationFlow.ConcentrationMeasure concentrationMeasure
          annotation (Placement(transformation(
              extent={{-10,-10},{10,10}},
              rotation=270,
              origin={-18,4})));
        Modelica.Blocks.Math.Gain gain(k=1000)
          annotation (Placement(transformation(extent={{-8,2},{-4,6}})));
        Library.ConcentrationFlow.FlowMeasure flowMeasure
          annotation (Placement(transformation(extent={{18,34},{38,14}})));
        Modelica.Blocks.Math.Gain gain1(k=.5)
          annotation (Placement(transformation(extent={{-52,-6},{-48,-2}})));
        Library.ConcentrationFlow.SolventOutflowPump bladderVoid
          annotation (Placement(transformation(extent={{66,-18},{78,-6}})));
        Library.Interfaces.BusConnector busConnector
          annotation (Placement(transformation(extent={{-96,76},{-84,88}}),
              iconTransformation(extent={{60,60},{100,100}})));
      equation
       connect(SO4Pool.SolventVolume, busConnector. ECFV_Vol)
                                                annotation (Line(
            points={{-62,30},{-67,30},{-67,82},{-90,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Bladder.SolventVolume, busConnector. BladderVolume_Mass) annotation (Line(
            points={{52,30},{46,30},{46,82},{-90,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(Diet.desiredFlow, busConnector.DietIntakeElectrolytes_SO4)
                                                   annotation (Line(
            points={{-74,10},{-74,82},{-90,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));

        connect(Diet.q_out,SO4Pool. q_out) annotation (Line(
            points={{-68,6},{-60,6},{-60,24},{-54,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(glomerulusPhosphateRate.solventFlow, busConnector. GlomerulusFiltrate_GFR)
          annotation (Line(
            points={{8,30},{8,82},{-90,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(glomerulus.q_out, glomerulusPhosphateRate.q_in)
                                                             annotation (Line(
            points={{-8,24},{-2,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(SO4Pool.q_out, glomerulus.q_in) annotation (Line(
            points={{-54,24},{-41,24},{-41,24},{-28,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(glomerulus.HCO3, busConnector. CO2Veins_cHCO3)  annotation (Line(
            points={{-16,29},{-16,82},{-90,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure.actualConc, gain.u) annotation (Line(
            points={{-14,4},{-11.2,4},{-11.2,4},{-8.4,4}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(gain.y, busConnector. SO4Pool_conc_per_liter) annotation (Line(
            points={{-3.8,4},{13.1,4},{13.1,82},{-90,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(concentrationMeasure.q_in, SO4Pool.q_out) annotation (Line(
            points={{-18,4},{-36,4},{-36,24},{-54,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(flowMeasure.actualFlow, busConnector. CD_SO4_Outflow) annotation (Line(
            points={{28,19},{28,82},{-90,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(flowMeasure.q_out, Bladder.q_out) annotation (Line(
            points={{32,24},{49,24},{49,24},{60,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(glomerulusPhosphateRate.q_out, flowMeasure.q_in) annotation (
            Line(
            points={{18,24},{24,24}},
            color={200,0,0},
            smooth=Smooth.None,
            thickness=1));
        connect(busConnector.BloodIons_StrongAnionsLessSO4, glomerulus.otherStrongAnions)
          annotation (Line(
            points={{-90,82},{-20,82},{-20,29}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-3,1},{-3,1}}));
        connect(busConnector.BloodIons_Cations, glomerulus.Cations) annotation (Line(
            points={{-90,82},{-24,82},{-24,29}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%first",
       index=-1,
       extent={{-3,1},{-3,1}}));
        connect(gain1.y, busConnector. SO4Pool_Osmoles) annotation (Line(
            points={{-47.8,-4},{13.1,-4},{13.1,82},{-90,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));
        connect(gain1.u, SO4Pool.SoluteMass) annotation (Line(
            points={{-52.4,-4},{-54,-4},{-54,16.2}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(Bladder.q_out, bladderVoid.q_in) annotation (Line(
            points={{60,24},{50,24},{50,-12},{66,-12}},
            color={200,0,0},
            thickness=1,
            smooth=Smooth.None));
        connect(bladderVoid.solventFlow, busConnector. BladderVoidFlow) annotation (Line(
            points={{72,-8.4},{72,82},{-90,82}},
            color={0,0,127},
            smooth=Smooth.None), Text(
       string="%second",
       index=1,
       extent={{3,1},{3,1}}));

      end Sulphate2;
    end Sulphate;

    package NH4 "Body Amonium Distribution"

      model Amonium2
        extends Library.Interfaces.BaseModel;
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}),       graphics), Icon(coordinateSystem(
                preserveAspectRatio=true, extent={{-100,-100},{100,100}}),
              graphics={Bitmap(extent={{-100,100},{100,-100}}, fileName=
                    "icons/NH4.jpg"), Text(
                extent={{-112,-102},{108,-128}},
                lineColor={0,0,255},
                textString="%name")}),
          Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
<tr>
<td>References:</td>
<td>Tom Coleman: QHP 2008 beta 3, University of Mississippi Medical Center</td>
</tr>
</table>
</html>"));
        Library.Factors.SplineValue AcuteEffect(data={{7.00,2.0,0},{7.45,1.0,-3.0},
              {7.80,0.0,0}})
          annotation (Placement(transformation(extent={{-60,52},{-40,72}})));
        Library.Factors.SplineDelayByDay ChronicEffect(Tau=3, data={{7.00,3.0,0},
              {7.45,1.0,-4.0},{7.80,0.0,0}})
          annotation (Placement(transformation(extent={{-60,42},{-40,62}})));
        Library.Factors.SplineValue PhOnFlux(data={{7.00,1.0,0},{7.45,0.6,-2.0},
              {7.80,0.0,0}})
          annotation (Placement(transformation(extent={{-60,26},{-40,46}})));
        Library.Blocks.ElectrolytesFlowConstant electrolytesFlowConstant(k=0.04)
          annotation (Placement(transformation(extent={{-68,74},{-56,86}})));
        Library.Interfaces.BusConnector busConnector
          annotation (Placement(transformation(extent={{-98,42},{-86,54}}),
              iconTransformation(extent={{62,62},{100,100}})));
      equation

        connect(AcuteEffect.y, ChronicEffect.yBase) annotation (Line(
            points={{-50,60},{-50,54}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(ChronicEffect.y, PhOnFlux.yBase) annotation (Line(
            points={{-50,50},{-50,38}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(electrolytesFlowConstant.y, AcuteEffect.yBase) annotation (Line(
            points={{-55.4,80},{-50,80},{-50,64}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(busConnector.Artys_pH, AcuteEffect.u) annotation (Line(
            points={{-92,48},{-76,48},{-76,62},{-59.8,62}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
        connect(PhOnFlux.y, busConnector.CD_NH4_Outflow) annotation (Line(
            points={{-50,34},{-50,26},{-92,26},{-92,48}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,-3},{6,-3}}));
        connect(busConnector.Artys_pH, ChronicEffect.u) annotation (Line(
            points={{-92,48},{-76,48},{-76,52},{-59.8,52}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
        connect(busConnector.Artys_pH, PhOnFlux.u) annotation (Line(
            points={{-92,48},{-76,48},{-76,36},{-59.8,36}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
      end Amonium2;
    end NH4;
    annotation (Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
<tr>
<td>References:</td>
<td>Tom Coleman: QHP 2008 beta 3, University of Mississippi Medical Center</td>
</tr>
</table>
</html>"));

    package setup

    model ElectrolytesConstInputs2

    Library.Interfaces.BusConnector busConnector
        annotation (Placement(transformation(extent={{26,-6},{40,8}}),
             iconTransformation(extent={{-40,-20},{0,20}})));
    Library.Blocks.Constant BladderVoidFlow(k=0)
    annotation (Placement(transformation(extent={{-30,-98},{-24,-92}})));
    Library.Blocks.Constant A2Pool_Log10Conc(k=1.29916)
    annotation (Placement(transformation(extent={{-32,-88},{-26,-82}})));
    Library.Blocks.Constant AldoPool_Aldo(k=0.290854848569316)
    annotation (Placement(transformation(extent={{-30,-78},{-24,-72}})));
    Library.Blocks.Constant BladderVolume_Mass(k=629.260404013417)
    annotation (Placement(transformation(extent={{-30,-68},{-24,-62}})));
    Library.Blocks.Constant Artys_pH(k=7.38644600458198)
    annotation (Placement(transformation(extent={{-30,-58},{-24,-52}})));
    Library.Blocks.Constant CD_KA_Outflow(k=6.08968322729714e-005)
    annotation (Placement(transformation(extent={{-30,-48},{-24,-42}})));
    Library.Blocks.Constant CO2Veins_cHCO3(k=25.7071728935027)
    annotation (Placement(transformation(extent={{-30,-38},{-24,-32}})));
    Library.Blocks.Constant CellH2O_Vol(k=27335.8967957385)
    annotation (Placement(transformation(extent={{-30,-28},{-24,-22}})));
    Library.Blocks.Constant ECFV_Vol(k=15491.3023234116)
    annotation (Placement(transformation(extent={{-30,-18},{-24,-12}})));
    Library.Blocks.Constant GILumenVolume_Mass(k=959.290660950713)
    annotation (Placement(transformation(extent={{-30,-8},{-24,-2}})));
    Library.Blocks.Constant GlomerulusFiltrate_GFR(k=130.805)
    annotation (Placement(transformation(extent={{-30,2},{-24,8}})));
    Library.Blocks.Constant KAPool_Osmoles(k=2.10110505683432)
    annotation (Placement(transformation(extent={{-30,8},{-24,14}})));
    Library.Blocks.Constant KAPool_conc(k=1.3839925831359e-002)
    annotation (Placement(transformation(extent={{-30,14},{-24,20}})));
    Library.Blocks.Constant KidneyAlpha_PT_NA(k=1.)
    annotation (Placement(transformation(extent={{-30,20},{-24,26}})));
    Library.Blocks.Constant KidneyFunction_Effect(k=0.995580586980285)
    annotation (Placement(transformation(extent={{-30,26},{-24,32}})));
    Library.Blocks.Constant Kidney_NephronCount_Total_xNormal(k=1.)
    annotation (Placement(transformation(extent={{-30,32},{-24,38}})));
    Library.Blocks.Constant LacPool_Mass_mEq(k=18.2596543652006)
    annotation (Placement(transformation(extent={{78,-2},{72,4}})));
    Library.Blocks.Constant LacPool_Lac_mEq_per_litre(k=1.17870363536868)
    annotation (Placement(transformation(extent={{78,8},{72,14}})));
    Library.Blocks.Constant Medulla_Volume(k=31.)
    annotation (Placement(transformation(extent={{78,18},{72,24}})));
    Library.Blocks.Constant NephronANP_Log10Conc(k=1.25866025557014)
    annotation (Placement(transformation(extent={{78,28},{72,34}})));
    Library.Blocks.Constant NephronAldo_conc_in_nG_per_dl(k=9.9383249094754)
    annotation (Placement(transformation(extent={{78,38},{72,44}})));
    Library.Blocks.Constant NephroneIFP_Pressure(k=3.98695)
    annotation (Placement(transformation(extent={{78,48},{72,54}})));
    Library.Blocks.Constant VasaRecta_Outflow(k=21.7865579572364)
    annotation (Placement(transformation(extent={{78,58},{72,64}})));
    Library.Blocks.Constant liver_GlucoseToCellStorageFlow(k=0)
    annotation (Placement(transformation(extent={{78,68},{72,74}})));
    Library.Blocks.Constant skeletalMuscle_GlucoseToCellStorageFlow(k=0)
    annotation (Placement(transformation(extent={{78,78},{72,84}})));
    Library.Blocks.Constant skeletalMuscle_GlucoseToCellStorageFlow1(
                                                                    k=0)
    annotation (Placement(transformation(extent={{78,88},{72,94}})));
      Library.Blocks.Constant Constant14(k=0)
        annotation (Placement(transformation(extent={{-86,42},{-78,50}})));
      Library.Blocks.Constant Constant15(k=0)
        annotation (Placement(transformation(extent={{-86,50},{-78,58}})));
      Library.Blocks.Constant Constant16(k=0)
        annotation (Placement(transformation(extent={{-86,58},{-78,66}})));
      Library.Blocks.Constant Constant17(k=0)
        annotation (Placement(transformation(extent={{-86,66},{-78,74}})));
      Library.Blocks.Constant Constant18(k=0)
        annotation (Placement(transformation(extent={{-86,74},{-78,82}})));
      Library.Blocks.Constant Constant19(k=.12)
        annotation (Placement(transformation(extent={{-86,82},{-78,90}})));
      Library.Blocks.Constant Constant20(k=0)
        annotation (Placement(transformation(extent={{-86,90},{-78,98}})));
      Library.Blocks.Constant Constant1(k=0) annotation (Placement(
            transformation(extent={{-94,-10},{-86,-2}})));
      Library.Blocks.Constant Constant2(k=0) annotation (Placement(
            transformation(extent={{-94,-24},{-86,-16}})));
    Library.Blocks.Constant Kidney_NephronCount_Filtering_xNormal(
                                                              k=1.)
    annotation (Placement(transformation(extent={{-30,38},{-24,44}})));
      Library.Blocks.Constant Constant21(k=0)
        annotation (Placement(transformation(extent={{-92,-92},{-84,-84}})));
      Library.Blocks.Constant Constant22(k=0)
        annotation (Placement(transformation(extent={{-92,-84},{-84,-76}})));
      Library.Blocks.Constant Constant23(k=0)
        annotation (Placement(transformation(extent={{-92,-76},{-84,-68}})));
      Library.Blocks.Constant Constant24(k=0)
        annotation (Placement(transformation(extent={{-92,-68},{-84,-60}})));
      Library.Blocks.Constant Constant25(k=0)
        annotation (Placement(transformation(extent={{-92,-60},{-84,-52}})));
      Library.Blocks.Constant Constant26(k=5.2e-002)
        annotation (Placement(transformation(extent={{-92,-52},{-84,-44}})));
      Library.Blocks.Constant Constant27(k=0)
        annotation (Placement(transformation(extent={{-92,-44},{-84,-36}})));
      Library.Blocks.Constant Constant28(k=0)
        annotation (Placement(transformation(extent={{80,-70},{72,-62}})));
      Library.Blocks.Constant Constant29(k=0)
        annotation (Placement(transformation(extent={{80,-62},{72,-54}})));
      Library.Blocks.Constant Constant30(k=0)
        annotation (Placement(transformation(extent={{80,-54},{72,-46}})));
      Library.Blocks.Constant Constant31(k=0)
        annotation (Placement(transformation(extent={{80,-46},{72,-38}})));
      Library.Blocks.Constant Constant32(k=0)
        annotation (Placement(transformation(extent={{80,-38},{72,-30}})));
      Library.Blocks.Constant Constant33(k=0.149511)
        annotation (Placement(transformation(extent={{80,-30},{72,-22}})));
      Library.Blocks.Constant Constant34(k=0)
        annotation (Placement(transformation(extent={{80,-22},{72,-14}})));
    Library.Blocks.Constant A2Pool_Log10Conc1(k=11.1951)
    annotation (Placement(transformation(extent={{-86,28},{-80,34}})));
    Library.Blocks.Constant A2Pool_Log10Conc2(k=2.5e-002)
    annotation (Placement(transformation(extent={{-86,22},{-80,28}})));
    Library.Blocks.Constant A2Pool_Log10Conc3(k=4.2e-002)
    annotation (Placement(transformation(extent={{-86,16},{-80,22}})));
    Library.Blocks.Constant A2Pool_Log10Conc4(k=14.9621)
    annotation (Placement(transformation(extent={{-88,4},{-82,10}})));
    equation

    connect(BladderVoidFlow.y, busConnector.BladderVoidFlow) annotation (Line(
     points={{-23.7,-95},{33,-95},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(A2Pool_Log10Conc.y, busConnector.A2Pool_Log10Conc) annotation (Line(
     points={{-25.7,-85},{33,-85},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(AldoPool_Aldo.y, busConnector.AldoPool_Aldo) annotation (Line(
     points={{-23.7,-75},{33,-75},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(BladderVolume_Mass.y, busConnector.BladderVolume_Mass) annotation (Line(
     points={{-23.7,-65},{33,-65},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(Artys_pH.y, busConnector.Artys_pH) annotation (Line(
     points={{-23.7,-55},{33,-55},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(CD_KA_Outflow.y, busConnector.CD_KA_Outflow) annotation (Line(
     points={{-23.7,-45},{33,-45},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(CO2Veins_cHCO3.y, busConnector.CO2Veins_cHCO3) annotation (Line(
     points={{-23.7,-35},{33,-35},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(CellH2O_Vol.y, busConnector.CellH2O_Vol) annotation (Line(
     points={{-23.7,-25},{33,-25},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(ECFV_Vol.y, busConnector.ECFV_Vol) annotation (Line(
     points={{-23.7,-15},{33,-15},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(GILumenVolume_Mass.y, busConnector.GILumenVolume_Mass) annotation (Line(
     points={{-23.7,-5},{33,-5},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(GlomerulusFiltrate_GFR.y, busConnector.GlomerulusFiltrate_GFR) annotation (Line(
     points={{-23.7,5},{33,5},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(KAPool_Osmoles.y, busConnector.KAPool_Osmoles) annotation (Line(
     points={{-23.7,11},{33,11},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(KAPool_conc.y, busConnector.KAPool_conc_per_liter) annotation (Line(
     points={{-23.7,17},{33,17},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(KidneyAlpha_PT_NA.y, busConnector.KidneyAlpha_PT_NA) annotation (Line(
     points={{-23.7,23},{33,23},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(KidneyFunction_Effect.y, busConnector.KidneyFunctionEffect) annotation (Line(
     points={{-23.7,29},{33,29},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(Kidney_NephronCount_Total_xNormal.y, busConnector.Kidney_NephronCount_Total_xNormal) annotation (Line(
     points={{-23.7,35},{33,35},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(LacPool_Mass_mEq.y, busConnector.LacPool_Mass_mEq) annotation (Line(
     points={{71.7,1},{52.35,1},{52.35,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(LacPool_Lac_mEq_per_litre.y, busConnector.LacPool_Lac_mEq_per_litre) annotation (Line(
     points={{71.7,11},{33,11},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(Medulla_Volume.y, busConnector.Medulla_Volume) annotation (Line(
     points={{71.7,21},{33,21},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(NephronANP_Log10Conc.y, busConnector.NephronANP_Log10Conc) annotation (Line(
     points={{71.7,31},{33,31},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(NephronAldo_conc_in_nG_per_dl.y, busConnector.NephronAldo_conc_in_nG_per_dl) annotation (Line(
     points={{71.7,41},{33,41},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(NephroneIFP_Pressure.y, busConnector.NephronIFP_Pressure) annotation (Line(
     points={{71.7,51},{32,52},{32,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(VasaRecta_Outflow.y, busConnector.VasaRecta_Outflow) annotation (Line(
     points={{71.7,61},{33,61},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(liver_GlucoseToCellStorageFlow.y, busConnector.liver_GlucoseToCellStorageFlow) annotation (Line(
     points={{71.7,71},{33,71},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
    connect(skeletalMuscle_GlucoseToCellStorageFlow.y, busConnector.skeletalMuscle_GlucoseToCellStorageFlow) annotation (Line(
     points={{71.7,81},{33,81},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));

      annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}),
                             graphics));
      connect(skeletalMuscle_GlucoseToCellStorageFlow1.y, busConnector.respiratoryMuscle_GlucoseToCellStorageFlow)
        annotation (Line(
          points={{71.7,91},{33,91},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(Constant14.y,busConnector.IVDrip_NaRate) annotation (Line(
          points={{-77.6,46},{33,46},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant15.y,busConnector. Transfusion_NaRate) annotation (Line(
          points={{-77.6,54},{33,54},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant16.y,busConnector. SweatDuct_NaRate) annotation (Line(
          points={{-77.6,62},{33,62},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant17.y,busConnector. Hemorrhage_NaRate) annotation (Line(
          points={{-77.6,70},{33,70},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant18.y,busConnector. DialyzerActivity_Na_Flux) annotation (
          Line(
          points={{-77.6,78},{33,78},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant19.y,busConnector. DietIntakeElectrolytes_Na) annotation (
          Line(
          points={{-77.6,86},{33,86},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant20.y,busConnector. GILumenDiarrhea_NaLoss) annotation (Line(
          points={{-77.6,94},{33,94},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant1.y,busConnector. FurosemidePool_Furosemide_conc)
        annotation (Line(
          points={{-85.6,-6},{-62,-6},{-62,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant2.y,busConnector. ThiazidePool_Thiazide_conc) annotation (
          Line(
          points={{-85.6,-20},{-62,-20},{-62,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Kidney_NephronCount_Filtering_xNormal.y, busConnector.Kidney_NephronCount_Filtering_xNormal)
                                                                                                 annotation (Line(
     points={{-23.7,41},{33,41},{33,1}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(Constant21.y,busConnector. IVDrip_KRate) annotation (Line(
          points={{-83.6,-88},{-58,-88},{-58,-40},{34,-40},{34,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant22.y,busConnector. Transfusion_KRate) annotation (Line(
          points={{-83.6,-80},{-58,-80},{-58,-40},{34,-40},{34,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant23.y,busConnector. SweatDuct_KRate) annotation (Line(
          points={{-83.6,-72},{-58,-72},{-58,-40},{34,-40},{34,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant24.y,busConnector. Hemorrhage_KRate) annotation (Line(
          points={{-83.6,-64},{-58,-64},{-58,-40},{34,-40},{34,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant25.y,busConnector. DialyzerActivity_K_Flux) annotation (
          Line(
          points={{-83.6,-56},{-58,-56},{-58,-40},{34,-40},{34,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant26.y,busConnector. DietIntakeElectrolytes_K) annotation (
          Line(
          points={{-83.6,-48},{-58,-48},{-58,-40},{34,-40},{34,1},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant27.y,busConnector. GILumenDiarrhea_KLoss) annotation (Line(
          points={{-83.6,-40},{33,-40},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant28.y,busConnector. IVDrip_ClRate) annotation (Line(
          points={{71.6,-66},{33,-66},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant29.y,busConnector. Transfusion_ClRate) annotation (Line(
          points={{71.6,-58},{33,-58},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant30.y,busConnector. SweatDuct_ClRate) annotation (Line(
          points={{71.6,-50},{33,-50},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant31.y,busConnector. Hemorrhage_ClRate) annotation (Line(
          points={{71.6,-42},{33,-42},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant32.y,busConnector. DialyzerActivity_Cl_Flux) annotation (
          Line(
          points={{71.6,-34},{33,-34},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant33.y,busConnector. DietIntakeElectrolytes_Cl) annotation (
          Line(
          points={{71.6,-26},{33,-26},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(Constant34.y,busConnector.GILumenVomitus_ClLoss) annotation (Line(
          points={{71.6,-18},{33,-18},{33,1}},
          color={0,0,127},
          smooth=Smooth.None));
        connect(A2Pool_Log10Conc1.y, busConnector.Aldo_conc_in_nG_per_dl)
          annotation (Line(
            points={{-79.7,31},{-56,31},{-56,1},{33,1}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
        connect(A2Pool_Log10Conc2.y, busConnector.DietIntakeElectrolytes_PO4)
          annotation (Line(
            points={{-79.7,25},{-56,25},{-56,1},{33,1}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
        connect(A2Pool_Log10Conc3.y, busConnector.DietIntakeElectrolytes_SO4)
          annotation (Line(
            points={{-79.7,19},{-56,19},{-56,1},{33,1}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
        connect(A2Pool_Log10Conc4.y, busConnector.BloodIons_ProteinAnions)
          annotation (Line(
            points={{-81.7,7},{-56,7},{-56,1},{33,1}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
    end ElectrolytesConstInputs2;
    end setup;

    package test

      model T2
        Electrolytes2 electrolytes(sodium(Medulla(initialSoluteMass=20.2451)))
          annotation (Placement(transformation(extent={{-16,-2},{4,18}})));
        setup.ElectrolytesConstInputs2 electrolytesConstInputs
          annotation (Placement(transformation(extent={{-70,-2},{-50,18}})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                  -100},{100,100}}),        graphics));
      equation
        connect(electrolytesConstInputs.busConnector, electrolytes.busConnector)
          annotation (Line(
            points={{-62,8},{-40,8},{-40,12},{-16,12}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None));
      end T2;

      model BusOMC
        BusSources busSources
          annotation (Placement(transformation(extent={{-64,10},{-44,30}})));
        BusConsumeGroup busConsumeGroup
          annotation (Placement(transformation(extent={{-16,10},{4,30}})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent=
                  {{-100,-100},{100,100}}), graphics));
      equation
        connect(busSources.busConnector, busConsumeGroup.busConnector)
          annotation (Line(
            points={{-53.8,21},{-15,21}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None));
      end BusOMC;

      model BusSources
        extends QHP.Library.Interfaces.BaseModel;

        Library.Interfaces.BusConnector busConnector
          annotation (Placement(transformation(extent={{-8,0},{12,20}})));
        Library.Blocks.OsmolarityConstant osmolarityConstant(k=3)
          annotation (Placement(transformation(extent={{-62,42},{-54,50}})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}),
                               graphics), Icon(graphics));
      equation
        connect(osmolarityConstant.y, busConnector.MyOmolarity) annotation (Line(
            points={{-53.6,46},{-20,46},{-20,10},{2,10}},
            color={0,0,127},
            smooth=Smooth.None), Text(
            string="%second",
            index=1,
            extent={{6,3},{6,3}}));
      end BusSources;

      model BusConsumeGroup
        Library.Interfaces.BusConnector busConnector
          annotation (Placement(transformation(extent={{-100,0},{-80,20}})));
        Modelica.Blocks.Continuous.Integrator integrator
          annotation (Placement(transformation(extent={{-24,0},{-4,20}})));
        annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={
                  {-100,-100},{100,100}}), graphics));
        Library.Factors.SplineValue splineValue(data={{0.7,0.8,0},{1.3,1.0,0.8},
              {1.6,1.2,0}})
          annotation (Placement(transformation(extent={{4,0},{24,20}})));
        Library.Blocks.Constant Constant(k=1.0)
          annotation (Placement(transformation(extent={{4,28},{12,36}})));
      equation
        connect(busConnector.MyOmolarity, integrator.u) annotation (Line(
            points={{-90,10},{-26,10}},
            color={0,0,255},
            thickness=0.5,
            smooth=Smooth.None), Text(
            string="%first",
            index=-1,
            extent={{-6,3},{-6,3}}));
        connect(Constant.y, splineValue.yBase) annotation (Line(
            points={{12.4,32},{14,32},{14,12}},
            color={0,0,127},
            smooth=Smooth.None));
        connect(integrator.y, splineValue.u) annotation (Line(
            points={{-3,10},{4.2,10}},
            color={0,0,127},
            smooth=Smooth.None));
      end BusConsumeGroup;
    end test;

    model Electrolytes2
      //extends QHP.Library.Interfaces.BaseModel;
      Sodium.Sodium2 sodium
        annotation (Placement(transformation(extent={{-80,60},{-60,80}})));
      Potassium.Potassium2 potassium
        annotation (Placement(transformation(extent={{-44,60},{-24,80}})));
      Chloride.Chloride2 chloride
        annotation (Placement(transformation(extent={{-10,60},{10,80}})));
      Phosphate.Phosphate2 phosphate
        annotation (Placement(transformation(extent={{-44,16},{-24,36}})));
      Sulphate.Sulphate2 sulphate
        annotation (Placement(transformation(extent={{-10,16},{10,36}})));
      Library.Interfaces.BusConnector busConnector
        annotation (Placement(transformation(extent={{82,36},{106,60}}),
            iconTransformation(extent={{-120,20},{-80,60}})));
      NH4.Amonium2 ammonia
        annotation (Placement(transformation(extent={{-80,16},{-60,36}})));
      annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                -100},{100,100}}), graphics),
                                        Icon(coordinateSystem(preserveAspectRatio=true,
              extent={{-100,-100},{100,100}}), graphics={Bitmap(extent={{-100,
                  100},{100,-100}}, fileName="icons/electrolytes.png"), Text(
              extent={{-122,-58},{120,-92}},
              lineColor={0,0,255},
              textString="%name")}),
        Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
<tr>
<td>References:</td>
<td>Tom Coleman: QHP 2008 beta 3, University of Mississippi Medical Center</td>
</tr><tr>
<td></td>
<td>Noriaki Ikeda: A model of overall regulation of body fluids (1979), Kitasato University</td>
</tr>
</table>
</html>"));
      ElectrolytesProperties electrolytesProperties
        annotation (Placement(transformation(extent={{68,12},{88,32}})));
    equation

      connect(sodium.busConnector, busConnector) annotation (Line(
          points={{-62,78},{-62,48},{94,48}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
      connect(busConnector, potassium.busConnector) annotation (Line(
          points={{94,48},{-26,48},{-26,78}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
      connect(busConnector, chloride.busConnector) annotation (Line(
          points={{94,48},{8.1,48},{8.1,78.1}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
      connect(ammonia.busConnector, busConnector) annotation (Line(
          points={{-61.9,34.1},{-61.9,48},{94,48}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
      connect(busConnector, electrolytesProperties.busConnector) annotation (
          Line(
          points={{94,48},{68,48},{68,26}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
      connect(sulphate.busConnector, busConnector) annotation (Line(
          points={{8,34},{8,48},{94,48}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
      connect(phosphate.busConnector, busConnector) annotation (Line(
          points={{-26,34},{-26,48},{94,48}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
    end Electrolytes2;

    model ElectrolytesProperties
      //extends QHP.Library.Interfaces.BaseModel;
      Library.Interfaces.BusConnector busConnector
        annotation (Placement(transformation(extent={{-104,88},{-86,106}}),
            iconTransformation(extent={{-120,20},{-80,60}})));
      Library.Blocks.OsmolarityConstant OsmCell_OtherCations(      k=692)
        annotation (Placement(transformation(extent={{4,-72},{24,-52}})));
      Library.Blocks.OsmolarityConstant CellElectrolytesMass(      k=1000)
        annotation (Placement(transformation(extent={{6,-96},{26,-76}})));
      Modelica.Blocks.Math.Add3 Cells(
        k1=2,
        k2=2,
        k3=-1) annotation (Placement(transformation(extent={{48,-68},{68,-48}})));
      Library.Blocks.OsmolarityConstant OsmECFV_OtherAnions(      k=373.0)
        annotation (Placement(transformation(extent={{-62,-12},{-42,8}})));
      Modelica.Blocks.Math.Sum ECF(nin=8)
        annotation (Placement(transformation(extent={{-24,2},{-4,22}})));
      Modelica.Blocks.Math.Sum BloodCations(nin=2)
        annotation (Placement(transformation(extent={{-46,54},{-26,74}})));
      Modelica.Blocks.Math.Feedback feedback1
        annotation (Placement(transformation(extent={{76,74},{96,54}})));
      Modelica.Blocks.Math.Feedback feedback2
        annotation (Placement(transformation(extent={{76,94},{96,74}})));
      Modelica.Blocks.Math.Add3 AnFlow
        annotation (Placement(transformation(extent={{-80,-72},{-60,-52}})));
      Modelica.Blocks.Math.Add3 CatFlow
        annotation (Placement(transformation(extent={{-80,-44},{-60,-24}})));
      Modelica.Blocks.Math.Feedback CollectingDuct_NetSumCats
        annotation (Placement(transformation(extent={{-44,-44},{-24,-24}})));
      Modelica.Blocks.Math.Sum StrongAnions(nin=5)
        annotation (Placement(transformation(extent={{-82,70},{-62,90}})));
      Modelica.Blocks.Math.Feedback StrongAnions2
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=0,
            origin={28,50})));
      Modelica.Blocks.Math.Add WeakAnions
        annotation (Placement(transformation(extent={{-10,-10},{10,10}},
            rotation=0,
            origin={-8,42})));
      annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                -100},{100,100}}),
                             graphics), Icon(coordinateSystem(preserveAspectRatio=true,
              extent={{-100,-100},{100,100}}), graphics={Bitmap(extent={{-100,
                  100},{100,-100}}, fileName="icons/electrolytes.png"), Text(
              extent={{-122,-58},{120,-92}},
              lineColor={0,0,255},
              textString="%name")}),
        Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
<tr>
<td>References:</td>
<td>Tom Coleman: QHP 2008 beta 3, University of Mississippi Medical Center</td>
</tr><tr>
<td></td>
<td>Noriaki Ikeda: A model of overall regulation of body fluids (1979), Kitasato University</td>
</tr>
</table>
</html>"));
    equation
      connect(busConnector.KCell_Mass, Cells.u1)  annotation (Line(
          points={{-95,97},{-96,97},{-96,-86},{-22,-86},{-22,-50},{46,-50}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(OsmCell_OtherCations.y, Cells.u2)  annotation (Line(
          points={{25,-62},{28,-62},{28,-58},{46,-58}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(CellElectrolytesMass.y, Cells.u3)  annotation (Line(
          points={{27,-86},{31.5,-86},{31.5,-66},{46,-66}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.NaPool_mass, ECF.u[1])  annotation (Line(
          points={{-95,97},{-96,98},{-96,12},{-26,12},{-26,10.25}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.KPool_mass, ECF.u[2])  annotation (Line(
          points={{-95,97},{-96,97},{-96,12},{-26,12},{-26,10.75}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(busConnector.ClPool_mass, ECF.u[3])  annotation (Line(
          points={{-95,97},{-95,12},{-26,12},{-26,11.25}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(OsmECFV_OtherAnions.y, ECF.u[8])  annotation (Line(
          points={{-41,-2},{-26,-2},{-26,13.75}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(busConnector.NaPool_conc_per_liter, BloodCations.u[1]) annotation (Line(
          points={{-95,97},{-96,64},{-48,64},{-48,63}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.KPool_conc_per_liter, BloodCations.u[2]) annotation (Line(
          points={{-95,97},{-96,97},{-96,66},{-48,66},{-48,65}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(feedback2.y, busConnector.BloodIons_StrongAnionsLessSO4) annotation (Line(
          points={{95,84},{100,84},{100,97},{-95,97}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.BloodIons_StrongAnionsLessPO4, feedback1.y) annotation (
          Line(
          points={{-95,97},{100,97},{100,64},{95,64}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.PO4Pool_conc_per_liter, feedback1.u2) annotation (Line(
          points={{-95,97},{100,97},{100,72},{86,72}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.SO4Pool_conc_per_liter, feedback2.u2) annotation (Line(
          points={{-95,97},{86,97},{86,92}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(CollectingDuct_NetSumCats.y, busConnector.CollectingDuct_NetSumCats)
        annotation (Line(
          points={{-25,-34},{100,-34},{100,96},{-96,96},{-96,97},{-95,97}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(CatFlow.y, CollectingDuct_NetSumCats.u1) annotation (Line(
          points={{-59,-34},{-42,-34}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(AnFlow.y, CollectingDuct_NetSumCats.u2) annotation (Line(
          points={{-59,-62},{-34,-62},{-34,-42}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.CD_NH4_Outflow, CatFlow.u1)
                                                 annotation (Line(
          points={{-95,97},{-96,97},{-96,-26},{-82,-26}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(busConnector.CD_PO4_Outflow, AnFlow.u2) annotation (Line(
          points={{-95,97},{-96,97},{-96,-62},{-82,-62}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(busConnector.CD_SO4_Outflow, AnFlow.u3) annotation (Line(
          points={{-95,97},{-96,97},{-96,-70},{-82,-70}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(BloodCations.y, StrongAnions2.u1)
                                              annotation (Line(
          points={{-25,64},{10,64},{10,50},{20,50}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.PO4Pool_conc_per_liter, StrongAnions.u[2])
        annotation (Line(
          points={{-95,97},{-96,97},{-96,79.2},{-84,79.2}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(busConnector.SO4Pool_conc_per_liter, StrongAnions.u[3])
        annotation (Line(
          points={{-95,97},{-96,80},{-84,80}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.ClPool_conc_per_liter, StrongAnions.u[5])
        annotation (Line(
          points={{-95,97},{-94,97},{-94,80},{-84,80},{-84,81.6}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(busConnector.PO4Pool_Osmoles, ECF.u[4]) annotation (Line(
          points={{-95,97},{-96,97},{-96,11.75},{-26,11.75}},
          color={0,0,127},
          smooth=Smooth.None));

      connect(busConnector.SO4Pool_Osmoles, ECF.u[5]) annotation (Line(
          points={{-95,97},{-96,97},{-96,12},{-26,12},{-26,12.25}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(busConnector.LacPool_Mass_mEq, ECF.u[6])                annotation (
          Line(
          points={{-95,97},{-96,97},{-96,12},{-26,12},{-26,12.75}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));

      connect(busConnector.LacPool_Lac_mEq_per_litre, StrongAnions.u[4])
            annotation (Line(
          points={{-95,97},{-95,80.8},{-84,80.8}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
      connect(busConnector.CO2Veins_cHCO3, WeakAnions.u2)
        annotation (Line(
          points={{-95,97},{-95,36},{-20,36}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None), Text(
          string="%first",
          index=-1,
          extent={{-6,3},{-6,3}}));
      connect(WeakAnions.y, StrongAnions2.u2)      annotation (Line(
          points={{3,42},{28,42}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(ECF.y, busConnector.OsmECFV_Electrolytes)
        annotation (Line(
          points={{-3,12},{14,12},{14,28},{-95,28},{-95,97}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(Cells.y, busConnector.OsmCell_Electrolytes)
        annotation (Line(
          points={{69,-58},{100,-58},{100,96},{-95,96},{-95,97}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(busConnector.KAPool_conc_per_liter, StrongAnions.u[1])
        annotation (Line(
          points={{-95,97},{-95,78.4},{-84,78.4}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
      connect(busConnector.CD_KA_Outflow, AnFlow.u1)                annotation (
         Line(
          points={{-95,97},{-96,52},{-96,-54},{-82,-54}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None), Text(
          string="%first",
          index=-1,
          extent={{-6,3},{-6,3}}));
      connect(busConnector.KAPool_Osmoles, ECF.u[7])                annotation (
         Line(
          points={{-95,97},{-96,97},{-96,12},{-26,12},{-26,13.25}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None));
      connect(BloodCations.y, busConnector.BloodIons_Cations)
        annotation (Line(
          points={{-25,64},{10,64},{10,96},{-95,96},{-95,97}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));

      connect(busConnector.CD_Na_Outflow, CatFlow.u2) annotation (Line(
          points={{-95,97},{-96,-34},{-82,-34}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None), Text(
          string="%first",
          index=-1,
          extent={{-6,3},{-6,3}}));
      connect(busConnector.CD_K_Outflow, CatFlow.u3) annotation (Line(
          points={{-95,97},{-96,-42},{-82,-42}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None), Text(
          string="%first",
          index=-1,
          extent={{-6,3},{-6,3}}));
      connect(BloodCations.y, busConnector.BloodCations) annotation (Line(
          points={{-25,64},{10,64},{10,97},{-95,97}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(busConnector.BloodIons_ProteinAnions, WeakAnions.u1) annotation (
          Line(
          points={{-95,97},{-95,48},{-20,48}},
          color={0,0,255},
          thickness=0.5,
          smooth=Smooth.None), Text(
          string="%first",
          index=-1,
          extent={{-6,3},{-6,3}}));
      connect(StrongAnions2.y, busConnector.BloodIons_StrongAnions) annotation (
         Line(
          points={{37,50},{100,50},{100,97},{-95,97}},
          color={0,0,127},
          smooth=Smooth.None), Text(
          string="%second",
          index=1,
          extent={{6,3},{6,3}}));
      connect(StrongAnions2.y, feedback2.u1) annotation (Line(
          points={{37,50},{74,50},{74,84},{78,84}},
          color={0,0,127},
          smooth=Smooth.None));
      connect(StrongAnions2.y, feedback1.u1) annotation (Line(
          points={{37,50},{74,50},{74,64},{78,64}},
          color={0,0,127},
          smooth=Smooth.None));
    end ElectrolytesProperties;
  end Electrolytes;
  annotation (uses(Modelica(version="3.1")), Documentation(revisions="<html>
<table>
<tr>
<td>Author:</td>
<td>Marek Matejak</td>
</tr>
<tr>
<td>Design:</td>
<td>Zuzana Rubaninska</td>
</tr>
<tr>
<td>Copyright:</td>
<td>In public domains</td>
</tr>
<tr>
<td>By:</td>
<td>Charles University, Prague</td>
</tr>
<tr>
<td>Date of:</td>
<td>2009</td>
</tr>
<tr>
<td>References:</td>
<td>Tom Coleman: QHP 2008 beta 3, University of Mississippi Medical Center</td>
</tr><tr>
<td></td>
<td>Siggaard Andersen: OSA (2005), University of Copenhagen</td>
</tr><tr>
<td></td>
<td>Noriaki Ikeda: A model of overall regulation of body fluids (1979), Kitasato University</td>
</tr>
</table>
</html>"));
end QHP;

model QHP_Electrolytes_test_T2
 extends QHP.Electrolytes.test.T2;
  annotation(experiment(
    StopTime=1,
    NumberOfIntervals=500,
    Tolerance=0.0001,
    Algorithm="dassl"));
end QHP_Electrolytes_test_T2;
