package ModelicaServices
  "ModelicaServices (Dymola implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
extends Modelica.Icons.Package;

package Machine

  final constant Real eps=1.e-15 "Biggest number such that 1.0 + eps = 1.0";

  final constant Real small=1.e-60
    "Smallest number such that small and -small are representable on the machine";

  final constant Real inf=1.e+60
    "Biggest Real number such that inf and -inf are representable on the machine";
  annotation (Documentation(info="<html>
<p>
Package in which processor specific constants are defined that are needed
by numerical algorithms. Typically these constants are not directly used,
but indirectly via the alias definition in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
</p>
</html>"));
end Machine;
annotation (
  Protection(access=Access.hide),
  preferredView="info",
  version="4.0.0",
  Dymola2(checkSum="3933384872:3320196239"),
  versionBuild=0,
  versionDate="2020-01-15",
  dateModified = "2020-01-15 08:44:41Z",
  uses(Modelica(version="4.0.0")),
  conversion(
    noneFromVersion="1.0",
    noneFromVersion="1.1",
    noneFromVersion="1.2",
    noneFromVersion="3.2.1",
 noneFromVersion="3.2.3"),
  Documentation(info="<html>
<p>
This package contains a set of functions and models to be used in the
Modelica Standard Library that requires a tool specific implementation.
These are:
</p>

<ul>
<li> <a href=\"modelica://ModelicaServices.Animation.Shape\">Animation.Shape</a>
     provides a 3-dim. visualization of elementary
     mechanical objects. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Animation.Surface\">Animation.Surface</a>
     provides a 3-dim. visualization of
     moveable parameterized surface. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Animation.Vector\">Animation.Vector</a>
     provides a 3-dim. visualization of a vector objects. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Vector\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Vector</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">ExternalReferences.loadResource</a>
     provides a function to return the absolute path name of an URI or a local file name. It is used in
<a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Machine\">Machine</a>
     provides a package of machine constants. It is used in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.</li>

<li> <a href=\"modelica://ModelicaServices.System.exit\">System.exit</a> provides a function to terminate the execution of the Modelica environment. It is used in <a href=\"modelica://Modelica.Utilities.System.exit\">Modelica.Utilities.System.exit</a> via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Types.SolverMethod\">Types.SolverMethod</a>
     provides a string defining the integration method to solve differential equations in
     a clocked discretized continuous-time partition (see Modelica 3.3 language specification).
     It is not yet used in the Modelica Standard Library, but in the Modelica_Synchronous library
     that provides convenience blocks for the clock operators of Modelica version &ge; 3.3.</li>
</ul>

<p>
This is the Dymola implementation.
</p>

<p>
Original version
<strong>Licensed by the Modelica Association under the 3-Clause BSD License</strong><br>
Copyright &copy; 2009-2020, Modelica Association and contributors.
</p>
<p>
<strong>Modifications licensed by Dassault Syst&egrave;mes, copyright &copy; 2009-2020.</strong>
</p>

</html>"));
end ModelicaServices;

package Modelica "Modelica Standard Library - Version 4.0.0"
extends Modelica.Icons.Package;

  package Blocks
  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;

    package Interfaces
    "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;

      connector RealInput = input Real "'input Real' as connector" annotation (
        defaultComponentName="u",
        Icon(graphics={
          Polygon(
            lineColor={0,0,127},
            fillColor={0,0,127},
            fillPattern=FillPattern.Solid,
            points={{-100.0,100.0},{100.0,0.0},{-100.0,-100.0}})},
          coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}},
            preserveAspectRatio=true,
            initialScale=0.2)),
        Diagram(
          coordinateSystem(preserveAspectRatio=true,
            initialScale=0.2,
            extent={{-100.0,-100.0},{100.0,100.0}}),
            graphics={
          Polygon(
            lineColor={0,0,127},
            fillColor={0,0,127},
            fillPattern=FillPattern.Solid,
            points={{0.0,50.0},{100.0,0.0},{0.0,-50.0},{0.0,50.0}}),
          Text(
            textColor={0,0,127},
            extent={{-10.0,60.0},{-10.0,85.0}},
            textString="%name")}),
        Documentation(info="<html>
<p>
Connector with one input signal of type Real.
</p>
</html>"));

      connector RealOutput = output Real "'output Real' as connector" annotation (
        defaultComponentName="y",
        Icon(
          coordinateSystem(preserveAspectRatio=true,
            extent={{-100.0,-100.0},{100.0,100.0}}),
            graphics={
          Polygon(
            lineColor={0,0,127},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid,
            points={{-100.0,100.0},{100.0,0.0},{-100.0,-100.0}})}),
        Diagram(
          coordinateSystem(preserveAspectRatio=true,
            extent={{-100.0,-100.0},{100.0,100.0}}),
            graphics={
          Polygon(
            lineColor={0,0,127},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid,
            points={{-100.0,50.0},{0.0,0.0},{-100.0,-50.0}}),
          Text(
            textColor={0,0,127},
            extent={{30.0,60.0},{30.0,110.0}},
            textString="%name")}),
        Documentation(info="<html>
<p>
Connector with one output signal of type Real.
</p>
</html>"));

      partial block SO "Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;

        RealOutput y "Connector of Real output signal" annotation (Placement(
              transformation(extent={{100,-10},{120,10}})));
        annotation (Documentation(info="<html>
<p>
Block has one continuous Real output signal.
</p>
</html>"));

      end SO;

      partial block SignalSource "Base class for continuous signal source"
        extends SO;
        parameter Real offset=0 "Offset of output signal y";
        parameter SI.Time startTime=0 "Output y = offset for time < startTime";
        annotation (Documentation(info="<html>
<p>
Basic block for Real sources of package Blocks.Sources.
This component has one continuous Real output signal y
and two parameters (offset, startTime) to shift the
generated signal.
</p>
</html>"));
      end SignalSource;
      annotation (Documentation(info="<html>
<p>
This package contains interface definitions for
<strong>continuous</strong> input/output blocks with Real,
Integer and Boolean signals. Furthermore, it contains
partial models for continuous and discrete blocks.
</p>

</html>",     revisions="<html>
<ul>
<li><em>June 28, 2019</em>
       by Thomas Beutlich:<br>
       Removed obsolete blocks.</li>
<li><em>Oct. 21, 2002</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and Christian Schweiger:<br>
       Added several new interfaces.</li>
<li><em>Oct. 24, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       RealInputSignal renamed to RealInput. RealOutputSignal renamed to
       output RealOutput. GraphBlock renamed to BlockIcon. SISOreal renamed to
       SISO. SOreal renamed to SO. I2SOreal renamed to M2SO.
       SignalGenerator renamed to SignalSource. Introduced the following
       new models: MIMO, MIMOs, SVcontrol, MVcontrol, DiscreteBlockIcon,
       DiscreteBlock, DiscreteSISO, DiscreteMIMO, DiscreteMIMOs,
       BooleanBlockIcon, BooleanSISO, BooleanSignalSource, MI2BooleanMOs.</li>
<li><em>June 30, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>"));
    end Interfaces;

    package Sources
    "Library of signal source blocks generating Real, Integer and Boolean signals"
      import Modelica.Blocks.Interfaces;
      extends Modelica.Icons.SourcesPackage;

      block Ramp "Generate ramp signal"
        parameter Real height=1 "Height of ramps"
          annotation(Dialog(groupImage="modelica://Modelica/Resources/Images/Blocks/Sources/Ramp.png"));
        parameter SI.Time duration(min=0.0, start=2)
          "Duration of ramp (= 0.0 gives a Step)";
        extends Interfaces.SignalSource;

      equation
        y = offset + (if time < startTime then 0 else if time < (startTime +
          duration) then (time - startTime)*height/duration else height);
        annotation (
          Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}}), graphics={
              Line(points={{-80,68},{-80,-80}}, color={192,192,192}),
              Polygon(
                points={{-80,90},{-88,68},{-72,68},{-80,90}},
                lineColor={192,192,192},
                fillColor={192,192,192},
                fillPattern=FillPattern.Solid),
              Line(points={{-90,-70},{82,-70}}, color={192,192,192}),
              Polygon(
                points={{90,-70},{68,-62},{68,-78},{90,-70}},
                lineColor={192,192,192},
                fillColor={192,192,192},
                fillPattern=FillPattern.Solid),
              Line(points={{-80,-70},{-40,-70},{31,38}}),
              Text(
                extent={{-150,-150},{150,-110}},
                textString="duration=%duration"),
              Line(points={{31,38},{86,38}})}),
          Documentation(info="<html>
<p>
The Real output y is a ramp signal:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Blocks/Sources/Ramp.png\"
     alt=\"Ramp.png\">
</p>

<p>
If parameter duration is set to 0.0, the limiting case of a Step signal is achieved.
</p>
</html>"));
      end Ramp;
      annotation (Documentation(info="<html>
<p>
This package contains <strong>source</strong> components, i.e., blocks which
have only output signals. These blocks are used as signal generators
for Real, Integer and Boolean signals.
</p>

<p>
All Real source signals (with the exception of the Constant source)
have at least the following two parameters:
</p>

<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
  <tr><td><strong>offset</strong></td>
      <td>Value which is added to the signal</td>
  </tr>
  <tr><td><strong>startTime</strong></td>
      <td>Start time of signal. For time &lt; startTime,
                the output y is set to offset.</td>
  </tr>
</table>

<p>
The <strong>offset</strong> parameter is especially useful in order to shift
the corresponding source, such that at initial time the system
is stationary. To determine the corresponding value of offset,
usually requires a trimming calculation.
</p>
</html>",     revisions="<html>
<ul>
<li><em>October 21, 2002</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and Christian Schweiger:<br>
       Integer sources added. Step, TimeTable and BooleanStep slightly changed.</li>
<li><em>Nov. 8, 1999</em>
       by <a href=\"mailto:christoph@clauss-it.com\">Christoph Clau&szlig;</a>,
       <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
       <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
       (nperiod=-1 is an infinite number of periods).</li>
<li><em>Oct. 31, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       <a href=\"mailto:christoph@clauss-it.com\">Christoph Clau&szlig;</a>,
       <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
       All sources vectorized. New sources: ExpSine, Trapezoid,
       BooleanConstant, BooleanStep, BooleanPulse, SampleTrigger.
       Improved documentation, especially detailed description of
       signals in diagram layer.</li>
<li><em>June 29, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>"));
    end Sources;

    package Icons "Icons for Blocks"
        extends Modelica.Icons.IconsPackage;

        partial block Block "Basic graphical layout of input/output block"

          annotation (
            Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                  100,100}}), graphics={Rectangle(
                extent={{-100,-100},{100,100}},
                lineColor={0,0,127},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid), Text(
                extent={{-150,150},{150,110}},
                textString="%name",
                textColor={0,0,255})}),
          Documentation(info="<html>
<p>
Block that has only the basic icon for an input/output
block (no declarations, no equations). Most blocks
of package Modelica.Blocks inherit directly or indirectly
from this block.
</p>
</html>"));

        end Block;
    end Icons;
  annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100.0,-100.0},{100.0,100.0}}), graphics={
        Rectangle(
          origin={0.0,35.1488},
          fillColor={255,255,255},
          extent={{-30.0,-20.1488},{30.0,20.1488}}),
        Rectangle(
          origin={0.0,-34.8512},
          fillColor={255,255,255},
          extent={{-30.0,-20.1488},{30.0,20.1488}}),
        Line(
          origin={-51.25,0.0},
          points={{21.25,-35.0},{-13.75,-35.0},{-13.75,35.0},{6.25,35.0}}),
        Polygon(
          origin={-40.0,35.0},
          pattern=LinePattern.None,
          fillPattern=FillPattern.Solid,
          points={{10.0,0.0},{-5.0,5.0},{-5.0,-5.0}}),
        Line(
          origin={51.25,0.0},
          points={{-21.25,35.0},{13.75,35.0},{13.75,-35.0},{-6.25,-35.0}}),
        Polygon(
          origin={40.0,-35.0},
          pattern=LinePattern.None,
          fillPattern=FillPattern.Solid,
          points={{-10.0,0.0},{5.0,5.0},{5.0,-5.0}})}), Documentation(info="<html>
<p>
This library contains input/output blocks to build up block diagrams.
</p>

<dl>
<dt><strong>Main Author:</strong></dt>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
    Oberpfaffenhofen<br>
    Postfach 1116<br>
    D-82230 Wessling<br>
    email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a><br></dd>
</dl>
<p>
Copyright &copy; 1998-2020, Modelica Association and contributors
</p>
</html>",   revisions="<html>
<ul>
<li><em>June 23, 2004</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Introduced new block connectors and adapted all blocks to the new connectors.
       Included subpackages Continuous, Discrete, Logical, Nonlinear from
       package ModelicaAdditions.Blocks.
       Included subpackage ModelicaAdditions.Table in Modelica.Blocks.Sources
       and in the new package Modelica.Blocks.Tables.
       Added new blocks to Blocks.Sources and Blocks.Logical.
       </li>
<li><em>October 21, 2002</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and Christian Schweiger:<br>
       New subpackage Examples, additional components.
       </li>
<li><em>June 20, 2000</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
       Michael Tiller:<br>
       Introduced a replaceable signal type into
       Blocks.Interfaces.RealInput/RealOutput:
<blockquote><pre>
replaceable type SignalType = Real
</pre></blockquote>
       in order that the type of the signal of an input/output block
       can be changed to a physical type, for example:
<blockquote><pre>
Sine sin1(outPort(redeclare type SignalType=Modelica.Units.SI.Torque))
</pre></blockquote>
      </li>
<li><em>Sept. 18, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Renamed to Blocks. New subpackages Math, Nonlinear.
       Additional components in subpackages Interfaces, Continuous
       and Sources.</li>
<li><em>June 30, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized a first version, based on an existing Dymola library
       of Dieter Moormann and Hilding Elmqvist.</li>
</ul>
</html>"));
  end Blocks;

  package Fluid
  "Library of 1-dim. thermo-fluid flow models using the Modelica.Media media description"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;
    import Cv = Modelica.Units.Conversions;

    package Examples "Demonstration of the usage of the library"
      extends Modelica.Icons.ExamplesPackage;

      package HeatExchanger "Demo of a heat exchanger model"
        extends Modelica.Icons.ExamplesPackage;

        model HeatExchangerSimulation "Simulation for the heat exchanger model"

        extends Modelica.Icons.Example;

        //replaceable package Medium = Modelica.Media.Water.ConstantPropertyLiquidWater;
        replaceable package Medium = Modelica.Media.Water.StandardWaterOnePhase;
        //package Medium = Modelica.Media.Incompressible.Examples.Essotherm650;
          Modelica.Fluid.Examples.HeatExchanger.BaseClasses.BasicHX HEX(
            c_wall=500,
            use_T_start=true,
            nNodes=20,
            m_flow_start_1=0.2,
            m_flow_start_2=0.2,
            k_wall=100,
            s_wall=0.005,
            crossArea_1=4.5e-4,
            crossArea_2=4.5e-4,
            perimeter_1=0.075,
            perimeter_2=0.075,
            rho_wall=900,
            redeclare package Medium_1 =
                Medium,
            redeclare package Medium_2 =
                Medium,
            modelStructure_1=Modelica.Fluid.Types.ModelStructure.av_b,
            modelStructure_2=Modelica.Fluid.Types.ModelStructure.a_vb,
            redeclare model HeatTransfer_1 =

              Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.LocalPipeFlowHeatTransfer
              (  alpha0=1000),
            length=20,
            area_h_1=0.075*20,
            area_h_2=0.075*20,
            redeclare model HeatTransfer_2 =

              Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.ConstantFlowHeatTransfer
              (  alpha0=2000),
            Twall_start=300,
            dT=10,
            T_start_1=304,
            T_start_2=300) annotation (Placement(transformation(extent={{
                    -26,-14},{34,46}})));

          Modelica.Fluid.Sources.Boundary_pT ambient2(nPorts=1,
            p=1e5,
            T=280,
            redeclare package Medium = Medium) annotation (Placement(
                transformation(extent={{82,-28},{62,-8}})));
          Modelica.Fluid.Sources.Boundary_pT ambient1(nPorts=1,
            p=1e5,
            T=300,
            redeclare package Medium = Medium) annotation (Placement(
                transformation(extent={{82,24},{62,44}})));
          Modelica.Fluid.Sources.MassFlowSource_T massFlowRate2(nPorts=1,
            m_flow=0.2,
            T=360,
            redeclare package Medium = Medium,
            use_m_flow_in=true,
            use_T_in=false,
            use_X_in=false)
                        annotation (Placement(transformation(extent={{-66,24},{-46,44}})));
          Modelica.Fluid.Sources.MassFlowSource_T massFlowRate1(nPorts=1,
            redeclare package Medium = Medium,
            m_flow=0.2,
            T=300) annotation (Placement(transformation(extent={{-66,-10},{-46,10}})));
          Modelica.Blocks.Sources.Ramp Ramp1(
            startTime=50,
            duration=5,
            height=0.4,
            offset=-0.2) annotation (Placement(transformation(extent={{-98,24},{-78,
                    44}})));
          inner Modelica.Fluid.System system(energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyStateInitial,
              use_eps_Re=true) annotation (Placement(transformation(extent=
                    {{60,70},{80,90}})));
        equation
          connect(massFlowRate1.ports[1], HEX.port_a1) annotation (Line(points={
                  {-46,0},{-40,0},{-40,15.4},{-29,15.4}}, color={0,127,255}));
          connect(HEX.port_b1, ambient1.ports[1]) annotation (Line(points={{37,
                  15.4},{48.5,15.4},{48.5,34},{62,34}}, color={0,127,255}));
          connect(Ramp1.y, massFlowRate2.m_flow_in) annotation (Line(points={{-77,34},
                  {-74,34},{-74,42},{-66,42}}, color={0,0,127}));
          connect(massFlowRate2.ports[1], HEX.port_b2)
                                                   annotation (Line(
              points={{-46,34},{-40,34},{-40,29.8},{-29,29.8}}, color={0,127,255}));
          connect(HEX.port_a2, ambient2.ports[1])
                                              annotation (Line(
              points={{37,2.2},{42,2},{50,2},{50,-18},{62,-18}}, color={0,127,255}));
          annotation (experiment(StopTime=200, Tolerance=
                  1e-005),
            Documentation(info="<html>
<p>The simulation start in steady state with counterflow operation. At time t = 50, the mass flow rate on the secondary circuit is changed to a negative value in 5 seconds. After a transient, the heat exchanger operates in co-current flow.</p>
<p><img src=\"modelica://Modelica/Resources/Images/Fluid/Examples/HeatExchanger/HeatExchanger.png\" alt=\"HeatExchanger.png\"/></p>
</html>"));
        end HeatExchangerSimulation;

        package BaseClasses "Additional models for heat exchangers"
          extends Modelica.Icons.BasesPackage;

          model BasicHX "Simple heat exchanger model"
            outer Modelica.Fluid.System system "System properties";
            //General
            parameter SI.Length length(min=0) "Length of flow path for both fluids";
            parameter Integer nNodes(min=1) = 2 "Spatial segmentation";
            parameter Modelica.Fluid.Types.ModelStructure modelStructure_1=Types.ModelStructure.av_vb
              "Determines whether flow or volume models are present at the ports"
              annotation(Evaluate=true, Dialog(tab="General",group="Fluid 1"));
            parameter Modelica.Fluid.Types.ModelStructure modelStructure_2=Types.ModelStructure.av_vb
              "Determines whether flow or volume models are present at the ports"
              annotation(Evaluate=true, Dialog(tab="General",group="Fluid 2"));
            replaceable package Medium_1 = Modelica.Media.Water.StandardWater constrainedby
            Modelica.Media.Interfaces.PartialMedium   "Fluid 1"
                                                              annotation(choicesAllMatching=true, Dialog(tab="General",group="Fluid 1"));
            replaceable package Medium_2 = Modelica.Media.Water.StandardWater constrainedby
            Modelica.Media.Interfaces.PartialMedium   "Fluid 2"
                                                              annotation(choicesAllMatching=true,Dialog(tab="General", group="Fluid 2"));
            parameter SI.Area crossArea_1 "Cross sectional area" annotation(Dialog(tab="General",group="Fluid 1"));
            parameter SI.Area crossArea_2 "Cross sectional area" annotation(Dialog(tab="General",group="Fluid 2"));
            parameter SI.Length perimeter_1 "Flow channel perimeter" annotation(Dialog(tab="General",group="Fluid 1"));
            parameter SI.Length perimeter_2 "Flow channel perimeter" annotation(Dialog(tab="General",group="Fluid 2"));
            final parameter Boolean use_HeatTransfer = true
              "= true to use the HeatTransfer_1/_2 model";

            // Heat transfer
            replaceable model HeatTransfer_1 =

              Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.IdealFlowHeatTransfer
              constrainedby
            Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.PartialFlowHeatTransfer
              "Heat transfer model" annotation(choicesAllMatching=true, Dialog(tab="General", group="Fluid 1", enable=use_HeatTransfer));

            replaceable model HeatTransfer_2 =

              Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.IdealFlowHeatTransfer
              constrainedby
            Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.PartialFlowHeatTransfer
              "Heat transfer model" annotation(choicesAllMatching=true, Dialog(tab="General", group="Fluid 2", enable=use_HeatTransfer));

            parameter SI.Area area_h_1 "Heat transfer area" annotation(Dialog(tab="General",group="Fluid 1"));
            parameter SI.Area area_h_2 "Heat transfer area" annotation(Dialog(tab="General",group="Fluid 2"));
           //Wall
            parameter SI.Length s_wall(min=0) "Wall thickness"
              annotation (Dialog(group="Wall properties"));
            parameter SI.ThermalConductivity k_wall
              "Thermal conductivity of wall material"
              annotation (Dialog(group="Wall properties"));
            parameter SI.SpecificHeatCapacity c_wall
              "Specific heat capacity of wall material"
              annotation(Dialog(tab="General", group="Wall properties"));
            parameter SI.Density rho_wall "Density of wall material"
              annotation(Dialog(tab="General", group="Wall properties"));
            final parameter SI.Area area_h=(area_h_1 + area_h_2)/2
              "Heat transfer area";
            final parameter SI.Mass m_wall=rho_wall*area_h*s_wall "Wall mass";

            // Assumptions
            parameter Boolean allowFlowReversal = system.allowFlowReversal
              "Allow flow reversal, false restricts to design direction (port_a -> port_b)"
              annotation(Dialog(tab="Assumptions"), Evaluate=true);
            parameter Modelica.Fluid.Types.Dynamics energyDynamics=system.energyDynamics
              "Formulation of energy balance"
              annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
            parameter Modelica.Fluid.Types.Dynamics massDynamics=system.massDynamics
              "Formulation of mass balance"
              annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
            parameter Modelica.Fluid.Types.Dynamics momentumDynamics=system.momentumDynamics
              "Formulation of momentum balance, if pressureLoss options available"
              annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));

            //Initialization pipe 1
            parameter SI.Temperature Twall_start "Start value of wall temperature"
                                                                                  annotation(Dialog(tab="Initialization", group="Wall"));
            parameter SI.TemperatureDifference dT "Start value for pipe_1.T - pipe_2.T"
              annotation (Dialog(tab="Initialization", group="Wall"));
            parameter Boolean use_T_start=true
              "Use T_start if true, otherwise h_start"
              annotation(Evaluate=true, Dialog(tab = "Initialization"));
            parameter Medium_1.AbsolutePressure p_a_start1=Medium_1.p_default
              "Start value of pressure"
              annotation(Dialog(tab = "Initialization", group = "Fluid 1"));
            parameter Medium_1.AbsolutePressure p_b_start1=Medium_1.p_default
              "Start value of pressure"
              annotation(Dialog(tab = "Initialization", group = "Fluid 1"));
            parameter Medium_1.Temperature T_start_1=if use_T_start then Medium_1.
                T_default else Medium_1.temperature_phX(
                  (p_a_start1 + p_b_start1)/2,
                  h_start_1,
                  X_start_1) "Start value of temperature"
              annotation(Evaluate=true, Dialog(tab = "Initialization", group = "Fluid 1", enable = use_T_start));
            parameter Medium_1.SpecificEnthalpy h_start_1=if use_T_start then Medium_1.specificEnthalpy_pTX(
                  (p_a_start1 + p_b_start1)/2,
                  T_start_1,
                  X_start_1) else Medium_1.h_default
              "Start value of specific enthalpy"
              annotation(Evaluate=true, Dialog(tab = "Initialization", group = "Fluid 1", enable = not use_T_start));
            parameter Medium_1.MassFraction X_start_1[Medium_1.nX]=Medium_1.X_default
              "Start value of mass fractions m_i/m"
              annotation (Dialog(tab="Initialization", group = "Fluid 1", enable=(Medium_1.nXi > 0)));
            parameter Medium_1.MassFlowRate m_flow_start_1 = system.m_flow_start
              "Start value of mass flow rate" annotation(Evaluate=true, Dialog(tab = "Initialization", group = "Fluid 1"));
            //Initialization pipe 2

            parameter Medium_2.AbsolutePressure p_a_start2=Medium_2.p_default
              "Start value of pressure"
              annotation(Dialog(tab = "Initialization", group = "Fluid 2"));
            parameter Medium_2.AbsolutePressure p_b_start2=Medium_2.p_default
              "Start value of pressure"
              annotation(Dialog(tab = "Initialization", group = "Fluid 2"));
            parameter Medium_2.Temperature T_start_2=if use_T_start then Medium_2.
                T_default else Medium_2.temperature_phX(
                  (p_a_start2 + p_b_start2)/2,
                  h_start_2,
                  X_start_2) "Start value of temperature"
              annotation(Evaluate=true, Dialog(tab = "Initialization", group = "Fluid 2", enable = use_T_start));
            parameter Medium_2.SpecificEnthalpy h_start_2=if use_T_start then Medium_2.specificEnthalpy_pTX(
                  (p_a_start2 + p_b_start2)/2,
                  T_start_2,
                  X_start_2) else Medium_2.h_default
              "Start value of specific enthalpy"
              annotation(Evaluate=true, Dialog(tab = "Initialization", group = "Fluid 2", enable = not use_T_start));
            parameter Medium_2.MassFraction X_start_2[Medium_2.nX]=Medium_2.X_default
              "Start value of mass fractions m_i/m"
              annotation (Dialog(tab="Initialization", group = "Fluid 2", enable=Medium_2.nXi>0));
            parameter Medium_2.MassFlowRate m_flow_start_2 = system.m_flow_start
              "Start value of mass flow rate" annotation(Evaluate=true, Dialog(tab = "Initialization", group = "Fluid 2"));

            //Pressure drop and heat transfer
            replaceable model FlowModel_1 =
                Modelica.Fluid.Pipes.BaseClasses.FlowModels.DetailedPipeFlow
              constrainedby
            Modelica.Fluid.Pipes.BaseClasses.FlowModels.PartialStaggeredFlowModel
              "Characteristic of wall friction" annotation(choicesAllMatching=true, Dialog(tab="General", group="Fluid 1"));
            replaceable model FlowModel_2 =
                Modelica.Fluid.Pipes.BaseClasses.FlowModels.DetailedPipeFlow
              constrainedby
            Modelica.Fluid.Pipes.BaseClasses.FlowModels.PartialStaggeredFlowModel
              "Characteristic of wall friction" annotation(choicesAllMatching=true, Dialog(tab="General", group="Fluid 2"));
            parameter Modelica.Fluid.Types.Roughness roughness_1=2.5e-5
              "Absolute roughness of pipe (default = smooth steel pipe)" annotation(Dialog(tab="General", group="Fluid 1"));
            parameter Modelica.Fluid.Types.Roughness roughness_2=2.5e-5
              "Absolute roughness of pipe (default = smooth steel pipe)" annotation(Dialog(tab="General", group="Fluid 2"));

            //Display variables
            SI.HeatFlowRate Q_flow_1 "Total heat flow rate of pipe 1";
            SI.HeatFlowRate Q_flow_2 "Total heat flow rate of pipe 2";

            BaseClasses.WallConstProps wall(
              rho_wall=rho_wall,
              c_wall=c_wall,
              T_start=Twall_start,
              k_wall=k_wall,
              dT=dT,
              s=s_wall,
              energyDynamics=energyDynamics,
              n=nNodes,
              area_h=area_h)
              annotation (Placement(transformation(extent={{-29,-23},{9,35}})));

            Pipes.DynamicPipe pipe_1(
              redeclare final package Medium = Medium_1,
              final isCircular=false,
              final diameter=0,
              final nNodes=nNodes,
              final allowFlowReversal=allowFlowReversal,
              final energyDynamics=energyDynamics,
              final massDynamics=massDynamics,
              final momentumDynamics=momentumDynamics,
              final length=length,
              final use_HeatTransfer=use_HeatTransfer,
              redeclare final model HeatTransfer = HeatTransfer_1,
              final use_T_start=use_T_start,
              final T_start=T_start_1,
              final h_start=h_start_1,
              final X_start=X_start_1,
              final m_flow_start=m_flow_start_1,
              final perimeter=perimeter_1,
              final crossArea=crossArea_1,
              final p_a_start=p_a_start1,
              final p_b_start=p_b_start1,
              final roughness=roughness_1,
              redeclare final model FlowModel = FlowModel_1,
              final modelStructure=modelStructure_1) annotation (Placement(transformation(extent={{-40,-80},
                      {20,-20}})));

            Pipes.DynamicPipe pipe_2(
              redeclare final package Medium = Medium_2,
              final nNodes=nNodes,
              final allowFlowReversal=allowFlowReversal,
              final energyDynamics=energyDynamics,
              final massDynamics=massDynamics,
              final momentumDynamics=momentumDynamics,
              final length=length,
              final isCircular=false,
              final diameter=0,
              final use_HeatTransfer=use_HeatTransfer,
              redeclare final model HeatTransfer = HeatTransfer_2,
              final use_T_start=use_T_start,
              final T_start=T_start_2,
              final h_start=h_start_2,
              final X_start=X_start_2,
              final m_flow_start=m_flow_start_2,
              final perimeter=perimeter_2,
              final crossArea=crossArea_2,
              final p_a_start=p_a_start2,
              final p_b_start=p_b_start2,
              final roughness=roughness_2,
              redeclare final model FlowModel = FlowModel_2,
              final modelStructure=modelStructure_2)
                        annotation (Placement(transformation(extent={{20,88},{-40,28}})));

            Modelica.Fluid.Interfaces.FluidPort_b port_b1(redeclare final
              package Medium =
                  Medium_1) annotation (Placement(transformation(extent={{100,-12},{120,
                      8}})));
            Modelica.Fluid.Interfaces.FluidPort_a port_a1(redeclare final
              package Medium =
                  Medium_1) annotation (Placement(transformation(extent={{-120,-12},{
                      -100,8}})));
            Modelica.Fluid.Interfaces.FluidPort_b port_b2(redeclare final
              package Medium =
                  Medium_2) annotation (Placement(transformation(extent={{-120,36},{
                      -100,56}})));
            Modelica.Fluid.Interfaces.FluidPort_a port_a2(redeclare final
              package Medium =
                  Medium_2) annotation (Placement(transformation(extent={{100,-56},{120,
                      -36}})));

          equation
            Q_flow_1 = sum(pipe_1.heatTransfer.Q_flows);
            Q_flow_2 = sum(pipe_2.heatTransfer.Q_flows);
            connect(pipe_2.port_b, port_b2) annotation (Line(
                points={{-40,58},{-76,58},{-76,46},{-110,46}},
                color={0,127,255},
                thickness=0.5));
            connect(pipe_1.port_b, port_b1) annotation (Line(
                points={{20,-50},{42,-50},{42,-2},{110,-2}},
                color={0,127,255},
                thickness=0.5));
            connect(pipe_1.port_a, port_a1) annotation (Line(
                points={{-40,-50},{-75.3,-50},{-75.3,-2},{-110,-2}},
                color={0,127,255},
                thickness=0.5));
            connect(pipe_2.port_a, port_a2) annotation (Line(
                points={{20,58},{65,58},{65,-46},{110,-46}},
                color={0,127,255},
                thickness=0.5));
            connect(wall.heatPort_b, pipe_1.heatPorts) annotation (Line(
                points={{-10,-8.5},{-10,-36.8},{-9.7,-36.8}}, color={191,0,0}));
            connect(pipe_2.heatPorts[nNodes:-1:1], wall.heatPort_a[1:nNodes])
              annotation (Line(
                points={{-10.3,44.8},{-10.3,31.7},{-10,31.7},{-10,20.5}}, color={127,0,0}));
            annotation (Icon(coordinateSystem(preserveAspectRatio=false,
                    extent={{-100,-100},{100,100}}), graphics={
                  Rectangle(
                    extent={{-100,-26},{100,-30}},
                    fillColor={95,95,95},
                    fillPattern=FillPattern.Forward),
                  Rectangle(
                    extent={{-100,30},{100,26}},
                    fillColor={95,95,95},
                    fillPattern=FillPattern.Forward),
                  Rectangle(
                    extent={{-100,60},{100,30}},
                    fillPattern=FillPattern.HorizontalCylinder,
                    fillColor={0,63,125}),
                  Rectangle(
                    extent={{-100,-30},{100,-60}},
                    fillPattern=FillPattern.HorizontalCylinder,
                    fillColor={0,63,125}),
                  Rectangle(
                    extent={{-100,26},{100,-26}},
                    fillPattern=FillPattern.HorizontalCylinder,
                    fillColor={0,128,255}),
                  Text(
                    extent={{-150,110},{150,70}},
                    textColor={0,0,255},
                    textString="%name"),
                  Line(
                    points={{30,-85},{-60,-85}},
                    color={0,128,255}),
                  Polygon(
                    points={{20,-70},{60,-85},{20,-100},{20,-70}},
                    lineColor={0,128,255},
                    fillColor={0,128,255},
                    fillPattern=FillPattern.Solid),
                  Line(
                    points={{30,77},{-60,77}},
                    color={0,128,255}),
                  Polygon(
                    points={{-50,92},{-90,77},{-50,62},{-50,92}},
                    lineColor={0,128,255},
                    fillColor={0,128,255},
                    fillPattern=FillPattern.Solid)}),
              Documentation(info="<html>
<p>Simple model of a heat exchanger consisting of two pipes and one wall in between.
For both fluids geometry parameters, such as heat transfer area and cross section as well as heat transfer and pressure drop correlations may be chosen.
The flow scheme may be concurrent or counterflow, defined by the respective flow directions of the fluids entering the component.
The design flow direction with positive m_flow variables is counterflow.</p>
</html>"));
          end BasicHX;

          model WallConstProps
            "Pipe wall with capacitance, assuming 1D heat conduction and constant material properties"
            parameter Integer n(min=1)=1
              "Segmentation perpendicular to heat conduction";
          //Geometry
            parameter SI.Length s "Wall thickness";
            parameter SI.Area area_h "Heat transfer area";
          //Material properties
            parameter SI.Density rho_wall "Density of wall material";
            parameter SI.SpecificHeatCapacity c_wall
              "Specific heat capacity of wall material";
            parameter SI.ThermalConductivity k_wall
              "Thermal conductivity of wall material";
            parameter SI.Mass[n] m=fill(rho_wall*area_h*s/n,n)
              "Distribution of wall mass";
          //Initialization
            outer Modelica.Fluid.System system;
            parameter Modelica.Fluid.Types.Dynamics energyDynamics=system.energyDynamics
              "Formulation of energy balance"
              annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
            parameter SI.Temperature T_start "Wall temperature start value";
            parameter SI.Temperature dT "Start value for port_b.T - port_a.T";
          //Temperatures
            SI.Temperature[n] Tb(each start=T_start+0.5*dT);
            SI.Temperature[n] Ta(each start=T_start-0.5*dT);
            SI.Temperature[n] T(start=ones(n)*T_start, each stateSelect=StateSelect.prefer)
              "Wall temperature";
            Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[n] heatPort_a
              "Thermal port"
              annotation (Placement(transformation(extent={{-20,40},{20,60}})));
            Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a[n] heatPort_b
              "Thermal port"
              annotation (Placement(transformation(extent={{-20,-40},{20,-60}})));

          initial equation
            if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
              der(T) = zeros(n);
            elseif energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
              T = ones(n)*T_start;
            end if;
          equation
            for i in 1:n loop
             assert(m[i]>0, "Wall has negative dimensions");
             if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
               0 = heatPort_a[i].Q_flow + heatPort_b[i].Q_flow;
             else
               c_wall*m[i]*der(T[i]) = heatPort_a[i].Q_flow + heatPort_b[i].Q_flow;
             end if;
             heatPort_a[i].Q_flow=2*k_wall/s*(Ta[i]-T[i])*area_h/n;
             heatPort_b[i].Q_flow=2*k_wall/s*(Tb[i]-T[i])*area_h/n;
            end for;
            Ta=heatPort_a.T;
            Tb=heatPort_b.T;
              annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                      -100},{100,100}}), graphics={Rectangle(
                    extent={{-100,40},{100,-40}},
                    fillColor={95,95,95},
                    fillPattern=FillPattern.Forward), Text(
                    extent={{-82,18},{76,-18}},
                    textString="%name")}),
                                      Documentation(revisions="<html>
<ul>
<li><em>04 Mar 2006</em>
    by Katrin Pr&ouml;l&szlig;:<br>
       Model added to the Fluid library</li>
</ul>
</html>",           info="<html>
Simple model of circular (or any other closed shape) wall to be used for pipe (or duct) models. Heat conduction is regarded one dimensional, capacitance is lumped at the arithmetic mean temperature. The spatial discretization (parameter <code>n</code>) is meant to correspond to a connected fluid model discretization.
</html>"));
          end WallConstProps;
        end BaseClasses;
      end HeatExchanger;
      annotation(preferredView="info");
    end Examples;

    model System
      "System properties and default values (ambient, flow direction, initialization)"

      package Medium = Modelica.Media.Interfaces.PartialMedium
        "Medium model for default start values"
          annotation (choicesAllMatching = true);
      parameter SI.AbsolutePressure p_ambient=101325
        "Default ambient pressure"
        annotation(Dialog(group="Environment"));
      parameter SI.Temperature T_ambient=293.15
        "Default ambient temperature"
        annotation(Dialog(group="Environment"));
      parameter SI.Acceleration g=Modelica.Constants.g_n
        "Constant gravity acceleration"
        annotation(Dialog(group="Environment"));

      // Assumptions
      parameter Boolean allowFlowReversal = true
        "= false to restrict to design flow direction (port_a -> port_b)"
        annotation(Dialog(tab="Assumptions"), Evaluate=true);
      parameter Modelica.Fluid.Types.Dynamics energyDynamics=
        Modelica.Fluid.Types.Dynamics.DynamicFreeInitial
        "Default formulation of energy balances"
        annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
      parameter Modelica.Fluid.Types.Dynamics massDynamics=
        energyDynamics "Default formulation of mass balances"
        annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
      final parameter Modelica.Fluid.Types.Dynamics substanceDynamics=
        massDynamics "Default formulation of substance balances"
        annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
      final parameter Modelica.Fluid.Types.Dynamics traceDynamics=
        massDynamics "Default formulation of trace substance balances"
        annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
      parameter Modelica.Fluid.Types.Dynamics momentumDynamics=
        Modelica.Fluid.Types.Dynamics.SteadyState
        "Default formulation of momentum balances, if options available"
        annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));

      // Initialization
      parameter SI.MassFlowRate m_flow_start = 0
        "Default start value for mass flow rates"
        annotation(Dialog(tab = "Initialization"));
      parameter SI.AbsolutePressure p_start = p_ambient
        "Default start value for pressures"
        annotation(Dialog(tab = "Initialization"));
      parameter SI.Temperature T_start = T_ambient
        "Default start value for temperatures"
        annotation(Dialog(tab = "Initialization"));
      // Advanced
      parameter Boolean use_eps_Re = false
        "= true to determine turbulent region automatically using Reynolds number"
        annotation(Evaluate=true, Dialog(tab = "Advanced"));
      parameter SI.MassFlowRate m_flow_nominal = if use_eps_Re then 1 else 1e2*m_flow_small
        "Default nominal mass flow rate"
        annotation(Dialog(tab="Advanced", enable = use_eps_Re));
      parameter Real eps_m_flow(min=0) = 1e-4
        "Regularization of zero flow for |m_flow| < eps_m_flow*m_flow_nominal"
        annotation(Dialog(tab = "Advanced", enable = use_eps_Re));
      parameter SI.AbsolutePressure dp_small(min=0) = 1
        "Default small pressure drop for regularization of laminar and zero flow"
        annotation(Dialog(tab="Advanced", group="Classic", enable = not use_eps_Re));
      parameter SI.MassFlowRate m_flow_small(min=0) = 1e-2
        "Default small mass flow rate for regularization of laminar and zero flow"
        annotation(Dialog(tab = "Advanced", group="Classic", enable = not use_eps_Re));
    initial equation
      //assert(use_eps_Re, "*** Using classic system.m_flow_small and system.dp_small."
      //       + " They do not distinguish between laminar flow and regularization of zero flow."
      //       + " Absolute small values are error prone for models with local nominal values."
      //       + " Moreover dp_small can generally be obtained automatically."
      //       + " Please update the model to new system.use_eps_Re = true  (see system, Advanced tab). ***",
      //       level=AssertionLevel.warning);
      annotation (
        defaultComponentName="system",
        defaultComponentPrefixes="inner",
        missingInnerMessage="
Your model is using an outer \"system\" component but
an inner \"system\" component is not defined.
For simulation drag Modelica.Fluid.System into your model
to specify system properties.",
        Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
                100}}), graphics={
            Rectangle(
              extent={{-100,100},{100,-100}},
              lineColor={0,0,255},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-150,150},{150,110}},
              textColor={0,0,255},
              textString="%name"),
            Line(points={{-86,-30},{82,-30}}),
            Line(points={{-82,-68},{-52,-30}}),
            Line(points={{-48,-68},{-18,-30}}),
            Line(points={{-14,-68},{16,-30}}),
            Line(points={{22,-68},{52,-30}}),
            Line(points={{74,84},{74,14}}),
            Polygon(
              points={{60,14},{88,14},{74,-18},{60,14}},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{16,20},{60,-18}},
              textString="g"),
            Text(
              extent={{-90,82},{74,50}},
              textString="defaults"),
            Line(
              points={{-82,14},{-42,-20},{2,30}},
              thickness=0.5),
            Ellipse(
              extent={{-10,40},{12,18}},
              pattern=LinePattern.None,
              fillColor={255,0,0},
              fillPattern=FillPattern.Solid)}),
        Documentation(info="<html>
<p>
 A system component is needed in each fluid model to provide system-wide settings, such as ambient conditions and overall modeling assumptions.
 The system settings are propagated to the fluid models using the inner/outer mechanism.
</p>
<p>
 A model should never directly use system parameters.
 Instead a local parameter should be declared, which uses the global setting as default.
 The only exceptions are:</p>
 <ul>
  <li>the gravity system.g,</li>
  <li>the global system.eps_m_flow, which is used to define a local m_flow_small for the local m_flow_nominal:
      <blockquote><pre>m_flow_small = system.eps_m_flow*m_flow_nominal</pre></blockquote>
  </li>
 </ul>
<p>
 The global system.m_flow_small and system.dp_small are classic parameters.
 They do not distinguish between laminar flow and regularization of zero flow.
 Absolute small values are error prone for models with local nominal values.
 Moreover dp_small can generally be obtained automatically.
 Consider using the new system.use_eps_Re = true (see Advanced tab).
</p>
</html>"));
    end System;

    package Pipes "Devices for conveying fluid"
        extends Modelica.Icons.VariantsPackage;

      model DynamicPipe "Dynamic pipe model with storage of mass and energy"

        import Modelica.Fluid.Types.ModelStructure;

        // extending PartialStraightPipe
        extends Modelica.Fluid.Pipes.BaseClasses.PartialStraightPipe(
          final port_a_exposesState = (modelStructure == ModelStructure.av_b) or (modelStructure == ModelStructure.av_vb),
          final port_b_exposesState = (modelStructure == ModelStructure.a_vb) or (modelStructure == ModelStructure.av_vb));

        // extending PartialTwoPortFlow
        extends BaseClasses.PartialTwoPortFlow(
          final lengths=fill(length/n, n),
          final crossAreas=fill(crossArea, n),
          final dimensions=fill(4*crossArea/perimeter, n),
          final roughnesses=fill(roughness, n),
          final dheights=height_ab*dxs);

        // Wall heat transfer
        parameter Boolean use_HeatTransfer = false
          "= true to use the HeatTransfer model"
            annotation (Dialog(tab="Assumptions", group="Heat transfer"));
        replaceable model HeatTransfer =
            Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.IdealFlowHeatTransfer
          constrainedby
        Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.PartialFlowHeatTransfer
          "Wall heat transfer"
            annotation (Dialog(tab="Assumptions", group="Heat transfer",enable=use_HeatTransfer),choicesAllMatching=true);
        Interfaces.HeatPorts_a[nNodes] heatPorts if use_HeatTransfer
          annotation (Placement(transformation(extent={{-10,45},{10,65}}), iconTransformation(extent={{-30,36},
                  {32,52}})));

        HeatTransfer heatTransfer(
          redeclare final package Medium = Medium,
          final n=n,
          final nParallel=nParallel,
          final surfaceAreas=perimeter*lengths,
          final lengths=lengths,
          final dimensions=dimensions,
          final roughnesses=roughnesses,
          final states=mediums.state,
          final vs = vs,
          final use_k = use_HeatTransfer) "Heat transfer model"
            annotation (Placement(transformation(extent={{-45,20},{-23,42}})));
        final parameter Real[n] dxs = lengths/sum(lengths) "Normalized lengths";
      equation
        Qb_flows = heatTransfer.Q_flows;
        // Wb_flow = v*A*dpdx + v*F_fric
        //         = v*A*dpdx + v*A*flowModel.dp_fg - v*A*dp_grav
        if n == 1 or useLumpedPressure then
          Wb_flows = dxs * ((vs*dxs)*(crossAreas*dxs)*((port_b.p - port_a.p) + sum(flowModel.dps_fg) - system.g*(dheights*mediums.d)))*nParallel;
        else
          if modelStructure == ModelStructure.av_vb or modelStructure == ModelStructure.av_b then
            Wb_flows[2:n-1] = {vs[i]*crossAreas[i]*((mediums[i+1].p - mediums[i-1].p)/2 + (flowModel.dps_fg[i-1]+flowModel.dps_fg[i])/2 - system.g*dheights[i]*mediums[i].d) for i in 2:n-1}*nParallel;
          else
            Wb_flows[2:n-1] = {vs[i]*crossAreas[i]*((mediums[i+1].p - mediums[i-1].p)/2 + (flowModel.dps_fg[i]+flowModel.dps_fg[i+1])/2 - system.g*dheights[i]*mediums[i].d) for i in 2:n-1}*nParallel;
          end if;
          if modelStructure == ModelStructure.av_vb then
            Wb_flows[1] = vs[1]*crossAreas[1]*((mediums[2].p - mediums[1].p)/2 + flowModel.dps_fg[1]/2 - system.g*dheights[1]*mediums[1].d)*nParallel;
            Wb_flows[n] = vs[n]*crossAreas[n]*((mediums[n].p - mediums[n-1].p)/2 + flowModel.dps_fg[n-1]/2 - system.g*dheights[n]*mediums[n].d)*nParallel;
          elseif modelStructure == ModelStructure.av_b then
            Wb_flows[1] = vs[1]*crossAreas[1]*((mediums[2].p - mediums[1].p)/2 + flowModel.dps_fg[1]/2 - system.g*dheights[1]*mediums[1].d)*nParallel;
            Wb_flows[n] = vs[n]*crossAreas[n]*((port_b.p - mediums[n-1].p)/1.5 + flowModel.dps_fg[n-1]/2+flowModel.dps_fg[n] - system.g*dheights[n]*mediums[n].d)*nParallel;
          elseif modelStructure == ModelStructure.a_vb then
            Wb_flows[1] = vs[1]*crossAreas[1]*((mediums[2].p - port_a.p)/1.5 + flowModel.dps_fg[1]+flowModel.dps_fg[2]/2 - system.g*dheights[1]*mediums[1].d)*nParallel;
            Wb_flows[n] = vs[n]*crossAreas[n]*((mediums[n].p - mediums[n-1].p)/2 + flowModel.dps_fg[n]/2 - system.g*dheights[n]*mediums[n].d)*nParallel;
          elseif modelStructure == ModelStructure.a_v_b then
            Wb_flows[1] = vs[1]*crossAreas[1]*((mediums[2].p - port_a.p)/1.5 + flowModel.dps_fg[1]+flowModel.dps_fg[2]/2 - system.g*dheights[1]*mediums[1].d)*nParallel;
            Wb_flows[n] = vs[n]*crossAreas[n]*((port_b.p - mediums[n-1].p)/1.5 + flowModel.dps_fg[n]/2+flowModel.dps_fg[n+1] - system.g*dheights[n]*mediums[n].d)*nParallel;
          else
            assert(false, "Unknown model structure");
          end if;
        end if;

        connect(heatPorts, heatTransfer.heatPorts)
          annotation (Line(points={{0,55},{0,54},{-34,54},{-34,38.7}}, color={191,0,0}));
        annotation (defaultComponentName="pipe",
      Documentation(info="<html>
<p>Model of a straight pipe with distributed mass, energy and momentum balances. It provides the complete balance equations for one-dimensional fluid flow as formulated in <a href=\"modelica://Modelica.Fluid.UsersGuide.ComponentDefinition.BalanceEquations\">UsersGuide.ComponentDefinition.BalanceEquations</a>.</p>
<p>This generic model offers a large number of combinations of possible parameter settings. In order to reduce model complexity, consider defining and/or using a tailored model for the application at hand, such as
<a href=\"modelica://Modelica.Fluid.Examples.HeatExchanger.HeatExchangerSimulation\">HeatExchanger</a>.</p>
<p>DynamicPipe treats the partial differential equations with the finite volume method and a staggered grid scheme for momentum balances. The pipe is split into nNodes equally spaced segments along the flow path. The default value is nNodes=2. This results in two lumped mass and energy balances and one lumped momentum balance across the dynamic pipe.</p>
<p>Note that this generally leads to high-index DAEs for pressure states if dynamic pipes are directly connected to each other, or generally to models with storage exposing a thermodynamic state through the port. This may not be valid if the dynamic pipe is connected to a model with non-differentiable pressure, like a Sources.Boundary_pT with prescribed jumping pressure. The <code><strong>modelStructure</strong></code> can be configured as appropriate in such situations, in order to place a momentum balance between a pressure state of the pipe and a non-differentiable boundary condition.</p>
<p>The default <code><strong>modelStructure</strong></code> is <code>av_vb</code> (see Advanced tab). The simplest possible alternative symmetric configuration, avoiding potential high-index DAEs at the cost of the potential introduction of nonlinear equation systems, is obtained with the setting <code>nNodes=1, modelStructure=a_v_b</code>. Depending on the configured model structure, the first and the last pipe segment, or the flow path length of the first and the last momentum balance, are of half size. See the documentation of the base class <a href=\"modelica://Modelica.Fluid.Pipes.BaseClasses.PartialTwoPortFlow\">Pipes.BaseClasses.PartialTwoPortFlow</a>, also covering asymmetric configurations.</p>
<p>The <code><strong>HeatTransfer</strong></code> component specifies the source term <code>Qb_flows</code> of the energy balance. The default component uses a constant coefficient for the heat transfer between the bulk flow and the segment boundaries exposed through the <code>heatPorts</code>. The <code>HeatTransfer</code> model is replaceable and can be exchanged with any model extended from <a href=\"modelica://Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.PartialFlowHeatTransfer\">BaseClasses.HeatTransfer.PartialFlowHeatTransfer</a>.</p>
<p>The intended use is for complex networks of pipes and other flow devices, like valves. See, e.g.,</p>
<ul>
<li><a href=\"modelica://Modelica.Fluid.Examples.BranchingDynamicPipes\">Examples.BranchingDynamicPipes</a>, or</li>
<li><a href=\"modelica://Modelica.Fluid.Examples.IncompressibleFluidNetwork\">Examples.IncompressibleFluidNetwork</a>.</li>
</ul>
</html>"),
      Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{100,100}}), graphics={
              Rectangle(
                extent={{-100,44},{100,-44}},
                fillPattern=FillPattern.HorizontalCylinder,
                fillColor={0,127,255}),
              Ellipse(
                extent={{-72,10},{-52,-10}},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{50,10},{70,-10}},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-48,15},{46,-20}},
                textString="%nNodes")}),
      Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{100,
                  100}}), graphics={
              Rectangle(
                extent={{-100,60},{100,50}},
                fillColor={255,255,255},
                fillPattern=FillPattern.Backward),
              Rectangle(
                extent={{-100,-50},{100,-60}},
                fillColor={255,255,255},
                fillPattern=FillPattern.Backward),
              Line(
                points={{100,45},{100,50}},
                arrow={Arrow.None,Arrow.Filled},
                pattern=LinePattern.Dot),
              Line(
                points={{0,45},{0,50}},
                arrow={Arrow.None,Arrow.Filled},
                pattern=LinePattern.Dot),
              Line(
                points={{100,-45},{100,-50}},
                arrow={Arrow.None,Arrow.Filled},
                pattern=LinePattern.Dot),
              Line(
                points={{0,-45},{0,-50}},
                arrow={Arrow.None,Arrow.Filled},
                pattern=LinePattern.Dot),
              Line(
                points={{-50,60},{-50,50}},
                pattern=LinePattern.Dot),
              Line(
                points={{50,60},{50,50}},
                pattern=LinePattern.Dot),
              Line(
                points={{0,-50},{0,-60}},
                pattern=LinePattern.Dot)}));
      end DynamicPipe;

      package BaseClasses
      "Base classes used in the Pipes package (only of interest to build new component models)"
        extends Modelica.Icons.BasesPackage;

        partial model PartialStraightPipe "Base class for straight pipe models"
          extends Modelica.Fluid.Interfaces.PartialTwoPort;

          // Geometry

          // Note: define nParallel as Real to support inverse calculations
          parameter Real nParallel(min=1)=1 "Number of identical parallel pipes"
            annotation(Dialog(group="Geometry"));
          parameter SI.Length length "Length"
            annotation(Dialog(tab="General", group="Geometry"));
          parameter Boolean isCircular=true
            "= true, if cross sectional area is circular"
            annotation (Evaluate, Dialog(tab="General", group="Geometry"));
          parameter SI.Diameter diameter "Diameter of circular pipe"
            annotation(Dialog(group="Geometry", enable=isCircular));
          parameter SI.Area crossArea=Modelica.Constants.pi*diameter*diameter/4
            "Inner cross section area"
            annotation(Dialog(tab="General", group="Geometry", enable=not isCircular));
          parameter SI.Length perimeter(min=0)=Modelica.Constants.pi*diameter
            "Inner perimeter"
            annotation(Dialog(tab="General", group="Geometry", enable=not isCircular));
          parameter Modelica.Fluid.Types.Roughness roughness=2.5e-5
            "Average height of surface asperities (default: smooth steel pipe)"
              annotation(Dialog(group="Geometry"));
          final parameter SI.Volume V=crossArea*length*nParallel "Volume size";

          // Static head
          parameter SI.Length height_ab=0 "Height(port_b) - Height(port_a)"
              annotation(Dialog(group="Static head"));

          // Pressure loss
          replaceable model FlowModel =
            Modelica.Fluid.Pipes.BaseClasses.FlowModels.DetailedPipeFlow
            constrainedby
          Modelica.Fluid.Pipes.BaseClasses.FlowModels.PartialStaggeredFlowModel
            "Wall friction, gravity, momentum flow"
              annotation(Dialog(group="Pressure loss"), choicesAllMatching=true);

        equation
          assert(length >= height_ab, "Parameter length must be greater or equal height_ab.");

          annotation (defaultComponentName="pipe",Icon(coordinateSystem(
                preserveAspectRatio=false,
                extent={{-100,-100},{100,100}}), graphics={Rectangle(
                  extent={{-100,40},{100,-40}},
                  fillPattern=FillPattern.Solid,
                  fillColor={95,95,95},
                  pattern=LinePattern.None), Rectangle(
                  extent={{-100,44},{100,-44}},
                  fillPattern=FillPattern.HorizontalCylinder,
                  fillColor={0,127,255})}), Documentation(info="<html>
<p>
Base class for one dimensional flow models. It specializes a PartialTwoPort with a parameter interface and icon graphics.
</p>
</html>"));
        end PartialStraightPipe;

        partial model PartialTwoPortFlow "Base class for distributed flow models"

          import Modelica.Fluid.Types.ModelStructure;

          // extending PartialTwoPort
          extends Modelica.Fluid.Interfaces.PartialTwoPort(
            final port_a_exposesState = (modelStructure == ModelStructure.av_b) or (modelStructure == ModelStructure.av_vb),
            final port_b_exposesState = (modelStructure == ModelStructure.a_vb) or (modelStructure == ModelStructure.av_vb));

          // distributed volume model
          extends Modelica.Fluid.Interfaces.PartialDistributedVolume(
            final n = nNodes,
            final fluidVolumes = {crossAreas[i]*lengths[i] for i in 1:n}*nParallel);

          // Geometry parameters
          parameter Real nParallel(min=1)=1
            "Number of identical parallel flow devices"
            annotation(Dialog(group="Geometry"));
          parameter SI.Length[n] lengths "Lengths of flow segments"
            annotation(Dialog(group="Geometry"));
          parameter SI.Area[n] crossAreas "Cross flow areas of flow segments"
            annotation(Dialog(group="Geometry"));
          parameter SI.Length[n] dimensions "Hydraulic diameters of flow segments"
            annotation(Dialog(group="Geometry"));
          parameter Modelica.Fluid.Types.Roughness[n] roughnesses
            "Average heights of surface asperities"
            annotation(Dialog(group="Geometry"));

          // Static head
          parameter SI.Length[n] dheights=zeros(n)
            "Differences in heights of flow segments"
              annotation(Dialog(group="Static head"), Evaluate=true);

          // Assumptions
          parameter Types.Dynamics momentumDynamics=system.momentumDynamics
            "Formulation of momentum balances"
            annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));

          // Initialization
          parameter Medium.MassFlowRate m_flow_start = system.m_flow_start
            "Start value for mass flow rate"
             annotation(Evaluate=true, Dialog(tab = "Initialization"));

          // Discretization
          parameter Integer nNodes(min=1)=2 "Number of discrete flow volumes"
            annotation(Dialog(tab="Advanced"),Evaluate=true);

          parameter Types.ModelStructure modelStructure=Types.ModelStructure.av_vb
            "Determines whether flow or volume models are present at the ports"
            annotation(Dialog(tab="Advanced"), Evaluate=true);

          parameter Boolean useLumpedPressure=false
            "= true to lump pressure states together"
            annotation(Dialog(tab="Advanced"),Evaluate=true);
          final parameter Integer nFM=if useLumpedPressure then nFMLumped else nFMDistributed
            "Number of flow models in flowModel";
          final parameter Integer nFMDistributed=if modelStructure==Types.ModelStructure.a_v_b then n+1 else if (modelStructure==Types.ModelStructure.a_vb or modelStructure==Types.ModelStructure.av_b) then n else n-1 "Number of distributed flow models";
          final parameter Integer nFMLumped=if modelStructure==Types.ModelStructure.a_v_b then 2 else 1 "Number of lumped flow models";
          final parameter Integer iLumped=integer(n/2)+1
            "Index of control volume with representative state if useLumpedPressure"
            annotation(Evaluate=true);

          // Advanced model options
          parameter Boolean useInnerPortProperties=false
            "= true to take port properties for flow models from internal control volumes"
            annotation(Dialog(tab="Advanced"),Evaluate=true);
          Medium.ThermodynamicState state_a
            "State defined by volume outside port_a";
          Medium.ThermodynamicState state_b
            "State defined by volume outside port_b";
          Medium.ThermodynamicState[nFM+1] statesFM
            "State vector for flowModel model";

          // Pressure loss model
          replaceable model FlowModel =
            Modelica.Fluid.Pipes.BaseClasses.FlowModels.DetailedPipeFlow
            constrainedby
          Modelica.Fluid.Pipes.BaseClasses.FlowModels.PartialStaggeredFlowModel
            "Wall friction, gravity, momentum flow"
              annotation(Dialog(group="Pressure loss"), choicesAllMatching=true);
          FlowModel flowModel(
                  redeclare final package Medium = Medium,
                  final n=nFM+1,
                  final states=statesFM,
                  final vs=vsFM,
                  final momentumDynamics=momentumDynamics,
                  final allowFlowReversal=allowFlowReversal,
                  final p_a_start=p_a_start,
                  final p_b_start=p_b_start,
                  final m_flow_start=m_flow_start,
                  final nParallel=nParallel,
                  final pathLengths=pathLengths,
                  final crossAreas=crossAreasFM,
                  final dimensions=dimensionsFM,
                  final roughnesses=roughnessesFM,
                  final dheights=dheightsFM,
                  final g=system.g) "Flow model"
             annotation (Placement(transformation(extent={{-77,-37},{75,-19}})));

          // Flow quantities
          Medium.MassFlowRate[n+1] m_flows(
             each min=if allowFlowReversal then -Modelica.Constants.inf else 0,
             each start=m_flow_start)
            "Mass flow rates of fluid across segment boundaries";
          Medium.MassFlowRate[n+1, Medium.nXi] mXi_flows
            "Independent mass flow rates across segment boundaries";
          Medium.MassFlowRate[n+1, Medium.nC] mC_flows
            "Trace substance mass flow rates across segment boundaries";
          Medium.EnthalpyFlowRate[n+1] H_flows
            "Enthalpy flow rates of fluid across segment boundaries";

          SI.Velocity[n] vs = {0.5*(m_flows[i] + m_flows[i+1])/mediums[i].d/crossAreas[i] for i in 1:n}/nParallel
            "Mean velocities in flow segments";

          // Model structure dependent flow geometry
      protected
          SI.Length[nFM] pathLengths "Lengths along flow path";
          SI.Length[nFM] dheightsFM "Differences in heights between flow segments";
          SI.Area[nFM+1] crossAreasFM "Cross flow areas of flow segments";
          SI.Velocity[nFM+1] vsFM "Mean velocities in flow segments";
          SI.Length[nFM+1] dimensionsFM "Hydraulic diameters of flow segments";
          Modelica.Fluid.Types.Roughness[nFM+1] roughnessesFM "Average heights of surface asperities";

        equation
          assert(nNodes > 1 or modelStructure <> ModelStructure.av_vb,
             "nNodes needs to be at least 2 for modelStructure av_vb, as flow model disappears otherwise!");
          // staggered grid discretization of geometry for flowModel, depending on modelStructure
          if useLumpedPressure then
            if modelStructure <> ModelStructure.a_v_b then
              pathLengths[1] = sum(lengths);
              dheightsFM[1] = sum(dheights);
              if n == 1 then
                crossAreasFM[1:2] = {crossAreas[1], crossAreas[1]};
                dimensionsFM[1:2] = {dimensions[1], dimensions[1]};
                roughnessesFM[1:2] = {roughnesses[1], roughnesses[1]};
              else // n > 1
                crossAreasFM[1:2] = {sum(crossAreas[1:iLumped-1])/(iLumped-1), sum(crossAreas[iLumped:n])/(n-iLumped+1)};
                dimensionsFM[1:2] = {sum(dimensions[1:iLumped-1])/(iLumped-1), sum(dimensions[iLumped:n])/(n-iLumped+1)};
                roughnessesFM[1:2] = {sum(roughnesses[1:iLumped-1])/(iLumped-1), sum(roughnesses[iLumped:n])/(n-iLumped+1)};
              end if;
            else
              if n == 1 then
                pathLengths[1:2] = {lengths[1]/2, lengths[1]/2};
                dheightsFM[1:2] = {dheights[1]/2, dheights[1]/2};
                crossAreasFM[1:3] = {crossAreas[1], crossAreas[1], crossAreas[1]};
                dimensionsFM[1:3] = {dimensions[1], dimensions[1], dimensions[1]};
                roughnessesFM[1:3] = {roughnesses[1], roughnesses[1], roughnesses[1]};
              else // n > 1
                pathLengths[1:2] = {sum(lengths[1:iLumped-1]), sum(lengths[iLumped:n])};
                dheightsFM[1:2] = {sum(dheights[1:iLumped-1]), sum(dheights[iLumped:n])};
                crossAreasFM[1:3] = {sum(crossAreas[1:iLumped-1])/(iLumped-1), sum(crossAreas)/n, sum(crossAreas[iLumped:n])/(n-iLumped+1)};
                dimensionsFM[1:3] = {sum(dimensions[1:iLumped-1])/(iLumped-1), sum(dimensions)/n, sum(dimensions[iLumped:n])/(n-iLumped+1)};
                roughnessesFM[1:3] = {sum(roughnesses[1:iLumped-1])/(iLumped-1), sum(roughnesses)/n, sum(roughnesses[iLumped:n])/(n-iLumped+1)};
              end if;
            end if;
          else
            if modelStructure == ModelStructure.av_vb then
              //nFM = n-1
              if n == 2 then
                pathLengths[1] = lengths[1] + lengths[2];
                dheightsFM[1] = dheights[1] + dheights[2];
              else
                pathLengths[1:n-1] = cat(1, {lengths[1] + 0.5*lengths[2]}, 0.5*(lengths[2:n-2] + lengths[3:n-1]), {0.5*lengths[n-1] + lengths[n]});
                dheightsFM[1:n-1] = cat(1, {dheights[1] + 0.5*dheights[2]}, 0.5*(dheights[2:n-2] + dheights[3:n-1]), {0.5*dheights[n-1] + dheights[n]});
              end if;
              crossAreasFM[1:n] = crossAreas;
              dimensionsFM[1:n] = dimensions;
              roughnessesFM[1:n] = roughnesses;
            elseif modelStructure == ModelStructure.av_b then
              //nFM = n
              pathLengths[1:n] = lengths;
              dheightsFM[1:n] = dheights;
              crossAreasFM[1:n+1] = cat(1, crossAreas[1:n], {crossAreas[n]});
              dimensionsFM[1:n+1] = cat(1, dimensions[1:n], {dimensions[n]});
              roughnessesFM[1:n+1] = cat(1, roughnesses[1:n], {roughnesses[n]});
            elseif modelStructure == ModelStructure.a_vb then
              //nFM = n
              pathLengths[1:n] = lengths;
              dheightsFM[1:n] = dheights;
              crossAreasFM[1:n+1] = cat(1, {crossAreas[1]}, crossAreas[1:n]);
              dimensionsFM[1:n+1] = cat(1, {dimensions[1]}, dimensions[1:n]);
              roughnessesFM[1:n+1] = cat(1, {roughnesses[1]}, roughnesses[1:n]);
            elseif modelStructure == ModelStructure.a_v_b then
              //nFM = n+1;
              pathLengths[1:n+1] = cat(1, {0.5*lengths[1]}, 0.5*(lengths[1:n-1] + lengths[2:n]), {0.5*lengths[n]});
              dheightsFM[1:n+1] = cat(1, {0.5*dheights[1]}, 0.5*(dheights[1:n-1] + dheights[2:n]), {0.5*dheights[n]});
              crossAreasFM[1:n+2] = cat(1, {crossAreas[1]}, crossAreas[1:n], {crossAreas[n]});
              dimensionsFM[1:n+2] = cat(1, {dimensions[1]}, dimensions[1:n], {dimensions[n]});
              roughnessesFM[1:n+2] = cat(1, {roughnesses[1]}, roughnesses[1:n], {roughnesses[n]});
            else
              assert(false, "Unknown model structure");
            end if;
          end if;

          // Source/sink terms for mass and energy balances
          for i in 1:n loop
            mb_flows[i] = m_flows[i] - m_flows[i + 1];
            mbXi_flows[i, :] = mXi_flows[i, :] - mXi_flows[i + 1, :];
            mbC_flows[i, :]  = mC_flows[i, :]  - mC_flows[i + 1, :];
            Hb_flows[i] = H_flows[i] - H_flows[i + 1];
          end for;

          // Distributed flow quantities, upwind discretization
          for i in 2:n loop
            H_flows[i] = semiLinear(m_flows[i], mediums[i - 1].h, mediums[i].h);
            mXi_flows[i, :] = semiLinear(m_flows[i], mediums[i - 1].Xi, mediums[i].Xi);
            mC_flows[i, :]  = semiLinear(m_flows[i], Cs[i - 1, :],         Cs[i, :]);
          end for;
          H_flows[1] = semiLinear(port_a.m_flow, inStream(port_a.h_outflow), mediums[1].h);
          H_flows[n + 1] = -semiLinear(port_b.m_flow, inStream(port_b.h_outflow), mediums[n].h);
          mXi_flows[1, :] = semiLinear(port_a.m_flow, inStream(port_a.Xi_outflow), mediums[1].Xi);
          mXi_flows[n + 1, :] = -semiLinear(port_b.m_flow, inStream(port_b.Xi_outflow), mediums[n].Xi);
          mC_flows[1, :] = semiLinear(port_a.m_flow, inStream(port_a.C_outflow), Cs[1, :]);
          mC_flows[n + 1, :] = -semiLinear(port_b.m_flow, inStream(port_b.C_outflow), Cs[n, :]);

          // Boundary conditions
          port_a.m_flow    = m_flows[1];
          port_b.m_flow    = -m_flows[n + 1];
          port_a.h_outflow = mediums[1].h;
          port_b.h_outflow = mediums[n].h;
          port_a.Xi_outflow = mediums[1].Xi;
          port_b.Xi_outflow = mediums[n].Xi;
          port_a.C_outflow = Cs[1, :];
          port_b.C_outflow = Cs[n, :];
          // The two equations below are not correct if C is stored in volumes.
          // C should be treated the same way as Xi.
          //port_a.C_outflow = inStream(port_b.C_outflow);
          //port_b.C_outflow = inStream(port_a.C_outflow);

          if useInnerPortProperties and n > 0 then
            state_a = Medium.setState_phX(port_a.p, mediums[1].h, mediums[1].Xi);
            state_b = Medium.setState_phX(port_b.p, mediums[n].h, mediums[n].Xi);
          else
            state_a = Medium.setState_phX(port_a.p, inStream(port_a.h_outflow), inStream(port_a.Xi_outflow));
            state_b = Medium.setState_phX(port_b.p, inStream(port_b.h_outflow), inStream(port_b.Xi_outflow));
          end if;

          // staggered grid discretization for flowModel, depending on modelStructure
          if useLumpedPressure then
            if modelStructure <> ModelStructure.av_vb then
              // all pressures are equal
              fill(mediums[1].p, n-1) = mediums[2:n].p;
            elseif n > 2 then
              // need two pressures
              fill(mediums[1].p, iLumped-2) = mediums[2:iLumped-1].p;
              fill(mediums[n].p, n-iLumped) = mediums[iLumped:n-1].p;
            end if;
            if modelStructure == ModelStructure.av_vb then
              port_a.p = mediums[1].p;
              statesFM[1] = mediums[1].state;
              m_flows[iLumped] = flowModel.m_flows[1];
              statesFM[2] = mediums[n].state;
              port_b.p = mediums[n].p;
              vsFM[1] = vs[1:iLumped-1]*lengths[1:iLumped-1]/sum(lengths[1:iLumped-1]);
              vsFM[2] = vs[iLumped:n]*lengths[iLumped:n]/sum(lengths[iLumped:n]);
            elseif modelStructure == ModelStructure.av_b then
              port_a.p = mediums[1].p;
              statesFM[1] = mediums[iLumped].state;
              statesFM[2] = state_b;
              m_flows[n+1] = flowModel.m_flows[1];
              vsFM[1] = vs*lengths/sum(lengths);
              vsFM[2] = m_flows[n+1]/Medium.density(state_b)/crossAreas[n]/nParallel;
            elseif modelStructure == ModelStructure.a_vb then
              m_flows[1] = flowModel.m_flows[1];
              statesFM[1] = state_a;
              statesFM[2] = mediums[iLumped].state;
              port_b.p = mediums[n].p;
              vsFM[1] = m_flows[1]/Medium.density(state_a)/crossAreas[1]/nParallel;
              vsFM[2] = vs*lengths/sum(lengths);
            elseif modelStructure == ModelStructure.a_v_b then
              m_flows[1] = flowModel.m_flows[1];
              statesFM[1] = state_a;
              statesFM[2] = mediums[iLumped].state;
              statesFM[3] = state_b;
              m_flows[n+1] = flowModel.m_flows[2];
              vsFM[1] = m_flows[1]/Medium.density(state_a)/crossAreas[1]/nParallel;
              vsFM[2] = vs*lengths/sum(lengths);
              vsFM[3] = m_flows[n+1]/Medium.density(state_b)/crossAreas[n]/nParallel;
            else
              assert(false, "Unknown model structure");
            end if;
          else
            if modelStructure == ModelStructure.av_vb then
              //nFM = n-1
              statesFM[1:n] = mediums[1:n].state;
              m_flows[2:n] = flowModel.m_flows[1:n-1];
              vsFM[1:n] = vs;
              port_a.p = mediums[1].p;
              port_b.p = mediums[n].p;
            elseif modelStructure == ModelStructure.av_b then
              //nFM = n
              statesFM[1:n] = mediums[1:n].state;
              statesFM[n+1] = state_b;
              m_flows[2:n+1] = flowModel.m_flows[1:n];
              vsFM[1:n] = vs;
              vsFM[n+1] = m_flows[n+1]/Medium.density(state_b)/crossAreas[n]/nParallel;
              port_a.p = mediums[1].p;
            elseif modelStructure == ModelStructure.a_vb then
              //nFM = n
              statesFM[1] = state_a;
              statesFM[2:n+1] = mediums[1:n].state;
              m_flows[1:n] = flowModel.m_flows[1:n];
              vsFM[1] = m_flows[1]/Medium.density(state_a)/crossAreas[1]/nParallel;
              vsFM[2:n+1] = vs;
              port_b.p = mediums[n].p;
            elseif modelStructure == ModelStructure.a_v_b then
              //nFM = n+1
              statesFM[1] = state_a;
              statesFM[2:n+1] = mediums[1:n].state;
              statesFM[n+2] = state_b;
              m_flows[1:n+1] = flowModel.m_flows[1:n+1];
              vsFM[1] = m_flows[1]/Medium.density(state_a)/crossAreas[1]/nParallel;
              vsFM[2:n+1] = vs;
              vsFM[n+2] = m_flows[n+1]/Medium.density(state_b)/crossAreas[n]/nParallel;
            else
              assert(false, "Unknown model structure");
            end if;
          end if;

          annotation (defaultComponentName="pipe",
        Documentation(info="<html>
<p>Base class for distributed flow models. The total volume is split into nNodes segments along the flow path.
The default value is nNodes=2.
</p>
<h4>Mass and Energy balances</h4>
<p>
The mass and energy balances are inherited from <a href=\"modelica://Modelica.Fluid.Interfaces.PartialDistributedVolume\">Interfaces.PartialDistributedVolume</a>.
One total mass and one energy balance is formed across each segment according to the finite volume approach.
Substance mass balances are added if the medium contains more than one component.
</p>
<p>
An extending model needs to define the geometry and the difference in heights between the flow segments (static head).
Moreover it needs to define two vectors of source terms for the distributed energy balance:
</p>
<ul>
<li><code><strong>Qb_flows[nNodes]</strong></code>, the heat flow source terms, e.g., conductive heat flows across segment boundaries, and</li>
<li><code><strong>Wb_flows[nNodes]</strong></code>, the work source terms.</li>
</ul>

<h4>Momentum balance</h4>
<p>
The momentum balance is determined by the <strong><code>FlowModel</code></strong> component, which can be replaced with any model extended from
<a href=\"modelica://Modelica.Fluid.Pipes.BaseClasses.FlowModels.PartialStaggeredFlowModel\">BaseClasses.FlowModels.PartialStaggeredFlowModel</a>.
The default setting is <a href=\"modelica://Modelica.Fluid.Pipes.BaseClasses.FlowModels.DetailedPipeFlow\">DetailedPipeFlow</a>.
</p>
<p>
This considers
</p>
<ul>
<li>pressure drop due to friction and other dissipative losses, and</li>
<li>gravity effects for non-horizontal devices.</li>
<li>variation of flow velocity along the flow path,
which occur due to changes in the cross sectional area or the fluid density, provided that <code>flowModel.use_Ib_flows</code> is true.</li>
</ul>

<h4>Model Structure</h4>
<p>
The momentum balances are formulated across the segment boundaries along the flow path according to the staggered grid approach.
The configurable <strong><code>modelStructure</code></strong> determines the formulation of the boundary conditions at <code>port_a</code> and <code>port_b</code>.
The options include (default: av_vb):
</p>
<ul>
<li><code>av_vb</code>: Symmetric setting with nNodes-1 momentum balances between nNodes flow segments.
    The ports <code>port_a</code> and <code>port_b</code> expose the first and the last thermodynamic state, respectively.
    Connecting two or more flow devices therefore may result in high-index DAEs for the pressures of connected flow segments.</li>
<li><code>a_v_b</code>: Alternative symmetric setting with nNodes+1 momentum balances across nNodes flow segments.
    Half momentum balances are placed between <code>port_a</code> and the first flow segment as well as between the last flow segment and <code>port_b</code>.
    Connecting two or more flow devices therefore results in algebraic pressures at the ports.
    The specification of good start values for the port pressures is essential for the solution of large nonlinear equation systems.</li>
<li><code>av_b</code>: Asymmetric setting with nNodes momentum balances, one between nth volume and <code>port_b</code>, potential pressure state at <code>port_a</code></li>
<li><code>a_vb</code>: Asymmetric setting with nNodes momentum balance, one between first volume and <code>port_a</code>, potential pressure state at <code>port_b</code></li>
</ul>
<p>
When connecting two components, e.g., two pipes, the momentum balance across the connection point reduces to
</p>
<blockquote><pre>pipe1.port_b.p = pipe2.port_a.p</pre></blockquote>
<p>
This is only true if the flow velocity remains the same on each side of the connection.
Consider using a fitting for any significant change in diameter or fluid density, if the resulting effects,
such as change in kinetic energy, cannot be neglected.
This also allows for taking into account friction losses with respect to the actual geometry of the connection point.
</p>
</html>",   revisions="<html>
<ul>
<li><em>5 Dec 2008</em>
    by Michael Wetter:<br>
       Modified mass balance for trace substances. With the new formulation, the trace substances masses <code>mC</code> are stored
       in the same way as the species <code>mXi</code>.</li>
<li><em>Dec 2008</em>
    by R&uuml;diger Franke:<br>
       Derived model from original DistributedPipe models
    <ul>
    <li>moved mass and energy balances to PartialDistributedVolume</li>
    <li>introduced replaceable pressure loss models</li>
    <li>combined all model structures and lumped pressure into one model</li>
    <li>new ModelStructure av_vb, replacing former avb</li>
    </ul></li>
<li><em>04 Mar 2006</em>
    by Katrin Pr&ouml;l&szlig;:<br>
       Model added to the Fluid library</li>
</ul>
</html>"),
        Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{100,
                    100}}), graphics={Ellipse(
                  extent={{-72,10},{-52,-10}},
                  fillPattern=FillPattern.Solid), Ellipse(
                  extent={{50,10},{70,-10}},
                  fillPattern=FillPattern.Solid)}),
        Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{
                    100,100}}), graphics={
                Polygon(
                  points={{-100,-50},{-100,50},{100,60},{100,-60},{-100,-50}},
                  fillColor={215,215,215},
                  fillPattern=FillPattern.Solid,
                  pattern=LinePattern.None),
                Polygon(
                  points={{-34,-53},{-34,53},{34,57},{34,-57},{-34,-53}},
                  fillColor={255,255,255},
                  fillPattern=FillPattern.Solid,
                  pattern=LinePattern.None),
                Line(
                  points={{-100,-50},{-100,50}},
                  arrow={Arrow.Filled,Arrow.Filled},
                  pattern=LinePattern.Dot),
                Text(
                  extent={{-99,36},{-69,30}},
                  textColor={0,0,255},
                  textString="crossAreas[1]"),
                Line(
                  points={{-100,70},{-34,70}},
                  arrow={Arrow.Filled,Arrow.Filled},
                  pattern=LinePattern.Dot),
                Text(
                  extent={{0,36},{40,30}},
                  textColor={0,0,255},
                  textString="crossAreas[2:n-1]"),
                Line(
                  points={{100,-60},{100,60}},
                  arrow={Arrow.Filled,Arrow.Filled},
                  pattern=LinePattern.Dot),
                Text(
                  extent={{100.5,36},{130.5,30}},
                  textColor={0,0,255},
                  textString="crossAreas[n]"),
                Line(
                  points={{-34,52},{-34,-53}},
                  pattern=LinePattern.Dash),
                Line(
                  points={{34,57},{34,-57}},
                  pattern=LinePattern.Dash),
                Line(
                  points={{34,70},{100,70}},
                  arrow={Arrow.Filled,Arrow.Filled},
                  pattern=LinePattern.Dot),
                Line(
                  points={{-34,70},{34,70}},
                  arrow={Arrow.Filled,Arrow.Filled},
                  pattern=LinePattern.Dot),
                Text(
                  extent={{-30,77},{30,71}},
                  textColor={0,0,255},
                  textString="lengths[2:n-1]"),
                Line(
                  points={{-100,-70},{0,-70}},
                  arrow={Arrow.None,Arrow.Filled}),
                Text(
                  extent={{-80,-63},{-20,-69}},
                  textColor={0,0,255},
                  textString="flowModel.dps_fg[1]"),
                Line(
                  points={{0,-70},{100,-70}},
                  arrow={Arrow.None,Arrow.Filled}),
                Text(
                  extent={{20.5,-63},{80,-69}},
                  textColor={0,0,255},
                  textString="flowModel.dps_fg[2:n-1]"),
                Line(
                  points={{-95,0},{-5,0}},
                  arrow={Arrow.None,Arrow.Filled}),
                Text(
                  extent={{-62,7},{-32,1}},
                  textColor={0,0,255},
                  textString="m_flows[2]"),
                Line(
                  points={{5,0},{95,0}},
                  arrow={Arrow.None,Arrow.Filled}),
                Text(
                  extent={{34,7},{64,1}},
                  textColor={0,0,255},
                  textString="m_flows[3:n]"),
                Line(
                  points={{-150,0},{-105,0}},
                  arrow={Arrow.None,Arrow.Filled}),
                Line(
                  points={{105,0},{150,0}},
                  arrow={Arrow.None,Arrow.Filled}),
                Text(
                  extent={{-140,7},{-110,1}},
                  textColor={0,0,255},
                  textString="m_flows[1]"),
                Text(
                  extent={{111,7},{141,1}},
                  textColor={0,0,255},
                  textString="m_flows[n+1]"),
                Text(
                  extent={{35,-92},{100,-98}},
                  textColor={0,0,255},
                  textString="(ModelStructure av_vb, n=3)"),
                Line(
                  points={{-100,-50},{-100,-86}},
                  pattern=LinePattern.Dot),
                Line(
                  points={{0,-55},{0,-86}},
                  pattern=LinePattern.Dot),
                Line(
                  points={{100,-60},{100,-86}},
                  pattern=LinePattern.Dot),
                Ellipse(
                  extent={{-5,5},{5,-5}},
                  pattern=LinePattern.None,
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{3,-4},{33,-10}},
                  textColor={0,0,255},
                  textString="states[2:n-1]"),
                Ellipse(
                  extent={{95,5},{105,-5}},
                  pattern=LinePattern.None,
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{104,-4},{124,-10}},
                  textColor={0,0,255},
                  textString="states[n]"),
                Ellipse(
                  extent={{-105,5},{-95,-5}},
                  pattern=LinePattern.None,
                  fillPattern=FillPattern.Solid),
                Text(
                  extent={{-96,-4},{-76,-10}},
                  textColor={0,0,255},
                  textString="states[1]"),
                Text(
                  extent={{-99.5,30},{-69.5,24}},
                  textColor={0,0,255},
                  textString="dimensions[1]"),
                Text(
                  extent={{-0.5,30},{40,24}},
                  textColor={0,0,255},
                  textString="dimensions[2:n-1]"),
                Text(
                  extent={{100.5,30},{130.5,24}},
                  textColor={0,0,255},
                  textString="dimensions[n]"),
                Line(
                  points={{-34,73},{-34,52}},
                  pattern=LinePattern.Dot),
                Line(
                  points={{34,73},{34,57}},
                  pattern=LinePattern.Dot),
                Line(
                  points={{-100,50},{100,60}},
                  thickness=0.5),
                Line(
                  points={{-100,-50},{100,-60}},
                  thickness=0.5),
                Line(
                  points={{-100,73},{-100,50}},
                  pattern=LinePattern.Dot),
                Line(
                  points={{100,73},{100,60}},
                  pattern=LinePattern.Dot),
                Line(
                  points={{0,-55},{0,55}},
                  arrow={Arrow.Filled,Arrow.Filled},
                  pattern=LinePattern.Dot),
                Line(
                  points={{-34,11},{34,11}},
                  arrow={Arrow.None,Arrow.Filled}),
                Text(
                  extent={{5,18},{25,12}},
                  textColor={0,0,255},
                  textString="vs[2:n-1]"),
                Text(
                  extent={{-72,18},{-62,12}},
                  textColor={0,0,255},
                  textString="vs[1]"),
                Line(
                  points={{-100,11},{-34,11}},
                  arrow={Arrow.None,Arrow.Filled}),
                Text(
                  extent={{63,18},{73,12}},
                  textColor={0,0,255},
                  textString="vs[n]"),
                Line(
                  points={{34,11},{100,11}},
                  arrow={Arrow.None,Arrow.Filled}),
                Text(
                  extent={{-80,-75},{-20,-81}},
                  textColor={0,0,255},
                  textString="flowModel.pathLengths[1]"),
                Line(
                  points={{-100,-82},{0,-82}},
                  arrow={Arrow.Filled,Arrow.Filled}),
                Line(
                  points={{0,-82},{100,-82}},
                  arrow={Arrow.Filled,Arrow.Filled}),
                Text(
                  extent={{15,-75},{85,-81}},
                  textColor={0,0,255},
                  textString="flowModel.pathLengths[2:n-1]"),
                Text(
                  extent={{-100,77},{-37,71}},
                  textColor={0,0,255},
                  textString="lengths[1]"),
                Text(
                  extent={{34,77},{100,71}},
                  textColor={0,0,255},
                  textString="lengths[n]")}));
        end PartialTwoPortFlow;

        package FlowModels
        "Flow models for pipes, including wall friction, static head and momentum flow"
          extends Modelica.Icons.Package;

              partial model PartialStaggeredFlowModel
          "Base class for momentum balances in flow models"

                //
                // Internal interface
                // (not exposed to GUI; needs to be hard coded when using this model
                //
                replaceable package Medium =
                  Modelica.Media.Interfaces.PartialMedium "Medium in the component"
                    annotation(Dialog(tab="Internal interface",enable=false));

                parameter Integer n=2 "Number of discrete flow volumes"
                  annotation(Dialog(tab="Internal interface",enable=false));

                // Inputs
                input Medium.ThermodynamicState[n] states
              "Thermodynamic states along design flow";
                input SI.Velocity[n] vs
              "Mean velocities of fluid flow";

                // Geometry parameters and inputs
                parameter Real nParallel
              "Number of identical parallel flow devices"
                   annotation(Dialog(tab="Internal interface",enable=false,group="Geometry"));

                input SI.Area[n] crossAreas
              "Cross flow areas at segment boundaries";
                input SI.Length[n] dimensions
              "Characteristic dimensions for fluid flow (diameters for pipe flow)";
                input Modelica.Fluid.Types.Roughness[n] roughnesses
              "Average height of surface asperities";

                // Static head
                input SI.Length[n-1] dheights
              "Height(states[2:n]) - Height(states[1:n-1])";

                parameter SI.Acceleration g=system.g
              "Constant gravity acceleration"
                  annotation(Dialog(tab="Internal interface",enable=false,group="Static head"));

                // Assumptions
                parameter Boolean allowFlowReversal=system.allowFlowReversal
            "= true, if flow reversal is enabled, otherwise restrict flow to design direction (states[1] -> states[n+1])"
                  annotation(Dialog(tab="Internal interface",enable=false,group="Assumptions"), Evaluate=true);
                parameter Modelica.Fluid.Types.Dynamics momentumDynamics=system.momentumDynamics
              "Formulation of momentum balance"
                  annotation(Dialog(tab="Internal interface",enable=false,group = "Assumptions"), Evaluate=true);

                // Initialization
                parameter Medium.MassFlowRate m_flow_start=system.m_flow_start
              "Start value of mass flow rates"
                  annotation(Dialog(tab="Internal interface",enable=false,group = "Initialization"));
                parameter Medium.AbsolutePressure p_a_start
              "Start value for p[1] at design inflow"
                  annotation(Dialog(tab="Internal interface",enable=false,group = "Initialization"));
                parameter Medium.AbsolutePressure p_b_start
              "Start value for p[n+1] at design outflow"
                  annotation(Dialog(tab="Internal interface",enable=false,group = "Initialization"));

                //
                // Implementation of momentum balance
                //
                extends Modelica.Fluid.Interfaces.PartialDistributedFlow(
                           final m = n-1);

                // Advanced parameters
                parameter Boolean useUpstreamScheme = true
              "= false to average upstream and downstream properties across flow segments"
                   annotation(Dialog(group="Advanced"), Evaluate=true);

                parameter Boolean use_Ib_flows = momentumDynamics <> Types.Dynamics.SteadyState
              "= true to consider differences in flow of momentum through boundaries"
                   annotation(Dialog(group="Advanced"), Evaluate=true);

                // Variables
                Medium.Density[n] rhos = if use_rho_nominal then fill(rho_nominal, n) else Medium.density(states);
                Medium.Density[n-1] rhos_act "Actual density per segment";

                Medium.DynamicViscosity[n] mus = if use_mu_nominal then fill(mu_nominal, n) else Medium.dynamicViscosity(states);
                Medium.DynamicViscosity[n-1] mus_act "Actual viscosity per segment";

                // Variables
                SI.Pressure[n-1] dps_fg(each start = (p_a_start - p_b_start)/(n-1))
              "Pressure drop between states";

                // Reynolds Number
                parameter SI.ReynoldsNumber Re_turbulent = 4000
              "Start of turbulent regime, depending on type of flow device";
                parameter Boolean show_Res = false
              "= true, if Reynolds numbers are included for plotting"
                   annotation (Evaluate=true, Dialog(group="Diagnostics"));
                SI.ReynoldsNumber[n] Res=Modelica.Fluid.Pipes.BaseClasses.CharacteristicNumbers.ReynoldsNumber(
                    vs,
                    rhos,
                    mus,
                    dimensions) if show_Res "Reynolds numbers";
                Medium.MassFlowRate[n-1] m_flows_turbulent=
                    {nParallel*(crossAreas[i] + crossAreas[i+1])/(dimensions[i] + dimensions[i+1])*mus_act[i]*Re_turbulent for i in 1:n-1} if
                       show_Res "Start of turbulent flow";
        protected
                parameter Boolean use_rho_nominal = false
              "= true, if rho_nominal is used, otherwise computed from medium"
                   annotation(Dialog(group="Advanced"), Evaluate=true);
                parameter SI.Density rho_nominal = Medium.density_pTX(Medium.p_default, Medium.T_default, Medium.X_default)
              "Nominal density (e.g., rho_liquidWater = 995, rho_air = 1.2)"
                  annotation(Dialog(group="Advanced", enable=use_rho_nominal));

                parameter Boolean use_mu_nominal = false
              "= true, if mu_nominal is used, otherwise computed from medium"
                   annotation(Dialog(group="Advanced"), Evaluate=true);
                parameter SI.DynamicViscosity mu_nominal = Medium.dynamicViscosity(
                                                               Medium.setState_pTX(
                                                                   Medium.p_default, Medium.T_default, Medium.X_default))
              "Nominal dynamic viscosity (e.g., mu_liquidWater = 1e-3, mu_air = 1.8e-5)"
                  annotation(Dialog(group="Advanced", enable=use_mu_nominal));

              equation
                if not allowFlowReversal then
                  rhos_act = rhos[1:n-1];
                  mus_act = mus[1:n-1];
                elseif not useUpstreamScheme then
                  rhos_act = 0.5*(rhos[1:n-1] + rhos[2:n]);
                  mus_act = 0.5*(mus[1:n-1] + mus[2:n]);
                else
                  for i in 1:n-1 loop
                    rhos_act[i] = noEvent(if m_flows[i] > 0 then rhos[i] else rhos[i+1]);
                    mus_act[i] = noEvent(if m_flows[i] > 0 then mus[i] else mus[i+1]);
                  end for;
                end if;

                if use_Ib_flows then
                  Ib_flows = nParallel*{rhos[i]*vs[i]*vs[i]*crossAreas[i] - rhos[i+1]*vs[i+1]*vs[i+1]*crossAreas[i+1] for i in 1:n-1};
                  // alternatively use densities rhos_act of actual streams, together with mass flow rates,
                  // not conserving momentum if fluid density changes between flow segments:
                  //Ib_flows = {((rhos[i]*vs[i])^2*crossAreas[i] - (rhos[i+1]*vs[i+1])^2*crossAreas[i+1])/rhos_act[i] for i in 1:n-1};
                else
                  Ib_flows = zeros(n-1);
                end if;

                Fs_p = nParallel*{0.5*(crossAreas[i]+crossAreas[i+1])*(Medium.pressure(states[i+1])-Medium.pressure(states[i])) for i in 1:n-1};

                // Note: the equation is written for dps_fg instead of Fs_fg to help the translator
                dps_fg = {Fs_fg[i]/nParallel*2/(crossAreas[i]+crossAreas[i+1]) for i in 1:n-1};

                annotation (Documentation(info="<html>
<p>
This partial model defines a common interface for <code>m=n-1</code> flow models between <code>n</code> device segments.
The flow models provide a steady-state or dynamic momentum balance using an upwind discretization scheme per default.
Extending models must add pressure loss terms for friction and gravity.
</p>
<p>
The fluid is specified in the interface with the thermodynamic <code>states[n]</code> for a given <code>Medium</code> model.
The geometry is specified with the <code>pathLengths[n-1]</code> between the device segments as well as
with the <code>crossAreas[n]</code> and the <code>roughnesses[n]</code> of the device segments.
Moreover the fluid flow is characterized for different types of devices by the characteristic <code>dimensions[n]</code>
and the average velocities <code>vs[n]</code> of fluid flow in the device segments.
See <a href=\"modelica://Modelica.Fluid.Pipes.BaseClasses.CharacteristicNumbers.ReynoldsNumber\">Pipes.BaseClasses.CharacteristicNumbers.ReynoldsNumber</a>
for example definitions.
</p>
<p>
The parameter <code>Re_turbulent</code> can be specified for the least mass flow rate of the turbulent regime.
It defaults to 4000, which is appropriate for pipe flow.
The <code>m_flows_turbulent[n-1]</code> resulting from <code>Re_turbulent</code> can optionally be calculated together with the Reynolds numbers
<code>Res[n]</code> of the device segments (<code>show_Res=true</code>).
</p>
<p>
Using the thermodynamic states[n] of the device segments, the densities rhos[n] and the dynamic viscosities mus[n]
of the segments as well as the actual densities rhos_act[n-1] and the actual viscosities mus_act[n-1] of the flows are predefined
in this base model. Note that no events are raised on flow reversal. This needs to be treated by an extending model,
e.g., with numerical smoothing or by raising events as appropriate.
</p>
</html>"),     Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                      -100},{100,100}}), graphics={Line(
                    points={{-80,-50},{-80,50},{80,-50},{80,50}},
                    color={0,0,255},
                    thickness=1), Text(
                    extent={{-40,-50},{40,-90}},
                    textString="%name")}));
              end PartialStaggeredFlowModel;

              partial model PartialGenericPipeFlow
          "GenericPipeFlow: Pipe flow pressure loss and gravity with replaceable WallFriction package"

                parameter Boolean from_dp = momentumDynamics >= Types.Dynamics.SteadyStateInitial
              "= true, use m_flow = f(dp), otherwise dp = f(m_flow)"
                  annotation (Dialog(group="Advanced"), Evaluate=true);

                extends
            Modelica.Fluid.Pipes.BaseClasses.FlowModels.PartialStaggeredFlowModel(
               final Re_turbulent=4000);

                replaceable package WallFriction =
                  Modelica.Fluid.Pipes.BaseClasses.WallFriction.Detailed
                    constrainedby
            Modelica.Fluid.Pipes.BaseClasses.WallFriction.PartialWallFriction
            "Wall friction model"
                    annotation(Dialog(group="Wall friction"), choicesAllMatching=true);

                input SI.Length[n-1] pathLengths_internal
              "pathLengths used internally; to be defined by extending class";
                input SI.ReynoldsNumber[n-1] Res_turbulent_internal = Re_turbulent*ones(n-1)
              "Re_turbulent used internally; to be defined by extending class";

                // Parameters
                parameter SI.AbsolutePressure dp_nominal
              "Nominal pressure loss (only for nominal models)";
                parameter SI.MassFlowRate m_flow_nominal "Nominal mass flow rate";
                parameter SI.MassFlowRate m_flow_small = if system.use_eps_Re then system.eps_m_flow*m_flow_nominal else system.m_flow_small
              "Within regularization if |m_flows| < m_flow_small (may be wider for large discontinuities in static head)"
                  annotation(Dialog(enable=not from_dp and WallFriction.use_m_flow_small));

        protected
                parameter SI.AbsolutePressure dp_small(start = 1, fixed = false)
              "Within regularization if |dp| < dp_small (may be wider for large discontinuities in static head)"
                  annotation(Dialog(enable=from_dp and WallFriction.use_dp_small));
                final parameter Boolean constantPressureLossCoefficient=
                   use_rho_nominal and (use_mu_nominal or not WallFriction.use_mu)
              "= true, if the pressure loss does not depend on fluid states"
                   annotation(Evaluate=true);
                final parameter Boolean continuousFlowReversal=
                   (not useUpstreamScheme)
                   or constantPressureLossCoefficient
                   or not allowFlowReversal
              "= true, if the pressure loss is continuous around zero flow"
                   annotation(Evaluate=true);

                SI.Length[n-1] diameters = 0.5*(dimensions[1:n-1] + dimensions[2:n])
              "Mean diameters between segments";
                SI.AbsolutePressure dp_fric_nominal=
                  sum(WallFriction.pressureLoss_m_flow(
                                 m_flow_nominal/nParallel,
                                 rho_nominal,
                                 rho_nominal,
                                 mu_nominal,
                                 mu_nominal,
                                 pathLengths_internal,
                                 diameters,
                                 (crossAreas[1:n-1]+crossAreas[2:n])/2,
                                 (roughnesses[1:n-1]+roughnesses[2:n])/2,
                                 m_flow_small/nParallel,
                                 Res_turbulent_internal))
              "Pressure loss for nominal conditions";

              initial equation
                // initialize dp_small from flow model
                if system.use_eps_Re then
                  dp_small = dp_fric_nominal/m_flow_nominal*m_flow_small;
                else
                  dp_small = system.dp_small;
                end if;

              equation
                for i in 1:n-1 loop
                  assert(m_flows[i] > -m_flow_small or allowFlowReversal, "Reversing flow occurs even though allowFlowReversal is false");
                end for;

                if continuousFlowReversal then
                  // simple regularization
                  if from_dp and not WallFriction.dp_is_zero then
                    m_flows = homotopy(
                      actual = WallFriction.massFlowRate_dp(
                                 dps_fg - {g*dheights[i]*rhos_act[i] for i in 1:n-1},
                                 rhos_act,
                                 rhos_act,
                                 mus_act,
                                 mus_act,
                                 pathLengths_internal,
                                 diameters,
                                 (crossAreas[1:n-1]+crossAreas[2:n])/2,
                                 (roughnesses[1:n-1]+roughnesses[2:n])/2,
                                 dp_small/(n-1),
                                 Res_turbulent_internal)*nParallel,
                      simplified = m_flow_nominal/dp_nominal*(dps_fg - g*dheights*rho_nominal));
                  else
                    dps_fg = homotopy(
                      actual = WallFriction.pressureLoss_m_flow(
                                 m_flows/nParallel,
                                 rhos_act,
                                 rhos_act,
                                 mus_act,
                                 mus_act,
                                 pathLengths_internal,
                                 diameters,
                                 (crossAreas[1:n-1]+crossAreas[2:n])/2,
                                 (roughnesses[1:n-1]+roughnesses[2:n])/2,
                                 m_flow_small/nParallel,
                                 Res_turbulent_internal) + {g*dheights[i]*rhos_act[i] for i in 1:n-1},
                      simplified = dp_nominal/m_flow_nominal*m_flows + g*dheights*rho_nominal);
                  end if;
                else
                  // regularization for discontinuous flow reversal and static head
                  if from_dp and not WallFriction.dp_is_zero then
                    m_flows = homotopy(
                      actual = WallFriction.massFlowRate_dp_staticHead(
                                 dps_fg,
                                 rhos[1:n-1],
                                 rhos[2:n],
                                 mus[1:n-1],
                                 mus[2:n],
                                 pathLengths_internal,
                                 diameters,
                                 g*dheights,
                                 (crossAreas[1:n-1]+crossAreas[2:n])/2,
                                 (roughnesses[1:n-1]+roughnesses[2:n])/2,
                                 dp_small/(n-1),
                                 Res_turbulent_internal)*nParallel,
                      simplified = m_flow_nominal/dp_nominal*(dps_fg - g*dheights*rho_nominal));
                  else
                    dps_fg = homotopy(
                      actual = WallFriction.pressureLoss_m_flow_staticHead(
                                 m_flows/nParallel,
                                 rhos[1:n-1],
                                 rhos[2:n],
                                 mus[1:n-1],
                                 mus[2:n],
                                 pathLengths_internal,
                                 diameters,
                                 g*dheights,
                                 (crossAreas[1:n-1]+crossAreas[2:n])/2,
                                 (roughnesses[1:n-1]+roughnesses[2:n])/2,
                                 m_flow_small/nParallel,
                                 Res_turbulent_internal),
                      simplified = dp_nominal/m_flow_nominal*m_flows + g*dheights*rho_nominal);
                  end if;
                end if;

                  annotation (Documentation(info="<html>
<p>
This model describes pressure losses due to <strong>wall friction</strong> in a pipe
and due to <strong>gravity</strong>.
Correlations of different complexity and validity can be
selected via the replaceable package <strong>WallFriction</strong> (see parameter menu below).
The details of the pipe wall friction model are described in the
<a href=\"modelica://Modelica.Fluid.UsersGuide.ComponentDefinition.WallFriction\">UsersGuide</a>.
Basically, different variants of the equation
</p>

<blockquote><pre>
dp = &lambda;(Re,&Delta;)*(L/D)*&rho;*v*|v|/2.
</pre></blockquote>

<p>

By default, the correlations are computed with media data at the actual time instant.
In order to reduce non-linear equation systems, the parameters
<strong>use_mu_nominal</strong> and <strong>use_rho_nominal</strong> provide the option
to compute the correlations with constant media values
at the desired operating point. This might speed-up the
simulation and/or might give a more robust simulation.
</p>
</html>"),     Diagram(coordinateSystem(
                      preserveAspectRatio=false,
                      extent={{-100,-100},{100,100}}), graphics={
                  Rectangle(
                    extent={{-100,64},{100,-64}},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Backward),
                  Rectangle(
                    extent={{-100,50},{100,-49}},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Line(
                    points={{-60,-49},{-60,50}},
                    color={0,0,255},
                    arrow={Arrow.Filled,Arrow.Filled}),
                  Text(
                    extent={{-50,16},{6,-10}},
                    textColor={0,0,255},
                    textString="diameters"),
                  Line(
                    points={{-100,74},{100,74}},
                    color={0,0,255},
                    arrow={Arrow.Filled,Arrow.Filled}),
                  Text(
                    extent={{-32,93},{32,74}},
                    textColor={0,0,255},
                    textString="pathLengths")}));
              end PartialGenericPipeFlow;

              model DetailedPipeFlow
          "DetailedPipeFlow: Detailed characteristic for laminar and turbulent flow"
                extends
            Modelica.Fluid.Pipes.BaseClasses.FlowModels.PartialGenericPipeFlow(
              redeclare package WallFriction =
                  Modelica.Fluid.Pipes.BaseClasses.WallFriction.Detailed,
              pathLengths_internal=pathLengths,
              dp_nominal(start=1, fixed=false),
              m_flow_nominal=if system.use_eps_Re then system.m_flow_nominal else 1e2*m_flow_small,
              Res_turbulent_internal = Re_turbulent*ones(n-1));

              initial equation
                // initialize dp_nominal from flow model
                if system.use_eps_Re then
                  dp_nominal = dp_fric_nominal + g*sum(dheights)*rho_nominal;
                else
                  dp_nominal = 1e3*dp_small;
                end if;

                  annotation (Documentation(info="<html>
<p>
This component defines the complete regime of wall friction.
The details are described in the
<a href=\"modelica://Modelica.Fluid.UsersGuide.ComponentDefinition.WallFriction\">UsersGuide</a>.
The functional relationship of the friction loss factor &lambda; is
displayed in the next figure. Function massFlowRate_dp() defines the \"red curve\"
(\"Swamee and Jain\"), where as function pressureLoss_m_flow() defines the
\"blue curve\" (\"Colebrook-White\"). The two functions are inverses from
each other and give slightly different results in the transition region
between Re = 1500 .. 4000, in order to get explicit equations without
solving a non-linear equation.
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/Pipes/BaseClasses/PipeFriction1.png\"
     alt=\"PipeFriction1.png\">
</p>

<p>
Additionally to wall friction, this component properly implements static
head. With respect to the latter, two cases can be distinguished. In the case
shown next, the change of elevation with the path from a to b has the opposite
sign of the change of density.</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/Pipes/BaseClasses/PipeFrictionStaticHead_case-a.png\"
     alt=\"PipeFrictionStaticHead_case-a.png\">
</p>

<p>
In the case illustrated second, the change of elevation with the path from a to
b has the same sign of the change of density.</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/Pipes/BaseClasses/PipeFrictionStaticHead_case-b.png\"
     alt=\"PipeFrictionStaticHead_case-b.png\">
</p>
</html>"),     Diagram(coordinateSystem(
                      preserveAspectRatio=false,
                      extent={{-100,-100},{100,100}}), graphics={
                  Rectangle(
                    extent={{-100,64},{100,-64}},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Backward),
                  Rectangle(
                    extent={{-100,50},{100,-49}},
                    fillColor={255,255,255},
                    fillPattern=FillPattern.Solid),
                  Line(
                    points={{-60,-49},{-60,50}},
                    color={0,0,255},
                    arrow={Arrow.Filled,Arrow.Filled}),
                  Text(
                    extent={{-50,16},{6,-10}},
                    textColor={0,0,255},
                    textString="diameters"),
                  Line(
                    points={{-100,74},{100,74}},
                    color={0,0,255},
                    arrow={Arrow.Filled,Arrow.Filled})}));
              end DetailedPipeFlow;
        end FlowModels;

      package HeatTransfer "Heat transfer for flow models"
        extends Modelica.Icons.Package;

        partial model PartialFlowHeatTransfer
            "Base class for any pipe heat transfer correlation"
          extends Modelica.Fluid.Interfaces.PartialHeatTransfer;

          // Additional inputs provided to flow heat transfer model
          input SI.Velocity[n] vs "Mean velocities of fluid flow in segments";

          // Geometry parameters and inputs for flow heat transfer
          parameter Real nParallel "Number of identical parallel flow devices"
             annotation(Dialog(tab="Internal interface",enable=false,group="Geometry"));
          input SI.Length[n] lengths "Lengths along flow path";
          input SI.Length[n] dimensions
              "Characteristic dimensions for fluid flow (diameter for pipe flow)";
          input Modelica.Fluid.Types.Roughness[n] roughnesses "Average heights of surface asperities";

          annotation (Documentation(info="<html>
Base class for heat transfer models of flow devices.
<p>
The geometry is specified in the interface with the <code>surfaceAreas[n]</code>, the <code>roughnesses[n]</code>
and the lengths[n] along the flow path.
Moreover the fluid flow is characterized for different types of devices by the characteristic <code>dimensions[n+1]</code>
and the average velocities <code>vs[n+1]</code> of fluid flow.
See <a href=\"modelica://Modelica.Fluid.Pipes.BaseClasses.CharacteristicNumbers.ReynoldsNumber\">Pipes.BaseClasses.CharacteristicNumbers.ReynoldsNumber</a>
for example definitions.
</p>
</html>"),    Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},
                      {100,100}}), graphics={Rectangle(
                    extent={{-80,60},{80,-60}},
                    pattern=LinePattern.None,
                    fillColor={255,0,0},
                    fillPattern=FillPattern.HorizontalCylinder), Text(
                    extent={{-40,22},{38,-18}},
                    textString="%name")}));
        end PartialFlowHeatTransfer;

        model IdealFlowHeatTransfer
            "IdealHeatTransfer: Ideal heat transfer without thermal resistance"
          extends PartialFlowHeatTransfer;
        equation
          Ts = heatPorts.T;
          annotation(Documentation(info="<html>
Ideal heat transfer without thermal resistance.
</html>"));
        end IdealFlowHeatTransfer;

        model ConstantFlowHeatTransfer
            "ConstantHeatTransfer: Constant heat transfer coefficient"
          extends PartialFlowHeatTransfer;
          parameter SI.CoefficientOfHeatTransfer alpha0 "Heat transfer coefficient";
        equation
          Q_flows = {alpha0*surfaceAreas[i]*(heatPorts[i].T - Ts[i])*nParallel for i in 1:n};
          annotation(Documentation(info="<html>
<p>
Simple heat transfer correlation with constant heat transfer coefficient, used as default component in distributed pipe models.
</p>
</html>"));
        end ConstantFlowHeatTransfer;

        partial model PartialPipeFlowHeatTransfer
            "Base class for pipe heat transfer correlation in terms of Nusselt number heat transfer in a circular pipe for laminar and turbulent one-phase flow"
          extends PartialFlowHeatTransfer;
          parameter SI.CoefficientOfHeatTransfer alpha0=100
              "Guess value for heat transfer coefficients";
          SI.CoefficientOfHeatTransfer[n] alphas(each start=alpha0)
              "Heat transfer coefficient";
          Real[n] Res "Reynolds numbers";
          Real[n] Prs "Prandtl numbers";
          Real[n] Nus "Nusselt numbers";
          Medium.Density[n] ds "Densities";
          Medium.DynamicViscosity[n] mus "Dynamic viscosities";
          Medium.ThermalConductivity[n] lambdas "Thermal conductivity";
          SI.Length[n] diameters = dimensions "Hydraulic diameters for pipe flow";
        equation
          ds=Medium.density(states);
          mus=Medium.dynamicViscosity(states);
          lambdas=Medium.thermalConductivity(states);
          Prs = Medium.prandtlNumber(states);
          Res = CharacteristicNumbers.ReynoldsNumber(vs, ds, mus, diameters);
          Nus = CharacteristicNumbers.NusseltNumber(alphas, diameters, lambdas);
          Q_flows={alphas[i]*surfaceAreas[i]*(heatPorts[i].T - Ts[i])*nParallel for i in 1:n};
            annotation (Documentation(info="<html>
<p>
Base class for heat transfer models that are expressed in terms of the Nusselt number and which can be used in distributed pipe models.
</p>
</html>"));
        end PartialPipeFlowHeatTransfer;

        model LocalPipeFlowHeatTransfer
            "LocalPipeFlowHeatTransfer: Laminar and turbulent forced convection in pipes, local coefficients"
          extends PartialPipeFlowHeatTransfer;
      protected
          Real[n] Nus_turb "Nusselt number for turbulent flow";
          Real[n] Nus_lam "Nusselt number for laminar flow";
          Real Nu_1;
          Real[n] Nus_2;
          Real[n] Xis;
        equation
          Nu_1=3.66;
          for i in 1:n loop
           Nus_turb[i]=smooth(0,(Xis[i]/8)*abs(Res[i])*Prs[i]/(1+12.7*(Xis[i]/8)^0.5*(Prs[i]^(2/3)-1))*(1+1/3*(diameters[i]/lengths[i]/(if vs[i]>=0 then (i-0.5) else (n-i+0.5)))^(2/3)));
           Xis[i]=(1.8*Modelica.Math.log10(max(1e-10,Res[i]))-1.5)^(-2);
           Nus_lam[i]=(Nu_1^3+0.7^3+(Nus_2[i]-0.7)^3)^(1/3);
           Nus_2[i]=smooth(0,1.077*(abs(Res[i])*Prs[i]*diameters[i]/lengths[i]/(if vs[i]>=0 then (i-0.5) else (n-i+0.5)))^(1/3));
           Nus[i]=Modelica.Media.Air.MoistAir.Utilities.spliceFunction(Nus_turb[i], Nus_lam[i], Res[i]-6150, 3850);
          end for;
          annotation (Documentation(info="<html>
<p>
Heat transfer model for laminar and turbulent flow in pipes. Range of validity:
</p>
<ul>
<li>fully developed pipe flow</li>
<li>forced convection</li>
<li>one phase Newtonian fluid</li>
<li>(spatial) constant wall temperature in the laminar region</li>
<li>0 &le; Re &le; 1e6, 0.6 &le; Pr &le; 100, d/L &le; 1</li>
<li>The correlation holds for non-circular pipes only in the turbulent region. Use diameter=4*crossArea/perimeter as characteristic length.</li>
</ul>
<p>
The correlation takes into account the spatial position along the pipe flow, which changes discontinuously at flow reversal. However, the heat transfer coefficient itself is continuous around zero flow rate, but not its derivative.
</p>
<h4>References</h4>
<dl><dt>Verein Deutscher Ingenieure (1997):</dt>
    <dd><strong>VDI W&auml;rmeatlas</strong>.
         Springer Verlag, Ed. 8, 1997.</dd>
</dl>
</html>"));
        end LocalPipeFlowHeatTransfer;
        annotation (Documentation(info="<html>
<p>
Heat transfer correlations for pipe models
</p>
</html>"));
      end HeatTransfer;

        package CharacteristicNumbers
        "Functions to compute characteristic numbers"
          extends Modelica.Icons.Package;

          function ReynoldsNumber "Return Reynolds number from v, rho, mu, D"
            extends Modelica.Icons.Function;

            input SI.Velocity v "Mean velocity of fluid flow";
            input SI.Density rho "Fluid density";
            input SI.DynamicViscosity mu "Dynamic (absolute) viscosity";
            input SI.Length D
              "Characteristic dimension (hydraulic diameter of pipes)";
            output SI.ReynoldsNumber Re "Reynolds number";
          algorithm
            Re := abs(v)*rho*D/mu;
            annotation (Documentation(info="<html>
<p>
Calculation of Reynolds Number
</p>
<blockquote><pre>
Re = |v|&rho;D/&mu;
</pre></blockquote>
<p>
a measure of the relationship between inertial forces (v&rho;) and viscous forces (D/&mu;).
</p>
<p>
The following table gives examples for the characteristic dimension D and the velocity v for different fluid flow devices:
</p>
<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
<tr><th><strong>Device Type</strong></th><th><strong>Characteristic Dimension D</strong></th><th><strong>Velocity v</strong></th></tr>
<tr><td>Circular Pipe</td><td>diameter</td>
    <td>m_flow/&rho;/crossArea</td></tr>
<tr><td>Rectangular Duct</td><td>4*crossArea/perimeter</td>
    <td>m_flow/&rho;/crossArea</td></tr>
<tr><td>Wide Duct</td><td>distance between narrow, parallel walls</td>
    <td>m_flow/&rho;/crossArea</td></tr>
<tr><td>Packed Bed</td><td>diameterOfSpericalParticles/(1-fluidFractionOfTotalVolume)</td>
    <td>m_flow/&rho;/crossArea (without particles)</td></tr>
<tr><td>Device with rotating agitator</td><td>diameterOfRotor</td>
    <td>RotationalSpeed*diameterOfRotor</td></tr>
</table>
</html>"));
          end ReynoldsNumber;

          function NusseltNumber "Return Nusselt number"
            extends Modelica.Icons.Function;

            input SI.CoefficientOfHeatTransfer alpha "Coefficient of heat transfer";
            input SI.Length D "Characteristic dimension";
            input SI.ThermalConductivity lambda "Thermal conductivity";
            output SI.NusseltNumber Nu "Nusselt number";
          algorithm
            Nu := alpha*D/lambda;
            annotation (Documentation(info="Nusselt number Nu = alpha*D/lambda"));
          end NusseltNumber;
        end CharacteristicNumbers;

        package WallFriction
        "Different variants for pressure drops due to pipe wall friction"
          extends Modelica.Icons.Package;

          partial package PartialWallFriction
            "Partial wall friction characteristic (base package of all wall friction characteristics)"
            extends Modelica.Icons.Package;
            import Modelica.Constants.pi;

          // Constants to be set in subpackages
            constant Boolean use_mu = true
              "= true, if mu_a/mu_b are used in function, otherwise value is not used";
            constant Boolean use_roughness = true
              "= true, if roughness is used in function, otherwise value is not used";
            constant Boolean use_dp_small = true
              "= true, if dp_small is used in function, otherwise value is not used";
            constant Boolean use_m_flow_small = true
              "= true, if m_flow_small is used in function, otherwise value is not used";
            constant Boolean dp_is_zero = false
              "= true, if no wall friction is present, i.e., dp = 0 (function massFlowRate_dp() cannot be used)";
            constant Boolean use_Re_turbulent = true
              "= true, if Re_turbulent input is used in function, otherwise value is not used";

          // pressure loss characteristic functions
            replaceable partial function massFlowRate_dp
              "Return mass flow rate m_flow as function of pressure loss dp, i.e., m_flow = f(dp), due to wall friction"
              extends Modelica.Icons.Function;

              input SI.Pressure dp "Pressure loss (dp = port_a.p - port_b.p)";
              input SI.Density rho_a "Density at port_a";
              input SI.Density rho_b "Density at port_b";
              input SI.DynamicViscosity mu_a
                "Dynamic viscosity at port_a (dummy if use_mu = false)";
              input SI.DynamicViscosity mu_b
                "Dynamic viscosity at port_b (dummy if use_mu = false)";
              input SI.Length length "Length of pipe";
              input SI.Diameter diameter "Inner (hydraulic) diameter of pipe";
              input SI.Area crossArea = pi*diameter^2/4 "Inner cross section area";
              input Modelica.Fluid.Types.Roughness roughness = 2.5e-5
                "Absolute roughness of pipe, with a default for a smooth steel pipe (dummy if use_roughness = false)";
              input SI.AbsolutePressure dp_small = 1
                "Regularization of zero flow if |dp| < dp_small (dummy if use_dp_small = false)";
              input SI.ReynoldsNumber Re_turbulent = 4000
                "Turbulent flow if Re >= Re_turbulent (dummy if use_Re_turbulent = false)";

              output SI.MassFlowRate m_flow "Mass flow rate from port_a to port_b";
            annotation (Documentation(info="<html>

</html>"));
            end massFlowRate_dp;

            replaceable partial function massFlowRate_dp_staticHead
              "Return mass flow rate m_flow as function of pressure loss dp, i.e., m_flow = f(dp), due to wall friction and static head"
              extends Modelica.Icons.Function;

              input SI.Pressure dp "Pressure loss (dp = port_a.p - port_b.p)";
              input SI.Density rho_a "Density at port_a";
              input SI.Density rho_b "Density at port_b";
              input SI.DynamicViscosity mu_a
                "Dynamic viscosity at port_a (dummy if use_mu = false)";
              input SI.DynamicViscosity mu_b
                "Dynamic viscosity at port_b (dummy if use_mu = false)";
              input SI.Length length "Length of pipe";
              input SI.Diameter diameter "Inner (hydraulic) diameter of pipe";
              input Real g_times_height_ab(unit="m2/s2")
                "Gravity times (Height(port_b) - Height(port_a))";
              input SI.Area crossArea = pi*diameter^2/4 "Inner cross section area";
              input Modelica.Fluid.Types.Roughness roughness = 2.5e-5
                "Absolute roughness of pipe, with a default for a smooth steel pipe (dummy if use_roughness = false)";
              input SI.AbsolutePressure dp_small=1
                "Regularization of zero flow if |dp| < dp_small (dummy if use_dp_small = false)";
              input SI.ReynoldsNumber Re_turbulent = 4000
                "Turbulent flow if Re >= Re_turbulent (dummy if use_Re_turbulent = false)";

              output SI.MassFlowRate m_flow "Mass flow rate from port_a to port_b";
              annotation (Documentation(info="<html>

</html>"));
            end massFlowRate_dp_staticHead;

            replaceable partial function pressureLoss_m_flow
              "Return pressure loss dp as function of mass flow rate m_flow, i.e., dp = f(m_flow), due to wall friction"
              extends Modelica.Icons.Function;

              input SI.MassFlowRate m_flow "Mass flow rate from port_a to port_b";
              input SI.Density rho_a "Density at port_a";
              input SI.Density rho_b "Density at port_b";
              input SI.DynamicViscosity mu_a
                "Dynamic viscosity at port_a (dummy if use_mu = false)";
              input SI.DynamicViscosity mu_b
                "Dynamic viscosity at port_b (dummy if use_mu = false)";
              input SI.Length length "Length of pipe";
              input SI.Diameter diameter "Inner (hydraulic) diameter of pipe";
              input SI.Area crossArea = pi*diameter^2/4 "Inner cross section area";
              input Modelica.Fluid.Types.Roughness roughness = 2.5e-5
                "Absolute roughness of pipe, with a default for a smooth steel pipe (dummy if use_roughness = false)";
              input SI.MassFlowRate m_flow_small = 0.01
                "Regularization of zero flow if |m_flow| < m_flow_small (dummy if use_m_flow_small = false)";
              input SI.ReynoldsNumber Re_turbulent = 4000
                "Turbulent flow if Re >= Re_turbulent (dummy if use_Re_turbulent = false)";

              output SI.Pressure dp "Pressure loss (dp = port_a.p - port_b.p)";

            annotation (Documentation(info="<html>

</html>"));
            end pressureLoss_m_flow;

            replaceable partial function pressureLoss_m_flow_staticHead
              "Return pressure loss dp as function of mass flow rate m_flow, i.e., dp = f(m_flow), due to wall friction and static head"
                      extends Modelica.Icons.Function;

              input SI.MassFlowRate m_flow "Mass flow rate from port_a to port_b";
              input SI.Density rho_a "Density at port_a";
              input SI.Density rho_b "Density at port_b";
              input SI.DynamicViscosity mu_a
                "Dynamic viscosity at port_a (dummy if use_mu = false)";
              input SI.DynamicViscosity mu_b
                "Dynamic viscosity at port_b (dummy if use_mu = false)";
              input SI.Length length "Length of pipe";
              input SI.Diameter diameter "Inner (hydraulic) diameter of pipe";
              input Real g_times_height_ab(unit="m2/s2")
                "Gravity times (Height(port_b) - Height(port_a))";
              input SI.Area crossArea = pi*diameter^2/4 "Inner cross section area";
              input Modelica.Fluid.Types.Roughness roughness = 2.5e-5
                "Absolute roughness of pipe, with a default for a smooth steel pipe (dummy if use_roughness = false)";
              input SI.MassFlowRate m_flow_small = 0.01
                "Regularization of zero flow if |m_flow| < m_flow_small (dummy if use_m_flow_small = false)";
              input SI.ReynoldsNumber Re_turbulent = 4000
                "Turbulent flow if Re >= Re_turbulent (dummy if use_Re_turbulent = false)";

              output SI.Pressure dp "Pressure loss (dp = port_a.p - port_b.p)";

            annotation (Documentation(info="<html>

</html>"));
            end pressureLoss_m_flow_staticHead;
            annotation (Documentation(info="<html>

</html>"));
          end PartialWallFriction;

          package Detailed
            "Pipe wall friction for laminar and turbulent flow (detailed characteristic)"

            extends PartialWallFriction(
                      final use_mu = true,
                      final use_roughness = true,
                      final use_dp_small = true,
                      final use_m_flow_small = true,
                      final use_Re_turbulent = true);

            import ln = Modelica.Math.log "Logarithm, base e";
            import Modelica.Math.log10 "Logarithm, base 10";
            import Modelica.Math.exp "Exponential function";

            redeclare function extends massFlowRate_dp
              "Return mass flow rate m_flow as function of pressure loss dp, i.e., m_flow = f(dp), due to wall friction"
              import Modelica.Math;
          protected
              Real Delta(min=0) = roughness/diameter "Relative roughness";
              SI.ReynoldsNumber Re1 = min((745*Math.exp(if Delta <= 0.0065 then 1 else 0.0065/Delta))^0.97, Re_turbulent)
                "Re leaving laminar curve";
              SI.ReynoldsNumber Re2 = Re_turbulent "Re entering turbulent curve";
              SI.DynamicViscosity mu "Upstream viscosity";
              SI.Density rho "Upstream density";
              SI.ReynoldsNumber Re "Reynolds number";
              Real lambda2 "Modified friction coefficient (= lambda*Re^2)";
              function interpolateInRegion2 =
                Modelica.Fluid.Dissipation.Utilities.Functions.General.CubicInterpolation_Re
                "Cubic Hermite spline interpolation in transition region";
            algorithm
              // Determine upstream density, upstream viscosity, and lambda2
              rho     := if dp >= 0 then rho_a else rho_b;
              mu      := if dp >= 0 then mu_a else mu_b;
              lambda2 := abs(dp)*2*diameter^3*rho/(length*mu*mu);

              // Determine Re under the assumption of laminar flow
              Re := lambda2/64;

              // Modify Re, if turbulent flow
              if Re > Re1 then
                 Re :=-2*sqrt(lambda2)*Math.log10(2.51/sqrt(lambda2) + 0.27*Delta);
                 if Re < Re2 then
                    Re := interpolateInRegion2(Re, Re1, Re2, Delta, lambda2);
                 end if;
              end if;

              // Determine mass flow rate
              m_flow := crossArea/diameter*mu*(if dp >= 0 then Re else -Re);
                      annotation (smoothOrder=1, Documentation(info="<html>

</html>"));
            end massFlowRate_dp;

            redeclare function extends pressureLoss_m_flow
              "Return pressure loss dp as function of mass flow rate m_flow, i.e., dp = f(m_flow), due to wall friction"
              import Modelica.Math;
              import Modelica.Constants.pi;
          protected
              Real Delta(min=0) = roughness/diameter "Relative roughness";
              SI.ReynoldsNumber Re1 = min(745*Math.exp(if Delta <= 0.0065 then 1 else 0.0065/Delta), Re_turbulent)
                "Re leaving laminar curve";
              SI.ReynoldsNumber Re2 = Re_turbulent "Re entering turbulent curve";
              SI.DynamicViscosity mu "Upstream viscosity";
              SI.Density rho "Upstream density";
              SI.ReynoldsNumber Re "Reynolds number";
              Real lambda2 "Modified friction coefficient (= lambda*Re^2)";
              function interpolateInRegion2 =
                Modelica.Fluid.Dissipation.Utilities.Functions.General.CubicInterpolation_lambda
                "Cubic Hermite spline interpolation in transition region";
            algorithm
              // Determine upstream density and upstream viscosity
              rho     :=if m_flow >= 0 then rho_a else rho_b;
              mu      :=if m_flow >= 0 then mu_a else mu_b;

              // Determine Re, lambda2 and pressure drop
              Re := diameter*abs(m_flow)/(crossArea*mu);
              lambda2 := if Re <= Re1 then 64*Re else
                        (if Re >= Re2 then 0.25*(Re/Math.log10(Delta/3.7 + 5.74/Re^0.9))^2 else
                         interpolateInRegion2(Re, Re1, Re2, Delta));
              dp :=length*mu*mu/(2*rho*diameter*diameter*diameter)*
                   (if m_flow >= 0 then lambda2 else -lambda2);
                      annotation (smoothOrder=1, Documentation(info="<html>

</html>"));
            end pressureLoss_m_flow;

            redeclare function extends massFlowRate_dp_staticHead
              "Return mass flow rate m_flow as function of pressure loss dp, i.e., m_flow = f(dp), due to wall friction and static head"

          protected
              Real Delta(min=0) = roughness/diameter "Relative roughness";
              SI.ReynoldsNumber Re "Reynolds number";
              SI.ReynoldsNumber Re1 = min((745*exp(if Delta <= 0.0065 then 1 else 0.0065/Delta))^0.97, Re_turbulent)
                "Boundary between laminar regime and transition";
              SI.ReynoldsNumber Re2 = Re_turbulent
                "Boundary between transition and turbulent regime";
              SI.Pressure dp_a
                "Upper end of regularization domain of the m_flow(dp) relation";
              SI.Pressure dp_b
                "Lower end of regularization domain of the m_flow(dp) relation";
              SI.MassFlowRate m_flow_a
                "Value at upper end of regularization domain";
              SI.MassFlowRate m_flow_b
                "Value at lower end of regularization domain";

              SI.MassFlowRate dm_flow_ddp_fric_a
                "Derivative at upper end of regularization domain";
              SI.MassFlowRate dm_flow_ddp_fric_b
                "Derivative at lower end of regularization domain";

              SI.Pressure dp_grav_a = g_times_height_ab*rho_a
                "Static head if mass flows in design direction (a to b)";
              SI.Pressure dp_grav_b = g_times_height_ab*rho_b
                "Static head if mass flows against design direction (b to a)";

              // Properly define zero mass flow conditions
              SI.MassFlowRate m_flow_zero = 0;
              SI.Pressure dp_zero = (dp_grav_a + dp_grav_b)/2;
              Real dm_flow_ddp_fric_zero;

            algorithm
              dp_a := max(dp_grav_a, dp_grav_b)+dp_small;
              dp_b := min(dp_grav_a, dp_grav_b)-dp_small;

              if dp>=dp_a then
                // Positive flow outside regularization
                m_flow := Internal.m_flow_of_dp_fric(dp-dp_grav_a, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta);
              elseif dp<=dp_b then
                // Negative flow outside regularization
                m_flow := Internal.m_flow_of_dp_fric(dp-dp_grav_b, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta);
              else
                // Regularization parameters
                (m_flow_a, dm_flow_ddp_fric_a) := Internal.m_flow_of_dp_fric(dp_a-dp_grav_a, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta);
                (m_flow_b, dm_flow_ddp_fric_b) := Internal.m_flow_of_dp_fric(dp_b-dp_grav_b, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta);
                // Include a properly defined zero mass flow point
                // Obtain a suitable slope from the linear section slope c (value of m_flow is overwritten later)
                (m_flow, dm_flow_ddp_fric_zero) := Utilities.regFun3(dp_zero, dp_b, dp_a, m_flow_b, m_flow_a, dm_flow_ddp_fric_b, dm_flow_ddp_fric_a);
                // Do regularization
                if dp>dp_zero then
                  m_flow := Utilities.regFun3(dp, dp_zero, dp_a, m_flow_zero, m_flow_a, dm_flow_ddp_fric_zero, dm_flow_ddp_fric_a);
                else
                  m_flow := Utilities.regFun3(dp, dp_b, dp_zero, m_flow_b, m_flow_zero, dm_flow_ddp_fric_b, dm_flow_ddp_fric_zero);
                end if;
              end if;
              annotation (smoothOrder=1);
            end massFlowRate_dp_staticHead;

            redeclare function extends pressureLoss_m_flow_staticHead
              "Return pressure loss dp as function of mass flow rate m_flow, i.e., dp = f(m_flow), due to wall friction and static head"

          protected
              Real Delta(min=0) = roughness/diameter "Relative roughness";
              SI.ReynoldsNumber Re1 = min(745*exp(if Delta <= 0.0065 then 1 else 0.0065/Delta), Re_turbulent)
                "Boundary between laminar regime and transition";
              SI.ReynoldsNumber Re2 = Re_turbulent
                "Boundary between transition and turbulent regime";

              SI.MassFlowRate m_flow_a
                "Upper end of regularization domain of the dp(m_flow) relation";
              SI.MassFlowRate m_flow_b
                "Lower end of regularization domain of the dp(m_flow) relation";

              SI.Pressure dp_a "Value at upper end of regularization domain";
              SI.Pressure dp_b "Value at lower end of regularization domain";

              SI.Pressure dp_grav_a = g_times_height_ab*rho_a
                "Static head if mass flows in design direction (a to b)";
              SI.Pressure dp_grav_b = g_times_height_ab*rho_b
                "Static head if mass flows against design direction (b to a)";

              Real ddp_dm_flow_a
                "Derivative of pressure drop with mass flow rate at m_flow_a";
              Real ddp_dm_flow_b
                "Derivative of pressure drop with mass flow rate at m_flow_b";

              // Properly define zero mass flow conditions
              SI.MassFlowRate m_flow_zero = 0;
              SI.Pressure dp_zero = (dp_grav_a + dp_grav_b)/2;
              Real ddp_dm_flow_zero;

            algorithm
              m_flow_a := if dp_grav_a<dp_grav_b then
                Internal.m_flow_of_dp_fric(dp_grav_b - dp_grav_a, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta)+m_flow_small else
                m_flow_small;
              m_flow_b := if dp_grav_a<dp_grav_b then
                Internal.m_flow_of_dp_fric(dp_grav_a - dp_grav_b, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta)-m_flow_small else
                -m_flow_small;

              if m_flow>=m_flow_a then
                // Positive flow outside regularization
                dp := Internal.dp_fric_of_m_flow(m_flow, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta) + dp_grav_a;
              elseif m_flow<=m_flow_b then
                // Negative flow outside regularization
                dp := Internal.dp_fric_of_m_flow(m_flow, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta) + dp_grav_b;
              else
                // Regularization parameters
                (dp_a, ddp_dm_flow_a) := Internal.dp_fric_of_m_flow(m_flow_a, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta);
                dp_a := dp_a + dp_grav_a "Adding dp_grav to dp_fric to get dp";
                (dp_b, ddp_dm_flow_b) := Internal.dp_fric_of_m_flow(m_flow_b, rho_a, rho_b, mu_a, mu_b, length, diameter, crossArea, Re1, Re2, Delta);
                dp_b := dp_b + dp_grav_b "Adding dp_grav to dp_fric to get dp";
                // Include a properly defined zero mass flow point
                // Obtain a suitable slope from the linear section slope c (value of dp is overwritten later)
                (dp, ddp_dm_flow_zero) := Utilities.regFun3(m_flow_zero, m_flow_b, m_flow_a, dp_b, dp_a, ddp_dm_flow_b, ddp_dm_flow_a);
                // Do regularization
                if m_flow>m_flow_zero then
                  dp := Utilities.regFun3(m_flow, m_flow_zero, m_flow_a, dp_zero, dp_a, ddp_dm_flow_zero, ddp_dm_flow_a);
                else
                  dp := Utilities.regFun3(m_flow, m_flow_b, m_flow_zero, dp_b, dp_zero, ddp_dm_flow_b, ddp_dm_flow_zero);
                end if;
              end if;
              annotation (smoothOrder=1);
            end pressureLoss_m_flow_staticHead;

          package Internal
              "Functions to calculate mass flow rate from friction pressure drop and vice versa"
            extends Modelica.Icons.InternalPackage;
            function m_flow_of_dp_fric
                "Calculate mass flow rate as function of pressure drop due to friction"
              extends Modelica.Icons.Function;

              input SI.Pressure dp_fric
                  "Pressure loss due to friction (dp = port_a.p - port_b.p)";
              input SI.Density rho_a "Density at port_a";
              input SI.Density rho_b "Density at port_b";
              input SI.DynamicViscosity mu_a
                  "Dynamic viscosity at port_a (dummy if use_mu = false)";
              input SI.DynamicViscosity mu_b
                  "Dynamic viscosity at port_b (dummy if use_mu = false)";
              input SI.Length length "Length of pipe";
              input SI.Diameter diameter "Inner (hydraulic) diameter of pipe";
              input SI.Area crossArea "Inner cross section area";
              input SI.ReynoldsNumber Re1
                  "Boundary between laminar regime and transition";
              input SI.ReynoldsNumber Re2
                  "Boundary between transition and turbulent regime";
              input Real Delta(min=0) "Relative roughness";
              output SI.MassFlowRate m_flow "Mass flow rate from port_a to port_b";
              output Real dm_flow_ddp_fric
                  "Derivative of mass flow rate with dp_fric";

            protected
              function interpolateInRegion2_withDerivative
                  "Interpolation in log-log space using a cubic Hermite polynomial, where x=log10(lambda2), y=log10(Re)"
                extends Modelica.Icons.Function;

                input Real lambda2 "Known independent variable";
                input SI.ReynoldsNumber Re1
                    "Boundary between laminar regime and transition";
                input SI.ReynoldsNumber Re2
                    "Boundary between transition and turbulent regime";
                input Real Delta(min=0) "Relative roughness";
                input SI.Pressure dp_fric
                    "Pressure loss due to friction (dp = port_a.p - port_b.p)";
                output SI.ReynoldsNumber Re "Unknown return variable";
                output Real dRe_ddp "Derivative of return value";
                // point lg(lambda2(Re1)) with derivative at lg(Re1)
              protected
                Real x1=log10(64*Re1);
                Real y1=log10(Re1);
                Real y1d=1;

                // Point lg(lambda2(Re2)) with derivative at lg(Re2)
                Real aux2=Delta/3.7 + 5.74/Re2^0.9;
                Real aux3=log10(aux2);
                Real L2=0.25*(Re2/aux3)^2;
                Real aux4=2.51/sqrt(L2) + 0.27*Delta;
                Real aux5=-2*sqrt(L2)*log10(aux4);
                Real x2=log10(L2);
                Real y2=log10(aux5);
                Real y2d=0.5 + (2.51/log(10))/(aux5*aux4);

                // Point of interest in transformed space
                Real x=log10(lambda2);
                Real y;
                Real dy_dx "Derivative in transformed space";
              algorithm
                // Interpolation
                (y, dy_dx) := Utilities.cubicHermite_withDerivative(x, x1, x2, y1, y2, y1d, y2d);

                // Return value
                Re := 10^y;

                // Derivative of return value
                dRe_ddp := Re/abs(dp_fric)*dy_dx;
                annotation (smoothOrder=1);
              end interpolateInRegion2_withDerivative;

              SI.DynamicViscosity mu "Upstream viscosity";
              SI.Density rho "Upstream density";
              Real lambda2 "Modified friction coefficient (= lambda*Re^2)";
              SI.ReynoldsNumber Re "Reynolds number";
              Real dRe_ddp "dRe/ddp";
              Real aux1;
              Real aux2;

            algorithm
              // Determine upstream density and upstream viscosity
              if dp_fric >= 0 then
                rho := rho_a;
                mu  := mu_a;
              else
                rho := rho_b;
                mu  := mu_b;
              end if;

              // Positive mass flow rate
              lambda2 := abs(dp_fric)*2*diameter^3*rho/(length*mu*mu)
                  "Known as lambda2=f(dp)";

              aux1:=(2*diameter^3*rho)/(length*mu^2);

              // Determine Re and dRe/ddp under the assumption of laminar flow
              Re := lambda2/64 "Hagen-Poiseuille";
              dRe_ddp := aux1/64 "Hagen-Poiseuille";

              // Modify Re, if turbulent flow
              if Re > Re1 then
                Re :=-2*sqrt(lambda2)*log10(2.51/sqrt(lambda2) + 0.27*Delta)
                    "Colebrook-White";
                aux2 := sqrt(aux1*abs(dp_fric));
                dRe_ddp := 1/log(10)*(-2*log(2.51/aux2+0.27*Delta)*aux1/(2*aux2)+2*2.51/(2*abs(dp_fric)*(2.51/aux2+0.27*Delta)));
                if Re < Re2 then
                  (Re, dRe_ddp) := interpolateInRegion2_withDerivative(lambda2, Re1, Re2, Delta, dp_fric);
                end if;
              end if;

              // Determine mass flow rate
              m_flow := crossArea/diameter*mu*(if dp_fric >= 0 then Re else -Re);
              // Determine derivative of mass flow rate with dp_fric
              dm_flow_ddp_fric := crossArea/diameter*mu*dRe_ddp;
              annotation(smoothOrder=1);
            end m_flow_of_dp_fric;

            function dp_fric_of_m_flow
                "Calculate pressure drop due to friction as function of mass flow rate"
              extends Modelica.Icons.Function;

              input SI.MassFlowRate m_flow "Mass flow rate from port_a to port_b";
              input SI.Density rho_a "Density at port_a";
              input SI.Density rho_b "Density at port_b";
              input SI.DynamicViscosity mu_a
                  "Dynamic viscosity at port_a (dummy if use_mu = false)";
              input SI.DynamicViscosity mu_b
                  "Dynamic viscosity at port_b (dummy if use_mu = false)";
              input SI.Length length "Length of pipe";
              input SI.Diameter diameter "Inner (hydraulic) diameter of pipe";
              input SI.Area crossArea "Inner cross section area";
              input SI.ReynoldsNumber Re1
                  "Boundary between laminar regime and transition";
              input SI.ReynoldsNumber Re2
                  "Boundary between transition and turbulent regime";
              input Real Delta(min=0) "Relative roughness";
              output SI.Pressure dp_fric
                  "Pressure loss due to friction (dp_fric = port_a.p - port_b.p - dp_grav)";
              output Real ddp_fric_dm_flow
                  "Derivative of pressure drop with mass flow rate";

            protected
              function interpolateInRegion2
                  "Interpolation in log-log space using a cubic Hermite polynomial, where x=log10(Re), y=log10(lambda2)"
                extends Modelica.Icons.Function;

                input SI.ReynoldsNumber Re "Known independent variable";
                input SI.ReynoldsNumber Re1
                    "Boundary between laminar regime and transition";
                input SI.ReynoldsNumber Re2
                    "Boundary between transition and turbulent regime";
                input Real Delta(min=0) "Relative roughness";
                input SI.MassFlowRate m_flow "Mass flow rate from port_a to port_b";
                output Real lambda2 "Unknown return value";
                output Real dlambda2_dm_flow "Derivative of return value";
                // point lg(lambda2(Re1)) with derivative at lg(Re1)
              protected
                Real x1 = log10(Re1);
                Real y1 = log10(64*Re1);
                Real y1d = 1;

                // Point lg(lambda2(Re2)) with derivative at lg(Re2)
                Real aux2 = Delta/3.7 + 5.74/Re2^0.9;
                Real aux3 = log10(aux2);
                Real L2 = 0.25*(Re2/aux3)^2;
                Real x2 = log10(Re2);
                Real y2 = log10(L2);
                Real y2d = 2+(2*5.74*0.9)/(log(aux2)*Re2^0.9*aux2);

                // Point of interest in transformed space
                Real x=log10(Re);
                Real y;
                Real dy_dx "Derivative in transformed space";
              algorithm
                // Interpolation
                (y, dy_dx) := Utilities.cubicHermite_withDerivative(x, x1, x2, y1, y2, y1d, y2d);

                // Return value
                lambda2 := 10^y;

                // Derivative of return value
                dlambda2_dm_flow := lambda2/abs(m_flow)*dy_dx;
                annotation(smoothOrder=1);
              end interpolateInRegion2;

              SI.DynamicViscosity mu "Upstream viscosity";
              SI.Density rho "Upstream density";
              SI.ReynoldsNumber Re "Reynolds number";
              Real lambda2 "Modified friction coefficient (= lambda*Re^2)";
              Real dlambda2_dm_flow "dlambda2/dm_flow";
              Real aux1;
              Real aux2;

            algorithm
              // Determine upstream density and upstream viscosity
              if m_flow >= 0 then
                rho := rho_a;
                mu  := mu_a;
              else
                rho := rho_b;
                mu  := mu_b;
              end if;

              // Determine Reynolds number
              Re := abs(m_flow)*diameter/(crossArea*mu);

              aux1 := diameter/(crossArea*mu);

              // Use correlation for lambda2 depending on actual conditions
              if Re <= Re1 then
                lambda2 := 64*Re "Hagen-Poiseuille";
                dlambda2_dm_flow := 64*aux1 "Hagen-Poiseuille";
              elseif Re >= Re2 then
                lambda2 := 0.25*(Re/log10(Delta/3.7 + 5.74/Re^0.9))^2 "Swamee-Jain";
                aux2 := Delta/3.7+5.74/((aux1*abs(m_flow))^0.9);
                dlambda2_dm_flow := 0.5*aux1*Re*log(10)^2*(1/(log(aux2)^2)+(5.74*0.9)/(log(aux2)^3*Re^0.9*aux2))
                    "Swamee-Jain";
              else
                (lambda2, dlambda2_dm_flow) := interpolateInRegion2(Re, Re1, Re2, Delta, m_flow);
              end if;

              // Compute pressure drop from lambda2
              dp_fric :=length*mu*mu/(2*rho*diameter*diameter*diameter)*
                   (if m_flow >= 0 then lambda2 else -lambda2);

              // Compute derivative from dlambda2/dm_flow
              ddp_fric_dm_flow := (length*mu^2)/(2*diameter^3*rho)*dlambda2_dm_flow;
              annotation(smoothOrder=1);
            end dp_fric_of_m_flow;
          end Internal;
            annotation (Documentation(info="<html>
<p>
This component defines the complete regime of wall friction.
The details are described in the
<a href=\"modelica://Modelica.Fluid.UsersGuide.ComponentDefinition.WallFriction\">UsersGuide</a>.
The functional relationship of the friction loss factor &lambda; is
displayed in the next figure. Function massFlowRate_dp() defines the \"red curve\"
(\"Swamee and Jain\"), where as function pressureLoss_m_flow() defines the
\"blue curve\" (\"Colebrook-White\"). The two functions are inverses from
each other and give slightly different results in the transition region
between Re = 1500 .. 4000, in order to get explicit equations without
solving a non-linear equation.
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/Pipes/BaseClasses/PipeFriction1.png\"
     alt=\"PipeFriction1.png\">
</p>

<p>
Additionally to wall friction, this component properly implements static
head. With respect to the latter, two cases can be distinguished. In the case
shown next, the change of elevation with the path from a to b has the opposite
sign of the change of density.</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/Pipes/BaseClasses/PipeFrictionStaticHead_case-a.png\"
     alt=\"PipeFrictionStaticHead_case-a.png\">
</p>

<p>
In the case illustrated second, the change of elevation with the path from a to
b has the same sign of the change of density.</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/Pipes/BaseClasses/PipeFrictionStaticHead_case-b.png\"
     alt=\"PipeFrictionStaticHead_case-b.png\">
</p>

</html>"));
          end Detailed;
          annotation (Documentation(info="<html>
<p>
This package provides functions to compute
pressure losses due to <strong>wall friction</strong> in a pipe.
Every correlation is defined by a package that is derived
by inheritance from the package WallFriction.PartialWallFriction.
The details of the underlying pipe wall friction model are described in the
<a href=\"modelica://Modelica.Fluid.UsersGuide.ComponentDefinition.WallFriction\">UsersGuide</a>.
Basically, different variants of the equation
</p>

<blockquote><pre>
dp = &lambda;(Re,&Delta;)*(L/D)*&rho;*v*|v|/2
</pre></blockquote>

<p>
are used, where the friction loss factor &lambda; is shown
in the next figure:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/Pipes/BaseClasses/PipeFriction1.png\"
     alt=\"PipeFriction1.png\">
</p>

</html>"));
        end WallFriction;
      end BaseClasses;
      annotation (Documentation(info="<html>
</html>"));
    end Pipes;

    package Sources "Define fixed or prescribed boundary conditions"
      extends Modelica.Icons.SourcesPackage;

      model Boundary_pT
        "Boundary with prescribed pressure, temperature, composition and trace substances"
        import Modelica.Media.Interfaces.Choices.IndependentVariables;

        extends Sources.BaseClasses.PartialSource;
        parameter Boolean use_p_in = false
          "Get the pressure from the input connector"
          annotation(Evaluate=true, HideResult=true, choices(checkBox=true));
        parameter Boolean use_T_in= false
          "Get the temperature from the input connector"
          annotation(Evaluate=true, HideResult=true, choices(checkBox=true));
        parameter Boolean use_X_in = false
          "Get the composition from the input connector"
          annotation(Evaluate=true, HideResult=true, choices(checkBox=true));
        parameter Boolean use_C_in = false
          "Get the trace substances from the input connector"
          annotation(Evaluate=true, HideResult=true, choices(checkBox=true));
        parameter Medium.AbsolutePressure p = Medium.p_default
          "Fixed value of pressure"
          annotation (Dialog(enable = not use_p_in));
        parameter Medium.Temperature T = Medium.T_default
          "Fixed value of temperature"
          annotation (Dialog(enable = not use_T_in));
        parameter Medium.MassFraction X[Medium.nX] = Medium.X_default
          "Fixed value of composition"
          annotation (Dialog(enable = (not use_X_in) and Medium.nXi > 0));
        parameter Medium.ExtraProperty C[Medium.nC](
             quantity=Medium.extraPropertiesNames) = Medium.C_default
          "Fixed values of trace substances"
          annotation (Dialog(enable = (not use_C_in) and Medium.nC > 0));
        Modelica.Blocks.Interfaces.RealInput p_in(unit="Pa") if use_p_in
          "Prescribed boundary pressure"
          annotation (Placement(transformation(extent={{-140,60},{-100,100}})));
        Modelica.Blocks.Interfaces.RealInput T_in(unit="K") if use_T_in
          "Prescribed boundary temperature"
          annotation (Placement(transformation(extent={{-140,20},{-100,60}})));
        Modelica.Blocks.Interfaces.RealInput X_in[Medium.nX](each unit="1") if use_X_in
          "Prescribed boundary composition"
          annotation (Placement(transformation(extent={{-140,-60},{-100,-20}})));
        Modelica.Blocks.Interfaces.RealInput C_in[Medium.nC] if use_C_in
          "Prescribed boundary trace substances"
          annotation (Placement(transformation(extent={{-140,-100},{-100,-60}})));
    protected
        Modelica.Blocks.Interfaces.RealInput p_in_internal(unit="Pa")
          "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput T_in_internal(unit="K")
          "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput X_in_internal[Medium.nX](each unit="1")
          "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput C_in_internal[Medium.nC]
          "Needed to connect to conditional connector";
      equation
        Modelica.Fluid.Utilities.checkBoundary(Medium.mediumName, Medium.substanceNames,
          Medium.singleState, true, X_in_internal, "Boundary_pT");
        connect(p_in, p_in_internal);
        connect(T_in, T_in_internal);
        connect(X_in, X_in_internal);
        connect(C_in, C_in_internal);
        if not use_p_in then
          p_in_internal = p;
        end if;
        if not use_T_in then
          T_in_internal = T;
        end if;
        if not use_X_in then
          X_in_internal = X;
        end if;
        if not use_C_in then
          C_in_internal = C;
        end if;
        medium.p = p_in_internal;
        if Medium.ThermoStates == IndependentVariables.ph or
           Medium.ThermoStates == IndependentVariables.phX then
           medium.h = Medium.specificEnthalpy(Medium.setState_pTX(p_in_internal, T_in_internal, X_in_internal));
        else
           medium.T = T_in_internal;
        end if;
        medium.Xi = X_in_internal[1:Medium.nXi];
        ports.C_outflow = fill(C_in_internal, nPorts);
        annotation (defaultComponentName="boundary",
          Icon(coordinateSystem(
              preserveAspectRatio=false,
              extent={{-100,-100},{100,100}}), graphics={
              Ellipse(
                extent={{-100,100},{100,-100}},
                fillPattern=FillPattern.Sphere,
                fillColor={0,127,255}),
              Text(
                extent={{-150,120},{150,160}},
                textString="%name",
                textColor={0,0,255}),
              Line(
                visible=use_p_in,
                points={{-100,80},{-58,80}},
                color={0,0,255}),
              Line(
                visible=use_T_in,
                points={{-100,40},{-92,40}},
                color={0,0,255}),
              Line(
                visible=use_X_in,
                points={{-100,-40},{-92,-40}},
                color={0,0,255}),
              Line(
                visible=use_C_in,
                points={{-100,-80},{-60,-80}},
                color={0,0,255}),
              Text(
                visible=use_p_in,
                extent={{-152,134},{-68,94}},
                textString="p"),
              Text(
                visible=use_X_in,
                extent={{-164,4},{-62,-36}},
                textString="X"),
              Text(
                visible=use_C_in,
                extent={{-164,-90},{-62,-130}},
                textString="C"),
              Text(
                visible=use_T_in,
                extent={{-162,34},{-60,-6}},
                textString="T")}),
          Documentation(info="<html>
<p>
Defines prescribed values for boundary conditions:
</p>
<ul>
<li> Prescribed boundary pressure.</li>
<li> Prescribed boundary temperature.</li>
<li> Boundary composition (only for multi-substance or trace-substance flow).</li>
</ul>
<p>If <code>use_p_in</code> is false (default option), the <code>p</code> parameter
is used as boundary pressure, and the <code>p_in</code> input connector is disabled; if <code>use_p_in</code> is true, then the <code>p</code> parameter is ignored, and the value provided by the input connector is used instead.</p>
<p>The same thing goes for the temperature, composition and trace substances.</p>
<p>
Note, that boundary temperature,
mass fractions and trace substances have only an effect if the mass flow
is from the boundary into the port. If mass is flowing from
the port into the boundary, the boundary definitions,
with exception of boundary pressure, do not have an effect.
</p>
</html>"));
      end Boundary_pT;

      model MassFlowSource_T
        "Ideal flow source that produces a prescribed mass flow with prescribed temperature, mass fraction and trace substances"
        import Modelica.Media.Interfaces.Choices.IndependentVariables;
        extends Sources.BaseClasses.PartialFlowSource;
        parameter Boolean use_m_flow_in = false
          "Get the mass flow rate from the input connector"
          annotation(Evaluate=true, HideResult=true, choices(checkBox=true));
        parameter Boolean use_T_in= false
          "Get the temperature from the input connector"
          annotation(Evaluate=true, HideResult=true, choices(checkBox=true));
        parameter Boolean use_X_in = false
          "Get the composition from the input connector"
          annotation(Evaluate=true, HideResult=true, choices(checkBox=true));
        parameter Boolean use_C_in = false
          "Get the trace substances from the input connector"
          annotation(Evaluate=true, HideResult=true, choices(checkBox=true));
        parameter Medium.MassFlowRate m_flow = 0
          "Fixed mass flow rate going out of the fluid port"
          annotation (Dialog(enable = not use_m_flow_in));
        parameter Medium.Temperature T = Medium.T_default
          "Fixed value of temperature"
          annotation (Dialog(enable = not use_T_in));
        parameter Medium.MassFraction X[Medium.nX] = Medium.X_default
          "Fixed value of composition"
          annotation (Dialog(enable = (not use_X_in) and Medium.nXi > 0));
        parameter Medium.ExtraProperty C[Medium.nC](
             quantity=Medium.extraPropertiesNames) = Medium.C_default
          "Fixed values of trace substances"
          annotation (Dialog(enable = (not use_C_in) and Medium.nC > 0));
        Modelica.Blocks.Interfaces.RealInput m_flow_in(unit="kg/s") if use_m_flow_in
          "Prescribed mass flow rate"
          annotation (Placement(transformation(extent={{-120,60},{-80,100}}), iconTransformation(extent={{-120,60},{-80,100}})));
        Modelica.Blocks.Interfaces.RealInput T_in(unit="K") if use_T_in
          "Prescribed fluid temperature"
          annotation (Placement(transformation(extent={{-140,20},{-100,60}}), iconTransformation(extent={{-140,20},{-100,60}})));
        Modelica.Blocks.Interfaces.RealInput X_in[Medium.nX](each unit="1") if use_X_in
          "Prescribed fluid composition"
          annotation (Placement(transformation(extent={{-140,-60},{-100,-20}})));
        Modelica.Blocks.Interfaces.RealInput C_in[Medium.nC] if use_C_in
          "Prescribed boundary trace substances"
          annotation (Placement(transformation(extent={{-120,-100},{-80,-60}})));
    protected
        Modelica.Blocks.Interfaces.RealInput m_flow_in_internal(unit="kg/s")
          "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput T_in_internal(unit="K")
          "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput X_in_internal[Medium.nX](each unit="1")
          "Needed to connect to conditional connector";
        Modelica.Blocks.Interfaces.RealInput C_in_internal[Medium.nC]
          "Needed to connect to conditional connector";
      equation
        Utilities.checkBoundary(Medium.mediumName, Medium.substanceNames,
          Medium.singleState, true, X_in_internal, "MassFlowSource_T");
        connect(m_flow_in, m_flow_in_internal);
        connect(T_in, T_in_internal);
        connect(X_in, X_in_internal);
        connect(C_in, C_in_internal);
        if not use_m_flow_in then
          m_flow_in_internal = m_flow;
        end if;
        if not use_T_in then
          T_in_internal = T;
        end if;
        if not use_X_in then
          X_in_internal = X;
        end if;
        if not use_C_in then
          C_in_internal = C;
        end if;
        if Medium.ThermoStates == IndependentVariables.ph or
           Medium.ThermoStates == IndependentVariables.phX then
           medium.h = Medium.specificEnthalpy(Medium.setState_pTX(medium.p, T_in_internal, X_in_internal));
        else
           medium.T = T_in_internal;
        end if;
        sum(ports.m_flow) = -m_flow_in_internal;
        medium.Xi = X_in_internal[1:Medium.nXi];
        ports.C_outflow = fill(C_in_internal, nPorts);
        annotation (defaultComponentName="boundary",
          Icon(coordinateSystem(
              preserveAspectRatio=true,
              extent={{-100,-100},{100,100}}), graphics={
              Rectangle(
                extent={{35,45},{100,-45}},
                fillPattern=FillPattern.HorizontalCylinder,
                fillColor={0,127,255}),
              Ellipse(
                extent={{-100,80},{60,-80}},
                lineColor={0,0,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Polygon(
                points={{-60,70},{60,0},{-60,-68},{-60,70}},
                lineColor={0,0,255},
                fillColor={0,0,255},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-54,32},{16,-30}},
                textColor={255,0,0},
                textString="m"),
              Text(
                extent={{-150,130},{150,170}},
                textString="%name",
                textColor={0,0,255}),
              Ellipse(
                extent={{-26,30},{-18,22}},
                lineColor={255,0,0},
                fillColor={255,0,0},
                fillPattern=FillPattern.Solid),
              Text(
                visible=use_m_flow_in,
                extent={{-185,132},{-45,100}},
                textString="m_flow"),
              Text(
                visible=use_T_in,
                extent={{-111,71},{-71,37}},
                textString="T"),
              Text(
                visible=use_X_in,
                extent={{-153,-44},{-33,-72}},
                textString="X"),
              Text(
                visible=use_C_in,
                extent={{-155,-98},{-35,-126}},
                textString="C")}),
          Documentation(info="<html>
<p>
Models an ideal flow source, with prescribed values of flow rate, temperature, composition and trace substances:
</p>
<ul>
<li> Prescribed mass flow rate.</li>
<li> Prescribed temperature.</li>
<li> Boundary composition (only for multi-substance or trace-substance flow).</li>
</ul>
<p>If <code>use_m_flow_in</code> is false (default option), the <code>m_flow</code> parameter
is used as boundary pressure, and the <code>m_flow_in</code> input connector is disabled; if <code>use_m_flow_in</code> is true, then the <code>m_flow</code> parameter is ignored, and the value provided by the input connector is used instead.</p>
<p>The same thing goes for the temperature and composition</p>
<p>
Note, that boundary temperature,
mass fractions and trace substances have only an effect if the mass flow
is from the boundary into the port. If mass is flowing from
the port into the boundary, the boundary definitions,
with exception of boundary flow rate, do not have an effect.
</p>
</html>"));
      end MassFlowSource_T;

      package BaseClasses
      "Base classes used in the Sources package (only of interest to build new component models)"
        extends Modelica.Icons.BasesPackage;

      partial model PartialSource
          "Partial component source with one fluid connector"
          import Modelica.Constants;

        parameter Integer nPorts=0 "Number of ports" annotation(Dialog(connectorSizing=true));

        replaceable package Medium =
            Modelica.Media.Interfaces.PartialMedium
            "Medium model within the source"
           annotation (choicesAllMatching=true);

        Medium.BaseProperties medium "Medium in the source";

        Interfaces.FluidPorts_b ports[nPorts](
                           redeclare each package Medium = Medium,
                           m_flow(each max=if flowDirection==Types.PortFlowDirection.Leaving then 0 else
                                           +Constants.inf,
                                  each min=if flowDirection==Types.PortFlowDirection.Entering then 0 else
                                           -Constants.inf))
          annotation (Placement(transformation(extent={{90,40},{110,-40}})));
      protected
        parameter Types.PortFlowDirection flowDirection=
                         Types.PortFlowDirection.Bidirectional
            "Allowed flow direction" annotation(Evaluate=true, Dialog(tab="Advanced"));
      equation
        // Only one connection allowed to a port to avoid unwanted ideal mixing
        for i in 1:nPorts loop
          assert(cardinality(ports[i]) <= 1,"
each ports[i] of boundary shall at most be connected to one component.
If two or more connections are present, ideal mixing takes
place with these connections, which is usually not the intention
of the modeller. Increase nPorts to add an additional port.
");

           ports[i].p          = medium.p;
           ports[i].h_outflow  = medium.h;
           ports[i].Xi_outflow = medium.Xi;
        end for;

        annotation (defaultComponentName="boundary", Documentation(info="<html>
<p>
Partial component to model the <strong>volume interface</strong> of a <strong>source</strong>
component, such as a mass flow source. The essential
features are:
</p>
<ul>
<li> The pressure in the connection port (= ports.p) is identical to the
     pressure in the volume.</li>
<li> The outflow enthalpy rate (= port.h_outflow) and the composition of the
     substances (= port.Xi_outflow) are identical to the respective values in the volume.</li>
</ul>
</html>"));
      end PartialSource;

      partial model PartialFlowSource
          "Partial component source with one fluid connector"
        import Modelica.Constants;

        parameter Integer nPorts=0 "Number of ports" annotation(Dialog(connectorSizing=true));

        replaceable package Medium =
            Modelica.Media.Interfaces.PartialMedium
            "Medium model within the source"
           annotation (choicesAllMatching=true);

        Medium.BaseProperties medium "Medium in the source";

        Interfaces.FluidPort_b ports[nPorts](
                           redeclare each package Medium = Medium,
                           m_flow(each max=if flowDirection==Types.PortFlowDirection.Leaving then 0 else
                                           +Constants.inf,
                                  each min=if flowDirection==Types.PortFlowDirection.Entering then 0 else
                                           -Constants.inf))
          annotation (Placement(transformation(extent={{90,10},{110,-10}})));
      protected
        parameter Types.PortFlowDirection flowDirection=
                         Types.PortFlowDirection.Bidirectional
            "Allowed flow direction" annotation(Evaluate=true, Dialog(tab="Advanced"));
      equation
        assert(abs(sum(abs(ports.m_flow)) - max(abs(ports.m_flow))) <= Modelica.Constants.small, "FlowSource only supports one connection with flow");
        assert(nPorts > 0, "At least one port needs to be present (nPorts > 0), otherwise the model is singular");
        // Only one connection allowed to a port to avoid unwanted ideal mixing
        for i in 1:nPorts loop
          assert(cardinality(ports[i]) <= 1,"
each ports[i] of boundary shall at most be connected to one component.
If two or more connections are present, ideal mixing takes
place with these connections, which is usually not the intention
of the modeller. Increase nPorts to add an additional port.
");        ports[i].p          = medium.p;
           ports[i].h_outflow  = medium.h;
           ports[i].Xi_outflow = medium.Xi;
        end for;

        annotation (defaultComponentName="boundary", Documentation(info="<html>
<p>
Partial component to model the <strong>volume interface</strong> of a <strong>source</strong>
component, such as a mass flow source. The essential
features are:
</p>
<ul>
<li> The pressure in the connection port (= ports.p) is identical to the
     pressure in the volume.</li>
<li> The outflow enthalpy rate (= port.h_outflow) and the composition of the
     substances (= port.Xi_outflow) are identical to the respective values in the volume.</li>
</ul>
</html>"));
      end PartialFlowSource;
      end BaseClasses;
      annotation (Documentation(info="<html>
<p>
Package <strong>Sources</strong> contains generic sources for fluid connectors
to define fixed or prescribed ambient conditions.
</p>
</html>"));
    end Sources;

    package Interfaces
    "Interfaces for steady state and unsteady, mixed-phase, multi-substance, incompressible and compressible flow"
      extends Modelica.Icons.InterfacesPackage;

      connector FluidPort
        "Interface for quasi one-dimensional fluid flow in a piping network (incompressible or compressible, one or more phases, one or more substances)"

        replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
          "Medium model" annotation (choicesAllMatching=true);

        flow Medium.MassFlowRate m_flow
          "Mass flow rate from the connection point into the component";
        Medium.AbsolutePressure p "Thermodynamic pressure in the connection point";
        stream Medium.SpecificEnthalpy h_outflow
          "Specific thermodynamic enthalpy close to the connection point if m_flow < 0";
        stream Medium.MassFraction Xi_outflow[Medium.nXi]
          "Independent mixture mass fractions m_i/m close to the connection point if m_flow < 0";
        stream Medium.ExtraProperty C_outflow[Medium.nC]
          "Properties c_i/m close to the connection point if m_flow < 0";
      end FluidPort;

      connector FluidPort_a "Generic fluid connector at design inlet"
        extends FluidPort;
        annotation (defaultComponentName="port_a",
                    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                  -100},{100,100}}), graphics={Ellipse(
                extent={{-40,40},{40,-40}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid), Text(extent={{-150,110},{150,50}},
                  textString="%name")}),
             Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
                  100,100}}), graphics={Ellipse(
                extent={{-100,100},{100,-100}},
                lineColor={0,127,255},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid), Ellipse(
                extent={{-100,100},{100,-100}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid)}));
      end FluidPort_a;

      connector FluidPort_b "Generic fluid connector at design outlet"
        extends FluidPort;
        annotation (defaultComponentName="port_b",
                    Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                  -100},{100,100}}), graphics={
              Ellipse(
                extent={{-40,40},{40,-40}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-30,30},{30,-30}},
                lineColor={0,127,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Text(extent={{-150,110},{150,50}}, textString="%name")}),
             Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{
                  100,100}}), graphics={
              Ellipse(
                extent={{-100,100},{100,-100}},
                lineColor={0,127,255},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-100,100},{100,-100}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-80,80},{80,-80}},
                lineColor={0,127,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid)}));
      end FluidPort_b;

      connector FluidPorts_b
        "Fluid connector with outlined, large icon to be used for vectors of FluidPorts (vector dimensions must be added after dragging)"
        extends FluidPort;
        annotation (defaultComponentName="ports_b",
                    Diagram(coordinateSystem(
              preserveAspectRatio=false,
              extent={{-50,-200},{50,200}},
              initialScale=0.2), graphics={
              Text(extent={{-75,130},{75,100}}, textString="%name"),
              Rectangle(
                extent={{-25,100},{25,-100}}),
              Ellipse(
                extent={{-25,90},{25,40}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-25,25},{25,-25}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-25,-40},{25,-90}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-15,-50},{15,-80}},
                lineColor={0,127,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-15,15},{15,-15}},
                lineColor={0,127,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-15,50},{15,80}},
                lineColor={0,127,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid)}),
             Icon(coordinateSystem(
              preserveAspectRatio=false,
              extent={{-50,-200},{50,200}},
              initialScale=0.2), graphics={
              Rectangle(
                extent={{-50,200},{50,-200}},
                lineColor={0,127,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-50,180},{50,80}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-50,50},{50,-50}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-50,-80},{50,-180}},
                fillColor={0,127,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-30,30},{30,-30}},
                lineColor={0,127,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-30,100},{30,160}},
                lineColor={0,127,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Ellipse(
                extent={{-30,-100},{30,-160}},
                lineColor={0,127,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid)}));
      end FluidPorts_b;

      partial model PartialTwoPort "Partial component with two ports"
        import Modelica.Constants;
        outer Modelica.Fluid.System system "System wide properties";

        replaceable package Medium =
            Modelica.Media.Interfaces.PartialMedium "Medium in the component"
            annotation (choicesAllMatching = true);

        parameter Boolean allowFlowReversal = system.allowFlowReversal
          "= true to allow flow reversal, false restricts to design direction (port_a -> port_b)"
          annotation(Dialog(tab="Assumptions"), Evaluate=true);

        Modelica.Fluid.Interfaces.FluidPort_a port_a(
                                      redeclare package Medium = Medium,
                           m_flow(min=if allowFlowReversal then -Constants.inf else 0))
          "Fluid connector a (positive design flow direction is from port_a to port_b)"
          annotation (Placement(transformation(extent={{-110,-10},{-90,10}})));
        Modelica.Fluid.Interfaces.FluidPort_b port_b(
                                      redeclare package Medium = Medium,
                           m_flow(max=if allowFlowReversal then +Constants.inf else 0))
          "Fluid connector b (positive design flow direction is from port_a to port_b)"
          annotation (Placement(transformation(extent={{110,-10},{90,10}}), iconTransformation(extent={{110,-10},{90,10}})));
        // Model structure, e.g., used for visualization
    protected
        parameter Boolean port_a_exposesState = false
          "= true if port_a exposes the state of a fluid volume";
        parameter Boolean port_b_exposesState = false
          "= true if port_b.p exposes the state of a fluid volume";
        parameter Boolean showDesignFlowDirection = true
          "= false to hide the arrow in the model icon";

        annotation (
          Documentation(info="<html>
<p>
This partial model defines an interface for components with two ports.
The treatment of the design flow direction and of flow reversal are predefined based on the parameter <code><strong>allowFlowReversal</strong></code>.
The component may transport fluid and may have internal storage for a given fluid <code><strong>Medium</strong></code>.
</p>
<p>
An extending model providing direct access to internal storage of mass or energy through port_a or port_b
should redefine the protected parameters <code><strong>port_a_exposesState</strong></code> and <code><strong>port_b_exposesState</strong></code> appropriately.
This will be visualized at the port icons, in order to improve the understanding of fluid model diagrams.
</p>
</html>"),Icon(coordinateSystem(
                preserveAspectRatio=true,
                extent={{-100,-100},{100,100}}), graphics={
              Polygon(
                points={{20,-70},{60,-85},{20,-100},{20,-70}},
                lineColor={0,128,255},
                fillColor={0,128,255},
                fillPattern=FillPattern.Solid,
                visible=showDesignFlowDirection),
              Polygon(
                points={{20,-75},{50,-85},{20,-95},{20,-75}},
                lineColor={255,255,255},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                visible=allowFlowReversal),
              Line(
                points={{55,-85},{-60,-85}},
                color={0,128,255},
                visible=showDesignFlowDirection),
              Text(
                extent={{-149,-114},{151,-154}},
                textColor={0,0,255},
                textString="%name"),
              Ellipse(
                extent={{-110,26},{-90,-24}},
                fillPattern=FillPattern.Solid,
                visible=port_a_exposesState),
              Ellipse(
                extent={{90,25},{110,-25}},
                fillPattern=FillPattern.Solid,
                visible=port_b_exposesState)}));
      end PartialTwoPort;

      connector HeatPorts_a
        "HeatPort connector with filled, large icon to be used for vectors of HeatPorts (vector dimensions must be added after dragging)"
        extends Modelica.Thermal.HeatTransfer.Interfaces.HeatPort;
        annotation (defaultComponentName="heatPorts_a",
             Icon(coordinateSystem(
              preserveAspectRatio=false,
              extent={{-200,-50},{200,50}},
              initialScale=0.2), graphics={
              Rectangle(
                extent={{-201,50},{200,-50}},
                lineColor={127,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Rectangle(
                extent={{-171,45},{-83,-45}},
                lineColor={127,0,0},
                fillColor={127,0,0},
                fillPattern=FillPattern.Solid),
              Rectangle(
                extent={{-45,45},{43,-45}},
                lineColor={127,0,0},
                fillColor={127,0,0},
                fillPattern=FillPattern.Solid),
              Rectangle(
                extent={{82,45},{170,-45}},
                lineColor={127,0,0},
                fillColor={127,0,0},
                fillPattern=FillPattern.Solid)}));
      end HeatPorts_a;

      partial model PartialHeatTransfer "Common interface for heat transfer models"

        // Parameters
        replaceable package Medium=Modelica.Media.Interfaces.PartialMedium
          "Medium in the component"
          annotation(Dialog(tab="Internal Interface",enable=false));

        parameter Integer n=1 "Number of heat transfer segments"
          annotation(Dialog(tab="Internal Interface",enable=false), Evaluate=true);

        // Inputs provided to heat transfer model
        input Medium.ThermodynamicState[n] states
          "Thermodynamic states of flow segments";

        input SI.Area[n] surfaceAreas "Heat transfer areas";

        // Outputs defined by heat transfer model
        output SI.HeatFlowRate[n] Q_flows "Heat flow rates";

        // Parameters
        parameter Boolean use_k = false
          "= true to use k value for thermal isolation"
          annotation(Dialog(tab="Internal Interface",enable=false));
        parameter SI.CoefficientOfHeatTransfer k = 0
          "Heat transfer coefficient to ambient"
          annotation(Dialog(group="Ambient"),Evaluate=true);
        parameter SI.Temperature T_ambient = system.T_ambient "Ambient temperature"
          annotation(Dialog(group="Ambient"));
        outer Modelica.Fluid.System system "System wide properties";

        // Heat ports
        Modelica.Fluid.Interfaces.HeatPorts_a[n] heatPorts
          "Heat port to component boundary"
          annotation (Placement(transformation(extent={{-10,60},{10,80}}), iconTransformation(extent={{-20,60},{20,80}})));

        // Variables
        SI.Temperature[n] Ts = Medium.temperature(states)
          "Temperatures defined by fluid states";

      equation
        if use_k then
          Q_flows = heatPorts.Q_flow + {k*surfaceAreas[i]*(T_ambient - heatPorts[i].T) for i in 1:n};
        else
          Q_flows = heatPorts.Q_flow;
        end if;

        annotation (Documentation(info="<html>
<p>
This component is a common interface for heat transfer models. The heat flow rates <code>Q_flows[n]</code> through the boundaries of n flow segments
are obtained as function of the thermodynamic <code>states</code> of the flow segments for a given fluid <code>Medium</code>,
the <code>surfaceAreas[n]</code> and the boundary temperatures <code>heatPorts[n].T</code>.
</p>
<p>
The heat loss coefficient <code>k</code> can be used to model a thermal isolation between <code>heatPorts.T</code> and <code>T_ambient</code>.</p>
<p>
An extending model implementing this interface needs to define one equation: the relation between the predefined fluid temperatures <code>Ts[n]</code>,
the boundary temperatures <code>heatPorts[n].T</code>, and the heat flow rates <code>Q_flows[n]</code>.
</p>
</html>"));
      end PartialHeatTransfer;

    partial model PartialDistributedVolume
        "Base class for distributed volume models"
        import Modelica.Fluid.Types;
        import Modelica.Fluid.Types.Dynamics;
        import Modelica.Media.Interfaces.Choices.IndependentVariables;
      outer Modelica.Fluid.System system "System properties";

      replaceable package Medium =
        Modelica.Media.Interfaces.PartialMedium "Medium in the component"
          annotation (choicesAllMatching = true);

      // Discretization
      parameter Integer n=2 "Number of discrete volumes";

      // Inputs provided to the volume model
      input SI.Volume[n] fluidVolumes
          "Discretized volume, determine in inheriting class";

      // Assumptions
      parameter Types.Dynamics energyDynamics=system.energyDynamics
          "Formulation of energy balances"
        annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
      parameter Types.Dynamics massDynamics=system.massDynamics
          "Formulation of mass balances"
        annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
      final parameter Types.Dynamics substanceDynamics=massDynamics
          "Formulation of substance balances"
        annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));
      final parameter Types.Dynamics traceDynamics=massDynamics
          "Formulation of trace substance balances"
        annotation(Evaluate=true, Dialog(tab = "Assumptions", group="Dynamics"));

      //Initialization
      parameter Medium.AbsolutePressure p_a_start=system.p_start
          "Start value of pressure at port a"
        annotation(Dialog(tab = "Initialization"));
      parameter Medium.AbsolutePressure p_b_start=p_a_start
          "Start value of pressure at port b"
        annotation(Dialog(tab = "Initialization"));
      final parameter Medium.AbsolutePressure[n] ps_start=if n > 1 then linspace(
            p_a_start, p_b_start, n) else {(p_a_start + p_b_start)/2}
          "Start value of pressure";

      parameter Boolean use_T_start=true "Use T_start if true, otherwise h_start"
         annotation(Evaluate=true, Dialog(tab = "Initialization"));

      parameter Medium.Temperature T_start=if use_T_start then system.T_start else
                  Medium.temperature_phX(
            (p_a_start + p_b_start)/2,
            h_start,
            X_start) "Start value of temperature"
        annotation(Evaluate=true, Dialog(tab = "Initialization", enable = use_T_start));
      parameter Medium.SpecificEnthalpy h_start=if use_T_start then
            Medium.specificEnthalpy_pTX(
            (p_a_start + p_b_start)/2,
            T_start,
            X_start) else Medium.h_default "Start value of specific enthalpy"
        annotation(Evaluate=true, Dialog(tab = "Initialization", enable = not use_T_start));
      parameter Medium.MassFraction X_start[Medium.nX] = Medium.X_default
          "Start value of mass fractions m_i/m"
        annotation (Dialog(tab="Initialization", enable=Medium.nXi > 0));
      parameter Medium.ExtraProperty C_start[Medium.nC](
           quantity=Medium.extraPropertiesNames) = Medium.C_default
          "Start value of trace substances"
        annotation (Dialog(tab="Initialization", enable=Medium.nC > 0));

      // Total quantities
      SI.Energy[n] Us "Internal energy of fluid";
      SI.Mass[n] ms "Fluid mass";
      SI.Mass[n,Medium.nXi] mXis "Substance mass";
      SI.Mass[n,Medium.nC] mCs "Trace substance mass";
      // C need to be added here because unlike for Xi, which has medium[:].Xi,
      // there is no variable medium[:].C
      SI.Mass[n,Medium.nC] mCs_scaled "Scaled trace substance mass";
      Medium.ExtraProperty Cs[n, Medium.nC] "Trace substance mixture content";

      Medium.BaseProperties[n] mediums(
        each preferredMediumStates=true,
        p(start=ps_start),
        each h(start=h_start),
        each T(start=T_start),
        each Xi(start=X_start[1:Medium.nXi]));

      //Source terms, have to be defined by an extending model (to zero if not used)
      Medium.MassFlowRate[n] mb_flows "Mass flow rate, source or sink";
      Medium.MassFlowRate[n,Medium.nXi] mbXi_flows
          "Independent mass flow rates, source or sink";
      Medium.ExtraPropertyFlowRate[n,Medium.nC] mbC_flows
          "Trace substance mass flow rates, source or sink";
      SI.EnthalpyFlowRate[n] Hb_flows "Enthalpy flow rate, source or sink";
      SI.HeatFlowRate[n] Qb_flows "Heat flow rate, source or sink";
      SI.Power[n] Wb_flows "Mechanical power, p*der(V) etc.";

    protected
      parameter Boolean initialize_p = not Medium.singleState
          "= true to set up initial equations for pressure";

    equation
      assert(not (energyDynamics<>Dynamics.SteadyState and massDynamics==Dynamics.SteadyState) or Medium.singleState,
             "Bad combination of dynamics options and Medium not conserving mass if fluidVolumes are fixed.");

      // Total quantities
      for i in 1:n loop
        ms[i] =fluidVolumes[i]*mediums[i].d;
        mXis[i, :] = ms[i]*mediums[i].Xi;
        mCs[i, :]  = ms[i]*Cs[i, :];
        Us[i] = ms[i]*mediums[i].u;
      end for;

      // Energy and mass balances
      if energyDynamics == Dynamics.SteadyState then
        for i in 1:n loop
          0 = Hb_flows[i] + Wb_flows[i] + Qb_flows[i];
        end for;
      else
        for i in 1:n loop
          der(Us[i]) = Hb_flows[i] + Wb_flows[i] + Qb_flows[i];
        end for;
      end if;
      if massDynamics == Dynamics.SteadyState then
        for i in 1:n loop
          0 = mb_flows[i];
        end for;
      else
        for i in 1:n loop
          der(ms[i]) = mb_flows[i];
        end for;
      end if;
      if substanceDynamics == Dynamics.SteadyState then
        for i in 1:n loop
          zeros(Medium.nXi) = mbXi_flows[i, :];
        end for;
      else
        for i in 1:n loop
          der(mXis[i, :]) = mbXi_flows[i, :];
        end for;
      end if;
      if traceDynamics == Dynamics.SteadyState then
        for i in 1:n loop
          zeros(Medium.nC)  = mbC_flows[i, :];
        end for;
      else
        for i in 1:n loop
          der(mCs_scaled[i, :])  = mbC_flows[i, :]./Medium.C_nominal;
          mCs[i, :] = mCs_scaled[i, :].*Medium.C_nominal;
        end for;
      end if;

    initial equation
      // initialization of balances
      if energyDynamics == Dynamics.FixedInitial then
        /*
    if use_T_start then
      mediums.T = fill(T_start, n);
    else
      mediums.h = fill(h_start, n);
    end if;
    */
        if Medium.ThermoStates == IndependentVariables.ph or
           Medium.ThermoStates == IndependentVariables.phX then
           mediums.h = fill(h_start, n);
        else
           mediums.T = fill(T_start, n);
        end if;

      elseif energyDynamics == Dynamics.SteadyStateInitial then
        /*
    if use_T_start then
      der(mediums.T) = zeros(n);
    else
      der(mediums.h) = zeros(n);
    end if;
    */
        if Medium.ThermoStates == IndependentVariables.ph or
           Medium.ThermoStates == IndependentVariables.phX then
           der(mediums.h) = zeros(n);
        else
           der(mediums.T) = zeros(n);
        end if;
      end if;

      if massDynamics == Dynamics.FixedInitial then
        if initialize_p then
          mediums.p = ps_start;
        end if;
      elseif massDynamics == Dynamics.SteadyStateInitial then
        if initialize_p then
          der(mediums.p) = zeros(n);
        end if;
      end if;

      if substanceDynamics == Dynamics.FixedInitial then
        mediums.Xi = fill(X_start[1:Medium.nXi], n);
      elseif substanceDynamics == Dynamics.SteadyStateInitial then
        for i in 1:n loop
          der(mediums[i].Xi) = zeros(Medium.nXi);
        end for;
      end if;

      if traceDynamics == Dynamics.FixedInitial then
        Cs = fill(C_start[1:Medium.nC], n);
      elseif traceDynamics == Dynamics.SteadyStateInitial then
        for i in 1:n loop
          der(mCs[i,:])      = zeros(Medium.nC);
        end for;
      end if;

       annotation (Documentation(info="<html>
<p>
Interface and base class for <code><strong>n</strong></code> ideally mixed fluid volumes with the ability to store mass and energy.
It is intended to model a one-dimensional spatial discretization of fluid flow according to the finite volume method.
The following boundary flow and source terms are part of the energy balance and must be specified in an extending class:
</p>
<ul>
<li><code><strong>Qb_flows[n]</strong></code>, heat flow term, e.g., conductive heat flows across segment boundaries, and</li>
<li><code><strong>Wb_flows[n]</strong></code>, work term.</li>
</ul>
<p>
The component volumes <code><strong>fluidVolumes[n]</strong></code> are an input that needs to be set in an extending class to complete the model.
</p>
<p>
Further source terms must be defined by an extending class for fluid flow across the segment boundary:
</p>
<ul>
<li><code><strong>Hb_flows[n]</strong></code>, enthalpy flow,</li>
<li><code><strong>mb_flows[n]</strong></code>, mass flow,</li>
<li><code><strong>mbXi_flows[n]</strong></code>, substance mass flow, and</li>
<li><code><strong>mbC_flows[n]</strong></code>, trace substance mass flow.</li>
</ul>
</html>"));
    end PartialDistributedVolume;

          partial model PartialDistributedFlow
      "Base class for a distributed momentum balance"

            outer Modelica.Fluid.System system "System properties";

            replaceable package Medium =
              Modelica.Media.Interfaces.PartialMedium "Medium in the component";

            parameter Boolean allowFlowReversal = system.allowFlowReversal
          "= true to allow flow reversal, false restricts to design direction (m_flows >= zeros(m))"
              annotation(Dialog(tab="Assumptions"), Evaluate=true);

            // Discretization
            parameter Integer m=1 "Number of flow segments";

            // Inputs provided to the flow model
            input SI.Length[m] pathLengths "Lengths along flow path";

            // Variables defined by momentum model
            Medium.MassFlowRate[m] m_flows(
               each min=if allowFlowReversal then -Modelica.Constants.inf else 0,
               each start = m_flow_start,
               each stateSelect = if momentumDynamics == Types.Dynamics.SteadyState then StateSelect.default else
                                         StateSelect.prefer)
          "Mass flow rates between states";

            // Parameters
            parameter Modelica.Fluid.Types.Dynamics momentumDynamics=system.momentumDynamics
          "Formulation of momentum balance"
              annotation(Dialog(tab="Assumptions", group="Dynamics"), Evaluate=true);

            parameter Medium.MassFlowRate m_flow_start=system.m_flow_start
          "Start value of mass flow rates"
              annotation(Dialog(tab="Initialization"));

            // Total quantities
            SI.Momentum[m] Is "Momenta of flow segments";

            // Source terms and forces to be defined by an extending model (zero if not used)
            SI.Force[m] Ib_flows "Flow of momentum across boundaries";
            SI.Force[m] Fs_p "Pressure forces";
            SI.Force[m] Fs_fg "Friction and gravity forces";

          equation
            // Total quantities
            Is = {m_flows[i]*pathLengths[i] for i in 1:m};

            // Momentum balances
            if momentumDynamics == Types.Dynamics.SteadyState then
              zeros(m) = Ib_flows - Fs_p - Fs_fg;
            else
              der(Is) = Ib_flows - Fs_p - Fs_fg;
            end if;

          initial equation
            if momentumDynamics == Types.Dynamics.FixedInitial then
              m_flows = fill(m_flow_start, m);
            elseif momentumDynamics == Types.Dynamics.SteadyStateInitial then
              der(m_flows) = zeros(m);
            end if;

            annotation (
               Documentation(info="<html>
<p>
Interface and base class for <code><strong>m</strong></code> momentum balances, defining the mass flow rates <code><strong>m_flows[m]</strong></code>
of a given <code>Medium</code> in <code><strong>m</strong></code> flow segments.
</p>
<p>
The following boundary flow and force terms are part of the momentum balances and must be specified in an extending model (to zero if not considered):
</p>
<ul>
<li><code><strong>Ib_flows[m]</strong></code>, the flows of momentum across segment boundaries,</li>
<li><code><strong>Fs_p[m]</strong></code>, pressure forces, and</li>
<li><code><strong>Fs_fg[m]</strong></code>, friction and gravity forces.</li>
</ul>
<p>
The lengths along the flow path <code><strong>pathLengths[m]</strong></code> are an input that needs to be set in an extending class to complete the model.
</p>
</html>"));
          end PartialDistributedFlow;
      annotation (Documentation(info="<html>

</html>",     revisions="<html>
<ul>
<li><em>June 9th, 2008</em>
       by Michael Sielemann: Introduced stream keyword after decision at 57th Design Meeting (Lund).</li>
<li><em>May 30, 2007</em>
       by Christoph Richter: moved everything back to its original position in Modelica.Fluid.</li>
<li><em>Apr. 20, 2007</em>
       by Christoph Richter: moved parts of the original package from Modelica.Fluid
       to the development branch of Modelica 2.2.2.</li>
<li><em>Nov. 2, 2005</em>
       by Francesco Casella: restructured after 45th Design Meeting.</li>
<li><em>Nov. 20-21, 2002</em>
       by Hilding Elmqvist, Mike Tiller, Allan Watson, John Batteh, Chuck Newman,
       Jonas Eborn: Improved at the 32nd Modelica Design Meeting.</li>
<li><em>Nov. 11, 2002</em>
       by Hilding Elmqvist, Martin Otter: improved version.</li>
<li><em>Nov. 6, 2002</em>
       by Hilding Elmqvist: first version.</li>
<li><em>Aug. 11, 2002</em>
       by Martin Otter: Improved according to discussion with Hilding
       Elmqvist and Hubertus Tummescheit.<br>
       The PortVicinity model is manually
       expanded in the base models.<br>
       The Volume used for components is renamed
       PartialComponentVolume.<br>
       A new volume model \"Fluid.Components.PortVolume\"
       introduced that has the medium properties of the port to which it is
       connected.<br>
       Fluid.Interfaces.PartialTwoPortTransport is a component
       for elementary two port transport elements, whereas PartialTwoPort
       is a component for a container component.</li>
</ul>
</html>"));
    end Interfaces;

    package Types "Common types for fluid models"
      extends Modelica.Icons.TypesPackage;

      type Roughness = Modelica.Icons.TypeReal (final quantity="Length", final unit="m", displayUnit="mm", min=0)
        "Real type for roughness of a pipe"
        annotation (Documentation(info="<html>
<p>
This Real type defines the absolute roughness of the inner surface of a
pipe or fitting, i.e., the absolute average height of surface asperities.
It has usually to
be estimated. In <em>[Idelchik 1994, pp. 105-109,
Table 2-5; Miller 1990, p. 190, Table 8-1]</em> many examples are given.
As a short summary:
</p>

<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
  <tr><td colspan=\"2\" align=\"center\"><strong>Type of pipe</strong></td>
      <td align=\"center\">Roughness</td></tr>

  <tr><td><strong>Smooth pipes</strong></td>
      <td>Drawn brass, copper, aluminium, glass, etc.</td>
      <td> 0.0025 mm</td>
  </tr>
  <tr><td rowspan=\"3\"><strong>Steel pipes</strong></td>
      <td>New smooth pipes</td>
      <td>0.025 mm</td>
  </tr>
  <tr><td>Mortar lined, average finish</td>
      <td>0.1 mm</td>
  </tr>
  <tr><td>Heavy rust</td>
      <td>1 mm</td>
  </tr>
  <tr><td rowspan=\"3\"><strong>Concrete pipes</strong></td>
      <td>Steel forms, first class workmanship</td>
      <td>0.025 mm</td>
  </tr>
  <tr><td>Steel forms, average workmanship</td>
      <td>0.1 mm</td>
  </tr>
  <tr><td>Block linings</td>
      <td>1 mm</td>
  </tr>
</table>

<h4>References</h4>

<dl>
    <dt>Idelchik I.E. (1994):</dt>
    <dd><a href=\"http://www.bookfinder.com/dir/i/Handbook_of_Hydraulic_Resistance/0849399084/\"><strong>Handbook
        of Hydraulic Resistance</strong></a>. 3rd edition, Begell House, ISBN
        0-8493-9908-4</dd>
    <dt>Miller D. S. (1990):</dt>
    <dd><strong>Internal flow systems</strong>.
    2nd edition. Cranfield:BHRA(Information Services).</dd>
</dl>
</html>"));

      type Dynamics = enumeration(
        DynamicFreeInitial
            "DynamicFreeInitial -- Dynamic balance, Initial guess value",
        FixedInitial   "FixedInitial -- Dynamic balance, Initial value fixed",
        SteadyStateInitial
            "SteadyStateInitial -- Dynamic balance, Steady state initial with guess value",
        SteadyState   "SteadyState -- Steady state balance, Initial guess value")
        "Enumeration to define definition of balance equations"
      annotation (Documentation(info="<html>
<p>
Enumeration to define the formulation of balance equations
(to be selected via choices menu):
</p>

<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
<tr><th><strong>Dynamics.</strong></th><th><strong>Meaning</strong></th></tr>
<tr><td>DynamicFreeInitial</td><td>Dynamic balance, Initial guess value</td></tr>

<tr><td>FixedInitial</td><td>Dynamic balance, Initial value fixed</td></tr>

<tr><td>SteadyStateInitial</td><td>Dynamic balance, Steady state initial with guess value</td></tr>

<tr><td>SteadyState</td><td>Steady state balance, Initial guess value</td></tr>
</table>

<p>
The enumeration \"Dynamics\" is used for the mass, energy and momentum balance equations
respectively. The exact meaning for the three balance equations is stated in the following
tables:
</p>

<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
<tr><td colspan=\"3\"><strong>Mass balance</strong> </td></tr>
<tr><td><strong>Dynamics.</strong></td>
    <td><strong>Balance equation</strong></td>
    <td><strong>Initial condition</strong></td></tr>

<tr><td> DynamicFreeInitial</td>
    <td> no restrictions </td>
    <td> no initial conditions </td></tr>

<tr><td> FixedInitial</td>
    <td> no restrictions </td>
    <td> <strong>if</strong> Medium.singleState <strong>then</strong><br>
         &nbsp;&nbsp;no initial condition<br>
         <strong>else</strong> p=p_start </td></tr>

<tr><td> SteadyStateInitial</td>
    <td> no restrictions </td>
    <td> <strong>if</strong> Medium.singleState <strong>then</strong><br>
         &nbsp;&nbsp;no initial condition<br>
         <strong>else</strong> <strong>der</strong>(p)=0 </td></tr>

<tr><td> SteadyState</td>
    <td> <strong>der</strong>(m)=0  </td>
    <td> no initial conditions </td></tr>
</table>

&nbsp;<br>

<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
<tr><td colspan=\"3\"><strong>Energy balance</strong> </td></tr>
<tr><td><strong>Dynamics.</strong></td>
    <td><strong>Balance equation</strong></td>
    <td><strong>Initial condition</strong></td></tr>

<tr><td> DynamicFreeInitial</td>
    <td> no restrictions </td>
    <td> no initial conditions </td></tr>

<tr><td> FixedInitial</td>
    <td> no restrictions </td>
    <td> T=T_start or h=h_start </td></tr>

<tr><td> SteadyStateInitial</td>
    <td> no restrictions </td>
    <td> <strong>der</strong>(T)=0 or <strong>der</strong>(h)=0 </td></tr>

<tr><td> SteadyState</td>
    <td> <strong>der</strong>(U)=0  </td>
    <td> no initial conditions </td></tr>
</table>

&nbsp;<br>

<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
<tr><td colspan=\"3\"><strong>Momentum balance</strong> </td></tr>
<tr><td><strong>Dynamics.</strong></td>
    <td><strong>Balance equation</strong></td>
    <td><strong>Initial condition</strong></td></tr>

<tr><td> DynamicFreeInitial</td>
    <td> no restrictions </td>
    <td> no initial conditions </td></tr>

<tr><td> FixedInitial</td>
    <td> no restrictions </td>
    <td> m_flow = m_flow_start </td></tr>

<tr><td> SteadyStateInitial</td>
    <td> no restrictions </td>
    <td> <strong>der</strong>(m_flow)=0 </td></tr>

<tr><td> SteadyState</td>
    <td> <strong>der</strong>(m_flow)=0 </td>
    <td> no initial conditions </td></tr>
</table>

<p>
In the tables above, the equations are given for one-substance fluids. For multiple-substance
fluids and for trace substances, equivalent equations hold.
</p>

<p>
Medium.singleState is a medium property and defines whether the medium is only
described by one state (+ the mass fractions in case of a multi-substance fluid). In such
a case one initial condition less must be provided. For example, incompressible
media have Medium.singleState = <strong>true</strong>.
</p>

</html>"));

      type PortFlowDirection = enumeration(
        Entering   "Fluid flow is only entering",
        Leaving   "Fluid flow is only leaving",
        Bidirectional   "No restrictions on fluid flow (flow reversal possible)")
        "Enumeration to define whether flow reversal is allowed" annotation (
          Documentation(info="<html>

<p>
Enumeration to define the assumptions on the model for the
direction of fluid flow at a port (to be selected via choices menu):
</p>

<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
<tr><th><strong>PortFlowDirection.</strong></th>
    <th><strong>Meaning</strong></th></tr>

<tr><td>Entering</td>
    <td>Fluid flow is only entering the port from the outside</td></tr>

<tr><td>Leaving</td>
    <td>Fluid flow is only leaving the port to the outside</td></tr>

<tr><td>Bidirectional</td>
    <td>No restrictions on fluid flow (flow reversal possible)</td></tr>
</table>

<p>
The default is \"PortFlowDirection.Bidirectional\". If you are completely sure that
the flow is only in one direction, then the other settings may
make the simulation of your model faster.
</p>

</html>"));

      type ModelStructure = enumeration(
        av_vb   "av_vb: port_a - volume - flow model - volume - port_b",
        a_v_b   "a_v_b: port_a - flow model - volume - flow model - port_b",
        av_b   "av_b: port_a - volume - flow model - port_b",
        a_vb   "a_vb: port_a - flow model - volume - port_b")
        "Enumeration with choices for model structure in distributed pipe model"
        annotation (Documentation(info="<html>

<p>
Enumeration to define the discretization structure of
distributed pipe models according to the staggered grid scheme:
</p>

<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
<tr><th><strong>ModelStructure.</strong></th>
    <th><strong>Meaning</strong></th></tr>

<tr><td>av_vb</td>
    <td>port_a - volume - flow model - volume - port_b</td></tr>

<tr><td>a_v_b</td>
    <td>port_a - flow model - volume - flow model - port_b</td></tr>

<tr><td>av_b</td>
    <td>port_a - volume - flow model - port_b</td></tr>

<tr><td>a_vb</td>
    <td>port_a - flow model - volume - port_b</td></tr>
</table>

<p>
The default is \"ModelStructure.av_vb\", i.e., the distributed pipe
has \"volumes\" at its both ends. The advantage is that connections
of the pipe to flow models (like fittings) lead to the desirable structure
of alternating volume and flow models, which means that no non-linear
algebraic equations occur.
</p>

<p>
Direct connections of distributed pipes with
this option means that two volumes are directly connected together. Due to the
stream concept this means that the pressures of the two connected volumes
are identical, but the temperatures are not set equal
(this corresponds to volumes that are connected together with a very
short distance and it needs some time until different volume temperatures
are equilibrated). Since the pressures of the volumes are identical, the number
of states is reduced and index reduction takes place (which means that medium
equations depending on pressure are differentiated and the number of required
initial conditions is reduced by one).
</p>

<p>
The default option \"av_vb\" cannot be used, if the dynamic pipe is connected to a model with non-differentiable pressure, like a Sources.Boundary_pT with prescribed jumping pressure. The modelStructure can be configured as appropriate in such situations, in order to place a momentum balance between a pressure state of the pipe and a non-differentiable boundary condition
(e.g., if the jumping pressure component is connected to port_a, use model structure
ModelStructure.a_vb).
</p>

</html>"));
      annotation (preferredView="info",
                  Documentation(info="<html>

</html>"));
    end Types;

    package Dissipation
    "Functions for convective heat transfer and pressure loss characteristics"
        extends Modelica.Icons.BasesPackage;
      import PI = Modelica.Constants.pi;
      import REC = Modelica.Fluid.Dissipation.Utilities.Records;
      import TYP = Modelica.Fluid.Dissipation.Utilities.Types;

      package Utilities "Package for utilities (should not be used directly)"
      extends Modelica.Icons.UtilitiesPackage;

        package Functions "Package for utility functions"
          extends Modelica.Icons.FunctionsPackage;

          package General "Package with utility functions"
            extends Modelica.Icons.FunctionsPackage;

            function CubicInterpolation_Re
              "Cubic Hermite spline interpolation of the Reynolds number in transition regime of the Moody diagram (inverse formulation)"
              extends Modelica.Icons.Function;
              import Modelica.Math;
              input Real Re_turbulent "Unused input";
              input SI.ReynoldsNumber Re1 "Boundary Reynolds number for laminar regime";
              input SI.ReynoldsNumber Re2 "Boundary Reynolds number for turbulent regime";
              input Real Delta "Relative roughness";
              input Real lambda2 "Modified friction coefficient (= independent variable)";
              output SI.ReynoldsNumber Re "Interpolated Reynolds number in transition region";
              // Point x1=lg(lambda2(Re1)) with derivative yd1=1 at y1=lg(Re1)
          protected
              Real x1=Math.log10(64*Re1) "Lower abscissa value";
              Real y1=Math.log10(Re1) "Lower ordinate value";
              Real yd1=1 "Left boundary slope";

              // Point x2=lg(lambda2(Re2)) with derivative yd2 at y2≈lg(Re2)
              Real aux1=(0.5/Math.log(10))*5.74*0.9;
              Real aux2=Delta/3.7 + 5.74/Re2^0.9;
              Real aux3=Math.log10(aux2);
              Real L2=0.25*(Re2/aux3)^2;
              Real aux4=2.51/sqrt(L2) + 0.27*Delta;
              Real aux5=-2*sqrt(L2)*Math.log10(aux4);
              Real x2=Math.log10(L2) "Upper abscissa value";
              Real y2=Math.log10(aux5) "Upper ordinate value";
              Real yd2=0.5 + (2.51/Math.log(10))/(aux5*aux4) "Right boundary slope";

              // Constants: Cubic polynomial between x1=lg(lambda2(Re1)) and x2=lg(lambda2(Re2))
              Real diff_x=x2 - x1 "Interval length";
              Real m=(y2 - y1)/diff_x;
              Real c2=(3*m - 2*yd1 - yd2)/diff_x;
              Real c3=(yd1 + yd2 - 2*m)/(diff_x*diff_x);
              Real lambda2_1=64*Re1;
              Real dx=Math.log10(lambda2/lambda2_1);

            algorithm
              // Prefer optimized interpolation formula for Re to avoid cubicHermite function call
              // Re := 10^Modelica.Fluid.Utilities.cubicHermite(Math.log10(lambda2), x1, x2, y1, y2, yd1, yd2);
              Re := Re1*(lambda2/lambda2_1)^(yd1 + dx*(c2 + dx*c3));
              annotation (Inline=false, smoothOrder=5,
                Documentation(info="<html>
<h4>Syntax</h4>
<blockquote><pre>
Re = <strong>CubicInterpolation_Re</strong>(0, Re1, Re2, Delta, lambda2);
</pre></blockquote>
<h4>Description</h4>
<p>
Function <strong>CubicInterpolation_Re</strong>(..) approximates the Reynolds number
<code>Re</code> in the transition regime between laminar and turbulent flow
of the Moody diagram by an inverse formulation of a cubic Hermite spline interpolation. See <a href=\"modelica://Modelica.Fluid.UsersGuide.ComponentDefinition.WallFriction\">
Modelica.Fluid.UsersGuide.ComponentDefinition.WallFriction</a> (especially <strong>Region 2</strong>)
for a detailed explanation.
</p>
</html>",     revisions="<html>
2018-11-20 Stefan Wischhusen: Renamed function from CubicInterpolation_DP to CubicInterpolation_Re.
</html>"));
            end CubicInterpolation_Re;

            function CubicInterpolation_lambda
              "Cubic Hermite spline interpolation of the modified friction coefficient in transition regime of the Moody diagram (direct formulation)"
              extends Modelica.Icons.Function;
              import Modelica.Math;
              input SI.ReynoldsNumber Re "Reynolds number (= independent variable)";
              input SI.ReynoldsNumber Re1 "Boundary Reynolds number for laminar regime";
              input SI.ReynoldsNumber Re2 "Boundary Reynolds number for turbulent regime";
              input Real Delta "Relative roughness";
              output Real lambda2 "Interpolated modified friction coefficient in transition regime";
              // Point x1=lg(Re1) with derivative yd1=1 at y1=lg(lambda2(Re1))
          protected
              Real x1=Math.log10(Re1) "Lower abscissa value";
              Real y1=Math.log10(64*Re1) "Lower ordinate value";
              Real yd1=1 "Left boundary slope";

              // Point x2=lg(Re2) with derivative yd2 at y2=lg(lambda2(Re2))
              Real aux1=(0.5/Math.log(10))*5.74*0.9;
              Real aux2=Delta/3.7 + 5.74/Re2^0.9;
              Real aux3=Math.log10(aux2);
              Real L2=0.25*(Re2/aux3)^2;
              Real aux4=2.51/sqrt(L2) + 0.27*Delta;
              Real aux5=-2*sqrt(L2)*Math.log10(aux4);
              Real x2=Math.log10(Re2) "Upper abscissa value";
              Real y2=Math.log10(L2) "Upper ordinate value";
              Real yd2=2 + 4*aux1/(aux2*aux3*(Re2)^0.9) "Right boundary slope";

              // Constants: Cubic polynomial between x1=lg(Re1) and x2=lg(Re2)
              Real diff_x=x2 - x1 "Interval length";
              Real m=(y2 - y1)/diff_x;
              Real c2=(3*m - 2*yd1 - yd2)/diff_x;
              Real c3=(yd1 + yd2 - 2*m)/(diff_x*diff_x);
              Real dx=Math.log10(Re/Re1);

            algorithm
              // Prefer optimized interpolation formula for lambda2 to avoid cubicHermite function call
              // lambda2 := 10^Modelica.Fluid.Utilities.cubicHermite(Math.log10(Re), x1, x2, y1, y2, yd1, yd2);
              lambda2 := 64*Re1*(Re/Re1)^(yd1 + dx*(c2 + dx*c3));
              annotation (Inline=false, smoothOrder=5,
                Documentation(info="<html>
<h4>Syntax</h4>
<blockquote><pre>
lambda2 = <strong>CubicInterpolation_lambda</strong>(Re, Re1, Re2, Delta);
</pre></blockquote>
<h4>Description</h4>
<p>
Function <strong>CubicInterpolation_lambda</strong>(..) approximates the modified friction coefficient
<code>lambda2</code>=<code>lambda*Re^2</code> in the transition regime between laminar and turbulent flow
of the Moody diagram by a (direct) cubic Hermite spline interpolation.
See <a href=\"modelica://Modelica.Fluid.UsersGuide.ComponentDefinition.WallFriction\">
Modelica.Fluid.UsersGuide.ComponentDefinition.WallFriction</a> (especially <strong>Region 2</strong>)
for a detailed explanation.
</p>
</html>",     revisions="<html>
2018-11-20 Stefan Wischhusen: Renamed function from CubicInterpolation_MFLOW to CubicInterpolation_lambda.
</html>"));
            end CubicInterpolation_lambda;
          end General;
        end Functions;

        package Records "Package for base records"
        extends Modelica.Icons.RecordsPackage;
        end Records;

        package Types "Package for types"
        extends Modelica.Icons.TypesPackage;
        end Types;
      end Utilities;
    annotation (Documentation(info="<html>
<h4>Library description</h4>

<p>
This library contains <strong>convective heat transfer</strong> and <strong>pressure loss</strong> functions written in
Modelica&reg;. Generally the pressure loss calculations are based on incompressible fluids and total pressure difference. For devices with non changing cross sectional area, the calculated total pressure loss is equal to the static pressure difference. Geodetic pressure loss is not considered throughout the library. The functions supplied may be used separately.
</p>

<p>
The library is a non-commercial product of XRG Simulation GmbH.
</p>

<h4>Acknowledgements</h4>

<p>
The following people contributed to the Fluid.Dissipation library (alphabetical list):
J&ouml;rg Eiden, Ole Engel, Nina Peci, Sven Rutkowski, Thorben Vahlenkamp, Stefan
Wischhusen.
</p>

<p>
The development of the Fluid.Dissipation library was founded within the ITEA research
project EuroSysLib-D by German Federal Ministry of Education and Research (promotional
reference 01IS07022B). The project was started in October 2007 and ended in June 2010.
</p>

<p>
Copyright &copy; 2007-2020, Modelica Association and contributors
</p>

<h4>Contact</h4>

XRG Simulation GmbH<br>
Harburger Schlossstra&szlig;e 6-12<br>
21079 Hamburg<br>
Germany<br>
<br>
<a href=\"mailto:info@xrg-simulation.de\">info@xrg-simulation.de</a> </html>"));
    end Dissipation;

    package Utilities
    "Utility models to construct fluid components (should not be used directly)"
      extends Modelica.Icons.UtilitiesPackage;

      function checkBoundary "Check whether boundary definition is correct"
        extends Modelica.Icons.Function;
        input String mediumName;
        input String substanceNames[:] "Names of substances";
        input Boolean singleState;
        input Boolean define_p;
        input Real X_boundary[:];
        input String modelName = "??? boundary ???";
    protected
        Integer nX = size(X_boundary,1);
        String X_str;
      algorithm
        assert(not singleState or singleState and define_p, "
Wrong value of parameter define_p (= false) in model \""     + modelName + "\":
The selected medium \""     + mediumName + "\" has Medium.singleState=true.
Therefore, an boundary density cannot be defined and
define_p = true is required.
");

        for i in 1:nX loop
          assert(X_boundary[i] >= 0.0, "
Wrong boundary mass fractions in medium \""
      + mediumName + "\" in model \"" + modelName + "\":
The boundary value X_boundary("   + String(i) + ") = " + String(
            X_boundary[i]) + "
is negative. It must be positive.
");     end for;

        if nX > 0 and abs(sum(X_boundary) - 1.0) > 1e-10 then
           X_str :="";
           for i in 1:nX loop
              X_str :=X_str + "   X_boundary[" + String(i) + "] = " + String(X_boundary[
              i]) + " \"" + substanceNames[i] + "\"\n";
           end for;
           Modelica.Utilities.Streams.error(
              "The boundary mass fractions in medium \"" + mediumName + "\" in model \"" + modelName + "\"\n" +
              "do not sum up to 1. Instead, sum(X_boundary) = " + String(sum(X_boundary)) + ":\n"
              + X_str);
        end if;
      end checkBoundary;

      function regFun3 "Co-monotonic and C1 smooth regularization function"
        extends Modelica.Icons.Function;

        input Real x "Abscissa value";
        input Real x0 "Lower abscissa value";
        input Real x1 "Upper abscissa value";
        input Real y0 "Ordinate value at lower abscissa value";
        input Real y1 "Ordinate value at upper abscissa value";
        input Real y0d "Derivative at lower abscissa value";
        input Real y1d "Derivative at upper abscissa value";

        output Real y "Ordinate value";
        output Real c
          "Slope of linear section between two cubic polynomials or dummy linear section slope if single cubic is used";

    protected
        Real h0 "Width of interval i=0";
        Real Delta0 "Slope of secant on interval i=0";
        Real xstar "Inflection point of cubic polynomial S0";
        Real mu "Distance of inflection point and left limit x0";
        Real eta "Distance of right limit x1 and inflection point";
        Real omega "Slope of cubic polynomial S0 at inflection point";
        Real rho "Weighting factor of eta and eta_tilde, mu and mu_tilde";
        Real theta0 "Slope metric";
        Real mu_tilde "Distance of start of linear section and left limit x0";
        Real eta_tilde "Distance of right limit x1 and end of linear section";
        Real xi1 "Start of linear section";
        Real xi2 "End of linear section";
        Real a1 "Leading coefficient of cubic on the left";
        Real a2 "Leading coefficient of cubic on the right";
        Real const12 "Integration constant of left cubic, linear section";
        Real const3 "Integration constant of right cubic";
        Real aux01;
        Real aux02;
        Boolean useSingleCubicPolynomial=false
          "Indicate to override further logic and use single cubic";
      algorithm
        // Check arguments: Data point position
        assert(x0 < x1, "regFun3(): Data points not sorted appropriately (x0 = " +
          String(x0) + " > x1 = " + String(x1) + "). Please flip arguments.");
        // Check arguments: Data point derivatives
        if y0d*y1d >= 0 then
          // Derivatives at data points allow co-monotone interpolation, nothing to do
        else
          // Strictly speaking, derivatives at data points do not allow co-monotone interpolation, however, they may be numerically zero so assert this
          assert(abs(y0d)<Modelica.Constants.eps or abs(y1d)<Modelica.Constants.eps, "regFun3(): Derivatives at data points do not allow co-monotone interpolation, as both are non-zero, of opposite sign and have an absolute value larger than machine eps (y0d = " +
          String(y0d) + ", y1d = " + String(y1d) + "). Please correct arguments.");
        end if;

        h0 := x1 - x0;
        Delta0 := (y1 - y0)/h0;

        if abs(Delta0) <= 0 then
          // Points (x0,y0) and (x1,y1) on horizontal line
          // Degenerate case as we cannot fulfill the C1 goal an comonotone behaviour at the same time
          y := y0 + Delta0*(x-x0);     // y == y0 == y1 with additional term to assist automatic differentiation
          c := 0;
        elseif abs(y1d + y0d - 2*Delta0) < 100*Modelica.Constants.eps then
          // Inflection point at +/- infinity, thus S0 is co-monotone and can be returned directly
          y := y0 + (x-x0)*(y0d + (x-x0)/h0*( (-2*y0d-y1d+3*Delta0) + (x-x0)*(y0d+y1d-2*Delta0)/h0));
          // Provide a "dummy linear section slope" as the slope of the cubic at x:=(x0+x1)/2
          aux01 := (x0 + x1)/2;
          c := 3*(y0d + y1d - 2*Delta0)*(aux01 - x0)^2/h0^2 + 2*(-2*y0d - y1d + 3*Delta0)*(aux01 - x0)/h0
             + y0d;
        else
          // Points (x0,y0) and (x1,y1) not on horizontal line and inflection point of S0 not at +/- infinity
          // Do actual interpolation
          xstar := 1/3*(-3*x0*y0d - 3*x0*y1d + 6*x0*Delta0 - 2*h0*y0d - h0*y1d + 3*h0*
            Delta0)/(-y0d - y1d + 2*Delta0);
          mu := xstar - x0;
          eta := x1 - xstar;
          omega := 3*(y0d + y1d - 2*Delta0)*(xstar - x0)^2/h0^2 + 2*(-2*y0d - y1d + 3*
            Delta0)*(xstar - x0)/h0 + y0d;

          aux01 := 0.25*sign(Delta0)*min(abs(omega), abs(Delta0))
            "Slope c if not using plain cubic S0";
          if abs(y0d - y1d) <= 100*Modelica.Constants.eps then
            // y0 == y1 (value and sign equal) -> resolve indefinite 0/0
            aux02 := y0d;
            if y1 > y0 + y0d*(x1 - x0) then
              // If y1 is above the linear extension through (x0/y0)
              // with slope y0d (when slopes are identical)
              //  -> then always used single cubic polynomial
              useSingleCubicPolynomial := true;
            end if;
          elseif abs(y1d + y0d - 2*Delta0) < 100*Modelica.Constants.eps then
            // (y1d+y0d-2*Delta0) approximately 0 -> avoid division by 0
            aux02 := (6*Delta0*(y1d + y0d - 3/2*Delta0) - y1d*y0d - y1d^2 - y0d^2)*(
              if (y1d + y0d - 2*Delta0) >= 0 then 1 else -1)*Modelica.Constants.inf;
          else
            // Okay, no guarding necessary
            aux02 := (6*Delta0*(y1d + y0d - 3/2*Delta0) - y1d*y0d - y1d^2 - y0d^2)/(3*
              (y1d + y0d - 2*Delta0));
          end if;

          //aux02 := -1/3*(y0d^2+y0d*y1d-6*y0d*Delta0+y1d^2-6*y1d*Delta0+9*Delta0^2)/(y0d+y1d-2*Delta0);
          //aux02 := -1/3*(6*y1d*y0*x1+y0d*y1d*x1^2-6*y0d*x0*y0+y0d^2*x0^2+y0d^2*x1^2+y1d^2*x1^2+y1d^2*x0^2-2*y0d*x0*y1d*x1-2*x0*y0d^2*x1+y0d*y1d*x0^2+6*y0d*x0*y1-6*y0d*y1*x1+6*y0d*y0*x1-2*x0*y1d^2*x1-6*y1d*y1*x1+6*y1d*x0*y1-6*y1d*x0*y0-18*y1*y0+9*y1^2+9*y0^2)/(y0d*x1^2-2*x0*y0d*x1+y1d*x1^2-2*x0*y1d*x1-2*y1*x1+2*y0*x1+y0d*x0^2+y1d*x0^2+2*x0*y1-2*x0*y0);

          // Test criteria (also used to avoid saddle points that lead to integrator contraction):
          //
          //  1. Cubic is not monotonic (from Gasparo Morandi)
          //       ((mu > 0) and (eta < h0) and (Delta0*omega <= 0))
          //
          //  2. Cubic may be monotonic but the linear section slope c is either too close
          //     to zero or the end point of the linear section is left of the start point
          //     Note however, that the suggested slope has to have the same sign as Delta0.
          //       (abs(aux01)<abs(aux02) and aux02*Delta0>=0)
          //
          //  3. Cubic may be monotonic but the resulting slope in the linear section
          //     is too close to zero (less than 1/10 of Delta0).
          //       (c < Delta0 / 10)
          //
          if (((mu > 0) and (eta < h0) and (Delta0*omega <= 0)) or (abs(aux01) < abs(
              aux02) and aux02*Delta0 >= 0) or (abs(aux01) < abs(0.1*Delta0))) and
              not useSingleCubicPolynomial then
            // NOT monotonic using plain cubic S0, use piecewise function S0 tilde instead
            c := aux01;
            // Avoid saddle points that are co-monotonic but lead to integrator contraction
            if abs(c) < abs(aux02) and aux02*Delta0 >= 0 then
              c := aux02;
            end if;
            if abs(c) < abs(0.1*Delta0) then
              c := 0.1*Delta0;
            end if;
            theta0 := (y0d*mu + y1d*eta)/h0;
            if abs(theta0 - c) < 1e-6 then
              // Slightly reduce c in order to avoid ill-posed problem
              c := (1 - 1e-6)*theta0;
            end if;
            rho := 3*(Delta0 - c)/(theta0 - c);
            mu_tilde := rho*mu;
            eta_tilde := rho*eta;
            xi1 := x0 + mu_tilde;
            xi2 := x1 - eta_tilde;
            a1 := (y0d - c)/max(mu_tilde^2, 100*Modelica.Constants.eps);
            a2 := (y1d - c)/max(eta_tilde^2, 100*Modelica.Constants.eps);
            const12 := y0 - a1/3*(x0 - xi1)^3 - c*x0;
            const3 := y1 - a2/3*(x1 - xi2)^3 - c*x1;
            // Do actual interpolation
            if (x < xi1) then
              y := a1/3*(x - xi1)^3 + c*x + const12;
            elseif (x < xi2) then
              y := c*x + const12;
            else
              y := a2/3*(x - xi2)^3 + c*x + const3;
            end if;
          else
            // Cubic S0 is monotonic, use it as is
            y := y0 + (x-x0)*(y0d + (x-x0)/h0*( (-2*y0d-y1d+3*Delta0) + (x-x0)*(y0d+y1d-2*Delta0)/h0));
            // Provide a "dummy linear section slope" as the slope of the cubic at x:=(x0+x1)/2
            aux01 := (x0 + x1)/2;
            c := 3*(y0d + y1d - 2*Delta0)*(aux01 - x0)^2/h0^2 + 2*(-2*y0d - y1d + 3*Delta0)*(aux01 - x0)/h0
               + y0d;
          end if;
        end if;

        annotation (smoothOrder=1, Documentation(revisions="<html>
<ul>
<li><em>May 2008</em> by <a href=\"mailto:Michael.Sielemann@dlr.de\">Michael Sielemann</a>:<br>Designed and implemented.</li>
<li><em>February 2011</em> by <a href=\"mailto:Michael.Sielemann@dlr.de\">Michael Sielemann</a>:<br>If the inflection point of the cubic S0 was at +/- infinity, the test criteria of <em>[Gasparo and Morandi, 1991]</em> result in division by zero. This case is handled properly now.</li>
<li><em>March 2013</em> by <a href=\"mailto:Michael.Sielemann@dlr.de\">Michael Sielemann</a>:<br>If the arguments prescribed a degenerate case with points <code>(x0,y0)</code> and <code>(x1,y1)</code> on horizontal line, then return value <code>c</code> was undefined. This was corrected. Furthermore, an additional term was included for the computation of <code>y</code> in this case to assist automatic differentiation.</li>
</ul>
</html>",       info="<html>
<p>
Approximates a function in a region between <code>x0</code> and <code>x1</code>
such that
</p>
<ul>
<li> The overall function is continuous with a
     continuous first derivative everywhere.</li>
<li> The function is co-monotone with the given
     data points.</li>
</ul>
<p>
In this region, a continuation is constructed from the given points
<code>(x0, y0)</code>, <code>(x1, y1)</code> and the respective
derivatives. For this purpose, a single polynomial of third order or two
cubic polynomials with a linear section in between are used <em>[Gasparo
and Morandi, 1991]</em>. This algorithm was extended with two additional
conditions to avoid saddle points with zero/infinite derivative that lead to
integrator step size reduction to zero.
</p>
<p>
This function was developed for pressure loss correlations properly
addressing the static head on top of the established requirements
for monotonicity and smoothness. In this case, the present function
allows to implement the exact solution in the limit of
<code>x1-x0 -> 0</code> or <code>y1-y0 -> 0</code>.
</p>
<p>
Typical screenshots for two different configurations
are shown below. The first one illustrates five different settings of <code>xi</code> and <code>yid</code>:
</p>
<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/Utilities/regFun3_a.png\"
      alt=\"regFun3_a.png\">
</p>
<p>
The second graph shows the continuous derivative of this regularization function:
</p>
<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/Utilities/regFun3_b.png\"
     alt=\"regFun3_a.png\">
</p>

<p>
<strong>Literature</strong>
</p>

<dl>
<dt> Gasparo M. G. and Morandi R. (1991):</dt>
<dd> <strong>Piecewise cubic monotone interpolation with assigned slopes</strong>.
     Computing, Vol. 46, Issue 4, December 1991, pp. 355 - 365.</dd>
</dl>
</html>"));
      end regFun3;

      function cubicHermite_withDerivative
        "Evaluate a cubic Hermite spline, return value and derivative"
        extends Modelica.Icons.Function;

        input Real x "Abscissa value";
        input Real x1 "Lower abscissa value";
        input Real x2 "Upper abscissa value";
        input Real y1 "Lower ordinate value";
        input Real y2 "Upper ordinate value";
        input Real y1d "Lower gradient";
        input Real y2d "Upper gradient";
        output Real y "Interpolated ordinate value";
        output Real dy_dx "Derivative dy/dx at abscissa value x";
    protected
        Real h "Distance between x1 and x2";
        Real t "Abscissa scaled with h, i.e., t=[0..1] within x=[x1..x2]";
        Real h00 "Basis function 00 of cubic Hermite spline";
        Real h10 "Basis function 10 of cubic Hermite spline";
        Real h01 "Basis function 01 of cubic Hermite spline";
        Real h11 "Basis function 11 of cubic Hermite spline";

        Real h00d "d/dt h00";
        Real h10d "d/dt h10";
        Real h01d "d/dt h01";
        Real h11d "d/dt h11";

        Real aux3 "t cube";
        Real aux2 "t square";
      algorithm
        h := x2 - x1;
        if abs(h)>0 then
          // Regular case
          t := (x - x1)/h;

          aux3 :=t^3;
          aux2 :=t^2;

          h00 := 2*aux3 - 3*aux2 + 1;
          h10 := aux3 - 2*aux2 + t;
          h01 := -2*aux3 + 3*aux2;
          h11 := aux3 - aux2;

          h00d := 6*(aux2 - t);
          h10d := 3*aux2 - 4*t + 1;
          h01d := 6*(t - aux2);
          h11d := 3*aux2 - 2*t;

          y := y1*h00 + h*y1d*h10 + y2*h01 + h*y2d*h11;
          dy_dx := y1*h00d/h + y1d*h10d + y2*h01d/h + y2d*h11d;
        else
          // Degenerate case, x1 and x2 are identical, return step function
          y := (y1 + y2)/2;
          dy_dx := sign(y2 - y1)*Modelica.Constants.inf;
        end if;
        annotation(smoothOrder=3, Documentation(revisions="<html>
<ul>
<li><em>May 2008</em>
    by <a href=\"mailto:Michael.Sielemann@dlr.de\">Michael Sielemann</a>:<br>
    Designed and implemented.</li>
</ul>
</html>"));
      end cubicHermite_withDerivative;
      annotation (Documentation(info="<html>

</html>"));
    end Utilities;
  annotation (Icon(graphics={
          Polygon(points={{-70,26},{68,-44},{68,26},{2,-10},{-70,-42},{-70,26}}),
          Line(points={{2,42},{2,-10}}),
          Rectangle(
            extent={{-18,50},{22,42}},
            fillPattern=FillPattern.Solid)}), preferredView="info",
    Documentation(info="<html>
<p>
Library <strong>Modelica.Fluid</strong> is a <strong>free</strong> Modelica package providing components for
<strong>1-dimensional thermo-fluid flow</strong> in networks of vessels, pipes, fluid machines, valves and fittings.
A unique feature is that the component equations and the media models
as well as pressure loss and heat transfer correlations are decoupled from each other.
All components are implemented such that they can be used for
media from the Modelica.Media library. This means especially that an
incompressible or compressible medium, a single or a multiple
substance medium with one or more phases might be used.
</p>

<p>
In the next figure, several features of the library are demonstrated with
a simple heating system with a closed flow cycle. By just changing one configuration parameter in the system object the equations are changed between steady-state and dynamic simulation with fixed or steady-state initial conditions.
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Fluid/HeatingSystem.png\" border=\"1\"
     alt=\"HeatingSystem.png\">
</p>

<p>
With respect to previous versions, the design
of the connectors has been changed in a non-backward compatible way,
using the recently developed concept
of stream connectors that results in much more reliable simulations
(see also <a href=\"modelica://Modelica/Resources/Documentation/Fluid/Stream-Connectors-Overview-Rationale.pdf\">Stream-Connectors-Overview-Rationale.pdf</a>).
This extension was included in Modelica 3.1.
</p>

<p>
The following parts are useful, when newly starting with this library:
</p>
<ul>
<li> <a href=\"modelica://Modelica.Fluid.UsersGuide\">Modelica.Fluid.UsersGuide</a>.</li>
<li> <a href=\"modelica://Modelica.Fluid.UsersGuide.ReleaseNotes\">Modelica.Fluid.UsersGuide.ReleaseNotes</a>
     summarizes the changes of the library releases.</li>
<li> <a href=\"modelica://Modelica.Fluid.Examples\">Modelica.Fluid.Examples</a>
     contains examples that demonstrate the usage of this library.</li>
</ul>
<p>
Copyright &copy; 2002-2020, Modelica Association and contributors
</p>
</html>"));
  end Fluid;

  package Media "Library of media property models"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;
    import Cv = Modelica.Units.Conversions;

  package Interfaces "Interfaces for media models"
    extends Modelica.Icons.InterfacesPackage;

    partial package PartialMedium
      "Partial medium properties (base package of all media packages)"
      extends Modelica.Media.Interfaces.Types;
      extends Modelica.Icons.MaterialPropertiesPackage;

      // Constants to be set in Medium
      constant Modelica.Media.Interfaces.Choices.IndependentVariables
        ThermoStates "Enumeration type for independent variables";
      constant String mediumName="unusablePartialMedium" "Name of the medium";
      constant String substanceNames[:]={mediumName}
        "Names of the mixture substances. Set substanceNames={mediumName} if only one substance.";
      constant String extraPropertiesNames[:]=fill("", 0)
        "Names of the additional (extra) transported properties. Set extraPropertiesNames=fill(\"\",0) if unused";
      constant Boolean singleState
        "= true, if u and d are not a function of pressure";
      constant Boolean reducedX=true
        "= true if medium contains the equation sum(X) = 1.0; set reducedX=true if only one substance (see docu for details)";
      constant Boolean fixedX=false
        "= true if medium contains the equation X = reference_X";
      constant AbsolutePressure reference_p=101325
        "Reference pressure of Medium: default 1 atmosphere";
      constant Temperature reference_T=298.15
        "Reference temperature of Medium: default 25 deg Celsius";
      constant MassFraction reference_X[nX]=fill(1/nX, nX)
        "Default mass fractions of medium";
      constant AbsolutePressure p_default=101325
        "Default value for pressure of medium (for initialization)";
      constant Temperature T_default=Modelica.Units.Conversions.from_degC(20)
        "Default value for temperature of medium (for initialization)";
      constant SpecificEnthalpy h_default=specificEnthalpy_pTX(
              p_default,
              T_default,
              X_default)
        "Default value for specific enthalpy of medium (for initialization)";
      constant MassFraction X_default[nX]=reference_X
        "Default value for mass fractions of medium (for initialization)";
      constant ExtraProperty C_default[nC]=fill(0, nC)
        "Default value for trace substances of medium (for initialization)";

      final constant Integer nS=size(substanceNames, 1) "Number of substances";
      constant Integer nX=nS "Number of mass fractions";
      constant Integer nXi=if fixedX then 0 else if reducedX then nS - 1 else nS
        "Number of structurally independent mass fractions (see docu for details)";

      final constant Integer nC=size(extraPropertiesNames, 1)
        "Number of extra (outside of standard mass-balance) transported properties";
      constant Real C_nominal[nC](min=fill(Modelica.Constants.eps, nC)) = 1.0e-6*
        ones(nC) "Default for the nominal values for the extra properties";
      replaceable record FluidConstants =
          Modelica.Media.Interfaces.Types.Basic.FluidConstants
        "Critical, triple, molecular and other standard data of fluid";

      replaceable record ThermodynamicState
        "Minimal variable set that is available as input argument to every medium function"
        extends Modelica.Icons.Record;
      end ThermodynamicState;

      replaceable partial model BaseProperties
        "Base properties (p, d, T, h, u, R_s, MM and, if applicable, X and Xi) of a medium"
        InputAbsolutePressure p "Absolute pressure of medium";
        InputMassFraction[nXi] Xi(start=reference_X[1:nXi])
          "Structurally independent mass fractions";
        InputSpecificEnthalpy h "Specific enthalpy of medium";
        Density d "Density of medium";
        Temperature T "Temperature of medium";
        MassFraction[nX] X(start=reference_X)
          "Mass fractions (= (component mass)/total mass  m_i/m)";
        SpecificInternalEnergy u "Specific internal energy of medium";
        SpecificHeatCapacity R_s "Gas constant (of mixture if applicable)";
        MolarMass MM "Molar mass (of mixture or single fluid)";
        ThermodynamicState state
          "Thermodynamic state record for optional functions";
        parameter Boolean preferredMediumStates=false
          "= true if StateSelect.prefer shall be used for the independent property variables of the medium"
          annotation (Evaluate=true, Dialog(tab="Advanced"));
        parameter Boolean standardOrderComponents=true
          "If true, and reducedX = true, the last element of X will be computed from the other ones";
        Modelica.Units.NonSI.Temperature_degC T_degC=
            Modelica.Units.Conversions.to_degC(T)
          "Temperature of medium in [degC]";
        Modelica.Units.NonSI.Pressure_bar p_bar=
            Modelica.Units.Conversions.to_bar(p)
          "Absolute pressure of medium in [bar]";

        // Local connector definition, used for equation balancing check
        connector InputAbsolutePressure = input SI.AbsolutePressure
          "Pressure as input signal connector";
        connector InputSpecificEnthalpy = input SI.SpecificEnthalpy
          "Specific enthalpy as input signal connector";
        connector InputMassFraction = input SI.MassFraction
          "Mass fraction as input signal connector";

      equation
        if standardOrderComponents then
          Xi = X[1:nXi];

          if fixedX then
            X = reference_X;
          end if;
          if reducedX and not fixedX then
            X[nX] = 1 - sum(Xi);
          end if;
          for i in 1:nX loop
            assert(X[i] >= -1.e-5 and X[i] <= 1 + 1.e-5, "Mass fraction X[" +
              String(i) + "] = " + String(X[i]) + "of substance " +
              substanceNames[i] + "\nof medium " + mediumName +
              " is not in the range 0..1");
          end for;

        end if;

        assert(p >= 0.0, "Pressure (= " + String(p) + " Pa) of medium \"" +
          mediumName + "\" is negative\n(Temperature = " + String(T) + " K)");
        annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={Rectangle(
                extent={{-100,100},{100,-100}},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid,
                lineColor={0,0,255}), Text(
                extent={{-152,164},{152,102}},
                textString="%name",
                textColor={0,0,255})}), Documentation(info="<html>
<p>
Model <strong>BaseProperties</strong> is a model within package <strong>PartialMedium</strong>
and contains the <strong>declarations</strong> of the minimum number of
variables that every medium model is supposed to support.
A specific medium inherits from model <strong>BaseProperties</strong> and provides
the equations for the basic properties.</p>
<p>
The BaseProperties model contains the following <strong>7+nXi variables</strong>
(nXi is the number of independent mass fractions defined in package
PartialMedium):
</p>
<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
  <tr><td><strong>Variable</strong></td>
      <td><strong>Unit</strong></td>
      <td><strong>Description</strong></td></tr>
  <tr><td>T</td>
      <td>K</td>
      <td>Temperature</td></tr>
  <tr><td>p</td>
      <td>Pa</td>
      <td>Absolute pressure</td></tr>
  <tr><td>d</td>
      <td>kg/m3</td>
      <td>Density</td></tr>
  <tr><td>h</td>
      <td>J/kg</td>
      <td>Specific enthalpy</td></tr>
  <tr><td>u</td>
      <td>J/kg</td>
      <td>Specific internal energy</td></tr>
  <tr><td>Xi[nXi]</td>
      <td>kg/kg</td>
      <td>Structurally independent mass fractions</td></tr>
  <tr><td>R_s</td>
      <td>J/(kg.K)</td>
      <td>Specific gas constant (of mixture if applicable)</td></tr>
  <tr><td>MM</td>
      <td>kg/mol</td>
      <td>Molar mass</td></tr>
</table>
<p>
In order to implement an actual medium model, one can extend from this
base model and add <strong>5 equations</strong> that provide relations among
these variables. Equations will also have to be added in order to
set all the variables within the ThermodynamicState record state.</p>
<p>
If standardOrderComponents=true, the full composition vector X[nX]
is determined by the equations contained in this base class, depending
on the independent mass fraction vector Xi[nXi].</p>
<p>Additional <strong>2 + nXi</strong> equations will have to be provided
when using the BaseProperties model, in order to fully specify the
thermodynamic conditions. The input connector qualifier applied to
p, h, and nXi indirectly declares the number of missing equations,
permitting advanced equation balance checking by Modelica tools.
Please note that this doesn't mean that the additional equations
should be connection equations, nor that exactly those variables
should be supplied, in order to complete the model.
For further information, see the <a href=\"modelica://Modelica.Media.UsersGuide\">Modelica.Media User's guide</a>, and
<a href=\"https://specification.modelica.org/v3.4/Ch4.html#balanced-models\">Section 4.7 (Balanced Models) of the Modelica 3.4 specification</a>.</p>
</html>"));
      end BaseProperties;

      replaceable partial function setState_pTX
        "Return thermodynamic state as function of p, T and composition X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input MassFraction X[:]=reference_X "Mass fractions";
        output ThermodynamicState state "Thermodynamic state record";
      end setState_pTX;

      replaceable partial function setState_phX
        "Return thermodynamic state as function of p, h and composition X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input MassFraction X[:]=reference_X "Mass fractions";
        output ThermodynamicState state "Thermodynamic state record";
      end setState_phX;

      replaceable partial function setState_psX
        "Return thermodynamic state as function of p, s and composition X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input MassFraction X[:]=reference_X "Mass fractions";
        output ThermodynamicState state "Thermodynamic state record";
      end setState_psX;

      replaceable partial function setState_dTX
        "Return thermodynamic state as function of d, T and composition X or Xi"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        input MassFraction X[:]=reference_X "Mass fractions";
        output ThermodynamicState state "Thermodynamic state record";
      end setState_dTX;

      replaceable partial function setSmoothState
        "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
        extends Modelica.Icons.Function;
        input Real x "m_flow or dp";
        input ThermodynamicState state_a "Thermodynamic state if x > 0";
        input ThermodynamicState state_b "Thermodynamic state if x < 0";
        input Real x_small(min=0)
          "Smooth transition in the region -x_small < x < x_small";
        output ThermodynamicState state
          "Smooth thermodynamic state for all x (continuous and differentiable)";
        annotation (Documentation(info="<html>
<p>
This function is used to approximate the equation
</p>
<blockquote><pre>
state = <strong>if</strong> x &gt; 0 <strong>then</strong> state_a <strong>else</strong> state_b;
</pre></blockquote>

<p>
by a smooth characteristic, so that the expression is continuous and differentiable:
</p>

<blockquote><pre>
state := <strong>smooth</strong>(1, <strong>if</strong> x &gt;  x_small <strong>then</strong> state_a <strong>else</strong>
                   <strong>if</strong> x &lt; -x_small <strong>then</strong> state_b <strong>else</strong> f(state_a, state_b));
</pre></blockquote>

<p>
This is performed by applying function <strong>Media.Common.smoothStep</strong>(..)
on every element of the thermodynamic state record.
</p>

<p>
If <strong>mass fractions</strong> X[:] are approximated with this function then this can be performed
for all <strong>nX</strong> mass fractions, instead of applying it for nX-1 mass fractions and computing
the last one by the mass fraction constraint sum(X)=1. The reason is that the approximating function has the
property that sum(state.X) = 1, provided sum(state_a.X) = sum(state_b.X) = 1.
This can be shown by evaluating the approximating function in the abs(x) &lt; x_small
region (otherwise state.X is either state_a.X or state_b.X):
</p>

<blockquote><pre>
X[1]  = smoothStep(x, X_a[1] , X_b[1] , x_small);
X[2]  = smoothStep(x, X_a[2] , X_b[2] , x_small);
   ...
X[nX] = smoothStep(x, X_a[nX], X_b[nX], x_small);
</pre></blockquote>

<p>
or
</p>

<blockquote><pre>
X[1]  = c*(X_a[1]  - X_b[1])  + (X_a[1]  + X_b[1])/2
X[2]  = c*(X_a[2]  - X_b[2])  + (X_a[2]  + X_b[2])/2;
   ...
X[nX] = c*(X_a[nX] - X_b[nX]) + (X_a[nX] + X_b[nX])/2;
c     = (x/x_small)*((x/x_small)^2 - 3)/4
</pre></blockquote>

<p>
Summing all mass fractions together results in
</p>

<blockquote><pre>
sum(X) = c*(sum(X_a) - sum(X_b)) + (sum(X_a) + sum(X_b))/2
       = c*(1 - 1) + (1 + 1)/2
       = 1
</pre></blockquote>

</html>"));
      end setSmoothState;

      replaceable partial function dynamicViscosity "Return dynamic viscosity"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output DynamicViscosity eta "Dynamic viscosity";
      end dynamicViscosity;

      replaceable partial function thermalConductivity
        "Return thermal conductivity"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output ThermalConductivity lambda "Thermal conductivity";
      end thermalConductivity;

      replaceable function prandtlNumber "Return the Prandtl number"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output PrandtlNumber Pr "Prandtl number";
      algorithm
        Pr := dynamicViscosity(state)*specificHeatCapacityCp(state)/
          thermalConductivity(state);
      end prandtlNumber;

      replaceable partial function pressure "Return pressure"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output AbsolutePressure p "Pressure";
      end pressure;

      replaceable partial function temperature "Return temperature"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output Temperature T "Temperature";
      end temperature;

      replaceable partial function density "Return density"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output Density d "Density";
      end density;

      replaceable partial function specificEnthalpy "Return specific enthalpy"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output SpecificEnthalpy h "Specific enthalpy";
      end specificEnthalpy;

      replaceable partial function specificInternalEnergy
        "Return specific internal energy"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output SpecificEnergy u "Specific internal energy";
      end specificInternalEnergy;

      replaceable partial function specificEntropy "Return specific entropy"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output SpecificEntropy s "Specific entropy";
      end specificEntropy;

      replaceable partial function specificGibbsEnergy
        "Return specific Gibbs energy"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output SpecificEnergy g "Specific Gibbs energy";
      end specificGibbsEnergy;

      replaceable partial function specificHelmholtzEnergy
        "Return specific Helmholtz energy"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output SpecificEnergy f "Specific Helmholtz energy";
      end specificHelmholtzEnergy;

      replaceable partial function specificHeatCapacityCp
        "Return specific heat capacity at constant pressure"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output SpecificHeatCapacity cp
          "Specific heat capacity at constant pressure";
      end specificHeatCapacityCp;

      function heatCapacity_cp = specificHeatCapacityCp
        "Alias for deprecated name";

      replaceable partial function specificHeatCapacityCv
        "Return specific heat capacity at constant volume"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output SpecificHeatCapacity cv
          "Specific heat capacity at constant volume";
      end specificHeatCapacityCv;

      function heatCapacity_cv = specificHeatCapacityCv
        "Alias for deprecated name";

      replaceable partial function isentropicExponent
        "Return isentropic exponent"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output IsentropicExponent gamma "Isentropic exponent";
      end isentropicExponent;

      replaceable partial function isentropicEnthalpy
        "Return isentropic enthalpy"
        extends Modelica.Icons.Function;
        input AbsolutePressure p_downstream "Downstream pressure";
        input ThermodynamicState refState "Reference state for entropy";
        output SpecificEnthalpy h_is "Isentropic enthalpy";
        annotation (Documentation(info="<html>
<p>
This function computes an isentropic state transformation:
</p>
<ol>
<li> A medium is in a particular state, refState.</li>
<li> The enthalpy at another state (h_is) shall be computed
     under the assumption that the state transformation from refState to h_is
     is performed with a change of specific entropy ds = 0 and the pressure of state h_is
     is p_downstream and the composition X upstream and downstream is assumed to be the same.</li>
</ol>

</html>"));
      end isentropicEnthalpy;

      replaceable partial function velocityOfSound "Return velocity of sound"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output VelocityOfSound a "Velocity of sound";
      end velocityOfSound;

      replaceable partial function isobaricExpansionCoefficient
        "Return overall the isobaric expansion coefficient beta"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output IsobaricExpansionCoefficient beta "Isobaric expansion coefficient";
        annotation (Documentation(info="<html>
<blockquote><pre>
beta is defined as  1/v * der(v,T), with v = 1/d, at constant pressure p.
</pre></blockquote>
</html>"));
      end isobaricExpansionCoefficient;

      function beta = isobaricExpansionCoefficient
        "Alias for isobaricExpansionCoefficient for user convenience";

      replaceable partial function isothermalCompressibility
        "Return overall the isothermal compressibility factor"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output SI.IsothermalCompressibility kappa "Isothermal compressibility";
        annotation (Documentation(info="<html>
<blockquote><pre>

kappa is defined as - 1/v * der(v,p), with v = 1/d at constant temperature T.

</pre></blockquote>
</html>"));
      end isothermalCompressibility;

      function kappa = isothermalCompressibility
        "Alias of isothermalCompressibility for user convenience";

      // explicit derivative functions for finite element models
      replaceable partial function density_derp_h
        "Return density derivative w.r.t. pressure at const specific enthalpy"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output DerDensityByPressure ddph "Density derivative w.r.t. pressure";
      end density_derp_h;

      replaceable partial function density_derh_p
        "Return density derivative w.r.t. specific enthalpy at constant pressure"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output DerDensityByEnthalpy ddhp
          "Density derivative w.r.t. specific enthalpy";
      end density_derh_p;

      replaceable partial function density_derp_T
        "Return density derivative w.r.t. pressure at const temperature"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output DerDensityByPressure ddpT "Density derivative w.r.t. pressure";
      end density_derp_T;

      replaceable partial function density_derT_p
        "Return density derivative w.r.t. temperature at constant pressure"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output DerDensityByTemperature ddTp
          "Density derivative w.r.t. temperature";
      end density_derT_p;

      replaceable partial function density_derX
        "Return density derivative w.r.t. mass fraction"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output Density[nX] dddX "Derivative of density w.r.t. mass fraction";
      end density_derX;

      replaceable partial function molarMass
        "Return the molar mass of the medium"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output MolarMass MM "Mixture molar mass";
      end molarMass;

      replaceable function specificEnthalpy_pTX
        "Return specific enthalpy from p, T, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input MassFraction X[:]=reference_X "Mass fractions";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := specificEnthalpy(setState_pTX(
                p,
                T,
                X));
        annotation (inverse(T=temperature_phX(
                      p,
                      h,
                      X)));
      end specificEnthalpy_pTX;

      replaceable function specificEntropy_pTX
        "Return specific enthalpy from p, T, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input MassFraction X[:]=reference_X "Mass fractions";
        output SpecificEntropy s "Specific entropy";
      algorithm
        s := specificEntropy(setState_pTX(
                p,
                T,
                X));

        annotation (inverse(T=temperature_psX(
                      p,
                      s,
                      X)));
      end specificEntropy_pTX;

      replaceable function density_pTX "Return density from p, T, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input MassFraction X[:] "Mass fractions";
        output Density d "Density";
      algorithm
        d := density(setState_pTX(
                p,
                T,
                X));
      end density_pTX;

      replaceable function temperature_phX
        "Return temperature from p, h, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input MassFraction X[:]=reference_X "Mass fractions";
        output Temperature T "Temperature";
      algorithm
        T := temperature(setState_phX(
                p,
                h,
                X));
      end temperature_phX;

      replaceable function density_phX "Return density from p, h, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input MassFraction X[:]=reference_X "Mass fractions";
        output Density d "Density";
      algorithm
        d := density(setState_phX(
                p,
                h,
                X));
      end density_phX;

      replaceable function temperature_psX
        "Return temperature from p,s, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input MassFraction X[:]=reference_X "Mass fractions";
        output Temperature T "Temperature";
      algorithm
        T := temperature(setState_psX(
                p,
                s,
                X));
        annotation (inverse(s=specificEntropy_pTX(
                      p,
                      T,
                      X)));
      end temperature_psX;

      replaceable function density_psX "Return density from p, s, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input MassFraction X[:]=reference_X "Mass fractions";
        output Density d "Density";
      algorithm
        d := density(setState_psX(
                p,
                s,
                X));
      end density_psX;

      replaceable function specificEnthalpy_psX
        "Return specific enthalpy from p, s, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input MassFraction X[:]=reference_X "Mass fractions";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := specificEnthalpy(setState_psX(
                p,
                s,
                X));
      end specificEnthalpy_psX;

      type MassFlowRate = SI.MassFlowRate (
          quantity="MassFlowRate." + mediumName,
          min=-1.0e5,
          max=1.e5) "Type for mass flow rate with medium specific attributes";

      annotation (Documentation(info="<html>
<p>
<strong>PartialMedium</strong> is a package and contains all <strong>declarations</strong> for
a medium. This means that constants, models, and functions
are defined that every medium is supposed to support
(some of them are optional). A medium package
inherits from <strong>PartialMedium</strong> and provides the
equations for the medium. The details of this package
are described in
<a href=\"modelica://Modelica.Media.UsersGuide\">Modelica.Media.UsersGuide</a>.
</p>
</html>",   revisions="<html>

</html>"));
    end PartialMedium;

    partial package PartialPureSubstance
      "Base class for pure substances of one chemical substance"
      extends PartialMedium(final reducedX=true, final fixedX=true);

      replaceable function setState_pT "Return thermodynamic state from p and T"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_pTX(
                p,
                T,
                fill(0, 0));
      end setState_pT;

      replaceable function setState_ph "Return thermodynamic state from p and h"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_phX(
                p,
                h,
                fill(0, 0));
      end setState_ph;

      replaceable function setState_ps "Return thermodynamic state from p and s"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_psX(
                p,
                s,
                fill(0, 0));
      end setState_ps;

      replaceable function setState_dT "Return thermodynamic state from d and T"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_dTX(
                d,
                T,
                fill(0, 0));
      end setState_dT;

      replaceable function density_ph "Return density from p and h"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        output Density d "Density";
      algorithm
        d := density_phX(
                p,
                h,
                fill(0, 0));
      end density_ph;

      replaceable function temperature_ph "Return temperature from p and h"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        output Temperature T "Temperature";
      algorithm
        T := temperature_phX(
                p,
                h,
                fill(0, 0));
      end temperature_ph;

      replaceable function pressure_dT "Return pressure from d and T"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        output AbsolutePressure p "Pressure";
      algorithm
        p := pressure(setState_dTX(
                d,
                T,
                fill(0, 0)));
      end pressure_dT;

      replaceable function specificEnthalpy_dT
        "Return specific enthalpy from d and T"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := specificEnthalpy(setState_dTX(
                d,
                T,
                fill(0, 0)));
      end specificEnthalpy_dT;

      replaceable function specificEnthalpy_ps
        "Return specific enthalpy from p and s"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := specificEnthalpy_psX(
                p,
                s,
                fill(0, 0));
      end specificEnthalpy_ps;

      replaceable function temperature_ps "Return temperature from p and s"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        output Temperature T "Temperature";
      algorithm
        T := temperature_psX(
                p,
                s,
                fill(0, 0));
      end temperature_ps;

      replaceable function density_ps "Return density from p and s"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        output Density d "Density";
      algorithm
        d := density_psX(
                p,
                s,
                fill(0, 0));
      end density_ps;

      replaceable function specificEnthalpy_pT
        "Return specific enthalpy from p and T"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := specificEnthalpy_pTX(
                p,
                T,
                fill(0, 0));
      end specificEnthalpy_pT;

      replaceable function density_pT "Return density from p and T"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        output Density d "Density";
      algorithm
        d := density(setState_pTX(
                p,
                T,
                fill(0, 0)));
      end density_pT;

      redeclare replaceable partial model extends BaseProperties(final
          standardOrderComponents=true)
      end BaseProperties;
    end PartialPureSubstance;

    partial package PartialMixtureMedium
      "Base class for pure substances of several chemical substances"
      extends PartialMedium(redeclare replaceable record FluidConstants =
            Modelica.Media.Interfaces.Types.IdealGas.FluidConstants);

      redeclare replaceable record extends ThermodynamicState
        "Thermodynamic state variables"
        AbsolutePressure p "Absolute pressure of medium";
        Temperature T "Temperature of medium";
        MassFraction[nX] X(start=reference_X)
          "Mass fractions (= (component mass)/total mass  m_i/m)";
      end ThermodynamicState;

      constant FluidConstants[nS] fluidConstants "Constant data for the fluid";

      replaceable function gasConstant
        "Return the gas constant of the mixture (also for liquids)"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state";
        output SI.SpecificHeatCapacity R_s "Mixture gas constant";
      end gasConstant;

      function moleToMassFractions "Return mass fractions X from mole fractions"
        extends Modelica.Icons.Function;
        input SI.MoleFraction moleFractions[:] "Mole fractions of mixture";
        input MolarMass[:] MMX "Molar masses of components";
        output SI.MassFraction X[size(moleFractions, 1)]
          "Mass fractions of gas mixture";
    protected
        MolarMass Mmix=moleFractions*MMX "Molar mass of mixture";
      algorithm
        for i in 1:size(moleFractions, 1) loop
          X[i] := moleFractions[i]*MMX[i]/Mmix;
        end for;
        annotation (smoothOrder=5);
      end moleToMassFractions;

      function massToMoleFractions "Return mole fractions from mass fractions X"
        extends Modelica.Icons.Function;
        input SI.MassFraction X[:] "Mass fractions of mixture";
        input SI.MolarMass[:] MMX "Molar masses of components";
        output SI.MoleFraction moleFractions[size(X, 1)]
          "Mole fractions of gas mixture";
    protected
        Real invMMX[size(X, 1)] "Inverses of molar weights";
        SI.MolarMass Mmix "Molar mass of mixture";
      algorithm
        for i in 1:size(X, 1) loop
          invMMX[i] := 1/MMX[i];
        end for;
        Mmix := 1/(X*invMMX);
        for i in 1:size(X, 1) loop
          moleFractions[i] := Mmix*X[i]/MMX[i];
        end for;
        annotation (smoothOrder=5);
      end massToMoleFractions;

    end PartialMixtureMedium;

    partial package PartialCondensingGases
      "Base class for mixtures of condensing and non-condensing gases"
      extends PartialMixtureMedium(ThermoStates=Modelica.Media.Interfaces.Choices.IndependentVariables.pTX);

      replaceable partial function saturationPressure
        "Return saturation pressure of condensing fluid"
        extends Modelica.Icons.Function;
        input Temperature Tsat "Saturation temperature";
        output AbsolutePressure psat "Saturation pressure";
      end saturationPressure;

      replaceable partial function enthalpyOfVaporization
        "Return vaporization enthalpy of condensing fluid"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        output SpecificEnthalpy r0 "Vaporization enthalpy";
      end enthalpyOfVaporization;

      replaceable partial function enthalpyOfLiquid
        "Return liquid enthalpy of condensing fluid"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        output SpecificEnthalpy h "Liquid enthalpy";
      end enthalpyOfLiquid;

      replaceable partial function enthalpyOfGas
        "Return enthalpy of non-condensing gas mixture"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        input MassFraction[:] X "Vector of mass fractions";
        output SpecificEnthalpy h "Specific enthalpy";
      end enthalpyOfGas;

      replaceable partial function enthalpyOfCondensingGas
        "Return enthalpy of condensing gas (most often steam)"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        output SpecificEnthalpy h "Specific enthalpy";
      end enthalpyOfCondensingGas;

      replaceable partial function enthalpyOfNonCondensingGas
        "Return enthalpy of the non-condensing species"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        output SpecificEnthalpy h "Specific enthalpy";
      end enthalpyOfNonCondensingGas;
    end PartialCondensingGases;

    partial package PartialTwoPhaseMedium
      "Base class for two phase medium of one substance"
      extends PartialPureSubstance(redeclare replaceable record FluidConstants
        =   Modelica.Media.Interfaces.Types.TwoPhase.FluidConstants);
      constant Boolean smoothModel=false
        "True if the (derived) model should not generate state events";
      constant Boolean onePhase=false
        "True if the (derived) model should never be called with two-phase inputs";

      constant FluidConstants[nS] fluidConstants "Constant data for the fluid";

      redeclare replaceable record extends ThermodynamicState
        "Thermodynamic state of two phase medium"
        FixedPhase phase(min=0, max=2)
          "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";
      end ThermodynamicState;

      redeclare replaceable partial model extends BaseProperties
        "Base properties (p, d, T, h, u, R_s, MM, sat) of two phase medium"
        SaturationProperties sat "Saturation properties at the medium pressure";
      end BaseProperties;

      replaceable partial function setDewState
        "Return the thermodynamic state on the dew line"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation point";
        input FixedPhase phase(
          min=1,
          max=2) = 1 "Phase: default is one phase";
        output ThermodynamicState state "Complete thermodynamic state info";
      end setDewState;

      replaceable partial function setBubbleState
        "Return the thermodynamic state on the bubble line"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation point";
        input FixedPhase phase(
          min=1,
          max=2) = 1 "Phase: default is one phase";
        output ThermodynamicState state "Complete thermodynamic state info";
      end setBubbleState;

      redeclare replaceable partial function extends setState_dTX
        "Return thermodynamic state as function of d, T and composition X or Xi"
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
      end setState_dTX;

      redeclare replaceable partial function extends setState_phX
        "Return thermodynamic state as function of p, h and composition X or Xi"
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
      end setState_phX;

      redeclare replaceable partial function extends setState_psX
        "Return thermodynamic state as function of p, s and composition X or Xi"
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
      end setState_psX;

      redeclare replaceable partial function extends setState_pTX
        "Return thermodynamic state as function of p, T and composition X or Xi"
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
      end setState_pTX;

      replaceable function setSat_T
        "Return saturation property record from temperature"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        output SaturationProperties sat "Saturation property record";
      algorithm
        sat.Tsat := T;
        sat.psat := saturationPressure(T);
      end setSat_T;

      replaceable function setSat_p
        "Return saturation property record from pressure"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        output SaturationProperties sat "Saturation property record";
      algorithm
        sat.psat := p;
        sat.Tsat := saturationTemperature(p);
      end setSat_p;

      replaceable partial function bubbleEnthalpy
        "Return bubble point specific enthalpy"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output SI.SpecificEnthalpy hl "Boiling curve specific enthalpy";
      end bubbleEnthalpy;

      replaceable partial function dewEnthalpy
        "Return dew point specific enthalpy"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output SI.SpecificEnthalpy hv "Dew curve specific enthalpy";
      end dewEnthalpy;

      replaceable partial function bubbleEntropy
        "Return bubble point specific entropy"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output SI.SpecificEntropy sl "Boiling curve specific entropy";
      end bubbleEntropy;

      replaceable partial function dewEntropy "Return dew point specific entropy"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output SI.SpecificEntropy sv "Dew curve specific entropy";
      end dewEntropy;

      replaceable partial function bubbleDensity "Return bubble point density"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output Density dl "Boiling curve density";
      end bubbleDensity;

      replaceable partial function dewDensity "Return dew point density"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output Density dv "Dew curve density";
      end dewDensity;

      replaceable partial function saturationPressure
        "Return saturation pressure"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        output AbsolutePressure p "Saturation pressure";
      end saturationPressure;

      replaceable partial function saturationTemperature
        "Return saturation temperature"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        output Temperature T "Saturation temperature";
      end saturationTemperature;

      replaceable function saturationPressure_sat "Return saturation pressure"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output AbsolutePressure p "Saturation pressure";
      algorithm
        p := sat.psat;
      end saturationPressure_sat;

      replaceable function saturationTemperature_sat
        "Return saturation temperature"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output Temperature T "Saturation temperature";
      algorithm
        T := sat.Tsat;
      end saturationTemperature_sat;

      replaceable partial function saturationTemperature_derp
        "Return derivative of saturation temperature w.r.t. pressure"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        output DerTemperatureByPressure dTp
          "Derivative of saturation temperature w.r.t. pressure";
      end saturationTemperature_derp;

      replaceable function saturationTemperature_derp_sat
        "Return derivative of saturation temperature w.r.t. pressure"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output DerTemperatureByPressure dTp
          "Derivative of saturation temperature w.r.t. pressure";
      algorithm
        dTp := saturationTemperature_derp(sat.psat);
      end saturationTemperature_derp_sat;

      replaceable partial function surfaceTension
        "Return surface tension sigma in the two phase region"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output SurfaceTension sigma
          "Surface tension sigma in the two phase region";
      end surfaceTension;

      redeclare replaceable function extends molarMass
        "Return the molar mass of the medium"
      algorithm
        MM := fluidConstants[1].molarMass;
      end molarMass;

      replaceable partial function dBubbleDensity_dPressure
        "Return bubble point density derivative"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output DerDensityByPressure ddldp "Boiling curve density derivative";
      end dBubbleDensity_dPressure;

      replaceable partial function dDewDensity_dPressure
        "Return dew point density derivative"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output DerDensityByPressure ddvdp "Saturated steam density derivative";
      end dDewDensity_dPressure;

      replaceable partial function dBubbleEnthalpy_dPressure
        "Return bubble point specific enthalpy derivative"
        extends Modelica.Icons.Function;
        input SaturationProperties sat "Saturation property record";
        output DerEnthalpyByPressure dhldp
          "Boiling curve specific enthalpy derivative";
      end dBubbleEnthalpy_dPressure;

      replaceable partial function dDewEnthalpy_dPressure
        "Return dew point specific enthalpy derivative"
        extends Modelica.Icons.Function;

        input SaturationProperties sat "Saturation property record";
        output DerEnthalpyByPressure dhvdp
          "Saturated steam specific enthalpy derivative";
      end dDewEnthalpy_dPressure;

      redeclare replaceable function specificEnthalpy_pTX
        "Return specific enthalpy from pressure, temperature and mass fraction"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input MassFraction X[:] "Mass fractions";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output SpecificEnthalpy h "Specific enthalpy at p, T, X";
      algorithm
        h := specificEnthalpy(setState_pTX(
                p,
                T,
                X,
                phase));
      end specificEnthalpy_pTX;

      redeclare replaceable function temperature_phX
        "Return temperature from p, h, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input MassFraction X[:] "Mass fractions";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output Temperature T "Temperature";
      algorithm
        T := temperature(setState_phX(
                p,
                h,
                X,
                phase));
      end temperature_phX;

      redeclare replaceable function density_phX
        "Return density from p, h, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input MassFraction X[:] "Mass fractions";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output Density d "Density";
      algorithm
        d := density(setState_phX(
                p,
                h,
                X,
                phase));
      end density_phX;

      redeclare replaceable function temperature_psX
        "Return temperature from p, s, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input MassFraction X[:] "Mass fractions";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output Temperature T "Temperature";
      algorithm
        T := temperature(setState_psX(
                p,
                s,
                X,
                phase));
      end temperature_psX;

      redeclare replaceable function density_psX
        "Return density from p, s, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input MassFraction X[:] "Mass fractions";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output Density d "Density";
      algorithm
        d := density(setState_psX(
                p,
                s,
                X,
                phase));
      end density_psX;

      redeclare replaceable function specificEnthalpy_psX
        "Return specific enthalpy from p, s, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input MassFraction X[:] "Mass fractions";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := specificEnthalpy(setState_psX(
                p,
                s,
                X,
                phase));
      end specificEnthalpy_psX;

      redeclare replaceable function setState_pT
        "Return thermodynamic state from p and T"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_pTX(
                p,
                T,
                fill(0, 0),
                phase);
      end setState_pT;

      redeclare replaceable function setState_ph
        "Return thermodynamic state from p and h"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_phX(
                p,
                h,
                fill(0, 0),
                phase);
      end setState_ph;

      redeclare replaceable function setState_ps
        "Return thermodynamic state from p and s"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_psX(
                p,
                s,
                fill(0, 0),
                phase);
      end setState_ps;

      redeclare replaceable function setState_dT
        "Return thermodynamic state from d and T"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_dTX(
                d,
                T,
                fill(0, 0),
                phase);
      end setState_dT;

      replaceable function setState_px
        "Return thermodynamic state from pressure and vapour quality"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input MassFraction x "Vapour quality";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_ph(
                p,
                (1 - x)*bubbleEnthalpy(setSat_p(p)) + x*dewEnthalpy(setSat_p(p)),
                2);
      end setState_px;

      replaceable function setState_Tx
        "Return thermodynamic state from temperature and vapour quality"
        extends Modelica.Icons.Function;
        input Temperature T "Temperature";
        input MassFraction x "Vapour quality";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := setState_ph(
                saturationPressure_sat(setSat_T(T)),
                (1 - x)*bubbleEnthalpy(setSat_T(T)) + x*dewEnthalpy(setSat_T(T)),
                2);
      end setState_Tx;

      replaceable function vapourQuality "Return vapour quality"
        extends Modelica.Icons.Function;
        input ThermodynamicState state "Thermodynamic state record";
        output MassFraction x "Vapour quality";
    protected
        constant SpecificEnthalpy eps=1e-8;
      algorithm
        x := min(max((specificEnthalpy(state) - bubbleEnthalpy(setSat_p(pressure(
          state))))/(dewEnthalpy(setSat_p(pressure(state))) - bubbleEnthalpy(
          setSat_p(pressure(state))) + eps), 0), 1);
      end vapourQuality;

      redeclare replaceable function density_ph "Return density from p and h"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output Density d "Density";
      algorithm
        d := density_phX(
                p,
                h,
                fill(0, 0),
                phase);
      end density_ph;

      redeclare replaceable function temperature_ph
        "Return temperature from p and h"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output Temperature T "Temperature";
      algorithm
        T := temperature_phX(
                p,
                h,
                fill(0, 0),
                phase);
      end temperature_ph;

      redeclare replaceable function pressure_dT "Return pressure from d and T"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output AbsolutePressure p "Pressure";
      algorithm
        p := pressure(setState_dTX(
                d,
                T,
                fill(0, 0),
                phase));
      end pressure_dT;

      redeclare replaceable function specificEnthalpy_dT
        "Return specific enthalpy from d and T"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := specificEnthalpy(setState_dTX(
                d,
                T,
                fill(0, 0),
                phase));
      end specificEnthalpy_dT;

      redeclare replaceable function specificEnthalpy_ps
        "Return specific enthalpy from p and s"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := specificEnthalpy_psX(
                p,
                s,
                fill(0, 0));
      end specificEnthalpy_ps;

      redeclare replaceable function temperature_ps
        "Return temperature from p and s"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output Temperature T "Temperature";
      algorithm
        T := temperature_psX(
                p,
                s,
                fill(0, 0),
                phase);
      end temperature_ps;

      redeclare replaceable function density_ps "Return density from p and s"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output Density d "Density";
      algorithm
        d := density_psX(
                p,
                s,
                fill(0, 0),
                phase);
      end density_ps;

      redeclare replaceable function specificEnthalpy_pT
        "Return specific enthalpy from p and T"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := specificEnthalpy_pTX(
                p,
                T,
                fill(0, 0),
                phase);
      end specificEnthalpy_pT;

      redeclare replaceable function density_pT "Return density from p and T"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input FixedPhase phase=0
          "2 for two-phase, 1 for one-phase, 0 if not known";
        output Density d "Density";
      algorithm
        d := density(setState_pTX(
                p,
                T,
                fill(0, 0),
                phase));
      end density_pT;
    end PartialTwoPhaseMedium;

    partial package PartialSimpleMedium
      "Medium model with linear dependency of u, h from temperature. All other quantities, especially density, are constant."

      extends Interfaces.PartialPureSubstance(final ThermoStates=Modelica.Media.Interfaces.Choices.IndependentVariables.pT,
          final singleState=true);

      constant SpecificHeatCapacity cp_const
        "Constant specific heat capacity at constant pressure";
      constant SpecificHeatCapacity cv_const
        "Constant specific heat capacity at constant volume";
      constant Density d_const "Constant density";
      constant DynamicViscosity eta_const "Constant dynamic viscosity";
      constant ThermalConductivity lambda_const "Constant thermal conductivity";
      constant VelocityOfSound a_const "Constant velocity of sound";
      constant Temperature T_min "Minimum temperature valid for medium model";
      constant Temperature T_max "Maximum temperature valid for medium model";
      constant Temperature T0=reference_T "Zero enthalpy temperature";
      constant MolarMass MM_const "Molar mass";

      constant FluidConstants[nS] fluidConstants "Fluid constants";

      redeclare record extends ThermodynamicState "Thermodynamic state"
        AbsolutePressure p "Absolute pressure of medium";
        Temperature T "Temperature of medium";
      end ThermodynamicState;

      redeclare replaceable model extends BaseProperties(T(stateSelect=if
              preferredMediumStates then StateSelect.prefer else StateSelect.default),
          p(stateSelect=if preferredMediumStates then StateSelect.prefer else
              StateSelect.default)) "Base properties"
      equation
        assert(T >= T_min and T <= T_max, "
Temperature T (= "   + String(T) + " K) is not
in the allowed range ("   + String(T_min) + " K <= T <= " + String(T_max) + " K)
required from medium model \""   + mediumName + "\".
");

        // h = cp_const*(T-T0);
        h = specificEnthalpy_pTX(
                p,
                T,
                X);
        u = cv_const*(T - T0);
        d = d_const;
        R_s = 0;
        MM = MM_const;
        state.T = T;
        state.p = p;
        annotation (Documentation(info="<html>
<p>
This is the most simple incompressible medium model, where
specific enthalpy h and specific internal energy u are only
a function of temperature T and all other provided medium
quantities are assumed to be constant.
Note that the (small) influence of the pressure term p/d is neglected.
</p>
</html>"));
      end BaseProperties;

      redeclare function setState_pTX
        "Return thermodynamic state from p, T, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input MassFraction X[:]=reference_X "Mass fractions";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := ThermodynamicState(p=p, T=T);
      end setState_pTX;

      redeclare function setState_phX
        "Return thermodynamic state from p, h, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input MassFraction X[:]=reference_X "Mass fractions";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := ThermodynamicState(p=p, T=T0 + h/cp_const);
      end setState_phX;

      redeclare replaceable function setState_psX
        "Return thermodynamic state from p, s, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input MassFraction X[:]=reference_X "Mass fractions";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        state := ThermodynamicState(p=p, T=Modelica.Math.exp(s/cp_const +
          Modelica.Math.log(reference_T)))
          "Here the incompressible limit is used, with cp as heat capacity";
      end setState_psX;

      redeclare function setState_dTX
        "Return thermodynamic state from d, T, and X or Xi"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        input MassFraction X[:]=reference_X "Mass fractions";
        output ThermodynamicState state "Thermodynamic state record";
      algorithm
        assert(false,
          "Pressure can not be computed from temperature and density for an incompressible fluid!");
      end setState_dTX;

      redeclare function extends setSmoothState
        "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
      algorithm
        state := ThermodynamicState(p=Media.Common.smoothStep(
                x,
                state_a.p,
                state_b.p,
                x_small), T=Media.Common.smoothStep(
                x,
                state_a.T,
                state_b.T,
                x_small));
      end setSmoothState;

      redeclare function extends dynamicViscosity "Return dynamic viscosity"

      algorithm
        eta := eta_const;
      end dynamicViscosity;

      redeclare function extends thermalConductivity
        "Return thermal conductivity"

      algorithm
        lambda := lambda_const;
      end thermalConductivity;

      redeclare function extends pressure "Return pressure"

      algorithm
        p := state.p;
      end pressure;

      redeclare function extends temperature "Return temperature"

      algorithm
        T := state.T;
      end temperature;

      redeclare function extends density "Return density"

      algorithm
        d := d_const;
      end density;

      redeclare function extends specificEnthalpy "Return specific enthalpy"

      algorithm
        h := cp_const*(state.T - T0);
      end specificEnthalpy;

      redeclare function extends specificHeatCapacityCp
        "Return specific heat capacity at constant pressure"

      algorithm
        cp := cp_const;
      end specificHeatCapacityCp;

      redeclare function extends specificHeatCapacityCv
        "Return specific heat capacity at constant volume"

      algorithm
        cv := cv_const;
      end specificHeatCapacityCv;

      redeclare function extends isentropicExponent "Return isentropic exponent"

      algorithm
        gamma := cp_const/cv_const;
      end isentropicExponent;

      redeclare function extends velocityOfSound "Return velocity of sound"

      algorithm
        a := a_const;
      end velocityOfSound;

      redeclare function specificEnthalpy_pTX
        "Return specific enthalpy from p, T, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input MassFraction X[nX] "Mass fractions";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := cp_const*(T - T0);
        annotation (Documentation(info="<html>
<p>
This function computes the specific enthalpy of the fluid, but neglects the (small) influence of the pressure term p/d.
</p>
</html>"));
      end specificEnthalpy_pTX;

      redeclare function temperature_phX
        "Return temperature from p, h, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input MassFraction X[nX] "Mass fractions";
        output Temperature T "Temperature";
      algorithm
        T := T0 + h/cp_const;
      end temperature_phX;

      redeclare function density_phX "Return density from p, h, and X or Xi"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input MassFraction X[nX] "Mass fractions";
        output Density d "Density";
      algorithm
        d := density(setState_phX(
                p,
                h,
                X));
      end density_phX;

      redeclare function extends specificInternalEnergy
        "Return specific internal energy"
        extends Modelica.Icons.Function;
      algorithm
        //  u := cv_const*(state.T - T0) - reference_p/d_const;
        u := cv_const*(state.T - T0);
        annotation (Documentation(info="<html>
<p>
This function computes the specific internal energy of the fluid, but neglects the (small) influence of the pressure term p/d.
</p>
</html>"));
      end specificInternalEnergy;

      redeclare function extends specificEntropy "Return specific entropy"
        extends Modelica.Icons.Function;
      algorithm
        s := cv_const*Modelica.Math.log(state.T/T0);
      end specificEntropy;

      redeclare function extends specificGibbsEnergy
        "Return specific Gibbs energy"
        extends Modelica.Icons.Function;
      algorithm
        g := specificEnthalpy(state) - state.T*specificEntropy(state);
      end specificGibbsEnergy;

      redeclare function extends specificHelmholtzEnergy
        "Return specific Helmholtz energy"
        extends Modelica.Icons.Function;
      algorithm
        f := specificInternalEnergy(state) - state.T*specificEntropy(state);
      end specificHelmholtzEnergy;

      redeclare function extends isentropicEnthalpy "Return isentropic enthalpy"
      algorithm
        h_is := cp_const*(temperature(refState) - T0);
      end isentropicEnthalpy;

      redeclare function extends isobaricExpansionCoefficient
        "Returns overall the isobaric expansion coefficient beta"
      algorithm
        beta := 0.0;
      end isobaricExpansionCoefficient;

      redeclare function extends isothermalCompressibility
        "Returns overall the isothermal compressibility factor"
      algorithm
        kappa := 0;
      end isothermalCompressibility;

      redeclare function extends density_derp_T
        "Returns the partial derivative of density with respect to pressure at constant temperature"
      algorithm
        ddpT := 0;
      end density_derp_T;

      redeclare function extends density_derT_p
        "Returns the partial derivative of density with respect to temperature at constant pressure"
      algorithm
        ddTp := 0;
      end density_derT_p;

      redeclare function extends density_derX
        "Returns the partial derivative of density with respect to mass fractions at constant pressure and temperature"
      algorithm
        dddX := fill(0, nX);
      end density_derX;

      redeclare function extends molarMass "Return the molar mass of the medium"
      algorithm
        MM := MM_const;
      end molarMass;
    end PartialSimpleMedium;

    package Choices "Types, constants to define menu choices"
      extends Modelica.Icons.Package;

      type IndependentVariables = enumeration(
        T   "Temperature",
        pT   "Pressure, Temperature",
        ph   "Pressure, Specific Enthalpy",
        phX   "Pressure, Specific Enthalpy, Mass Fraction",
        pTX   "Pressure, Temperature, Mass Fractions",
        dTX   "Density, Temperature, Mass Fractions")
        "Enumeration defining the independent variables of a medium";

      type ReferenceEnthalpy = enumeration(
        ZeroAt0K
            "The enthalpy is 0 at 0 K (default), if the enthalpy of formation is excluded",
        ZeroAt25C
            "The enthalpy is 0 at 25 degC, if the enthalpy of formation is excluded",
        UserDefined
            "The user-defined reference enthalpy is used at 293.15 K (25 degC)")
        "Enumeration defining the reference enthalpy of a medium" annotation (
          Evaluate=true);
      annotation (Documentation(info="<html>
<p>
Enumerations and data types for all types of fluids
</p>

<p>
Note: Reference enthalpy might have to be extended with enthalpy of formation.
</p>
</html>"));
    end Choices;

    package Types "Types to be used in fluid models"
      extends Modelica.Icons.Package;

      type AbsolutePressure = SI.AbsolutePressure (
          min=0,
          max=1.e8,
          nominal=1.e5,
          start=1.e5)
        "Type for absolute pressure with medium specific attributes";

      type Density = SI.Density (
          min=0,
          max=1.e5,
          nominal=1,
          start=1) "Type for density with medium specific attributes";

      type DynamicViscosity = SI.DynamicViscosity (
          min=0,
          max=1.e8,
          nominal=1.e-3,
          start=1.e-3)
        "Type for dynamic viscosity with medium specific attributes";

      type EnthalpyFlowRate = SI.EnthalpyFlowRate (
          nominal=1000.0,
          min=-1.0e8,
          max=1.e8) "Type for enthalpy flow rate with medium specific attributes";

      type MassFraction = Real (
          quantity="MassFraction",
          final unit="kg/kg",
          min=0,
          max=1,
          nominal=0.1) "Type for mass fraction with medium specific attributes";

      type MoleFraction = Real (
          quantity="MoleFraction",
          final unit="mol/mol",
          min=0,
          max=1,
          nominal=0.1) "Type for mole fraction with medium specific attributes";

      type MolarMass = SI.MolarMass (
          min=0.001,
          max=0.25,
          nominal=0.032) "Type for molar mass with medium specific attributes";

      type MolarVolume = SI.MolarVolume (
          min=1e-6,
          max=1.0e6,
          nominal=1.0) "Type for molar volume with medium specific attributes";

      type IsentropicExponent = SI.RatioOfSpecificHeatCapacities (
          min=1,
          max=500000,
          nominal=1.2,
          start=1.2)
        "Type for isentropic exponent with medium specific attributes";

      type SpecificEnergy = SI.SpecificEnergy (
          min=-1.0e8,
          max=1.e8,
          nominal=1.e6)
        "Type for specific energy with medium specific attributes";

      type SpecificInternalEnergy = SpecificEnergy
        "Type for specific internal energy with medium specific attributes";

      type SpecificEnthalpy = SI.SpecificEnthalpy (
          min=-1.0e10,
          max=1.e10,
          nominal=1.e6)
        "Type for specific enthalpy with medium specific attributes";

      type SpecificEntropy = SI.SpecificEntropy (
          min=-1.e7,
          max=1.e7,
          nominal=1.e3)
        "Type for specific entropy with medium specific attributes";

      type SpecificHeatCapacity = SI.SpecificHeatCapacity (
          min=0,
          max=1.e7,
          nominal=1.e3,
          start=1.e3)
        "Type for specific heat capacity with medium specific attributes";

      type SurfaceTension = SI.SurfaceTension
        "Type for surface tension with medium specific attributes";

      type Temperature = SI.Temperature (
          min=1,
          max=1.e4,
          nominal=300,
          start=288.15) "Type for temperature with medium specific attributes";

      type ThermalConductivity = SI.ThermalConductivity (
          min=0,
          max=500,
          nominal=1,
          start=1)
        "Type for thermal conductivity with medium specific attributes";

      type PrandtlNumber = SI.PrandtlNumber (
          min=1e-3,
          max=1e5,
          nominal=1.0) "Type for Prandtl number with medium specific attributes";

      type VelocityOfSound = SI.Velocity (
          min=0,
          max=1.e5,
          nominal=1000,
          start=1000)
        "Type for velocity of sound with medium specific attributes";

      type ExtraProperty = Real (min=0.0, start=1.0)
        "Type for unspecified, mass-specific property transported by flow";

      type ExtraPropertyFlowRate = Real (unit="kg/s")
        "Type for flow rate of unspecified, mass-specific property";

      type IsobaricExpansionCoefficient = Real (
          min=0,
          max=1.0e8,
          unit="1/K")
        "Type for isobaric expansion coefficient with medium specific attributes";

      type DipoleMoment = Real (
          min=0.0,
          max=2.0,
          unit="debye",
          quantity="ElectricDipoleMoment")
        "Type for dipole moment with medium specific attributes";

      type DerDensityByPressure = SI.DerDensityByPressure
        "Type for partial derivative of density with respect to pressure with medium specific attributes";

      type DerDensityByEnthalpy = SI.DerDensityByEnthalpy
        "Type for partial derivative of density with respect to enthalpy with medium specific attributes";

      type DerEnthalpyByPressure = SI.DerEnthalpyByPressure
        "Type for partial derivative of enthalpy with respect to pressure with medium specific attributes";

      type DerDensityByTemperature = SI.DerDensityByTemperature
        "Type for partial derivative of density with respect to temperature with medium specific attributes";

      type DerTemperatureByPressure = Real (final unit="K/Pa")
        "Type for partial derivative of temperature with respect to pressure with medium specific attributes";

      replaceable record SaturationProperties
        "Saturation properties of two phase medium"
        extends Modelica.Icons.Record;
        AbsolutePressure psat "Saturation pressure";
        Temperature Tsat "Saturation temperature";
      end SaturationProperties;

      type FixedPhase = Integer (min=0, max=2)
        "Phase of the fluid: 1 for 1-phase, 2 for two-phase, 0 for not known, e.g., interactive use";

      package Basic
      "The most basic version of a record used in several degrees of detail"
        extends Icons.Package;

        record FluidConstants
          "Critical, triple, molecular and other standard data of fluid"
          extends Modelica.Icons.Record;
          String iupacName
            "Complete IUPAC name (or common name, if non-existent)";
          String casRegistryNumber
            "Chemical abstracts sequencing number (if it exists)";
          String chemicalFormula
            "Chemical formula, (brutto, nomenclature according to Hill";
          String structureFormula "Chemical structure formula";
          MolarMass molarMass "Molar mass";
        end FluidConstants;
      end Basic;

      package IdealGas
      "The ideal gas version of a record used in several degrees of detail"
        extends Icons.Package;

        record FluidConstants "Extended fluid constants"
          extends Modelica.Media.Interfaces.Types.Basic.FluidConstants;
          Temperature criticalTemperature "Critical temperature";
          AbsolutePressure criticalPressure "Critical pressure";
          MolarVolume criticalMolarVolume "Critical molar Volume";
          Real acentricFactor "Pitzer acentric factor";
          //   Temperature triplePointTemperature "Triple point temperature";
          //   AbsolutePressure triplePointPressure "Triple point pressure";
          Temperature meltingPoint "Melting point at 101325 Pa";
          Temperature normalBoilingPoint "Normal boiling point (at 101325 Pa)";
          DipoleMoment dipoleMoment
            "Dipole moment of molecule in Debye (1 debye = 3.33564e10-30 C.m)";
          Boolean hasIdealGasHeatCapacity=false
            "True if ideal gas heat capacity is available";
          Boolean hasCriticalData=false "True if critical data are known";
          Boolean hasDipoleMoment=false "True if a dipole moment known";
          Boolean hasFundamentalEquation=false "True if a fundamental equation";
          Boolean hasLiquidHeatCapacity=false
            "True if liquid heat capacity is available";
          Boolean hasSolidHeatCapacity=false
            "True if solid heat capacity is available";
          Boolean hasAccurateViscosityData=false
            "True if accurate data for a viscosity function is available";
          Boolean hasAccurateConductivityData=false
            "True if accurate data for thermal conductivity is available";
          Boolean hasVapourPressureCurve=false
            "True if vapour pressure data, e.g., Antoine coefficients are known";
          Boolean hasAcentricFactor=false
            "True if Pitzer acentric factor is known";
          SpecificEnthalpy HCRIT0=0.0
            "Critical specific enthalpy of the fundamental equation";
          SpecificEntropy SCRIT0=0.0
            "Critical specific entropy of the fundamental equation";
          SpecificEnthalpy deltah=0.0
            "Difference between specific enthalpy model (h_m) and f.eq. (h_f) (h_m - h_f)";
          SpecificEntropy deltas=0.0
            "Difference between specific enthalpy model (s_m) and f.eq. (s_f) (s_m - s_f)";
        end FluidConstants;
      end IdealGas;

      package TwoPhase
      "The two phase fluid version of a record used in several degrees of detail"
        extends Icons.Package;

        record FluidConstants "Extended fluid constants"
          extends Modelica.Media.Interfaces.Types.Basic.FluidConstants;
          Temperature criticalTemperature "Critical temperature";
          AbsolutePressure criticalPressure "Critical pressure";
          MolarVolume criticalMolarVolume "Critical molar Volume";
          Real acentricFactor "Pitzer acentric factor";
          Temperature triplePointTemperature "Triple point temperature";
          AbsolutePressure triplePointPressure "Triple point pressure";
          Temperature meltingPoint "Melting point at 101325 Pa";
          Temperature normalBoilingPoint "Normal boiling point (at 101325 Pa)";
          DipoleMoment dipoleMoment
            "Dipole moment of molecule in Debye (1 debye = 3.33564e10-30 C.m)";
          Boolean hasIdealGasHeatCapacity=false
            "True if ideal gas heat capacity is available";
          Boolean hasCriticalData=false "True if critical data are known";
          Boolean hasDipoleMoment=false "True if a dipole moment known";
          Boolean hasFundamentalEquation=false "True if a fundamental equation";
          Boolean hasLiquidHeatCapacity=false
            "True if liquid heat capacity is available";
          Boolean hasSolidHeatCapacity=false
            "True if solid heat capacity is available";
          Boolean hasAccurateViscosityData=false
            "True if accurate data for a viscosity function is available";
          Boolean hasAccurateConductivityData=false
            "True if accurate data for thermal conductivity is available";
          Boolean hasVapourPressureCurve=false
            "True if vapour pressure data, e.g., Antoine coefficients are known";
          Boolean hasAcentricFactor=false
            "True if Pitzer acentric factor is known";
          SpecificEnthalpy HCRIT0=0.0
            "Critical specific enthalpy of the fundamental equation";
          SpecificEntropy SCRIT0=0.0
            "Critical specific entropy of the fundamental equation";
          SpecificEnthalpy deltah=0.0
            "Difference between specific enthalpy model (h_m) and f.eq. (h_f) (h_m - h_f)";
          SpecificEntropy deltas=0.0
            "Difference between specific enthalpy model (s_m) and f.eq. (s_f) (s_m - s_f)";
        end FluidConstants;
      end TwoPhase;
    end Types;
    annotation (Documentation(info="<html>
<p>
This package provides basic interfaces definitions of media models for different
kind of media.
</p>
</html>"));
  end Interfaces;

  package Common
    "Data structures and fundamental functions for fluid properties"
    extends Modelica.Icons.Package;

    type DerPressureByDensity = Real (final quantity="DerPressureByDensity",
          final unit="Pa.m3/kg");

    type DerPressureByTemperature = Real (final quantity=
            "DerPressureByTemperature", final unit="Pa/K");

    record IF97BaseTwoPhase "Intermediate property data record for IF 97"
      extends Modelica.Icons.Record;
      Integer phase(start=0)
        "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
      Integer region(min=1, max=5) "IF 97 region";
      SI.Pressure p "Pressure";
      SI.Temperature T "Temperature";
      SI.SpecificEnthalpy h "Specific enthalpy";
      SI.SpecificHeatCapacity R_s "Gas constant";
      SI.SpecificHeatCapacity cp "Specific heat capacity";
      SI.SpecificHeatCapacity cv "Specific heat capacity";
      SI.Density rho "Density";
      SI.SpecificEntropy s "Specific entropy";
      DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
      DerPressureByDensity pd "Derivative of pressure w.r.t. density";
      Real vt "Derivative of specific volume w.r.t. temperature";
      Real vp "Derivative of specific volume w.r.t. pressure";
      Real x "Dryness fraction";
      Real dpT "dp/dT derivative of saturation curve";
    end IF97BaseTwoPhase;

    record IF97PhaseBoundaryProperties
      "Thermodynamic base properties on the phase boundary for IF97 steam tables"

      extends Modelica.Icons.Record;
      Boolean region3boundary "True if boundary between 2-phase and region 3";
      SI.SpecificHeatCapacity R_s "Specific heat capacity";
      SI.Temperature T "Temperature";
      SI.Density d "Density";
      SI.SpecificEnthalpy h "Specific enthalpy";
      SI.SpecificEntropy s "Specific entropy";
      SI.SpecificHeatCapacity cp "Heat capacity at constant pressure";
      SI.SpecificHeatCapacity cv "Heat capacity at constant volume";
      DerPressureByTemperature dpT "dp/dT derivative of saturation curve";
      DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
      DerPressureByDensity pd "Derivative of pressure w.r.t. density";
      Real vt(unit="m3/(kg.K)")
        "Derivative of specific volume w.r.t. temperature";
      Real vp(unit="m3/(kg.Pa)") "Derivative of specific volume w.r.t. pressure";
    end IF97PhaseBoundaryProperties;

    record GibbsDerivs
      "Derivatives of dimensionless Gibbs-function w.r.t. dimensionless pressure and temperature"

      extends Modelica.Icons.Record;
      SI.Pressure p "Pressure";
      SI.Temperature T "Temperature";
      SI.SpecificHeatCapacity R_s "Specific heat capacity";
      Real pi(unit="1") "Dimensionless pressure";
      Real tau(unit="1") "Dimensionless temperature";
      Real g(unit="1") "Dimensionless Gibbs-function";
      Real gpi(unit="1") "Derivative of g w.r.t. pi";
      Real gpipi(unit="1") "2nd derivative of g w.r.t. pi";
      Real gtau(unit="1") "Derivative of g w.r.t. tau";
      Real gtautau(unit="1") "2nd derivative of g w.r.t. tau";
      Real gtaupi(unit="1") "Mixed derivative of g w.r.t. pi and tau";
    end GibbsDerivs;

    record HelmholtzDerivs
      "Derivatives of dimensionless Helmholtz-function w.r.t. dimensionless pressure, density and temperature"
      extends Modelica.Icons.Record;
      SI.Density d "Density";
      SI.Temperature T "Temperature";
      SI.SpecificHeatCapacity R_s "Specific heat capacity";
      Real delta(unit="1") "Dimensionless density";
      Real tau(unit="1") "Dimensionless temperature";
      Real f(unit="1") "Dimensionless Helmholtz-function";
      Real fdelta(unit="1") "Derivative of f w.r.t. delta";
      Real fdeltadelta(unit="1") "2nd derivative of f w.r.t. delta";
      Real ftau(unit="1") "Derivative of f w.r.t. tau";
      Real ftautau(unit="1") "2nd derivative of f w.r.t. tau";
      Real fdeltatau(unit="1") "Mixed derivative of f w.r.t. delta and tau";
    end HelmholtzDerivs;

    record PhaseBoundaryProperties
      "Thermodynamic base properties on the phase boundary"
      extends Modelica.Icons.Record;
      SI.Density d "Density";
      SI.SpecificEnthalpy h "Specific enthalpy";
      SI.SpecificEnergy u "Inner energy";
      SI.SpecificEntropy s "Specific entropy";
      SI.SpecificHeatCapacity cp "Heat capacity at constant pressure";
      SI.SpecificHeatCapacity cv "Heat capacity at constant volume";
      DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
      DerPressureByDensity pd "Derivative of pressure w.r.t. density";
    end PhaseBoundaryProperties;

    record NewtonDerivatives_ph
      "Derivatives for fast inverse calculations of Helmholtz functions: p & h"

      extends Modelica.Icons.Record;
      SI.Pressure p "Pressure";
      SI.SpecificEnthalpy h "Specific enthalpy";
      DerPressureByDensity pd "Derivative of pressure w.r.t. density";
      DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
      Real hd "Derivative of specific enthalpy w.r.t. density";
      Real ht "Derivative of specific enthalpy w.r.t. temperature";
    end NewtonDerivatives_ph;

    record NewtonDerivatives_ps
      "Derivatives for fast inverse calculation of Helmholtz functions: p & s"

      extends Modelica.Icons.Record;
      SI.Pressure p "Pressure";
      SI.SpecificEntropy s "Specific entropy";
      DerPressureByDensity pd "Derivative of pressure w.r.t. density";
      DerPressureByTemperature pt "Derivative of pressure w.r.t. temperature";
      Real sd "Derivative of specific entropy w.r.t. density";
      Real st "Derivative of specific entropy w.r.t. temperature";
    end NewtonDerivatives_ps;

    record NewtonDerivatives_pT
      "Derivatives for fast inverse calculations of Helmholtz functions:p & T"

      extends Modelica.Icons.Record;
      SI.Pressure p "Pressure";
      DerPressureByDensity pd "Derivative of pressure w.r.t. density";
    end NewtonDerivatives_pT;

    function gibbsToBoundaryProps
      "Calculate phase boundary property record from dimensionless Gibbs function"

      extends Modelica.Icons.Function;
      input GibbsDerivs g "Dimensionless derivatives of Gibbs function";
      output PhaseBoundaryProperties sat "Phase boundary properties";
  protected
      Real vt "Derivative of specific volume w.r.t. temperature";
      Real vp "Derivative of specific volume w.r.t. pressure";
    algorithm
      sat.d := g.p/(g.R_s*g.T*g.pi*g.gpi);
      sat.h := g.R_s*g.T*g.tau*g.gtau;
      sat.u := g.T*g.R_s*(g.tau*g.gtau - g.pi*g.gpi);
      sat.s := g.R_s*(g.tau*g.gtau - g.g);
      sat.cp := -g.R_s*g.tau*g.tau*g.gtautau;
      sat.cv := g.R_s*(-g.tau*g.tau*g.gtautau + (g.gpi - g.tau*g.gtaupi)*(g.gpi - g.tau
        *g.gtaupi)/(g.gpipi));
      vt := g.R_s/g.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
      vp := g.R_s*g.T/(g.p*g.p)*g.pi*g.pi*g.gpipi;
      // sat.kappa := -1/(sat.d*g.p)*sat.cp/(vp*sat.cp + vt*vt*g.T);
      sat.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
      sat.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
    end gibbsToBoundaryProps;

    function helmholtzToBoundaryProps
      "Calculate phase boundary property record from dimensionless Helmholtz function"

      extends Modelica.Icons.Function;
      input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
      output PhaseBoundaryProperties sat "Phase boundary property record";
  protected
      SI.Pressure p "Pressure";
    algorithm
      p := f.R_s*f.d*f.T*f.delta*f.fdelta;
      sat.d := f.d;
      sat.h := f.R_s*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
      sat.s := f.R_s*(f.tau*f.ftau - f.f);
      sat.u := f.R_s*f.T*f.tau*f.ftau;
      sat.cp := f.R_s*(-f.tau*f.tau*f.ftautau + (f.delta*f.fdelta - f.delta*f.tau*f.fdeltatau)
        ^2/(2*f.delta*f.fdelta + f.delta*f.delta*f.fdeltadelta));
      sat.cv := f.R_s*(-f.tau*f.tau*f.ftautau);
      sat.pt := f.R_s*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
      sat.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
    end helmholtzToBoundaryProps;

    function cv2Phase
      "Compute isochoric specific heat capacity inside the two-phase region"

      extends Modelica.Icons.Function;
      input PhaseBoundaryProperties liq "Properties on the boiling curve";
      input PhaseBoundaryProperties vap "Properties on the condensation curve";
      input SI.MassFraction x "Vapour mass fraction";
      input SI.Temperature T "Temperature";
      input SI.Pressure p "Properties";
      output SI.SpecificHeatCapacity cv "Isochoric specific heat capacity";
  protected
      Real dpT "Derivative of pressure w.r.t. temperature";
      Real dxv "Derivative of vapour mass fraction w.r.t. specific volume";
      Real dvTl "Derivative of liquid specific volume w.r.t. temperature";
      Real dvTv "Derivative of vapour specific volume w.r.t. temperature";
      Real duTl "Derivative of liquid specific inner energy w.r.t. temperature";
      Real duTv "Derivative of vapour specific inner energy w.r.t. temperature";
      Real dxt "Derivative of vapour mass fraction w.r.t. temperature";
    algorithm
      dxv := if (liq.d <> vap.d) then liq.d*vap.d/(liq.d - vap.d) else 0.0;
      dpT := (vap.s - liq.s)*dxv;
      // wrong at critical point
      dvTl := (liq.pt - dpT)/liq.pd/liq.d/liq.d;
      dvTv := (vap.pt - dpT)/vap.pd/vap.d/vap.d;
      dxt := -dxv*(dvTl + x*(dvTv - dvTl));
      duTl := liq.cv + (T*liq.pt - p)*dvTl;
      duTv := vap.cv + (T*vap.pt - p)*dvTv;
      cv := duTl + x*(duTv - duTl) + dxt*(vap.u - liq.u);
    end cv2Phase;

    function Helmholtz_ph
      "Function to calculate analytic derivatives for computing d and t given p and h"
      extends Modelica.Icons.Function;
      input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
      output NewtonDerivatives_ph nderivs
        "Derivatives for Newton iteration to calculate d and t from p and h";
  protected
      SI.SpecificHeatCapacity cv "Isochoric heat capacity";
    algorithm
      cv := -f.R_s*(f.tau*f.tau*f.ftautau);
      nderivs.p := f.d*f.R_s*f.T*f.delta*f.fdelta;
      nderivs.h := f.R_s*f.T*(f.tau*f.ftau + f.delta*f.fdelta);
      nderivs.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
      nderivs.pt := f.R_s*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
      nderivs.ht := cv + nderivs.pt/f.d;
      nderivs.hd := (nderivs.pd - f.T*nderivs.pt/f.d)/f.d;
    end Helmholtz_ph;

    function Helmholtz_pT
      "Function to calculate analytic derivatives for computing d and t given p and t"

      extends Modelica.Icons.Function;
      input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
      output NewtonDerivatives_pT nderivs
        "Derivatives for Newton iteration to compute d and t from p and t";
    algorithm
      nderivs.p := f.d*f.R_s*f.T*f.delta*f.fdelta;
      nderivs.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
    end Helmholtz_pT;

    function Helmholtz_ps
      "Function to calculate analytic derivatives for computing d and t given p and s"

      extends Modelica.Icons.Function;
      input HelmholtzDerivs f "Dimensionless derivatives of Helmholtz function";
      output NewtonDerivatives_ps nderivs
        "Derivatives for Newton iteration to compute d and t from p and s";
  protected
      SI.SpecificHeatCapacity cv "Isochoric heat capacity";
    algorithm
      cv := -f.R_s*(f.tau*f.tau*f.ftautau);
      nderivs.p := f.d*f.R_s*f.T*f.delta*f.fdelta;
      nderivs.s := f.R_s*(f.tau*f.ftau - f.f);
      nderivs.pd := f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
      nderivs.pt := f.R_s*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
      nderivs.st := cv/f.T;
      nderivs.sd := -nderivs.pt/(f.d*f.d);
    end Helmholtz_ps;

    function smoothStep
      "Approximation of a general step, such that the characteristic is continuous and differentiable"
      extends Modelica.Icons.Function;
      input Real x "Abscissa value";
      input Real y1 "Ordinate value for x > 0";
      input Real y2 "Ordinate value for x < 0";
      input Real x_small(min=0) = 1e-5
        "Approximation of step for -x_small <= x <= x_small; x_small > 0 required";
      output Real y "Ordinate value to approximate y = if x > 0 then y1 else y2";
    algorithm
      y := smooth(1, if x > x_small then y1 else if x < -x_small then y2 else if
        abs(x_small) > 0 then (x/x_small)*((x/x_small)^2 - 3)*(y2 - y1)/4 + (y1
         + y2)/2 else (y1 + y2)/2);

      annotation (
        Inline=true,
        smoothOrder=1,
        Documentation(revisions="<html>
<ul>
<li><em>April 29, 2008</em>
    by <a href=\"mailto:Martin.Otter@DLR.de\">Martin Otter</a>:<br>
    Designed and implemented.</li>
<li><em>August 12, 2008</em>
    by <a href=\"mailto:Michael.Sielemann@dlr.de\">Michael Sielemann</a>:<br>
    Minor modification to cover the limit case <code>x_small -> 0</code> without division by zero.</li>
</ul>
</html>",   info="<html>
<p>
This function is used to approximate the equation
</p>
<blockquote><pre>
y = <strong>if</strong> x &gt; 0 <strong>then</strong> y1 <strong>else</strong> y2;
</pre></blockquote>

<p>
by a smooth characteristic, so that the expression is continuous and differentiable:
</p>

<blockquote><pre>
y = <strong>smooth</strong>(1, <strong>if</strong> x &gt;  x_small <strong>then</strong> y1 <strong>else</strong>
              <strong>if</strong> x &lt; -x_small <strong>then</strong> y2 <strong>else</strong> f(y1, y2));
</pre></blockquote>

<p>
In the region -x_small &lt; x &lt; x_small a 2nd order polynomial is used
for a smooth transition from y1 to y2.
</p>

<p>
If <strong>mass fractions</strong> X[:] are approximated with this function then this can be performed
for all <strong>nX</strong> mass fractions, instead of applying it for nX-1 mass fractions and computing
the last one by the mass fraction constraint sum(X)=1. The reason is that the approximating function has the
property that sum(X) = 1, provided sum(X_a) = sum(X_b) = 1
(and y1=X_a[i], y2=X_b[i]).
This can be shown by evaluating the approximating function in the abs(x) &lt; x_small
region (otherwise X is either X_a or X_b):
</p>

<blockquote><pre>
X[1]  = smoothStep(x, X_a[1] , X_b[1] , x_small);
X[2]  = smoothStep(x, X_a[2] , X_b[2] , x_small);
   ...
X[nX] = smoothStep(x, X_a[nX], X_b[nX], x_small);
</pre></blockquote>

<p>
or
</p>

<blockquote><pre>
X[1]  = c*(X_a[1]  - X_b[1])  + (X_a[1]  + X_b[1])/2
X[2]  = c*(X_a[2]  - X_b[2])  + (X_a[2]  + X_b[2])/2;
   ...
X[nX] = c*(X_a[nX] - X_b[nX]) + (X_a[nX] + X_b[nX])/2;
c     = (x/x_small)*((x/x_small)^2 - 3)/4
</pre></blockquote>

<p>
Summing all mass fractions together results in
</p>

<blockquote><pre>
sum(X) = c*(sum(X_a) - sum(X_b)) + (sum(X_a) + sum(X_b))/2
       = c*(1 - 1) + (1 + 1)/2
       = 1
</pre></blockquote>
</html>"));
    end smoothStep;
    annotation (Documentation(info="<html><h4>Package description</h4>
      <p>Package Modelica.Media.Common provides records and functions shared by many of the property sub-packages.
      High accuracy fluid property models share a lot of common structure, even if the actual models are different.
      Common data structures and computations shared by these property models are collected in this library.
   </p>

</html>",   revisions="<html>
      <ul>
      <li>First implemented: <em>July, 2000</em>
      by Hubertus Tummescheit
      for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
      </li>
      <li>Code reorganization, enhanced documentation, additional functions: <em>December, 2002</em>
      by Hubertus Tummescheit and move to Modelica
                            properties library.</li>
      <li>Inclusion into Modelica.Media: September 2003</li>
      </ul>

      <address>Author: Hubertus Tummescheit,<br>
      Lund University<br>
      Department of Automatic Control<br>
      Box 118, 22100 Lund, Sweden<br>
      email: hubertus@control.lth.se
      </address>
</html>"));
  end Common;

    package Air "Medium models for air"
        extends Modelica.Icons.VariantsPackage;

      package MoistAir "Air: Moist air model (190 ... 647 K)"
        extends Interfaces.PartialCondensingGases(
          mediumName="Moist air",
          substanceNames={"water","air"},
          final reducedX=true,
          final singleState=false,
          reference_X={0.01,0.99},
          fluidConstants={IdealGases.Common.FluidData.H2O,IdealGases.Common.FluidData.N2},
          Temperature(min=190, max=647));
        import Modelica.Media.IdealGases.Common.Functions;

        constant Integer Water=1
          "Index of water (in substanceNames, massFractions X, etc.)";

        constant Integer Air=2
          "Index of air (in substanceNames, massFractions X, etc.)";

        constant Real k_mair=steam.MM/dryair.MM "Ratio of molar weights";

        constant IdealGases.Common.DataRecord dryair=IdealGases.Common.SingleGasesData.Air;

        constant IdealGases.Common.DataRecord steam=IdealGases.Common.SingleGasesData.H2O;

        constant SI.MolarMass[2] MMX={steam.MM,dryair.MM}
          "Molar masses of components";
        import Modelica.Media.Interfaces;
        import Modelica.Math;
        import Modelica.Constants;
        import Modelica.Media.IdealGases.Common.SingleGasNasa;
        import Modelica.Media.Interfaces.Choices.ReferenceEnthalpy;

        redeclare record extends ThermodynamicState
          "ThermodynamicState record for moist air"
        end ThermodynamicState;

        redeclare replaceable model extends BaseProperties(
          T(stateSelect=if preferredMediumStates then StateSelect.prefer else
                StateSelect.default),
          p(stateSelect=if preferredMediumStates then StateSelect.prefer else
                StateSelect.default),
          Xi(each stateSelect=if preferredMediumStates then StateSelect.prefer
                 else StateSelect.default),
          final standardOrderComponents=true) "Moist air base properties record"

          /* p, T, X = X[Water] are used as preferred states, since only then all
     other quantities can be computed in a recursive sequence.
     If other variables are selected as states, static state selection
     is no longer possible and non-linear algebraic equations occur.
      */
          MassFraction x_water "Mass of total water/mass of dry air";
          Real phi "Relative humidity";

      protected
          MassFraction X_liquid "Mass fraction of liquid or solid water";
          MassFraction X_steam "Mass fraction of steam water";
          MassFraction X_air "Mass fraction of air";
          MassFraction X_sat
            "Steam water mass fraction of saturation boundary in kg_water/kg_moistair";
          MassFraction x_sat
            "Steam water mass content of saturation boundary in kg_water/kg_dryair";
          AbsolutePressure p_steam_sat "Partial saturation pressure of steam";
        equation
          assert(T >= 190 and T <= 647, "
Temperature T is not in the allowed range
190.0 K <= (T ="     + String(T) + " K) <= 647.0 K
required from medium model \""     + mediumName + "\".");
          MM = 1/(Xi[Water]/MMX[Water] + (1.0 - Xi[Water])/MMX[Air]);

          p_steam_sat = min(saturationPressure(T), 0.999*p);
          X_sat = min(p_steam_sat*k_mair/max(100*Constants.eps, p - p_steam_sat)*(1
             - Xi[Water]), 1.0)
            "Water content at saturation with respect to actual water content";
          X_liquid = max(Xi[Water] - X_sat, 0.0);
          X_steam = Xi[Water] - X_liquid;
          X_air = 1 - Xi[Water];

          h = specificEnthalpy_pTX(
                p,
                T,
                Xi);
          R_s = dryair.R_s*(X_air/(1 - X_liquid)) + steam.R_s*X_steam/(1 - X_liquid);
          //
          u = h - R_s*T;
          d = p/(R_s*T);
          /* Note, u and d are computed under the assumption that the volume of the liquid
         water is negligible with respect to the volume of air and of steam
      */
          state.p = p;
          state.T = T;
          state.X = X;

          // these x are per unit mass of DRY air!
          x_sat = k_mair*p_steam_sat/max(100*Constants.eps, p - p_steam_sat);
          x_water = Xi[Water]/max(X_air, 100*Constants.eps);
          phi = p/p_steam_sat*Xi[Water]/(Xi[Water] + k_mair*X_air);
          annotation (Documentation(info="<html>
<p>This model computes thermodynamic properties of moist air from three independent (thermodynamic or/and numerical) state variables. Preferred numerical states are temperature T, pressure p and the reduced composition vector Xi, which contains the water mass fraction only. As an EOS the <strong>ideal gas law</strong> is used and associated restrictions apply. The model can also be used in the <strong>fog region</strong>, when moisture is present in its liquid state. However, it is assumed that the liquid water volume is negligible compared to that of the gas phase. Computation of thermal properties is based on property data of <a href=\"modelica://Modelica.Media.Air.DryAirNasa\"> dry air</a> and water (source: VDI-W&auml;rmeatlas), respectively. Besides the standard thermodynamic variables <strong>absolute and relative humidity</strong>, x_water and phi, respectively, are given by the model. Upper case X denotes absolute humidity with respect to mass of moist air while absolute humidity with respect to mass of dry air only is denoted by a lower case x throughout the model. See <a href=\"modelica://Modelica.Media.Air.MoistAir\">package description</a> for further information.</p>
</html>"));
        end BaseProperties;

        redeclare function setState_pTX
          "Return thermodynamic state as function of pressure p, temperature T and composition X"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction X[:]=reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state";
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(
                p=p,
                T=T,
                X=X) else ThermodynamicState(
                p=p,
                T=T,
                X=cat(
                  1,
                  X,
                  {1 - sum(X)}));
          annotation (smoothOrder=2, Documentation(info="<html>
The <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state record</a> is computed from pressure p, temperature T and composition X.
</html>"));
        end setState_pTX;

        redeclare function setState_phX
          "Return thermodynamic state as function of pressure p, specific enthalpy h and composition X"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction X[:]=reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state";
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(
                p=p,
                T=T_phX(
                  p,
                  h,
                  X),
                X=X) else ThermodynamicState(
                p=p,
                T=T_phX(
                  p,
                  h,
                  X),
                X=cat(
                  1,
                  X,
                  {1 - sum(X)}));
          annotation (smoothOrder=2, Documentation(info="<html>
The <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state record</a> is computed from pressure p, specific enthalpy h and composition X.
</html>"));
        end setState_phX;

        redeclare function setState_dTX
          "Return thermodynamic state as function of density d, temperature T and composition X"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input MassFraction X[:]=reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state";
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(
                p=d*({steam.R_s,dryair.R_s}*X)*T,
                T=T,
                X=X) else ThermodynamicState(
                p=d*({steam.R_s,dryair.R_s}*cat(
                  1,
                  X,
                  {1 - sum(X)}))*T,
                T=T,
                X=cat(
                  1,
                  X,
                  {1 - sum(X)}));
          annotation (smoothOrder=2, Documentation(info="<html>
The <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state record</a> is computed from density d, temperature T and composition X.
</html>"));
        end setState_dTX;

        redeclare function extends setSmoothState
          "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
        algorithm
          state := ThermodynamicState(
                p=Media.Common.smoothStep(
                  x,
                  state_a.p,
                  state_b.p,
                  x_small),
                T=Media.Common.smoothStep(
                  x,
                  state_a.T,
                  state_b.T,
                  x_small),
                X=Media.Common.smoothStep(
                  x,
                  state_a.X,
                  state_b.X,
                  x_small));
        end setSmoothState;

        redeclare function extends gasConstant
          "Return ideal gas constant as a function from thermodynamic state, only valid for phi<1"

        algorithm
          R_s := dryair.R_s*(1 - state.X[Water]) + steam.R_s*state.X[Water];
          annotation (smoothOrder=2, Documentation(info="<html>
The ideal gas constant for moist air is computed from <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state</a> assuming that all water is in the gas phase.
</html>"));
        end gasConstant;

        function saturationPressureLiquid
          "Return saturation pressure of water as a function of temperature T in the range of 273.16 to 647.096 K"

          extends Modelica.Icons.Function;
          input SI.Temperature Tsat "Saturation temperature";
          output SI.AbsolutePressure psat "Saturation pressure";
      protected
          SI.Temperature Tcritical=647.096 "Critical temperature";
          SI.AbsolutePressure pcritical=22.064e6 "Critical pressure";
          Real r1=(1 - Tsat/Tcritical) "Common subexpression";
          Real a[:]={-7.85951783,1.84408259,-11.7866497,22.6807411,-15.9618719,
              1.80122502} "Coefficients a[:]";
          Real n[:]={1.0,1.5,3.0,3.5,4.0,7.5} "Coefficients n[:]";
        algorithm
          psat := exp(((a[1]*r1^n[1] + a[2]*r1^n[2] + a[3]*r1^n[3] + a[4]*r1^n[4]
             + a[5]*r1^n[5] + a[6]*r1^n[6])*Tcritical)/Tsat)*pcritical;
          annotation (
            derivative=saturationPressureLiquid_der,
            Inline=false,
            smoothOrder=5,
            Documentation(info="<html>
<p>Saturation pressure of water above the triple point temperature is computed from temperature.</p>
<p>Source: A Saul, W Wagner: &quot;International equations for the saturation properties of ordinary water substance&quot;, equation 2.1</p>
</html>"));
        end saturationPressureLiquid;

        function saturationPressureLiquid_der
          "Derivative function for 'saturationPressureLiquid'"

          extends Modelica.Icons.Function;
          input SI.Temperature Tsat "Saturation temperature";
          input Real dTsat(unit="K/s") "Saturation temperature derivative";
          output Real psat_der(unit="Pa/s") "Saturation pressure derivative";
      protected
          SI.Temperature Tcritical=647.096 "Critical temperature";
          SI.AbsolutePressure pcritical=22.064e6 "Critical pressure";
          Real r1=(1 - Tsat/Tcritical) "Common subexpression 1";
          Real r1_der=-1/Tcritical*dTsat "Derivative of common subexpression 1";
          Real a[:]={-7.85951783,1.84408259,-11.7866497,22.6807411,-15.9618719,
              1.80122502} "Coefficients a[:]";
          Real n[:]={1.0,1.5,3.0,3.5,4.0,7.5} "Coefficients n[:]";
          Real r2=(a[1]*r1^n[1] + a[2]*r1^n[2] + a[3]*r1^n[3] + a[4]*r1^n[4] + a[5]
              *r1^n[5] + a[6]*r1^n[6]) "Common subexpression 2";
        algorithm
          // Approach used here is based on Baehr: "Thermodynamik", 12th edition p.204ff, "Method of Wagner"
          //psat := exp(((a[1]*r1^n[1] + a[2]*r1^n[2] + a[3]*r1^n[3] + a[4]*r1^n[4] + a[5]*r1^n[5] + a[6]*r1^n[6])*Tcritical)/Tsat) * pcritical;
          psat_der := exp((r2*Tcritical)/Tsat)*pcritical*((a[1]*(r1^(n[1] - 1)*n[1]
            *r1_der) + a[2]*(r1^(n[2] - 1)*n[2]*r1_der) + a[3]*(r1^(n[3] - 1)*n[3]*
            r1_der) + a[4]*(r1^(n[4] - 1)*n[4]*r1_der) + a[5]*(r1^(n[5] - 1)*n[5]*
            r1_der) + a[6]*(r1^(n[6] - 1)*n[6]*r1_der))*Tcritical/Tsat - r2*
            Tcritical*dTsat/Tsat^2);
          annotation (
            Inline=false,
            smoothOrder=5,
            Documentation(info="<html>
<p>Saturation pressure of water above the triple point temperature is computed from temperature.</p>
<p>Source: A Saul, W Wagner: &quot;International equations for the saturation properties of ordinary water substance&quot;, equation 2.1</p>
</html>"));
        end saturationPressureLiquid_der;

        function sublimationPressureIce
          "Return sublimation pressure of water as a function of temperature T between 190 and 273.16 K"

          extends Modelica.Icons.Function;
          input SI.Temperature Tsat "Sublimation temperature";
          output SI.AbsolutePressure psat "Sublimation pressure";
      protected
          SI.Temperature Ttriple=273.16 "Triple point temperature";
          SI.AbsolutePressure ptriple=611.657 "Triple point pressure";
          Real r1=Tsat/Ttriple "Common subexpression";
          Real a[:]={-13.9281690,34.7078238} "Coefficients a[:]";
          Real n[:]={-1.5,-1.25} "Coefficients n[:]";
        algorithm
          psat := exp(a[1] - a[1]*r1^n[1] + a[2] - a[2]*r1^n[2])*ptriple;
          annotation (
            Inline=false,
            smoothOrder=5,
            derivative=sublimationPressureIce_der,
            Documentation(info="<html>
<p>Sublimation pressure of water below the triple point temperature is computed from temperature.</p>
<p>Source: W Wagner, A Saul, A Pruss: &quot;International equations for the pressure along the melting and along the sublimation curve of ordinary water substance&quot;, equation 3.5</p>
</html>"));
        end sublimationPressureIce;

        function sublimationPressureIce_der
          "Derivative function for 'sublimationPressureIce'"

          extends Modelica.Icons.Function;
          input SI.Temperature Tsat "Sublimation temperature";
          input Real dTsat(unit="K/s") "Sublimation temperature derivative";
          output Real psat_der(unit="Pa/s") "Sublimation pressure derivative";
      protected
          SI.Temperature Ttriple=273.16 "Triple point temperature";
          SI.AbsolutePressure ptriple=611.657 "Triple point pressure";
          Real r1=Tsat/Ttriple "Common subexpression 1";
          Real r1_der=dTsat/Ttriple "Derivative of common subexpression 1";
          Real a[:]={-13.9281690,34.7078238} "Coefficients a[:]";
          Real n[:]={-1.5,-1.25} "Coefficients n[:]";
        algorithm
          //psat := exp(a[1] - a[1]*r1^n[1] + a[2] - a[2]*r1^n[2]) * ptriple;
          psat_der := exp(a[1] - a[1]*r1^n[1] + a[2] - a[2]*r1^n[2])*ptriple*(-(a[1]
            *(r1^(n[1] - 1)*n[1]*r1_der)) - (a[2]*(r1^(n[2] - 1)*n[2]*r1_der)));
          annotation (
            Inline=false,
            smoothOrder=5,
            Documentation(info="<html>
<p>Sublimation pressure of water below the triple point temperature is computed from temperature.</p>
<p>Source: W Wagner, A Saul, A Pruss: &quot;International equations for the pressure along the melting and along the sublimation curve of ordinary water substance&quot;, equation 3.5</p>
</html>"));
        end sublimationPressureIce_der;

        redeclare function extends saturationPressure
          "Return saturation pressure of water as a function of temperature T between 190 and 647.096 K"

        algorithm
          psat := Utilities.spliceFunction(
                saturationPressureLiquid(Tsat),
                sublimationPressureIce(Tsat),
                Tsat - 273.16,
                1.0);
          annotation (
            Inline=false,
            smoothOrder=5,
            derivative=saturationPressure_der,
            Documentation(info="<html>
Saturation pressure of water in the liquid and the solid region is computed using correlations. Functions for the
<a href=\"modelica://Modelica.Media.Air.MoistAir.sublimationPressureIce\">solid</a> and the <a href=\"modelica://Modelica.Media.Air.MoistAir.saturationPressureLiquid\"> liquid</a> region, respectively, are combined using the first derivative continuous <a href=\"modelica://Modelica.Media.Air.MoistAir.Utilities.spliceFunction\">spliceFunction</a>. This functions range of validity is from 190 to 647.096 K. For more information on the type of correlation used, see the documentation of the linked functions.
</html>"));
        end saturationPressure;

        function saturationPressure_der
          "Derivative function for 'saturationPressure'"
          extends Modelica.Icons.Function;
          input Temperature Tsat "Saturation temperature";
          input Real dTsat(unit="K/s") "Time derivative of saturation temperature";
          output Real psat_der(unit="Pa/s") "Saturation pressure";

        algorithm
          /*psat := Utilities.spliceFunction(saturationPressureLiquid(Tsat),sublimationPressureIce(Tsat),Tsat-273.16,1.0);*/
          psat_der := Utilities.spliceFunction_der(
                saturationPressureLiquid(Tsat),
                sublimationPressureIce(Tsat),
                Tsat - 273.16,
                1.0,
                saturationPressureLiquid_der(Tsat=Tsat, dTsat=dTsat),
                sublimationPressureIce_der(Tsat=Tsat, dTsat=dTsat),
                dTsat,
                0);
          annotation (
            Inline=false,
            smoothOrder=5,
            Documentation(info="<html>
Derivative function of <a href=\"modelica://Modelica.Media.Air.MoistAir.saturationPressure\">saturationPressure</a>
</html>"));
        end saturationPressure_der;

        redeclare function extends enthalpyOfVaporization
          "Return enthalpy of vaporization of water as a function of temperature T, 273.16 to 647.096 K"

      protected
          Real Tcritical=647.096 "Critical temperature";
          Real dcritical=322 "Critical density";
          Real pcritical=22.064e6 "Critical pressure";
          Real n[:]={1,1.5,3,3.5,4,7.5} "Powers in equation (1)";
          Real a[:]={-7.85951783,1.84408259,-11.7866497,22.6807411,-15.9618719,
              1.80122502} "Coefficients in equation (1) of [1]";
          Real m[:]={1/3,2/3,5/3,16/3,43/3,110/3} "Powers in equation (2)";
          Real b[:]={1.99274064,1.09965342,-0.510839303,-1.75493479,-45.5170352,-6.74694450e5}
            "Coefficients in equation (2) of [1]";
          Real o[:]={2/6,4/6,8/6,18/6,37/6,71/6} "Powers in equation (3)";
          Real c[:]={-2.03150240,-2.68302940,-5.38626492,-17.2991605,-44.7586581,-63.9201063}
            "Coefficients in equation (3) of [1]";
          Real tau=1 - T/Tcritical "Temperature expression";
          Real r1=(a[1]*Tcritical*tau^n[1])/T + (a[2]*Tcritical*tau^n[2])/T + (a[3]
              *Tcritical*tau^n[3])/T + (a[4]*Tcritical*tau^n[4])/T + (a[5]*
              Tcritical*tau^n[5])/T + (a[6]*Tcritical*tau^n[6])/T "Expression 1";
          Real r2=a[1]*n[1]*tau^n[1] + a[2]*n[2]*tau^n[2] + a[3]*n[3]*tau^n[3] + a[
              4]*n[4]*tau^n[4] + a[5]*n[5]*tau^n[5] + a[6]*n[6]*tau^n[6]
            "Expression 2";
          Real dp=dcritical*(1 + b[1]*tau^m[1] + b[2]*tau^m[2] + b[3]*tau^m[3] + b[
              4]*tau^m[4] + b[5]*tau^m[5] + b[6]*tau^m[6])
            "Density of saturated liquid";
          Real dpp=dcritical*exp(c[1]*tau^o[1] + c[2]*tau^o[2] + c[3]*tau^o[3] + c[
              4]*tau^o[4] + c[5]*tau^o[5] + c[6]*tau^o[6])
            "Density of saturated vapor";
        algorithm
          r0 := -(((dp - dpp)*exp(r1)*pcritical*(r2 + r1*tau))/(dp*dpp*tau))
            "Difference of equations (7) and (6)";
          annotation (
            smoothOrder=2,
            Documentation(info="<html>
<p>Enthalpy of vaporization of water is computed from temperature in the region of 273.16 to 647.096 K.</p>
<p>Source: W Wagner, A Pruss: \"International equations for the saturation properties of ordinary water substance. Revised according to the international temperature scale of 1990\" (1993).</p>
</html>"));
        end enthalpyOfVaporization;

        redeclare function extends enthalpyOfLiquid
          "Return enthalpy of liquid water as a function of temperature T(use enthalpyOfWater instead)"

        algorithm
          h := (T - 273.15)*1e3*(4.2166 - 0.5*(T - 273.15)*(0.0033166 + 0.333333*(T
             - 273.15)*(0.00010295 - 0.25*(T - 273.15)*(1.3819e-6 + 0.2*(T - 273.15)
            *7.3221e-9))));
          annotation (
            Inline=false,
            smoothOrder=5,
            Documentation(info="<html>
Specific enthalpy of liquid water is computed from temperature using a polynomial approach. Kept for compatibility reasons, better use <a href=\"modelica://Modelica.Media.Air.MoistAir.enthalpyOfWater\">enthalpyOfWater</a> instead.
</html>"));
        end enthalpyOfLiquid;

        redeclare function extends enthalpyOfGas
          "Return specific enthalpy of gas (air and steam) as a function of temperature T and composition X"

        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=steam,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=46479.819 + 2501014.5)*X[Water] +
            Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=dryair,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=25104.684)*(1.0 - X[Water]);
          annotation (
            Inline=false,
            smoothOrder=5,
            Documentation(info="<html>
Specific enthalpy of moist air is computed from temperature, provided all water is in the gaseous state. The first entry in the composition vector X must be the mass fraction of steam. For a function that also covers the fog region please refer to <a href=\"modelica://Modelica.Media.Air.MoistAir.h_pTX\">h_pTX</a>.
</html>"));
        end enthalpyOfGas;

        redeclare function extends enthalpyOfCondensingGas
          "Return specific enthalpy of steam as a function of temperature T"

        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=steam,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=46479.819 + 2501014.5);
          annotation (
            Inline=false,
            smoothOrder=5,
            Documentation(info="<html>
Specific enthalpy of steam is computed from temperature.
</html>"));
        end enthalpyOfCondensingGas;

        redeclare function extends enthalpyOfNonCondensingGas
          "Return specific enthalpy of dry air as a function of temperature T"

        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=dryair,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=25104.684);
          annotation (
            Inline=false,
            smoothOrder=1,
            Documentation(info="<html>
Specific enthalpy of dry air is computed from temperature.
</html>"));
        end enthalpyOfNonCondensingGas;

        function enthalpyOfWater
          "Computes specific enthalpy of water (solid/liquid) near atmospheric pressure from temperature T"
          extends Modelica.Icons.Function;
          input SI.Temperature T "Temperature";
          output SI.SpecificEnthalpy h "Specific enthalpy of water";
        algorithm
          /*simple model assuming constant properties:
  heat capacity of liquid water:4200 J/kg
  heat capacity of solid water: 2050 J/kg
  enthalpy of fusion (liquid=>solid): 333000 J/kg*/

          h := Utilities.spliceFunction(
                4200*(T - 273.15),
                2050*(T - 273.15) - 333000,
                T - 273.16,
                0.1);
          annotation (derivative=enthalpyOfWater_der, Documentation(info="<html>
Specific enthalpy of water (liquid and solid) is computed from temperature using constant properties as follows:<br>
<ul>
<li>heat capacity of liquid water:4200 J/kg</li>
<li>heat capacity of solid water: 2050 J/kg</li>
<li>enthalpy of fusion (liquid=>solid): 333000 J/kg</li>
</ul>
Pressure is assumed to be around 1 bar. This function is usually used to determine the specific enthalpy of the liquid or solid fraction of moist air.
</html>"));
        end enthalpyOfWater;

        function enthalpyOfWater_der "Derivative function of enthalpyOfWater"
          extends Modelica.Icons.Function;
          input SI.Temperature T "Temperature";
          input Real dT(unit="K/s") "Time derivative of temperature";
          output Real dh(unit="J/(kg.s)") "Time derivative of specific enthalpy";
        algorithm
          /*simple model assuming constant properties:
  heat capacity of liquid water:4200 J/kg
  heat capacity of solid water: 2050 J/kg
  enthalpy of fusion (liquid=>solid): 333000 J/kg*/

          //h:=Utilities.spliceFunction(4200*(T-273.15),2050*(T-273.15)-333000,T-273.16,0.1);
          dh := Utilities.spliceFunction_der(
                4200*(T - 273.15),
                2050*(T - 273.15) - 333000,
                T - 273.16,
                0.1,
                4200*dT,
                2050*dT,
                dT,
                0);
          annotation (Documentation(info="<html>
Derivative function for <a href=\"modelica://Modelica.Media.Air.MoistAir.enthalpyOfWater\">enthalpyOfWater</a>.

</html>"));
        end enthalpyOfWater_der;

        redeclare function extends pressure
          "Returns pressure of ideal gas as a function of the thermodynamic state record"

        algorithm
          p := state.p;
          annotation (smoothOrder=2, Documentation(info="<html>
Pressure is returned from the thermodynamic state record input as a simple assignment.
</html>"));
        end pressure;

        redeclare function extends temperature
          "Return temperature of ideal gas as a function of the thermodynamic state record"

        algorithm
          T := state.T;
          annotation (smoothOrder=2, Documentation(info="<html>
Temperature is returned from the thermodynamic state record input as a simple assignment.
</html>"));
        end temperature;

        function T_phX
          "Return temperature as a function of pressure p, specific enthalpy h and composition X"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X "Mass fractions of composition";
          output Temperature T "Temperature";

      protected
          function f_nonlinear "Solve h_pTX(p,T,X) for T with given h"
            extends Modelica.Math.Nonlinear.Interfaces.partialScalarFunction;
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction[:] X "Mass fractions of composition";
          algorithm
            y := h_pTX(p=p, T=u, X=X) - h;
          end f_nonlinear;

        algorithm
          T := Modelica.Math.Nonlinear.solveOneNonlinearEquation(
            function f_nonlinear(p=p, h=h, X=X[1:nXi]), 190, 647);
          annotation (Documentation(info="<html>
Temperature is computed from pressure, specific enthalpy and composition via numerical inversion of function <a href=\"modelica://Modelica.Media.Air.MoistAir.h_pTX\">h_pTX</a>.
</html>"));
        end T_phX;

        redeclare function extends density
          "Returns density of ideal gas as a function of the thermodynamic state record"

        algorithm
          d := state.p/(gasConstant(state)*state.T);
          annotation (smoothOrder=2, Documentation(info="<html>
Density is computed from pressure, temperature and composition in the thermodynamic state record applying the ideal gas law.
</html>"));
        end density;

        redeclare function extends specificEnthalpy
          "Return specific enthalpy of moist air as a function of the thermodynamic state record"

        algorithm
          h := h_pTX(
                state.p,
                state.T,
                state.X);
          annotation (smoothOrder=2, Documentation(info="<html>
Specific enthalpy of moist air is computed from the thermodynamic state record. The fog region is included for both, ice and liquid fog.
</html>"));
        end specificEnthalpy;

        function h_pTX
          "Return specific enthalpy of moist air as a function of pressure p, temperature T and composition X"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input SI.MassFraction X[:] "Mass fractions of moist air";
          output SI.SpecificEnthalpy h "Specific enthalpy at p, T, X";
      protected
          SI.AbsolutePressure p_steam_sat "Partial saturation pressure of steam";
          SI.MassFraction X_sat "Absolute humidity per unit mass of moist air";
          SI.MassFraction X_liquid "Mass fraction of liquid water";
          SI.MassFraction X_steam "Mass fraction of steam water";
          SI.MassFraction X_air "Mass fraction of air";
        algorithm
          p_steam_sat := saturationPressure(T);
          //p_steam_sat :=min(saturationPressure(T), 0.999*p);
          X_sat := min(p_steam_sat*k_mair/max(100*Constants.eps, p - p_steam_sat)*(
            1 - X[Water]), 1.0);
          X_liquid := max(X[Water] - X_sat, 0.0);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          /* h        := {SingleGasNasa.h_Tlow(data=steam,  T=T, refChoice=ReferenceEnthalpy.UserDefined, h_off=46479.819+2501014.5),
               SingleGasNasa.h_Tlow(data=dryair, T=T, refChoice=ReferenceEnthalpy.UserDefined, h_off=25104.684)}*
    {X_steam, X_air} + enthalpyOfLiquid(T)*X_liquid;*/
          h := {Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=steam,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=46479.819 + 2501014.5),
            Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=dryair,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=25104.684)}*{X_steam,X_air} + enthalpyOfWater(T)*X_liquid;
          annotation (
            derivative=h_pTX_der,
            Inline=false,
            Documentation(info="<html>
Specific enthalpy of moist air is computed from pressure, temperature and composition with X[1] as the total water mass fraction. The fog region is included for both, ice and liquid fog.
</html>"));
        end h_pTX;

        function h_pTX_der "Derivative function of h_pTX"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input SI.MassFraction X[:] "Mass fractions of moist air";
          input Real dp(unit="Pa/s") "Pressure derivative";
          input Real dT(unit="K/s") "Temperature derivative";
          input Real dX[:](each unit="1/s") "Composition derivative";
          output Real h_der(unit="J/(kg.s)") "Time derivative of specific enthalpy";
      protected
          SI.AbsolutePressure p_steam_sat "Partial saturation pressure of steam";
          SI.MassFraction X_sat "Absolute humidity per unit mass of moist air";
          SI.MassFraction X_liquid "Mass fraction of liquid water";
          SI.MassFraction X_steam "Mass fraction of steam water";
          SI.MassFraction X_air "Mass fraction of air";
          SI.MassFraction x_sat
            "Absolute humidity per unit mass of dry air at saturation";
          Real dX_steam(unit="1/s") "Time derivative of steam mass fraction";
          Real dX_air(unit="1/s") "Time derivative of dry air mass fraction";
          Real dX_liq(unit="1/s")
            "Time derivative of liquid/solid water mass fraction";
          Real dps(unit="Pa/s") "Time derivative of saturation pressure";
          Real dx_sat(unit="1/s")
            "Time derivative of absolute humidity per unit mass of dry air";
        algorithm
          p_steam_sat := saturationPressure(T);
          x_sat := p_steam_sat*k_mair/max(100*Modelica.Constants.eps, p -
            p_steam_sat);
          X_sat := min(x_sat*(1 - X[Water]), 1.0);
          X_liquid := Utilities.smoothMax(
                X[Water] - X_sat,
                0.0,
                1e-5);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];

          dX_air := -dX[Water];
          dps := saturationPressure_der(Tsat=T, dTsat=dT);
          dx_sat := k_mair*(dps*(p - p_steam_sat) - p_steam_sat*(dp - dps))/(p -
            p_steam_sat)/(p - p_steam_sat);
          dX_liq := Utilities.smoothMax_der(
                X[Water] - X_sat,
                0.0,
                1e-5,
                (1 + x_sat)*dX[Water] - (1 - X[Water])*dx_sat,
                0,
                0);
          dX_steam := dX[Water] - dX_liq;

          h_der := X_steam*Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(
                data=steam,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=46479.819 + 2501014.5,
                dT=dT) + dX_steam*Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=steam,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=46479.819 + 2501014.5) + X_air*
            Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(
                data=dryair,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=25104.684,
                dT=dT) + dX_air*Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=dryair,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=25104.684) + X_liquid*enthalpyOfWater_der(T=T, dT=dT) +
            dX_liq*enthalpyOfWater(T);

          annotation (
            Inline=false,
            smoothOrder=1,
            Documentation(info="<html>
Derivative function for <a href=\"modelica://Modelica.Media.Air.MoistAir.h_pTX\">h_pTX</a>.
</html>"));
        end h_pTX_der;

        redeclare function extends isentropicExponent
          "Return isentropic exponent (only for gas fraction!)"
        algorithm
          gamma := specificHeatCapacityCp(state)/specificHeatCapacityCv(state);
        end isentropicExponent;

        redeclare function extends specificInternalEnergy
          "Return specific internal energy of moist air as a function of the thermodynamic state record"
          extends Modelica.Icons.Function;
        algorithm
          u := specificInternalEnergy_pTX(
                state.p,
                state.T,
                state.X);

          annotation (smoothOrder=2, Documentation(info="<html>
Specific internal energy is determined from the thermodynamic state record, assuming that the liquid or solid water volume is negligible.
</html>"));
        end specificInternalEnergy;

        function specificInternalEnergy_pTX
          "Return specific internal energy of moist air as a function of pressure p, temperature T and composition X"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input SI.MassFraction X[:] "Mass fractions of moist air";
          output SI.SpecificInternalEnergy u "Specific internal energy";
      protected
          SI.AbsolutePressure p_steam_sat "Partial saturation pressure of steam";
          SI.MassFraction X_liquid "Mass fraction of liquid water";
          SI.MassFraction X_steam "Mass fraction of steam water";
          SI.MassFraction X_air "Mass fraction of air";
          SI.MassFraction X_sat "Absolute humidity per unit mass of moist air";
          SI.SpecificHeatCapacity R_gas "Ideal gas constant";
        algorithm
          p_steam_sat := saturationPressure(T);
          X_sat := min(p_steam_sat*k_mair/max(100*Constants.eps, p - p_steam_sat)*(
            1 - X[Water]), 1.0);
          X_liquid := max(X[Water] - X_sat, 0.0);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          R_gas := dryair.R_s*X_air/(1 - X_liquid) + steam.R_s*X_steam/(1 - X_liquid);
          u := X_steam*Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=steam,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=46479.819 + 2501014.5) + X_air*
            Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=dryair,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=25104.684) + enthalpyOfWater(T)*X_liquid - R_gas*T;

          annotation (derivative=specificInternalEnergy_pTX_der, Documentation(info=
                 "<html>
Specific internal energy is determined from pressure p, temperature T and composition X, assuming that the liquid or solid water volume is negligible.
</html>"));
        end specificInternalEnergy_pTX;

        function specificInternalEnergy_pTX_der
          "Derivative function for specificInternalEnergy_pTX"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input SI.MassFraction X[:] "Mass fractions of moist air";
          input Real dp(unit="Pa/s") "Pressure derivative";
          input Real dT(unit="K/s") "Temperature derivative";
          input Real dX[:](each unit="1/s") "Mass fraction derivatives";
          output Real u_der(unit="J/(kg.s)") "Specific internal energy derivative";
      protected
          SI.AbsolutePressure p_steam_sat "Partial saturation pressure of steam";
          SI.MassFraction X_liquid "Mass fraction of liquid water";
          SI.MassFraction X_steam "Mass fraction of steam water";
          SI.MassFraction X_air "Mass fraction of air";
          SI.MassFraction X_sat "Absolute humidity per unit mass of moist air";
          SI.SpecificHeatCapacity R_gas "Ideal gas constant";

          SI.MassFraction x_sat
            "Absolute humidity per unit mass of dry air at saturation";
          Real dX_steam(unit="1/s") "Time derivative of steam mass fraction";
          Real dX_air(unit="1/s") "Time derivative of dry air mass fraction";
          Real dX_liq(unit="1/s")
            "Time derivative of liquid/solid water mass fraction";
          Real dps(unit="Pa/s") "Time derivative of saturation pressure";
          Real dx_sat(unit="1/s")
            "Time derivative of absolute humidity per unit mass of dry air";
          Real dR_gas(unit="J/(kg.K.s)") "Time derivative of ideal gas constant";
        algorithm
          p_steam_sat := saturationPressure(T);
          x_sat := p_steam_sat*k_mair/max(100*Modelica.Constants.eps, p -
            p_steam_sat);
          X_sat := min(x_sat*(1 - X[Water]), 1.0);
          X_liquid := Utilities.spliceFunction(
                X[Water] - X_sat,
                0.0,
                X[Water] - X_sat,
                1e-6);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          R_gas := steam.R_s*X_steam/(1 - X_liquid) + dryair.R_s*X_air/(1 - X_liquid);

          dX_air := -dX[Water];
          dps := saturationPressure_der(Tsat=T, dTsat=dT);
          dx_sat := k_mair*(dps*(p - p_steam_sat) - p_steam_sat*(dp - dps))/(p -
            p_steam_sat)/(p - p_steam_sat);
          dX_liq := Utilities.spliceFunction_der(
                X[Water] - X_sat,
                0.0,
                X[Water] - X_sat,
                1e-6,
                (1 + x_sat)*dX[Water] - (1 - X[Water])*dx_sat,
                0.0,
                (1 + x_sat)*dX[Water] - (1 - X[Water])*dx_sat,
                0.0);
          dX_steam := dX[Water] - dX_liq;
          dR_gas := (steam.R_s*(dX_steam*(1 - X_liquid) + dX_liq*X_steam) + dryair.R_s*
            (dX_air*(1 - X_liquid) + dX_liq*X_air))/(1 - X_liquid)/(1 - X_liquid);

          u_der := X_steam*Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(
                data=steam,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=46479.819 + 2501014.5,
                dT=dT) + dX_steam*Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=steam,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=46479.819 + 2501014.5) + X_air*
            Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(
                data=dryair,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=25104.684,
                dT=dT) + dX_air*Modelica.Media.IdealGases.Common.Functions.h_Tlow(
                data=dryair,
                T=T,
                refChoice=ReferenceEnthalpy.UserDefined,
                h_off=25104.684) + X_liquid*enthalpyOfWater_der(T=T, dT=dT) +
            dX_liq*enthalpyOfWater(T) - dR_gas*T - R_gas*dT;
          annotation (Documentation(info="<html>
Derivative function for <a href=\"modelica://Modelica.Media.Air.MoistAir.specificInternalEnergy_pTX\">specificInternalEnergy_pTX</a>.
</html>"));
        end specificInternalEnergy_pTX_der;

        redeclare function extends specificEntropy
          "Return specific entropy from thermodynamic state record, only valid for phi<1"

        algorithm
          s := s_pTX(
                state.p,
                state.T,
                state.X);
          annotation (
            Inline=false,
            smoothOrder=2,
            Documentation(info="<html>
Specific entropy is calculated from the thermodynamic state record, assuming ideal gas behavior and including entropy of mixing. Liquid or solid water is not taken into account, the entire water content X[1] is assumed to be in the vapor state (relative humidity below 1.0).
</html>"));
        end specificEntropy;

        redeclare function extends specificGibbsEnergy
          "Return specific Gibbs energy as a function of the thermodynamic state record, only valid for phi<1"
          extends Modelica.Icons.Function;
        algorithm
          g := h_pTX(
                state.p,
                state.T,
                state.X) - state.T*specificEntropy(state);
          annotation (smoothOrder=2, Documentation(info="<html>
The Gibbs Energy is computed from the thermodynamic state record for moist air with a water content below saturation.
</html>"));
        end specificGibbsEnergy;

        redeclare function extends specificHelmholtzEnergy
          "Return specific Helmholtz energy as a function of the thermodynamic state record, only valid for phi<1"
          extends Modelica.Icons.Function;
        algorithm
          f := h_pTX(
                state.p,
                state.T,
                state.X) - gasConstant(state)*state.T - state.T*specificEntropy(
            state);
          annotation (smoothOrder=2, Documentation(info="<html>
The Specific Helmholtz Energy is computed from the thermodynamic state record for moist air with a water content below saturation.
</html>"));
        end specificHelmholtzEnergy;

        redeclare function extends specificHeatCapacityCp
          "Return specific heat capacity at constant pressure as a function of the thermodynamic state record"

      protected
          Real dT(unit="s/K") = 1.0;
        algorithm
          cp := h_pTX_der(
                state.p,
                state.T,
                state.X,
                0.0,
                1.0,
                zeros(size(state.X, 1)))*dT "Definition of cp: dh/dT @ constant p";
          //      cp:= SingleGasNasa.cp_Tlow(dryair, state.T)*(1-state.X[Water])
          //        + SingleGasNasa.cp_Tlow(steam, state.T)*state.X[Water];
          annotation (
            Inline=false,
            smoothOrder=2,
            Documentation(info="<html>
The specific heat capacity at constant pressure <strong>cp</strong> is computed from temperature and composition for a mixture of steam (X[1]) and dry air. All water is assumed to be in the vapor state.
</html>"));
        end specificHeatCapacityCp;

        redeclare function extends specificHeatCapacityCv
          "Return specific heat capacity at constant volume as a function of the thermodynamic state record"

        algorithm
          cv := Modelica.Media.IdealGases.Common.Functions.cp_Tlow(dryair, state.T)
            *(1 - state.X[Water]) +
            Modelica.Media.IdealGases.Common.Functions.cp_Tlow(steam, state.T)*
            state.X[Water] - gasConstant(state);
          annotation (
            Inline=false,
            smoothOrder=2,
            Documentation(info="<html>
The specific heat capacity at constant density <strong>cv</strong> is computed from temperature and composition for a mixture of steam (X[1]) and dry air. All water is assumed to be in the vapor state.
</html>"));
        end specificHeatCapacityCv;

      redeclare function extends dynamicViscosity
          "Return dynamic viscosity as a function of the thermodynamic state record, valid from 123.15 K to 1273.15 K"

        import Modelica.Math.Polynomials;
      algorithm
        eta := 1e-6*Polynomials.evaluateWithRange(
            {9.7391102886305869E-15,-3.1353724870333906E-11,4.3004876595642225E-08,
            -3.8228016291758240E-05,5.0427874367180762E-02,1.7239260139242528E+01},
            Cv.to_degC(123.15),
            Cv.to_degC(1273.15),
            Cv.to_degC(state.T));
        annotation (smoothOrder=2, Documentation(info="<html>
<p>Dynamic viscosity is computed from temperature using a simple polynomial for dry air. Range of validity is from 123.15 K to 1273.15 K. The influence of pressure and moisture is neglected.</p>
<p>Source: VDI Waermeatlas, 8th edition.</p>
</html>"));
      end dynamicViscosity;

      redeclare function extends thermalConductivity
          "Return thermal conductivity as a function of the thermodynamic state record, valid from 123.15 K to 1273.15 K"
        import Modelica.Math.Polynomials;
      algorithm
        lambda := 1e-3*Polynomials.evaluateWithRange(
            {6.5691470817717812E-15,-3.4025961923050509E-11,5.3279284846303157E-08,
            -4.5340839289219472E-05,7.6129675309037664E-02,2.4169481088097051E+01},
            Cv.to_degC(123.15),
            Cv.to_degC(1273.15),
            Cv.to_degC(state.T));

        annotation (smoothOrder=2, Documentation(info="<html>
<p>Thermal conductivity is computed from temperature using a simple polynomial for dry air. Range of validity is from 123.15 K to 1273.15 K. The influence of pressure and moisture is neglected.</p>
<p>Source: VDI Waermeatlas, 8th edition.</p>
</html>"));
      end thermalConductivity;

        redeclare function extends velocityOfSound
        algorithm
          a := sqrt(isentropicExponent(state)*gasConstant(state)*temperature(state));
          annotation (Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end velocityOfSound;

        redeclare function extends isobaricExpansionCoefficient

        algorithm
          beta := 1/temperature(state);
          annotation (Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end isobaricExpansionCoefficient;

        redeclare function extends isothermalCompressibility

        algorithm
          kappa := 1/pressure(state);
          annotation (Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end isothermalCompressibility;

        redeclare function extends density_derp_h

        algorithm
          ddph := 1/(gasConstant(state)*temperature(state));

          annotation (Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end density_derp_h;

        redeclare function extends density_derh_p

        algorithm
          ddhp := -density(state)/(specificHeatCapacityCp(state)*temperature(state));
          annotation (Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end density_derh_p;

        redeclare function extends density_derp_T

        algorithm
          ddpT := 1/(gasConstant(state)*temperature(state));

          annotation (Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end density_derp_T;

        redeclare function extends density_derT_p

        algorithm
          ddTp := -density(state)/temperature(state);
          annotation (Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end density_derT_p;

        redeclare function extends density_derX

        algorithm
          dddX[Water] := - pressure(state)*(steam.R_s - dryair.R_s)/(((steam.R_s - dryair.R_s)
            *state.X[Water] + dryair.R_s)^2*temperature(state));
          dddX[Air] := - pressure(state)*(dryair.R_s - steam.R_s)/((steam.R_s + (dryair.R_s - steam.R_s)*
            state.X[Air])^2*temperature(state));

          annotation (Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
<p>2019-05-14        Stefan Wischhusen: Corrected derivatives.</p>
</html>"));
        end density_derX;

        redeclare function extends molarMass
        algorithm
          MM := Modelica.Constants.R/Modelica.Media.Air.MoistAir.gasConstant(state);
          annotation (Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end molarMass;

        function T_psX
          "Return temperature as a function of pressure p, specific entropy s and composition X"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X "Mass fractions of composition";
          output Temperature T "Temperature";

      protected
          function f_nonlinear "Solve s_pTX(p,T,X) for T with given s"
            extends Modelica.Math.Nonlinear.Interfaces.partialScalarFunction;
            input AbsolutePressure p "Pressure";
            input SpecificEntropy s "Specific entropy";
            input MassFraction[:] X "Mass fractions of composition";
          algorithm
            y := s_pTX(p=p, T=u, X=X) - s;
          end f_nonlinear;

        algorithm
          T := Modelica.Math.Nonlinear.solveOneNonlinearEquation(
            function f_nonlinear(p=p, s=s, X=X[1:nX]), 190, 647);
          annotation (Documentation(info="<html>
Temperature is computed from pressure, specific entropy and composition via numerical inversion of function <a href=\"modelica://Modelica.Media.Air.MoistAir.s_pTX\">s_pTX</a>.
</html>",     revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end T_psX;

        redeclare function extends setState_psX
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(
                p=p,
                T=T_psX(
                  p,
                  s,
                  X),
                X=X) else ThermodynamicState(
                p=p,
                T=T_psX(
                  p,
                  s,
                  X),
                X=cat(
                  1,
                  X,
                  {1 - sum(X)}));
          annotation (smoothOrder=2, Documentation(info="<html>
The <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state record</a> is computed from pressure p, specific enthalpy h and composition X.
</html>",     revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end setState_psX;

        function s_pTX
          "Return specific entropy of moist air as a function of pressure p, temperature T and composition X (only valid for phi<1)"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input SI.MassFraction X[:] "Mass fractions of moist air";
          output SI.SpecificEntropy s "Specific entropy at p, T, X";
      protected
          MoleFraction[2] Y=massToMoleFractions(X, {steam.MM,dryair.MM})
            "Molar fraction";

        algorithm
          s:= Modelica.Media.IdealGases.Common.Functions.s0_Tlow(dryair, T)*(1 - X[Water])
          + Modelica.Media.IdealGases.Common.Functions.s0_Tlow(steam, T)*X[Water]
          - Modelica.Constants.R*(Utilities.smoothMax(X[Water]/MMX[Water],0.0,1e-9)*Modelica.Math.log(max(Y[Water], Modelica.Constants.eps)*p/reference_p)
          + Utilities.smoothMax((1 - X[Water])/MMX[Air],0.0,1e-9)*Modelica.Math.log(max(Y[Air], Modelica.Constants.eps)*p/reference_p));
          annotation (
            derivative=s_pTX_der,
            Inline=false,
            Documentation(info="<html>
Specific entropy of moist air is computed from pressure, temperature and composition with X[1] as the total water mass fraction.
</html>",     revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
<p>2019-05-14        Stefan Wischhusen: Corrected calculation.</p>
<p>2019-09-10        Stefan Wischhusen: Corrected pressure influence (p &lt; p_ref).</p>
</html>"),  Icon(graphics={Text(
                  extent={{-100,100},{100,-100}},
                  textColor={255,127,0},
                  textString="f")}));
        end s_pTX;

        function s_pTX_der
          "Return specific entropy of moist air as a function of pressure p, temperature T and composition X (only valid for phi<1)"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input SI.MassFraction X[:] "Mass fractions of moist air";
          input Real dp(unit="Pa/s") "Derivative of pressure";
          input Real dT(unit="K/s") "Derivative of temperature";
          input Real dX[nX](each unit="1/s") "Derivative of mass fractions";
          output Real ds(unit="J/(kg.K.s)") "Specific entropy at p, T, X";
      protected
          MoleFraction[2] Y=massToMoleFractions(X, {steam.MM,dryair.MM})
            "Molar fraction";
          MolarMass MM "Molar mass";

        algorithm
          MM := MMX[Water]*MMX[Air]/(X[Water]*MMX[Air] + X[Air]*MMX[Water]);

          ds := IdealGases.Common.Functions.s0_Tlow_der(
            dryair,
            T,
            dT)*(1 - X[Water]) + IdealGases.Common.Functions.s0_Tlow_der(
            steam,
            T,
            dT)*X[Water] + Modelica.Media.IdealGases.Common.Functions.s0_Tlow(dryair, T)*dX[Air] + Modelica.Media.IdealGases.Common.Functions.s0_Tlow(steam, T)*dX[Water] - Modelica.Constants.R*(1/MMX[Water]*(Utilities.smoothMax_der(
            X[Water],
            0.0,
            1e-9,
            dX[Water],
            0.0,
            0.0)*(Modelica.Math.log(max(Y[Water], Modelica.Constants.eps)*p/reference_p) + MM/MMX[Air]) + dp/p*Utilities.smoothMax(
            X[Water],
            0.0,
            1e-9)) + 1/MMX[Air]*(Utilities.smoothMax_der(
            X[Air],
            0.0,
            1e-9,
            dX[Air],
            0.0,
            0.0)*(Modelica.Math.log(max(Y[Air], Modelica.Constants.eps)*p/reference_p) + MM/MMX[Water]) + dp/p*Utilities.smoothMax(
            X[Air],
            0.0,
            1e-9)));

          annotation (
            Inline=false,
            smoothOrder=1,
            Documentation(info="<html>
Specific entropy of moist air is computed from pressure, temperature and composition with X[1] as the total water mass fraction.
</html>",     revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
<p>2019-05-14        Stefan Wischhusen: Corrected calculation.</p>
<p>2019-09-10        Stefan Wischhusen: Corrected pressure influence (p &lt; p_ref).</p>
</html>"),  Icon(graphics={Text(
                  extent={{-100,100},{100,-100}},
                  textColor={255,127,0},
                  textString="f")}));
        end s_pTX_der;

        redeclare function extends isentropicEnthalpy
          "Isentropic enthalpy (only valid for phi<1)"
          extends Modelica.Icons.Function;
        algorithm
          h_is := Modelica.Media.Air.MoistAir.h_pTX(
                p_downstream,
                Modelica.Media.Air.MoistAir.T_psX(
                  p_downstream,
                  Modelica.Media.Air.MoistAir.specificEntropy(refState),
                  refState.X),
                refState.X);

          annotation (Icon(graphics={Text(
                  extent={{-100,100},{100,-100}},
                  textColor={255,127,0},
                  textString="f")}), Documentation(revisions="<html>
<p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
</html>"));
        end isentropicEnthalpy;

        package Utilities "Utility functions"
          extends Modelica.Icons.UtilitiesPackage;

          function spliceFunction "Spline interpolation of two functions"
            extends Modelica.Icons.Function;
            input Real pos "Returned value for x-deltax >= 0";
            input Real neg "Returned value for x+deltax <= 0";
            input Real x "Function argument";
            input Real deltax=1 "Region around x with spline interpolation";
            output Real out;
        protected
            Real scaledX;
            Real scaledX1;
            Real y;
          algorithm
            scaledX1 := x/deltax;
            scaledX := scaledX1*Modelica.Math.asin(1);
            if scaledX1 <= -0.999999999 then
              y := 0;
            elseif scaledX1 >= 0.999999999 then
              y := 1;
            else
              y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX)) + 1)/2;
            end if;
            out := pos*y + (1 - y)*neg;
            annotation (derivative=spliceFunction_der);
          end spliceFunction;

          function spliceFunction_der "Derivative of spliceFunction"
            extends Modelica.Icons.Function;
            input Real pos;
            input Real neg;
            input Real x;
            input Real deltax=1;
            input Real dpos;
            input Real dneg;
            input Real dx;
            input Real ddeltax=0;
            output Real out;
        protected
            Real scaledX;
            Real scaledX1;
            Real dscaledX1;
            Real y;
          algorithm
            scaledX1 := x/deltax;
            scaledX := scaledX1*Modelica.Math.asin(1);
            dscaledX1 := (dx - scaledX1*ddeltax)/deltax;
            if scaledX1 <= -0.99999999999 then
              y := 0;
            elseif scaledX1 >= 0.9999999999 then
              y := 1;
            else
              y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX)) + 1)/2;
            end if;
            out := dpos*y + (1 - y)*dneg;
            if (abs(scaledX1) < 1) then
              out := out + (pos - neg)*dscaledX1*Modelica.Math.asin(1)/2/(
                Modelica.Math.cosh(Modelica.Math.tan(scaledX))*Modelica.Math.cos(
                scaledX))^2;
            end if;
          end spliceFunction_der;

          function smoothMax
            extends Modelica.Icons.Function;
            import Modelica.Math;

            input Real x1 "First argument of smooth max operator";
            input Real x2 "Second argument of smooth max operator";
            input Real dx
              "Approximate difference between x1 and x2, below which regularization starts";
            output Real y "Result of smooth max operator";
          algorithm
            y := max(x1, x2) + Math.log((exp((4/dx)*(x1 - max(x1, x2)))) + (exp((4/
              dx)*(x2 - max(x1, x2)))))/(4/dx);
            annotation (smoothOrder=2, Documentation(info="<html>
<p>An implementation of Kreisselmeier Steinhauser smooth maximum</p>
</html>"));
          end smoothMax;

          function smoothMax_der
            extends Modelica.Icons.Function;

            import Modelica.Math.exp;
            import Modelica.Math.log;

            input Real x1 "First argument of smooth max operator";
            input Real x2 "Second argument of smooth max operator";
            input Real dx
              "Approximate difference between x1 and x2, below which regularization starts";
            input Real dx1;
            input Real dx2;
            input Real ddx;
            output Real dy "Derivative of smooth max operator";
          algorithm
            dy := (if x1 > x2 then dx1 else dx2) + 0.25*(((4*(dx1 - (if x1 > x2
               then dx1 else dx2))/dx - 4*(x1 - max(x1, x2))*ddx/dx^2)*exp(4*(x1 -
              max(x1, x2))/dx) + (4*(dx2 - (if x1 > x2 then dx1 else dx2))/dx - 4*(
              x2 - max(x1, x2))*ddx/dx^2)*exp(4*(x2 - max(x1, x2))/dx))*dx/(exp(4*(
              x1 - max(x1, x2))/dx) + exp(4*(x2 - max(x1, x2))/dx)) + log(exp(4*(x1
               - max(x1, x2))/dx) + exp(4*(x2 - max(x1, x2))/dx))*ddx);

            annotation (Documentation(info="<html>
<p>An implementation of Kreisselmeier Steinhauser smooth maximum</p>
</html>"));
          end smoothMax_der;
        end Utilities;
        annotation (Documentation(info="<html>
<h4>Thermodynamic Model</h4>
<p>This package provides a full thermodynamic model of moist air including the fog region and temperatures below zero degC.
The governing assumptions in this model are:</p>
<ul>
<li>the perfect gas law applies</li>
<li>water volume other than that of steam is neglected</li></ul>
<p>All extensive properties are expressed in terms of the total mass in order to comply with other media in this library. However, for moist air it is rather common to express the absolute humidity in terms of mass of dry air only, which has advantages when working with charts. In addition, care must be taken, when working with mass fractions with respect to total mass, that all properties refer to the same water content when being used in mathematical operations (which is always the case if based on dry air only). Therefore two absolute humidities are computed in the <strong>BaseProperties</strong> model: <strong>X</strong> denotes the absolute humidity in terms of the total mass while <strong>x</strong> denotes the absolute humidity per unit mass of dry air. In addition, the relative humidity <strong>phi</strong> is also computed.</p>
<p>At the triple point temperature of water of 0.01 &deg;C or 273.16 K and a relative humidity greater than 1 fog may be present as liquid and as ice resulting in a specific enthalpy somewhere between those of the two isotherms for solid and liquid fog, respectively. For numerical reasons a coexisting mixture of 50% solid and 50% liquid fog is assumed in the fog region at the triple point in this model.</p>

<h4>Range of validity</h4>
<p>From the assumptions mentioned above it follows that the <strong>pressure</strong> should be in the region around <strong>atmospheric</strong> conditions or below (a few bars may still be fine though). Additionally a very high water content at low temperatures would yield incorrect densities, because the volume of the liquid or solid phase would not be negligible anymore. The model does not provide information on limits for water drop size in the fog region or transport information for the actual condensation or evaporation process in combination with surfaces. All excess water which is not in its vapour state is assumed to be still present in the air regarding its energy but not in terms of its spatial extent.<br><br>
The thermodynamic model may be used for <strong>temperatures</strong> ranging from <strong>190 ... 647 K</strong>. This holds for all functions unless otherwise stated in their description. However, although the model works at temperatures above the saturation temperature it is questionable to use the term \"relative humidity\" in this region. Please note, that although several functions compute pure water properties, they are designed to be used within the moist air medium model where properties are dominated by air and steam in their vapor states, and not for pure liquid water applications.</p>

<h4>Transport Properties</h4>
<p>Several additional functions that are not needed to describe the thermodynamic system, but are required to model transport processes, like heat and mass transfer, may be called. They usually neglect the moisture influence unless otherwise stated.</p>

<h4>Application</h4>
<p>The model's main area of application is all processes that involve moist air cooling under near atmospheric pressure with possible moisture condensation. This is the case in all domestic and industrial air conditioning applications. Another large domain of moist air applications covers all processes that deal with dehydration of bulk material using air as a transport medium. Engineering tasks involving moist air are often performed (or at least visualized) by using charts that contain all relevant thermodynamic data for a moist air system. These so called psychrometric charts can be generated from the medium properties in this package. The model <a href=\"modelica://Modelica.Media.Examples.PsychrometricData\">PsychrometricData</a> may be used for this purpose in order to obtain data for figures like those below (the plotting itself is not part of the model though).</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Media/Air/Mollier.png\"><br>
<img src=\"modelica://Modelica/Resources/Images/Media/Air/PsycroChart.png\">
</p>

<p>
<strong>Legend:</strong> blue - constant specific enthalpy, red - constant temperature, black - constant relative humidity</p>

</html>"));
      end MoistAir;
      annotation (Documentation(info="<html>
  <p>This package contains different medium models for air:</p>
<ul>
<li><strong>SimpleAir</strong><br>
    Simple dry air medium in a limited temperature range.</li>
<li><strong>DryAirNasa</strong><br>
    Dry air as an ideal gas from Media.IdealGases.MixtureGases.Air.</li>
<li><strong>MoistAir</strong><br>
    Moist air as an ideal gas mixture of steam and dry air with fog below and above the triple point temperature.</li>
</ul>
</html>"));
    end Air;

    package IdealGases
    "Data and models of ideal gases (single, fixed and dynamic mixtures) from NASA source"
      extends Modelica.Icons.VariantsPackage;

      package Common "Common packages and data for the ideal gas models"
        extends Modelica.Icons.Package;

      record DataRecord
        "Coefficient data record for properties of ideal gases based on NASA source"
        extends Modelica.Icons.Record;
        String name "Name of ideal gas";
        SI.MolarMass MM "Molar mass";
        SI.SpecificEnthalpy Hf "Enthalpy of formation at 298.15K";
        SI.SpecificEnthalpy H0 "H0(298.15K) - H0(0K)";
        SI.Temperature Tlimit "Temperature limit between low and high data sets";
        Real alow[7] "Low temperature coefficients a";
        Real blow[2] "Low temperature constants b";
        Real ahigh[7] "High temperature coefficients a";
        Real bhigh[2] "High temperature constants b";
        SI.SpecificHeatCapacity R_s "Gas constant";
        annotation (Documentation(info="<html>
<p>
This data record contains the coefficients for the
ideal gas equations according to:
</p>
<blockquote>
  <p>McBride B.J., Zehe M.J., and Gordon S. (2002): <strong>NASA Glenn Coefficients
  for Calculating Thermodynamic Properties of Individual Species</strong>. NASA
  report TP-2002-211556</p>
</blockquote>
<p>
The equations have the following structure:
</p>
<div><img src=\"modelica://Modelica/Resources/Images/Media/IdealGases/Common/singleEquations.png\"></div>
<p>
The polynomials for h(T) and s0(T) are derived via integration from the one for cp(T)  and contain the integration constants b1, b2 that define the reference specific enthalpy and entropy. For entropy differences the reference pressure p0 is arbitrary, but not for absolute entropies. It is chosen as 1 standard atmosphere (101325 Pa).
</p>
<p>
For most gases, the region of validity is from 200 K to 6000 K.
The equations are split into two regions that are separated
by Tlimit (usually 1000 K). In both regions the gas is described
by the data above. The two branches are continuous and in most
gases also differentiable at Tlimit.
</p>
</html>"));
      end DataRecord;

        package Functions
        "Basic Functions for ideal gases: cp, h, s, thermal conductivity, viscosity"
          extends Modelica.Icons.FunctionsPackage;

          constant Boolean excludeEnthalpyOfFormation=true
            "If true, enthalpy of formation Hf is not included in specific enthalpy h";

          constant Modelica.Media.Interfaces.Choices.ReferenceEnthalpy referenceChoice=Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K
            "Choice of reference enthalpy";

          constant Modelica.Media.Interfaces.Types.SpecificEnthalpy h_offset=0.0
            "User defined offset for reference enthalpy, if referenceChoice = UserDefined";

          constant Integer methodForThermalConductivity(min=1,max=2)=1;

          function cp_T
            "Compute specific heat capacity at constant pressure from temperature and gas data"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input SI.Temperature T "Temperature";
            output SI.SpecificHeatCapacity cp "Specific heat capacity at temperature T";
          algorithm
            cp := smooth(0,if T < data.Tlimit then data.R_s*(1/(T*T)*(data.alow[1] + T*(
              data.alow[2] + T*(1.*data.alow[3] + T*(data.alow[4] + T*(data.alow[5] + T
              *(data.alow[6] + data.alow[7]*T))))))) else data.R_s*(1/(T*T)*(data.ahigh[1]
               + T*(data.ahigh[2] + T*(1.*data.ahigh[3] + T*(data.ahigh[4] + T*(data.
              ahigh[5] + T*(data.ahigh[6] + data.ahigh[7]*T))))))));
            annotation (Inline=true,smoothOrder=2);
          end cp_T;

          function cp_Tlow
            "Compute specific heat capacity at constant pressure, low T region"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input SI.Temperature T "Temperature";
            output SI.SpecificHeatCapacity cp "Specific heat capacity at temperature T";
          algorithm
            cp := data.R_s*(1/(T*T)*(data.alow[1] + T*(
              data.alow[2] + T*(1.*data.alow[3] + T*(data.alow[4] + T*(data.alow[5] + T
              *(data.alow[6] + data.alow[7]*T)))))));
            annotation (Inline=false, derivative(zeroDerivative=data) = cp_Tlow_der);
          end cp_Tlow;

          function cp_Tlow_der
            "Compute derivative of specific heat capacity at constant pressure, low T region"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input SI.Temperature T "Temperature";
            input Real dT(unit="K/s") "Temperature derivative";
            output Real cp_der(unit="J/(kg.K.s)") "Derivative of specific heat capacity";
          algorithm
            cp_der := dT*data.R_s/(T*T*T)*(-2*data.alow[1] + T*(
              -data.alow[2] + T*T*(data.alow[4] + T*(2.*data.alow[5] + T
              *(3.*data.alow[6] + 4.*data.alow[7]*T)))));
            annotation(smoothOrder=2);
          end cp_Tlow_der;

          function h_T "Compute specific enthalpy from temperature and gas data; reference is decided by the
    refChoice input, or by the referenceChoice package constant by default"
            import Modelica.Media.Interfaces.Choices;
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input SI.Temperature T "Temperature";
            input Boolean exclEnthForm=excludeEnthalpyOfFormation
              "If true, enthalpy of formation Hf is not included in specific enthalpy h";
            input Modelica.Media.Interfaces.Choices.ReferenceEnthalpy
                                            refChoice=referenceChoice
              "Choice of reference enthalpy";
            input SI.SpecificEnthalpy h_off=h_offset
              "User defined offset for reference enthalpy, if referenceChoice = UserDefined";
            output SI.SpecificEnthalpy h "Specific enthalpy at temperature T";

          algorithm
            h := smooth(0,(if T < data.Tlimit then data.R_s*((-data.alow[1] + T*(data.
              blow[1] + data.alow[2]*Math.log(T) + T*(1.*data.alow[3] + T*(0.5*data.
              alow[4] + T*(1/3*data.alow[5] + T*(0.25*data.alow[6] + 0.2*data.alow[7]*T))))))
              /T) else data.R_s*((-data.ahigh[1] + T*(data.bhigh[1] + data.ahigh[2]*
              Math.log(T) + T*(1.*data.ahigh[3] + T*(0.5*data.ahigh[4] + T*(1/3*data.
              ahigh[5] + T*(0.25*data.ahigh[6] + 0.2*data.ahigh[7]*T))))))/T)) + (if
              exclEnthForm then -data.Hf else 0.0) + (if (refChoice
               == Choices.ReferenceEnthalpy.ZeroAt0K) then data.H0 else 0.0) + (if
              refChoice == Choices.ReferenceEnthalpy.UserDefined then h_off else
                    0.0));
            annotation (Inline=false,smoothOrder=2);
          end h_T;

          function h_Tlow "Compute specific enthalpy, low T region; reference is decided by the
    refChoice input, or by the referenceChoice package constant by default"
            import Modelica.Media.Interfaces.Choices;
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input SI.Temperature T "Temperature";
            input Boolean exclEnthForm=excludeEnthalpyOfFormation
              "If true, enthalpy of formation Hf is not included in specific enthalpy h";
            input Modelica.Media.Interfaces.Choices.ReferenceEnthalpy
                                            refChoice=referenceChoice
              "Choice of reference enthalpy";
            input SI.SpecificEnthalpy h_off=h_offset
              "User defined offset for reference enthalpy, if referenceChoice = UserDefined";
            output SI.SpecificEnthalpy h "Specific enthalpy at temperature T";

          algorithm
            h := data.R_s*((-data.alow[1] + T*(data.
              blow[1] + data.alow[2]*Math.log(T) + T*(1.*data.alow[3] + T*(0.5*data.
              alow[4] + T*(1/3*data.alow[5] + T*(0.25*data.alow[6] + 0.2*data.alow[7]*T))))))
              /T) + (if
              exclEnthForm then -data.Hf else 0.0) + (if (refChoice
               == Choices.ReferenceEnthalpy.ZeroAt0K) then data.H0 else 0.0) + (if
              refChoice == Choices.ReferenceEnthalpy.UserDefined then h_off else
                    0.0);
            annotation(Inline=false,smoothOrder=2);
          end h_Tlow;

          function h_Tlow_der "Compute derivative of specific enthalpy, low T region; reference is decided by the
    refChoice input, or by the referenceChoice package constant by default"
            import Modelica.Media.Interfaces.Choices;
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input SI.Temperature T "Temperature";
            input Boolean exclEnthForm=excludeEnthalpyOfFormation
              "If true, enthalpy of formation Hf is not included in specific enthalpy h";
            input Modelica.Media.Interfaces.Choices.ReferenceEnthalpy
                                            refChoice=referenceChoice
              "Choice of reference enthalpy";
            input SI.SpecificEnthalpy h_off=h_offset
              "User defined offset for reference enthalpy, if referenceChoice = UserDefined";
            input Real dT(unit="K/s") "Temperature derivative";
            output Real h_der(unit="J/(kg.s)")
              "Derivative of specific enthalpy at temperature T";
          algorithm
            h_der := dT*Modelica.Media.IdealGases.Common.Functions.cp_Tlow(
                                data,T);
            annotation(Inline=true,smoothOrder=2);
          end h_Tlow_der;

          function s0_T "Compute specific entropy from temperature and gas data"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input SI.Temperature T "Temperature";
            output SI.SpecificEntropy s "Specific entropy at temperature T";
          algorithm
            s := if T < data.Tlimit then data.R_s*(data.blow[2] - 0.5*data.alow[
              1]/(T*T) - data.alow[2]/T + data.alow[3]*Math.log(T) + T*(
              data.alow[4] + T*(0.5*data.alow[5] + T*(1/3*data.alow[6] + 0.25*data.alow[
              7]*T)))) else data.R_s*(data.bhigh[2] - 0.5*data.ahigh[1]/(T*T) - data.
              ahigh[2]/T + data.ahigh[3]*Math.log(T) + T*(data.ahigh[4]
               + T*(0.5*data.ahigh[5] + T*(1/3*data.ahigh[6] + 0.25*data.ahigh[7]*T))));
            annotation (Inline=true, smoothOrder=2);
          end s0_T;

          function s0_Tlow "Compute specific entropy, low T region"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input SI.Temperature T "Temperature";
            output SI.SpecificEntropy s "Specific entropy at temperature T";
          algorithm
            s := data.R_s*(data.blow[2] - 0.5*data.alow[
              1]/(T*T) - data.alow[2]/T + data.alow[3]*Math.log(T) + T*(
              data.alow[4] + T*(0.5*data.alow[5] + T*(1/3*data.alow[6] + 0.25*data.alow[
              7]*T))));
            annotation (Inline=true, smoothOrder=2);
          end s0_Tlow;

          function s0_Tlow_der "Compute derivative of specific entropy, low T region"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input SI.Temperature T "Temperature";
            input Real T_der(unit="K/s") "Temperature derivative";
            output Real s_der(unit="J/(kg.K.s)") "Derivative of specific entropy at temperature T";
          algorithm
            s_der := data.R_s*T_der*(data.alow[1]/(T*T*T) + data.alow[2]/(T*T) + data.alow[3]/T + data.alow[4] + T*(data.alow[5] + T*(data.alow[6] + T*data.alow[7])));
            annotation (Inline=true);
          end s0_Tlow_der;

          function dynamicViscosityLowPressure
            "Dynamic viscosity of low pressure gases"
            extends Modelica.Icons.Function;
            input SI.Temperature T "Gas temperature";
            input SI.Temperature Tc "Critical temperature of gas";
            input SI.MolarMass M "Molar mass of gas";
            input SI.MolarVolume Vc "Critical molar volume of gas";
            input Real w "Acentric factor of gas";
            input Modelica.Media.Interfaces.Types.DipoleMoment mu
              "Dipole moment of gas molecule";
            input Real k =  0.0 "Special correction for highly polar substances";
            output SI.DynamicViscosity eta "Dynamic viscosity of gas";
        protected
            parameter Real Const1_SI=40.785*10^(-9.5)
              "Constant in formula for eta converted to SI units";
            parameter Real Const2_SI=131.3/1000.0
              "Constant in formula for mur converted to SI units";
            Real mur=Const2_SI*mu/sqrt(Vc*Tc)
              "Dimensionless dipole moment of gas molecule";
            Real Fc=1 - 0.2756*w + 0.059035*mur^4 + k
              "Factor to account for molecular shape and polarities of gas";
            Real Tstar "Dimensionless temperature defined by equation below";
            Real Ov "Viscosity collision integral for the gas";

          algorithm
            Tstar := 1.2593*T/Tc;
            Ov := 1.16145*Tstar^(-0.14874) + 0.52487*Modelica.Math.exp(-0.7732*Tstar) + 2.16178*Modelica.Math.exp(-2.43787
              *Tstar);
            eta := Const1_SI*Fc*sqrt(M*T)/(Vc^(2/3)*Ov);
            annotation (smoothOrder=2,
                        Documentation(info="<html>
<p>
The used formula are based on the method of Chung et al (1984, 1988) referred to in ref [1] chapter 9.
The formula 9-4.10 is the one being used. The Formula is given in non-SI units, the following conversion constants were used to
transform the formula to SI units:
</p>

<ul>
<li> <strong>Const1_SI:</strong> The factor 10^(-9.5) =10^(-2.5)*1e-7 where the
     factor 10^(-2.5) originates from the conversion of g/mol->kg/mol + cm^3/mol->m^3/mol
      and the factor 1e-7 is due to conversion from microPoise->Pa.s.</li>
<li>  <strong>Const2_SI:</strong> The factor 1/3.335641e-27 = 1e-3/3.335641e-30
      where the factor 3.335641e-30 comes from debye->C.m and
      1e-3 is due to conversion from cm^3/mol->m^3/mol</li>
</ul>

<h4>References</h4>
<p>
[1] Bruce E. Poling, John E. Prausnitz, John P. O'Connell, \"The Properties of Gases and Liquids\" 5th Ed. Mc Graw Hill.
</p>

<h4>Author</h4>
<p>T. Skoglund, Lund, Sweden, 2004-08-31</p>

</html>"));
          end dynamicViscosityLowPressure;

          function thermalConductivityEstimate
            "Thermal conductivity of polyatomic gases (Eucken and Modified Eucken correlation)"
            extends Modelica.Icons.Function;
            input Modelica.Media.Interfaces.Types.SpecificHeatCapacity Cp
              "Constant pressure heat capacity";
            input Modelica.Media.Interfaces.Types.DynamicViscosity eta
              "Dynamic viscosity";
            input Integer method(min=1,max=2)=1
              "1: Eucken Method, 2: Modified Eucken Method";
            input IdealGases.Common.DataRecord data "Ideal gas data";
            output Modelica.Media.Interfaces.Types.ThermalConductivity lambda
              "Thermal conductivity [W/(m.k)]";
          algorithm
            lambda := if method == 1 then eta*(Cp - data.R_s + (9/4)*data.R_s)
                                     else eta*(Cp - data.R_s)*(1.32 + 1.77/((Cp/data.R_s) - 1.0));
            annotation (smoothOrder=2,
                        Documentation(info="<html>
<p>
This function provides two similar methods for estimating the
thermal conductivity of polyatomic gases.
The Eucken method (input method == 1) gives good results for low temperatures,
but it tends to give an underestimated value of the thermal conductivity
(lambda) at higher temperatures.<br>
The Modified Eucken method (input method == 2) gives good results for
high-temperatures, but it tends to give an overestimated value of the
thermal conductivity (lambda) at low temperatures.
</p>
</html>"));
          end thermalConductivityEstimate;
        end Functions;

      partial package SingleGasNasa
        "Medium model of an ideal gas based on NASA source"
        extends Interfaces.PartialPureSubstance(
           ThermoStates=Modelica.Media.Interfaces.Choices.IndependentVariables.pT,
           redeclare final record FluidConstants =
              Modelica.Media.Interfaces.Types.IdealGas.FluidConstants,
           mediumName=data.name,
           substanceNames={data.name},
           singleState=false,
           Temperature(min=200, max=6000, start=500, nominal=500),
           SpecificEnthalpy(start=if Functions.referenceChoice==ReferenceEnthalpy.ZeroAt0K then data.H0 else
              if Functions.referenceChoice==ReferenceEnthalpy.UserDefined then Functions.h_offset else 0, nominal=1.0e5),
           Density(start=10, nominal=10),
           AbsolutePressure(start=10e5, nominal=10e5));

        redeclare record extends ThermodynamicState
          "Thermodynamic state variables for ideal gases"
          AbsolutePressure p "Absolute pressure of medium";
          Temperature T "Temperature of medium";
        end ThermodynamicState;
        import Modelica.Math;
        import Modelica.Media.Interfaces.Choices.ReferenceEnthalpy;

        constant IdealGases.Common.DataRecord data
          "Data record of ideal gas substance";

        constant FluidConstants[nS] fluidConstants "Constant data for the fluid";

        redeclare model extends BaseProperties(
         T(stateSelect=if preferredMediumStates then StateSelect.prefer else StateSelect.default),
         p(stateSelect=if preferredMediumStates then StateSelect.prefer else StateSelect.default))
          "Base properties of ideal gas medium"
        equation
          assert(T >= 200 and T <= 6000, "
Temperature T (= "       + String(T) + " K) is not in the allowed range
200 K <= T <= 6000 K required from medium model \""       + mediumName + "\".
");       MM = data.MM;
          R_s = data.R_s;
          h = Modelica.Media.IdealGases.Common.Functions.h_T(
                  data, T,
                  Modelica.Media.IdealGases.Common.Functions.excludeEnthalpyOfFormation,
                  Modelica.Media.IdealGases.Common.Functions.referenceChoice,
                  Modelica.Media.IdealGases.Common.Functions.h_offset);
          u = h - R_s*T;

          // Has to be written in the form d=f(p,T) in order that static
          // state selection for p and T is possible
          d = p/(R_s*T);
          // connect state with BaseProperties
          state.T = T;
          state.p = p;
        end BaseProperties;

          redeclare function setState_pTX
          "Return thermodynamic state as function of p, T and composition X"
            extends Modelica.Icons.Function;
            input AbsolutePressure p "Pressure";
            input Temperature T "Temperature";
            input MassFraction X[:]=reference_X "Mass fractions";
            output ThermodynamicState state;
          algorithm
            state := ThermodynamicState(p=p,T=T);
            annotation(Inline=true,smoothOrder=2);
          end setState_pTX;

          redeclare function setState_phX
          "Return thermodynamic state as function of p, h and composition X"
            extends Modelica.Icons.Function;
            input AbsolutePressure p "Pressure";
            input SpecificEnthalpy h "Specific enthalpy";
            input MassFraction X[:]=reference_X "Mass fractions";
            output ThermodynamicState state;
          algorithm
            state := ThermodynamicState(p=p,T=T_h(h));
            annotation(Inline=true,smoothOrder=2);
          end setState_phX;

          redeclare function setState_psX
          "Return thermodynamic state as function of p, s and composition X"
            extends Modelica.Icons.Function;
            input AbsolutePressure p "Pressure";
            input SpecificEntropy s "Specific entropy";
            input MassFraction X[:]=reference_X "Mass fractions";
            output ThermodynamicState state;
          algorithm
            state := ThermodynamicState(p=p,T=T_ps(p,s));
            annotation(Inline=true,smoothOrder=2);
          end setState_psX;

          redeclare function setState_dTX
          "Return thermodynamic state as function of d, T and composition X"
            extends Modelica.Icons.Function;
            input Density d "Density";
            input Temperature T "Temperature";
            input MassFraction X[:]=reference_X "Mass fractions";
            output ThermodynamicState state;
          algorithm
            state := ThermodynamicState(p=d*data.R_s*T,T=T);
            annotation(Inline=true,smoothOrder=2);
          end setState_dTX;

            redeclare function extends setSmoothState
        "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
            algorithm
              state := ThermodynamicState(p=Media.Common.smoothStep(x, state_a.p, state_b.p, x_small),
                                          T=Media.Common.smoothStep(x, state_a.T, state_b.T, x_small));
              annotation(Inline=true,smoothOrder=2);
            end setSmoothState;

        redeclare function extends pressure "Return pressure of ideal gas"
        algorithm
          p := state.p;
          annotation(Inline=true,smoothOrder=2);
        end pressure;

        redeclare function extends temperature "Return temperature of ideal gas"
        algorithm
          T := state.T;
          annotation(Inline=true,smoothOrder=2);
        end temperature;

        redeclare function extends density "Return density of ideal gas"
        algorithm
          d := state.p/(data.R_s*state.T);
          annotation(Inline=true,smoothOrder=2);
        end density;

        redeclare function extends specificEnthalpy "Return specific enthalpy"
          extends Modelica.Icons.Function;
        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_T(
                   data,state.T);
          annotation(Inline=true,smoothOrder=2);
        end specificEnthalpy;

        redeclare function extends specificInternalEnergy
          "Return specific internal energy"
          extends Modelica.Icons.Function;
        algorithm
          u := Modelica.Media.IdealGases.Common.Functions.h_T(
                   data,state.T) - data.R_s*state.T;
          annotation(Inline=true,smoothOrder=2);
        end specificInternalEnergy;

        redeclare function extends specificEntropy "Return specific entropy"
          extends Modelica.Icons.Function;
        algorithm
          s := Modelica.Media.IdealGases.Common.Functions.s0_T(
                    data, state.T) - data.R_s*Modelica.Math.log(state.p/reference_p);
          annotation(Inline=true,smoothOrder=2);
        end specificEntropy;

        redeclare function extends specificGibbsEnergy "Return specific Gibbs energy"
          extends Modelica.Icons.Function;
        algorithm
          g := Modelica.Media.IdealGases.Common.Functions.h_T(
                   data,state.T) - state.T*specificEntropy(state);
          annotation(Inline=true,smoothOrder=2);
        end specificGibbsEnergy;

        redeclare function extends specificHelmholtzEnergy
          "Return specific Helmholtz energy"
          extends Modelica.Icons.Function;
        algorithm
          f := Modelica.Media.IdealGases.Common.Functions.h_T(
                   data,state.T) - data.R_s*state.T - state.T*specificEntropy(state);
          annotation(Inline=true,smoothOrder=2);
        end specificHelmholtzEnergy;

        redeclare function extends specificHeatCapacityCp
          "Return specific heat capacity at constant pressure"
        algorithm
          cp := Modelica.Media.IdealGases.Common.Functions.cp_T(
                     data, state.T);
          annotation(Inline=true,smoothOrder=2);
        end specificHeatCapacityCp;

        redeclare function extends specificHeatCapacityCv
          "Compute specific heat capacity at constant volume from temperature and gas data"
        algorithm
          cv := Modelica.Media.IdealGases.Common.Functions.cp_T(
                     data, state.T) - data.R_s;
          annotation(Inline=true,smoothOrder=2);
        end specificHeatCapacityCv;

        redeclare function extends isentropicExponent "Return isentropic exponent"
        algorithm
          gamma := specificHeatCapacityCp(state)/specificHeatCapacityCv(state);
          annotation(Inline=true,smoothOrder=2);
        end isentropicExponent;

        redeclare function extends velocityOfSound "Return velocity of sound"
          extends Modelica.Icons.Function;
        algorithm
          a := sqrt(max(0,data.R_s*state.T*Modelica.Media.IdealGases.Common.Functions.cp_T(
                                              data, state.T)/specificHeatCapacityCv(state)));
          annotation(Inline=true,smoothOrder=2);
        end velocityOfSound;

        function isentropicEnthalpyApproximation
          "Approximate method of calculating h_is from upstream properties and downstream pressure"
          extends Modelica.Icons.Function;
          input SI.Pressure p2 "Downstream pressure";
          input ThermodynamicState state "Properties at upstream location";
          input Boolean exclEnthForm=Functions.excludeEnthalpyOfFormation
            "If true, enthalpy of formation Hf is not included in specific enthalpy h";
          input ReferenceEnthalpy refChoice=Functions.referenceChoice
            "Choice of reference enthalpy";
          input SpecificEnthalpy h_off=Functions.h_offset
            "User defined offset for reference enthalpy, if referenceChoice = UserDefined";
          output SI.SpecificEnthalpy h_is "Isentropic enthalpy";
      protected
          IsentropicExponent gamma =  isentropicExponent(state) "Isentropic exponent";
        algorithm
          h_is := Modelica.Media.IdealGases.Common.Functions.h_T(
                      data,state.T,exclEnthForm,refChoice,h_off) +
            gamma/(gamma - 1.0)*state.p/density(state)*((p2/state.p)^((gamma - 1)/gamma) - 1.0);
          annotation(Inline=true,smoothOrder=2);
        end isentropicEnthalpyApproximation;

        redeclare function extends isentropicEnthalpy "Return isentropic enthalpy"
        input Boolean exclEnthForm=Functions.excludeEnthalpyOfFormation
            "If true, enthalpy of formation Hf is not included in specific enthalpy h";
        input ReferenceEnthalpy refChoice=Functions.referenceChoice
            "Choice of reference enthalpy";
        input SpecificEnthalpy h_off=Functions.h_offset
            "User defined offset for reference enthalpy, if referenceChoice = UserDefined";
        algorithm
          h_is := isentropicEnthalpyApproximation(p_downstream,refState,exclEnthForm,refChoice,h_off);
          annotation(Inline=true,smoothOrder=2);
        end isentropicEnthalpy;

        redeclare function extends isobaricExpansionCoefficient
          "Returns overall the isobaric expansion coefficient beta"
        algorithm
          beta := 1/state.T;
          annotation(Inline=true,smoothOrder=2);
        end isobaricExpansionCoefficient;

        redeclare function extends isothermalCompressibility
          "Returns overall the isothermal compressibility factor"
        algorithm
          kappa := 1.0/state.p;
          annotation(Inline=true,smoothOrder=2);
        end isothermalCompressibility;

        redeclare function extends density_derp_T
          "Returns the partial derivative of density with respect to pressure at constant temperature"
        algorithm
          ddpT := 1/(state.T*data.R_s);
          annotation(Inline=true,smoothOrder=2);
        end density_derp_T;

        redeclare function extends density_derT_p
          "Returns the partial derivative of density with respect to temperature at constant pressure"
        algorithm
          ddTp := -state.p/(state.T*state.T*data.R_s);
          annotation(Inline=true,smoothOrder=2);
        end density_derT_p;

        redeclare function extends density_derX
          "Returns the partial derivative of density with respect to mass fractions at constant pressure and temperature"
        algorithm
          dddX := fill(0,nX);
          annotation(Inline=true,smoothOrder=2);
        end density_derX;

        redeclare replaceable function extends dynamicViscosity "Dynamic viscosity"
        algorithm
          assert(fluidConstants[1].hasCriticalData,
          "Failed to compute dynamicViscosity: For the species \"" + mediumName + "\" no critical data is available.");
          assert(fluidConstants[1].hasDipoleMoment,
          "Failed to compute dynamicViscosity: For the species \"" + mediumName + "\" no critical data is available.");
          eta := Modelica.Media.IdealGases.Common.Functions.dynamicViscosityLowPressure(
                                             state.T,
                             fluidConstants[1].criticalTemperature,
                             fluidConstants[1].molarMass,
                             fluidConstants[1].criticalMolarVolume,
                             fluidConstants[1].acentricFactor,
                             fluidConstants[1].dipoleMoment);
          annotation (smoothOrder=2);
        end dynamicViscosity;

        redeclare replaceable function extends thermalConductivity
          "Thermal conductivity of gas"
        //  input IdealGases.Common.DataRecord data "Ideal gas data";
          input Integer method=Functions.methodForThermalConductivity
            "1: Eucken Method, 2: Modified Eucken Method";
        algorithm
          assert(fluidConstants[1].hasCriticalData,
          "Failed to compute thermalConductivity: For the species \"" + mediumName + "\" no critical data is available.");
          lambda := Modelica.Media.IdealGases.Common.Functions.thermalConductivityEstimate(
                                                specificHeatCapacityCp(state),
            dynamicViscosity(state), method=method,data=data);
          annotation (smoothOrder=2);
        end thermalConductivity;

        redeclare function extends molarMass "Return the molar mass of the medium"
        algorithm
          MM := data.MM;
          annotation(Inline=true,smoothOrder=2);
        end molarMass;

        function T_h "Compute temperature from specific enthalpy"
          extends Modelica.Icons.Function;
          input SpecificEnthalpy h "Specific enthalpy";
          output Temperature T "Temperature";

      protected
          function f_nonlinear "Solve h(data,T) for T with given h (use only indirectly via temperature_phX)"
            extends Modelica.Math.Nonlinear.Interfaces.partialScalarFunction;
            input DataRecord data "Ideal gas data";
            input SpecificEnthalpy h "Specific enthalpy";
          algorithm
            y := Functions.h_T(data=data, T=u) - h;
          end f_nonlinear;

        algorithm
          T := Modelica.Math.Nonlinear.solveOneNonlinearEquation(
            function f_nonlinear(data=data, h=h), 200, 6000);
        end T_h;

        function T_ps "Compute temperature from pressure and specific entropy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          output Temperature T "Temperature";

      protected
          function f_nonlinear "Solve s(data,T) for T with given s (use only indirectly via temperature_psX)"
            extends Modelica.Math.Nonlinear.Interfaces.partialScalarFunction;
            input DataRecord data "Ideal gas data";
            input AbsolutePressure p "Pressure";
            input SpecificEntropy s "Specific entropy";
          algorithm
            y := Functions.s0_T(data=data, T=u) - data.R_s*Modelica.Math.log(p/reference_p) - s;
          end f_nonlinear;

        algorithm
          T := Modelica.Math.Nonlinear.solveOneNonlinearEquation(
            function f_nonlinear(data=data, p=p, s=s), 200, 6000);
        end T_ps;
        annotation (
          Documentation(info="<html>
<p>
This model calculates medium properties
for an ideal gas of a single substance, or for an ideal
gas consisting of several substances where the
mass fractions are fixed. Independent variables
are temperature <strong>T</strong> and pressure <strong>p</strong>.
Only density is a function of T and p. All other quantities
are solely a function of T. The properties
are valid in the range:
</p>
<blockquote><pre>
200 K &le; T &le; 6000 K
</pre></blockquote>
<p>
The following quantities are always computed:
</p>
<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
  <tr><td><strong>Variable</strong></td>
      <td><strong>Unit</strong></td>
      <td><strong>Description</strong></td></tr>
  <tr><td>h</td>
      <td>J/kg</td>
      <td>specific enthalpy h = h(T)</td></tr>
  <tr><td>u</td>
      <td>J/kg</td>
      <td>specific internal energy u = u(T)</td></tr>
  <tr><td>d</td>
      <td>kg/m^3</td>
      <td>density d = d(p,T)</td></tr>
</table>
<p>
For the other variables, see the functions in
Modelica.Media.IdealGases.Common.SingleGasNasa.
Note, dynamic viscosity and thermal conductivity are only provided
for gases that use a data record from Modelica.Media.IdealGases.FluidData.
Currently these are the following gases:
</p>
<blockquote><pre>
Ar
C2H2_vinylidene
C2H4
C2H5OH
C2H6
C3H6_propylene
C3H7OH
C3H8
C4H8_1_butene
C4H9OH
C4H10_n_butane
C5H10_1_pentene
C5H12_n_pentane
C6H6
C6H12_1_hexene
C6H14_n_heptane
C7H14_1_heptene
C8H10_ethylbenz
CH3OH
CH4
CL2
CO
CO2
F2
H2
H2O
He
N2
N2O
NH3
NO
O2
SO2
SO3
</pre></blockquote>
<p>
<strong>Sources for model and literature:</strong><br>
Original Data: Computer program for calculation of complex chemical
equilibrium compositions and applications. Part 1: Analysis
Document ID: 19950013764 N (95N20180) File Series: NASA Technical Reports
Report Number: NASA-RP-1311  E-8017  NAS 1.61:1311
Authors: Gordon, Sanford (NASA Lewis Research Center)
 Mcbride, Bonnie J. (NASA Lewis Research Center)
Published: Oct 01, 1994.
</p>
<p><strong>Known limits of validity:</strong><br>
The data is valid for
temperatures between 200K and 6000K.  A few of the data sets for
monatomic gases have a discontinuous 1st derivative at 1000K, but
this never caused problems so far.
</p>
<p>
This model has been copied from the ThermoFluid library
and adapted to the Modelica.Media package.
</p>
</html>"));
      end SingleGasNasa;

        package FluidData "Critical data, dipole moments and related data"
          extends Modelica.Icons.Package;
          import Modelica.Media.Interfaces.PartialMixtureMedium;
          import Modelica.Media.IdealGases.Common.SingleGasesData;

          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants N2(
                               chemicalFormula =        "N2",
                               iupacName =              "unknown",
                               structureFormula =       "unknown",
                               casRegistryNumber =      "7727-37-9",
                               meltingPoint =            63.15,
                               normalBoilingPoint =      77.35,
                               criticalTemperature =    126.20,
                               criticalPressure =        33.98e5,
                               criticalMolarVolume =     90.10e-6,
                               acentricFactor =           0.037,
                               dipoleMoment =             0.0,
                               molarMass =              SingleGasesData.N2.MM,
                               hasDipoleMoment =       true,
                               hasIdealGasHeatCapacity=true,
                               hasCriticalData =       true,
                               hasAcentricFactor =     true);

          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants H2O(
                               chemicalFormula =        "H2O",
                               iupacName =              "oxidane",
                               structureFormula =       "H2O",
                               casRegistryNumber =      "7732-18-5",
                               meltingPoint =           273.15,
                               normalBoilingPoint =     373.124,
                               criticalTemperature =    647.096,
                               criticalPressure =       220.64e5,
                               criticalMolarVolume =     55.95e-6,
                               acentricFactor =           0.344,
                               dipoleMoment =             1.8,
                               molarMass =              SingleGasesData.H2O.MM,
                               hasDipoleMoment =       true,
                               hasIdealGasHeatCapacity=true,
                               hasCriticalData =       true,
                               hasAcentricFactor =     true);
          annotation (Documentation(info="<html>
<p>
This package contains FluidConstants data records for the following 37 gases
(see also the description in
<a href=\"modelica://Modelica.Media.IdealGases\">Modelica.Media.IdealGases</a>):
</p>
<blockquote><pre>
Argon             Methane          Methanol       Carbon Monoxide  Carbon Dioxide
Acetylene         Ethylene         Ethanol        Ethane           Propylene
Propane           1-Propanol       1-Butene       N-Butane         1-Pentene
N-Pentane         Benzene          1-Hexene       N-Hexane         1-Heptane
N-Heptane         Ethylbenzene     N-Octane       Chlorine         Fluorine
Hydrogen          Steam            Helium         Ammonia          Nitric Oxide
Nitrogen Dioxide  Nitrogen         Nitrous        Oxide            Neon Oxygen
Sulfur Dioxide    Sulfur Trioxide
</pre></blockquote>

</html>"));
        end FluidData;

        package SingleGasesData
        "Ideal gas data based on the NASA Glenn coefficients"
          extends Modelica.Icons.Package;

          constant IdealGases.Common.DataRecord Air(
            name="Air",
            MM=0.0289651159,
            Hf=-4333.833858403446,
            H0=298609.6803431054,
            Tlimit=1000,
            alow={10099.5016,-196.827561,5.00915511,-0.00576101373,1.06685993e-005,-7.94029797e-009,
                2.18523191e-012},
            blow={-176.796731,-3.921504225},
            ahigh={241521.443,-1257.8746,5.14455867,-0.000213854179,7.06522784e-008,-1.07148349e-011,
                6.57780015e-016},
            bhigh={6462.26319,-8.147411905},
            R_s=287.0512249529787);

          constant IdealGases.Common.DataRecord H2O(
            name="H2O",
            MM=0.01801528,
            Hf=-13423382.81725291,
            H0=549760.6476280135,
            Tlimit=1000,
            alow={-39479.6083,575.573102,0.931782653,0.00722271286,-7.34255737e-006,
                4.95504349e-009,-1.336933246e-012},
            blow={-33039.7431,17.24205775},
            ahigh={1034972.096,-2412.698562,4.64611078,0.002291998307,-6.836830479999999e-007,
                9.426468930000001e-011,-4.82238053e-015},
            bhigh={-13842.86509,-7.97814851},
            R_s=461.5233290850878);

          constant IdealGases.Common.DataRecord N2(
            name="N2",
            MM=0.0280134,
            Hf=0,
            H0=309498.4543111511,
            Tlimit=1000,
            alow={22103.71497,-381.846182,6.08273836,-0.00853091441,1.384646189e-005,-9.62579362e-009,
                2.519705809e-012},
            blow={710.846086,-10.76003744},
            ahigh={587712.406,-2239.249073,6.06694922,-0.00061396855,1.491806679e-007,-1.923105485e-011,
                1.061954386e-015},
            bhigh={12832.10415,-15.86640027},
            R_s=296.8033869505308);
          annotation (Documentation(info="<html>
<p>This package contains ideal gas models for the 1241 ideal gases from</p>
<blockquote>
  <p>McBride B.J., Zehe M.J., and Gordon S. (2002): <strong>NASA Glenn Coefficients
  for Calculating Thermodynamic Properties of Individual Species</strong>. NASA
  report TP-2002-211556</p>
</blockquote>

<blockquote><pre>
Ag        BaOH+           C2H4O_ethylen_o DF      In2I4    Nb      ScO2
Ag+       Ba_OH_2         CH3CHO_ethanal  DOCl    In2I6    Nb+     Sc2O
Ag-       BaS             CH3COOH         DO2     In2O     Nb-     Sc2O2
Air       Ba2             OHCH2COOH       DO2-    K        NbCl5   Si
Al        Be              C2H5            D2      K+       NbO     Si+
Al+       Be+             C2H5Br          D2+     K-       NbOCl3  Si-
Al-       Be++            C2H6            D2-     KAlF4    NbO2    SiBr
AlBr      BeBr            CH3N2CH3        D2O     KBO2     Ne      SiBr2
AlBr2     BeBr2           C2H5OH          D2O2    KBr      Ne+     SiBr3
AlBr3     BeCl            CH3OCH3         D2S     KCN      Ni      SiBr4
AlC       BeCl2           CH3O2CH3        e-      KCl      Ni+     SiC
AlC2      BeF             CCN             F       KF       Ni-     SiC2
AlCl      BeF2            CNC             F+      KH       NiCl    SiCl
AlCl+     BeH             OCCN            F-      KI       NiCl2   SiCl2
AlCl2     BeH+            C2N2            FCN     Kli      NiO     SiCl3
AlCl3     BeH2            C2O             FCO     KNO2     NiS     SiCl4
AlF       BeI             C3              FO      KNO3     O       SiF
AlF+      BeI2            C3H3_1_propynl  FO2_FOO KNa      O+      SiFCl
AlFCl     BeN             C3H3_2_propynl  FO2_OFO KO       O-      SiF2
AlFCl2    BeO             C3H4_allene     F2      KOH      OD      SiF3
AlF2      BeOH            C3H4_propyne    F2O     K2       OD-     SiF4
AlF2-     BeOH+           C3H4_cyclo      F2O2    K2+      OH      SiH
AlF2Cl    Be_OH_2         C3H5_allyl      FS2F    K2Br2    OH+     SiH+
AlF3      BeS             C3H6_propylene  Fe      K2CO3    OH-     SiHBr3
AlF4-     Be2             C3H6_cyclo      Fe+     K2C2N2   O2      SiHCl
AlH       Be2Cl4          C3H6O_propylox  Fe_CO_5 K2Cl2    O2+     SiHCl3
AlHCl     Be2F4           C3H6O_acetone   FeCl    K2F2     O2-     SiHF
AlHCl2    Be2O            C3H6O_propanal  FeCl2   K2I2     O3      SiHF3
AlHF      Be2OF2          C3H7_n_propyl   FeCl3   K2O      P       SiHI3
AlHFCl    Be2O2           C3H7_i_propyl   FeO     K2O+     P+      SiH2
AlHF2     Be3O3           C3H8            Fe_OH_2 K2O2     P-      SiH2Br2
AlH2      Be4O4           C3H8O_1propanol Fe2Cl4  K2O2H2   PCl     SiH2Cl2
AlH2Cl    Br              C3H8O_2propanol Fe2Cl6  K2SO4    PCl2    SiH2F2
AlH2F     Br+             CNCOCN          Ga      Kr       PCl2-   SiH2I2
AlH3      Br-             C3O2            Ga+     Kr+      PCl3    SiH3
AlI       BrCl            C4              GaBr    li       PCl5    SiH3Br
AlI2      BrF             C4H2_butadiyne  GaBr2   li+      PF      SiH3Cl
AlI3      BrF3            C4H4_1_3-cyclo  GaBr3   li-      PF+     SiH3F
AlN       BrF5            C4H6_butadiene  GaCl    liAlF4   PF-     SiH3I
AlO       BrO             C4H6_1butyne    GaCl2   liBO2    PFCl    SiH4
AlO+      OBrO            C4H6_2butyne    GaCl3   liBr     PFCl-   SiI
AlO-      BrOO            C4H6_cyclo      GaF     liCl     PFCl2   SiI2
AlOCl     BrO3            C4H8_1_butene   GaF2    liF      PFCl4   SiN
AlOCl2    Br2             C4H8_cis2_buten GaF3    liH      PF2     SiO
AlOF      BrBrO           C4H8_isobutene  GaH     liI      PF2-    SiO2
AlOF2     BrOBr           C4H8_cyclo      GaI     liN      PF2Cl   SiS
AlOF2-    C               C4H9_n_butyl    GaI2    liNO2    PF2Cl3  SiS2
AlOH      C+              C4H9_i_butyl    GaI3    liNO3    PF3     Si2
AlOHCl    C-              C4H9_s_butyl    GaO     liO      PF3Cl2  Si2C
AlOHCl2   CBr             C4H9_t_butyl    GaOH    liOF     PF4Cl   Si2F6
AlOHF     CBr2            C4H10_n_butane  Ga2Br2  liOH     PF5     Si2N
AlOHF2    CBr3            C4H10_isobutane Ga2Br4  liON     PH      Si3
AlO2      CBr4            C4N2            Ga2Br6  li2      PH2     Sn
AlO2-     CCl             C5              Ga2Cl2  li2+     PH2-    Sn+
Al_OH_2   CCl2            C5H6_1_3cyclo   Ga2Cl4  li2Br2   PH3     Sn-
Al_OH_2Cl CCl2Br2         C5H8_cyclo      Ga2Cl6  li2F2    PN      SnBr
Al_OH_2F  CCl3            C5H10_1_pentene Ga2F2   li2I2    PO      SnBr2
Al_OH_3   CCl3Br          C5H10_cyclo     Ga2F4   li2O     PO-     SnBr3
AlS       CCl4            C5H11_pentyl    Ga2F6   li2O+    POCl3   SnBr4
AlS2      CF              C5H11_t_pentyl  Ga2I2   li2O2    POFCl2  SnCl
Al2       CF+             C5H12_n_pentane Ga2I4   li2O2H2  POF2Cl  SnCl2
Al2Br6    CFBr3           C5H12_i_pentane Ga2I6   li2SO4   POF3    SnCl3
Al2C2     CFCl            CH3C_CH3_2CH3   Ga2O    li3+     PO2     SnCl4
Al2Cl6    CFClBr2         C6D5_phenyl     Ge      li3Br3   PO2-    SnF
Al2F6     CFCl2           C6D6            Ge+     li3Cl3   PS      SnF2
Al2I6     CFCl2Br         C6H2            Ge-     li3F3    P2      SnF3
Al2O      CFCl3           C6H5_phenyl     GeBr    li3I3    P2O3    SnF4
Al2O+     CF2             C6H5O_phenoxy   GeBr2   Mg       P2O4    SnI
Al2O2     CF2+            C6H6            GeBr3   Mg+      P2O5    SnI2
Al2O2+    CF2Br2          C6H5OH_phenol   GeBr4   MgBr     P3      SnI3
Al2O3     CF2Cl           C6H10_cyclo     GeCl    MgBr2    P3O6    SnI4
Al2S      CF2ClBr         C6H12_1_hexene  GeCl2   MgCl     P4      SnO
Al2S2     CF2Cl2          C6H12_cyclo     GeCl3   MgCl+    P4O6    SnO2
Ar        CF3             C6H13_n_hexyl   GeCl4   MgCl2    P4O7    SnS
Ar+       CF3+            C6H14_n_hexane  GeF     MgF      P4O8    SnS2
B         CF3Br           C7H7_benzyl     GeF2    MgF+     P4O9    Sn2
B+        CF3Cl           C7H8            GeF3    MgF2     P4O10   Sr
B-        CF4             C7H8O_cresol_mx GeF4    MgF2+    Pb      Sr+
BBr       CH+             C7H14_1_heptene GeH4    MgH      Pb+     SrBr
BBr2      CHBr3           C7H15_n_heptyl  GeI     MgI      Pb-     SrBr2
BBr3      CHCl            C7H16_n_heptane GeO     MgI2     PbBr    SrCl
BC        CHClBr2         C7H16_2_methylh GeO2    MgN      PbBr2   SrCl+
BC2       CHCl2           C8H8_styrene    GeS     MgO      PbBr3   SrCl2
BCl       CHCl2Br         C8H10_ethylbenz GeS2    MgOH     PbBr4   SrF
BCl+      CHCl3           C8H16_1_octene  Ge2     MgOH+    PbCl    SrF+
BClOH     CHF             C8H17_n_octyl   H       Mg_OH_2  PbCl2   SrF2
BCl_OH_2  CHFBr2          C8H18_n_octane  H+      MgS      PbCl3   SrH
BCl2      CHFCl           C8H18_isooctane H-      Mg2      PbCl4   SrI
BCl2+     CHFClBr         C9H19_n_nonyl   HAlO    Mg2F4    PbF     SrI2
BCl2OH    CHFCl2          C10H8_naphthale HAlO2   Mn       PbF2    SrO
BF        CHF2            C10H21_n_decyl  HBO     Mn+      PbF3    SrOH
BFCl      CHF2Br          C12H9_o_bipheny HBO+    Mo       PbF4    SrOH+
BFCl2     CHF2Cl          C12H10_biphenyl HBO2    Mo+      PbI     Sr_OH_2
BFOH      CHF3            Ca              HBS     Mo-      PbI2    SrS
BF_OH_2   CHI3            Ca+             HBS+    MoO      PbI3    Sr2
BF2       CH2             CaBr            HCN     MoO2     PbI4    Ta
BF2+      CH2Br2          CaBr2           HCO     MoO3     PbO     Ta+
BF2-      CH2Cl           CaCl            HCO+    MoO3-    PbO2    Ta-
BF2Cl     CH2ClBr         CaCl+           HCCN    Mo2O6    PbS     TaCl5
BF2OH     CH2Cl2          CaCl2           HCCO    Mo3O9    PbS2    TaO
BF3       CH2F            CaF             HCl     Mo4O12   Rb      TaO2
BF4-      CH2FBr          CaF+            HD      Mo5O15   Rb+     Ti
BH        CH2FCl          CaF2            HD+     N        Rb-     Ti+
BHCl      CH2F2           CaH             HDO     N+       RbBO2   Ti-
BHCl2     CH2I2           CaI             HDO2    N-       RbBr    TiCl
BHF       CH3             CaI2            HF      NCO      RbCl    TiCl2
BHFCl     CH3Br           CaO             HI      ND       RbF     TiCl3
BHF2      CH3Cl           CaO+            HNC     ND2      RbH     TiCl4
BH2       CH3F            CaOH            HNCO    ND3      RbI     TiO
BH2Cl     CH3I            CaOH+           HNO     NF       RbK     TiO+
BH2F      CH2OH           Ca_OH_2         HNO2    NF2      Rbli    TiOCl
BH3       CH2OH+          CaS             HNO3    NF3      RbNO2   TiOCl2
BH3NH3    CH3O            Ca2             HOCl    NH       RbNO3   TiO2
BH4       CH4             Cd              HOF     NH+      RbNa    U
BI        CH3OH           Cd+             HO2     NHF      RbO     UF
BI2       CH3OOH          Cl              HO2-    NHF2     RbOH    UF+
BI3       CI              Cl+             HPO     NH2      Rb2Br2  UF-
BN        CI2             Cl-             HSO3F   NH2F     Rb2Cl2  UF2
BO        CI3             ClCN            H2      NH3      Rb2F2   UF2+
BO-       CI4             ClF             H2+     NH2OH    Rb2I2   UF2-
BOCl      CN              ClF3            H2-     NH4+     Rb2O    UF3
BOCl2     CN+             ClF5            HBOH    NO       Rb2O2   UF3+
BOF       CN-             ClO             HCOOH   NOCl     Rb2O2H2 UF3-
BOF2      CNN             ClO2            H2F2    NOF      Rb2SO4  UF4
BOH       CO              Cl2             H2O     NOF3     Rn      UF4+
BO2       CO+             Cl2O            H2O+    NO2      Rn+     UF4-
BO2-      COCl            Co              H2O2    NO2-     S       UF5
B_OH_2    COCl2           Co+             H2S     NO2Cl    S+      UF5+
BS        COFCl           Co-             H2SO4   NO2F     S-      UF5-
BS2       COF2            Cr              H2BOH   NO3      SCl     UF6
B2        COHCl           Cr+             HB_OH_2 NO3-     SCl2    UF6-
B2C       COHF            Cr-             H3BO3   NO3F     SCl2+   UO
B2Cl4     COS             CrN             H3B3O3  N2       SD      UO+
B2F4      CO2             CrO             H3B3O6  N2+      SF      UOF
B2H       CO2+            CrO2            H3F3    N2-      SF+     UOF2
B2H2      COOH            CrO3            H3O+    NCN      SF-     UOF3
B2H3      CP              CrO3-           H4F4    N2D2_cis SF2     UOF4
B2H3_db   CS              Cs              H5F5    N2F2     SF2+    UO2
B2H4      CS2             Cs+             H6F6    N2F4     SF2-    UO2+
B2H4_db   C2              Cs-             H7F7    N2H2     SF3     UO2-
B2H5      C2+             CsBO2           He      NH2NO2   SF3+    UO2F
B2H5_db   C2-             CsBr            He+     N2H4     SF3-    UO2F2
B2H6      C2Cl            CsCl            Hg      N2O      SF4     UO3
B2O       C2Cl2           CsF             Hg+     N2O+     SF4+    UO3-
B2O2      C2Cl3           CsH             HgBr2   N2O3     SF4-    V
B2O3      C2Cl4           CsI             I       N2O4     SF5     V+
B2_OH_4   C2Cl6           Csli            I+      N2O5     SF5+    V-
B2S       C2F             CsNO2           I-      N3       SF5-    VCl4
B2S2      C2FCl           CsNO3           IF5     N3H      SF6     VN
B2S3      C2FCl3          CsNa            IF7     Na       SF6-    VO
B3H7_C2v  C2F2            CsO             I2      Na+      SH      VO2
B3H7_Cs   C2F2Cl2         CsOH            In      Na-      SH-     V4O10
B3H9      C2F3            CsRb            In+     NaAlF4   SN      W
B3N3H6    C2F3Cl          Cs2             InBr    NaBO2    SO      W+
B3O3Cl3   C2F4            Cs2Br2          InBr2   NaBr     SO-     W-
B3O3FCl2  C2F6            Cs2CO3          InBr3   NaCN     SOF2    WCl6
B3O3F2Cl  C2H             Cs2Cl2          InCl    NaCl     SO2     WO
B3O3F3    C2HCl           Cs2F2           InCl2   NaF      SO2-    WOCl4
B4H4      C2HCl3          Cs2I2           InCl3   NaH      SO2Cl2  WO2
B4H10     C2HF            Cs2O            InF     NaI      SO2FCl  WO2Cl2
B4H12     C2HFCl2         Cs2O+           InF2    Nali     SO2F2   WO3
B5H9      C2HF2Cl         Cs2O2           InF3    NaNO2    SO3     WO3-
Ba        C2HF3           Cs2O2H2         InH     NaNO3    S2      Xe
Ba+       C2H2_vinylidene Cs2SO4          InI     NaO      S2-     Xe+
BaBr      C2H2Cl2         Cu              InI2    NaOH     S2Cl2   Zn
BaBr2     C2H2FCl         Cu+             InI3    NaOH+    S2F2    Zn+
BaCl      C2H2F2          Cu-             InO     Na2      S2O     Zr
BaCl+     CH2CO_ketene    CuCl            InOH    Na2Br2   S3      Zr+
BaCl2     O_CH_2O         CuF             In2Br2  Na2Cl2   S4      Zr-
BaF       HO_CO_2OH       CuF2            In2Br4  Na2F2    S5      ZrN
BaF+      C2H3_vinyl      CuO             In2Br6  Na2I2    S6      ZrO
BaF2      CH2Br-COOH      Cu2             In2Cl2  Na2O     S7      ZrO+
BaH       C2H3Cl          Cu3Cl3          In2Cl4  Na2O+    S8      ZrO2
BaI       CH2Cl-COOH      D               In2Cl6  Na2O2    Sc
BaI2      C2H3F           D+              In2F2   Na2O2H2  Sc+
BaO       CH3CN           D-              In2F4   Na2SO4   Sc-
BaO+      CH3CO_acetyl    DBr             In2F6   Na3Cl3   ScO
BaOH      C2H4            DCl             In2I2   Na3F3    ScO+
</pre></blockquote>
</html>"));
        end SingleGasesData;
      annotation (Documentation(info="<html>
</html>"));
      end Common;
      annotation (Documentation(info="<html>
<p>This package contains data for the 1241 ideal gases from</p>
<blockquote>
  <p>McBride B.J., Zehe M.J., and Gordon S. (2002): <strong>NASA Glenn Coefficients
  for Calculating Thermodynamic Properties of Individual Species</strong>. NASA
  report TP-2002-211556</p>
</blockquote>
<p>Medium models for some of these gases are available in package
<a href=\"modelica://Modelica.Media.IdealGases.SingleGases\">IdealGases.SingleGases</a>
and some examples for mixtures are available in package <a href=\"modelica://Modelica.Media.IdealGases.MixtureGases\">IdealGases.MixtureGases</a>
</p>
<h4>Using and Adapting Medium Models</h4>
<p>
The data records allow computing the ideal gas specific enthalpy, specific entropy and heat capacity of the substances listed below. From them, even the Gibbs energy and equilibrium constants for reactions can be computed. Critical data that is needed for computing the viscosity and thermal conductivity is not included. In order to add mixtures or single substance medium packages that are
subtypes of
<a href=\"modelica://Modelica.Media.Interfaces.PartialMedium\">Interfaces.PartialMedium</a>
(i.e., can be utilized at all places where PartialMedium is defined),
a few additional steps have to be performed:
</p>
<ol>
<li>
All single gas media need to define a constant instance of record
<a href=\"modelica://Modelica.Media.Interfaces.PartialMedium.FluidConstants\">IdealGases.Common.SingleGasNasa.FluidConstants</a>.
For 37 ideal gases such records are provided in package
<a href=\"modelica://Modelica.Media.IdealGases.Common.FluidData\">IdealGases.Common.FluidData</a>.
For the other gases, such a record instance has to be provided by the user, e.g., by getting
the data from a commercial or public data base. A public source of the needed data is for example the <a href=\"http://webbook.nist.gov/chemistry/\"> NIST Chemistry WebBook</a></li>

<li>When the data is available, and a user has an instance of a
<a href=\"modelica://Modelica.Media.Interfaces.PartialMedium.FluidConstants\">FluidConstants</a> record filled with data, a medium package has to be written. Note that only the dipole moment, the acentric factor and critical data are necessary for the viscosity and thermal conductivity functions.</li>
<li><ul>
<li>For single components, a new package following the pattern in
<a href=\"modelica://Modelica.Media.IdealGases.SingleGases\">IdealGases.SingleGases</a> has to be created, pointing both to a data record for cp and to a user-defined fluidConstants record.</li>
<li>For mixtures of several components, a new package following the pattern in
<a href=\"modelica://Modelica.Media.IdealGases.MixtureGases\">IdealGases.MixtureGases</a> has to be created, building an array of data records for cp and an array of (partly) user-defined fluidConstants records.</li>
</ul></li>
</ol>
<p>Note that many properties can computed for the full set of 1241 gases listed below, but due to the missing viscosity and thermal conductivity functions, no fully Modelica.Media-compliant media can be defined.</p>
<p>
Data records for heat capacity, specific enthalpy and specific entropy exist for the following substances and ions:
</p>
<blockquote><pre>
Ag        BaOH+           C2H4O_ethylen_o DF      In2I4    Nb      ScO2
Ag+       Ba_OH_2         CH3CHO_ethanal  DOCl    In2I6    Nb+     Sc2O
Ag-       BaS             CH3COOH         DO2     In2O     Nb-     Sc2O2
Air       Ba2             OHCH2COOH       DO2-    K        NbCl5   Si
Al        Be              C2H5            D2      K+       NbO     Si+
Al+       Be+             C2H5Br          D2+     K-       NbOCl3  Si-
Al-       Be++            C2H6            D2-     KAlF4    NbO2    SiBr
AlBr      BeBr            CH3N2CH3        D2O     KBO2     Ne      SiBr2
AlBr2     BeBr2           C2H5OH          D2O2    KBr      Ne+     SiBr3
AlBr3     BeCl            CH3OCH3         D2S     KCN      Ni      SiBr4
AlC       BeCl2           CH3O2CH3        e-      KCl      Ni+     SiC
AlC2      BeF             CCN             F       KF       Ni-     SiC2
AlCl      BeF2            CNC             F+      KH       NiCl    SiCl
AlCl+     BeH             OCCN            F-      KI       NiCl2   SiCl2
AlCl2     BeH+            C2N2            FCN     Kli      NiO     SiCl3
AlCl3     BeH2            C2O             FCO     KNO2     NiS     SiCl4
AlF       BeI             C3              FO      KNO3     O       SiF
AlF+      BeI2            C3H3_1_propynl  FO2_FOO KNa      O+      SiFCl
AlFCl     BeN             C3H3_2_propynl  FO2_OFO KO       O-      SiF2
AlFCl2    BeO             C3H4_allene     F2      KOH      OD      SiF3
AlF2      BeOH            C3H4_propyne    F2O     K2       OD-     SiF4
AlF2-     BeOH+           C3H4_cyclo      F2O2    K2+      OH      SiH
AlF2Cl    Be_OH_2         C3H5_allyl      FS2F    K2Br2    OH+     SiH+
AlF3      BeS             C3H6_propylene  Fe      K2CO3    OH-     SiHBr3
AlF4-     Be2             C3H6_cyclo      Fe+     K2C2N2   O2      SiHCl
AlH       Be2Cl4          C3H6O_propylox  Fe_CO_5 K2Cl2    O2+     SiHCl3
AlHCl     Be2F4           C3H6O_acetone   FeCl    K2F2     O2-     SiHF
AlHCl2    Be2O            C3H6O_propanal  FeCl2   K2I2     O3      SiHF3
AlHF      Be2OF2          C3H7_n_propyl   FeCl3   K2O      P       SiHI3
AlHFCl    Be2O2           C3H7_i_propyl   FeO     K2O+     P+      SiH2
AlHF2     Be3O3           C3H8            Fe_OH_2 K2O2     P-      SiH2Br2
AlH2      Be4O4           C3H8O_1propanol Fe2Cl4  K2O2H2   PCl     SiH2Cl2
AlH2Cl    Br              C3H8O_2propanol Fe2Cl6  K2SO4    PCl2    SiH2F2
AlH2F     Br+             CNCOCN          Ga      Kr       PCl2-   SiH2I2
AlH3      Br-             C3O2            Ga+     Kr+      PCl3    SiH3
AlI       BrCl            C4              GaBr    li       PCl5    SiH3Br
AlI2      BrF             C4H2_butadiyne  GaBr2   li+      PF      SiH3Cl
AlI3      BrF3            C4H4_1_3-cyclo  GaBr3   li-      PF+     SiH3F
AlN       BrF5            C4H6_butadiene  GaCl    liAlF4   PF-     SiH3I
AlO       BrO             C4H6_1butyne    GaCl2   liBO2    PFCl    SiH4
AlO+      OBrO            C4H6_2butyne    GaCl3   liBr     PFCl-   SiI
AlO-      BrOO            C4H6_cyclo      GaF     liCl     PFCl2   SiI2
AlOCl     BrO3            C4H8_1_butene   GaF2    liF      PFCl4   SiN
AlOCl2    Br2             C4H8_cis2_buten GaF3    liH      PF2     SiO
AlOF      BrBrO           C4H8_isobutene  GaH     liI      PF2-    SiO2
AlOF2     BrOBr           C4H8_cyclo      GaI     liN      PF2Cl   SiS
AlOF2-    C               C4H9_n_butyl    GaI2    liNO2    PF2Cl3  SiS2
AlOH      C+              C4H9_i_butyl    GaI3    liNO3    PF3     Si2
AlOHCl    C-              C4H9_s_butyl    GaO     liO      PF3Cl2  Si2C
AlOHCl2   CBr             C4H9_t_butyl    GaOH    liOF     PF4Cl   Si2F6
AlOHF     CBr2            C4H10_n_butane  Ga2Br2  liOH     PF5     Si2N
AlOHF2    CBr3            C4H10_isobutane Ga2Br4  liON     PH      Si3
AlO2      CBr4            C4N2            Ga2Br6  li2      PH2     Sn
AlO2-     CCl             C5              Ga2Cl2  li2+     PH2-    Sn+
Al_OH_2   CCl2            C5H6_1_3cyclo   Ga2Cl4  li2Br2   PH3     Sn-
Al_OH_2Cl CCl2Br2         C5H8_cyclo      Ga2Cl6  li2F2    PN      SnBr
Al_OH_2F  CCl3            C5H10_1_pentene Ga2F2   li2I2    PO      SnBr2
Al_OH_3   CCl3Br          C5H10_cyclo     Ga2F4   li2O     PO-     SnBr3
AlS       CCl4            C5H11_pentyl    Ga2F6   li2O+    POCl3   SnBr4
AlS2      CF              C5H11_t_pentyl  Ga2I2   li2O2    POFCl2  SnCl
Al2       CF+             C5H12_n_pentane Ga2I4   li2O2H2  POF2Cl  SnCl2
Al2Br6    CFBr3           C5H12_i_pentane Ga2I6   li2SO4   POF3    SnCl3
Al2C2     CFCl            CH3C_CH3_2CH3   Ga2O    li3+     PO2     SnCl4
Al2Cl6    CFClBr2         C6D5_phenyl     Ge      li3Br3   PO2-    SnF
Al2F6     CFCl2           C6D6            Ge+     li3Cl3   PS      SnF2
Al2I6     CFCl2Br         C6H2            Ge-     li3F3    P2      SnF3
Al2O      CFCl3           C6H5_phenyl     GeBr    li3I3    P2O3    SnF4
Al2O+     CF2             C6H5O_phenoxy   GeBr2   Mg       P2O4    SnI
Al2O2     CF2+            C6H6            GeBr3   Mg+      P2O5    SnI2
Al2O2+    CF2Br2          C6H5OH_phenol   GeBr4   MgBr     P3      SnI3
Al2O3     CF2Cl           C6H10_cyclo     GeCl    MgBr2    P3O6    SnI4
Al2S      CF2ClBr         C6H12_1_hexene  GeCl2   MgCl     P4      SnO
Al2S2     CF2Cl2          C6H12_cyclo     GeCl3   MgCl+    P4O6    SnO2
Ar        CF3             C6H13_n_hexyl   GeCl4   MgCl2    P4O7    SnS
Ar+       CF3+            C6H14_n_hexane  GeF     MgF      P4O8    SnS2
B         CF3Br           C7H7_benzyl     GeF2    MgF+     P4O9    Sn2
B+        CF3Cl           C7H8            GeF3    MgF2     P4O10   Sr
B-        CF4             C7H8O_cresol_mx GeF4    MgF2+    Pb      Sr+
BBr       CH+             C7H14_1_heptene GeH4    MgH      Pb+     SrBr
BBr2      CHBr3           C7H15_n_heptyl  GeI     MgI      Pb-     SrBr2
BBr3      CHCl            C7H16_n_heptane GeO     MgI2     PbBr    SrCl
BC        CHClBr2         C7H16_2_methylh GeO2    MgN      PbBr2   SrCl+
BC2       CHCl2           C8H8_styrene    GeS     MgO      PbBr3   SrCl2
BCl       CHCl2Br         C8H10_ethylbenz GeS2    MgOH     PbBr4   SrF
BCl+      CHCl3           C8H16_1_octene  Ge2     MgOH+    PbCl    SrF+
BClOH     CHF             C8H17_n_octyl   H       Mg_OH_2  PbCl2   SrF2
BCl_OH_2  CHFBr2          C8H18_n_octane  H+      MgS      PbCl3   SrH
BCl2      CHFCl           C8H18_isooctane H-      Mg2      PbCl4   SrI
BCl2+     CHFClBr         C9H19_n_nonyl   HAlO    Mg2F4    PbF     SrI2
BCl2OH    CHFCl2          C10H8_naphthale HAlO2   Mn       PbF2    SrO
BF        CHF2            C10H21_n_decyl  HBO     Mn+      PbF3    SrOH
BFCl      CHF2Br          C12H9_o_bipheny HBO+    Mo       PbF4    SrOH+
BFCl2     CHF2Cl          C12H10_biphenyl HBO2    Mo+      PbI     Sr_OH_2
BFOH      CHF3            Ca              HBS     Mo-      PbI2    SrS
BF_OH_2   CHI3            Ca+             HBS+    MoO      PbI3    Sr2
BF2       CH2             CaBr            HCN     MoO2     PbI4    Ta
BF2+      CH2Br2          CaBr2           HCO     MoO3     PbO     Ta+
BF2-      CH2Cl           CaCl            HCO+    MoO3-    PbO2    Ta-
BF2Cl     CH2ClBr         CaCl+           HCCN    Mo2O6    PbS     TaCl5
BF2OH     CH2Cl2          CaCl2           HCCO    Mo3O9    PbS2    TaO
BF3       CH2F            CaF             HCl     Mo4O12   Rb      TaO2
BF4-      CH2FBr          CaF+            HD      Mo5O15   Rb+     Ti
BH        CH2FCl          CaF2            HD+     N        Rb-     Ti+
BHCl      CH2F2           CaH             HDO     N+       RbBO2   Ti-
BHCl2     CH2I2           CaI             HDO2    N-       RbBr    TiCl
BHF       CH3             CaI2            HF      NCO      RbCl    TiCl2
BHFCl     CH3Br           CaO             HI      ND       RbF     TiCl3
BHF2      CH3Cl           CaO+            HNC     ND2      RbH     TiCl4
BH2       CH3F            CaOH            HNCO    ND3      RbI     TiO
BH2Cl     CH3I            CaOH+           HNO     NF       RbK     TiO+
BH2F      CH2OH           Ca_OH_2         HNO2    NF2      Rbli    TiOCl
BH3       CH2OH+          CaS             HNO3    NF3      RbNO2   TiOCl2
BH3NH3    CH3O            Ca2             HOCl    NH       RbNO3   TiO2
BH4       CH4             Cd              HOF     NH+      RbNa    U
BI        CH3OH           Cd+             HO2     NHF      RbO     UF
BI2       CH3OOH          Cl              HO2-    NHF2     RbOH    UF+
BI3       CI              Cl+             HPO     NH2      Rb2Br2  UF-
BN        CI2             Cl-             HSO3F   NH2F     Rb2Cl2  UF2
BO        CI3             ClCN            H2      NH3      Rb2F2   UF2+
BO-       CI4             ClF             H2+     NH2OH    Rb2I2   UF2-
BOCl      CN              ClF3            H2-     NH4+     Rb2O    UF3
BOCl2     CN+             ClF5            HBOH    NO       Rb2O2   UF3+
BOF       CN-             ClO             HCOOH   NOCl     Rb2O2H2 UF3-
BOF2      CNN             ClO2            H2F2    NOF      Rb2SO4  UF4
BOH       CO              Cl2             H2O     NOF3     Rn      UF4+
BO2       CO+             Cl2O            H2O+    NO2      Rn+     UF4-
BO2-      COCl            Co              H2O2    NO2-     S       UF5
B_OH_2    COCl2           Co+             H2S     NO2Cl    S+      UF5+
BS        COFCl           Co-             H2SO4   NO2F     S-      UF5-
BS2       COF2            Cr              H2BOH   NO3      SCl     UF6
B2        COHCl           Cr+             HB_OH_2 NO3-     SCl2    UF6-
B2C       COHF            Cr-             H3BO3   NO3F     SCl2+   UO
B2Cl4     COS             CrN             H3B3O3  N2       SD      UO+
B2F4      CO2             CrO             H3B3O6  N2+      SF      UOF
B2H       CO2+            CrO2            H3F3    N2-      SF+     UOF2
B2H2      COOH            CrO3            H3O+    NCN      SF-     UOF3
B2H3      CP              CrO3-           H4F4    N2D2_cis SF2     UOF4
B2H3_db   CS              Cs              H5F5    N2F2     SF2+    UO2
B2H4      CS2             Cs+             H6F6    N2F4     SF2-    UO2+
B2H4_db   C2              Cs-             H7F7    N2H2     SF3     UO2-
B2H5      C2+             CsBO2           He      NH2NO2   SF3+    UO2F
B2H5_db   C2-             CsBr            He+     N2H4     SF3-    UO2F2
B2H6      C2Cl            CsCl            Hg      N2O      SF4     UO3
B2O       C2Cl2           CsF             Hg+     N2O+     SF4+    UO3-
B2O2      C2Cl3           CsH             HgBr2   N2O3     SF4-    V
B2O3      C2Cl4           CsI             I       N2O4     SF5     V+
B2_OH_4   C2Cl6           Csli            I+      N2O5     SF5+    V-
B2S       C2F             CsNO2           I-      N3       SF5-    VCl4
B2S2      C2FCl           CsNO3           IF5     N3H      SF6     VN
B2S3      C2FCl3          CsNa            IF7     Na       SF6-    VO
B3H7_C2v  C2F2            CsO             I2      Na+      SH      VO2
B3H7_Cs   C2F2Cl2         CsOH            In      Na-      SH-     V4O10
B3H9      C2F3            CsRb            In+     NaAlF4   SN      W
B3N3H6    C2F3Cl          Cs2             InBr    NaBO2    SO      W+
B3O3Cl3   C2F4            Cs2Br2          InBr2   NaBr     SO-     W-
B3O3FCl2  C2F6            Cs2CO3          InBr3   NaCN     SOF2    WCl6
B3O3F2Cl  C2H             Cs2Cl2          InCl    NaCl     SO2     WO
B3O3F3    C2HCl           Cs2F2           InCl2   NaF      SO2-    WOCl4
B4H4      C2HCl3          Cs2I2           InCl3   NaH      SO2Cl2  WO2
B4H10     C2HF            Cs2O            InF     NaI      SO2FCl  WO2Cl2
B4H12     C2HFCl2         Cs2O+           InF2    Nali     SO2F2   WO3
B5H9      C2HF2Cl         Cs2O2           InF3    NaNO2    SO3     WO3-
Ba        C2HF3           Cs2O2H2         InH     NaNO3    S2      Xe
Ba+       C2H2_vinylidene Cs2SO4          InI     NaO      S2-     Xe+
BaBr      C2H2Cl2         Cu              InI2    NaOH     S2Cl2   Zn
BaBr2     C2H2FCl         Cu+             InI3    NaOH+    S2F2    Zn+
BaCl      C2H2F2          Cu-             InO     Na2      S2O     Zr
BaCl+     CH2CO_ketene    CuCl            InOH    Na2Br2   S3      Zr+
BaCl2     O_CH_2O         CuF             In2Br2  Na2Cl2   S4      Zr-
BaF       HO_CO_2OH       CuF2            In2Br4  Na2F2    S5      ZrN
BaF+      C2H3_vinyl      CuO             In2Br6  Na2I2    S6      ZrO
BaF2      CH2Br-COOH      Cu2             In2Cl2  Na2O     S7      ZrO+
BaH       C2H3Cl          Cu3Cl3          In2Cl4  Na2O+    S8      ZrO2
BaI       CH2Cl-COOH      D               In2Cl6  Na2O2    Sc
BaI2      C2H3F           D+              In2F2   Na2O2H2  Sc+
BaO       CH3CN           D-              In2F4   Na2SO4   Sc-
BaO+      CH3CO_acetyl    DBr             In2F6   Na3Cl3   ScO
BaOH      C2H4            DCl             In2I2   Na3F3    ScO+
</pre></blockquote></html>"));
    end IdealGases;

    package Water "Medium models for water"
    extends Modelica.Icons.VariantsPackage;
    import Modelica.Media.Water.ConstantPropertyLiquidWater.simpleWaterConstants;

    constant Modelica.Media.Interfaces.Types.TwoPhase.FluidConstants[1]
      waterConstants(
      each chemicalFormula="H2O",
      each structureFormula="H2O",
      each casRegistryNumber="7732-18-5",
      each iupacName="oxidane",
      each molarMass=0.018015268,
      each criticalTemperature=647.096,
      each criticalPressure=22064.0e3,
      each criticalMolarVolume=1/322.0*0.018015268,
      each normalBoilingPoint=373.124,
      each meltingPoint=273.15,
      each triplePointTemperature=273.16,
      each triplePointPressure=611.657,
      each acentricFactor=0.344,
      each dipoleMoment=1.8,
      each hasCriticalData=true);

    package ConstantPropertyLiquidWater
      "Water: Simple liquid water medium (incompressible, constant data)"

      constant Modelica.Media.Interfaces.Types.Basic.FluidConstants[1]
        simpleWaterConstants(
        each chemicalFormula="H2O",
        each structureFormula="H2O",
        each casRegistryNumber="7732-18-5",
        each iupacName="oxidane",
        each molarMass=0.018015268);
      extends Interfaces.PartialSimpleMedium(
        mediumName="SimpleLiquidWater",
        cp_const=4184,
        cv_const=4184,
        d_const=995.586,
        eta_const=1.e-3,
        lambda_const=0.598,
        a_const=1484,
        T_min=Cv.from_degC(-1),
        T_max=Cv.from_degC(130),
        T0=273.15,
        MM_const=0.018015268,
        fluidConstants=simpleWaterConstants);
      annotation (Documentation(info="<html>

</html>"));
    end ConstantPropertyLiquidWater;

    package StandardWater = WaterIF97_ph
      "Water using the IF97 standard, explicit in p and h. Recommended for most applications";

    package StandardWaterOnePhase = WaterIF97_pT
      "Water using the IF97 standard, explicit in p and T. Recommended for one-phase applications";

    package WaterIF97_pT "Water using the IF97 standard, explicit in p and T"
      extends WaterIF97_base(
        ThermoStates=Modelica.Media.Interfaces.Choices.IndependentVariables.pT,
        final ph_explicit=false,
        final dT_explicit=false,
        final pT_explicit=true,
        final smoothModel=true,
        final onePhase=true);
    end WaterIF97_pT;

    package WaterIF97_ph "Water using the IF97 standard, explicit in p and h"
      extends WaterIF97_base(
        ThermoStates=Modelica.Media.Interfaces.Choices.IndependentVariables.ph,
        final ph_explicit=true,
        final dT_explicit=false,
        final pT_explicit=false,
        smoothModel=false,
        onePhase=false);
      annotation (Documentation(info="<html>

</html>"));
    end WaterIF97_ph;

    partial package WaterIF97_base
      "Water: Steam properties as defined by IAPWS/IF97 standard"

      extends Interfaces.PartialTwoPhaseMedium(
        mediumName="WaterIF97",
        substanceNames={"water"},
        singleState=false,
        SpecificEnthalpy(start=1.0e5, nominal=5.0e5),
        Density(start=150, nominal=500),
        AbsolutePressure(
          start=50e5,
          nominal=10e5,
          min=611.657,
          max=100e6),
        Temperature(
          start=500,
          nominal=500,
          min=273.15,
          max=2273.15),
        smoothModel=false,
        onePhase=false,
        fluidConstants=waterConstants);

      redeclare record extends SaturationProperties
      end SaturationProperties;

      redeclare record extends ThermodynamicState "Thermodynamic state"
        SpecificEnthalpy h "Specific enthalpy";
        Density d "Density";
        Temperature T "Temperature";
        AbsolutePressure p "Pressure";
      end ThermodynamicState;

      constant Integer Region = 0 "Region of IF97, if known, zero otherwise";
      constant Boolean ph_explicit
        "True if explicit in pressure and specific enthalpy";
      constant Boolean dT_explicit "True if explicit in density and temperature";
      constant Boolean pT_explicit "True if explicit in pressure and temperature";

      redeclare replaceable model extends BaseProperties(
        h(stateSelect=if ph_explicit and preferredMediumStates then StateSelect.prefer
               else StateSelect.default),
        d(stateSelect=if dT_explicit and preferredMediumStates then StateSelect.prefer
               else StateSelect.default),
        T(stateSelect=if (pT_explicit or dT_explicit) and preferredMediumStates
               then StateSelect.prefer else StateSelect.default),
        p(stateSelect=if (pT_explicit or ph_explicit) and preferredMediumStates
               then StateSelect.prefer else StateSelect.default))
        "Base properties of water"
        Integer phase(
          min=0,
          max=2,
          start=1,
          fixed=false) "2 for two-phase, 1 for one-phase, 0 if not known";
      equation
        MM = fluidConstants[1].molarMass;
        if Region > 0 then // Fixed region
          phase = (if Region == 4 then 2 else 1);
        elseif smoothModel then
          if onePhase then
            phase = 1;
            if ph_explicit then
              assert(((h < bubbleEnthalpy(sat) or h > dewEnthalpy(sat)) or p >
                fluidConstants[1].criticalPressure),
                "With onePhase=true this model may only be called with one-phase states h < hl or h > hv!"
                 + "(p = " + String(p) + ", h = " + String(h) + ")");
            else
              if dT_explicit then
                assert(not ((d < bubbleDensity(sat) and d > dewDensity(sat)) and T
                   < fluidConstants[1].criticalTemperature),
                  "With onePhase=true this model may only be called with one-phase states d > dl or d < dv!"
                   + "(d = " + String(d) + ", T = " + String(T) + ")");
              end if;
            end if;
          else
            phase = 0;
          end if;
        else
          if ph_explicit then
            phase = if ((h < bubbleEnthalpy(sat) or h > dewEnthalpy(sat)) or p >
              fluidConstants[1].criticalPressure) then 1 else 2;
          elseif dT_explicit then
            phase = if not ((d < bubbleDensity(sat) and d > dewDensity(sat)) and T
               < fluidConstants[1].criticalTemperature) then 1 else 2;
          else
            phase = 1;
            //this is for the one-phase only case pT
          end if;
        end if;
        if dT_explicit then
          p = pressure_dT(
                d,
                T,
                phase,
                Region);
          h = specificEnthalpy_dT(
                d,
                T,
                phase,
                Region);
          sat.Tsat = T;
          sat.psat = saturationPressure(T);
        elseif ph_explicit then
          d = density_ph(
                p,
                h,
                phase,
                Region);
          T = temperature_ph(
                p,
                h,
                phase,
                Region);
          sat.Tsat = saturationTemperature(p);
          sat.psat = p;
        else
          h = specificEnthalpy_pT(
                p,
                T,
                Region);
          d = density_pT(
                p,
                T,
                Region);
          sat.psat = p;
          sat.Tsat = saturationTemperature(p);
        end if;
        u = h - p/d;
        R_s = Modelica.Constants.R/fluidConstants[1].molarMass;
        h = state.h;
        p = state.p;
        T = state.T;
        d = state.d;
        phase = state.phase;
      end BaseProperties;

      redeclare function density_ph
        "Computes density as a function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
        output Density d "Density";
      algorithm
        d := IF97_Utilities.rho_ph(
              p,
              h,
              phase,
              region);
        annotation (Inline=true);
      end density_ph;

      redeclare function temperature_ph
        "Computes temperature as a function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEnthalpy h "Specific enthalpy";
        input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
        output Temperature T "Temperature";
      algorithm
        T := IF97_Utilities.T_ph(
              p,
              h,
              phase,
              region);
        annotation (Inline=true);
      end temperature_ph;

      redeclare function temperature_ps
        "Compute temperature from pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
        output Temperature T "Temperature";
      algorithm
        T := IF97_Utilities.T_ps(
              p,
              s,
              phase,
              region);
        annotation (Inline=true);
      end temperature_ps;

      redeclare function density_ps
        "Computes density as a function of pressure and specific enthalpy"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
        output Density d "Density";
      algorithm
        d := IF97_Utilities.rho_ps(
              p,
              s,
              phase,
              region);
        annotation (Inline=true);
      end density_ps;

      redeclare function pressure_dT
        "Computes pressure as a function of density and temperature"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
        output AbsolutePressure p "Pressure";
      algorithm
        p := IF97_Utilities.p_dT(
              d,
              T,
              phase,
              region);
        annotation (Inline=true);
      end pressure_dT;

      redeclare function specificEnthalpy_dT
        "Computes specific enthalpy as a function of density and temperature"
        extends Modelica.Icons.Function;
        input Density d "Density";
        input Temperature T "Temperature";
        input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := IF97_Utilities.h_dT(
              d,
              T,
              phase,
              region);
        annotation (Inline=true);
      end specificEnthalpy_dT;

      redeclare function specificEnthalpy_pT
        "Computes specific enthalpy as a function of pressure and temperature"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := IF97_Utilities.h_pT(
              p,
              T,
              region);
        annotation (Inline=true);
      end specificEnthalpy_pT;

      redeclare function specificEnthalpy_ps
        "Computes specific enthalpy as a function of pressure and temperature"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input SpecificEntropy s "Specific entropy";
        input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
        output SpecificEnthalpy h "Specific enthalpy";
      algorithm
        h := IF97_Utilities.h_ps(
              p,
              s,
              phase,
              region);
        annotation (Inline=true);
      end specificEnthalpy_ps;

      redeclare function density_pT
        "Computes density as a function of pressure and temperature"
        extends Modelica.Icons.Function;
        input AbsolutePressure p "Pressure";
        input Temperature T "Temperature";
        input FixedPhase phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
        output Density d "Density";
      algorithm
        d := IF97_Utilities.rho_pT(
              p,
              T,
              region);
        annotation (Inline=true);
      end density_pT;

      redeclare function extends setDewState
        "Set the thermodynamic state on the dew line"
      algorithm
        state := ThermodynamicState(
              phase=phase,
              p=sat.psat,
              T=sat.Tsat,
              h=dewEnthalpy(sat),
              d=dewDensity(sat));
        annotation (Inline=true);
      end setDewState;

      redeclare function extends setBubbleState
        "Set the thermodynamic state on the bubble line"
      algorithm
        state := ThermodynamicState(
              phase=phase,
              p=sat.psat,
              T=sat.Tsat,
              h=bubbleEnthalpy(sat),
              d=bubbleDensity(sat));
        annotation (Inline=true);
      end setBubbleState;

      redeclare function extends dynamicViscosity "Dynamic viscosity of water"
      algorithm
        eta := IF97_Utilities.dynamicViscosity(
              state.d,
              state.T,
              state.p,
              state.phase);
        annotation (Inline=true);
      end dynamicViscosity;

      redeclare function extends thermalConductivity
        "Thermal conductivity of water"
      algorithm
        lambda := IF97_Utilities.thermalConductivity(
              state.d,
              state.T,
              state.p,
              state.phase);
        annotation (Inline=true);
      end thermalConductivity;

      redeclare function extends surfaceTension
        "Surface tension in two phase region of water"
      algorithm
        sigma := IF97_Utilities.surfaceTension(sat.Tsat);
        annotation (Inline=true);
      end surfaceTension;

      redeclare function extends pressure "Return pressure of ideal gas"
      algorithm
        p := state.p;
        annotation (Inline=true);
      end pressure;

      redeclare function extends temperature "Return temperature of ideal gas"
      algorithm
        T := state.T;
        annotation (Inline=true);
      end temperature;

      redeclare function extends density "Return density of ideal gas"
      algorithm
        d := state.d;
        annotation (Inline=true);
      end density;

      redeclare function extends specificEnthalpy "Return specific enthalpy"
        extends Modelica.Icons.Function;
      algorithm
        h := state.h;
        annotation (Inline=true);
      end specificEnthalpy;

      redeclare function extends specificInternalEnergy
        "Return specific internal energy"
        extends Modelica.Icons.Function;
      algorithm
        u := state.h - state.p/state.d;
        annotation (Inline=true);
      end specificInternalEnergy;

      redeclare function extends specificGibbsEnergy "Return specific Gibbs energy"
        extends Modelica.Icons.Function;
      algorithm
        g := state.h - state.T*specificEntropy(state);
        annotation (Inline=true);
      end specificGibbsEnergy;

      redeclare function extends specificHelmholtzEnergy
        "Return specific Helmholtz energy"
        extends Modelica.Icons.Function;
      algorithm
        f := state.h - state.p/state.d - state.T*specificEntropy(state);
        annotation (Inline=true);
      end specificHelmholtzEnergy;

      redeclare function extends specificEntropy "Specific entropy of water"
      algorithm
        s := if dT_explicit then IF97_Utilities.s_dT(
              state.d,
              state.T,
              state.phase,
              Region) else if pT_explicit then IF97_Utilities.s_pT(
              state.p,
              state.T,
              Region) else IF97_Utilities.s_ph(
              state.p,
              state.h,
              state.phase,
              Region);
        annotation (Inline=true);
      end specificEntropy;

      redeclare function extends specificHeatCapacityCp
        "Specific heat capacity at constant pressure of water"
      algorithm
        cp := if dT_explicit then IF97_Utilities.cp_dT(
              state.d,
              state.T,
              Region) else if pT_explicit then IF97_Utilities.cp_pT(
              state.p,
              state.T,
              Region) else IF97_Utilities.cp_ph(
              state.p,
              state.h,
              Region);
        annotation (Inline=true);
      end specificHeatCapacityCp;

      redeclare function extends specificHeatCapacityCv
        "Specific heat capacity at constant volume of water"
      algorithm
        cv := if dT_explicit then IF97_Utilities.cv_dT(
              state.d,
              state.T,
              state.phase,
              Region) else if pT_explicit then IF97_Utilities.cv_pT(
              state.p,
              state.T,
              Region) else IF97_Utilities.cv_ph(
              state.p,
              state.h,
              state.phase,
              Region);
        annotation (Inline=true);
      end specificHeatCapacityCv;

      redeclare function extends isentropicExponent "Return isentropic exponent"
      algorithm
        gamma := if dT_explicit then IF97_Utilities.isentropicExponent_dT(
              state.d,
              state.T,
              state.phase,
              Region) else if pT_explicit then IF97_Utilities.isentropicExponent_pT(
              state.p,
              state.T,
              Region) else IF97_Utilities.isentropicExponent_ph(
              state.p,
              state.h,
              state.phase,
              Region);
        annotation (Inline=true);
      end isentropicExponent;

      redeclare function extends isothermalCompressibility
        "Isothermal compressibility of water"
      algorithm
        //    assert(state.phase <> 2, "Isothermal compressibility can not be computed with 2-phase inputs!");
        kappa := if dT_explicit then IF97_Utilities.kappa_dT(
              state.d,
              state.T,
              state.phase,
              Region) else if pT_explicit then IF97_Utilities.kappa_pT(
              state.p,
              state.T,
              Region) else IF97_Utilities.kappa_ph(
              state.p,
              state.h,
              state.phase,
              Region);
        annotation (Inline=true);
      end isothermalCompressibility;

      redeclare function extends isobaricExpansionCoefficient
        "Isobaric expansion coefficient of water"
      algorithm
        //    assert(state.phase <> 2, "The isobaric expansion coefficient can not be computed with 2-phase inputs!");
        beta := if dT_explicit then IF97_Utilities.beta_dT(
              state.d,
              state.T,
              state.phase,
              Region) else if pT_explicit then IF97_Utilities.beta_pT(
              state.p,
              state.T,
              Region) else IF97_Utilities.beta_ph(
              state.p,
              state.h,
              state.phase,
              Region);
        annotation (Inline=true);
      end isobaricExpansionCoefficient;

      redeclare function extends velocityOfSound
        "Return velocity of sound as a function of the thermodynamic state record"
      algorithm
        a := if dT_explicit then IF97_Utilities.velocityOfSound_dT(
              state.d,
              state.T,
              state.phase,
              Region) else if pT_explicit then IF97_Utilities.velocityOfSound_pT(
              state.p,
              state.T,
              Region) else IF97_Utilities.velocityOfSound_ph(
              state.p,
              state.h,
              state.phase,
              Region);
        annotation (Inline=true);
      end velocityOfSound;

      redeclare function extends isentropicEnthalpy "Compute h(s,p)"
      algorithm
        h_is := IF97_Utilities.isentropicEnthalpy(
              p_downstream,
              specificEntropy(refState),
              0);
        annotation (Inline=true);
      end isentropicEnthalpy;

      redeclare function extends density_derh_p
        "Density derivative by specific enthalpy"
      algorithm
        ddhp := IF97_Utilities.ddhp(
              state.p,
              state.h,
              state.phase,
              Region);
        annotation (Inline=true);
      end density_derh_p;

      redeclare function extends density_derp_h "Density derivative by pressure"
      algorithm
        ddph := IF97_Utilities.ddph(
              state.p,
              state.h,
              state.phase,
              Region);
        annotation (Inline=true);
      end density_derp_h;

      //   redeclare function extends density_derT_p
      //     "Density derivative by temperature"
      //   algorithm
      //     ddTp := IF97_Utilities.ddTp(state.p, state.h, state.phase);
      //   end density_derT_p;
      //
      //   redeclare function extends density_derp_T
      //     "Density derivative by pressure"
      //   algorithm
      //     ddpT := IF97_Utilities.ddpT(state.p, state.h, state.phase);
      //   end density_derp_T;

      redeclare function extends bubbleEnthalpy
        "Boiling curve specific enthalpy of water"
      algorithm
        hl := IF97_Utilities.BaseIF97.Regions.hl_p(sat.psat);
        annotation (Inline=true);
      end bubbleEnthalpy;

      redeclare function extends dewEnthalpy "Dew curve specific enthalpy of water"
      algorithm
        hv := IF97_Utilities.BaseIF97.Regions.hv_p(sat.psat);
        annotation (Inline=true);
      end dewEnthalpy;

      redeclare function extends bubbleEntropy
        "Boiling curve specific entropy of water"
      algorithm
        sl := IF97_Utilities.BaseIF97.Regions.sl_p(sat.psat);
        annotation (Inline=true);
      end bubbleEntropy;

      redeclare function extends dewEntropy "Dew curve specific entropy of water"
      algorithm
        sv := IF97_Utilities.BaseIF97.Regions.sv_p(sat.psat);
        annotation (Inline=true);
      end dewEntropy;

      redeclare function extends bubbleDensity
        "Boiling curve specific density of water"
      algorithm
        dl := if ph_explicit or pT_explicit then
          IF97_Utilities.BaseIF97.Regions.rhol_p(sat.psat) else
          IF97_Utilities.BaseIF97.Regions.rhol_T(sat.Tsat);
        annotation (Inline=true);
      end bubbleDensity;

      redeclare function extends dewDensity "Dew curve specific density of water"
      algorithm
        dv := if ph_explicit or pT_explicit then
          IF97_Utilities.BaseIF97.Regions.rhov_p(sat.psat) else
          IF97_Utilities.BaseIF97.Regions.rhov_T(sat.Tsat);
        annotation (Inline=true);
      end dewDensity;

      redeclare function extends saturationTemperature
        "Saturation temperature of water"
      algorithm
        T := IF97_Utilities.BaseIF97.Basic.tsat(p);
        annotation (Inline=true);
      end saturationTemperature;

      redeclare function extends saturationTemperature_derp
        "Derivative of saturation temperature w.r.t. pressure"
      algorithm
        dTp := IF97_Utilities.BaseIF97.Basic.dtsatofp(p);
        annotation (Inline=true);
      end saturationTemperature_derp;

      redeclare function extends saturationPressure "Saturation pressure of water"
      algorithm
        p := IF97_Utilities.BaseIF97.Basic.psat(T);
        annotation (Inline=true);
      end saturationPressure;

      redeclare function extends dBubbleDensity_dPressure
        "Bubble point density derivative"
      algorithm
        ddldp := IF97_Utilities.BaseIF97.Regions.drhol_dp(sat.psat);
        annotation (Inline=true);
      end dBubbleDensity_dPressure;

      redeclare function extends dDewDensity_dPressure
        "Dew point density derivative"
      algorithm
        ddvdp := IF97_Utilities.BaseIF97.Regions.drhov_dp(sat.psat);
        annotation (Inline=true);
      end dDewDensity_dPressure;

      redeclare function extends dBubbleEnthalpy_dPressure
        "Bubble point specific enthalpy derivative"
      algorithm
        dhldp := IF97_Utilities.BaseIF97.Regions.dhl_dp(sat.psat);
        annotation (Inline=true);
      end dBubbleEnthalpy_dPressure;

      redeclare function extends dDewEnthalpy_dPressure
        "Dew point specific enthalpy derivative"
      algorithm
        dhvdp := IF97_Utilities.BaseIF97.Regions.dhv_dp(sat.psat);
        annotation (Inline=true);
      end dDewEnthalpy_dPressure;

      redeclare function extends setState_dTX
        "Return thermodynamic state of water as function of d, T, and optional region"
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
      algorithm
        state := ThermodynamicState(
              d=d,
              T=T,
              phase=if region == 0 then 0 else if
            region == 4 then 2 else 1,
              h=specificEnthalpy_dT(
                d,
                T,
                region=region),
              p=pressure_dT(
                d,
                T,
                region=region));
        annotation (Inline=true);
      end setState_dTX;

      redeclare function extends setState_phX
        "Return thermodynamic state of water as function of p, h, and optional region"
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
      algorithm
        state := ThermodynamicState(
              d=density_ph(
                p,
                h,
                region=region),
              T=temperature_ph(
                p,
                h,
                region=region),
              phase=if region == 0 then 0 else if region==4 then 2 else 1,
              h=h,
              p=p);
        annotation (Inline=true);
      end setState_phX;

      redeclare function extends setState_psX
        "Return thermodynamic state of water as function of p, s, and optional region"
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
      algorithm
        state := ThermodynamicState(
              d=density_ps(
                p,
                s,
                region=region),
              T=temperature_ps(
                p,
                s,
                region=region),
              phase=if region == 0 then 0 else if region==4 then 2 else 1,
              h=specificEnthalpy_ps(
                p,
                s,
                region=region),
              p=p);
        annotation (Inline=true);
      end setState_psX;

      redeclare function extends setState_pTX
        "Return thermodynamic state of water as function of p, T, and optional region"
        input Integer region=Region
          "If 0, region is unknown, otherwise known and this input";
      algorithm
        state := ThermodynamicState(
              d=density_pT(
                p,
                T,
                region=region),
              T=T,
              phase=1,
              h=specificEnthalpy_pT(
                p,
                T,
                region=region),
              p=p);
        annotation (Inline=true);
      end setState_pTX;

      redeclare function extends setSmoothState
        "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
        import Modelica.Media.Common.smoothStep;
      algorithm
        state := ThermodynamicState(
              p=smoothStep(
                x,
                state_a.p,
                state_b.p,
                x_small),
              h=smoothStep(
                x,
                state_a.h,
                state_b.h,
                x_small),
              d=density_ph(smoothStep(
                x,
                state_a.p,
                state_b.p,
                x_small), smoothStep(
                x,
                state_a.h,
                state_b.h,
                x_small)),
              T=temperature_ph(smoothStep(
                x,
                state_a.p,
                state_b.p,
                x_small), smoothStep(
                x,
                state_a.h,
                state_b.h,
                x_small)),
              phase=0);
        annotation (Inline=true);
      end setSmoothState;
      annotation (Documentation(info="<html>
<p>
This model calculates medium properties
for water in the <strong>liquid</strong>, <strong>gas</strong> and <strong>two phase</strong> regions
according to the IAPWS/IF97 standard, i.e., the accepted industrial standard
and best compromise between accuracy and computation time.
For more details see <a href=\"modelica://Modelica.Media.Water.IF97_Utilities\">
Modelica.Media.Water.IF97_Utilities</a>. Three variable pairs can be the
independent variables of the model:
</p>
<ol>
<li>Pressure <strong>p</strong> and specific enthalpy <strong>h</strong> are the most natural choice for general applications. This is the recommended choice for most general purpose applications, in particular for power plants.</li>
<li>Pressure <strong>p</strong> and temperature <strong>T</strong> are the most natural choice for applications where water is always in the same phase, both for liquid water and steam.</li>
<li>Density <strong>d</strong> and temperature <strong>T</strong> are explicit variables of the Helmholtz function in the near-critical region and can be the best choice for applications with super-critical or near-critical states.</li>
</ol>
<p>
The following quantities are always computed:
</p>
<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
  <tr><td><strong>Variable</strong></td>
      <td><strong>Unit</strong></td>
      <td><strong>Description</strong></td></tr>
  <tr><td>T</td>
      <td>K</td>
      <td>temperature</td></tr>
  <tr><td>u</td>
      <td>J/kg</td>
      <td>specific internal energy</td></tr>
  <tr><td>d</td>
      <td>kg/m^3</td>
      <td>density</td></tr>
  <tr><td>p</td>
      <td>Pa</td>
      <td>pressure</td></tr>
  <tr><td>h</td>
      <td>J/kg</td>
      <td>specific enthalpy</td></tr>
</table>
<p>
In some cases additional medium properties are needed.
A component that needs these optional properties has to call
one of the functions listed in
<a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.OptionalProperties\">
Modelica.Media.UsersGuide.MediumUsage.OptionalProperties</a> and in
<a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.TwoPhase\">
Modelica.Media.UsersGuide.MediumUsage.TwoPhase</a>.
</p>
<p>Many further properties can be computed. Using the well-known Bridgman's Tables, all first partial derivatives of the standard thermodynamic variables can be computed easily.
</p>
</html>"));
    end WaterIF97_base;

      package IF97_Utilities
      "Low level and utility computation for high accuracy water properties according to the IAPWS/IF97 standard"
        extends Modelica.Icons.UtilitiesPackage;

        package BaseIF97
        "Modelica Physical Property Model: the new industrial formulation IAPWS-IF97"
          extends Modelica.Icons.Package;

          record IterationData "Constants for iterations internal to some functions"

            extends Modelica.Icons.Record;
            constant Integer IMAX=50
              "Maximum number of iterations for inverse functions";
            constant Real DELP=1.0e-6 "Maximum iteration error in pressure, Pa";
            constant Real DELS=1.0e-8
              "Maximum iteration error in specific entropy, J/{kg.K}";
            constant Real DELH=1.0e-8
              "Maximum iteration error in specific enthalpy, J/kg";
            constant Real DELD=1.0e-8 "Maximum iteration error in density, kg/m^3";
          end IterationData;

          record data "Constant IF97 data and region limits"
            extends Modelica.Icons.Record;
            constant SI.SpecificHeatCapacity RH2O=461.526
              "Specific gas constant of water vapour";
            constant SI.MolarMass MH2O=0.01801528 "Molar weight of water";
            constant SI.Temperature TSTAR1=1386.0
              "Normalization temperature for region 1 IF97";
            constant SI.Pressure PSTAR1=16.53e6
              "Normalization pressure for region 1 IF97";
            constant SI.Temperature TSTAR2=540.0
              "Normalization temperature for region 2 IF97";
            constant SI.Pressure PSTAR2=1.0e6
              "Normalization pressure for region 2 IF97";
            constant SI.Temperature TSTAR5=1000.0
              "Normalization temperature for region 5 IF97";
            constant SI.Pressure PSTAR5=1.0e6
              "Normalization pressure for region 5 IF97";
            constant SI.SpecificEnthalpy HSTAR1=2.5e6
              "Normalization specific enthalpy for region 1 IF97";
            constant Real IPSTAR=1.0e-6
              "Normalization pressure for inverse function in region 2 IF97";
            constant Real IHSTAR=5.0e-7
              "Normalization specific enthalpy for inverse function in region 2 IF97";
            constant SI.Temperature TLIMIT1=623.15
              "Temperature limit between regions 1 and 3";
            constant SI.Temperature TLIMIT2=1073.15
              "Temperature limit between regions 2 and 5";
            constant SI.Temperature TLIMIT5=2273.15 "Upper temperature limit of 5";
            constant SI.Pressure PLIMIT1=100.0e6
              "Upper pressure limit for regions 1, 2 and 3";
            constant SI.Pressure PLIMIT4A=16.5292e6
              "Pressure limit between regions 1 and 2, important for two-phase (region 4)";
            constant SI.Pressure PLIMIT5=10.0e6
              "Upper limit of valid pressure in region 5";
            constant SI.Pressure PCRIT=22064000.0 "The critical pressure";
            constant SI.Temperature TCRIT=647.096 "The critical temperature";
            constant SI.Density DCRIT=322.0 "The critical density";
            constant SI.SpecificEntropy SCRIT=4412.02148223476
              "The calculated specific entropy at the critical point";
            constant SI.SpecificEnthalpy HCRIT=2087546.84511715
              "The calculated specific enthalpy at the critical point";
            constant Real[5] n=array(
                    0.34805185628969e3,
                    -0.11671859879975e1,
                    0.10192970039326e-2,
                    0.57254459862746e3,
                    0.13918839778870e2)
              "Polynomial coefficients for boundary between regions 2 and 3";
            annotation (Documentation(info="<html>
 <h4>Record description</h4>
                           <p>Constants needed in the international steam properties IF97.
                           SCRIT and HCRIT are calculated from Helmholtz function for region 3.</p>
<h4>Version Info and Revision history
</h4>
<ul>
<li>First implemented: <em>July, 2000</em>
       by Hubertus Tummescheit
       </li>
</ul>
 <address>Author: Hubertus Tummescheit,<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
<ul>
 <li>Initial version: July 2000</li>
 <li>Documentation added: December 2002</li>
</ul>
</html>"));
          end data;

          record triple "Triple point data"
            extends Modelica.Icons.Record;
            constant SI.Temperature Ttriple=273.16 "The triple point temperature";
            constant SI.Pressure ptriple=611.657 "The triple point pressure";
            constant SI.Density dltriple=999.792520031617642
              "The triple point liquid density";
            constant SI.Density dvtriple=0.485457572477861372e-2
              "The triple point vapour density";
            annotation (Documentation(info="<html>
 <h4>Record description</h4>
 <p>Vapour/liquid/ice triple point data for IF97 steam properties.</p>
<h4>Version Info and Revision history
</h4>
<ul>
<li>First implemented: <em>July, 2000</em>
       by Hubertus Tummescheit
       </li>
</ul>
 <address>Author: Hubertus Tummescheit,<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
<ul>
 <li>Initial version: July 2000</li>
 <li>Documentation added: December 2002</li>
</ul>
</html>"));
          end triple;

          package Regions
          "Functions to find the current region for given pairs of input variables"
            extends Modelica.Icons.FunctionsPackage;

            function boundary23ofT
              "Boundary function for region boundary between regions 2 and 3 (input temperature)"

              extends Modelica.Icons.Function;
              input SI.Temperature t "Temperature (K)";
              output SI.Pressure p "Pressure";
          protected
              constant Real[5] n=data.n;
            algorithm
              p := 1.0e6*(n[1] + t*(n[2] + t*n[3]));
            end boundary23ofT;

            function boundary23ofp
              "Boundary function for region boundary between regions 2 and 3 (input pressure)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.Temperature t "Temperature (K)";
          protected
              constant Real[5] n=data.n;
              Real pi "Dimensionless pressure";
            algorithm
              pi := p/1.0e6;
              assert(p > triple.ptriple,
                "IF97 medium function boundary23ofp called with too low pressure\n"
                 + "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              t := n[4] + ((pi - n[5])/n[3])^0.5;
            end boundary23ofp;

            function hlowerofp5
              "Explicit lower specific enthalpy limit of region 5 as function of pressure"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p/data.PSTAR5;
              assert(p > triple.ptriple,
                "IF97 medium function hlowerofp5 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              h := 461526.*(9.01505286876203 + pi*(-0.00979043490246092 + (-0.0000203245575263501
                 + 3.36540214679088e-7*pi)*pi));
            end hlowerofp5;

            function hupperofp5
              "Explicit upper specific enthalpy limit of region 5 as function of pressure"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p/data.PSTAR5;
              assert(p > triple.ptriple,
                "IF97 medium function hupperofp5 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              h := 461526.*(15.9838891400332 + pi*(-0.000489898813722568 + (-5.01510211858761e-8
                 + 7.5006972718273e-8*pi)*pi));
            end hupperofp5;

            function slowerofp5
              "Explicit lower specific entropy limit of region 5 as function of pressure"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p/data.PSTAR5;
              assert(p > triple.ptriple,
                "IF97 medium function slowerofp5 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              s := 461.526*(18.4296209980112 + pi*(-0.00730911805860036 + (-0.0000168348072093888
                 + 2.09066899426354e-7*pi)*pi) - Modelica.Math.log(pi));
            end slowerofp5;

            function supperofp5
              "Explicit upper specific entropy limit of region 5 as function of pressure"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              Real pi "Dimensionless pressure";
            algorithm
              pi := p/data.PSTAR5;
              assert(p > triple.ptriple,
                "IF97 medium function supperofp5 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              s := 461.526*(22.7281531474243 + pi*(-0.000656650220627603 + (-1.96109739782049e-8
                 + 2.19979537113031e-8*pi)*pi) - Modelica.Math.log(pi));
            end supperofp5;

            function hlowerofp1
              "Explicit lower specific enthalpy limit of region 1 as function of pressure"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real pi1 "Dimensionless pressure";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              pi1 := 7.1 - p/data.PSTAR1;
              assert(p > triple.ptriple,
                "IF97 medium function hlowerofp1 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              o[1] := pi1*pi1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];

              h := 639675.036*(0.173379420894777 + pi1*(-0.022914084306349 + pi1*(-0.00017146768241932
                 + pi1*(-4.18695814670391e-6 + pi1*(-2.41630417490008e-7 + pi1*(
                1.73545618580828e-11 + o[1]*pi1*(8.43755552264362e-14 + o[2]*o[3]*pi1
                *(5.35429206228374e-35 + o[1]*(-8.12140581014818e-38 + o[1]*o[2]*(-1.43870236842915e-44
                 + pi1*(1.73894459122923e-45 + (-7.06381628462585e-47 +
                9.64504638626269e-49*pi1)*pi1)))))))))));
            end hlowerofp1;

            function hupperofp1
              "Explicit upper specific enthalpy limit of region 1 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real pi1 "Dimensionless pressure";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              pi1 := 7.1 - p/data.PSTAR1;
              assert(p > triple.ptriple,
                "IF97 medium function hupperofp1 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              o[1] := pi1*pi1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              h := 639675.036*(2.42896927729349 + pi1*(-0.00141131225285294 + pi1*(
                0.00143759406818289 + pi1*(0.000125338925082983 + pi1*(
                0.0000123617764767172 + pi1*(3.17834967400818e-6 + o[1]*pi1*(
                1.46754947271665e-8 + o[2]*o[3]*pi1*(1.86779322717506e-17 + o[1]*(-4.18568363667416e-19
                 + o[1]*o[2]*(-9.19148577641497e-22 + pi1*(4.27026404402408e-22 + (-6.66749357417962e-23
                 + 3.49930466305574e-24*pi1)*pi1)))))))))));
            end hupperofp1;

            function supperofp1
              "Explicit upper specific entropy limit of region 1 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              Real pi1 "Dimensionless pressure";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              pi1 := 7.1 - p/data.PSTAR1;
              assert(p > triple.ptriple,
                "IF97 medium function supperofp1 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              o[1] := pi1*pi1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              s := 461.526*(7.28316418503422 + pi1*(0.070602197808399 + pi1*(
                0.0039229343647356 + pi1*(0.000313009170788845 + pi1*(
                0.0000303619398631619 + pi1*(7.46739440045781e-6 + o[1]*pi1*(
                3.40562176858676e-8 + o[2]*o[3]*pi1*(4.21886233340801e-17 + o[1]*(-9.44504571473549e-19
                 + o[1]*o[2]*(-2.06859611434475e-21 + pi1*(9.60758422254987e-22 + (-1.49967810652241e-22
                 + 7.86863124555783e-24*pi1)*pi1)))))))))));
            end supperofp1;

            function hlowerofp2
              "Explicit lower specific enthalpy limit of region 2 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real pi "Dimensionless pressure";
              Real q1 "Auxiliary variable";
              Real q2 "Auxiliary variable";
              Real[18] o "Vector of auxiliary variables";
            algorithm
              pi := p/data.PSTAR2;
              assert(p > triple.ptriple,
                "IF97 medium function hlowerofp2 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              q1 := 572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
              q2 := -0.5 + 540./q1;
              o[1] := q1*q1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              o[4] := pi*pi;
              o[5] := o[4]*o[4];
              o[6] := q2*q2;
              o[7] := o[6]*o[6];
              o[8] := o[6]*o[7];
              o[9] := o[5]*o[5];
              o[10] := o[7]*o[7];
              o[11] := o[9]*o[9];
              o[12] := o[10]*o[10];
              o[13] := o[12]*o[12];
              o[14] := o[7]*q2;
              o[15] := o[6]*q2;
              o[16] := o[10]*o[6];
              o[17] := o[13]*o[6];
              o[18] := o[13]*o[6]*q2;
              h := (4.63697573303507e9 + 3.74686560065793*o[2] + 3.57966647812489e-6*
                o[1]*o[2] + 2.81881548488163e-13*o[3] - 7.64652332452145e7*q1 -
                0.00450789338787835*o[2]*q1 - 1.55131504410292e-9*o[1]*o[2]*q1 + o[1]
                *(2.51383707870341e6 - 4.78198198764471e6*o[10]*o[11]*o[12]*o[13]*o[4]
                 + 49.9651389369988*o[11]*o[12]*o[13]*o[4]*o[5]*o[7] + o[15]*o[4]*(
                1.03746636552761e-13 - 0.00349547959376899*o[16] -
                2.55074501962569e-7*o[8])*o[9] + (-242662.235426958*o[10]*o[12] -
                3.46022402653609*o[16])*o[4]*o[5]*pi + o[4]*(0.109336249381227 -
                2248.08924686956*o[14] - 354742.725841972*o[17] - 24.1331193696374*o[
                6])*pi - 3.09081828396912e-19*o[11]*o[12]*o[5]*o[7]*pi -
                1.24107527851371e-8*o[11]*o[13]*o[4]*o[5]*o[6]*o[7]*pi +
                3.99891272904219*o[5]*o[8]*pi + 0.0641817365250892*o[10]*o[7]*o[9]*pi
                 + pi*(-4444.87643334512 - 75253.6156722047*o[14] - 43051.9020511789*
                o[6] - 22926.6247146068*q2) + o[4]*(-8.23252840892034 -
                3927.0508365636*o[15] - 239.325789467604*o[18] - 76407.3727417716*o[8]
                 - 94.4508644545118*q2) + 0.360567666582363*o[5]*(-0.0161221195808321
                 + q2)*(0.0338039844460968 + q2) + o[11]*(-0.000584580992538624*o[10]
                *o[12]*o[7] + 1.33248030241755e6*o[12]*o[13]*q2) + o[9]*(-7.38502736990986e7
                *o[18] + 0.0000224425477627799*o[6]*o[7]*q2) + o[4]*o[5]*(-2.08438767026518e8
                *o[17] - 0.0000124971648677697*o[6] - 8442.30378348203*o[10]*o[6]*o[7]
                *q2) + o[11]*o[9]*(4.73594929247646e-22*o[10]*o[12]*q2 -
                13.6411358215175*o[10]*o[12]*o[13]*q2 + 5.52427169406836e-10*o[13]*o[
                6]*o[7]*q2) + o[11]*o[5]*(2.67174673301715e-6*o[17] +
                4.44545133805865e-18*o[12]*o[6]*q2 - 50.2465185106411*o[10]*o[13]*o[6]
                *o[7]*q2)))/o[1];
            end hlowerofp2;

            function hupperofp2
              "Explicit upper specific enthalpy limit of region 2 as function of pressure"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real pi "Dimensionless pressure";
              Real[2] o "Vector of auxiliary variables";
            algorithm
              pi := p/data.PSTAR2;
              assert(p > triple.ptriple,
                "IF97 medium function hupperofp2 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              o[1] := pi*pi;
              o[2] := o[1]*o[1]*o[1];
              h := 4.16066337647071e6 + pi*(-4518.48617188327 + pi*(-8.53409968320258
                 + pi*(0.109090430596056 + pi*(-0.000172486052272327 + pi*(
                4.2261295097284e-15 + pi*(-1.27295130636232e-10 + pi*(-3.79407294691742e-25
                 + pi*(7.56960433802525e-23 + pi*(7.16825117265975e-32 + pi*(
                3.37267475986401e-21 + (-7.5656940729795e-74 + o[1]*(-8.00969737237617e-134
                 + (1.6746290980312e-65 + pi*(-3.71600586812966e-69 + pi*(
                8.06630589170884e-129 + (-1.76117969553159e-103 +
                1.88543121025106e-84*pi)*pi)))*o[1]))*o[2]))))))))));
            end hupperofp2;

            function slowerofp2
              "Explicit lower specific entropy limit of region 2 as function of pressure (meets region 4 saturation pressure curve at 623.15 K)"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              Real pi "Dimensionless pressure";
              Real q1 "Auxiliary variable";
              Real q2 "Auxiliary variable";
              Real[40] o "Vector of auxiliary variables";
            algorithm
              pi := p/data.PSTAR2;
              assert(p > triple.ptriple,
                "IF97 medium function slowerofp2 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              q1 := 572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
              q2 := -0.5 + 540.0/q1;
              o[1] := pi*pi;
              o[2] := o[1]*pi;
              o[3] := o[1]*o[1];
              o[4] := o[1]*o[3]*pi;
              o[5] := q1*q1;
              o[6] := o[5]*q1;
              o[7] := 1/o[5];
              o[8] := 1/q1;
              o[9] := o[5]*o[5];
              o[10] := o[9]*q1;
              o[11] := q2*q2;
              o[12] := o[11]*q2;
              o[13] := o[1]*o[3];
              o[14] := o[11]*o[11];
              o[15] := o[3]*o[3];
              o[16] := o[1]*o[15];
              o[17] := o[11]*o[14];
              o[18] := o[11]*o[14]*q2;
              o[19] := o[3]*pi;
              o[20] := o[14]*o[14];
              o[21] := o[11]*o[20];
              o[22] := o[15]*pi;
              o[23] := o[14]*o[20]*q2;
              o[24] := o[20]*o[20];
              o[25] := o[15]*o[15];
              o[26] := o[25]*o[3];
              o[27] := o[14]*o[24];
              o[28] := o[25]*o[3]*pi;
              o[29] := o[20]*o[24]*q2;
              o[30] := o[15]*o[25];
              o[31] := o[24]*o[24];
              o[32] := o[11]*o[31]*q2;
              o[33] := o[14]*o[31];
              o[34] := o[1]*o[25]*o[3]*pi;
              o[35] := o[11]*o[14]*o[31]*q2;
              o[36] := o[1]*o[25]*o[3];
              o[37] := o[1]*o[25];
              o[38] := o[20]*o[24]*o[31]*q2;
              o[39] := o[14]*q2;
              o[40] := o[11]*o[31];

              s := 461.526*(9.692768600217 + 1.22151969114703e-16*o[10] +
                0.00018948987516315*o[1]*o[11] + 1.6714766451061e-11*o[12]*o[13] +
                0.0039392777243355*o[1]*o[14] - 1.0406965210174e-19*o[14]*o[16] +
                0.043797295650573*o[1]*o[18] - 2.2922076337661e-6*o[18]*o[19] -
                2.0481737692309e-8*o[2] + 0.00003227767723857*o[12]*o[2] +
                0.0015033924542148*o[17]*o[2] - 1.1256211360459e-11*o[15]*o[20] +
                1.0018179379511e-9*o[11]*o[14]*o[16]*o[20] + 1.0234747095929e-13*o[16]
                *o[21] - 1.9809712802088e-8*o[22]*o[23] + 0.0021171472321355*o[13]*o[
                24] - 8.9185845355421e-25*o[26]*o[27] - 1.2790717852285e-8*o[11]*o[3]
                 - 4.8225372718507e-7*o[12]*o[3] - 7.3087610595061e-29*o[11]*o[20]*o[
                24]*o[30] - 0.10693031879409*o[11]*o[24]*o[25]*o[31] +
                4.2002467698208e-6*o[24]*o[26]*o[31] - 5.5414715350778e-17*o[20]*o[30]
                *o[31] + 9.436970724121e-7*o[11]*o[20]*o[24]*o[30]*o[31] +
                23.895741934104*o[13]*o[32] + 0.040668253562649*o[2]*o[32] -
                3.0629316876232e-13*o[26]*o[32] + 0.000026674547914087*o[1]*o[33] +
                8.2311340897998*o[15]*o[33] + 1.2768608934681e-15*o[34]*o[35] +
                0.33662250574171*o[37]*o[38] + 5.905956432427e-18*o[4] +
                0.038946842435739*o[29]*o[4] - 4.88368302964335e-6*o[5] -
                3.34901734177133e6/o[6] + 2.58538448402683e-9*o[6] + 82839.5726841115
                *o[7] - 5446.7940672972*o[8] - 8.40318337484194e-13*o[9] +
                0.0017731742473213*pi + 0.045996013696365*o[11]*pi +
                0.057581259083432*o[12]*pi + 0.05032527872793*o[17]*pi + o[8]*pi*(
                9.63082563787332 - 0.008917431146179*q1) + 0.00811842799898148*q1 +
                0.000033032641670203*o[1]*q2 - 4.3870667284435e-7*o[2]*q2 +
                8.0882908646985e-11*o[14]*o[20]*o[24]*o[25]*q2 + 5.9056029685639e-26*
                o[14]*o[24]*o[28]*q2 + 7.8847309559367e-10*o[3]*q2 -
                3.7826947613457e-6*o[14]*o[24]*o[31]*o[36]*q2 + 1.2621808899101e-6*o[
                11]*o[20]*o[4]*q2 + 540.*o[8]*(10.08665568018 - 0.000033032641670203*
                o[1] - 6.2245802776607e-15*o[10] - 0.015757110897342*o[1]*o[12] -
                5.0144299353183e-11*o[11]*o[13] + 4.1627860840696e-19*o[12]*o[16] -
                0.306581069554011*o[1]*o[17] + 9.0049690883672e-11*o[15]*o[18] +
                0.0000160454534363627*o[17]*o[19] + 4.3870667284435e-7*o[2] -
                0.00009683303171571*o[11]*o[2] + 2.57526266427144e-7*o[14]*o[20]*o[22]
                 - 1.40254511313154e-8*o[16]*o[23] - 2.34560435076256e-9*o[14]*o[20]*
                o[24]*o[25] - 1.24017662339842e-24*o[27]*o[28] - 7.8847309559367e-10*
                o[3] + 1.44676118155521e-6*o[11]*o[3] + 1.90027787547159e-27*o[29]*o[
                30] - 0.000960283724907132*o[1]*o[32] - 296.320827232793*o[15]*o[32]
                 - 4.97975748452559e-14*o[11]*o[14]*o[31]*o[34] +
                2.21658861403112e-15*o[30]*o[35] + 0.000200482822351322*o[14]*o[24]*o[
                31]*o[36] - 19.1874828272775*o[20]*o[24]*o[31]*o[37] -
                0.0000547344301999018*o[30]*o[38] - 0.0090203547252888*o[2]*o[39] -
                0.0000138839897890111*o[21]*o[4] - 0.973671060893475*o[20]*o[24]*o[4]
                 - 836.35096769364*o[13]*o[40] - 1.42338887469272*o[2]*o[40] +
                1.07202609066812e-11*o[26]*o[40] + 0.0000150341259240398*o[5] -
                1.8087714924605e-8*o[6] + 18605.6518987296*o[7] - 306.813232163376*o[
                8] + 1.43632471334824e-11*o[9] + 1.13103675106207e-18*o[5]*o[9] -
                0.017834862292358*pi - 0.172743777250296*o[11]*pi - 0.30195167236758*
                o[39]*pi + o[8]*pi*(-49.6756947920742 + 0.045996013696365*q1) -
                0.0003789797503263*o[1]*q2 - 0.033874355714168*o[11]*o[13]*o[14]*o[20]
                *q2 - 1.0234747095929e-12*o[16]*o[20]*q2 + 1.78371690710842e-23*o[11]
                *o[24]*o[26]*q2 + 2.558143570457e-8*o[3]*q2 + 5.3465159397045*o[24]*o[
                25]*o[31]*q2 - 0.000201611844951398*o[11]*o[14]*o[20]*o[26]*o[31]*q2)
                 - Modelica.Math.log(pi));
            end slowerofp2;

            function supperofp2
              "Explicit upper specific entropy limit of region 2 as function of pressure"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              Real pi "Dimensionless pressure";
              Real[2] o "Vector of auxiliary variables";
            algorithm
              pi := p/data.PSTAR2;
              assert(p > triple.ptriple,
                "IF97 medium function supperofp2 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              o[1] := pi*pi;
              o[2] := o[1]*o[1]*o[1];
              s := 8505.73409708683 - 461.526*Modelica.Math.log(pi) + pi*(-3.36563543302584
                 + pi*(-0.00790283552165338 + pi*(0.0000915558349202221 + pi*(-1.59634706513e-7
                 + pi*(3.93449217595397e-18 + pi*(-1.18367426347994e-13 + pi*(
                2.72575244843195e-15 + pi*(7.04803892603536e-26 + pi*(
                6.67637687381772e-35 + pi*(3.1377970315132e-24 + (-7.04844558482265e-77
                 + o[1]*(-7.46289531275314e-137 + (1.55998511254305e-68 + pi*(-3.46166288915497e-72
                 + pi*(7.51557618628583e-132 + (-1.64086406733212e-106 +
                1.75648443097063e-87*pi)*pi)))*o[1]))*o[2]*o[2]))))))))));
            end supperofp2;

            function d1n "Density in region 1 as function of p and T"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.Density d "Density";
          protected
              Real pi "Dimensionless pressure";
              Real pi1 "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau1 "Dimensionless temperature";
              Real gpi "Dimensionless Gibbs-derivative w.r.t. pi";
              Real[11] o "Auxiliary variables";
            algorithm
              pi := p/data.PSTAR1;
              tau := data.TSTAR1/T;
              pi1 := 7.1 - pi;
              tau1 := tau - 1.222;
              o[1] := tau1*tau1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              o[4] := o[1]*o[2];
              o[5] := o[1]*tau1;
              o[6] := o[2]*tau1;
              o[7] := pi1*pi1;
              o[8] := o[7]*o[7];
              o[9] := o[8]*o[8];
              o[10] := o[3]*o[3];
              o[11] := o[10]*o[10];
              gpi := pi1*(pi1*((0.000095038934535162 + o[2]*(8.4812393955936e-6 +
                2.55615384360309e-9*o[4]))/o[2] + pi1*((8.9701127632e-6 + (
                2.60684891582404e-6 + 5.7366919751696e-13*o[2]*o[3])*o[5])/o[6] + pi1
                *(2.02584984300585e-6/o[3] + o[7]*pi1*(o[8]*o[9]*pi1*(o[7]*(o[7]*o[8]
                *(-7.63737668221055e-22/(o[1]*o[11]*o[2]) + pi1*(pi1*(-5.65070932023524e-23
                /(o[11]*o[3]) + (2.99318679335866e-24*pi1)/(o[11]*o[3]*tau1)) +
                3.5842867920213e-22/(o[1]*o[11]*o[2]*tau1))) - 3.33001080055983e-19/(
                o[1]*o[10]*o[2]*o[3]*tau1)) + 1.44400475720615e-17/(o[10]*o[2]*o[3]*
                tau1)) + (1.01874413933128e-8 + 1.39398969845072e-9*o[6])/(o[1]*o[3]*
                tau1))))) + (0.00094368642146534 + o[5]*(0.00060003561586052 + (-0.000095322787813974
                 + o[1]*(8.8283690661692e-6 + 1.45389992595188e-15*o[1]*o[2]*o[3]))*
                tau1))/o[5]) + (-0.00028319080123804 + o[1]*(0.00060706301565874 + o[
                4]*(0.018990068218419 + tau1*(0.032529748770505 + (0.021841717175414
                 + 0.00005283835796993*o[1])*tau1))))/(o[3]*tau1);
              d := p/(data.RH2O*T*pi*gpi);
            end d1n;

            function d2n "Density in region 2 as function of p and T"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.Density d "Density";
          protected
              Real pi "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau2 "Dimensionless temperature";
              Real gpi "Dimensionless Gibbs-derivative w.r.t. pi";
              Real[12] o "Auxiliary variables";
            algorithm
              pi := p/data.PSTAR2;
              tau := data.TSTAR2/T;
              tau2 := tau - 0.5;
              o[1] := tau2*tau2;
              o[2] := o[1]*tau2;
              o[3] := o[1]*o[1];
              o[4] := o[3]*o[3];
              o[5] := o[4]*o[4];
              o[6] := o[3]*o[4]*o[5]*tau2;
              o[7] := o[3]*o[4]*tau2;
              o[8] := o[1]*o[3]*o[4];
              o[9] := pi*pi;
              o[10] := o[9]*o[9];
              o[11] := o[3]*o[5]*tau2;
              o[12] := o[5]*o[5];
              gpi := (1. + pi*(-0.0017731742473213 + tau2*(-0.017834862292358 + tau2*
                (-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[2])*
                tau2)) + pi*(tau2*(-0.000066065283340406 + (-0.0003789797503263 + o[1]
                *(-0.007878555448671 + o[2]*(-0.087594591301146 -
                0.000053349095828174*o[6])))*tau2) + pi*(6.1445213076927e-8 + (
                1.31612001853305e-6 + o[1]*(-0.00009683303171571 + o[2]*(-0.0045101773626444
                 - 0.122004760687947*o[6])))*tau2 + pi*(tau2*(-3.15389238237468e-9 +
                (5.116287140914e-8 + 1.92901490874028e-6*tau2)*tau2) + pi*(
                0.0000114610381688305*o[1]*o[3]*tau2 + pi*(o[2]*(-1.00288598706366e-10
                 + o[7]*(-0.012702883392813 - 143.374451604624*o[1]*o[5]*tau2)) + pi*
                (-4.1341695026989e-17 + o[1]*o[4]*(-8.8352662293707e-6 -
                0.272627897050173*o[8])*tau2 + pi*(o[4]*(9.0049690883672e-11 -
                65.8490727183984*o[3]*o[4]*o[5]) + pi*(1.78287415218792e-7*o[7] + pi*
                (o[3]*(1.0406965210174e-18 + o[1]*(-1.0234747095929e-12 -
                1.0018179379511e-8*o[3])*o[3]) + o[10]*o[9]*((-1.29412653835176e-9 +
                1.71088510070544*o[11])*o[6] + o[9]*(-6.05920510335078*o[12]*o[4]*o[5]
                *tau2 + o[9]*(o[3]*o[5]*(1.78371690710842e-23 + o[1]*o[3]*o[4]*(
                6.1258633752464e-12 - 0.000084004935396416*o[7])*tau2) + pi*(-1.24017662339842e-24
                *o[11] + pi*(0.0000832192847496054*o[12]*o[3]*o[5]*tau2 + pi*(o[1]*o[
                4]*o[5]*(1.75410265428146e-27 + (1.32995316841867e-15 -
                0.0000226487297378904*o[1]*o[5])*o[8])*pi - 2.93678005497663e-14*o[1]
                *o[12]*o[3]*tau2)))))))))))))))))/pi;
              d := p/(data.RH2O*T*pi*gpi);
            end d2n;

            function hl_p_R4b
              "Explicit approximation of liquid specific enthalpy on the boundary between regions 4 and 3"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real x "Auxiliary variable";
            algorithm
              // documentation of accuracy in notebook ~hubertus/props/IAPWS/R3Approx.nb
              // boundary between region IVa and III
              x := Modelica.Math.acos(p/data.PCRIT);
              h := (1 + x*(-0.4945586958175176 + x*(1.346800016564904 + x*(-3.889388153209752
                 + x*(6.679385472887931 + x*(-6.75820241066552 + x*(3.558919744656498
                 + (-0.7179818554978939 - 0.0001152032945617821*x)*x)))))))*data.HCRIT;
            end hl_p_R4b;

            function hv_p_R4b
              "Explicit approximation of vapour specific enthalpy on the boundary between regions 4 and 3"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real x "Auxiliary variable";
            algorithm
              // boundary between region IVa and III
              x := Modelica.Math.acos(p/data.PCRIT);
              h := (1 + x*(0.4880153718655694 + x*(0.2079670746250689 + x*(-6.084122698421623
                 + x*(25.08887602293532 + x*(-48.38215180269516 + x*(
                45.66489164833212 + (-16.98555442961553 + 0.0006616936460057691*x)*x)))))))
                *data.HCRIT;
            end hv_p_R4b;

            function sl_p_R4b
              "Explicit approximation of liquid specific entropy on the boundary between regions 4 and 3"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              Real x "Auxiliary variable";
            algorithm
              // boundary between region IVa and III
              x := Modelica.Math.acos(p/data.PCRIT);
              s := (1 + x*(-0.36160692245648063 + x*(0.9962778630486647 + x*(-2.8595548144171103
                 + x*(4.906301159555333 + x*(-4.974092309614206 + x*(
                2.6249651699204457 + (-0.5319954375299023 - 0.00008064497431880644*x)
                *x)))))))*data.SCRIT;
            end sl_p_R4b;

            function sv_p_R4b
              "Explicit approximation of vapour specific entropy on the boundary between regions 4 and 3"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEntropy s;
          protected
              Real x "Auxiliary variable";
            algorithm

              // documentation of accuracy in notebook ~hubertus/props/IAPWS/R3Approx.nb
              // boundary between region IVa and III
              x := Modelica.Math.acos(p/data.PCRIT);
              s := (1 + x*(0.35682641826674344 + x*(0.1642457027815487 + x*(-4.425350377422446
                 + x*(18.324477859983133 + x*(-35.338631625948665 + x*(
                33.36181025816282 + (-12.408711490585757 + 0.0004810049834109226*x)*x)))))))
                *data.SCRIT;
            end sv_p_R4b;

            function rhol_p_R4b
              "Explicit approximation of liquid density on the boundary between regions 4 and 3"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.Density dl "Liquid density";
          protected
              Real x "Auxiliary variable";
            algorithm
              if (p < data.PCRIT) then
                x := Modelica.Math.acos(p/data.PCRIT);
                dl := (1 + x*(1.903224079094824 + x*(-2.5314861802401123 + x*(-8.191449323843552
                   + x*(94.34196116778385 + x*(-369.3676833623383 + x*(
                  796.6627910598293 + x*(-994.5385383600702 + x*(673.2581177021598 +
                  (-191.43077336405156 + 0.00052536560808895*x)*x)))))))))*data.DCRIT;
              else
                dl := data.DCRIT;
              end if;
            end rhol_p_R4b;

            function rhov_p_R4b
              "Explicit approximation of vapour density on the boundary between regions 4 and 2"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.Density dv "Vapour density";
          protected
              Real x "Auxiliary variable";
            algorithm
              if (p < data.PCRIT) then
                x := Modelica.Math.acos(p/data.PCRIT);
                dv := (1 + x*(-1.8463850803362596 + x*(-1.1447872718878493 + x*(
                  59.18702203076563 + x*(-403.5391431811611 + x*(1437.2007245332388
                   + x*(-3015.853540307519 + x*(3740.5790348670057 + x*(-2537.375817253895
                   + (725.8761975803782 - 0.0011151111658332337*x)*x)))))))))*data.DCRIT;
              else
                dv := data.DCRIT;
              end if;
            end rhov_p_R4b;

            function boilingcurve_p "Properties on the boiling curve"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output Common.IF97PhaseBoundaryProperties bpro "Property record";
          protected
              Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives";
              Common.HelmholtzDerivs f
                "Dimensionless Helmholtz function and derivatives";
              SI.Pressure plim=min(p, data.PCRIT - 1e-7)
                "Pressure limited to critical pressure - epsilon";
            algorithm
              bpro.R_s := data.RH2O;
              bpro.T := Basic.tsat(plim);
              bpro.dpT := Basic.dptofT(bpro.T);
              bpro.region3boundary := bpro.T > data.TLIMIT1;
              if not bpro.region3boundary then
                g := Basic.g1(p, bpro.T);
                bpro.d := p/(bpro.R_s*bpro.T*g.pi*g.gpi);
                bpro.h := if p > plim then data.HCRIT else bpro.R_s*bpro.T*g.tau*g.gtau;
                bpro.s := g.R_s*(g.tau*g.gtau - g.g);
                bpro.cp := -bpro.R_s*g.tau*g.tau*g.gtautau;
                bpro.vt := bpro.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
                bpro.vp := bpro.R_s*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
                bpro.pt := -p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
                bpro.pd := -bpro.R_s*bpro.T*g.gpi*g.gpi/(g.gpipi);
              else
                bpro.d := rhol_p_R4b(plim);
                f := Basic.f3(bpro.d, bpro.T);
                bpro.h := hl_p_R4b(plim);
                // bpro.R_s*bpro.T*(f.tau*f.ftau + f.delta*f.fdelta);
                bpro.s := f.R_s*(f.tau*f.ftau - f.f);
                bpro.cv := bpro.R_s*(-f.tau*f.tau*f.ftautau);
                bpro.pt := bpro.R_s*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
                bpro.pd := bpro.R_s*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              end if;
            end boilingcurve_p;

            function dewcurve_p "Properties on the dew curve"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output Common.IF97PhaseBoundaryProperties bpro "Property record";
          protected
              Common.GibbsDerivs g "Dimensionless Gibbs function and derivatives";
              Common.HelmholtzDerivs f
                "Dimensionless Helmholtz function and derivatives";
              SI.Pressure plim=min(p, data.PCRIT - 1e-7)
                "Pressure limited to critical pressure - epsilon";
            algorithm
              bpro.R_s := data.RH2O;
              bpro.T := Basic.tsat(plim);
              bpro.dpT := Basic.dptofT(bpro.T);
              bpro.region3boundary := bpro.T > data.TLIMIT1;
              if not bpro.region3boundary then
                g := Basic.g2(p, bpro.T);
                bpro.d := p/(bpro.R_s*bpro.T*g.pi*g.gpi);
                bpro.h := if p > plim then data.HCRIT else bpro.R_s*bpro.T*g.tau*g.gtau;
                bpro.s := g.R_s*(g.tau*g.gtau - g.g);
                bpro.cp := -bpro.R_s*g.tau*g.tau*g.gtautau;
                bpro.vt := bpro.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
                bpro.vp := bpro.R_s*bpro.T/(p*p)*g.pi*g.pi*g.gpipi;
                bpro.pt := -p/bpro.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
                bpro.pd := -bpro.R_s*bpro.T*g.gpi*g.gpi/(g.gpipi);
              else
                bpro.d := rhov_p_R4b(plim);
                f := Basic.f3(bpro.d, bpro.T);
                bpro.h := hv_p_R4b(plim);
                // bpro.R_s*bpro.T*(f.tau*f.ftau + f.delta*f.fdelta);
                bpro.s := f.R_s*(f.tau*f.ftau - f.f);
                bpro.cv := bpro.R_s*(-f.tau*f.tau*f.ftautau);
                bpro.pt := bpro.R_s*bpro.d*f.delta*(f.fdelta - f.tau*f.fdeltatau);
                bpro.pd := bpro.R_s*bpro.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
              end if;
            end dewcurve_p;

            function hvl_p
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              h := bpro.h;
              annotation (
                derivative(noDerivative=bpro) = hvl_p_der,
                Inline=false,
                LateInline=true);
            end hvl_p;

            function hl_p
              "Liquid specific enthalpy on the boundary between regions 4 and 3 or 1"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              h := hvl_p(p, boilingcurve_p(p));
              annotation (Inline=true);
            end hl_p;

            function hv_p
              "Vapour specific enthalpy on the boundary between regions 4 and 3 or 2"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              h := hvl_p(p, dewcurve_p(p));
              annotation (Inline=true);
            end hv_p;

            function hvl_p_der
              "Derivative function for the specific enthalpy along the phase boundary"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              input Real p_der "Derivative of pressure";
              output Real h_der
                "Time derivative of specific enthalpy along the phase boundary";
            algorithm
              if bpro.region3boundary then
                h_der := ((bpro.d*bpro.pd - bpro.T*bpro.pt)*p_der + (bpro.T*bpro.pt*
                  bpro.pt + bpro.d*bpro.d*bpro.pd*bpro.cv)/bpro.dpT*p_der)/(bpro.pd*
                  bpro.d*bpro.d);
              else
                h_der := (1/bpro.d - bpro.T*bpro.vt)*p_der + bpro.cp/bpro.dpT*p_der;
              end if;
              annotation (Inline=true);
            end hvl_p_der;

            function rhovl_p
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output SI.Density rho "Density";
            algorithm
              rho := bpro.d;
              annotation (
                derivative(noDerivative=bpro) = rhovl_p_der,
                Inline=false,
                LateInline=true);
            end rhovl_p;

            function rhol_p "Density of saturated water"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Saturation pressure";
              output SI.Density rho "Density of steam at the condensation point";
            algorithm
              rho := rhovl_p(p, boilingcurve_p(p));
              annotation (Inline=true);
            end rhol_p;

            function rhov_p "Density of saturated vapour"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Saturation pressure";
              output SI.Density rho "Density of steam at the condensation point";
            algorithm
              rho := rhovl_p(p, dewcurve_p(p));
              annotation (Inline=true);
            end rhov_p;

            function rhovl_p_der
              extends Modelica.Icons.Function;
              input SI.Pressure p "Saturation pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              input Real p_der "Derivative of pressure";
              output Real d_der "Time derivative of density along the phase boundary";
            algorithm
              d_der := if bpro.region3boundary then (p_der - bpro.pt*p_der/bpro.dpT)/
                bpro.pd else -bpro.d*bpro.d*(bpro.vp + bpro.vt/bpro.dpT)*p_der;
              annotation (Inline=true);
            end rhovl_p_der;

            function sl_p
              "Liquid specific entropy on the boundary between regions 4 and 3 or 1"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              SI.Temperature Tsat "Saturation temperature";
              SI.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              if (p < data.PLIMIT4A) then
                Tsat := Basic.tsat(p);
                (h,s) := Isentropic.handsofpT1(p, Tsat);
              elseif (p < data.PCRIT) then
                s := sl_p_R4b(p);
              else
                s := data.SCRIT;
              end if;
            end sl_p;

            function sv_p
              "Vapour specific entropy on the boundary between regions 4 and 3 or 2"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              SI.Temperature Tsat "Saturation temperature";
              SI.SpecificEnthalpy h "Specific enthalpy";
            algorithm
              if (p < data.PLIMIT4A) then
                Tsat := Basic.tsat(p);
                (h,s) := Isentropic.handsofpT2(p, Tsat);
              elseif (p < data.PCRIT) then
                s := sv_p_R4b(p);
              else
                s := data.SCRIT;
              end if;
            end sv_p;

            function rhol_T "Density of saturated water"
              extends Modelica.Icons.Function;
              input SI.Temperature T "Temperature";
              output SI.Density d "Density of water at the boiling point";
          protected
              SI.Pressure p "Saturation pressure";
            algorithm
              p := Basic.psat(T);
              if T < data.TLIMIT1 then
                d := d1n(p, T);
              elseif T < data.TCRIT then
                d := rhol_p_R4b(p);
              else
                d := data.DCRIT;
              end if;
            end rhol_T;

            function rhov_T "Density of saturated vapour"
              extends Modelica.Icons.Function;
              input SI.Temperature T "Temperature";
              output SI.Density d "Density of steam at the condensation point";
          protected
              SI.Pressure p "Saturation pressure";
            algorithm

              // assert(T <= data.TCRIT,"input temperature has to be below the critical temperature");
              p := Basic.psat(T);
              if T < data.TLIMIT1 then
                d := d2n(p, T);
              elseif T < data.TCRIT then
                d := rhov_p_R4b(p);
              else
                d := data.DCRIT;
              end if;
            end rhov_T;

            function region_ph
              "Return the current region (valid values: 1,2,3,4,5) in IF97 for given pressure and specific enthalpy"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              input Integer phase=0
                "Phase: 2 for two-phase, 1 for one phase, 0 if not known";
              input Integer mode=0
                "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "Region (valid values: 1,2,3,4,5) in IF97";
              // If mode is different from 0, no checking for the region is done and
              // the mode is assumed to be the correct region. This can be used to
              // implement e.g., water-only steam tables when mode == 1
          protected
              Boolean hsubcrit;
              SI.Temperature Ttest;
              constant Real[5] n=data.n;
              SI.SpecificEnthalpy hl "Bubble enthalpy";
              SI.SpecificEnthalpy hv "Dew enthalpy";
            algorithm
              if (mode <> 0) then
                region := mode;
              else
                // check for regions 1, 2, 3 and 4
                hl := hl_p(p);
                hv := hv_p(p);
                if (phase == 2) then
                  region := 4;
                else
                  // phase == 1 or 0, now check if we are in the legal area
                  if (p < triple.ptriple) or (p > data.PLIMIT1) or (h < hlowerofp1(p))
                       or ((p < 10.0e6) and (h > hupperofp5(p))) or ((p >= 10.0e6)
                       and (h > hupperofp2(p))) then
                    // outside of valid range
                    region := -1;
                  else
                    //region 5 and -1 check complete
                    hsubcrit := (h < data.HCRIT);
                    // simple precheck: very simple if pressure < PLIMIT4A
                    if (p < data.PLIMIT4A) then
                      // we can never be in region 3, so test for others
                      if hsubcrit then
                        if (phase == 1) then
                          region := 1;
                        else
                          if (h < Isentropic.hofpT1(p, Basic.tsat(p))) then
                            region := 1;
                          else
                            region := 4;
                          end if;
                        end if;
                        // external or internal phase check
                      else
                        if (h > hlowerofp5(p)) then
                          // check for region 5
                          if ((p < data.PLIMIT5) and (h < hupperofp5(p))) then
                            region := 5;
                          else
                            region := -2;
                            // pressure and specific enthalpy too high, but this should
                          end if;
                          // never happen
                        else
                          if (phase == 1) then
                            region := 2;
                          else
                            if (h > Isentropic.hofpT2(p, Basic.tsat(p))) then
                              region := 2;
                            else
                              region := 4;
                            end if;
                          end if;
                          // external or internal phase check
                        end if;
                        // tests for region 2 or 5
                      end if;
                      // tests for sub or supercritical
                    else
                      // the pressure is over data.PLIMIT4A
                      if hsubcrit then
                        // region 1 or 3 or 4
                        if h < hupperofp1(p) then
                          region := 1;
                        else
                          if h < hl or p > data.PCRIT then
                            region := 3;
                          else
                            region := 4;
                          end if;
                        end if;
                        // end of test for region 1, 3 or 4
                      else
                        // region 2, 3 or 4
                        if (h > hlowerofp2(p)) then
                          region := 2;
                        else
                          if h > hv or p > data.PCRIT then
                            region := 3;
                          else
                            region := 4;
                          end if;
                        end if;
                        // test for 2 and 3
                      end if;
                      // tests above PLIMIT4A
                    end if;
                    // above or below PLIMIT4A
                  end if;
                  // check for grand limits of p and h
                end if;
                // all tests with phase == 1
              end if;
              // mode was == 0
              // assert(region > 0,"IF97 function called outside the valid range!");
            end region_ph;

            function region_ps
              "Return the current region (valid values: 1,2,3,4,5) in IF97 for given pressure and specific entropy"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              input Integer phase=0
                "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
              input Integer mode=0
                "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "Region (valid values: 1,2,3,4,5) in IF97";
              //  If mode is different from 0, no checking for the region is done and
              //    the mode is assumed to be the correct region. This can be used to
              //    implement e.g., water-only steam tables when mode == 1
          protected
              Boolean ssubcrit;
              SI.Temperature Ttest;
              constant Real[5] n=data.n;
              SI.SpecificEntropy sl "Bubble entropy";
              SI.SpecificEntropy sv "Dew entropy";
            algorithm
              if (mode <> 0) then
                region := mode;
              else
                // check for regions 1, 2, 3, and 4
                sl := sl_p(p);
                sv := sv_p(p);
                // check all cases two-phase
                if (phase == 2) or (phase == 0 and s > sl and s < sv and p < data.PCRIT) then
                  region := 4;
                else
                  // phase == 1
                  region := 0;
                  if (p < triple.ptriple) then
                    region := -2;
                  end if;
                  if (p > data.PLIMIT1) then
                    region := -3;
                  end if;
                  if ((p < 10.0e6) and (s > supperofp5(p))) then
                    region := -5;
                  end if;
                  if ((p >= 10.0e6) and (s > supperofp2(p))) then
                    region := -6;
                  end if;
                  if region < 0 then
                    assert(false,
                      "Region computation from p and s failed: function called outside the legal region");
                  else
                    ssubcrit := (s < data.SCRIT);
                    // simple precheck: very simple if pressure < PLIMIT4A
                    if (p < data.PLIMIT4A) then
                      // we can never be in region 3, so test for 1 and 2
                      if ssubcrit then
                        region := 1;
                      else
                        if (s > slowerofp5(p)) then
                          // check for region 5
                          if ((p < data.PLIMIT5) and (s < supperofp5(p))) then
                            region := 5;
                          else
                            region := -1;
                            // pressure and specific entropy too high, should never happen!
                          end if;
                        else
                          region := 2;
                        end if;
                        // tests for region 2 or 5
                      end if;
                      // tests for sub or supercritical
                    else
                      // the pressure is over data.PLIMIT4A
                      if ssubcrit then
                        // region 1 or 3
                        if s < supperofp1(p) then
                          region := 1;
                        else
                          if s < sl or p > data.PCRIT then
                            region := 3;
                          else
                            region := 4;
                          end if;
                        end if;
                        // test for region 1, 3 or 4
                      else
                        // region 2, 3 or 4
                        if (s > slowerofp2(p)) then
                          region := 2;
                        else
                          if s > sv or p > data.PCRIT then
                            region := 3;
                          else
                            region := 4;
                          end if;
                        end if;
                        // test for 2,3 and 4
                      end if;
                      // tests above PLIMIT4A
                    end if;
                    // above or below PLIMIT4A
                  end if;
                  // grand test for limits of p and s
                end if;
                // all tests with phase == 1
              end if;
              // mode was == 0
            end region_ps;

            function region_pT
              "Return the current region (valid values: 1,2,3,5) in IF97, given pressure and temperature"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              input Integer mode=0
                "Mode: 0 means check, otherwise assume region=mode";
              output Integer region
                "Region (valid values: 1,2,3,5) in IF97, region 4 is impossible!";
            algorithm
              if (mode <> 0) then
                region := mode;
              else
                if p < data.PLIMIT4A then
                  //test for regions 1,2,5
                  if T > data.TLIMIT2 then
                    region := 5;
                  elseif T > Basic.tsat(p) then
                    region := 2;
                  else
                    region := 1;
                  end if;
                else
                  //test for regions 1,2,3
                  if T < data.TLIMIT1 then
                    region := 1;
                  elseif T < boundary23ofp(p) then
                    region := 3;
                  else
                    region := 2;
                  end if;
                end if;
              end if;
              // mode was == 0
            end region_pT;

            function region_dT
              "Return the current region (valid values: 1,2,3,4,5) in IF97, given density and temperature"
              extends Modelica.Icons.Function;
              input SI.Density d "Density";
              input SI.Temperature T "Temperature (K)";
              input Integer phase=0
                "Phase: 2 for two-phase, 1 for one phase, 0 if not known";
              input Integer mode=0
                "Mode: 0 means check, otherwise assume region=mode";
              output Integer region "(valid values: 1,2,3,4,5) in IF97";
          protected
              Boolean Tovercrit "Flag if overcritical temperature";
              SI.Pressure p23 "Pressure needed to know if region 2 or 3";
            algorithm
              Tovercrit := T > data.TCRIT;
              if (mode <> 0) then
                region := mode;
              else
                p23 := boundary23ofT(T);
                if T > data.TLIMIT2 then
                  if d < 20.5655874106483 then
                    // check for the density in the upper corner of validity!
                    region := 5;
                  else
                    assert(false,
                      "Out of valid region for IF97, pressure above region 5!");
                  end if;
                elseif Tovercrit then
                  //check for regions 1, 2 or 3
                  if d > d2n(p23, T) and T > data.TLIMIT1 then
                    region := 3;
                  elseif T < data.TLIMIT1 then
                    region := 1;
                  else
                    // d  < d2n(p23, T) and T > data.TLIMIT1
                    region := 2;
                  end if;
                  // below critical, check for regions 1, 2, 3 or 4
                elseif (d > rhol_T(T)) then
                  // either 1 or 3
                  if T < data.TLIMIT1 then
                    region := 1;
                  else
                    region := 3;
                  end if;
                elseif (d < rhov_T(T)) then
                  // not liquid, not 2-phase, and not region 5, so either 2 or 3 or illegal
                  if (d > d2n(p23, T) and T > data.TLIMIT1) then
                    region := 3;
                  else
                    region := 2;
                  end if;
                else
                  region := 4;
                end if;
              end if;
            end region_dT;

            function hvl_dp
              "Derivative function for the specific enthalpy along the phase boundary"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output Real dh_dp
                "Derivative of specific enthalpy along the phase boundary";
            algorithm
              if bpro.region3boundary then
                dh_dp := ((bpro.d*bpro.pd - bpro.T*bpro.pt) + (bpro.T*bpro.pt*bpro.pt
                   + bpro.d*bpro.d*bpro.pd*bpro.cv)/bpro.dpT)/(bpro.pd*bpro.d*bpro.d);
              else
                dh_dp := (1/bpro.d - bpro.T*bpro.vt) + bpro.cp/bpro.dpT;
              end if;
            end hvl_dp;

            function dhl_dp
              "Derivative of liquid specific enthalpy on the boundary between regions 4 and 3 or 1 w.r.t. pressure"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.DerEnthalpyByPressure dh_dp
                "Specific enthalpy derivative w.r.t. pressure";
            algorithm
              dh_dp := hvl_dp(p, boilingcurve_p(p));
              annotation (Inline=true);
            end dhl_dp;

            function dhv_dp
              "Derivative of vapour specific enthalpy on the boundary between regions 4 and 3 or 1 w.r.t. pressure"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.DerEnthalpyByPressure dh_dp
                "Specific enthalpy derivative w.r.t. pressure";
            algorithm
              dh_dp := hvl_dp(p, dewcurve_p(p));
              annotation (Inline=true);
            end dhv_dp;

            function drhovl_dp
              extends Modelica.Icons.Function;
              input SI.Pressure p "Saturation pressure";
              input Common.IF97PhaseBoundaryProperties bpro "Property record";
              output Real dd_dp(unit="kg/(m3.Pa)")
                "Derivative of density along the phase boundary";
            algorithm
              dd_dp := if bpro.region3boundary then (1.0 - bpro.pt/bpro.dpT)/bpro.pd
                 else -bpro.d*bpro.d*(bpro.vp + bpro.vt/bpro.dpT);
              annotation (Inline=true);
            end drhovl_dp;

            function drhol_dp
              "Derivative of density of saturated water w.r.t. pressure"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Saturation pressure";
              output SI.DerDensityByPressure dd_dp
                "Derivative of density of water at the boiling point";
            algorithm
              dd_dp := drhovl_dp(p, boilingcurve_p(p));
              annotation (Inline=true);
            end drhol_dp;

            function drhov_dp
              "Derivative of density of saturated steam w.r.t. pressure"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Saturation pressure";
              output SI.DerDensityByPressure dd_dp
                "Derivative of density of water at the boiling point";
            algorithm
              dd_dp := drhovl_dp(p, dewcurve_p(p));
              annotation (Inline=true);
            end drhov_dp;
            annotation (Documentation(info="<html><h4>Package description</h4>
 <p>Package <strong>Regions</strong> contains a large number of auxiliary functions which are needed to compute the current region
 of the IAPWS/IF97 for a given pair of input variables as quickly as possible. The focus of this implementation was on
 computational efficiency, not on compact code. Many of the function values calculated in these functions could be obtained
 using the fundamental functions of IAPWS/IF97, but with considerable overhead. If the region of IAPWS/IF97 is known in advance,
 the input variable mode can be set to the region, then the somewhat costly region checks are omitted.
 The checking for the phase has to be done outside the region functions because many properties are not
 differentiable at the region boundary. If the input phase is 2, the output region will be set to 4 immediately.</p>
 <h4>Package contents</h4>
 <p> The main 4 functions in this package are the functions returning the appropriate region for two input variables.</p>
 <ul>
 <li>Function <strong>region_ph</strong> compute the region of IAPWS/IF97 for input pair pressure and specific enthalpy.</li>
 <li>Function <strong>region_ps</strong> compute the region of IAPWS/IF97 for input pair pressure and specific entropy</li>
 <li>Function <strong>region_dT</strong> compute the region of IAPWS/IF97 for input pair density and temperature.</li>
 <li>Function <strong>region_pT</strong> compute the region of IAPWS/IF97 for input pair pressure and temperature (only in phase region).</li>
 </ul>
 <p>In addition, functions of the boiling and condensation curves compute the specific enthalpy, specific entropy, or density on these
 curves. The functions for the saturation pressure and temperature are included in the package <strong>Basic</strong> because they are part of
 the original <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IAPWS/IF97 standards document</a>. These functions are also aliased to
 be used directly from package <strong>Water</strong>.
</p>
 <ul>
 <li>Function <strong>hl_p</strong> computes the liquid specific enthalpy as a function of pressure. For overcritical pressures,
 the critical specific enthalpy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <strong>hv_p</strong> computes the vapour specific enthalpy as a function of pressure. For overcritical pressures,
 the critical specific enthalpy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <strong>sl_p</strong> computes the liquid specific entropy as a function of pressure. For overcritical pressures,
 the critical  specific entropy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <strong>sv_p</strong> computes the vapour  specific entropy as a function of pressure. For overcritical pressures,
 the critical  specific entropy is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <strong>rhol_T</strong> computes the liquid density as a function of temperature. For overcritical temperatures,
 the critical density is returned. An approximation is used for temperatures > 623.15 K.</li>
 <li>Function <strong>rhol_T</strong> computes the vapour density as a function of temperature. For overcritical temperatures,
 the critical density is returned. An approximation is used for temperatures > 623.15 K.</li>
 </ul>
 <p>All other functions are auxiliary functions called from the region functions to check a specific boundary.</p>
 <ul>
 <li>Function <strong>boundary23ofT</strong> computes the boundary pressure between regions 2 and 3 (input temperature)</li>
 <li>Function <strong>boundary23ofp</strong> computes the boundary temperature between regions 2 and 3 (input pressure)</li>
 <li>Function <strong>hlowerofp5</strong> computes the lower specific enthalpy limit of region 5 (input p, T=1073.15 K)</li>
 <li>Function <strong>hupperofp5</strong> computes the upper specific enthalpy limit of region 5 (input p, T=2273.15 K)</li>
 <li>Function <strong>slowerofp5</strong> computes the lower specific entropy limit of region 5 (input p, T=1073.15 K)</li>
 <li>Function <strong>supperofp5</strong> computes the upper specific entropy limit of region 5 (input p, T=2273.15 K)</li>
 <li>Function <strong>hlowerofp1</strong> computes the lower specific enthalpy limit of region 1 (input p, T=273.15 K)</li>
 <li>Function <strong>hupperofp1</strong> computes the upper specific enthalpy limit of region 1 (input p, T=623.15 K)</li>
 <li>Function <strong>slowerofp1</strong> computes the lower specific entropy limit of region 1 (input p, T=273.15 K)</li>
 <li>Function <strong>supperofp1</strong> computes the upper specific entropy limit of region 1 (input p, T=623.15 K)</li>
 <li>Function <strong>hlowerofp2</strong> computes the lower specific enthalpy limit of region 2 (input p, T=623.15 K)</li>
 <li>Function <strong>hupperofp2</strong> computes the upper specific enthalpy limit of region 2 (input p, T=1073.15 K)</li>
 <li>Function <strong>slowerofp2</strong> computes the lower specific entropy limit of region 2 (input p, T=623.15 K)</li>
 <li>Function <strong>supperofp2</strong> computes the upper specific entropy limit of region 2 (input p, T=1073.15 K)</li>
 <li>Function <strong>d1n</strong> computes the density in region 1 as function of pressure and temperature</li>
 <li>Function <strong>d2n</strong> computes the density in region 2 as function of pressure and temperature</li>
 <li>Function <strong>dhot1ofp</strong> computes the hot density limit of region 1 (input p, T=623.15 K)</li>
 <li>Function <strong>dupper1ofT</strong>computes the high pressure density limit of region 1 (input T, p=100MPa)</li>
 <li>Function <strong>hl_p_R4b</strong> computes a high accuracy approximation to the liquid enthalpy for temperatures > 623.15 K (input p)</li>
 <li>Function <strong>hv_p_R4b</strong> computes a high accuracy approximation to the vapour enthalpy for temperatures > 623.15 K (input p)</li>
 <li>Function <strong>sl_p_R4b</strong> computes a high accuracy approximation to the liquid entropy for temperatures > 623.15 K (input p)</li>
 <li>Function <strong>sv_p_R4b</strong> computes a high accuracy approximation to the vapour entropy for temperatures > 623.15 K (input p)</li>
 <li>Function <strong>rhol_p_R4b</strong> computes a high accuracy approximation to the liquid density for temperatures > 623.15 K (input p)</li>
 <li>Function <strong>rhov_p_R4b</strong> computes a high accuracy approximation to the vapour density for temperatures > 623.15 K (input p)</li>
 </ul>

<h4>Version Info and Revision history</h4>
<ul>
<li>First implemented: <em>July, 2000</em>
       by Hubertus Tummescheit
       </li>
</ul>
<address>Authors: Hubertus Tummescheit, Jonas Eborn and Falko Jens Wagner<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
 </address>
 <ul>
 <li>Initial version: July 2000</li>
 <li>Revised and extended for inclusion in Modelica.Thermal: December 2002</li>
</ul>
</html>"));
          end Regions;

          package Basic "Base functions as described in IAWPS/IF97"
            extends Modelica.Icons.FunctionsPackage;

            function g1 "Gibbs function for region 1: g(p,T)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output Modelica.Media.Common.GibbsDerivs g
                "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          protected
              Real pi1 "Dimensionless pressure";
              Real tau1 "Dimensionless temperature";
              Real[45] o "Vector of auxiliary variables";
              Real pl "Auxiliary variable";
            algorithm
              pl := min(p, data.PCRIT - 1);
              assert(p > triple.ptriple,
                "IF97 medium function g1 called with too low pressure\n" + "p = " +
                String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              assert(p <= 100.0e6, "IF97 medium function g1: the input pressure (= "
                 + String(p) + " Pa) is higher than 100 MPa");
              assert(T >= 273.15, "IF97 medium function g1: the temperature (= " +
                String(T) + " K) is lower than 273.15 K!");
              g.p := p;
              g.T := T;
              g.R_s := data.RH2O;
              g.pi := p/data.PSTAR1;
              g.tau := data.TSTAR1/T;
              pi1 := 7.1000000000000 - g.pi;
              tau1 := -1.22200000000000 + g.tau;
              o[1] := tau1*tau1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              o[4] := o[3]*tau1;
              o[5] := 1/o[4];
              o[6] := o[1]*o[2];
              o[7] := o[1]*tau1;
              o[8] := 1/o[7];
              o[9] := o[1]*o[2]*o[3];
              o[10] := 1/o[2];
              o[11] := o[2]*tau1;
              o[12] := 1/o[11];
              o[13] := o[2]*o[3];
              o[14] := 1/o[3];
              o[15] := pi1*pi1;
              o[16] := o[15]*pi1;
              o[17] := o[15]*o[15];
              o[18] := o[17]*o[17];
              o[19] := o[17]*o[18]*pi1;
              o[20] := o[15]*o[17];
              o[21] := o[3]*o[3];
              o[22] := o[21]*o[21];
              o[23] := o[22]*o[3]*tau1;
              o[24] := 1/o[23];
              o[25] := o[22]*o[3];
              o[26] := 1/o[25];
              o[27] := o[1]*o[2]*o[22]*tau1;
              o[28] := 1/o[27];
              o[29] := o[1]*o[2]*o[22];
              o[30] := 1/o[29];
              o[31] := o[1]*o[2]*o[21]*o[3]*tau1;
              o[32] := 1/o[31];
              o[33] := o[2]*o[21]*o[3]*tau1;
              o[34] := 1/o[33];
              o[35] := o[1]*o[3]*tau1;
              o[36] := 1/o[35];
              o[37] := o[1]*o[3];
              o[38] := 1/o[37];
              o[39] := 1/o[6];
              o[40] := o[1]*o[22]*o[3];
              o[41] := 1/o[40];
              o[42] := 1/o[22];
              o[43] := o[1]*o[2]*o[21]*o[3];
              o[44] := 1/o[43];
              o[45] := 1/o[13];
              g.g := pi1*(pi1*(pi1*(o[10]*(-0.000031679644845054 + o[2]*(-2.82707979853120e-6
                 - 8.5205128120103e-10*o[6])) + pi1*(o[12]*(-2.24252819080000e-6 + (-6.5171222895601e-7
                 - 1.43417299379240e-13*o[13])*o[7]) + pi1*(-4.0516996860117e-7*o[14]
                 + o[16]*((-1.27343017416410e-9 - 1.74248712306340e-10*o[11])*o[36]
                 + o[19]*(-6.8762131295531e-19*o[34] + o[15]*(1.44783078285210e-20*o[
                32] + o[20]*(2.63357816627950e-23*o[30] + pi1*(-1.19476226400710e-23*
                o[28] + pi1*(1.82280945814040e-24*o[26] - 9.3537087292458e-26*o[24]*
                pi1))))))))) + o[8]*(-0.00047184321073267 + o[7]*(-0.000300017807930260
                 + (0.000047661393906987 + o[1]*(-4.4141845330846e-6 -
                7.2694996297594e-16*o[9]))*tau1))) + o[5]*(0.000283190801238040 + o[1]
                *(-0.00060706301565874 + o[6]*(-0.0189900682184190 + tau1*(-0.032529748770505
                 + (-0.0218417171754140 - 0.000052838357969930*o[1])*tau1))))) + (
                0.146329712131670 + tau1*(-0.84548187169114 + tau1*(-3.7563603672040
                 + tau1*(3.3855169168385 + tau1*(-0.95791963387872 + tau1*(
                0.157720385132280 + (-0.0166164171995010 + 0.00081214629983568*tau1)*
                tau1))))))/o[1];

              g.gpi := pi1*(pi1*(o[10]*(0.000095038934535162 + o[2]*(
                8.4812393955936e-6 + 2.55615384360309e-9*o[6])) + pi1*(o[12]*(
                8.9701127632000e-6 + (2.60684891582404e-6 + 5.7366919751696e-13*o[13])
                *o[7]) + pi1*(2.02584984300585e-6*o[14] + o[16]*((1.01874413933128e-8
                 + 1.39398969845072e-9*o[11])*o[36] + o[19]*(1.44400475720615e-17*o[
                34] + o[15]*(-3.3300108005598e-19*o[32] + o[20]*(-7.6373766822106e-22
                *o[30] + pi1*(3.5842867920213e-22*o[28] + pi1*(-5.6507093202352e-23*o[
                26] + 2.99318679335866e-24*o[24]*pi1))))))))) + o[8]*(
                0.00094368642146534 + o[7]*(0.00060003561586052 + (-0.000095322787813974
                 + o[1]*(8.8283690661692e-6 + 1.45389992595188e-15*o[9]))*tau1))) + o[
                5]*(-0.000283190801238040 + o[1]*(0.00060706301565874 + o[6]*(
                0.0189900682184190 + tau1*(0.032529748770505 + (0.0218417171754140 +
                0.000052838357969930*o[1])*tau1))));

              g.gpipi := pi1*(o[10]*(-0.000190077869070324 + o[2]*(-0.0000169624787911872
                 - 5.1123076872062e-9*o[6])) + pi1*(o[12]*(-0.0000269103382896000 + (
                -7.8205467474721e-6 - 1.72100759255088e-12*o[13])*o[7]) + pi1*(-8.1033993720234e-6
                *o[14] + o[16]*((-7.1312089753190e-8 - 9.7579278891550e-9*o[11])*o[36]
                 + o[19]*(-2.88800951441230e-16*o[34] + o[15]*(7.3260237612316e-18*o[
                32] + o[20]*(2.13846547101895e-20*o[30] + pi1*(-1.03944316968618e-20*
                o[28] + pi1*(1.69521279607057e-21*o[26] - 9.2788790594118e-23*o[24]*
                pi1))))))))) + o[8]*(-0.00094368642146534 + o[7]*(-0.00060003561586052
                 + (0.000095322787813974 + o[1]*(-8.8283690661692e-6 -
                1.45389992595188e-15*o[9]))*tau1));

              g.gtau := pi1*(o[38]*(-0.00254871721114236 + o[1]*(0.0042494411096112
                 + (0.0189900682184190 + (-0.0218417171754140 - 0.000158515073909790*
                o[1])*o[1])*o[6])) + pi1*(o[10]*(0.00141552963219801 + o[2]*(
                0.000047661393906987 + o[1]*(-0.0000132425535992538 -
                1.23581493705910e-14*o[9]))) + pi1*(o[12]*(0.000126718579380216 -
                5.1123076872062e-9*o[37]) + pi1*(o[39]*(0.0000112126409540000 + (
                1.30342445791202e-6 - 1.43417299379240e-12*o[13])*o[7]) + pi1*(
                3.2413597488094e-6*o[5] + o[16]*((1.40077319158051e-8 +
                1.04549227383804e-9*o[11])*o[45] + o[19]*(1.99410180757040e-17*o[44]
                 + o[15]*(-4.4882754268415e-19*o[42] + o[20]*(-1.00075970318621e-21*o[
                28] + pi1*(4.6595728296277e-22*o[26] + pi1*(-7.2912378325616e-23*o[24]
                 + 3.8350205789908e-24*o[41]*pi1))))))))))) + o[8]*(-0.292659424263340
                 + tau1*(0.84548187169114 + o[1]*(3.3855169168385 + tau1*(-1.91583926775744
                 + tau1*(0.47316115539684 + (-0.066465668798004 + 0.0040607314991784*
                tau1)*tau1)))));

              g.gtautau := pi1*(o[36]*(0.0254871721114236 + o[1]*(-0.033995528876889
                 + (-0.037980136436838 - 0.00031703014781958*o[2])*o[6])) + pi1*(o[12]
                *(-0.0056621185287920 + o[6]*(-0.0000264851071985076 -
                1.97730389929456e-13*o[9])) + pi1*((-0.00063359289690108 -
                2.55615384360309e-8*o[37])*o[39] + pi1*(pi1*(-0.0000291722377392842*o[
                38] + o[16]*(o[19]*(-5.9823054227112e-16*o[32] + o[15]*(o[20]*(
                3.9029628424262e-20*o[26] + pi1*(-1.86382913185108e-20*o[24] + pi1*(
                2.98940751135026e-21*o[41] - (1.61070864317613e-22*pi1)/(o[1]*o[22]*o[
                3]*tau1)))) + 1.43624813658928e-17/(o[22]*tau1))) + (-1.68092782989661e-7
                 - 7.3184459168663e-9*o[11])/(o[2]*o[3]*tau1))) + (-0.000067275845724000
                 + (-3.9102733737361e-6 - 1.29075569441316e-11*o[13])*o[7])/(o[1]*o[2]
                *tau1))))) + o[10]*(0.87797827279002 + tau1*(-1.69096374338228 + o[7]
                *(-1.91583926775744 + tau1*(0.94632231079368 + (-0.199397006394012 +
                0.0162429259967136*tau1)*tau1))));

              g.gtaupi := o[38]*(0.00254871721114236 + o[1]*(-0.0042494411096112 + (-0.0189900682184190
                 + (0.0218417171754140 + 0.000158515073909790*o[1])*o[1])*o[6])) +
                pi1*(o[10]*(-0.00283105926439602 + o[2]*(-0.000095322787813974 + o[1]
                *(0.0000264851071985076 + 2.47162987411820e-14*o[9]))) + pi1*(o[12]*(
                -0.00038015573814065 + 1.53369230616185e-8*o[37]) + pi1*(o[39]*(-0.000044850563816000
                 + (-5.2136978316481e-6 + 5.7366919751696e-12*o[13])*o[7]) + pi1*(-0.0000162067987440468
                *o[5] + o[16]*((-1.12061855326441e-7 - 8.3639381907043e-9*o[11])*o[45]
                 + o[19]*(-4.1876137958978e-16*o[44] + o[15]*(1.03230334817355e-17*o[
                42] + o[20]*(2.90220313924001e-20*o[28] + pi1*(-1.39787184888831e-20*
                o[26] + pi1*(2.26028372809410e-21*o[24] - 1.22720658527705e-22*o[41]*
                pi1))))))))));
            end g1;

            function g2 "Gibbs function for region 2: g(p,T)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              input Boolean checkLimits=true "Check if inputs p,T are in region of validity";
              output Modelica.Media.Common.GibbsDerivs g
                "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          protected
              Real tau2 "Dimensionless temperature";
              Real[55] o "Vector of auxiliary variables";
            algorithm
              g.p := p;
              g.T := T;
              g.R_s := data.RH2O;
              if checkLimits then
                assert(p > 0.0,
                  "IF97 medium function g2 called with too low pressure\n" + "p = " +
                  String(p) + " Pa <= 0.0 Pa");
                assert(p <= 100.0e6, "IF97 medium function g2: the input pressure (= "
                   + String(p) + " Pa) is higher than 100 MPa");
                assert(T >= 273.15, "IF97 medium function g2: the temperature (= " +
                  String(T) + " K) is lower than 273.15 K!");
                assert(T <= 1073.15,
                  "IF97 medium function g2: the input temperature (= " + String(T) +
                  " K) is higher than the limit of 1073.15 K");
              end if;
              g.pi := p/data.PSTAR2;
              g.tau := data.TSTAR2/T;
              tau2 := -0.5 + g.tau;
              o[1] := tau2*tau2;
              o[2] := o[1]*tau2;
              o[3] := -0.050325278727930*o[2];
              o[4] := -0.057581259083432 + o[3];
              o[5] := o[4]*tau2;
              o[6] := -0.045996013696365 + o[5];
              o[7] := o[6]*tau2;
              o[8] := -0.0178348622923580 + o[7];
              o[9] := o[8]*tau2;
              o[10] := o[1]*o[1];
              o[11] := o[10]*o[10];
              o[12] := o[11]*o[11];
              o[13] := o[10]*o[11]*o[12]*tau2;
              o[14] := o[1]*o[10]*tau2;
              o[15] := o[10]*o[11]*tau2;
              o[16] := o[1]*o[12]*tau2;
              o[17] := o[1]*o[11]*tau2;
              o[18] := o[1]*o[10]*o[11];
              o[19] := o[10]*o[11]*o[12];
              o[20] := o[1]*o[10];
              o[21] := g.pi*g.pi;
              o[22] := o[21]*o[21];
              o[23] := o[21]*o[22];
              o[24] := o[10]*o[12]*tau2;
              o[25] := o[12]*o[12];
              o[26] := o[11]*o[12]*o[25]*tau2;
              o[27] := o[10]*o[12];
              o[28] := o[1]*o[10]*o[11]*tau2;
              o[29] := o[10]*o[12]*o[25]*tau2;
              o[30] := o[1]*o[10]*o[25]*tau2;
              o[31] := o[1]*o[11]*o[12];
              o[32] := o[1]*o[12];
              o[33] := g.tau*g.tau;
              o[34] := o[33]*o[33];
              o[35] := -0.000053349095828174*o[13];
              o[36] := -0.087594591301146 + o[35];
              o[37] := o[2]*o[36];
              o[38] := -0.0078785554486710 + o[37];
              o[39] := o[1]*o[38];
              o[40] := -0.00037897975032630 + o[39];
              o[41] := o[40]*tau2;
              o[42] := -0.000066065283340406 + o[41];
              o[43] := o[42]*tau2;
              o[44] := 5.7870447262208e-6*tau2;
              o[45] := -0.301951672367580*o[2];
              o[46] := -0.172743777250296 + o[45];
              o[47] := o[46]*tau2;
              o[48] := -0.091992027392730 + o[47];
              o[49] := o[48]*tau2;
              o[50] := o[1]*o[11];
              o[51] := o[10]*o[11];
              o[52] := o[11]*o[12]*o[25];
              o[53] := o[10]*o[12]*o[25];
              o[54] := o[1]*o[10]*o[25];
              o[55] := o[11]*o[12]*tau2;

              g.g := g.pi*(-0.00177317424732130 + o[9] + g.pi*(tau2*(-0.000033032641670203
                 + (-0.000189489875163150 + o[1]*(-0.0039392777243355 + (-0.043797295650573
                 - 0.0000266745479140870*o[13])*o[2]))*tau2) + g.pi*(
                2.04817376923090e-8 + (4.3870667284435e-7 + o[1]*(-0.000032277677238570
                 + (-0.00150339245421480 - 0.040668253562649*o[13])*o[2]))*tau2 + g.pi
                *(g.pi*(2.29220763376610e-6*o[14] + g.pi*((-1.67147664510610e-11 + o[
                15]*(-0.00211714723213550 - 23.8957419341040*o[16]))*o[2] + g.pi*(-5.9059564324270e-18
                 + o[17]*(-1.26218088991010e-6 - 0.038946842435739*o[18]) + g.pi*(o[
                11]*(1.12562113604590e-11 - 8.2311340897998*o[19]) + g.pi*(
                1.98097128020880e-8*o[15] + g.pi*(o[10]*(1.04069652101740e-19 + (-1.02347470959290e-13
                 - 1.00181793795110e-9*o[10])*o[20]) + o[23]*(o[13]*(-8.0882908646985e-11
                 + 0.106930318794090*o[24]) + o[21]*(-0.33662250574171*o[26] + o[21]*
                (o[27]*(8.9185845355421e-25 + (3.06293168762320e-13 -
                4.2002467698208e-6*o[15])*o[28]) + g.pi*(-5.9056029685639e-26*o[24]
                 + g.pi*(3.7826947613457e-6*o[29] + g.pi*(-1.27686089346810e-15*o[30]
                 + o[31]*(7.3087610595061e-29 + o[18]*(5.5414715350778e-17 -
                9.4369707241210e-7*o[32]))*g.pi)))))))))))) + tau2*(-7.8847309559367e-10
                 + (1.27907178522850e-8 + 4.8225372718507e-7*tau2)*tau2))))) + (-0.0056087911830200
                 + g.tau*(0.071452738814550 + g.tau*(-0.40710498239280 + g.tau*(
                1.42408197144400 + g.tau*(-4.3839511194500 + g.tau*(-9.6927686002170
                 + g.tau*(10.0866556801800 + (-0.284086326077200 + 0.0212684635330700
                *g.tau)*g.tau) + Modelica.Math.log(g.pi)))))))/(o[34]*g.tau);

              g.gpi := (1.00000000000000 + g.pi*(-0.00177317424732130 + o[9] + g.pi*(
                o[43] + g.pi*(6.1445213076927e-8 + (1.31612001853305e-6 + o[1]*(-0.000096833031715710
                 + (-0.0045101773626444 - 0.122004760687947*o[13])*o[2]))*tau2 + g.pi
                *(g.pi*(0.0000114610381688305*o[14] + g.pi*((-1.00288598706366e-10 +
                o[15]*(-0.0127028833928130 - 143.374451604624*o[16]))*o[2] + g.pi*(-4.1341695026989e-17
                 + o[17]*(-8.8352662293707e-6 - 0.272627897050173*o[18]) + g.pi*(o[11]
                *(9.0049690883672e-11 - 65.849072718398*o[19]) + g.pi*(
                1.78287415218792e-7*o[15] + g.pi*(o[10]*(1.04069652101740e-18 + (-1.02347470959290e-12
                 - 1.00181793795110e-8*o[10])*o[20]) + o[23]*(o[13]*(-1.29412653835176e-9
                 + 1.71088510070544*o[24]) + o[21]*(-6.0592051033508*o[26] + o[21]*(o[
                27]*(1.78371690710842e-23 + (6.1258633752464e-12 -
                0.000084004935396416*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[24]
                 + g.pi*(0.000083219284749605*o[29] + g.pi*(-2.93678005497663e-14*o[
                30] + o[31]*(1.75410265428146e-27 + o[18]*(1.32995316841867e-15 -
                0.0000226487297378904*o[32]))*g.pi)))))))))))) + tau2*(-3.15389238237468e-9
                 + (5.1162871409140e-8 + 1.92901490874028e-6*tau2)*tau2))))))/g.pi;

              g.gpipi := (-1.00000000000000 + o[21]*(o[43] + g.pi*(
                1.22890426153854e-7 + (2.63224003706610e-6 + o[1]*(-0.000193666063431420
                 + (-0.0090203547252888 - 0.244009521375894*o[13])*o[2]))*tau2 + g.pi
                *(g.pi*(0.000045844152675322*o[14] + g.pi*((-5.0144299353183e-10 + o[
                15]*(-0.063514416964065 - 716.87225802312*o[16]))*o[2] + g.pi*(-2.48050170161934e-16
                 + o[17]*(-0.000053011597376224 - 1.63576738230104*o[18]) + g.pi*(o[
                11]*(6.3034783618570e-10 - 460.94350902879*o[19]) + g.pi*(
                1.42629932175034e-6*o[15] + g.pi*(o[10]*(9.3662686891566e-18 + (-9.2112723863361e-12
                 - 9.0163614415599e-8*o[10])*o[20]) + o[23]*(o[13]*(-1.94118980752764e-8
                 + 25.6632765105816*o[24]) + o[21]*(-103.006486756963*o[26] + o[21]*(
                o[27]*(3.3890621235060e-22 + (1.16391404129682e-10 -
                0.00159609377253190*o[15])*o[28]) + g.pi*(-2.48035324679684e-23*o[24]
                 + g.pi*(0.00174760497974171*o[29] + g.pi*(-6.4609161209486e-13*o[30]
                 + o[31]*(4.0344361048474e-26 + o[18]*(3.05889228736295e-14 -
                0.00052092078397148*o[32]))*g.pi)))))))))))) + tau2*(-9.4616771471240e-9
                 + (1.53488614227420e-7 + o[44])*tau2)))))/o[21];

              g.gtau := (0.0280439559151000 + g.tau*(-0.285810955258200 + g.tau*(
                1.22131494717840 + g.tau*(-2.84816394288800 + g.tau*(4.3839511194500
                 + o[33]*(10.0866556801800 + (-0.56817265215440 + 0.063805390599210*g.tau)
                *g.tau))))))/(o[33]*o[34]) + g.pi*(-0.0178348622923580 + o[49] + g.pi
                *(-0.000033032641670203 + (-0.00037897975032630 + o[1]*(-0.0157571108973420
                 + (-0.306581069554011 - 0.00096028372490713*o[13])*o[2]))*tau2 + g.pi
                *(4.3870667284435e-7 + o[1]*(-0.000096833031715710 + (-0.0090203547252888
                 - 1.42338887469272*o[13])*o[2]) + g.pi*(-7.8847309559367e-10 + g.pi*
                (0.0000160454534363627*o[20] + g.pi*(o[1]*(-5.0144299353183e-11 + o[
                15]*(-0.033874355714168 - 836.35096769364*o[16])) + g.pi*((-0.0000138839897890111
                 - 0.97367106089347*o[18])*o[50] + g.pi*(o[14]*(9.0049690883672e-11
                 - 296.320827232793*o[19]) + g.pi*(2.57526266427144e-7*o[51] + g.pi*(
                o[2]*(4.1627860840696e-19 + (-1.02347470959290e-12 -
                1.40254511313154e-8*o[10])*o[20]) + o[23]*(o[19]*(-2.34560435076256e-9
                 + 5.3465159397045*o[24]) + o[21]*(-19.1874828272775*o[52] + o[21]*(o[
                16]*(1.78371690710842e-23 + (1.07202609066812e-11 -
                0.000201611844951398*o[15])*o[28]) + g.pi*(-1.24017662339842e-24*o[27]
                 + g.pi*(0.000200482822351322*o[53] + g.pi*(-4.9797574845256e-14*o[54]
                 + (1.90027787547159e-27 + o[18]*(2.21658861403112e-15 -
                0.000054734430199902*o[32]))*o[55]*g.pi)))))))))))) + (
                2.55814357045700e-8 + 1.44676118155521e-6*tau2)*tau2))));

              g.gtautau := (-0.168263735490600 + g.tau*(1.42905477629100 + g.tau*(-4.8852597887136
                 + g.tau*(8.5444918286640 + g.tau*(-8.7679022389000 + o[33]*(-0.56817265215440
                 + 0.127610781198420*g.tau)*g.tau)))))/(o[33]*o[34]*g.tau) + g.pi*(-0.091992027392730
                 + (-0.34548755450059 - 1.50975836183790*o[2])*tau2 + g.pi*(-0.00037897975032630
                 + o[1]*(-0.047271332692026 + (-1.83948641732407 - 0.033609930371750*
                o[13])*o[2]) + g.pi*((-0.000193666063431420 + (-0.045101773626444 -
                48.395221739552*o[13])*o[2])*tau2 + g.pi*(2.55814357045700e-8 +
                2.89352236311042e-6*tau2 + g.pi*(0.000096272720618176*o[10]*tau2 + g.pi
                *((-1.00288598706366e-10 + o[15]*(-0.50811533571252 -
                28435.9329015838*o[16]))*tau2 + g.pi*(o[11]*(-0.000138839897890111 -
                23.3681054614434*o[18])*tau2 + g.pi*((6.3034783618570e-10 -
                10371.2289531477*o[19])*o[20] + g.pi*(3.09031519712573e-6*o[17] + g.pi
                *(o[1]*(1.24883582522088e-18 + (-9.2112723863361e-12 -
                1.82330864707100e-7*o[10])*o[20]) + o[23]*(o[1]*o[11]*o[12]*(-6.5676921821352e-8
                 + 261.979281045521*o[24])*tau2 + o[21]*(-1074.49903832754*o[1]*o[10]
                *o[12]*o[25]*tau2 + o[21]*((3.3890621235060e-22 + (
                3.6448887082716e-10 - 0.0094757567127157*o[15])*o[28])*o[32] + g.pi*(
                -2.48035324679684e-23*o[16] + g.pi*(0.0104251067622687*o[1]*o[12]*o[
                25]*tau2 + g.pi*(o[11]*o[12]*(4.7506946886790e-26 + o[18]*(
                8.6446955947214e-14 - 0.00311986252139440*o[32]))*g.pi -
                1.89230784411972e-12*o[10]*o[25]*tau2))))))))))))))));

              g.gtaupi := -0.0178348622923580 + o[49] + g.pi*(-0.000066065283340406
                 + (-0.00075795950065260 + o[1]*(-0.0315142217946840 + (-0.61316213910802
                 - 0.00192056744981426*o[13])*o[2]))*tau2 + g.pi*(1.31612001853305e-6
                 + o[1]*(-0.000290499095147130 + (-0.0270610641758664 -
                4.2701666240781*o[13])*o[2]) + g.pi*(-3.15389238237468e-9 + g.pi*(
                0.000080227267181813*o[20] + g.pi*(o[1]*(-3.00865796119098e-10 + o[15]
                *(-0.203246134285008 - 5018.1058061618*o[16])) + g.pi*((-0.000097187928523078
                 - 6.8156974262543*o[18])*o[50] + g.pi*(o[14]*(7.2039752706938e-10 -
                2370.56661786234*o[19]) + g.pi*(2.31773639784430e-6*o[51] + g.pi*(o[2]
                *(4.1627860840696e-18 + (-1.02347470959290e-11 - 1.40254511313154e-7*
                o[10])*o[20]) + o[23]*(o[19]*(-3.7529669612201e-8 + 85.544255035272*o[
                24]) + o[21]*(-345.37469089099*o[52] + o[21]*(o[16]*(
                3.5674338142168e-22 + (2.14405218133624e-10 - 0.0040322368990280*o[15])
                *o[28]) + g.pi*(-2.60437090913668e-23*o[27] + g.pi*(
                0.0044106220917291*o[53] + g.pi*(-1.14534422144089e-12*o[54] + (
                4.5606669011318e-26 + o[18]*(5.3198126736747e-14 -
                0.00131362632479764*o[32]))*o[55]*g.pi)))))))))))) + (
                1.02325742818280e-7 + o[44])*tau2)));
            end g2;

            function f3 "Helmholtz function for region 3: f(d,T)"
              extends Modelica.Icons.Function;
              input SI.Density d "Density";
              input SI.Temperature T "Temperature (K)";
              output Modelica.Media.Common.HelmholtzDerivs f
                "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          protected
              Real[40] o "Vector of auxiliary variables";
            algorithm
              f.T := T;
              f.d := d;
              f.R_s := data.RH2O;
              f.tau := data.TCRIT/T;
              f.delta := if (d == data.DCRIT and T == data.TCRIT) then 1 - Modelica.Constants.eps
                 else abs(d/data.DCRIT);
              o[1] := f.tau*f.tau;
              o[2] := o[1]*o[1];
              o[3] := o[2]*f.tau;
              o[4] := o[1]*f.tau;
              o[5] := o[2]*o[2];
              o[6] := o[1]*o[5]*f.tau;
              o[7] := o[5]*f.tau;
              o[8] := -0.64207765181607*o[1];
              o[9] := 0.88521043984318 + o[8];
              o[10] := o[7]*o[9];
              o[11] := -1.15244078066810 + o[10];
              o[12] := o[11]*o[2];
              o[13] := -1.26543154777140 + o[12];
              o[14] := o[1]*o[13];
              o[15] := o[1]*o[2]*o[5]*f.tau;
              o[16] := o[2]*o[5];
              o[17] := o[1]*o[5];
              o[18] := o[5]*o[5];
              o[19] := o[1]*o[18]*o[2];
              o[20] := o[1]*o[18]*o[2]*f.tau;
              o[21] := o[18]*o[5];
              o[22] := o[1]*o[18]*o[5];
              o[23] := 0.251168168486160*o[2];
              o[24] := 0.078841073758308 + o[23];
              o[25] := o[15]*o[24];
              o[26] := -6.1005234513930 + o[25];
              o[27] := o[26]*f.tau;
              o[28] := 9.7944563083754 + o[27];
              o[29] := o[2]*o[28];
              o[30] := -1.70429417648412 + o[29];
              o[31] := o[1]*o[30];
              o[32] := f.delta*f.delta;
              o[33] := -10.9153200808732*o[1];
              o[34] := 13.2781565976477 + o[33];
              o[35] := o[34]*o[7];
              o[36] := -6.9146446840086 + o[35];
              o[37] := o[2]*o[36];
              o[38] := -2.53086309554280 + o[37];
              o[39] := o[38]*f.tau;
              o[40] := o[18]*o[5]*f.tau;

              f.f := -15.7328452902390 + f.tau*(20.9443969743070 + (-7.6867707878716
                 + o[3]*(2.61859477879540 + o[4]*(-2.80807811486200 + o[1]*(
                1.20533696965170 - 0.0084566812812502*o[6]))))*f.tau) + f.delta*(o[14]
                 + f.delta*(0.38493460186671 + o[1]*(-0.85214708824206 + o[2]*(
                4.8972281541877 + (-3.05026172569650 + o[15]*(0.039420536879154 +
                0.125584084243080*o[2]))*f.tau)) + f.delta*(-0.279993296987100 + o[1]
                *(1.38997995694600 + o[1]*(-2.01899150235700 + o[16]*(-0.0082147637173963
                 - 0.47596035734923*o[17]))) + f.delta*(0.043984074473500 + o[1]*(-0.44476435428739
                 + o[1]*(0.90572070719733 + 0.70522450087967*o[19])) + f.delta*(f.delta
                *(-0.0221754008730960 + o[1]*(0.094260751665092 + 0.164362784479610*o[
                21]) + f.delta*(-0.0135033722413480*o[1] + f.delta*(-0.0148343453524720
                *o[22] + f.delta*(o[1]*(0.00057922953628084 + 0.0032308904703711*o[21])
                 + f.delta*(0.000080964802996215 - 0.000044923899061815*f.delta*o[22]
                 - 0.000165576797950370*f.tau))))) + (0.107705126263320 + o[1]*(-0.32913623258954
                 - 0.50871062041158*o[20]))*f.tau))))) + 1.06580700285130*
                Modelica.Math.log(f.delta);

              f.fdelta := (1.06580700285130 + f.delta*(o[14] + f.delta*(
                0.76986920373342 + o[31] + f.delta*(-0.83997989096130 + o[1]*(
                4.1699398708380 + o[1]*(-6.0569745070710 + o[16]*(-0.0246442911521889
                 - 1.42788107204769*o[17]))) + f.delta*(0.175936297894000 + o[1]*(-1.77905741714956
                 + o[1]*(3.6228828287893 + 2.82089800351868*o[19])) + f.delta*(f.delta
                *(-0.133052405238576 + o[1]*(0.56556450999055 + 0.98617670687766*o[21])
                 + f.delta*(-0.094523605689436*o[1] + f.delta*(-0.118674762819776*o[
                22] + f.delta*(o[1]*(0.0052130658265276 + 0.0290780142333399*o[21])
                 + f.delta*(0.00080964802996215 - 0.00049416288967996*f.delta*o[22]
                 - 0.00165576797950370*f.tau))))) + (0.53852563131660 + o[1]*(-1.64568116294770
                 - 2.54355310205790*o[20]))*f.tau))))))/f.delta;

              f.fdeltadelta := (-1.06580700285130 + o[32]*(0.76986920373342 + o[31]
                 + f.delta*(-1.67995978192260 + o[1]*(8.3398797416760 + o[1]*(-12.1139490141420
                 + o[16]*(-0.049288582304378 - 2.85576214409538*o[17]))) + f.delta*(
                0.52780889368200 + o[1]*(-5.3371722514487 + o[1]*(10.8686484863680 +
                8.4626940105560*o[19])) + f.delta*(f.delta*(-0.66526202619288 + o[1]*
                (2.82782254995276 + 4.9308835343883*o[21]) + f.delta*(-0.56714163413662
                *o[1] + f.delta*(-0.83072333973843*o[22] + f.delta*(o[1]*(
                0.041704526612220 + 0.232624113866719*o[21]) + f.delta*(
                0.0072868322696594 - 0.0049416288967996*f.delta*o[22] -
                0.0149019118155333*f.tau))))) + (2.15410252526640 + o[1]*(-6.5827246517908
                 - 10.1742124082316*o[20]))*f.tau)))))/o[32];

              f.ftau := 20.9443969743070 + (-15.3735415757432 + o[3]*(
                18.3301634515678 + o[4]*(-28.0807811486200 + o[1]*(14.4640436358204
                 - 0.194503669468755*o[6]))))*f.tau + f.delta*(o[39] + f.delta*(f.tau
                *(-1.70429417648412 + o[2]*(29.3833689251262 + (-21.3518320798755 + o[
                15]*(0.86725181134139 + 3.2651861903201*o[2]))*f.tau)) + f.delta*((
                2.77995991389200 + o[1]*(-8.0759660094280 + o[16]*(-0.131436219478341
                 - 12.3749692910800*o[17])))*f.tau + f.delta*((-0.88952870857478 + o[
                1]*(3.6228828287893 + 18.3358370228714*o[19]))*f.tau + f.delta*(
                0.107705126263320 + o[1]*(-0.98740869776862 - 13.2264761307011*o[20])
                 + f.delta*((0.188521503330184 + 4.2734323964699*o[21])*f.tau + f.delta
                *(-0.0270067444826960*f.tau + f.delta*(-0.38569297916427*o[40] + f.delta
                *(f.delta*(-0.000165576797950370 - 0.00116802137560719*f.delta*o[40])
                 + (0.00115845907256168 + 0.084003152229649*o[21])*f.tau)))))))));

              f.ftautau := -15.3735415757432 + o[3]*(109.980980709407 + o[4]*(-252.727030337580
                 + o[1]*(159.104479994024 - 4.2790807283126*o[6]))) + f.delta*(-2.53086309554280
                 + o[2]*(-34.573223420043 + (185.894192367068 - 174.645121293971*o[1])
                *o[7]) + f.delta*(-1.70429417648412 + o[2]*(146.916844625631 + (-128.110992479253
                 + o[15]*(18.2122880381691 + 81.629654758002*o[2]))*f.tau) + f.delta*
                (2.77995991389200 + o[1]*(-24.2278980282840 + o[16]*(-1.97154329217511
                 - 309.374232277000*o[17])) + f.delta*(-0.88952870857478 + o[1]*(
                10.8686484863680 + 458.39592557179*o[19]) + f.delta*(f.delta*(
                0.188521503330184 + 106.835809911747*o[21] + f.delta*(-0.0270067444826960
                 + f.delta*(-9.6423244791068*o[21] + f.delta*(0.00115845907256168 +
                2.10007880574121*o[21] - 0.0292005343901797*o[21]*o[32])))) + (-1.97481739553724
                 - 330.66190326753*o[20])*f.tau)))));

              f.fdeltatau := o[39] + f.delta*(f.tau*(-3.4085883529682 + o[2]*(
                58.766737850252 + (-42.703664159751 + o[15]*(1.73450362268278 +
                6.5303723806402*o[2]))*f.tau)) + f.delta*((8.3398797416760 + o[1]*(-24.2278980282840
                 + o[16]*(-0.39430865843502 - 37.124907873240*o[17])))*f.tau + f.delta
                *((-3.5581148342991 + o[1]*(14.4915313151573 + 73.343348091486*o[19]))
                *f.tau + f.delta*(0.53852563131660 + o[1]*(-4.9370434888431 -
                66.132380653505*o[20]) + f.delta*((1.13112901998110 +
                25.6405943788192*o[21])*f.tau + f.delta*(-0.189047211378872*f.tau + f.delta
                *(-3.08554383331418*o[40] + f.delta*(f.delta*(-0.00165576797950370 -
                0.0128482351316791*f.delta*o[40]) + (0.0104261316530551 +
                0.75602837006684*o[21])*f.tau))))))));
            end f3;

            function g5 "Base function for region 5: g(p,T)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output Modelica.Media.Common.GibbsDerivs g
                "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          protected
              Real[11] o "Vector of auxiliary variables";
            algorithm
              assert(p > 0.0,
                "IF97 medium function g5 called with too low pressure\n" + "p = " +
                String(p) + " Pa <=  0.0 Pa");
              assert(p <= data.PLIMIT5, "IF97 medium function g5: input pressure (= "
                 + String(p) + " Pa) is higher than 10 MPa in region 5");
              assert(T <= 2273.15, "IF97 medium function g5: input temperature (= "
                 + String(T) + " K) is higher than limit of 2273.15K in region 5");
              g.p := p;
              g.T := T;
              g.R_s := data.RH2O;
              g.pi := p/data.PSTAR5;
              g.tau := data.TSTAR5/T;
              o[1] := g.tau*g.tau;
              o[2] := -0.0045942820899910*o[1];
              o[3] := 0.00217746787145710 + o[2];
              o[4] := o[3]*g.tau;
              o[5] := o[1]*g.tau;
              o[6] := o[1]*o[1];
              o[7] := o[6]*o[6];
              o[8] := o[7]*g.tau;
              o[9] := -7.9449656719138e-6*o[8];
              o[10] := g.pi*g.pi;
              o[11] := -0.0137828462699730*o[1];

              g.g := g.pi*(-0.000125631835895920 + o[4] + g.pi*(-3.9724828359569e-6*o[
                8] + 1.29192282897840e-7*o[5]*g.pi)) + (-0.0248051489334660 + g.tau*(
                0.36901534980333 + g.tau*(-3.11613182139250 + g.tau*(-13.1799836742010
                 + (6.8540841634434 - 0.32961626538917*g.tau)*g.tau +
                Modelica.Math.log(g.pi)))))/o[5];

              g.gpi := (1.0 + g.pi*(-0.000125631835895920 + o[4] + g.pi*(o[9] +
                3.8757684869352e-7*o[5]*g.pi)))/g.pi;

              g.gpipi := (-1.00000000000000 + o[10]*(o[9] + 7.7515369738704e-7*o[5]*g.pi))
                /o[10];

              g.gtau := g.pi*(0.00217746787145710 + o[11] + g.pi*(-0.000035752345523612
                *o[7] + 3.8757684869352e-7*o[1]*g.pi)) + (0.074415446800398 + g.tau*(
                -0.73803069960666 + (3.11613182139250 + o[1]*(6.8540841634434 -
                0.65923253077834*g.tau))*g.tau))/o[6];

              g.gtautau := (-0.297661787201592 + g.tau*(2.21409209881998 + (-6.2322636427850
                 - 0.65923253077834*o[5])*g.tau))/(o[6]*g.tau) + g.pi*(-0.0275656925399460
                *g.tau + g.pi*(-0.000286018764188897*o[1]*o[6]*g.tau +
                7.7515369738704e-7*g.pi*g.tau));

              g.gtaupi := 0.00217746787145710 + o[11] + g.pi*(-0.000071504691047224*o[
                7] + 1.16273054608056e-6*o[1]*g.pi);
            end g5;

            function tph1 "Inverse function for region 1: T(p,h)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.Temperature T "Temperature (K)";
          protected
              Real pi "Dimensionless pressure";
              Real eta1 "Dimensionless specific enthalpy";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              assert(p > triple.ptriple,
                "IF97 medium function tph1 called with too low pressure\n" + "p = "
                 + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              pi := p/data.PSTAR2;
              eta1 := h/data.HSTAR1 + 1.0;
              o[1] := eta1*eta1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              T := -238.724899245210 - 13.3917448726020*pi + eta1*(404.21188637945 +
                43.211039183559*pi + eta1*(113.497468817180 - 54.010067170506*pi +
                eta1*(30.5358922039160*pi + eta1*(-6.5964749423638*pi + o[1]*(-5.8457616048039
                 + o[2]*(pi*(0.0093965400878363 + (-0.0000258586412820730 +
                6.6456186191635e-8*pi)*pi) + o[2]*o[3]*(-0.000152854824131400 + o[1]*
                o[3]*(-1.08667076953770e-6 + pi*(1.15736475053400e-7 + pi*(-4.0644363084799e-9
                 + pi*(8.0670734103027e-11 + pi*(-9.3477771213947e-13 + (
                5.8265442020601e-15 - 1.50201859535030e-17*pi)*pi))))))))))));
            end tph1;

            function tps1 "Inverse function for region 1: T(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              output SI.Temperature T "Temperature (K)";
          protected
              constant SI.Pressure pstar=1.0e6;
              constant SI.SpecificEntropy sstar=1.0e3;
              Real pi "Dimensionless pressure";
              Real sigma1 "Dimensionless specific entropy";
              Real[6] o "Vector of auxiliary variables";
            algorithm
              pi := p/pstar;
              assert(p > triple.ptriple,
                "IF97 medium function tps1 called with too low pressure\n" + "p = "
                 + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");

              sigma1 := s/sstar + 2.0;
              o[1] := sigma1*sigma1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              o[4] := o[3]*o[3];
              o[5] := o[4]*o[4];
              o[6] := o[1]*o[2]*o[4];

              T := 174.782680583070 + sigma1*(34.806930892873 + sigma1*(
                6.5292584978455 + (0.33039981775489 + o[3]*(-1.92813829231960e-7 -
                2.49091972445730e-23*o[2]*o[4]))*sigma1)) + pi*(-0.261076364893320 +
                pi*(0.00056608900654837 + pi*(o[1]*o[3]*(2.64004413606890e-13 +
                7.8124600459723e-29*o[6]) - 3.07321999036680e-31*o[5]*pi) + sigma1*(-0.00032635483139717
                 + sigma1*(0.000044778286690632 + o[1]*o[2]*(-5.1322156908507e-10 -
                4.2522657042207e-26*o[6])*sigma1))) + sigma1*(0.225929659815860 +
                sigma1*(-0.064256463395226 + sigma1*(0.0078876289270526 + o[3]*sigma1
                *(3.5672110607366e-10 + 1.73324969948950e-24*o[1]*o[4]*sigma1)))));
            end tps1;

            function tph2 "Reverse function for region 2: T(p,h)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.Temperature T "Temperature (K)";
          protected
              Real pi "Dimensionless pressure";
              Real pi2b "Dimensionless pressure";
              Real pi2c "Dimensionless pressure";
              Real eta "Dimensionless specific enthalpy";
              Real etabc "Dimensionless specific enthalpy";
              Real eta2a "Dimensionless specific enthalpy";
              Real eta2b "Dimensionless specific enthalpy";
              Real eta2c "Dimensionless specific enthalpy";
              Real[8] o "Vector of auxiliary variables";
            algorithm
              pi := p*data.IPSTAR;
              eta := h*data.IHSTAR;
              etabc := h*1.0e-3;
              if (pi < 4.0) then
                eta2a := eta - 2.1;
                o[1] := eta2a*eta2a;
                o[2] := o[1]*o[1];
                o[3] := pi*pi;
                o[4] := o[3]*o[3];
                o[5] := o[3]*pi;
                T := 1089.89523182880 + (1.84457493557900 - 0.0061707422868339*pi)*pi
                   + eta2a*(849.51654495535 - 4.1792700549624*pi + eta2a*(-107.817480918260
                   + (6.2478196935812 - 0.310780466295830*pi)*pi + eta2a*(
                  33.153654801263 - 17.3445631081140*pi + o[2]*(-7.4232016790248 + pi
                  *(-200.581768620960 + 11.6708730771070*pi) + o[1]*(271.960654737960
                  *pi + o[1]*(-455.11318285818*pi + eta2a*(1.38657242832260*o[4] + o[
                  1]*o[2]*(3091.96886047550*pi + o[1]*(11.7650487243560 + o[2]*(-13551.3342407750
                  *o[5] + o[2]*(-62.459855192507*o[3]*o[4]*pi + o[2]*(o[4]*(
                  235988.325565140 + 7399.9835474766*pi) + o[1]*(19127.7292396600*o[3]
                  *o[4] + o[1]*(o[3]*(1.28127984040460e8 - 551966.97030060*o[5]) + o[
                  1]*(-9.8554909623276e8*o[3] + o[1]*(2.82245469730020e9*o[3] + o[1]*
                  (o[3]*(-3.5948971410703e9 + 3.7154085996233e6*o[5]) + o[1]*pi*(
                  252266.403578720 + pi*(1.72273499131970e9 + pi*(1.28487346646500e7
                   + (-1.31052365450540e7 - 415351.64835634*o[3])*pi))))))))))))))))))));
              elseif (pi < (0.12809002730136e-03*etabc - 0.67955786399241)*etabc +
                  0.90584278514723e3) then
                eta2b := eta - 2.6;
                pi2b := pi - 2.0;
                o[1] := pi2b*pi2b;
                o[2] := o[1]*pi2b;
                o[3] := o[1]*o[1];
                o[4] := eta2b*eta2b;
                o[5] := o[4]*o[4];
                o[6] := o[4]*o[5];
                o[7] := o[5]*o[5];
                T := 1489.50410795160 + 0.93747147377932*pi2b + eta2b*(
                  743.07798314034 + o[2]*(0.000110328317899990 - 1.75652339694070e-18
                  *o[1]*o[3]) + eta2b*(-97.708318797837 + pi2b*(3.3593118604916 +
                  pi2b*(-0.0218107553247610 + pi2b*(0.000189552483879020 + (
                  2.86402374774560e-7 - 8.1456365207833e-14*o[2])*pi2b))) + o[5]*(
                  3.3809355601454*pi2b + o[4]*(-0.108297844036770*o[1] + o[5]*(
                  2.47424647056740 + (0.168445396719040 + o[1]*(0.00308915411605370
                   - 0.0000107798573575120*pi2b))*pi2b + o[6]*(-0.63281320016026 +
                  pi2b*(0.73875745236695 + (-0.046333324635812 + o[1]*(-0.000076462712454814
                   + 2.82172816350400e-7*pi2b))*pi2b) + o[6]*(1.13859521296580 + pi2b
                  *(-0.47128737436186 + o[1]*(0.00135555045549490 + (
                  0.0000140523928183160 + 1.27049022719450e-6*pi2b)*pi2b)) + o[5]*(-0.47811863648625
                   + (0.150202731397070 + o[2]*(-0.0000310838143314340 + o[1]*(-1.10301392389090e-8
                   - 2.51805456829620e-11*pi2b)))*pi2b + o[5]*o[7]*(
                  0.0085208123431544 + pi2b*(-0.00217641142197500 + pi2b*(
                  0.000071280351959551 + o[1]*(-1.03027382121030e-6 + (
                  7.3803353468292e-8 + 8.6934156344163e-15*o[3])*pi2b))))))))))));
              else
                eta2c := eta - 1.8;
                pi2c := pi + 25.0;
                o[1] := pi2c*pi2c;
                o[2] := o[1]*o[1];
                o[3] := o[1]*o[2]*pi2c;
                o[4] := 1/o[3];
                o[5] := o[1]*o[2];
                o[6] := eta2c*eta2c;
                o[7] := o[2]*o[2];
                o[8] := o[6]*o[6];
                T := eta2c*((859777.22535580 + o[1]*(482.19755109255 +
                  1.12615974072300e-12*o[5]))/o[1] + eta2c*((-5.8340131851590e11 + (
                  2.08255445631710e10 + 31081.0884227140*o[2])*pi2c)/o[5] + o[6]*(o[8]
                  *(o[6]*(1.23245796908320e-7*o[5] + o[6]*(-1.16069211309840e-6*o[5]
                   + o[8]*(0.0000278463670885540*o[5] + (-0.00059270038474176*o[5] +
                  0.00129185829918780*o[5]*o[6])*o[8]))) - 10.8429848800770*pi2c) + o[
                  4]*(7.3263350902181e12 + o[7]*(3.7966001272486 + (-0.045364172676660
                   - 1.78049822406860e-11*o[2])*pi2c))))) + o[4]*(-3.2368398555242e12
                   + pi2c*(3.5825089945447e11 + pi2c*(-1.07830682174700e10 + o[1]*
                  pi2c*(610747.83564516 + pi2c*(-25745.7236041700 + (1208.23158659360
                   + 1.45591156586980e-13*o[5])*pi2c)))));
              end if;
            end tph2;

            function tps2a "Reverse function for region 2a: T(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              output SI.Temperature T "Temperature (K)";
          protected
              Real[12] o "Vector of auxiliary variables";
              constant Real IPSTAR=1.0e-6 "Scaling variable";
              constant Real ISSTAR2A=1/2000.0 "Scaling variable";
              Real pi "Dimensionless pressure";
              Real sigma2a "Dimensionless specific entropy";
            algorithm
              pi := p*IPSTAR;
              sigma2a := s*ISSTAR2A - 2.0;
              o[1] := pi^0.5;
              o[2] := sigma2a*sigma2a;
              o[3] := o[2]*o[2];
              o[4] := o[3]*o[3];
              o[5] := o[4]*o[4];
              o[6] := pi^0.25;
              o[7] := o[2]*o[4]*o[5];
              o[8] := 1/o[7];
              o[9] := o[3]*sigma2a;
              o[10] := o[2]*o[3]*sigma2a;
              o[11] := o[3]*o[4]*sigma2a;
              o[12] := o[2]*sigma2a;
              T := ((-392359.83861984 + (515265.73827270 + o[3]*(40482.443161048 + o[
                2]*o[3]*(-321.93790923902 + o[2]*(96.961424218694 - 22.8678463717730*
                sigma2a))))*sigma2a)/(o[4]*o[5]) + o[6]*((-449429.14124357 + o[3]*(-5011.8336020166
                 + 0.35684463560015*o[4]*sigma2a))/(o[2]*o[5]*sigma2a) + o[6]*(o[8]*(
                44235.335848190 + o[9]*(-13673.3888117080 + o[3]*(421632.60207864 + (
                22516.9258374750 + o[10]*(474.42144865646 - 149.311307976470*sigma2a))
                *sigma2a))) + o[6]*((-197811.263204520 - 23554.3994707600*sigma2a)/(o[
                2]*o[3]*o[4]*sigma2a) + o[6]*((-19070.6163020760 + o[11]*(
                55375.669883164 + (3829.3691437363 - 603.91860580567*o[2])*o[3]))*o[8]
                 + o[6]*((1936.31026203310 + o[2]*(4266.0643698610 + o[2]*o[3]*o[4]*(
                -5978.0638872718 - 704.01463926862*o[9])))/(o[2]*o[4]*o[5]*sigma2a)
                 + o[1]*((338.36784107553 + o[12]*(20.8627866351870 + (
                0.033834172656196 - 0.000043124428414893*o[12])*o[3]))*sigma2a + o[6]
                *(166.537913564120 + sigma2a*(-139.862920558980 + o[3]*(-0.78849547999872
                 + (0.072132411753872 + o[3]*(-0.0059754839398283 + (-0.0000121413589539040
                 + 2.32270967338710e-7*o[2])*o[3]))*sigma2a)) + o[6]*(-10.5384635661940
                 + o[3]*(2.07189254965020 + (-0.072193155260427 + 2.07498870811200e-7
                *o[4])*o[9]) + o[6]*(o[6]*(o[12]*(0.210375278936190 +
                0.000256812397299990*o[3]*o[4]) + (-0.0127990029337810 -
                8.2198102652018e-6*o[11])*o[6]*o[9]) + o[10]*(-0.0183406579113790 +
                2.90362723486960e-7*o[2]*o[4]*sigma2a)))))))))))/(o[1]*pi);
            end tps2a;

            function tps2b "Reverse function for region 2b: T(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              output SI.Temperature T "Temperature (K)";
          protected
              Real[8] o "Vector of auxiliary variables";
              constant Real IPSTAR=1.0e-6 "Scaling variable";
              constant Real ISSTAR2B=1/785.3 "Scaling variable";
              Real pi "Dimensionless pressure";
              Real sigma2b "Dimensionless specific entropy";
            algorithm
              pi := p*IPSTAR;
              sigma2b := 10.0 - s*ISSTAR2B;
              o[1] := pi*pi;
              o[2] := o[1]*o[1];
              o[3] := sigma2b*sigma2b;
              o[4] := o[3]*o[3];
              o[5] := o[4]*o[4];
              o[6] := o[3]*o[5]*sigma2b;
              o[7] := o[3]*o[5];
              o[8] := o[3]*sigma2b;
              T := (316876.65083497 + 20.8641758818580*o[6] + pi*(-398593.99803599 -
                21.8160585188770*o[6] + pi*(223697.851942420 + (-2784.17034458170 +
                9.9207436071480*o[7])*sigma2b + pi*(-75197.512299157 + (
                2970.86059511580 + o[7]*(-3.4406878548526 + 0.38815564249115*sigma2b))
                *sigma2b + pi*(17511.2950857500 + sigma2b*(-1423.71128544490 + (
                1.09438033641670 + 0.89971619308495*o[4])*o[4]*sigma2b) + pi*(-3375.9740098958
                 + (471.62885818355 + o[4]*(-1.91882419936790 + o[8]*(
                0.41078580492196 - 0.33465378172097*sigma2b)))*sigma2b + pi*(
                1387.00347775050 + sigma2b*(-406.63326195838 + sigma2b*(
                41.727347159610 + o[3]*(2.19325494345320 + sigma2b*(-1.03200500090770
                 + (0.35882943516703 + 0.0052511453726066*o[8])*sigma2b)))) + pi*(
                12.8389164507050 + sigma2b*(-2.86424372193810 + sigma2b*(
                0.56912683664855 + (-0.099962954584931 + o[4]*(-0.0032632037778459 +
                0.000233209225767230*sigma2b))*sigma2b)) + pi*(-0.153348098574500 + (
                0.0290722882399020 + 0.00037534702741167*o[4])*sigma2b + pi*(
                0.00172966917024110 + (-0.00038556050844504 - 0.000035017712292608*o[
                3])*sigma2b + pi*(-0.0000145663936314920 + 5.6420857267269e-6*sigma2b
                 + pi*(4.1286150074605e-8 + (-2.06846711188240e-8 +
                1.64093936747250e-9*sigma2b)*sigma2b))))))))))))/(o[1]*o[2]);
            end tps2b;

            function tps2c "Reverse function for region 2c: T(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              output SI.Temperature T "Temperature (K)";
          protected
              constant Real IPSTAR=1.0e-6 "Scaling variable";
              constant Real ISSTAR2C=1/2925.1 "Scaling variable";
              Real pi "Dimensionless pressure";
              Real sigma2c "Dimensionless specific entropy";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              pi := p*IPSTAR;
              sigma2c := 2.0 - s*ISSTAR2C;
              o[1] := pi*pi;
              o[2] := sigma2c*sigma2c;
              o[3] := o[2]*o[2];
              T := (909.68501005365 + 2404.56670884200*sigma2c + pi*(-591.62326387130
                 + pi*(541.45404128074 + sigma2c*(-270.983084111920 + (
                979.76525097926 - 469.66772959435*sigma2c)*sigma2c) + pi*(
                14.3992746047230 + (-19.1042042304290 + o[2]*(5.3299167111971 -
                21.2529753759340*sigma2c))*sigma2c + pi*(-0.311473344137600 + (
                0.60334840894623 - 0.042764839702509*sigma2c)*sigma2c + pi*(
                0.0058185597255259 + (-0.0145970082847530 + 0.0056631175631027*o[3])*
                sigma2c + pi*(-0.000076155864584577 + sigma2c*(0.000224403429193320
                 - 0.0000125610950134130*o[2]*sigma2c) + pi*(6.3323132660934e-7 + (-2.05419896753750e-6
                 + 3.6405370390082e-8*sigma2c)*sigma2c + pi*(-2.97598977892150e-9 +
                1.01366185297630e-8*sigma2c + pi*(5.9925719692351e-12 + sigma2c*(-2.06778701051640e-11
                 + o[2]*(-2.08742781818860e-11 + (1.01621668250890e-10 -
                1.64298282813470e-10*sigma2c)*sigma2c))))))))))))/o[1];
            end tps2c;

            function tps2 "Reverse function for region 2: T(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              output SI.Temperature T "Temperature (K)";
          protected
              Real pi "Dimensionless pressure";
              constant SI.SpecificEntropy SLIMIT=5.85e3
                "Subregion boundary specific entropy between regions 2a and 2b";
            algorithm
              if p < 4.0e6 then
                T := tps2a(p, s);
              elseif s > SLIMIT then
                T := tps2b(p, s);
              else
                T := tps2c(p, s);
              end if;
            end tps2;

            function tsat "Region 4 saturation temperature as a function of pressure"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.Temperature t_sat "Temperature";
          protected
              Real pi "Dimensionless pressure";
              Real[20] o "Vector of auxiliary variables";
            algorithm
              assert(p > triple.ptriple,
                "IF97 medium function tsat called with too low pressure\n" + "p = "
                 + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              //  assert(p <= data.PCRIT,
              //    "tsat: input pressure is higher than the critical point pressure");
              pi := min(p, data.PCRIT)*data.IPSTAR;
              o[1] := pi^0.25;
              o[2] := -3.2325550322333e6*o[1];
              o[3] := pi^0.5;
              o[4] := -724213.16703206*o[3];
              o[5] := 405113.40542057 + o[2] + o[4];
              o[6] := -17.0738469400920*o[1];
              o[7] := 14.9151086135300 + o[3] + o[6];
              o[8] := -4.0*o[5]*o[7];
              o[9] := 12020.8247024700*o[1];
              o[10] := 1167.05214527670*o[3];
              o[11] := -4823.2657361591 + o[10] + o[9];
              o[12] := o[11]*o[11];
              o[13] := o[12] + o[8];
              o[14] := o[13]^0.5;
              o[15] := -o[14];
              o[16] := -12020.8247024700*o[1];
              o[17] := -1167.05214527670*o[3];
              o[18] := 4823.2657361591 + o[15] + o[16] + o[17];
              o[19] := 1/o[18];
              o[20] := 2.0*o[19]*o[5];

              t_sat := 0.5*(650.17534844798 + o[20] - (-4.0*(-0.238555575678490 +
                1300.35069689596*o[19]*o[5]) + (650.17534844798 + o[20])^2.0)^0.5);
              annotation (derivative=tsat_der);
            end tsat;

            function dtsatofp "Derivative of saturation temperature w.r.t. pressure"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output Real dtsat(unit="K/Pa") "Derivative of T w.r.t. p";
          protected
              Real pi "Dimensionless pressure";
              Real[49] o "Vector of auxiliary variables";
            algorithm
              pi := max(Modelica.Constants.small, p*data.IPSTAR);
              o[1] := pi^0.75;
              o[2] := 1/o[1];
              o[3] := -4.268461735023*o[2];
              o[4] := sqrt(pi);
              o[5] := 1/o[4];
              o[6] := 0.5*o[5];
              o[7] := o[3] + o[6];
              o[8] := pi^0.25;
              o[9] := -3.2325550322333e6*o[8];
              o[10] := -724213.16703206*o[4];
              o[11] := 405113.40542057 + o[10] + o[9];
              o[12] := -4*o[11]*o[7];
              o[13] := -808138.758058325*o[2];
              o[14] := -362106.58351603*o[5];
              o[15] := o[13] + o[14];
              o[16] := -17.073846940092*o[8];
              o[17] := 14.91510861353 + o[16] + o[4];
              o[18] := -4*o[15]*o[17];
              o[19] := 3005.2061756175*o[2];
              o[20] := 583.52607263835*o[5];
              o[21] := o[19] + o[20];
              o[22] := 12020.82470247*o[8];
              o[23] := 1167.0521452767*o[4];
              o[24] := -4823.2657361591 + o[22] + o[23];
              o[25] := 2.0*o[21]*o[24];
              o[26] := o[12] + o[18] + o[25];
              o[27] := -4.0*o[11]*o[17];
              o[28] := o[24]*o[24];
              o[29] := o[27] + o[28];
              o[30] := sqrt(o[29]);
              o[31] := 1/o[30];
              o[32] := (-o[30]);
              o[33] := -12020.82470247*o[8];
              o[34] := -1167.0521452767*o[4];
              o[35] := 4823.2657361591 + o[32] + o[33] + o[34];
              o[36] := o[30];
              o[37] := -4823.2657361591 + o[22] + o[23] + o[36];
              o[38] := o[37]*o[37];
              o[39] := 1/o[38];
              o[40] := -1.72207339365771*o[30];
              o[41] := 21592.2055343628*o[8];
              o[42] := o[30]*o[8];
              o[43] := -8192.87114842946*o[4];
              o[44] := -0.510632954559659*o[30]*o[4];
              o[45] := -3100.02526152368*o[1];
              o[46] := pi;
              o[47] := 1295.95640782102*o[46];
              o[48] := 2862.09212505088 + o[40] + o[41] + o[42] + o[43] + o[44] + o[
                45] + o[47];
              o[49] := 1/(o[35]*o[35]);
              dtsat := data.IPSTAR*0.5*((2.0*o[15])/o[35] - 2.*o[11]*(-3005.2061756175
                *o[2] - 0.5*o[26]*o[31] - 583.52607263835*o[5])*o[49] - (
                20953.46356643991*(o[39]*(1295.95640782102 + 5398.05138359071*o[2] +
                0.25*o[2]*o[30] - 0.861036696828853*o[26]*o[31] - 0.255316477279829*o[
                26]*o[31]*o[4] - 4096.43557421473*o[5] - 0.255316477279829*o[30]*o[5]
                 - 2325.01894614276/o[8] + 0.5*o[26]*o[31]*o[8]) - 2.0*(o[19] + o[20]
                 + 0.5*o[26]*o[31])*o[48]*o[37]^(-3)))/sqrt(o[39]*o[48]));
            end dtsatofp;

            function tsat_der "Derivative function for tsat"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input Real der_p(unit="Pa/s") "Pressure derivative";
              output Real der_tsat(unit="K/s") "Temperature derivative";
          protected
              Real dtp;
            algorithm
              dtp := dtsatofp(p);
              der_tsat := dtp*der_p;
            end tsat_der;

            function psat "Region 4 saturation pressure as a function of temperature"

              extends Modelica.Icons.Function;
              input SI.Temperature T "Temperature (K)";
              output SI.Pressure p_sat "Pressure";
          protected
              Real[8] o "Vector of auxiliary variables";
              Real Tlim=min(T, data.TCRIT);
            algorithm
              assert(T >= 273.16, "IF97 medium function psat: input temperature (= "
                 + String(triple.Ttriple) + " K).\n" +
                "lower than the triple point temperature 273.16 K");
              o[1] := -650.17534844798 + Tlim;
              o[2] := 1/o[1];
              o[3] := -0.238555575678490*o[2];
              o[4] := o[3] + Tlim;
              o[5] := -4823.2657361591*o[4];
              o[6] := o[4]*o[4];
              o[7] := 14.9151086135300*o[6];
              o[8] := 405113.40542057 + o[5] + o[7];
              p_sat := 16.0e6*o[8]*o[8]*o[8]*o[8]*1/(3.2325550322333e6 -
                12020.8247024700*o[4] + 17.0738469400920*o[6] + (-4.0*(-724213.16703206
                 + 1167.05214527670*o[4] + o[6])*o[8] + (-3.2325550322333e6 +
                12020.8247024700*o[4] - 17.0738469400920*o[6])^2.0)^0.5)^4.0;
              annotation (derivative=psat_der);
            end psat;

            function dptofT
              "Derivative of pressure w.r.t. temperature along the saturation pressure curve"

              extends Modelica.Icons.Function;
              input SI.Temperature T "Temperature (K)";
              output Real dpt(unit="Pa/K") "Temperature derivative of pressure";
          protected
              Real[31] o "Vector of auxiliary variables";
              Real Tlim "Temperature limited to TCRIT";
            algorithm
              Tlim := min(T, data.TCRIT);
              o[1] := -650.17534844798 + Tlim;
              o[2] := 1/o[1];
              o[3] := -0.238555575678490*o[2];
              o[4] := o[3] + Tlim;
              o[5] := -4823.2657361591*o[4];
              o[6] := o[4]*o[4];
              o[7] := 14.9151086135300*o[6];
              o[8] := 405113.40542057 + o[5] + o[7];
              o[9] := o[8]*o[8];
              o[10] := o[9]*o[9];
              o[11] := o[1]*o[1];
              o[12] := 1/o[11];
              o[13] := 0.238555575678490*o[12];
              o[14] := 1.00000000000000 + o[13];
              o[15] := 12020.8247024700*o[4];
              o[16] := -17.0738469400920*o[6];
              o[17] := -3.2325550322333e6 + o[15] + o[16];
              o[18] := -4823.2657361591*o[14];
              o[19] := 29.8302172270600*o[14]*o[4];
              o[20] := o[18] + o[19];
              o[21] := 1167.05214527670*o[4];
              o[22] := -724213.16703206 + o[21] + o[6];
              o[23] := o[17]*o[17];
              o[24] := -4.0000000000000*o[22]*o[8];
              o[25] := o[23] + o[24];
              o[26] := sqrt(o[25]);
              o[27] := -12020.8247024700*o[4];
              o[28] := 17.0738469400920*o[6];
              o[29] := 3.2325550322333e6 + o[26] + o[27] + o[28];
              o[30] := o[29]*o[29];
              o[31] := o[30]*o[30];
              dpt := 1e6*((-64.0*o[10]*(-12020.8247024700*o[14] + 34.147693880184*o[
                14]*o[4] + (0.5*(-4.0*o[20]*o[22] + 2.00000000000000*o[17]*(
                12020.8247024700*o[14] - 34.147693880184*o[14]*o[4]) - 4.0*(
                1167.05214527670*o[14] + 2.0*o[14]*o[4])*o[8]))/o[26]))/(o[29]*o[31])
                 + (64.*o[20]*o[8]*o[9])/o[31]);
            end dptofT;

            function psat_der "Derivative function for psat"
              extends Modelica.Icons.Function;
              input SI.Temperature T "Temperature (K)";
              input Real der_T(unit="K/s") "Temperature derivative";
              output Real der_psat(unit="Pa/s") "Pressure";
          protected
              Real dpt;
            algorithm
              dpt := dptofT(T);
              der_psat := dpt*der_T;
            end psat_der;

            function h3ab_p "Region 3 a b boundary for pressure/enthalpy"
              extends Modelica.Icons.Function;
              output SI.SpecificEnthalpy h "Enthalpy";
              input SI.Pressure p "Pressure";
          protected
              constant Real[:] n={0.201464004206875e4,0.374696550136983e1,-0.219921901054187e-1,
                  0.875131686009950e-4};
              constant SI.SpecificEnthalpy hstar=1000 "Normalization enthalpy";
              constant SI.Pressure pstar=1e6 "Normalization pressure";
              Real pi=p/pstar "Normalized specific pressure";

            algorithm
              h := (n[1] + n[2]*pi + n[3]*pi^2 + n[4]*pi^3)*hstar;
              annotation (Documentation(info="<html>
      <p>
      &nbsp;Equation number 1 from:
      </p>
      <div style=\"text-align: center;\">&nbsp;[1] The international Association
      for the Properties of Water and Steam<br>
      &nbsp;Vejle, Denmark<br>
      &nbsp;August 2003<br>
      &nbsp;Supplementary Release on Backward Equations for the Functions
      T(p,h), v(p,h) and T(p,s),<br>
      &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
      the Thermodynamic Properties of<br>
      &nbsp;Water and Steam</div>
      </html>"));
            end h3ab_p;

            function T3a_ph "Region 3 a: inverse function T(p,h)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.Temperature T "Temperature";
          protected
              constant Real[:] n={-0.133645667811215e-6,0.455912656802978e-5,-0.146294640700979e-4,
                  0.639341312970080e-2,0.372783927268847e3,-0.718654377460447e4,
                  0.573494752103400e6,-0.267569329111439e7,-0.334066283302614e-4,-0.245479214069597e-1,
                  0.478087847764996e2,0.764664131818904e-5,0.128350627676972e-2,
                  0.171219081377331e-1,-0.851007304583213e1,-0.136513461629781e-1,-0.384460997596657e-5,
                  0.337423807911655e-2,-0.551624873066791,0.729202277107470,-0.992522757376041e-2,
                  -0.119308831407288,0.793929190615421,0.454270731799386,
                  0.209998591259910,-0.642109823904738e-2,-0.235155868604540e-1,
                  0.252233108341612e-2,-0.764885133368119e-2,0.136176427574291e-1,-0.133027883575669e-1};
              constant Real[:] I={-12,-12,-12,-12,-12,-12,-12,-12,-10,-10,-10,-8,-8,-8,
                  -8,-5,-3,-2,-2,-2,-1,-1,0,0,1,3,3,4,4,10,12};
              constant Real[:] J={0,1,2,6,14,16,20,22,1,5,12,0,2,4,10,2,0,1,3,4,0,2,0,
                  1,1,0,1,0,3,4,5};
              constant SI.SpecificEnthalpy hstar=2300e3 "Normalization enthalpy";
              constant SI.Pressure pstar=100e6 "Normalization pressure";
              constant SI.Temperature Tstar=760 "Normalization temperature";
              Real pi=p/pstar "Normalized specific pressure";
              Real eta=h/hstar "Normalized specific enthalpy";
            algorithm
              T := sum(n[i]*(pi + 0.240)^I[i]*(eta - 0.615)^J[i] for i in 1:31)*Tstar;
              annotation (Documentation(info="<html>
<p>
 &nbsp;Equation number 2 from:
</p>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Functions
 T(p,h), v(p,h) and T(p,s),<br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </html>"));
            end T3a_ph;

            function T3b_ph "Region 3 b: inverse function T(p,h)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.Temperature T "Temperature";
          protected
              constant Real[:] n={0.323254573644920e-4,-0.127575556587181e-3,-0.475851877356068e-3,
                  0.156183014181602e-2,0.105724860113781,-0.858514221132534e2,
                  0.724140095480911e3,0.296475810273257e-2,-0.592721983365988e-2,-0.126305422818666e-1,
                  -0.115716196364853,0.849000969739595e2,-0.108602260086615e-1,
                  0.154304475328851e-1,0.750455441524466e-1,0.252520973612982e-1,-0.602507901232996e-1,
                  -0.307622221350501e1,-0.574011959864879e-1,0.503471360939849e1,-0.925081888584834,
                  0.391733882917546e1,-0.773146007130190e2,0.949308762098587e4,-0.141043719679409e7,
                  0.849166230819026e7,0.861095729446704,0.323346442811720,
                  0.873281936020439,-0.436653048526683,0.286596714529479,-0.131778331276228,
                  0.676682064330275e-2};
              constant Real[:] I={-12,-12,-10,-10,-10,-10,-10,-8,-8,-8,-8,-8,-6,-6,-6,
                  -4,-4,-3,-2,-2,-1,-1,-1,-1,-1,-1,0,0,1,3,5,6,8};
              constant Real[:] J={0,1,0,1,5,10,12,0,1,2,4,10,0,1,2,0,1,5,0,4,2,4,6,10,
                  14,16,0,2,1,1,1,1,1};
              constant SI.Temperature Tstar=860 "Normalization temperature";
              constant SI.Pressure pstar=100e6 "Normalization pressure";
              constant SI.SpecificEnthalpy hstar=2800e3 "Normalization enthalpy";
              Real pi=p/pstar "Normalized specific pressure";
              Real eta=h/hstar "Normalized specific enthalpy";
            algorithm
              T := sum(n[i]*(pi + 0.298)^I[i]*(eta - 0.720)^J[i] for i in 1:33)*Tstar;
              annotation (Documentation(info="<html>
 <p>
 &nbsp;Equation number 3 from:
</p>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Functions
 T(p,h), v(p,h) and T(p,s),<br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </html>"));
            end T3b_ph;

            function v3a_ph "Region 3 a: inverse function v(p,h)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.SpecificVolume v "Specific volume";
          protected
              constant Real[:] n={0.529944062966028e-2,-0.170099690234461,
                  0.111323814312927e2,-0.217898123145125e4,-0.506061827980875e-3,
                  0.556495239685324,-0.943672726094016e1,-0.297856807561527,
                  0.939353943717186e2,0.192944939465981e-1,0.421740664704763,-0.368914126282330e7,
                  -0.737566847600639e-2,-0.354753242424366,-0.199768169338727e1,
                  0.115456297059049e1,0.568366875815960e4,0.808169540124668e-2,
                  0.172416341519307,0.104270175292927e1,-0.297691372792847,
                  0.560394465163593,0.275234661176914,-0.148347894866012,-0.651142513478515e-1,
                  -0.292468715386302e1,0.664876096952665e-1,0.352335014263844e1,-0.146340792313332e-1,
                  -0.224503486668184e1,0.110533464706142e1,-0.408757344495612e-1};
              constant Real[:] I={-12,-12,-12,-12,-10,-10,-10,-8,-8,-6,-6,-6,-4,-4,-3,
                  -2,-2,-1,-1,-1,-1,0,0,1,1,1,2,2,3,4,5,8};
              constant Real[:] J={6,8,12,18,4,7,10,5,12,3,4,22,2,3,7,3,16,0,1,2,3,0,1,
                  0,1,2,0,2,0,2,2,2};
              constant SI.Volume vstar=0.0028 "Normalization temperature";
              constant SI.Pressure pstar=100e6 "Normalization pressure";
              constant SI.SpecificEnthalpy hstar=2100e3 "Normalization enthalpy";
              Real pi=p/pstar "Normalized specific pressure";
              Real eta=h/hstar "Normalized specific enthalpy";
            algorithm
              v := sum(n[i]*(pi + 0.128)^I[i]*(eta - 0.727)^J[i] for i in 1:32)*vstar;
              annotation (Documentation(info="<html>
<p>
&nbsp;Equation number 4 from:
</p>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Functions
 T(p,h), v(p,h) and T(p,s),<br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </html>"));
            end v3a_ph;

            function v3b_ph "Region 3 b: inverse function v(p,h)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.SpecificVolume v "Specific volume";
          protected
              constant Real[:] n={-0.225196934336318e-8,0.140674363313486e-7,
                  0.233784085280560e-5,-0.331833715229001e-4,0.107956778514318e-2,-0.271382067378863,
                  0.107202262490333e1,-0.853821329075382,-0.215214194340526e-4,
                  0.769656088222730e-3,-0.431136580433864e-2,0.453342167309331,-0.507749535873652,
                  -0.100475154528389e3,-0.219201924648793,-0.321087965668917e1,
                  0.607567815637771e3,0.557686450685932e-3,0.187499040029550,
                  0.905368030448107e-2,0.285417173048685,0.329924030996098e-1,
                  0.239897419685483,0.482754995951394e1,-0.118035753702231e2,
                  0.169490044091791,-0.179967222507787e-1,0.371810116332674e-1,-0.536288335065096e-1,
                  0.160697101092520e1};
              constant Real[:] I={-12,-12,-8,-8,-8,-8,-8,-8,-6,-6,-6,-6,-6,-6,-4,-4,-4,
                  -3,-3,-2,-2,-1,-1,-1,-1,0,1,1,2,2};
              constant Real[:] J={0,1,0,1,3,6,7,8,0,1,2,5,6,10,3,6,10,0,2,1,2,0,1,4,5,
                  0,0,1,2,6};
              constant SI.Volume vstar=0.0088 "Normalization temperature";
              constant SI.Pressure pstar=100e6 "Normalization pressure";
              constant SI.SpecificEnthalpy hstar=2800e3 "Normalization enthalpy";
              Real pi=p/pstar "Normalized specific pressure";
              Real eta=h/hstar "Normalized specific enthalpy";
            algorithm
              v := sum(n[i]*(pi + 0.0661)^I[i]*(eta - 0.720)^J[i] for i in 1:30)*
                vstar;
              annotation (Documentation(info="<html>
<p>
 &nbsp;Equation number 5 from:
</p>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Functions
 T(p,h), v(p,h) and T(p,s),<br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </html>"));
            end v3b_ph;

            function T3a_ps "Region 3 a: inverse function T(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              output SI.Temperature T "Temperature";
          protected
              constant Real[:] n={0.150042008263875e10,-0.159397258480424e12,
                  0.502181140217975e-3,-0.672057767855466e2,0.145058545404456e4,-0.823889534888890e4,
                  -0.154852214233853,0.112305046746695e2,-0.297000213482822e2,
                  0.438565132635495e11,0.137837838635464e-2,-0.297478527157462e1,
                  0.971777947349413e13,-0.571527767052398e-4,0.288307949778420e5,-0.744428289262703e14,
                  0.128017324848921e2,-0.368275545889071e3,0.664768904779177e16,
                  0.449359251958880e-1,-0.422897836099655e1,-0.240614376434179,-0.474341365254924e1,
                  0.724093999126110,0.923874349695897,0.399043655281015e1,
                  0.384066651868009e-1,-0.359344365571848e-2,-0.735196448821653,
                  0.188367048396131,0.141064266818704e-3,-0.257418501496337e-2,
                  0.123220024851555e-2};
              constant Real[:] I={-12,-12,-10,-10,-10,-10,-8,-8,-8,-8,-6,-6,-6,-5,-5,
                  -5,-4,-4,-4,-2,-2,-1,-1,0,0,0,1,2,2,3,8,8,10};
              constant Real[:] J={28,32,4,10,12,14,5,7,8,28,2,6,32,0,14,32,6,10,36,1,
                  4,1,6,0,1,4,0,0,3,2,0,1,2};
              constant SI.Temperature Tstar=760 "Normalization temperature";
              constant SI.Pressure pstar=100e6 "Normalization pressure";
              constant SI.SpecificEntropy sstar=4.4e3 "Normalization entropy";
              Real pi=p/pstar "Normalized specific pressure";
              Real sigma=s/sstar "Normalized specific entropy";
            algorithm
              T := sum(n[i]*(pi + 0.240)^I[i]*(sigma - 0.703)^J[i] for i in 1:33)*
                Tstar;
              annotation (Documentation(info="<html>
<p>
 &nbsp;Equation number 6 from:
</p>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Functions
 T(p,h), v(p,h) and T(p,s),<br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
 </html>"));
            end T3a_ps;

            function T3b_ps "Region 3 b: inverse function T(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              output SI.Temperature T "Temperature";
          protected
              constant Real[:] n={0.527111701601660,-0.401317830052742e2,
                  0.153020073134484e3,-0.224799398218827e4,-0.193993484669048,-0.140467557893768e1,
                  0.426799878114024e2,0.752810643416743,0.226657238616417e2,-0.622873556909932e3,
                  -0.660823667935396,0.841267087271658,-0.253717501764397e2,
                  0.485708963532948e3,0.880531517490555e3,0.265015592794626e7,-0.359287150025783,
                  -0.656991567673753e3,0.241768149185367e1,0.856873461222588,
                  0.655143675313458,-0.213535213206406,0.562974957606348e-2,-0.316955725450471e15,
                  -0.699997000152457e-3,0.119845803210767e-1,0.193848122022095e-4,-0.215095749182309e-4};
              constant Real[:] I={-12,-12,-12,-12,-8,-8,-8,-6,-6,-6,-5,-5,-5,-5,-5,-4,
                  -3,-3,-2,0,2,3,4,5,6,8,12,14};
              constant Real[:] J={1,3,4,7,0,1,3,0,2,4,0,1,2,4,6,12,1,6,2,0,1,1,0,24,0,
                  3,1,2};
              constant SI.Temperature Tstar=860 "Normalization temperature";
              constant SI.Pressure pstar=100e6 "Normalization pressure";
              constant SI.SpecificEntropy sstar=5.3e3 "Normalization entropy";
              Real pi=p/pstar "Normalized specific pressure";
              Real sigma=s/sstar "Normalized specific entropy";
            algorithm
              T := sum(n[i]*(pi + 0.760)^I[i]*(sigma - 0.818)^J[i] for i in 1:28)*
                Tstar;
              annotation (Documentation(info="<html>
<p>
 &nbsp;Equation number 7 from:
</p>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Functions
 T(p,h), v(p,h) and T(p,s),<br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
</html>"));
            end T3b_ps;

            function v3a_ps "Region 3 a: inverse function v(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              output SI.SpecificVolume v "Specific volume";
          protected
              constant Real[:] n={0.795544074093975e2,-0.238261242984590e4,
                  0.176813100617787e5,-0.110524727080379e-2,-0.153213833655326e2,
                  0.297544599376982e3,-0.350315206871242e8,0.277513761062119,-0.523964271036888,
                  -0.148011182995403e6,0.160014899374266e7,0.170802322663427e13,
                  0.246866996006494e-3,0.165326084797980e1,-0.118008384666987,
                  0.253798642355900e1,0.965127704669424,-0.282172420532826e2,
                  0.203224612353823,0.110648186063513e1,0.526127948451280,
                  0.277000018736321,0.108153340501132e1,-0.744127885357893e-1,
                  0.164094443541384e-1,-0.680468275301065e-1,0.257988576101640e-1,-0.145749861944416e-3};
              constant Real[:] I={-12,-12,-12,-10,-10,-10,-10,-8,-8,-8,-8,-6,-5,-4,-3,
                  -3,-2,-2,-1,-1,0,0,0,1,2,4,5,6};
              constant Real[:] J={10,12,14,4,8,10,20,5,6,14,16,28,1,5,2,4,3,8,1,2,0,1,
                  3,0,0,2,2,0};
              constant SI.Volume vstar=0.0028 "Normalization temperature";
              constant SI.Pressure pstar=100e6 "Normalization pressure";
              constant SI.SpecificEntropy sstar=4.4e3 "Normalization entropy";
              Real pi=p/pstar "Normalized specific pressure";
              Real sigma=s/sstar "Normalized specific entropy";
            algorithm
              v := sum(n[i]*(pi + 0.187)^I[i]*(sigma - 0.755)^J[i] for i in 1:28)*
                vstar;
              annotation (Documentation(info="<html>
<p>
 &nbsp;Equation number 8 from:
</p>
 <div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Functions
 T(p,h), v(p,h) and T(p,s),<br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
</html>"));
            end v3a_ps;

            function v3b_ps "Region 3 b: inverse function v(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              output SI.SpecificVolume v "Specific volume";
          protected
              constant Real[:] n={0.591599780322238e-4,-0.185465997137856e-2,
                  0.104190510480013e-1,0.598647302038590e-2,-0.771391189901699,
                  0.172549765557036e1,-0.467076079846526e-3,0.134533823384439e-1,-0.808094336805495e-1,
                  0.508139374365767,0.128584643361683e-2,-0.163899353915435e1,
                  0.586938199318063e1,-0.292466667918613e1,-0.614076301499537e-2,
                  0.576199014049172e1,-0.121613320606788e2,0.167637540957944e1,-0.744135838773463e1,
                  0.378168091437659e-1,0.401432203027688e1,0.160279837479185e2,
                  0.317848779347728e1,-0.358362310304853e1,-0.115995260446827e7,
                  0.199256573577909,-0.122270624794624,-0.191449143716586e2,-0.150448002905284e-1,
                  0.146407900162154e2,-0.327477787188230e1};
              constant Real[:] I={-12,-12,-12,-12,-12,-12,-10,-10,-10,-10,-8,-5,-5,-5,
                  -4,-4,-4,-4,-3,-2,-2,-2,-2,-2,-2,0,0,0,1,1,2};
              constant Real[:] J={0,1,2,3,5,6,0,1,2,4,0,1,2,3,0,1,2,3,1,0,1,2,3,4,12,
                  0,1,2,0,2,2};
              constant SI.Volume vstar=0.0088 "Normalization temperature";
              constant SI.Pressure pstar=100e6 "Normalization pressure";
              constant SI.SpecificEntropy sstar=5.3e3 "Normalization entropy";
              Real pi=p/pstar "Normalized specific pressure";
              Real sigma=s/sstar "Normalized specific entropy";
            algorithm
              v := sum(n[i]*(pi + 0.298)^I[i]*(sigma - 0.816)^J[i] for i in 1:31)*
                vstar;
              annotation (Documentation(info="<html>
<p>
 &nbsp;Equation number 9 from:
</p>
<div style=\"text-align: center;\">&nbsp;[1] The international Association
 for the Properties of Water and Steam<br>
 &nbsp;Vejle, Denmark<br>
 &nbsp;August 2003<br>
 &nbsp;Supplementary Release on Backward Equations for the Functions
 T(p,h), v(p,h) and T(p,s),<br>
 &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
 the Thermodynamic Properties of<br>
 &nbsp;Water and Steam</div>
</html>"));
            end v3b_ps;
            annotation (Documentation(info="<html><h4>Package description</h4>
          <p>Package BaseIF97/Basic computes the fundamental functions for the 5 regions of the steam tables
          as described in the standards document <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a>. The code of these
          functions has been generated using <strong><em>Mathematica</em></strong> and the add-on packages \"Format\" and \"Optimize\"
          to generate highly efficient, expression-optimized C-code from a symbolic representation of the thermodynamic
          functions. The C-code has than been transformed into Modelica code. An important feature of this optimization was to
          simultaneously optimize the functions and the directional derivatives because they share many common subexpressions.</p>
          <h4>Package contents</h4>
          <ul>
          <li>Function <strong>g1</strong> computes the dimensionless Gibbs function for region 1 and all derivatives up
          to order 2 w.r.t. pi and tau. Inputs: p and T.</li>
          <li>Function <strong>g2</strong> computes the dimensionless Gibbs function  for region 2 and all derivatives up
          to order 2 w.r.t. pi and tau. Inputs: p and T.</li>
          <li>Function <strong>g2metastable</strong> computes the dimensionless Gibbs function for metastable vapour
          (adjacent to region 2 but 2-phase at equilibrium) and all derivatives up
          to order 2 w.r.t. pi and tau. Inputs: p and T.</li>
          <li>Function <strong>f3</strong> computes the dimensionless Helmholtz function  for region 3 and all derivatives up
          to order 2 w.r.t. delta and tau. Inputs: d and T.</li>
          <li>Function <strong>g5</strong>computes the dimensionless Gibbs function for region 5 and all derivatives up
          to order 2 w.r.t. pi and tau. Inputs: p and T.</li>
          <li>Function <strong>tph1</strong> computes the inverse function T(p,h) in region 1.</li>
          <li>Function <strong>tph2</strong> computes the inverse function T(p,h) in region 2.</li>
          <li>Function <strong>tps2a</strong> computes the inverse function T(p,s) in region 2a.</li>
          <li>Function <strong>tps2b</strong> computes the inverse function T(p,s) in region 2b.</li>
          <li>Function <strong>tps2c</strong> computes the inverse function T(p,s) in region 2c.</li>
          <li>Function <strong>tps2</strong> computes the inverse function T(p,s) in region 2.</li>
          <li>Function <strong>tsat</strong> computes the saturation temperature as a function of pressure.</li>
          <li>Function <strong>dtsatofp</strong> computes the derivative of the saturation temperature w.r.t. pressure as
          a function of pressure.</li>
          <li>Function <strong>tsat_der</strong> computes the Modelica derivative function of tsat.</li>
          <li>Function <strong>psat</strong> computes the saturation pressure as a function of temperature.</li>
          <li>Function <strong>dptofT</strong>  computes the derivative of the saturation pressure w.r.t. temperature as
          a function of temperature.</li>
          <li>Function <strong>psat_der</strong> computes the Modelica derivative function of psat.</li>
          </ul>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <em>July, 2000</em>
          by Hubertus Tummescheit
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit,<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documentation added: December 2002</li>
          </ul>
       <p>
       Equation from:
       </p>
       <div style=\"text-align: center;\">&nbsp;[1] The international Association
       for the Properties of Water and Steam<br>
       &nbsp;Vejle, Denmark<br>
       &nbsp;August 2003<br>
       &nbsp;Supplementary Release on Backward Equations for the Functions
       T(p,h), v(p,h) and T(p,s),<br>
       &nbsp;v(p,s) for Region 3 of the IAPWS Industrial Formulation 1997 for
       the Thermodynamic Properties of<br>
       &nbsp;Water and Steam</div>
       </html>"));
          end Basic;

          package Transport
          "Transport properties for water according to IAPWS/IF97"
            extends Modelica.Icons.FunctionsPackage;

            function visc_dTp "Dynamic viscosity eta(d,T,p), industrial formulation"
              extends Modelica.Icons.Function;
              input SI.Density d "Density";
              input SI.Temperature T "Temperature (K)";
              input SI.Pressure p "Pressure (only needed for region of validity)";
              input Integer phase=0
                "2 for two-phase, 1 for one-phase, 0 if not known (unused)";
              input Boolean checkLimits=true "Check if inputs d,T,P are in region of validity";
              output SI.DynamicViscosity eta "Dynamic viscosity";
          protected
              constant Real n0=1.0 "Viscosity coefficient";
              constant Real n1=0.978197 "Viscosity coefficient";
              constant Real n2=0.579829 "Viscosity coefficient";
              constant Real n3=-0.202354 "Viscosity coefficient";
              constant Real[42] nn=array(
                        0.5132047,
                        0.3205656,
                        0.0,
                        0.0,
                        -0.7782567,
                        0.1885447,
                        0.2151778,
                        0.7317883,
                        1.241044,
                        1.476783,
                        0.0,
                        0.0,
                        -0.2818107,
                        -1.070786,
                        -1.263184,
                        0.0,
                        0.0,
                        0.0,
                        0.1778064,
                        0.460504,
                        0.2340379,
                        -0.4924179,
                        0.0,
                        0.0,
                        -0.0417661,
                        0.0,
                        0.0,
                        0.1600435,
                        0.0,
                        0.0,
                        0.0,
                        -0.01578386,
                        0.0,
                        0.0,
                        0.0,
                        0.0,
                        0.0,
                        0.0,
                        0.0,
                        -0.003629481,
                        0.0,
                        0.0) "Viscosity coefficients";
              constant SI.Density rhostar=317.763 "Scaling density";
              constant SI.DynamicViscosity etastar=55.071e-6 "Scaling viscosity";
              constant SI.Temperature tstar=647.226 "Scaling temperature";
              Integer i "Auxiliary variable";
              Integer j "Auxiliary variable";
              Real delta "Dimensionless density";
              Real deltam1 "Dimensionless density";
              Real tau "Dimensionless temperature";
              Real taum1 "Dimensionless temperature";
              Real Psi0 "Auxiliary variable";
              Real Psi1 "Auxiliary variable";
              Real tfun "Auxiliary variable";
              Real rhofun "Auxiliary variable";
              Real Tc=T - 273.15 "Celsius temperature for region check";
            algorithm
              //      if phase == 0 then
              //        region := BaseIF97.Regions.region_dT(d,T,0);
              //      end if;
              //      if phase == 2 then
              //        region := 4;
              //      end if;
              // assert(phase <> 2, "Viscosity can not be computed for two-phase states");
              delta := d/rhostar;
              if checkLimits then
                assert(d > triple.dvtriple,
                  "IF97 medium function visc_dTp for viscosity called with too low density\n"
                   + "d = " + String(d) + " <= " + String(triple.dvtriple) +
                  " (triple point density)");
                assert((p <= 500e6 and (Tc >= 0.0 and Tc <= 150)) or (p <= 350e6 and (
                  Tc > 150.0 and Tc <= 600)) or (p <= 300e6 and (Tc > 600.0 and Tc <=
                  900)),
                  "IF97 medium function visc_dTp: viscosity computed outside the range\n"
                   + "of validity of the IF97 formulation: p = " + String(p) +
                  " Pa, Tc = " + String(Tc) + " K");
              end if;
              deltam1 := delta - 1.0;
              tau := tstar/T;
              taum1 := tau - 1.0;
              Psi0 := 1/(n0 + (n1 + (n2 + n3*tau)*tau)*tau)/(tau^0.5);
              Psi1 := 0.0;
              tfun := 1.0;
              for i in 1:6 loop
                if (i <> 1) then
                  tfun := tfun*taum1;
                end if;
                rhofun := 1.;
                for j in 0:6 loop
                  if (j <> 0) then
                    rhofun := rhofun*deltam1;
                  end if;
                  Psi1 := Psi1 + nn[i + j*6]*tfun*rhofun;
                end for;
              end for;
              eta := etastar*Psi0*Modelica.Math.exp(delta*Psi1);
            end visc_dTp;

            function cond_dTp
              "Thermal conductivity lam(d,T,p) (industrial use version) only in one-phase region"
              extends Modelica.Icons.Function;
              input SI.Density d "Density";
              input SI.Temperature T "Temperature (K)";
              input SI.Pressure p "Pressure";
              input Integer phase=0
                "2 for two-phase, 1 for one-phase, 0 if not known";
              input Boolean industrialMethod=true
                "If true, the industrial method is used, otherwise the scientific one";
              input Boolean checkLimits=true "Check if inputs d,T,P are in region of validity";
              output SI.ThermalConductivity lambda "Thermal conductivity";
          protected
              Integer region(min=1, max=5) "IF97 region, valid values:1,2,3, and 5";
              constant Real n0=1.0 "Conductivity coefficient";
              constant Real n1=6.978267 "Conductivity coefficient";
              constant Real n2=2.599096 "Conductivity coefficient";
              constant Real n3=-0.998254 "Conductivity coefficient";
              constant Real[30] nn=array(
                        1.3293046,
                        1.7018363,
                        5.2246158,
                        8.7127675,
                        -1.8525999,
                        -0.40452437,
                        -2.2156845,
                        -10.124111,
                        -9.5000611,
                        0.9340469,
                        0.2440949,
                        1.6511057,
                        4.9874687,
                        4.3786606,
                        0.0,
                        0.018660751,
                        -0.76736002,
                        -0.27297694,
                        -0.91783782,
                        0.0,
                        -0.12961068,
                        0.37283344,
                        -0.43083393,
                        0.0,
                        0.0,
                        0.044809953,
                        -0.1120316,
                        0.13333849,
                        0.0,
                        0.0) "Conductivity coefficient";
              constant SI.ThermalConductivity lamstar=0.4945 "Scaling conductivity";
              constant SI.Density rhostar=317.763 "Scaling density";
              constant SI.Temperature tstar=647.226 "Scaling temperature";
              constant SI.Pressure pstar=22.115e6 "Scaling pressure";
              constant SI.DynamicViscosity etastar=55.071e-6 "Scaling viscosity";
              Integer i "Auxiliary variable";
              Integer j "Auxiliary variable";
              Real delta "Dimensionless density";
              Real tau "Dimensionless temperature";
              Real deltam1 "Dimensionless density";
              Real taum1 "Dimensionless temperature";
              Real Lam0 "Part of thermal conductivity";
              Real Lam1 "Part of thermal conductivity";
              Real Lam2 "Part of thermal conductivity";
              Real tfun "Auxiliary variable";
              Real rhofun "Auxiliary variable";
              Real dpitau "Auxiliary variable";
              Real ddelpi "Auxiliary variable";
              Real d2 "Auxiliary variable";
              Modelica.Media.Common.GibbsDerivs g
                "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              Modelica.Media.Common.HelmholtzDerivs f
                "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              Real Tc=T - 273.15 "Celsius temperature for region check";
              Real Chi "Symmetrized compressibility";
              // slightly different variables for industrial use
              constant SI.Density rhostar2=317.7 "Reference density";
              constant SI.Temperature Tstar2=647.25 "Reference temperature";
              constant SI.ThermalConductivity lambdastar=1
                "Reference thermal conductivity";
              Real TREL=T/Tstar2 "Relative temperature";
              Real rhoREL=d/rhostar2 "Relative density";
              Real lambdaREL "Relative thermal conductivity";
              Real deltaTREL "Relative temperature increment";
              constant Real[:] C={0.642857,-4.11717,-6.17937,0.00308976,0.0822994,
                  10.0932};
              constant Real[:] dpar={0.0701309,0.0118520,0.00169937,-1.0200};
              constant Real[:] b={-0.397070,0.400302,1.060000};
              constant Real[:] B={-0.171587,2.392190};
              constant Real[:] a={0.0102811,0.0299621,0.0156146,-0.00422464};
              Real Q;
              Real S;
              Real lambdaREL2
                "Function, part of the interpolating equation of the thermal conductivity";
              Real lambdaREL1
                "Function, part of the interpolating equation of the thermal conductivity";
              Real lambdaREL0
                "Function, part of the interpolating equation of the thermal conductivity";
            algorithm
              // simplified region check, assuming that calling arguments are legal
              //  assert(phase <> 2,
              //   "ThermalConductivity can not be called with 2-phase inputs!");
              if checkLimits then
                assert(d > triple.dvtriple,
                  "IF97 medium function cond_dTp called with too low density\n" +
                  "d = " + String(d) + " <= " + String(triple.dvtriple) +
                  " (triple point density)");
                assert((p <= 100e6 and (Tc >= 0.0 and Tc <= 500)) or (p <= 70e6 and (Tc
                   > 500.0 and Tc <= 650)) or (p <= 40e6 and (Tc > 650.0 and Tc <= 800)),
                  "IF97 medium function cond_dTp: thermal conductivity computed outside the range\n"
                   + "of validity of the IF97 formulation: p = " + String(p) +
                  " Pa, Tc = " + String(Tc) + " K");
              end if;
              if industrialMethod == true then
                deltaTREL := abs(TREL - 1) + C[4];
                Q := 2 + C[5]/deltaTREL^(3/5);
                if TREL >= 1 then
                  S := 1/deltaTREL;
                else
                  S := C[6]/deltaTREL^(3/5);
                end if;
                lambdaREL2 := (dpar[1]/TREL^10 + dpar[2])*rhoREL^(9/5)*
                  Modelica.Math.exp(C[1]*(1 - rhoREL^(14/5))) + dpar[3]*S*rhoREL^Q*
                  Modelica.Math.exp((Q/(1 + Q))*(1 - rhoREL^(1 + Q))) + dpar[4]*
                  Modelica.Math.exp(C[2]*TREL^(3/2) + C[3]/rhoREL^5);
                lambdaREL1 := b[1] + b[2]*rhoREL + b[3]*Modelica.Math.exp(B[1]*(
                  rhoREL + B[2])^2);
                lambdaREL0 := TREL^(1/2)*sum(a[i]*TREL^(i - 1) for i in 1:4);
                lambdaREL := lambdaREL0 + lambdaREL1 + lambdaREL2;
                lambda := lambdaREL*lambdastar;
              else
                if p < data.PLIMIT4A then
                  //regions are 1 or 2,
                  if d > data.DCRIT then
                    region := 1;
                  else
                    region := 2;
                  end if;
                else
                  //region is 3, or illegal
                  assert(false,
                    "The scientific method works only for temperature up to 623.15 K");
                end if;
                tau := tstar/T;
                delta := d/rhostar;
                deltam1 := delta - 1.0;
                taum1 := tau - 1.0;
                Lam0 := 1/(n0 + (n1 + (n2 + n3*tau)*tau)*tau)/(tau^0.5);
                Lam1 := 0.0;
                tfun := 1.0;
                for i in 1:5 loop
                  if (i <> 1) then
                    tfun := tfun*taum1;
                  end if;
                  rhofun := 1.0;
                  for j in 0:5 loop
                    if (j <> 0) then
                      rhofun := rhofun*deltam1;
                    end if;
                    Lam1 := Lam1 + nn[i + j*5]*tfun*rhofun;
                  end for;
                end for;
                if (region == 1) then
                  g := Basic.g1(p, T);
                  // dp/dT @ cont d = -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
                  dpitau := -tstar/pstar*(data.PSTAR1*(g.gpi - data.TSTAR1/T*g.gtaupi)
                    /g.gpipi/T);
                  ddelpi := -pstar/rhostar*data.RH2O/data.PSTAR1/data.PSTAR1*T*d*d*g.gpipi;
                  Chi := delta*ddelpi;
                elseif (region == 2) then
                  g := Basic.g2(p, T);
                  dpitau := -tstar/pstar*(data.PSTAR2*(g.gpi - data.TSTAR2/T*g.gtaupi)
                    /g.gpipi/T);
                  ddelpi := -pstar/rhostar*data.RH2O/data.PSTAR2/data.PSTAR2*T*d*d*g.gpipi;
                  Chi := delta*ddelpi;
                  //         elseif (region == 3) then
                  //           f := Basic.f3(T, d);
                  //            dpitau := tstar/pstar*(f.R_s*f.d*f.delta*(f.fdelta - f.tau*f.fdeltatau));
                  //           ddelpi := pstar*d*d/(rhostar*p*p)/(f.R_s*f.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta));
                  //    Chi := delta*ddelpi;
                else
                  assert(false,
                    "Thermal conductivity can only be called in the one-phase regions below 623.15 K\n"
                     + "(p = " + String(p) + " Pa, T = " + String(T) +
                    " K, region = " + String(region) + ")");
                end if;
                taum1 := 1/tau - 1;
                d2 := deltam1*deltam1;
                Lam2 := 0.0013848*etastar/visc_dTp(
                        d,
                        T,
                        p)/(tau*tau*delta*delta)*dpitau*dpitau*max(Chi, Modelica.Constants.small)
                  ^0.4678*(delta)^0.5*Modelica.Math.exp(-18.66*taum1*taum1 - d2*d2);
                lambda := lamstar*(Lam0*Modelica.Math.exp(delta*Lam1) + Lam2);
              end if;
            end cond_dTp;

            function surfaceTension
              "Surface tension in region 4 between steam and water"
              extends Modelica.Icons.Function;
              input SI.Temperature T "Temperature (K)";
              output SI.SurfaceTension sigma "Surface tension in SI units";
          protected
              Real Theta "Dimensionless temperature";
            algorithm
              Theta := min(1.0, T/data.TCRIT);
              sigma := 235.8e-3*(1 - Theta)^1.256*(1 - 0.625*(1 - Theta));
            end surfaceTension;
            annotation (Documentation(info="<html><h4>Package description</h4>
          <h4>Package contents</h4>
          <ul>
          <li>Function <strong>visc_dTp</strong> implements a function to compute the industrial formulation of the
          dynamic viscosity of water as a function of density and temperature.
          The details are described in the document <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/visc.pdf\">visc.pdf</a>.</li>
          <li>Function <strong>cond_dTp</strong> implements a function to compute  the industrial formulation of the thermal conductivity of water as
          a function of density, temperature and pressure. <strong>Important note</strong>: Obviously only two of the three
          inputs are really needed, but using three inputs speeds up the computation and the three variables are known in most models anyways.
          The inputs d,T and p have to be consistent.
          The details are described in the document <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/surf.pdf\">surf.pdf</a>.</li>
          <li>Function <strong>surfaceTension</strong> implements a function to compute the surface tension between vapour
          and liquid water as a function of temperature.
          The details are described in the document <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/thcond.pdf\">thcond.pdf</a>.</li>
          </ul>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <em>October, 2002</em>
          by Hubertus Tummescheit
          </li>
          </ul>
          <address>Authors: Hubertus Tummescheit and Jonas Eborn<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: October 2002</li>
          </ul>
          </html>"));
          end Transport;

          package Isentropic
          "Functions for calculating the isentropic enthalpy from pressure p and specific entropy s"
            extends Modelica.Icons.FunctionsPackage;

            function hofpT1
              "Intermediate function for isentropic specific enthalpy in region 1"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real[13] o "Vector of auxiliary variables";
              Real pi1 "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau1 "Dimensionless temperature";
            algorithm
              tau := data.TSTAR1/T;
              pi1 := 7.1 - p/data.PSTAR1;
              assert(p > triple.ptriple,
                "IF97 medium function hofpT1 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              tau1 := -1.222 + tau;
              o[1] := tau1*tau1;
              o[2] := o[1]*tau1;
              o[3] := o[1]*o[1];
              o[4] := o[3]*o[3];
              o[5] := o[1]*o[4];
              o[6] := o[1]*o[3];
              o[7] := o[3]*tau1;
              o[8] := o[3]*o[4];
              o[9] := pi1*pi1;
              o[10] := o[9]*o[9];
              o[11] := o[10]*o[10];
              o[12] := o[4]*o[4];
              o[13] := o[12]*o[12];

              h := data.RH2O*T*tau*(pi1*((-0.00254871721114236 + o[1]*(
                0.00424944110961118 + (0.018990068218419 + (-0.021841717175414 -
                0.00015851507390979*o[1])*o[1])*o[6]))/o[5] + pi1*((
                0.00141552963219801 + o[3]*(0.000047661393906987 + o[1]*(-0.0000132425535992538
                 - 1.2358149370591e-14*o[1]*o[3]*o[4])))/o[3] + pi1*((
                0.000126718579380216 - 5.11230768720618e-9*o[5])/o[7] + pi1*((
                0.000011212640954 + o[2]*(1.30342445791202e-6 - 1.4341729937924e-12*o[
                8]))/o[6] + pi1*(o[9]*pi1*((1.40077319158051e-8 + 1.04549227383804e-9
                *o[7])/o[8] + o[10]*o[11]*pi1*(1.9941018075704e-17/(o[1]*o[12]*o[3]*o[
                4]) + o[9]*(-4.48827542684151e-19/o[13] + o[10]*o[9]*(pi1*(
                4.65957282962769e-22/(o[13]*o[4]) + pi1*((3.83502057899078e-24*pi1)/(
                o[1]*o[13]*o[4]) - 7.2912378325616e-23/(o[13]*o[4]*tau1))) -
                1.00075970318621e-21/(o[1]*o[13]*o[3]*tau1))))) + 3.24135974880936e-6
                /(o[4]*tau1)))))) + (-0.29265942426334 + tau1*(0.84548187169114 + o[1]
                *(3.3855169168385 + tau1*(-1.91583926775744 + tau1*(0.47316115539684
                 + (-0.066465668798004 + 0.0040607314991784*tau1)*tau1)))))/o[2]);
            end hofpT1;

            function handsofpT1
              "Special function for specific enthalpy and specific entropy in region 1"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              Real[28] o "Vector of auxiliary variables";
              Real pi1 "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau1 "Dimensionless temperature";
              Real g "Dimensionless Gibbs energy";
              Real gtau "Derivative of dimensionless Gibbs energy w.r.t. tau";
            algorithm
              assert(p > triple.ptriple,
                "IF97 medium function handsofpT1 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              tau := data.TSTAR1/T;
              pi1 := 7.1 - p/data.PSTAR1;
              tau1 := -1.222 + tau;
              o[1] := tau1*tau1;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              o[4] := o[3]*tau1;
              o[5] := 1/o[4];
              o[6] := o[1]*o[2];
              o[7] := o[1]*tau1;
              o[8] := 1/o[7];
              o[9] := o[1]*o[2]*o[3];
              o[10] := 1/o[2];
              o[11] := o[2]*tau1;
              o[12] := 1/o[11];
              o[13] := o[2]*o[3];
              o[14] := pi1*pi1;
              o[15] := o[14]*pi1;
              o[16] := o[14]*o[14];
              o[17] := o[16]*o[16];
              o[18] := o[16]*o[17]*pi1;
              o[19] := o[14]*o[16];
              o[20] := o[3]*o[3];
              o[21] := o[20]*o[20];
              o[22] := o[21]*o[3]*tau1;
              o[23] := 1/o[22];
              o[24] := o[21]*o[3];
              o[25] := 1/o[24];
              o[26] := o[1]*o[2]*o[21]*tau1;
              o[27] := 1/o[26];
              o[28] := o[1]*o[3];

              g := pi1*(pi1*(pi1*(o[10]*(-0.000031679644845054 + o[2]*(-2.8270797985312e-6
                 - 8.5205128120103e-10*o[6])) + pi1*(o[12]*(-2.2425281908e-6 + (-6.5171222895601e-7
                 - 1.4341729937924e-13*o[13])*o[7]) + pi1*(-4.0516996860117e-7/o[3]
                 + o[15]*(o[18]*(o[14]*(o[19]*(2.6335781662795e-23/(o[1]*o[2]*o[21])
                 + pi1*(-1.1947622640071e-23*o[27] + pi1*(1.8228094581404e-24*o[25]
                 - 9.3537087292458e-26*o[23]*pi1))) + 1.4478307828521e-20/(o[1]*o[2]*
                o[20]*o[3]*tau1)) - 6.8762131295531e-19/(o[2]*o[20]*o[3]*tau1)) + (-1.2734301741641e-9
                 - 1.7424871230634e-10*o[11])/(o[1]*o[3]*tau1))))) + o[8]*(-0.00047184321073267
                 + o[7]*(-0.00030001780793026 + (0.000047661393906987 + o[1]*(-4.4141845330846e-6
                 - 7.2694996297594e-16*o[9]))*tau1))) + o[5]*(0.00028319080123804 + o[
                1]*(-0.00060706301565874 + o[6]*(-0.018990068218419 + tau1*(-0.032529748770505
                 + (-0.021841717175414 - 0.00005283835796993*o[1])*tau1))))) + (
                0.14632971213167 + tau1*(-0.84548187169114 + tau1*(-3.756360367204 +
                tau1*(3.3855169168385 + tau1*(-0.95791963387872 + tau1*(
                0.15772038513228 + (-0.016616417199501 + 0.00081214629983568*tau1)*
                tau1))))))/o[1];

              gtau := pi1*((-0.00254871721114236 + o[1]*(0.00424944110961118 + (
                0.018990068218419 + (-0.021841717175414 - 0.00015851507390979*o[1])*o[
                1])*o[6]))/o[28] + pi1*(o[10]*(0.00141552963219801 + o[2]*(
                0.000047661393906987 + o[1]*(-0.0000132425535992538 -
                1.2358149370591e-14*o[9]))) + pi1*(o[12]*(0.000126718579380216 -
                5.11230768720618e-9*o[28]) + pi1*((0.000011212640954 + (
                1.30342445791202e-6 - 1.4341729937924e-12*o[13])*o[7])/o[6] + pi1*(
                3.24135974880936e-6*o[5] + o[15]*((1.40077319158051e-8 +
                1.04549227383804e-9*o[11])/o[13] + o[18]*(1.9941018075704e-17/(o[1]*o[
                2]*o[20]*o[3]) + o[14]*(-4.48827542684151e-19/o[21] + o[19]*(-1.00075970318621e-21
                *o[27] + pi1*(4.65957282962769e-22*o[25] + pi1*(-7.2912378325616e-23*
                o[23] + (3.83502057899078e-24*pi1)/(o[1]*o[21]*o[3])))))))))))) + o[8]
                *(-0.29265942426334 + tau1*(0.84548187169114 + o[1]*(3.3855169168385
                 + tau1*(-1.91583926775744 + tau1*(0.47316115539684 + (-0.066465668798004
                 + 0.0040607314991784*tau1)*tau1)))));

              h := data.RH2O*T*tau*gtau;
              s := data.RH2O*(tau*gtau - g);
            end handsofpT1;

            function hofpT2
              "Intermediate function for isentropic specific enthalpy in region 2"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.SpecificEnthalpy h "Specific enthalpy";
          protected
              Real[16] o "Vector of auxiliary variables";
              Real pi "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau2 "Dimensionless temperature";
            algorithm
              assert(p > triple.ptriple,
                "IF97 medium function hofpT2 called with too low pressure\n" + "p = "
                 + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              pi := p/data.PSTAR2;
              tau := data.TSTAR2/T;
              tau2 := -0.5 + tau;
              o[1] := tau*tau;
              o[2] := o[1]*o[1];
              o[3] := tau2*tau2;
              o[4] := o[3]*tau2;
              o[5] := o[3]*o[3];
              o[6] := o[5]*o[5];
              o[7] := o[6]*o[6];
              o[8] := o[5]*o[6]*o[7]*tau2;
              o[9] := o[3]*o[5];
              o[10] := o[5]*o[6]*tau2;
              o[11] := o[3]*o[7]*tau2;
              o[12] := o[3]*o[5]*o[6];
              o[13] := o[5]*o[6]*o[7];
              o[14] := pi*pi;
              o[15] := o[14]*o[14];
              o[16] := o[7]*o[7];

              h := data.RH2O*T*tau*((0.0280439559151 + tau*(-0.2858109552582 + tau*(
                1.2213149471784 + tau*(-2.848163942888 + tau*(4.38395111945 + o[1]*(
                10.08665568018 + (-0.5681726521544 + 0.06380539059921*tau)*tau))))))/
                (o[1]*o[2]) + pi*(-0.017834862292358 + tau2*(-0.09199202739273 + (-0.172743777250296
                 - 0.30195167236758*o[4])*tau2) + pi*(-0.000033032641670203 + (-0.0003789797503263
                 + o[3]*(-0.015757110897342 + o[4]*(-0.306581069554011 -
                0.000960283724907132*o[8])))*tau2 + pi*(4.3870667284435e-7 + o[3]*(-0.00009683303171571
                 + o[4]*(-0.0090203547252888 - 1.42338887469272*o[8])) + pi*(-7.8847309559367e-10
                 + (2.558143570457e-8 + 1.44676118155521e-6*tau2)*tau2 + pi*(
                0.0000160454534363627*o[9] + pi*((-5.0144299353183e-11 + o[10]*(-0.033874355714168
                 - 836.35096769364*o[11]))*o[3] + pi*((-0.0000138839897890111 -
                0.973671060893475*o[12])*o[3]*o[6] + pi*((9.0049690883672e-11 -
                296.320827232793*o[13])*o[3]*o[5]*tau2 + pi*(2.57526266427144e-7*o[5]
                *o[6] + pi*(o[4]*(4.1627860840696e-19 + (-1.0234747095929e-12 -
                1.40254511313154e-8*o[5])*o[9]) + o[14]*o[15]*(o[13]*(-2.34560435076256e-9
                 + 5.3465159397045*o[5]*o[7]*tau2) + o[14]*(-19.1874828272775*o[16]*o[
                6]*o[7] + o[14]*(o[11]*(1.78371690710842e-23 + (1.07202609066812e-11
                 - 0.000201611844951398*o[10])*o[3]*o[5]*o[6]*tau2) + pi*(-1.24017662339842e-24
                *o[5]*o[7] + pi*(0.000200482822351322*o[16]*o[5]*o[7] + pi*(-4.97975748452559e-14
                *o[16]*o[3]*o[5] + o[6]*o[7]*(1.90027787547159e-27 + o[12]*(
                2.21658861403112e-15 - 0.0000547344301999018*o[3]*o[7]))*pi*tau2)))))))))))))))));
            end hofpT2;

            function handsofpT2
              "Function for isentropic specific enthalpy and specific entropy in region 2"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              output SI.SpecificEnthalpy h "Specific enthalpy";
              output SI.SpecificEntropy s "Specific entropy";
          protected
              Real[22] o "Vector of auxiliary variables";
              Real pi "Dimensionless pressure";
              Real tau "Dimensionless temperature";
              Real tau2 "Dimensionless temperature";
              Real g "Dimensionless Gibbs energy";
              Real gtau "Derivative of dimensionless Gibbs energy w.r.t. tau";
            algorithm
              assert(p > triple.ptriple,
                "IF97 medium function handsofpT2 called with too low pressure\n" +
                "p = " + String(p) + " Pa <= " + String(triple.ptriple) +
                " Pa (triple point pressure)");
              tau := data.TSTAR2/T;
              pi := p/data.PSTAR2;
              tau2 := tau - 0.5;
              o[1] := tau2*tau2;
              o[2] := o[1]*tau2;
              o[3] := o[1]*o[1];
              o[4] := o[3]*o[3];
              o[5] := o[4]*o[4];
              o[6] := o[3]*o[4]*o[5]*tau2;
              o[7] := o[1]*o[3]*tau2;
              o[8] := o[3]*o[4]*tau2;
              o[9] := o[1]*o[5]*tau2;
              o[10] := o[1]*o[3]*o[4];
              o[11] := o[3]*o[4]*o[5];
              o[12] := o[1]*o[3];
              o[13] := pi*pi;
              o[14] := o[13]*o[13];
              o[15] := o[13]*o[14];
              o[16] := o[3]*o[5]*tau2;
              o[17] := o[5]*o[5];
              o[18] := o[3]*o[5];
              o[19] := o[1]*o[3]*o[4]*tau2;
              o[20] := o[1]*o[5];
              o[21] := tau*tau;
              o[22] := o[21]*o[21];

              g := pi*(-0.0017731742473213 + tau2*(-0.017834862292358 + tau2*(-0.045996013696365
                 + (-0.057581259083432 - 0.05032527872793*o[2])*tau2)) + pi*(tau2*(-0.000033032641670203
                 + (-0.00018948987516315 + o[1]*(-0.0039392777243355 + o[2]*(-0.043797295650573
                 - 0.000026674547914087*o[6])))*tau2) + pi*(2.0481737692309e-8 + (
                4.3870667284435e-7 + o[1]*(-0.00003227767723857 + o[2]*(-0.0015033924542148
                 - 0.040668253562649*o[6])))*tau2 + pi*(tau2*(-7.8847309559367e-10 +
                (1.2790717852285e-8 + 4.8225372718507e-7*tau2)*tau2) + pi*(
                2.2922076337661e-6*o[7] + pi*(o[2]*(-1.6714766451061e-11 + o[8]*(-0.0021171472321355
                 - 23.895741934104*o[9])) + pi*(-5.905956432427e-18 + o[1]*(-1.2621808899101e-6
                 - 0.038946842435739*o[10])*o[4]*tau2 + pi*((1.1256211360459e-11 -
                8.2311340897998*o[11])*o[4] + pi*(1.9809712802088e-8*o[8] + pi*((
                1.0406965210174e-19 + o[12]*(-1.0234747095929e-13 -
                1.0018179379511e-9*o[3]))*o[3] + o[15]*((-8.0882908646985e-11 +
                0.10693031879409*o[16])*o[6] + o[13]*(-0.33662250574171*o[17]*o[4]*o[
                5]*tau2 + o[13]*(o[18]*(8.9185845355421e-25 + o[19]*(
                3.0629316876232e-13 - 4.2002467698208e-6*o[8])) + pi*(-5.9056029685639e-26
                *o[16] + pi*(3.7826947613457e-6*o[17]*o[3]*o[5]*tau2 + pi*(o[1]*(
                7.3087610595061e-29 + o[10]*(5.5414715350778e-17 - 9.436970724121e-7*
                o[20]))*o[4]*o[5]*pi - 1.2768608934681e-15*o[1]*o[17]*o[3]*tau2))))))))))))))))
                 + (-0.00560879118302 + tau*(0.07145273881455 + tau*(-0.4071049823928
                 + tau*(1.424081971444 + tau*(-4.38395111945 + tau*(-9.692768600217
                 + tau*(10.08665568018 + (-0.2840863260772 + 0.02126846353307*tau)*
                tau) + Modelica.Math.log(pi)))))))/(o[22]*tau);

              gtau := (0.0280439559151 + tau*(-0.2858109552582 + tau*(1.2213149471784
                 + tau*(-2.848163942888 + tau*(4.38395111945 + o[21]*(10.08665568018
                 + (-0.5681726521544 + 0.06380539059921*tau)*tau))))))/(o[21]*o[22])
                 + pi*(-0.017834862292358 + tau2*(-0.09199202739273 + (-0.172743777250296
                 - 0.30195167236758*o[2])*tau2) + pi*(-0.000033032641670203 + (-0.0003789797503263
                 + o[1]*(-0.015757110897342 + o[2]*(-0.306581069554011 -
                0.000960283724907132*o[6])))*tau2 + pi*(4.3870667284435e-7 + o[1]*(-0.00009683303171571
                 + o[2]*(-0.0090203547252888 - 1.42338887469272*o[6])) + pi*(-7.8847309559367e-10
                 + (2.558143570457e-8 + 1.44676118155521e-6*tau2)*tau2 + pi*(
                0.0000160454534363627*o[12] + pi*(o[1]*(-5.0144299353183e-11 + o[8]*(
                -0.033874355714168 - 836.35096769364*o[9])) + pi*(o[1]*(-0.0000138839897890111
                 - 0.973671060893475*o[10])*o[4] + pi*((9.0049690883672e-11 -
                296.320827232793*o[11])*o[7] + pi*(2.57526266427144e-7*o[3]*o[4] + pi
                *(o[2]*(4.1627860840696e-19 + o[12]*(-1.0234747095929e-12 -
                1.40254511313154e-8*o[3])) + o[15]*(o[11]*(-2.34560435076256e-9 +
                5.3465159397045*o[16]) + o[13]*(-19.1874828272775*o[17]*o[4]*o[5] + o[
                13]*((1.78371690710842e-23 + o[19]*(1.07202609066812e-11 -
                0.000201611844951398*o[8]))*o[9] + pi*(-1.24017662339842e-24*o[18] +
                pi*(0.000200482822351322*o[17]*o[3]*o[5] + pi*(-4.97975748452559e-14*
                o[1]*o[17]*o[3] + (1.90027787547159e-27 + o[10]*(2.21658861403112e-15
                 - 0.0000547344301999018*o[20]))*o[4]*o[5]*pi*tau2))))))))))))))));

              h := data.RH2O*T*tau*gtau;
              s := data.RH2O*(tau*gtau - g);
            end handsofpT2;
            annotation (Documentation(info="<html><h4>Package description</h4>
          <h4>Package contents</h4>
          <ul>
          <li>Function <strong>hofpT1</strong> computes h(p,T) in region 1.</li>
          <li>Function <strong>handsofpT1</strong> computes (s,h)=f(p,T) in region 1, needed for two-phase properties.</li>
          <li>Function <strong>hofps1</strong> computes h(p,s) in region 1.</li>
          <li>Function <strong>hofpT2</strong> computes h(p,T) in region 2.</li>
          <li>Function <strong>handsofpT2</strong> computes (s,h)=f(p,T) in region 2, needed for two-phase properties.</li>
          <li>Function <strong>hofps2</strong> computes h(p,s) in region 2.</li>
          <li>Function <strong>hofdT3</strong> computes h(d,T) in region 3.</li>
          <li>Function <strong>hofpsdt3</strong> computes h(p,s,dguess,Tguess) in region 3, where dguess and Tguess are initial guess
          values for the density and temperature consistent with p and s.</li>
          <li>Function <strong>hofps4</strong> computes h(p,s) in region 4.</li>
          <li>Function <strong>hofpT5</strong> computes h(p,T) in region 5.</li>
          <li>Function <strong>water_hisentropic</strong> computes h(p,s,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary.</li>
          <li>Function <strong>water_hisentropic_dyn</strong> computes h(p,s,dguess,Tguess,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary. Tguess and dguess are initial guess
          values for the density and temperature consistent with p and s. This function should be preferred in
          dynamic simulations where good guesses are often available.</li>
          </ul>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <em>July, 2000</em>
          by Hubertus Tummescheit
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit,<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documentation added: December 2002</li>
          </ul>
          </html>"));
          end Isentropic;

          package Inverses "Efficient inverses for selected pairs of variables"
            extends Modelica.Icons.FunctionsPackage;

            function fixdT "Region limits for inverse iteration in region 3"

              extends Modelica.Icons.Function;
              input SI.Density din "Density";
              input SI.Temperature Tin "Temperature";
              output SI.Density dout "Density";
              output SI.Temperature Tout "Temperature";
          protected
              SI.Temperature Tmin "Approximation of minimum temperature";
              SI.Temperature Tmax "Approximation of maximum temperature";
            algorithm
              if (din > 765.0) then
                dout := 765.0;
              elseif (din < 110.0) then
                dout := 110.0;
              else
                dout := din;
              end if;
              if (dout < 390.0) then
                Tmax := 554.3557377 + dout*0.809344262;
              else
                Tmax := 1116.85 - dout*0.632948717;
              end if;
              if (dout < data.DCRIT) then
                Tmin := data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/
                  1.0e6);
              else
                Tmin := data.TCRIT*(1.0 - (dout - data.DCRIT)*(dout - data.DCRIT)/
                  1.44e6);
              end if;
              if (Tin < Tmin) then
                Tout := Tmin;
              elseif (Tin > Tmax) then
                Tout := Tmax;
              else
                Tout := Tin;
              end if;
            end fixdT;

            function dofp13 "Density at the boundary between regions 1 and 3"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.Density d "Density";
          protected
              Real p2 "Auxiliary variable";
              Real[3] o "Vector of auxiliary variables";
            algorithm
              p2 := 7.1 - 6.04960677555959e-8*p;
              o[1] := p2*p2;
              o[2] := o[1]*o[1];
              o[3] := o[2]*o[2];
              d := 57.4756752485113/(0.0737412153522555 + p2*(0.00145092247736023 +
                p2*(0.000102697173772229 + p2*(0.0000114683182476084 + p2*(
                1.99080616601101e-6 + o[1]*p2*(1.13217858826367e-8 + o[2]*o[3]*p2*(
                1.35549330686006e-17 + o[1]*(-3.11228834832975e-19 + o[1]*o[2]*(-7.02987180039442e-22
                 + p2*(3.29199117056433e-22 + (-5.17859076694812e-23 +
                2.73712834080283e-24*p2)*p2))))))))));

            end dofp13;

            function dofp23 "Density at the boundary between regions 2 and 3"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              output SI.Density d "Density";
          protected
              SI.Temperature T;
              Real[13] o "Vector of auxiliary variables";
              Real taug "Auxiliary variable";
              Real pi "Dimensionless pressure";
              Real gpi23
                "Derivative of g w.r.t. pi on the boundary between regions 2 and 3";
            algorithm
              pi := p/data.PSTAR2;
              T := 572.54459862746 + 31.3220101646784*(-13.91883977887 + pi)^0.5;
              o[1] := (-13.91883977887 + pi)^0.5;
              taug := -0.5 + 540.0/(572.54459862746 + 31.3220101646784*o[1]);
              o[2] := taug*taug;
              o[3] := o[2]*taug;
              o[4] := o[2]*o[2];
              o[5] := o[4]*o[4];
              o[6] := o[5]*o[5];
              o[7] := o[4]*o[5]*o[6]*taug;
              o[8] := o[4]*o[5]*taug;
              o[9] := o[2]*o[4]*o[5];
              o[10] := pi*pi;
              o[11] := o[10]*o[10];
              o[12] := o[4]*o[6]*taug;
              o[13] := o[6]*o[6];

              gpi23 := (1.0 + pi*(-0.0017731742473213 + taug*(-0.017834862292358 +
                taug*(-0.045996013696365 + (-0.057581259083432 - 0.05032527872793*o[3])
                *taug)) + pi*(taug*(-0.000066065283340406 + (-0.0003789797503263 + o[
                2]*(-0.007878555448671 + o[3]*(-0.087594591301146 -
                0.000053349095828174*o[7])))*taug) + pi*(6.1445213076927e-8 + (
                1.31612001853305e-6 + o[2]*(-0.00009683303171571 + o[3]*(-0.0045101773626444
                 - 0.122004760687947*o[7])))*taug + pi*(taug*(-3.15389238237468e-9 +
                (5.116287140914e-8 + 1.92901490874028e-6*taug)*taug) + pi*(
                0.0000114610381688305*o[2]*o[4]*taug + pi*(o[3]*(-1.00288598706366e-10
                 + o[8]*(-0.012702883392813 - 143.374451604624*o[2]*o[6]*taug)) + pi*
                (-4.1341695026989e-17 + o[2]*o[5]*(-8.8352662293707e-6 -
                0.272627897050173*o[9])*taug + pi*(o[5]*(9.0049690883672e-11 -
                65.8490727183984*o[4]*o[5]*o[6]) + pi*(1.78287415218792e-7*o[8] + pi*
                (o[4]*(1.0406965210174e-18 + o[2]*(-1.0234747095929e-12 -
                1.0018179379511e-8*o[4])*o[4]) + o[10]*o[11]*((-1.29412653835176e-9
                 + 1.71088510070544*o[12])*o[7] + o[10]*(-6.05920510335078*o[13]*o[5]
                *o[6]*taug + o[10]*(o[4]*o[6]*(1.78371690710842e-23 + o[2]*o[4]*o[5]*
                (6.1258633752464e-12 - 0.000084004935396416*o[8])*taug) + pi*(-1.24017662339842e-24
                *o[12] + pi*(0.0000832192847496054*o[13]*o[4]*o[6]*taug + pi*(o[2]*o[
                5]*o[6]*(1.75410265428146e-27 + (1.32995316841867e-15 -
                0.0000226487297378904*o[2]*o[6])*o[9])*pi - 2.93678005497663e-14*o[13]
                *o[2]*o[4]*taug)))))))))))))))))/pi;
              d := p/(data.RH2O*T*pi*gpi23);
            end dofp23;

            function dofpt3 "Inverse iteration in region 3: (d) = f(p,T)"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.Temperature T "Temperature (K)";
              input SI.Pressure delp "Iteration converged if (p-pre(p) < delp)";
              output SI.Density d "Density";
              output Integer error=0
                "Error flag: iteration failed if different from 0";
          protected
              SI.Density dguess "Guess density";
              Integer i=0 "Loop counter";
              Real dp "Pressure difference";
              SI.Density deld "Density step";
              Modelica.Media.Common.HelmholtzDerivs f
                "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              Modelica.Media.Common.NewtonDerivatives_pT nDerivs
                "Derivatives needed in Newton iteration";
              Boolean found=false "Flag for iteration success";
              Boolean supercritical "Flag, true for supercritical states";
              Boolean liquid "Flag, true for liquid states";
              SI.Density dmin "Lower density limit";
              SI.Density dmax "Upper density limit";
              SI.Temperature Tmax "Maximum temperature";
              Real damping "Damping factor";
            algorithm
              found := false;
              assert(p >= data.PLIMIT4A,
                "BaseIF97.dofpt3: function called outside of region 3! p too low\n"
                 + "p = " + String(p) + " Pa < " + String(data.PLIMIT4A) + " Pa");
              assert(T >= data.TLIMIT1,
                "BaseIF97.dofpt3: function called outside of region 3! T too low\n"
                 + "T = " + String(T) + " K < " + String(data.TLIMIT1) + " K");
              assert(p >= Regions.boundary23ofT(T),
                "BaseIF97.dofpt3: function called outside of region 3! T too high\n"
                 + "p = " + String(p) + " Pa, T = " + String(T) + " K");
              supercritical := p > data.PCRIT;
              damping := if supercritical then 1.0 else 1.0;
              Tmax := Regions.boundary23ofp(p);
              if supercritical then
                dmax := dofp13(p);
                dmin := dofp23(p);
                dguess := dmax - (T - data.TLIMIT1)/(data.TLIMIT1 - Tmax)*(dmax -
                  dmin);
                //this may need even further improvement!!
              else
                liquid := T < Basic.tsat(p);
                if liquid then
                  dmax := dofp13(p);
                  dmin := Regions.rhol_p_R4b(p);
                  dguess := 1.1*Regions.rhol_T(T)
                    "Guess: 10 percent more than on the phase boundary for same T";
                  //      dguess := 0.5*(dmax + dmin);
                else
                  dmax := Regions.rhov_p_R4b(p);
                  dmin := dofp23(p);
                  dguess := 0.9*Regions.rhov_T(T)
                    "Guess: 10% less than on the phase boundary for same T";
                  //      dguess := 0.5*(dmax + dmin);
                end if;
              end if;
              while ((i < IterationData.IMAX) and not found) loop
                d := dguess;
                f := Basic.f3(d, T);
                nDerivs := Modelica.Media.Common.Helmholtz_pT(f);
                dp := nDerivs.p - p;
                if (abs(dp/p) <= delp) then
                  found := true;
                end if;
                deld := dp/nDerivs.pd*damping;
                d := d - deld;
                if d > dmin and d < dmax then
                  dguess := d;
                else
                  if d > dmax then
                    dguess := dmax - sqrt(Modelica.Constants.eps);
                    // put it on the correct spot just inside the boundary here instead
                  else
                    dguess := dmin + sqrt(Modelica.Constants.eps);
                  end if;
                end if;
                i := i + 1;
              end while;
              if not found then
                error := 1;
              end if;
              assert(error <> 1, "Error in inverse function dofpt3: iteration failed");
            end dofpt3;

            function dtofph3 "Inverse iteration in region 3: (d,T) = f(p,h)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              input SI.Pressure delp "Iteration accuracy";
              input SI.SpecificEnthalpy delh "Iteration accuracy";
              output SI.Density d "Density";
              output SI.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";
          protected
              SI.Temperature Tguess "Initial temperature";
              SI.Density dguess "Initial density";
              Integer i "Iteration counter";
              Real dh "Newton-error in h-direction";
              Real dp "Newton-error in p-direction";
              Real det "Determinant of directional derivatives";
              Real deld "Newton-step in d-direction";
              Real delt "Newton-step in T-direction";
              Modelica.Media.Common.HelmholtzDerivs f
                "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              Modelica.Media.Common.NewtonDerivatives_ph nDerivs
                "Derivatives needed in Newton iteration";
              Boolean found=false "Flag for iteration success";
              Integer subregion "1 for subregion 3a, 2 for subregion 3b";
            algorithm
              if p < data.PCRIT then
                // allow a 10 J margin inside the (well approximated) phase boundary
                subregion := if h < (Regions.hl_p(p) + 10.0) then 1 else if h > (
                  Regions.hv_p(p) - 10.0) then 2 else 0;
                assert(subregion <> 0,
                  "Inverse iteration of dt from ph called in 2 phase region: this can not work");
              else
                //supercritical
                subregion := if h < Basic.h3ab_p(p) then 1 else 2;
              end if;
              T := if subregion == 1 then Basic.T3a_ph(p, h) else Basic.T3b_ph(p, h);
              d := if subregion == 1 then 1/Basic.v3a_ph(p, h) else 1/Basic.v3b_ph(p,
                h);
              i := 0;
              error := 0;
              while ((i < IterationData.IMAX) and not found) loop
                f := Basic.f3(d, T);
                nDerivs := Modelica.Media.Common.Helmholtz_ph(f);
                dh := nDerivs.h - h;
                dp := nDerivs.p - p;
                if ((abs(dh/h) <= delh) and (abs(dp/p) <= delp)) then
                  found := true;
                end if;
                det := nDerivs.ht*nDerivs.pd - nDerivs.pt*nDerivs.hd;
                delt := (nDerivs.pd*dh - nDerivs.hd*dp)/det;
                deld := (nDerivs.ht*dp - nDerivs.pt*dh)/det;
                T := T - delt;
                d := d - deld;
                dguess := d;
                Tguess := T;
                i := i + 1;
                (d,T) := fixdT(dguess, Tguess);
              end while;
              if not found then
                error := 1;
              end if;
              assert(error <> 1,
                "Error in inverse function dtofph3: iteration failed");
            end dtofph3;

            function dtofps3 "Inverse iteration in region 3: (d,T) = f(p,s)"
              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              input SI.Pressure delp "Iteration accuracy";
              input SI.SpecificEntropy dels "Iteration accuracy";
              output SI.Density d "Density";
              output SI.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";
          protected
              SI.Temperature Tguess "Initial temperature";
              SI.Density dguess "Initial density";
              Integer i "Iteration counter";
              Real ds "Newton-error in s-direction";
              Real dp "Newton-error in p-direction";
              Real det "Determinant of directional derivatives";
              Real deld "Newton-step in d-direction";
              Real delt "Newton-step in T-direction";
              Modelica.Media.Common.HelmholtzDerivs f
                "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
              Modelica.Media.Common.NewtonDerivatives_ps nDerivs
                "Derivatives needed in Newton iteration";
              Boolean found "Flag for iteration success";
              Integer subregion "1 for subregion 3a, 2 for subregion 3b";
            algorithm
              i := 0;
              error := 0;
              found := false;
              if p < data.PCRIT then
                // allow a 1 J/K margin inside the (well approximated) phase boundary
                subregion := if s < (Regions.sl_p(p) + 10.0) then 1 else if s > (
                  Regions.sv_p(p) - 10.0) then 2 else 0;
                assert(subregion <> 0,
                  "Inverse iteration of dt from ps called in 2 phase region: this is illegal!");
              else
                subregion := if s < data.SCRIT then 1 else 2;
              end if;
              T := if subregion == 1 then Basic.T3a_ps(p, s) else Basic.T3b_ps(p, s);
              d := if subregion == 1 then 1/Basic.v3a_ps(p, s) else 1/Basic.v3b_ps(p,
                s);
              while ((i < IterationData.IMAX) and not found) loop
                f := Basic.f3(d, T);
                nDerivs := Modelica.Media.Common.Helmholtz_ps(f);
                ds := nDerivs.s - s;
                dp := nDerivs.p - p;
                if ((abs(ds/s) <= dels) and (abs(dp/p) <= delp)) then
                  found := true;
                end if;
                det := nDerivs.st*nDerivs.pd - nDerivs.pt*nDerivs.sd;
                delt := (nDerivs.pd*ds - nDerivs.sd*dp)/det;
                deld := (nDerivs.st*dp - nDerivs.pt*ds)/det;
                T := T - delt;
                d := d - deld;
                dguess := d;
                Tguess := T;
                i := i + 1;
                (d,T) := fixdT(dguess, Tguess);
              end while;
              if not found then
                error := 1;
              end if;
              assert(error <> 1,
                "Error in inverse function dtofps3: iteration failed");
            end dtofps3;

            function pofdt125 "Inverse iteration in region 1,2 and 5: p = g(d,T)"
              extends Modelica.Icons.Function;
              input SI.Density d "Density";
              input SI.Temperature T "Temperature (K)";
              input SI.Pressure reldd "Relative iteration accuracy of density";
              input Integer region
                "Region in IAPWS/IF97 in which inverse should be calculated";
              output SI.Pressure p "Pressure";
              output Integer error "Error flag: iteration failed if different from 0";
          protected
              Integer i "Counter for while-loop";
              Modelica.Media.Common.GibbsDerivs g
                "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              Boolean found "Flag if iteration has been successful";
              Real dd
                "Difference between density for guessed p and the current density";
              Real delp "Step in p in Newton-iteration";
              Real relerr "Relative error in d";
              SI.Pressure pguess1=1.0e6 "Initial pressure guess in region 1";
              SI.Pressure pguess2 "Initial pressure guess in region 2";
              constant SI.Pressure pguess5=0.5e6 "Initial pressure guess in region 5";
            algorithm
              i := 0;
              error := 0;
              pguess2 := 42800*d;
              found := false;
              if region == 1 then
                p := pguess1;
              elseif region == 2 then
                p := pguess2;
              else
                p := pguess5;
              end if;
              while ((i < IterationData.IMAX) and not found) loop
                if region == 1 then
                  g := Basic.g1(p, T);
                elseif region == 2 then
                  g := Basic.g2(p, T);
                else
                  g := Basic.g5(p, T);
                end if;
                dd := p/(data.RH2O*T*g.pi*g.gpi) - d;
                relerr := dd/d;
                if (abs(relerr) < reldd) then
                  found := true;
                end if;
                delp := dd*(-p*p/(d*d*data.RH2O*T*g.pi*g.pi*g.gpipi));
                p := p - delp;
                i := i + 1;
                if not found then
                  if p < triple.ptriple then
                    p := 2.0*triple.ptriple;
                  end if;
                  if p > data.PLIMIT1 then
                    p := 0.95*data.PLIMIT1;
                  end if;
                end if;
              end while;

              // print("i = " + i2s(i) + ", p = " + r2s(p/1.0e5) + ", delp = " + r2s(delp*1.0e-5) + "\n");
              if not found then
                error := 1;
              end if;
              assert(error <> 1,
                "Error in inverse function pofdt125: iteration failed");
            end pofdt125;

            function tofph5 "Inverse iteration in region 5: (p,T) = f(p,h)"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEnthalpy h "Specific enthalpy";
              input SI.SpecificEnthalpy reldh "Iteration accuracy";
              output SI.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";

          protected
              Modelica.Media.Common.GibbsDerivs g
                "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              SI.SpecificEnthalpy proh "H for current guess in T";
              constant SI.Temperature Tguess=1500 "Initial temperature";
              Integer i "Iteration counter";
              Real relerr "Relative error in h";
              Real dh "Newton-error in h-direction";
              Real dT "Newton-step in T-direction";
              Boolean found "Flag for iteration success";
            algorithm
              i := 0;
              error := 0;
              T := Tguess;
              found := false;
              while ((i < IterationData.IMAX) and not found) loop
                g := Basic.g5(p, T);
                proh := data.RH2O*T*g.tau*g.gtau;
                dh := proh - h;
                relerr := dh/h;
                if (abs(relerr) < reldh) then
                  found := true;
                end if;
                dT := dh/(-data.RH2O*g.tau*g.tau*g.gtautau);
                T := T - dT;
                i := i + 1;
              end while;
              if not found then
                error := 1;
              end if;
              assert(error <> 1, "Error in inverse function tofph5: iteration failed");
            end tofph5;

            function tofps5 "Inverse iteration in region 5: (p,T) = f(p,s)"

              extends Modelica.Icons.Function;
              input SI.Pressure p "Pressure";
              input SI.SpecificEntropy s "Specific entropy";
              input SI.SpecificEnthalpy relds "Iteration accuracy";
              output SI.Temperature T "Temperature (K)";
              output Integer error "Error flag: iteration failed if different from 0";

          protected
              Modelica.Media.Common.GibbsDerivs g
                "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
              SI.SpecificEntropy pros "S for current guess in T";
              parameter SI.Temperature Tguess=1500 "Initial temperature";
              Integer i "Iteration counter";
              Real relerr "Relative error in s";
              Real ds "Newton-error in s-direction";
              Real dT "Newton-step in T-direction";
              Boolean found "Flag for iteration success";
            algorithm
              i := 0;
              error := 0;
              T := Tguess;
              found := false;
              while ((i < IterationData.IMAX) and not found) loop
                g := Basic.g5(p, T);
                pros := data.RH2O*(g.tau*g.gtau - g.g);
                ds := pros - s;
                relerr := ds/s;
                if (abs(relerr) < relds) then
                  found := true;
                end if;
                dT := ds*T/(-data.RH2O*g.tau*g.tau*g.gtautau);
                T := T - dT;
                i := i + 1;
              end while;
              if not found then
                error := 1;
              end if;
              assert(error <> 1, "Error in inverse function tofps5: iteration failed");
            end tofps5;
            annotation (Documentation(info="<html><h4>Package description</h4>
          <h4>Package contents</h4>
          <ul>
          <li>Function <strong>fixdT</strong> constrains density and temperature to allowed region</li>
          <li>Function <strong>dofp13</strong> computes d as a function of p at boundary between regions 1 and 3</li>
          <li>Function <strong>dofp23</strong> computes d as a function of p at boundary between regions 2 and 3</li>
          <li>Function <strong>dofpt3</strong> iteration to compute d as a function of p and T in region 3</li>
          <li>Function <strong>dtofph3</strong> iteration to compute d and T as a function of p and h in region 3</li>
          <li>Function <strong>dtofps3</strong> iteration to compute d and T as a function of p and s in region 3</li>
          <li>Function <strong>dtofpsdt3</strong> iteration to compute d and T as a function of p and s in region 3,
          with initial guesses</li>
          <li>Function <strong>pofdt125</strong> iteration to compute p as a function of p and T in regions 1, 2 and 5</li>
          <li>Function <strong>tofph5</strong> iteration to compute T as a function of p and h in region 5</li>
          <li>Function <strong>tofps5</strong> iteration to compute T as a function of p and s in region 5</li>
          <li>Function <strong>tofpst5</strong> iteration to compute T as a function of p and s in region 5, with initial guess in T</li>
          </ul>
          <h4>Version Info and Revision history
          </h4>
          <ul>
          <li>First implemented: <em>July, 2000</em>
          by Hubertus Tummescheit
          </li>
          </ul>
          <address>Author: Hubertus Tummescheit,<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
          </address>
          <ul>
          <li>Initial version: July 2000</li>
          <li>Documentation added: December 2002</li>
          </ul>
          </html>"));
          end Inverses;
          annotation (Documentation(info="<html>
<style type=\"text/css\">
.nobr
{
white-space:nowrap;
}
</style>
    <h4>Version Info and Revision history</h4>
        <ul>
        <li>First implemented: <em>July, 2000</em>
        by Hubertus Tummescheit
        for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
        </li>
      <li>Code reorganization, enhanced documentation, additional functions:   <em>December, 2002</em>
      by <a href=\"mailto:Hubertus.Tummescheit@modelon.se\">Hubertus Tummescheit</a> and moved to Modelica
      properties library.</li>
        </ul>
      <address>Author: Hubertus Tummescheit,<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
      </address>
        <p>In September 1997, the International Association for the Properties
        of Water and Steam (<a href=\"http://www.iapws.org\">IAPWS</a>) adopted a
        new formulation for the thermodynamic properties of water and steam for
        industrial use. This new industrial standard is called \"IAPWS Industrial
        Formulation for the Thermodynamic Properties of Water and Steam\" (IAPWS-IF97).
        The formulation IAPWS-IF97 replaces the previous industrial standard IFC-67.</p>
        <p>Based on this new formulation, a new steam table, titled \"<a href=\"https://doi.org/10.1007/978-3-662-03529-0\">Properties of Water and Steam</a>\" by W. Wagner and A. Kruse, was published by
        the Springer-Verlag, Berlin - New-York - Tokyo in April 1998. This
        steam table, ref. <a href=\"#steamprop\">[1]</a> is bilingual (English /
        German) and contains a complete description of the equations of
        IAPWS-IF97. This reference is the authoritative source of information
        for this implementation. A mostly identical version has been published by the International
        Association for the Properties
        of Water and Steam (<a href=\"http://www.iapws.org\">IAPWS</a>) with permission granted to re-publish the
        information if credit is given to IAPWS. This document is distributed with this library as
        <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a>.
        In addition, the equations published by <a href=\"http://www.iapws.org\">IAPWS</a> for
        the transport properties dynamic viscosity (standards document: <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/visc.pdf\">visc.pdf</a>)
        and thermal conductivity (standards document: <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/thcond.pdf\">thcond.pdf</a>)
        and equations for the surface tension (standards document: <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/surf.pdf\">surf.pdf</a>)
        are also implemented in this library and included for reference.</p>
        <p>
        The functions in BaseIF97.mo are low level functions which should
        only be used in those exceptions when the standard user level
        functions in Water.mo do not contain the wanted properties.
     </p>
<p>Based on IAPWS-IF97, Modelica functions are available for calculating
the most common thermophysical properties (thermodynamic and transport
properties). The implementation requires part of the common medium
property infrastructure of the Modelica.Thermal.Properties library in the file
Common.mo. There are a few extensions from the version of IF97 as
documented in <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a> in order to improve performance for
dynamic simulations. Input variables for calculating the properties are
only implemented for a limited number of variable pairs which make sense as dynamic states: (p,h), (p,T), (p,s) and (d,T).
</p>
<hr size=\"3\" width=\"70%\">
<h4><a name=\"regions\">1. Structure and Regions of IAPWS-IF97</a></h4>
<p>The IAPWS Industrial Formulation 1997 consists of
a set of equations for different regions which cover the following range
of validity:</p>
<table border=\"0\" cellpadding=\"4\">
<tr>
<td>273,15 K &lt; <em>T</em> &lt; 1073,15 K</td>
<td><em>p</em> &lt; 100 MPa</td>
</tr>
<tr>
<td>1073,15 K &lt; <em>T</em> &lt; 2273,15 K</td>
<td><em>p</em> &lt; 10 MPa</td>
</tr>
</table>
<p>
Figure 1 shows the 5 regions into which the entire range of validity of
IAPWS-IF97 is divided. The boundaries of the regions can be directly taken
from Fig. 1 except for the boundary between regions 2 and 3; this boundary,
which corresponds approximately to the isentropic line <span class=\"nobr\"><em>s</em> = 5.047 kJ kg
<sup>-1</sup>K<sup>-1</sup></span>, is defined
by a corresponding auxiliary equation. Both regions 1 and 2 are individually
covered by a fundamental equation for the specific Gibbs free energy <span class=\"nobr\"><em>g</em>( <em>p</em>,<em>T</em> )</span>, region 3 by a fundamental equation for the specific Helmholtz
free energy <span class=\"nobr\"><em>f </em>(<em> <font face=\"symbol\">r</font></em>,<em>T
</em>)</span>, and the saturation curve, corresponding to region 4, by a saturation-pressure
equation <span><em>p</em><sub>s</sub>( <em>T</em> )</span>. The high-temperature
region 5 is also covered by a <span class=\"nobr\"><em>g</em>( <em>p</em>,<em>T</em> )</span> equation. These
5 equations, shown in rectangular boxes in Fig. 1, form the so-called <em>basic
equations</em>.
</p>
<table border=\"0\" cellspacing=\"0\" cellpadding=\"2\">
  <caption align=\"bottom\">Figure 1: Regions and equations of IAPWS-IF97</caption>
  <tr>
    <td>
    <img src=\"modelica://Modelica/Resources/Images/Media/Water/if97.png\" alt=\"Regions and equations of IAPWS-IF97\">
    </td>
  </tr>
</table>
<p>
In addition to these basic equations, so-called <em>backward
equations</em> are provided for regions 1, 2, and 4 in form of
<span class=\"nobr\"><em>T</em>( <em>p</em>,<em>h</em> )</span> and <span class=\"nobr\"><em>T</em>( <em>
p</em>,<em>s</em> )</span> for regions 1 and 2, and <span class=\"nobr\"><em>T</em><sub>s</sub>( <em>p</em> )</span> for region 4. These
backward equations, marked in grey in Fig. 1, were developed in such a
way that they are numerically very consistent with the corresponding
basic equation. Thus, properties as functions of&nbsp; <em>p</em>,<em>h
</em>and of&nbsp;<em> p</em>,<em>s </em>for regions 1 and 2, and of
<em>p</em> for region 4 can be calculated without any iteration. As a
result of this special concept for the development of the new
industrial standard IAPWS-IF97, the most important properties can be
calculated extremely quickly. All Modelica functions are optimized
with regard to short computing times.
</p>
<p>
The complete description of the individual equations of the new industrial
formulation IAPWS-IF97 is given in <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a>. Comprehensive information on
IAPWS-IF97 (requirements, concept, accuracy, consistency along region boundaries,
and the increase of computing speed in comparison with IFC-67, etc.) can
be taken from <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a> or [2].
</p>
<p>
<a name=\"steamprop\">[1]<em>Wagner, W., Kruse, A.</em> Properties of Water
and Steam / Zustandsgr&ouml;&szlig;en von Wasser und Wasserdampf / IAPWS-IF97.
Springer-Verlag, Berlin, 1998.</a>
</p>
<p>
[2] <em>Wagner, W., Cooper, J. R., Dittmann, A., Kijima,
J., Kretzschmar, H.-J., Kruse, A., Mare&#353; R., Oguchi, K., Sato, H., St&ouml;cker,
I., &#352;ifner, O., Takaishi, Y., Tanishita, I., Tr&uuml;benbach, J., and Willkommen,
Th.</em> The IAPWS Industrial Formulation 1997 for the Thermodynamic Properties
of Water and Steam. ASME Journal of Engineering for Gas Turbines and Power 122 (2000), 150 - 182.
</p>
<hr size=\"3\" width=\"90%\">
<h4>2. Calculable Properties      </h4>
<table border=\"1\" cellpadding=\"2\" cellspacing=\"0\">
       <tbody>
       <tr>
       <td bgcolor=\"#cccccc\"><br>
      </td>
      <td bgcolor=\"#cccccc\"><strong>Common name</strong><br>
       </td>
       <td bgcolor=\"#cccccc\"><strong>Abbreviation</strong><br>
       </td>
       <td bgcolor=\"#cccccc\"><strong>Unit</strong><br>
       </td>
       </tr>
       <tr>
       <td>&nbsp;1<br>
      </td>
      <td>Pressure</td>
       <td>p<br>
        </td>
       <td>Pa<br>
       </td>
       </tr>
       <tr>
       <td>&nbsp;2<br>
      </td>
      <td>Temperature</td>
       <td>T<br>
       </td>
       <td>K<br>
       </td>
       </tr>
       <tr>
       <td>&nbsp;3<br>
      </td>
      <td>Density</td>
        <td>d<br>
        </td>
       <td>kg/m<sup>3</sup><br>
       </td>
       </tr>
       <tr>
       <td>&nbsp;4<br>
      </td>
      <td>Specific volume</td>
        <td>v<br>
        </td>
       <td>m<sup>3</sup>/kg<br>
       </td>
       </tr>
       <tr>
       <td>&nbsp;5<br>
      </td>
      <td>Specific enthalpy</td>
       <td>h<br>
       </td>
       <td>J/kg<br>
       </td>
       </tr>
       <tr>
       <td>&nbsp;6<br>
      </td>
      <td>Specific entropy</td>
       <td>s<br>
       </td>
       <td>J/(kg K)<br>
       </td>
       </tr>
       <tr>
       <td>&nbsp;7<br>
      </td>
      <td>Specific internal energy<br>
       </td>
       <td>u<br>
       </td>
       <td>J/kg<br>
       </td>
       </tr>
       <tr>
       <td>&nbsp;8<br>
      </td>
      <td>Specific isobaric heat capacity</td>
       <td>c<sub>p</sub><br>
       </td>
       <td>J/(kg K)<br>
       </td>
       </tr>
       <tr>
       <td>&nbsp;9<br>
      </td>
      <td>Specific isochoric heat capacity</td>
       <td>c<sub>v</sub><br>
       </td>
       <td>J/(kg K)<br>
       </td>
       </tr>
       <tr>
       <td>10<br>
      </td>
      <td>Isentropic exponent, kappa = -(v/p) (dp/dv)<sub>s</sub></td>
     <td>kappa (&kappa;)<br>
     </td>
     <td>1<br>
     </td>
     </tr>
     <tr>
     <td>11<br>
      </td>
      <td>Speed of sound<br>
     </td>
     <td>a<br>
     </td>
     <td>m/s<br>
     </td>
     </tr>
     <tr>
     <td>12<br>
      </td>
      <td>Dryness fraction<br>
     </td>
     <td>x<br>
     </td>
     <td>kg/kg<br>
     </td>
     </tr>
     <tr>
     <td>13<br>
      </td>
      <td>Specific Helmholtz free energy, f = u - Ts</td>
     <td>f<br>
     </td>
     <td>J/kg<br>
     </td>
     </tr>
     <tr>
     <td>14<br>
      </td>
      <td>Specific Gibbs free energy, g = h - Ts</td>
     <td>g<br>
     </td>
     <td>J/kg<br>
     </td>
     </tr>
     <tr>
     <td>15<br>
      </td>
      <td>Isenthalpic exponent, theta = -(v/p) (dp/dv)<sub>h</sub></td>
     <td>theta (&theta;)<br>
     </td>
     <td>1<br>
     </td>
     </tr>
     <tr>
     <td>16<br>
      </td>
      <td>Isobaric volume expansion coefficient, alpha = v<sup>-1</sup> (dv/dT)<sub>p</sub></td>
     <td>alpha (&alpha;)<br>
     </td>
       <td>1/K<br>
     </td>
     </tr>
     <tr>
     <td>17<br>
      </td>
      <td>Isochoric pressure coefficient, beta = p<sup>-1</sup>(dp/dT)<sub>v</sub></td>
     <td>beta (&beta;)<br>
     </td>
     <td>1/K<br>
     </td>
     </tr>
     <tr>
     <td>18<br>
     </td>
     <td>Isothermal compressibility, gamma = -v<sup>-1</sup>(dv/dp)<sub>T</sub></td>
     <td>gamma (&gamma;)<br>
     </td>
     <td>1/Pa<br>
     </td>
     </tr>
     <!-- <tr><td>f</td><td>Fugacity</td></tr> --> <tr>
     <td>19<br>
      </td>
      <td>Dynamic viscosity</td>
     <td>eta (&eta;)<br>
     </td>
     <td>Pa s<br>
     </td>
     </tr>
     <tr>
     <td>20<br>
      </td>
      <td>Kinematic viscosity</td>
     <td>nu (&nu;)<br>
     </td>
     <td>m<sup>2</sup>/s<br>
     </td>
     </tr>
     <!-- <tr><td>Pr</td><td>Prandtl number</td></tr> --> <tr>
     <td>21<br>
      </td>
      <td>Thermal conductivity</td>
     <td>lambda (&lambda;)<br>
     </td>
     <td>W/(m K)<br>
     </td>
     </tr>
     <tr>
     <td>22<br>
      </td>
      <td>Surface tension</td>
     <td>sigma (&sigma;)<br>
     </td>
     <td>N/m<br>
     </td>
     </tr>
  </tbody>
</table>
        <p>The properties 1-11 are calculated by default with the functions for dynamic
        simulation, 2 of these variables are the dynamic states and are the inputs
        to calculate all other properties. In addition to these properties
        of general interest, the entries to the thermodynamic Jacobian matrix which render
        the mass- and energy balances explicit in the input variables to the property calculation are also calculated.
        For an explanatory example using pressure and specific enthalpy as states, see the Examples sub-package.</p>
        <p>The high-level calls to steam properties are grouped into records comprising both the properties of general interest
        and the entries to the thermodynamic Jacobian. If additional properties are
        needed the low level functions in BaseIF97 provide more choice.</p>
        <hr size=\"3\" width=\"90%\">
        <h4>Additional functions</h4>
        <ul>
        <li>Function <strong>boundaryvals_p</strong> computes the temperature and the specific enthalpy and
        entropy on both phase boundaries as a function of p</li>
        <li>Function <strong>boundaryderivs_p</strong> is the Modelica derivative function of <strong>boundaryvals_p</strong></li>
        <li>Function <strong>extraDerivs_ph</strong> computes all entries to Bridgmans tables for all
        one-phase regions of IF97 using inputs (p,h). All 336 directional derivatives of the
        thermodynamic surface can be computed as a ratio of two entries in the return data, see package Common
        for details.</li>
        <li>Function <strong>extraDerivs_pT</strong> computes all entries to Bridgmans tables for all
        one-phase regions of IF97 using inputs (p,T).</li>
        </ul>
        </html>"));
        end BaseIF97;

        function waterBaseProp_ph "Intermediate property record for water"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0
            "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
          input Integer region=0
            "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
      protected
          Common.GibbsDerivs g
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
          SI.SpecificEnthalpy h_liq "Liquid specific enthalpy";
          SI.Density d_liq "Liquid density";
          SI.SpecificEnthalpy h_vap "Vapour specific enthalpy";
          SI.Density d_vap "Vapour density";
          Common.PhaseBoundaryProperties liq "Phase boundary property record";
          Common.PhaseBoundaryProperties vap "Phase boundary property record";
          Common.GibbsDerivs gl
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.GibbsDerivs gv
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Modelica.Media.Common.HelmholtzDerivs fl
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Modelica.Media.Common.HelmholtzDerivs fv
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          SI.Temperature t1
            "Temperature at phase boundary, using inverse from region 1";
          SI.Temperature t2
            "Temperature at phase boundary, using inverse from region 2";
        algorithm
          aux.region := if region == 0 then (if phase == 2 then 4 else
            BaseIF97.Regions.region_ph(
              p=p,
              h=h,
              phase=phase)) else region;
          aux.phase := if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
          aux.p := max(p, 611.657);
          aux.h := max(h, 1e3);
          aux.R_s := BaseIF97.data.RH2O;
          aux.vt := 0.0 "Initialized in case it is not needed";
          aux.vp := 0.0 "Initialized in case it is not needed";
          if (aux.region == 1) then
            aux.T := BaseIF97.Basic.tph1(aux.p, aux.h);
            g := BaseIF97.Basic.g1(p, aux.T);
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 0.0;
            aux.dpT := -aux.vt/aux.vp;
          elseif (aux.region == 2) then
            aux.T := BaseIF97.Basic.tph2(aux.p, aux.h);
            g := BaseIF97.Basic.g2(p, aux.T);
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 1.0;
            aux.dpT := -aux.vt/aux.vp;
          elseif (aux.region == 3) then
            (aux.rho,aux.T,error) := BaseIF97.Inverses.dtofph3(
                p=aux.p,
                h=aux.h,
                delp=1.0e-7,
                delh=1.0e-6);
            f := BaseIF97.Basic.f3(aux.rho, aux.T);
            aux.h := aux.R_s*aux.T*(f.tau*f.ftau + f.delta*f.fdelta);
            aux.s := aux.R_s*(f.tau*f.ftau - f.f);
            aux.pd := aux.R_s*aux.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
            aux.pt := aux.R_s*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
            aux.cv := abs(aux.R_s*(-f.tau*f.tau*f.ftautau))
              "Can be close to neg. infinity near critical point";
            aux.cp := (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*
              aux.rho*aux.pd);
            aux.x := 0.0;
            aux.dpT := aux.pt;
            /*safety against div-by-0 in initialization*/
          elseif (aux.region == 4) then
            h_liq := hl_p(p);
            h_vap := hv_p(p);
            aux.x := if (h_vap <> h_liq) then (h - h_liq)/(h_vap - h_liq) else 1.0;
            if p < BaseIF97.data.PLIMIT4A then
              t1 := BaseIF97.Basic.tph1(aux.p, h_liq);
              t2 := BaseIF97.Basic.tph2(aux.p, h_vap);
              gl := BaseIF97.Basic.g1(aux.p, t1);
              gv := BaseIF97.Basic.g2(aux.p, t2);
              liq := Common.gibbsToBoundaryProps(gl);
              vap := Common.gibbsToBoundaryProps(gv);
              aux.T := t1 + aux.x*(t2 - t1);
            else
              aux.T := BaseIF97.Basic.tsat(aux.p);
              // how to avoid ?
              d_liq := rhol_T(aux.T);
              d_vap := rhov_T(aux.T);
              fl := BaseIF97.Basic.f3(d_liq, aux.T);
              fv := BaseIF97.Basic.f3(d_vap, aux.T);
              liq := Common.helmholtzToBoundaryProps(fl);
              vap := Common.helmholtzToBoundaryProps(fv);
              //  aux.dpT := BaseIF97.Basic.dptofT(aux.T);
            end if;
            aux.dpT := if (liq.d <> vap.d) then (vap.s - liq.s)*liq.d*vap.d/(liq.d -
              vap.d) else BaseIF97.Basic.dptofT(aux.T);
            aux.s := liq.s + aux.x*(vap.s - liq.s);
            aux.rho := liq.d*vap.d/(vap.d + aux.x*(liq.d - vap.d));
            aux.cv := Common.cv2Phase(
                liq,
                vap,
                aux.x,
                aux.T,
                p);
            aux.cp := liq.cp + aux.x*(vap.cp - liq.cp);
            aux.pt := liq.pt + aux.x*(vap.pt - liq.pt);
            aux.pd := liq.pd + aux.x*(vap.pd - liq.pd);
          elseif (aux.region == 5) then
            (aux.T,error) := BaseIF97.Inverses.tofph5(
                p=aux.p,
                h=aux.h,
                reldh=1.0e-7);
            assert(error == 0, "Error in inverse iteration of steam tables");
            g := BaseIF97.Basic.g5(aux.p, aux.T);
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.dpT := -aux.vt/aux.vp;
          else
            assert(false, "Error in region computation of IF97 steam tables" +
              "(p = " + String(p) + ", h = " + String(h) + ")");
          end if;
        end waterBaseProp_ph;

        function waterBaseProp_ps "Intermediate property record for water"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Integer phase=0
            "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
          input Integer region=0
            "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
      protected
          Common.GibbsDerivs g
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
          SI.SpecificEntropy s_liq "Liquid specific entropy";
          SI.Density d_liq "Liquid density";
          SI.SpecificEntropy s_vap "Vapour specific entropy";
          SI.Density d_vap "Vapour density";
          Common.PhaseBoundaryProperties liq "Phase boundary property record";
          Common.PhaseBoundaryProperties vap "Phase boundary property record";
          Common.GibbsDerivs gl
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.GibbsDerivs gv
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Modelica.Media.Common.HelmholtzDerivs fl
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Modelica.Media.Common.HelmholtzDerivs fv
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          SI.Temperature t1
            "Temperature at phase boundary, using inverse from region 1";
          SI.Temperature t2
            "Temperature at phase boundary, using inverse from region 2";
        algorithm
          aux.region := if region == 0 then (if phase == 2 then 4 else
            BaseIF97.Regions.region_ps(
              p=p,
              s=s,
              phase=phase)) else region;
          aux.phase := if phase <> 0 then phase else if aux.region == 4 then 2 else 1;
          aux.p := p;
          aux.s := s;
          aux.R_s := BaseIF97.data.RH2O;
          aux.vt := 0.0 "Initialized in case it is not needed";
          aux.vp := 0.0 "Initialized in case it is not needed";
          if (aux.region == 1) then
            aux.T := BaseIF97.Basic.tps1(p, s);
            g := BaseIF97.Basic.g1(p, aux.T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 0.0;
            aux.dpT := -aux.vt/aux.vp;
          elseif (aux.region == 2) then
            aux.T := BaseIF97.Basic.tps2(p, s);
            g := BaseIF97.Basic.g2(p, aux.T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 1.0;
            aux.dpT := -aux.vt/aux.vp;
          elseif (aux.region == 3) then
            (aux.rho,aux.T,error) := BaseIF97.Inverses.dtofps3(
                p=p,
                s=s,
                delp=1.0e-7,
                dels=1.0e-6);
            f := BaseIF97.Basic.f3(aux.rho, aux.T);
            aux.h := aux.R_s*aux.T*(f.tau*f.ftau + f.delta*f.fdelta);
            aux.s := aux.R_s*(f.tau*f.ftau - f.f);
            aux.pd := aux.R_s*aux.T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
            aux.pt := aux.R_s*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
            aux.cv := aux.R_s*(-f.tau*f.tau*f.ftautau);
            aux.cp := (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*
              aux.rho*aux.pd);
            aux.x := 0.0;
            aux.dpT := aux.pt;
            /*safety against div-by-0 in initialization*/
          elseif (aux.region == 4) then
            s_liq := BaseIF97.Regions.sl_p(p);
            s_vap := BaseIF97.Regions.sv_p(p);
            aux.x := if (s_vap <> s_liq) then (s - s_liq)/(s_vap - s_liq) else 1.0;
            if p < BaseIF97.data.PLIMIT4A then
              t1 := BaseIF97.Basic.tps1(p, s_liq);
              t2 := BaseIF97.Basic.tps2(p, s_vap);
              gl := BaseIF97.Basic.g1(p, t1);
              gv := BaseIF97.Basic.g2(p, t2);
              liq := Common.gibbsToBoundaryProps(gl);
              vap := Common.gibbsToBoundaryProps(gv);
              aux.T := t1 + aux.x*(t2 - t1);
            else
              aux.T := BaseIF97.Basic.tsat(p);
              d_liq := rhol_T(aux.T);
              d_vap := rhov_T(aux.T);
              fl := BaseIF97.Basic.f3(d_liq, aux.T);
              fv := BaseIF97.Basic.f3(d_vap, aux.T);
              liq := Common.helmholtzToBoundaryProps(fl);
              vap := Common.helmholtzToBoundaryProps(fv);
            end if;
            aux.dpT := if (liq.d <> vap.d) then (vap.s - liq.s)*liq.d*vap.d/(liq.d -
              vap.d) else BaseIF97.Basic.dptofT(aux.T);
            aux.h := liq.h + aux.x*(vap.h - liq.h);
            aux.rho := liq.d*vap.d/(vap.d + aux.x*(liq.d - vap.d));
            aux.cv := Common.cv2Phase(
                liq,
                vap,
                aux.x,
                aux.T,
                p);
            aux.cp := liq.cp + aux.x*(vap.cp - liq.cp);
            aux.pt := liq.pt + aux.x*(vap.pt - liq.pt);
            aux.pd := liq.pd + aux.x*(vap.pd - liq.pd);
          elseif (aux.region == 5) then
            (aux.T,error) := BaseIF97.Inverses.tofps5(
                p=p,
                s=s,
                relds=1.0e-7);
            assert(error == 0, "Error in inverse iteration of steam tables");
            g := BaseIF97.Basic.g5(p, aux.T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.rho := p/(aux.R_s*aux.T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*aux.T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.dpT := -aux.vt/aux.vp;
            aux.x := 1.0;
          else
            assert(false, "Error in region computation of IF97 steam tables" +
              "(p = " + String(p) + ", s = " + String(s) + ")");
          end if;
        end waterBaseProp_ps;

        function rho_props_ps "Density as function of pressure and specific entropy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output SI.Density rho "Density";
        algorithm
          rho := properties.rho;
          annotation (Inline=false, LateInline=true);
        end rho_props_ps;

        function rho_ps "Density as function of pressure and specific entropy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.Density rho "Density";
        algorithm
          rho := rho_props_ps(
              p,
              s,
              waterBaseProp_ps(
                p,
                s,
                phase,
                region));
          annotation (Inline=true);
        end rho_ps;

        function T_props_ps
          "Temperature as function of pressure and specific entropy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output SI.Temperature T "Temperature";
        algorithm
          T := properties.T;
          annotation (Inline=false, LateInline=true);
        end T_props_ps;

        function T_ps "Temperature as function of pressure and specific entropy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.Temperature T "Temperature";
        algorithm
          T := T_props_ps(
              p,
              s,
              waterBaseProp_ps(
                p,
                s,
                phase,
                region));
          annotation (Inline=true);
        end T_ps;

        function h_props_ps
          "Specific enthalpy as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := aux.h;
          annotation (Inline=false, LateInline=true);
        end h_props_ps;

        function h_ps "Specific enthalpy as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := h_props_ps(
              p,
              s,
              waterBaseProp_ps(
                p,
                s,
                phase,
                region));
          annotation (Inline=true);
        end h_ps;

        function rho_props_ph "Density as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output SI.Density rho "Density";
        algorithm
          rho := properties.rho;
          annotation (
            derivative(noDerivative=properties) = rho_ph_der,
            Inline=false,
            LateInline=true);
        end rho_props_ph;

        function rho_ph "Density as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.Density rho "Density";
        algorithm
          rho := rho_props_ph(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end rho_ph;

        function rho_ph_der "Derivative function of rho_ph"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real h_der "Derivative of specific enthalpy";
          output Real rho_der "Derivative of density";
        algorithm
          if (properties.region == 4) then
            rho_der := (properties.rho*(properties.rho*properties.cv/properties.dpT + 1.0)/(properties.dpT*properties.T))*p_der
               + (-properties.rho*properties.rho/(properties.dpT*properties.T))*h_der;
          elseif (properties.region == 3) then
            rho_der := ((properties.rho*(properties.cv*properties.rho + properties.pt))/(properties.rho*properties.rho*properties.pd*
              properties.cv + properties.T*properties.pt*properties.pt))*p_der + (-properties.rho*properties.rho*properties.pt/(properties.rho
              *properties.rho*properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*h_der;
          else
            //regions 1,2,5
            rho_der := (-properties.rho*properties.rho*(properties.vp*properties.cp - properties.vt/properties.rho + properties.T*properties.vt
              *properties.vt)/properties.cp)*p_der + (-properties.rho*properties.rho*properties.vt/(properties.cp))*h_der;
          end if;
        end rho_ph_der;

        function T_props_ph
          "Temperature as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output SI.Temperature T "Temperature";
        algorithm
          T := properties.T;
          annotation (
            derivative(noDerivative=properties) = T_ph_der,
            Inline=false,
            LateInline=true);
        end T_props_ph;

        function T_ph "Temperature as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.Temperature T "Temperature";
        algorithm
          T := T_props_ph(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end T_ph;

        function T_ph_der "Derivative function of T_ph"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real h_der "Derivative of specific enthalpy";
          output Real T_der "Derivative of temperature";
        algorithm
          if (properties.region == 4) then
            T_der := 1/properties.dpT*p_der;
          elseif (properties.region == 3) then
            T_der := ((-properties.rho*properties.pd + properties.T*properties.pt)/(properties.rho*properties.rho*properties.pd*properties.cv
               + properties.T*properties.pt*properties.pt))*p_der + ((properties.rho*properties.rho*properties.pd)/(properties.rho*properties.rho
              *properties.pd*properties.cv + properties.T*properties.pt*properties.pt))*h_der;
          else
            //regions 1,2 or 5
            T_der := ((-1/properties.rho + properties.T*properties.vt)/properties.cp)*p_der + (1/properties.cp)*h_der;
          end if;
        end T_ph_der;

        function s_props_ph
          "Specific entropy as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := properties.s;
          annotation (
            derivative(noDerivative=properties) = s_ph_der,
            Inline=false,
            LateInline=true);
        end s_props_ph;

        function s_ph
          "Specific entropy as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := s_props_ph(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end s_ph;

        function s_ph_der
          "Specific entropy as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase properties "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real h_der "Derivative of specific enthalpy";
          output Real s_der "Derivative of entropy";
        algorithm
          s_der := -1/(properties.rho*properties.T)*p_der + 1/properties.T*h_der;
          annotation (Inline=true);
        end s_ph_der;

        function cv_props_ph
          "Specific heat capacity at constant volume as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := aux.cv;
          annotation (Inline=false, LateInline=true);
        end cv_props_ph;

        function cv_ph
          "Specific heat capacity at constant volume as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := cv_props_ph(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end cv_ph;

        function cp_props_ph
          "Specific heat capacity at constant pressure as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := aux.cp;
          annotation (Inline=false, LateInline=true);
        end cp_props_ph;

        function cp_ph
          "Specific heat capacity at constant pressure as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := cp_props_ph(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end cp_ph;

        function beta_props_ph
          "Isobaric expansion coefficient as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd)
             else aux.vt*aux.rho;
          annotation (Inline=false, LateInline=true);
        end beta_props_ph;

        function beta_ph
          "Isobaric expansion coefficient as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := beta_props_ph(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end beta_ph;

        function kappa_props_ph
          "Isothermal compressibility factor as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.IsothermalCompressibility kappa
            "Isothermal compressibility factor";
        algorithm
          kappa := if aux.region == 3 or aux.region == 4 then 1/(aux.rho*aux.pd)
             else -aux.vp*aux.rho;
          annotation (Inline=false, LateInline=true);
        end kappa_props_ph;

        function kappa_ph
          "Isothermal compressibility factor as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.IsothermalCompressibility kappa
            "Isothermal compressibility factor";
        algorithm
          kappa := kappa_props_ph(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end kappa_ph;

        function velocityOfSound_props_ph
          "Speed of sound as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          // dp/drho at constant s
          v_sound := if aux.region == 3 then sqrt(max(0, (aux.pd*aux.rho*aux.rho*aux.cv
             + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv))) else if aux.region ==
            4 then sqrt(max(0, 1/((aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*
            aux.T)) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T)))) else sqrt(max(0, -
            aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T))));
          annotation (Inline=false, LateInline=true);
        end velocityOfSound_props_ph;

        function velocityOfSound_ph
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := velocityOfSound_props_ph(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end velocityOfSound_ph;

        function isentropicExponent_props_ph
          "Isentropic exponent as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho
             + aux.pt*aux.pt*aux.T)/(aux.cv)) else if aux.region == 4 then 1/(aux.rho
            *p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*
            aux.cp + aux.vt*aux.vt*aux.T);
          annotation (Inline=false, LateInline=true);
        end isentropicExponent_props_ph;

        function isentropicExponent_ph
          "Isentropic exponent as function of pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := isentropicExponent_props_ph(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=false, LateInline=true);
        end isentropicExponent_ph;

        function ddph_props "Density derivative by pressure"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.DerDensityByPressure ddph "Density derivative by pressure";
        algorithm
          ddph := if aux.region == 3 then ((aux.rho*(aux.cv*aux.rho + aux.pt))/(aux.rho
            *aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)) else if aux.region == 4
             then (aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT*aux.T)) else (-aux.rho
            *aux.rho*(aux.vp*aux.cp - aux.vt/aux.rho + aux.T*aux.vt*aux.vt)/aux.cp);
          annotation (Inline=false, LateInline=true);
        end ddph_props;

        function ddph "Density derivative by pressure"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.DerDensityByPressure ddph "Density derivative by pressure";
        algorithm
          ddph := ddph_props(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end ddph;

        function ddhp_props "Density derivative by specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.DerDensityByEnthalpy ddhp
            "Density derivative by specific enthalpy";
        algorithm
          ddhp := if aux.region == 3 then -aux.rho*aux.rho*aux.pt/(aux.rho*aux.rho*
            aux.pd*aux.cv + aux.T*aux.pt*aux.pt) else if aux.region == 4 then -aux.rho
            *aux.rho/(aux.dpT*aux.T) else -aux.rho*aux.rho*aux.vt/(aux.cp);
          annotation (Inline=false, LateInline=true);
        end ddhp_props;

        function ddhp "Density derivative by specific enthalpy"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEnthalpy h "Specific enthalpy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.DerDensityByEnthalpy ddhp
            "Density derivative by specific enthalpy";
        algorithm
          ddhp := ddhp_props(
              p,
              h,
              waterBaseProp_ph(
                p,
                h,
                phase,
                region));
          annotation (Inline=true);
        end ddhp;

        function waterBaseProp_pT
          "Intermediate property record for water (p and T preferred states)"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
      protected
          Common.GibbsDerivs g
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
        algorithm
          aux.phase := 1;
          aux.region := if region == 0 then BaseIF97.Regions.region_pT(p=p, T=T)
             else region;
          aux.R_s := BaseIF97.data.RH2O;
          aux.p := p;
          aux.T := T;
          aux.vt := 0.0 "Initialized in case it is not needed";
          aux.vp := 0.0 "Initialized in case it is not needed";
          if (aux.region == 1) then
            g := BaseIF97.Basic.g1(p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 0.0;
            aux.dpT := -aux.vt/aux.vp;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
          elseif (aux.region == 2) then
            g := BaseIF97.Basic.g2(p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 1.0;
            aux.dpT := -aux.vt/aux.vp;
          elseif (aux.region == 3) then
            (aux.rho,error) := BaseIF97.Inverses.dofpt3(
                p=p,
                T=T,
                delp=1.0e-7);
            f := BaseIF97.Basic.f3(aux.rho, T);
            aux.h := aux.R_s*T*(f.tau*f.ftau + f.delta*f.fdelta);
            aux.s := aux.R_s*(f.tau*f.ftau - f.f);
            aux.pd := aux.R_s*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
            aux.pt := aux.R_s*aux.rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
            aux.cv := aux.R_s*(-f.tau*f.tau*f.ftautau);
            aux.x := 0.0;
            aux.dpT := aux.pt;
            /*safety against div-by-0 in initialization*/
          elseif (aux.region == 5) then
            g := BaseIF97.Basic.g5(p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(p*p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 1.0;
            aux.dpT := -aux.vt/aux.vp;
          else
            assert(false, "Error in region computation of IF97 steam tables" +
              "(p = " + String(p) + ", T = " + String(T) + ")");
          end if;
        end waterBaseProp_pT;

        function rho_props_pT "Density as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Density rho "Density";
        algorithm
          rho := aux.rho;
          annotation (
            derivative(noDerivative=aux) = rho_pT_der,
            Inline=false,
            LateInline=true);
        end rho_props_pT;

        function rho_pT "Density as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.Density rho "Density";
        algorithm
          rho := rho_props_pT(
              p,
              T,
              waterBaseProp_pT(
                p,
                T,
                region));
          annotation (Inline=true);
        end rho_pT;

        function h_props_pT
          "Specific enthalpy as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := aux.h;
          annotation (
            derivative(noDerivative=aux) = h_pT_der,
            Inline=false,
            LateInline=true);
        end h_props_pT;

        function h_pT "Specific enthalpy as function or pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := h_props_pT(
              p,
              T,
              waterBaseProp_pT(
                p,
                T,
                region));
          annotation (Inline=true);
        end h_pT;

        function h_pT_der "Derivative function of h_pT"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real T_der "Derivative of temperature";
          output Real h_der "Derivative of specific enthalpy";
        algorithm
          if (aux.region == 3) then
            h_der := ((-aux.rho*aux.pd + T*aux.pt)/(aux.rho*aux.rho*aux.pd))*p_der +
              ((aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*aux.rho
              *aux.pd))*T_der;
          else
            //regions 1,2 or 5
            h_der := (1/aux.rho - aux.T*aux.vt)*p_der + aux.cp*T_der;
          end if;
        end h_pT_der;

        function rho_pT_der "Derivative function of rho_pT"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Derivative of pressure";
          input Real T_der "Derivative of temperature";
          output Real rho_der "Derivative of density";
        algorithm
          if (aux.region == 3) then
            rho_der := (1/aux.pd)*p_der - (aux.pt/aux.pd)*T_der;
          else
            //regions 1,2 or 5
            rho_der := (-aux.rho*aux.rho*aux.vp)*p_der + (-aux.rho*aux.rho*aux.vt)*
              T_der;
          end if;
        end rho_pT_der;

        function s_props_pT
          "Specific entropy as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := aux.s;
          annotation (Inline=false, LateInline=true);
        end s_props_pT;

        function s_pT "Temperature as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := s_props_pT(
              p,
              T,
              waterBaseProp_pT(
                p,
                T,
                region));
          annotation (Inline=true);
        end s_pT;

        function cv_props_pT
          "Specific heat capacity at constant volume as function of pressure and temperature"

          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := aux.cv;
          annotation (Inline=false, LateInline=true);
        end cv_props_pT;

        function cv_pT
          "Specific heat capacity at constant volume as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := cv_props_pT(
              p,
              T,
              waterBaseProp_pT(
                p,
                T,
                region));
          annotation (Inline=true);
        end cv_pT;

        function cp_props_pT
          "Specific heat capacity at constant pressure as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := if aux.region == 3 then (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt
            *aux.pt)/(aux.rho*aux.rho*aux.pd) else aux.cp;
          annotation (Inline=false, LateInline=true);
        end cp_props_pT;

        function cp_pT
          "Specific heat capacity at constant pressure as function of pressure and temperature"

          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := cp_props_pT(
              p,
              T,
              waterBaseProp_pT(
                p,
                T,
                region));
          annotation (Inline=true);
        end cp_pT;

        function beta_props_pT
          "Isobaric expansion coefficient as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := if aux.region == 3 then aux.pt/(aux.rho*aux.pd) else aux.vt*aux.rho;
          annotation (Inline=false, LateInline=true);
        end beta_props_pT;

        function beta_pT
          "Isobaric expansion coefficient as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := beta_props_pT(
              p,
              T,
              waterBaseProp_pT(
                p,
                T,
                region));
          annotation (Inline=true);
        end beta_pT;

        function kappa_props_pT
          "Isothermal compressibility factor as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.IsothermalCompressibility kappa
            "Isothermal compressibility factor";
        algorithm
          kappa := if aux.region == 3 then 1/(aux.rho*aux.pd) else -aux.vp*aux.rho;
          annotation (Inline=false, LateInline=true);
        end kappa_props_pT;

        function kappa_pT
          "Isothermal compressibility factor as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.IsothermalCompressibility kappa
            "Isothermal compressibility factor";
        algorithm
          kappa := kappa_props_pT(
              p,
              T,
              waterBaseProp_pT(
                p,
                T,
                region));
          annotation (Inline=true);
        end kappa_pT;

        function velocityOfSound_props_pT
          "Speed of sound as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          // dp/drho at constant s
          v_sound := if aux.region == 3 then sqrt(max(0, (aux.pd*aux.rho*aux.rho*aux.cv
             + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv))) else sqrt(max(0, -aux.cp
            /(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T))));
          annotation (Inline=false, LateInline=true);
        end velocityOfSound_props_pT;

        function velocityOfSound_pT
          "Speed of sound as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := velocityOfSound_props_pT(
              p,
              T,
              waterBaseProp_pT(
                p,
                T,
                region));
          annotation (Inline=true);
        end velocityOfSound_pT;

        function isentropicExponent_props_pT
          "Isentropic exponent as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := if aux.region == 3 then 1/(aux.rho*p)*((aux.pd*aux.cv*aux.rho*aux.rho
             + aux.pt*aux.pt*aux.T)/(aux.cv)) else -1/(aux.rho*aux.p)*aux.cp/(aux.vp*
            aux.cp + aux.vt*aux.vt*aux.T);
          annotation (Inline=false, LateInline=true);
        end isentropicExponent_props_pT;

        function isentropicExponent_pT
          "Isentropic exponent as function of pressure and temperature"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.Temperature T "Temperature";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := isentropicExponent_props_pT(
              p,
              T,
              waterBaseProp_pT(
                p,
                T,
                region));
          annotation (Inline=false, LateInline=true);
        end isentropicExponent_pT;

        function waterBaseProp_dT
          "Intermediate property record for water (d and T preferred states)"
          extends Modelica.Icons.Function;
          input SI.Density rho "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0
            "Phase: 2 for two-phase, 1 for one phase, 0 if unknown";
          input Integer region=0
            "If 0, do region computation, otherwise assume the region is this input";
          output Common.IF97BaseTwoPhase aux "Auxiliary record";
      protected
          SI.SpecificEnthalpy h_liq "Liquid specific enthalpy";
          SI.Density d_liq "Liquid density";
          SI.SpecificEnthalpy h_vap "Vapour specific enthalpy";
          SI.Density d_vap "Vapour density";
          Common.GibbsDerivs g
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Common.HelmholtzDerivs f
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Modelica.Media.Common.PhaseBoundaryProperties liq
            "Phase boundary property record";
          Modelica.Media.Common.PhaseBoundaryProperties vap
            "Phase boundary property record";
          Modelica.Media.Common.GibbsDerivs gl
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Modelica.Media.Common.GibbsDerivs gv
            "Dimensionless Gibbs function and derivatives w.r.t. pi and tau";
          Modelica.Media.Common.HelmholtzDerivs fl
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Modelica.Media.Common.HelmholtzDerivs fv
            "Dimensionless Helmholtz function and derivatives w.r.t. delta and tau";
          Integer error "Error flag for inverse iterations";
        algorithm
          aux.region := if region == 0 then (if phase == 2 then 4 else
            BaseIF97.Regions.region_dT(
              d=rho,
              T=T,
              phase=phase)) else region;
          aux.phase := if aux.region == 4 then 2 else 1;
          aux.R_s := BaseIF97.data.RH2O;
          aux.rho := rho;
          aux.T := T;
          aux.vt := 0.0 "Initialized in case it is not needed";
          aux.vp := 0.0 "Initialized in case it is not needed";
          if (aux.region == 1) then
            (aux.p,error) := BaseIF97.Inverses.pofdt125(
                d=rho,
                T=T,
                reldd=1.0e-8,
                region=1);
            g := BaseIF97.Basic.g1(aux.p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := aux.p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 0.0;
          elseif (aux.region == 2) then
            (aux.p,error) := BaseIF97.Inverses.pofdt125(
                d=rho,
                T=T,
                reldd=1.0e-8,
                region=2);
            g := BaseIF97.Basic.g2(aux.p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := aux.p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
            aux.x := 1.0;
          elseif (aux.region == 3) then
            f := BaseIF97.Basic.f3(rho, T);
            aux.p := aux.R_s*rho*T*f.delta*f.fdelta;
            aux.h := aux.R_s*T*(f.tau*f.ftau + f.delta*f.fdelta);
            aux.s := aux.R_s*(f.tau*f.ftau - f.f);
            aux.pd := aux.R_s*T*f.delta*(2.0*f.fdelta + f.delta*f.fdeltadelta);
            aux.pt := aux.R_s*rho*f.delta*(f.fdelta - f.tau*f.fdeltatau);
            aux.cv := aux.R_s*(-f.tau*f.tau*f.ftautau);
            aux.cp := (aux.rho*aux.rho*aux.pd*aux.cv + aux.T*aux.pt*aux.pt)/(aux.rho*
              aux.rho*aux.pd);
            aux.x := 0.0;
          elseif (aux.region == 4) then
            aux.p := BaseIF97.Basic.psat(T);
            d_liq := rhol_T(T);
            d_vap := rhov_T(T);
            h_liq := hl_p(aux.p);
            h_vap := hv_p(aux.p);
            aux.x := if (d_vap <> d_liq) then (1/rho - 1/d_liq)/(1/d_vap - 1/d_liq)
               else 1.0;
            aux.h := h_liq + aux.x*(h_vap - h_liq);
            if T < BaseIF97.data.TLIMIT1 then
              gl := BaseIF97.Basic.g1(aux.p, T);
              gv := BaseIF97.Basic.g2(aux.p, T);
              liq := Common.gibbsToBoundaryProps(gl);
              vap := Common.gibbsToBoundaryProps(gv);
            else
              fl := BaseIF97.Basic.f3(d_liq, T);
              fv := BaseIF97.Basic.f3(d_vap, T);
              liq := Common.helmholtzToBoundaryProps(fl);
              vap := Common.helmholtzToBoundaryProps(fv);
            end if;
            aux.dpT := if (liq.d <> vap.d) then (vap.s - liq.s)*liq.d*vap.d/(liq.d -
              vap.d) else BaseIF97.Basic.dptofT(aux.T);
            aux.s := liq.s + aux.x*(vap.s - liq.s);
            aux.cv := Common.cv2Phase(
                liq,
                vap,
                aux.x,
                aux.T,
                aux.p);
            aux.cp := liq.cp + aux.x*(vap.cp - liq.cp);
            aux.pt := liq.pt + aux.x*(vap.pt - liq.pt);
            aux.pd := liq.pd + aux.x*(vap.pd - liq.pd);
          elseif (aux.region == 5) then
            (aux.p,error) := BaseIF97.Inverses.pofdt125(
                d=rho,
                T=T,
                reldd=1.0e-8,
                region=5);
            g := BaseIF97.Basic.g2(aux.p, T);
            aux.h := aux.R_s*aux.T*g.tau*g.gtau;
            aux.s := aux.R_s*(g.tau*g.gtau - g.g);
            aux.rho := aux.p/(aux.R_s*T*g.pi*g.gpi);
            aux.vt := aux.R_s/aux.p*(g.pi*g.gpi - g.tau*g.pi*g.gtaupi);
            aux.vp := aux.R_s*T/(aux.p*aux.p)*g.pi*g.pi*g.gpipi;
            aux.pt := -g.p/g.T*(g.gpi - g.tau*g.gtaupi)/(g.gpipi*g.pi);
            aux.pd := -g.R_s*g.T*g.gpi*g.gpi/(g.gpipi);
            aux.cp := -aux.R_s*g.tau*g.tau*g.gtautau;
            aux.cv := aux.R_s*(-g.tau*g.tau*g.gtautau + ((g.gpi - g.tau*g.gtaupi)*(g.gpi
               - g.tau*g.gtaupi)/g.gpipi));
          else
            assert(false, "Error in region computation of IF97 steam tables" +
              "(rho = " + String(rho) + ", T = " + String(T) + ")");
          end if;
        end waterBaseProp_dT;

        function h_props_dT
          "Specific enthalpy as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := aux.h;
          annotation (
            derivative(noDerivative=aux) = h_dT_der,
            Inline=false,
            LateInline=true);
        end h_props_dT;

        function h_dT "Specific enthalpy as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := h_props_dT(
              d,
              T,
              waterBaseProp_dT(
                d,
                T,
                phase,
                region));
          annotation (Inline=true);
        end h_dT;

        function h_dT_der "Derivative function of h_dT"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real d_der "Derivative of density";
          input Real T_der "Derivative of temperature";
          output Real h_der "Derivative of specific enthalpy";
        algorithm
          if (aux.region == 3) then
            h_der := ((-d*aux.pd + T*aux.pt)/(d*d))*d_der + ((aux.cv*d + aux.pt)/d)*
              T_der;
          elseif (aux.region == 4) then
            h_der := T*aux.dpT/(d*d)*d_der + ((aux.cv*d + aux.dpT)/d)*T_der;
          else
            //regions 1,2 or 5
            h_der := (-(-1/d + T*aux.vt)/(d*d*aux.vp))*d_der + ((aux.vp*aux.cp - aux.vt
              /d + T*aux.vt*aux.vt)/aux.vp)*T_der;
          end if;
        end h_dT_der;

        function p_props_dT "Pressure as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Pressure p "Pressure";
        algorithm
          p := aux.p;
          annotation (
            derivative(noDerivative=aux) = p_dT_der,
            Inline=false,
            LateInline=true);
        end p_props_dT;

        function p_dT "Pressure as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.Pressure p "Pressure";
        algorithm
          p := p_props_dT(
              d,
              T,
              waterBaseProp_dT(
                d,
                T,
                phase,
                region));
          annotation (Inline=true);
        end p_dT;

        function p_dT_der "Derivative function of p_dT"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real d_der "Derivative of density";
          input Real T_der "Derivative of temperature";
          output Real p_der "Derivative of pressure";
        algorithm
          if (aux.region == 3) then
            p_der := aux.pd*d_der + aux.pt*T_der;
          elseif (aux.region == 4) then
            p_der := aux.dpT*T_der;
            /*density derivative is 0.0*/
          else
            //regions 1,2 or 5
            p_der := (-1/(d*d*aux.vp))*d_der + (-aux.vt/aux.vp)*T_der;
          end if;
        end p_dT_der;

        function s_props_dT "Specific entropy as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := aux.s;
          annotation (Inline=false, LateInline=true);
        end s_props_dT;

        function s_dT "Temperature as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEntropy s "Specific entropy";
        algorithm
          s := s_props_dT(
              d,
              T,
              waterBaseProp_dT(
                d,
                T,
                phase,
                region));
          annotation (Inline=true);
        end s_dT;

        function cv_props_dT
          "Specific heat capacity at constant volume as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := aux.cv;
          annotation (Inline=false, LateInline=true);
        end cv_props_dT;

        function cv_dT
          "Specific heat capacity at constant volume as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cv "Specific heat capacity";
        algorithm
          cv := cv_props_dT(
              d,
              T,
              waterBaseProp_dT(
                d,
                T,
                phase,
                region));
          annotation (Inline=true);
        end cv_dT;

        function cp_props_dT
          "Specific heat capacity at constant pressure as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := aux.cp;
          annotation (Inline=false, LateInline=true);
        end cp_props_dT;

        function cp_dT
          "Specific heat capacity at constant pressure as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificHeatCapacity cp "Specific heat capacity";
        algorithm
          cp := cp_props_dT(
              d,
              T,
              waterBaseProp_dT(
                d,
                T,
                phase,
                region));
          annotation (Inline=true);
        end cp_dT;

        function beta_props_dT
          "Isobaric expansion coefficient as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := if aux.region == 3 or aux.region == 4 then aux.pt/(aux.rho*aux.pd)
             else aux.vt*aux.rho;
          annotation (Inline=false, LateInline=true);
        end beta_props_dT;

        function beta_dT
          "Isobaric expansion coefficient as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.RelativePressureCoefficient beta "Isobaric expansion coefficient";
        algorithm
          beta := beta_props_dT(
              d,
              T,
              waterBaseProp_dT(
                d,
                T,
                phase,
                region));
          annotation (Inline=true);
        end beta_dT;

        function kappa_props_dT
          "Isothermal compressibility factor as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.IsothermalCompressibility kappa
            "Isothermal compressibility factor";
        algorithm
          kappa := if aux.region == 3 or aux.region == 4 then 1/(aux.rho*aux.pd)
             else -aux.vp*aux.rho;
          annotation (Inline=false, LateInline=true);
        end kappa_props_dT;

        function kappa_dT
          "Isothermal compressibility factor as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.IsothermalCompressibility kappa
            "Isothermal compressibility factor";
        algorithm
          kappa := kappa_props_dT(
              d,
              T,
              waterBaseProp_dT(
                d,
                T,
                phase,
                region));
          annotation (Inline=true);
        end kappa_dT;

        function velocityOfSound_props_dT
          "Speed of sound as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          // dp/drho at constant s
          v_sound := if aux.region == 3 then sqrt(max(0, ((aux.pd*aux.rho*aux.rho*aux.cv
             + aux.pt*aux.pt*aux.T)/(aux.rho*aux.rho*aux.cv)))) else if aux.region
             == 4 then sqrt(max(0, 1/((aux.rho*(aux.rho*aux.cv/aux.dpT + 1.0)/(aux.dpT
            *aux.T)) - 1/aux.rho*aux.rho*aux.rho/(aux.dpT*aux.T)))) else sqrt(max(0,
            -aux.cp/(aux.rho*aux.rho*(aux.vp*aux.cp + aux.vt*aux.vt*aux.T))));
          annotation (Inline=false, LateInline=true);
        end velocityOfSound_props_dT;

        function velocityOfSound_dT
          "Speed of sound as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.Velocity v_sound "Speed of sound";
        algorithm
          v_sound := velocityOfSound_props_dT(
              d,
              T,
              waterBaseProp_dT(
                d,
                T,
                phase,
                region));
          annotation (Inline=true);
        end velocityOfSound_dT;

        function isentropicExponent_props_dT
          "Isentropic exponent as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := if aux.region == 3 then 1/(aux.rho*aux.p)*((aux.pd*aux.cv*aux.rho*
            aux.rho + aux.pt*aux.pt*aux.T)/(aux.cv)) else if aux.region == 4 then 1/(
            aux.rho*aux.p)*aux.dpT*aux.dpT*aux.T/aux.cv else -1/(aux.rho*aux.p)*aux.cp
            /(aux.vp*aux.cp + aux.vt*aux.vt*aux.T);
          annotation (Inline=false, LateInline=true);
        end isentropicExponent_props_dT;

        function isentropicExponent_dT
          "Isentropic exponent as function of density and temperature"
          extends Modelica.Icons.Function;
          input SI.Density d "Density";
          input SI.Temperature T "Temperature";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output Real gamma "Isentropic exponent";
        algorithm
          gamma := isentropicExponent_props_dT(
              d,
              T,
              waterBaseProp_dT(
                d,
                T,
                phase,
                region));
          annotation (Inline=false, LateInline=true);
        end isentropicExponent_dT;

        function hl_p = BaseIF97.Regions.hl_p
          "Compute the saturated liquid specific h(p)";

        function hv_p = BaseIF97.Regions.hv_p
          "Compute the saturated vapour specific h(p)";

        function rhol_T = BaseIF97.Regions.rhol_T "Compute the saturated liquid d(T)";

        function rhov_T = BaseIF97.Regions.rhov_T "Compute the saturated vapour d(T)";

        function dynamicViscosity = BaseIF97.Transport.visc_dTp
          "Compute eta(d,T) in the one-phase region";

        function thermalConductivity = BaseIF97.Transport.cond_dTp
          "Compute lambda(d,T,p) in the one-phase region";

        function surfaceTension = BaseIF97.Transport.surfaceTension
          "Compute sigma(T) at saturation T";

        function isentropicEnthalpy
          "Isentropic specific enthalpy from p,s (preferably use dynamicIsentropicEnthalpy in dynamic simulation!)"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Integer phase=0 "2 for two-phase, 1 for one-phase, 0 if not known";
          input Integer region=0
            "If 0, region is unknown, otherwise known and this input";
          output SI.SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := isentropicEnthalpy_props(
              p,
              s,
              waterBaseProp_ps(
                p,
                s,
                phase,
                region));
          annotation (Inline=true);
        end isentropicEnthalpy;

        function isentropicEnthalpy_props
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          output SI.SpecificEnthalpy h "Isentropic enthalpy";
        algorithm
          h := aux.h;
          annotation (
            derivative(noDerivative=aux) = isentropicEnthalpy_der,
            Inline=false,
            LateInline=true);
        end isentropicEnthalpy_props;

        function isentropicEnthalpy_der
          "Derivative of isentropic specific enthalpy from p,s"
          extends Modelica.Icons.Function;
          input SI.Pressure p "Pressure";
          input SI.SpecificEntropy s "Specific entropy";
          input Common.IF97BaseTwoPhase aux "Auxiliary record";
          input Real p_der "Pressure derivative";
          input Real s_der "Entropy derivative";
          output Real h_der "Specific enthalpy derivative";
        algorithm
          h_der := 1/aux.rho*p_der + aux.T*s_der;
          annotation (Inline=true);
        end isentropicEnthalpy_der;
        annotation (Documentation(info="<html>
      <h4>Package description</h4>
      <p>This package provides high accuracy physical properties for water according
      to the IAPWS/IF97 standard. It has been part of the ThermoFluid Modelica library and been extended,
      reorganized and documented to become part of the Modelica Standard library.</p>
      <p>An important feature that distinguishes this implementation of the IF97 steam property standard
      is that this implementation has been explicitly designed to work well in dynamic simulations. Computational
      performance has been of high importance. This means that there often exist several ways to get the same result
      from different functions if one of the functions is called often but can be optimized for that purpose.
      </p>
      <p>
      The original documentation of the IAPWS/IF97 steam properties can freely be distributed with computer
      implementations, so for curious minds the complete standard documentation is provided with the Modelica
      properties library. The following documents are included
      (in directory Modelica/Resources/Documentation/Media/Water/IF97documentation):
      </p>
      <ul>
      <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a> The standards document for the main part of the IF97.</li>
      <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/Back3.pdf\">Back3.pdf</a> The backwards equations for region 3.</li>
      <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/crits.pdf\">crits.pdf</a> The critical point data.</li>
      <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/meltsub.pdf\">meltsub.pdf</a> The melting- and sublimation line formulation (in IF97_Utilities.BaseIF97.IceBoundaries)</li>
      <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/surf.pdf\">surf.pdf</a> The surface tension standard definition</li>
      <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/thcond.pdf\">thcond.pdf</a> The thermal conductivity standard definition</li>
      <li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/visc.pdf\">visc.pdf</a> The viscosity standard definition</li>
      </ul>
      <h4>Package contents
      </h4>
      <ul>
      <li>Package <strong>BaseIF97</strong> contains the implementation of the IAPWS-IF97 as described in
      <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a>. The explicit backwards equations for region 3 from
      <a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/Back3.pdf\">Back3.pdf</a> are implemented as initial values for an inverse iteration of the exact
      function in IF97 for the input pairs (p,h) and (p,s).
      The low-level functions in BaseIF97 are not needed for standard simulation usage,
      but can be useful for experts and some special purposes.</li>
      <li>Function <strong>water_ph</strong> returns all properties needed for a dynamic control volume model and properties of general
      interest using pressure p and specific entropy enthalpy h as dynamic states in the record ThermoProperties_ph.</li>
      <li>Function <strong>water_ps</strong> returns all properties needed for a dynamic control volume model and properties of general
      interest using pressure p and specific entropy s as dynamic states in the record ThermoProperties_ps.</li>
      <li>Function <strong>water_dT</strong> returns all properties needed for a dynamic control volume model and properties of general
      interest using density d and temperature T as dynamic states in the record ThermoProperties_dT.</li>
      <li>Function <strong>water_pT</strong> returns all properties needed for a dynamic control volume model and properties of general
      interest using pressure p and temperature T as dynamic states in the record ThermoProperties_pT. Due to the coupling of
      pressure and temperature in the two-phase region, this model can obviously
      only be used for one-phase models or models treating both phases independently.</li>
      <li>Function <strong>hl_p</strong> computes the liquid specific enthalpy as a function of pressure. For overcritical pressures,
      the critical specific enthalpy is returned</li>
      <li>Function <strong>hv_p</strong> computes the vapour specific enthalpy as a function of pressure. For overcritical pressures,
      the critical specific enthalpy is returned</li>
      <li>Function <strong>sl_p</strong> computes the liquid specific entropy as a function of pressure. For overcritical pressures,
      the critical  specific entropy is returned</li>
      <li>Function <strong>sv_p</strong> computes the vapour  specific entropy as a function of pressure. For overcritical pressures,
      the critical  specific entropy is returned</li>
      <li>Function <strong>rhol_T</strong> computes the liquid density as a function of temperature. For overcritical temperatures,
      the critical density is returned</li>
      <li>Function <strong>rhol_T</strong> computes the vapour density as a function of temperature. For overcritical temperatures,
      the critical density is returned</li>
      <li>Function <strong>dynamicViscosity</strong> computes the dynamic viscosity as a function of density and temperature.</li>
      <li>Function <strong>thermalConductivity</strong> computes the thermal conductivity as a function of density, temperature and pressure.
      <strong>Important note</strong>: Obviously only two of the three
      inputs are really needed, but using three inputs speeds up the computation and the three variables
      are known in most models anyways. The inputs d,T and p have to be consistent.</li>
      <li>Function <strong>surfaceTension</strong> computes the surface tension between vapour
          and liquid water as a function of temperature.</li>
      <li>Function <strong>isentropicEnthalpy</strong> computes the specific enthalpy h(p,s,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary.</li>
      <li>Function <strong>dynamicIsentropicEnthalpy</strong> computes the specific enthalpy h(p,s,,dguess,Tguess,phase) in all regions.
          The phase input is needed due to discontinuous derivatives at the phase boundary. Tguess and dguess are initial guess
          values for the density and temperature consistent with p and s. This function should be preferred in
          dynamic simulations where good guesses are often available.</li>
      </ul>
      <h4>Version Info and Revision history
      </h4>
      <ul>
      <li>First implemented: <em>July, 2000</em>
      by Hubertus Tummescheit for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
      </li>
      <li>Code reorganization, enhanced documentation, additional functions:   <em>December, 2002</em>
      by <a href=\"mailto:Hubertus.Tummescheit@modelon.se\">Hubertus Tummescheit</a> and moved to Modelica
      properties library.</li>
      </ul>
      <address>Author: Hubertus Tummescheit,<br>
      Modelon AB<br>
      Ideon Science Park<br>
      SE-22370 Lund, Sweden<br>
      email: hubertus@modelon.se
      </address>
      </html>",       revisions="<html><h4>Intermediate release notes during development</h4>
<p>Currently the Events/noEvents switch is only implemented for p-h states. Only after testing that implementation, it will be extended to dT.</p></html>"));
      end IF97_Utilities;
    annotation (Documentation(info="<html>
<p>This package contains different medium models for water:</p>
<ul>
<li><strong>ConstantPropertyLiquidWater</strong><br>
    Simple liquid water medium (incompressible, constant data).</li>
<li><strong>IdealSteam</strong><br>
    Steam water medium as ideal gas from Media.IdealGases.SingleGases.H2O</li>
<li><strong>WaterIF97 derived models</strong><br>
    High precision water model according to the IAPWS/IF97 standard
    (liquid, steam, two phase region). Models with different independent
    variables are provided as well as models valid only
    for particular regions. The <strong>WaterIF97_ph</strong> model is valid
    in all regions and is the recommended one to use.</li>
</ul>
<h4>Overview of WaterIF97 derived water models</h4>
<p>
The WaterIF97 models calculate medium properties
for water in the <strong>liquid</strong>, <strong>gas</strong> and <strong>two phase</strong> regions
according to the IAPWS/IF97 standard, i.e., the accepted industrial standard
and best compromise between accuracy and computation time.
It has been part of the ThermoFluid Modelica library and been extended,
reorganized and documented to become part of the Modelica Standard library.</p>
<p>An important feature that distinguishes this implementation of the IF97 steam property standard
is that this implementation has been explicitly designed to work well in dynamic simulations. Computational
performance has been of high importance. This means that there often exist several ways to get the same result
from different functions if one of the functions is called often but can be optimized for that purpose.
</p>
<p>Three variable pairs can be the independent variables of the model:
</p>
<ol>
<li>Pressure <strong>p</strong> and specific enthalpy <strong>h</strong> are
    the most natural choice for general applications.
    This is the recommended choice for most general purpose
    applications, in particular for power plants.</li>
<li>Pressure <strong>p</strong> and temperature <strong>T</strong> are the most natural
    choice for applications where water is always in the same phase,
    both for liquid water and steam.</li>
<li>Density <strong>d</strong> and temperature <strong>T</strong> are explicit
    variables of the Helmholtz function in the near-critical
    region and can be the best choice for applications with
    super-critical or near-critical states.</li>
</ol>
<p>
The following quantities are always computed in Medium.BaseProperties:
</p>
<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
  <tr><td><strong>Variable</strong></td>
      <td><strong>Unit</strong></td>
      <td><strong>Description</strong></td></tr>
  <tr><td>T</td>
      <td>K</td>
      <td>temperature</td></tr>
  <tr><td>u</td>
      <td>J/kg</td>
      <td>specific internal energy</td></tr>
  <tr><td>d</td>
      <td>kg/m^3</td>
      <td>density</td></tr>
  <tr><td>p</td>
      <td>Pa</td>
      <td>pressure</td></tr>
  <tr><td>h</td>
      <td>J/kg</td>
      <td>specific enthalpy</td></tr>
</table>
<p>
In some cases additional medium properties are needed.
A component that needs these optional properties has to call
one of the following functions:
</p>
<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
  <tr><td><strong>Function call</strong></td>
      <td><strong>Unit</strong></td>
      <td><strong>Description</strong></td></tr>
  <tr><td>Medium.dynamicViscosity(medium.state)</td>
      <td>Pa.s</td>
      <td>dynamic viscosity</td></tr>
  <tr><td>Medium.thermalConductivity(medium.state)</td>
      <td>W/(m.K)</td>
      <td>thermal conductivity</td></tr>
  <tr><td>Medium.prandtlNumber(medium.state)</td>
      <td>1</td>
      <td>Prandtl number</td></tr>
  <tr><td>Medium.specificEntropy(medium.state)</td>
      <td>J/(kg.K)</td>
      <td>specific entropy</td></tr>
  <tr><td>Medium.heatCapacity_cp(medium.state)</td>
      <td>J/(kg.K)</td>
      <td>specific heat capacity at constant pressure</td></tr>
  <tr><td>Medium.heatCapacity_cv(medium.state)</td>
      <td>J/(kg.K)</td>
      <td>specific heat capacity at constant density</td></tr>
  <tr><td>Medium.isentropicExponent(medium.state)</td>
      <td>1</td>
      <td>isentropic exponent</td></tr>
  <tr><td>Medium.isentropicEnthalpy(pressure, medium.state)</td>
      <td>J/kg</td>
      <td>isentropic enthalpy</td></tr>
  <tr><td>Medium.velocityOfSound(medium.state)</td>
      <td>m/s</td>
      <td>velocity of sound</td></tr>
  <tr><td>Medium.isobaricExpansionCoefficient(medium.state)</td>
      <td>1/K</td>
      <td>isobaric expansion coefficient</td></tr>
  <tr><td>Medium.isothermalCompressibility(medium.state)</td>
      <td>1/Pa</td>
      <td>isothermal compressibility</td></tr>
  <tr><td>Medium.density_derp_h(medium.state)</td>
      <td>kg/(m3.Pa)</td>
      <td>derivative of density by pressure at constant enthalpy</td></tr>
  <tr><td>Medium.density_derh_p(medium.state)</td>
      <td>kg2/(m3.J)</td>
      <td>derivative of density by enthalpy at constant pressure</td></tr>
  <tr><td>Medium.density_derp_T(medium.state)</td>
      <td>kg/(m3.Pa)</td>
      <td>derivative of density by pressure at constant temperature</td></tr>
  <tr><td>Medium.density_derT_p(medium.state)</td>
      <td>kg/(m3.K)</td>
      <td>derivative of density by temperature at constant pressure</td></tr>
  <tr><td>Medium.density_derX(medium.state)</td>
      <td>kg/m3</td>
      <td>derivative of density by mass fraction</td></tr>
  <tr><td>Medium.molarMass(medium.state)</td>
      <td>kg/mol</td>
      <td>molar mass</td></tr>
</table>
<p>More details are given in
<a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.OptionalProperties\">
Modelica.Media.UsersGuide.MediumUsage.OptionalProperties</a>.

Many additional optional functions are defined to compute properties of
saturated media, either liquid (bubble point) or vapour (dew point).
The argument to such functions is a SaturationProperties record, which can be
set starting from either the saturation pressure or the saturation temperature.
With reference to a model defining a pressure p, a temperature T, and a
SaturationProperties record sat, the following functions are provided:
</p>
<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
  <tr><td><strong>Function call</strong></td>
      <td><strong>Unit</strong></td>
      <td><strong>Description</strong></td></tr>
  <tr><td>Medium.saturationPressure(T)</td>
      <td>Pa</td>
      <td>Saturation pressure at temperature T</td></tr>
  <tr><td>Medium.saturationTemperature(p)</td>
      <td>K</td>
      <td>Saturation temperature at pressure p</td></tr>
  <tr><td>Medium.saturationTemperature_derp(p)</td>
      <td>K/Pa</td>
      <td>Derivative of saturation temperature with respect to pressure</td></tr>
  <tr><td>Medium.bubbleEnthalpy(sat)</td>
      <td>J/kg</td>
      <td>Specific enthalpy at bubble point</td></tr>
  <tr><td>Medium.dewEnthalpy(sat)</td>
      <td>J/kg</td>
      <td>Specific enthalpy at dew point</td></tr>
  <tr><td>Medium.bubbleEntropy(sat)</td>
      <td>J/(kg.K)</td>
      <td>Specific entropy at bubble point</td></tr>
  <tr><td>Medium.dewEntropy(sat)</td>
      <td>J/(kg.K)</td>
      <td>Specific entropy at dew point</td></tr>
  <tr><td>Medium.bubbleDensity(sat)</td>
      <td>kg/m3</td>
      <td>Density at bubble point</td></tr>
  <tr><td>Medium.dewDensity(sat)</td>
      <td>kg/m3</td>
      <td>Density at dew point</td></tr>
  <tr><td>Medium.dBubbleDensity_dPressure(sat)</td>
      <td>kg/(m3.Pa)</td>
      <td>Derivative of density at bubble point with respect to pressure</td></tr>
  <tr><td>Medium.dDewDensity_dPressure(sat)</td>
      <td>kg/(m3.Pa)</td>
      <td>Derivative of density at dew point with respect to pressure</td></tr>
  <tr><td>Medium.dBubbleEnthalpy_dPressure(sat)</td>
      <td>J/(kg.Pa)</td>
      <td>Derivative of specific enthalpy at bubble point with respect to pressure</td></tr>
  <tr><td>Medium.dDewEnthalpy_dPressure(sat)</td>
      <td>J/(kg.Pa)</td>
      <td>Derivative of specific enthalpy at dew point with respect to pressure</td></tr>
  <tr><td>Medium.surfaceTension(sat)</td>
      <td>N/m</td>
      <td>Surface tension between liquid and vapour phase</td></tr>
</table>
<p>Details on usage and some examples are given in:
<a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage.TwoPhase\">
Modelica.Media.UsersGuide.MediumUsage.TwoPhase</a>.
</p>
<p>Many further properties can be computed. Using the well-known Bridgman's Tables,
all first partial derivatives of the standard thermodynamic variables can be computed easily.
</p>
<p>
The documentation of the IAPWS/IF97 steam properties can be freely
distributed with computer implementations and are included here
(in directory Modelica/Resources/Documentation/Media/Water/IF97documentation):
</p>
<ul>
<li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/IF97.pdf\">IF97.pdf</a> The standards document for the main part of the IF97.</li>
<li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/Back3.pdf\">Back3.pdf</a> The backwards equations for region 3.</li>
<li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/crits.pdf\">crits.pdf</a> The critical point data.</li>
<li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/meltsub.pdf\">meltsub.pdf</a> The melting- and sublimation line formulation (not implemented)</li>
<li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/surf.pdf\">surf.pdf</a> The surface tension standard definition</li>
<li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/thcond.pdf\">thcond.pdf</a> The thermal conductivity standard definition</li>
<li><a href=\"modelica://Modelica/Resources/Documentation/Media/Water/IF97documentation/visc.pdf\">visc.pdf</a> The viscosity standard definition</li>
</ul>
</html>"));
    end Water;
  annotation (preferredView="info",Documentation(info="<html>
<p>
This library contains <a href=\"modelica://Modelica.Media.Interfaces\">interface</a>
definitions for media and the following <strong>property</strong> models for
single and multiple substance fluids with one and multiple phases:
</p>
<ul>
<li> <a href=\"modelica://Modelica.Media.IdealGases\">Ideal gases:</a><br>
     1241 high precision gas models based on the
     NASA Glenn coefficients, plus ideal gas mixture models based
     on the same data.</li>
<li> <a href=\"modelica://Modelica.Media.Water\">Water models:</a><br>
     ConstantPropertyLiquidWater, WaterIF97 (high precision
     water model according to the IAPWS/IF97 standard)</li>
<li> <a href=\"modelica://Modelica.Media.Air\">Air models:</a><br>
     SimpleAir, DryAirNasa, ReferenceAir, MoistAir, ReferenceMoistAir.</li>
<li> <a href=\"modelica://Modelica.Media.Incompressible\">
     Incompressible media:</a><br>
     TableBased incompressible fluid models (properties are defined by tables rho(T),
     HeatCapacity_cp(T), etc.)</li>
<li> <a href=\"modelica://Modelica.Media.CompressibleLiquids\">
     Compressible liquids:</a><br>
     Simple liquid models with linear compressibility</li>
<li> <a href=\"modelica://Modelica.Media.R134a\">Refrigerant Tetrafluoroethane (R134a)</a>.</li>
</ul>
<p>
The following parts are useful, when newly starting with this library:</p>
<ul>
<li> <a href=\"modelica://Modelica.Media.UsersGuide\">Modelica.Media.UsersGuide</a>.</li>
<li> <a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage\">Modelica.Media.UsersGuide.MediumUsage</a>
     describes how to use a medium model in a component model.</li>
<li> <a href=\"modelica://Modelica.Media.UsersGuide.MediumDefinition\">
     Modelica.Media.UsersGuide.MediumDefinition</a>
     describes how a new fluid medium model has to be implemented.</li>
<li> <a href=\"modelica://Modelica.Media.UsersGuide.ReleaseNotes\">Modelica.Media.UsersGuide.ReleaseNotes</a>
     summarizes the changes of the library releases.</li>
<li> <a href=\"modelica://Modelica.Media.Examples\">Modelica.Media.Examples</a>
     contains examples that demonstrate the usage of this library.</li>
</ul>
<p>
Copyright &copy; 1998-2020, Modelica Association and contributors
</p>
</html>",   revisions="<html>
<ul>
<li><em>February 01, 2017</em> by Thomas Beutlich:<br>
    Fixed data errors of the NASA Glenn coefficients in some ideal gases (CH2, CH3, CH3OOH, C2CL2, C2CL4, C2CL6, C2HCL, C2HCL3, CH2CO_ketene, O_CH_2O, HO_CO_2OH, CH2BrminusCOOH, C2H3CL, CH2CLminusCOOH, HO2, HO2minus, OD, ODminus), see <a href=\"https://github.com/modelica/ModelicaStandardLibrary/issues/1922\">#1922</a></li>
<li><em>May 16, 2013</em> by Stefan Wischhusen (XRG Simulation):<br>
    Added new media models Air.ReferenceMoistAir, Air.ReferenceAir, R134a.</li>
<li><em>May 25, 2011</em> by Francesco Casella:<br>Added min/max attributes to Water, TableBased, MixtureGasNasa, SimpleAir and MoistAir local types.</li>
<li><em>May 25, 2011</em> by Stefan Wischhusen:<br>Added individual settings for polynomial fittings of properties.</li>
</ul>
</html>"),
      Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}),
          graphics={
          Line(
            points = {{-76,-80},{-62,-30},{-32,40},{4,66},{48,66},{73,45},{62,-8},{48,-50},{38,-80}},
            color={64,64,64},
            smooth=Smooth.Bezier),
          Line(
            points={{-40,20},{68,20}},
            color={175,175,175}),
          Line(
            points={{-40,20},{-44,88},{-44,88}},
            color={175,175,175}),
          Line(
            points={{68,20},{86,-58}},
            color={175,175,175}),
          Line(
            points={{-60,-28},{56,-28}},
            color={175,175,175}),
          Line(
            points={{-60,-28},{-74,84},{-74,84}},
            color={175,175,175}),
          Line(
            points={{56,-28},{70,-80}},
            color={175,175,175}),
          Line(
            points={{-76,-80},{38,-80}},
            color={175,175,175}),
          Line(
            points={{-76,-80},{-94,-16},{-94,-16}},
            color={175,175,175})}));
  end Media;

  package Thermal
  "Library of thermal system components to model heat transfer and simple thermo-fluid pipe flow"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;

    package HeatTransfer
    "Library of 1-dimensional heat transfer with lumped elements"
      extends Modelica.Icons.Package;

      package Interfaces "Connectors and partial models"
        extends Modelica.Icons.InterfacesPackage;

        partial connector HeatPort "Thermal port for 1-dim. heat transfer"
          SI.Temperature T "Port temperature";
          flow SI.HeatFlowRate Q_flow
            "Heat flow rate (positive if flowing from outside into the component)";
          annotation (Documentation(info="<html>

</html>"));
        end HeatPort;

        connector HeatPort_a
          "Thermal port for 1-dim. heat transfer (filled rectangular icon)"

          extends HeatPort;

          annotation(defaultComponentName = "port_a",
            Documentation(info="<html>
<p>This connector is used for 1-dimensional heat flow between components.
The variables in the connector are:</p>
<blockquote><pre>
T       Temperature in [Kelvin].
Q_flow  Heat flow rate in [Watt].
</pre></blockquote>
<p>According to the Modelica sign convention, a <strong>positive</strong> heat flow
rate <strong>Q_flow</strong> is considered to flow <strong>into</strong> a component. This
convention has to be used whenever this connector is used in a model
class.</p>
<p>Note, that the two connector classes <strong>HeatPort_a</strong> and
<strong>HeatPort_b</strong> are identical with the only exception of the different
<strong>icon layout</strong>.</p></html>"),     Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{
                    100,100}}), graphics={Rectangle(
                  extent={{-100,100},{100,-100}},
                  lineColor={191,0,0},
                  fillColor={191,0,0},
                  fillPattern=FillPattern.Solid)}),
            Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},
                    {100,100}}), graphics={Rectangle(
                  extent={{-50,50},{50,-50}},
                  lineColor={191,0,0},
                  fillColor={191,0,0},
                  fillPattern=FillPattern.Solid), Text(
                  extent={{-120,120},{100,60}},
                  textColor={191,0,0},
                  textString="%name")}));
        end HeatPort_a;
        annotation (Documentation(info="<html>

</html>"));
      end Interfaces;
      annotation (
         Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100,-100},{100,100}}), graphics={
          Polygon(
            origin = {13.758,27.517},
            lineColor = {128,128,128},
            fillColor = {192,192,192},
            fillPattern = FillPattern.Solid,
            points = {{-54,-6},{-61,-7},{-75,-15},{-79,-24},{-80,-34},{-78,-42},{-73,-49},{-64,-51},{-57,-51},{-47,-50},{-41,-43},{-38,-35},{-40,-27},{-40,-20},{-42,-13},{-47,-7},{-54,-5},{-54,-6}}),
        Polygon(
            origin = {13.758,27.517},
            fillColor = {160,160,164},
            fillPattern = FillPattern.Solid,
            points = {{-75,-15},{-79,-25},{-80,-34},{-78,-42},{-72,-49},{-64,-51},{-57,-51},{-47,-50},{-57,-47},{-65,-45},{-71,-40},{-74,-33},{-76,-23},{-75,-15},{-75,-15}}),
          Polygon(
            origin = {13.758,27.517},
            lineColor = {160,160,164},
            fillColor = {192,192,192},
            fillPattern = FillPattern.Solid,
            points = {{39,-6},{32,-7},{18,-15},{14,-24},{13,-34},{15,-42},{20,-49},{29,-51},{36,-51},{46,-50},{52,-43},{55,-35},{53,-27},{53,-20},{51,-13},{46,-7},{39,-5},{39,-6}}),
          Polygon(
            origin = {13.758,27.517},
            fillColor = {160,160,164},
            fillPattern = FillPattern.Solid,
            points = {{18,-15},{14,-25},{13,-34},{15,-42},{21,-49},{29,-51},{36,-51},{46,-50},{36,-47},{28,-45},{22,-40},{19,-33},{17,-23},{18,-15},{18,-15}}),
          Polygon(
            origin = {13.758,27.517},
            lineColor = {191,0,0},
            fillColor = {191,0,0},
            fillPattern = FillPattern.Solid,
            points = {{-9,-23},{-9,-10},{18,-17},{-9,-23}}),
          Line(
            origin = {13.758,27.517},
            points = {{-41,-17},{-9,-17}},
            color = {191,0,0},
            thickness = 0.5),
          Line(
            origin = {13.758,27.517},
            points = {{-17,-40},{15,-40}},
            color = {191,0,0},
            thickness = 0.5),
          Polygon(
            origin = {13.758,27.517},
            lineColor = {191,0,0},
            fillColor = {191,0,0},
            fillPattern = FillPattern.Solid,
            points = {{-17,-46},{-17,-34},{-40,-40},{-17,-46}})}),
                                Documentation(info="<html>
<p>
This package contains components to model <strong>1-dimensional heat transfer</strong>
with lumped elements.</p>
</html>",     revisions="<html>
<ul>
<li><em>July 15, 2002</em>
       by Michael Tiller, <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and Nikolaus Sch&uuml;rmann:<br>
       Implemented.
</li>
<li><em>June 13, 2005</em>
       by <a href=\"https://www.haumer.at/\">Anton Haumer</a><br>
       Refined placing of connectors (cosmetic).<br>
       Refined all Examples; removed Examples.FrequencyInverter, introducing Examples.Motor<br>
       Introduced temperature dependent correction (1 + alpha*(T - T_ref)) in Fixed/PrescribedHeatFlow<br>
</li>
  <li> v1.1.1 2007/11/13 Anton Haumer<br>
       components moved to sub-packages</li>
  <li> v1.2.0 2009/08/26 Anton Haumer<br>
       added component ThermalCollector</li>

</ul>
</html>"));
    end HeatTransfer;
    annotation (
     Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}), graphics={
      Line(
      origin={-47.5,11.6667},
      points={{-2.5,-91.6667},{17.5,-71.6667},{-22.5,-51.6667},{17.5,-31.6667},{-22.5,-11.667},{17.5,8.3333},{-2.5,28.3333},{-2.5,48.3333}},
        smooth=Smooth.Bezier),
      Polygon(
      origin={-50.0,68.333},
      pattern=LinePattern.None,
      fillPattern=FillPattern.Solid,
        points={{0.0,21.667},{-10.0,-8.333},{10.0,-8.333}}),
      Line(
      origin={2.5,11.6667},
      points={{-2.5,-91.6667},{17.5,-71.6667},{-22.5,-51.6667},{17.5,-31.6667},{-22.5,-11.667},{17.5,8.3333},{-2.5,28.3333},{-2.5,48.3333}},
        smooth=Smooth.Bezier),
      Polygon(
      origin={0.0,68.333},
      pattern=LinePattern.None,
      fillPattern=FillPattern.Solid,
        points={{0.0,21.667},{-10.0,-8.333},{10.0,-8.333}}),
      Line(
      origin={52.5,11.6667},
      points={{-2.5,-91.6667},{17.5,-71.6667},{-22.5,-51.6667},{17.5,-31.6667},{-22.5,-11.667},{17.5,8.3333},{-2.5,28.3333},{-2.5,48.3333}},
        smooth=Smooth.Bezier),
      Polygon(
      origin={50.0,68.333},
      pattern=LinePattern.None,
      fillPattern=FillPattern.Solid,
        points={{0.0,21.667},{-10.0,-8.333},{10.0,-8.333}})}),
      Documentation(info="<html>
<p>
This package contains libraries to model heat transfer
and fluid heat flow.
</p>
</html>"));
  end Thermal;

  package Math
  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Nonlinear "Library of functions operating on nonlinear equations"
      extends Modelica.Icons.Package;

      package Interfaces "Interfaces for functions"
        extends Modelica.Icons.InterfacesPackage;

      encapsulated partial function partialScalarFunction
          "Interface for a function with one input and one output Real signal"
        import Modelica;
        extends Modelica.Icons.Function;
        input Real u "Independent variable";
        output Real y "Dependent variable y=f(u)";
          annotation (Documentation(info="<html>
<p>
This partial function defines the interface of a function with
one input and one output Real signal. The scalar functions
of <a href=\"modelica://Modelica.Math.Nonlinear\">Modelica.Math.Nonlinear</a>
are derived from this base type by inheritance.
This allows to use these functions directly as function arguments
to a function, see, .e.g.,
<a href=\"modelica://Modelica.Math.Nonlinear.Examples\">Math.Nonlinear.Examples</a>.
</p>

</html>"));
      end partialScalarFunction;
        annotation (Documentation(info="<html>
<p>
Interface definitions of functions. The main purpose is to use functions
derived from these interface definitions as function arguments
to a function, see, .e.g.,
<a href=\"modelica://Modelica.Math.Nonlinear.Examples\">Math.Nonlinear.Examples</a>.
</p>
</html>"));
      end Interfaces;

      function solveOneNonlinearEquation
        "Solve f(u) = 0 in a very reliable and efficient way (f(u_min) and f(u_max) must have different signs)"
        extends Modelica.Icons.Function;
        import Modelica.Utilities.Streams.error;

        input Modelica.Math.Nonlinear.Interfaces.partialScalarFunction f
          "Function y = f(u); u is computed so that y=0";
        input Real u_min "Lower bound of search interval";
        input Real u_max "Upper bound of search interval";
        input Real tolerance=100*Modelica.Constants.eps
          "Relative tolerance of solution u";
        output Real u "Value of independent variable u so that f(u) = 0";

    protected
        constant Real eps=Modelica.Constants.eps "Machine epsilon";
        Real a=u_min "Current best minimum interval value";
        Real b=u_max "Current best maximum interval value";
        Real c "Intermediate point a <= c <= b";
        Real d;
        Real e "b - a";
        Real m;
        Real s;
        Real p;
        Real q;
        Real r;
        Real tol;
        Real fa "= f(a)";
        Real fb "= f(b)";
        Real fc;
        Boolean found=false;
      algorithm
        // Check that f(u_min) and f(u_max) have different sign
        fa := f(u_min);
        fb := f(u_max);
        fc := fb;
        if fa > 0.0 and fb > 0.0 or fa < 0.0 and fb < 0.0 then
          error(
            "The arguments u_min and u_max provided in the function call\n"+
            "    solveOneNonlinearEquation(f,u_min,u_max)\n" +
            "do not bracket the root of the single non-linear equation 0=f(u):\n" +
            "  u_min  = " + String(u_min) + "\n" + "  u_max  = " + String(u_max)
             + "\n" + "  fa = f(u_min) = " + String(fa) + "\n" +
            "  fb = f(u_max) = " + String(fb) + "\n" +
            "fa and fb must have opposite sign which is not the case");
        end if;

        // Initialize variables
        c := a;
        fc := fa;
        e := b - a;
        d := e;

        // Search loop
        while not found loop
          if abs(fc) < abs(fb) then
            a := b;
            b := c;
            c := a;
            fa := fb;
            fb := fc;
            fc := fa;
          end if;

          tol := 2*eps*abs(b) + tolerance;
          m := (c - b)/2;

          if abs(m) <= tol or fb == 0.0 then
            // root found (interval is small enough)
            found := true;
            u := b;
          else
            // Determine if a bisection is needed
            if abs(e) < tol or abs(fa) <= abs(fb) then
              e := m;
              d := e;
            else
              s := fb/fa;
              if a == c then
                // linear interpolation
                p := 2*m*s;
                q := 1 - s;
              else
                // inverse quadratic interpolation
                q := fa/fc;
                r := fb/fc;
                p := s*(2*m*q*(q - r) - (b - a)*(r - 1));
                q := (q - 1)*(r - 1)*(s - 1);
              end if;

              if p > 0 then
                q := -q;
              else
                p := -p;
              end if;

              s := e;
              e := d;
              if 2*p < 3*m*q - abs(tol*q) and p < abs(0.5*s*q) then
                // interpolation successful
                d := p/q;
              else
                // use bi-section
                e := m;
                d := e;
              end if;
            end if;

            // Best guess value is defined as "a"
            a := b;
            fa := fb;
            b := b + (if abs(d) > tol then d else if m > 0 then tol else -tol);
            fb := f(b);

            if fb > 0 and fc > 0 or fb < 0 and fc < 0 then
              // initialize variables
              c := a;
              fc := fa;
              e := b - a;
              d := e;
            end if;
          end if;
        end while;

        annotation (Documentation(info="<html>
<h4>Syntax</h4>
<blockquote><pre>
<strong>solveOneNonlinearEquation</strong>(function f(), u_min, u_max);
<strong>solveOneNonlinearEquation</strong>(function f(), u_min, u_max, tolerance=100*Modelica.Constants.eps);
</pre></blockquote>

<h4>Description</h4>

<p>
This function determines the solution of <strong>one non-linear algebraic equation</strong> \"y=f(u)\"
in <strong>one unknown</strong> \"u\" in a reliable way. It is one of the best numerical
algorithms for this purpose. As input, the nonlinear function f(u)
has to be given, as well as an interval u_min, u_max that
contains the solution, i.e., \"f(u_min)\" and \"f(u_max)\" must
have a different sign. The function computes a smaller interval
in which a sign change is present using the relative tolerance
\"tolerance\" that can be given as 4th input argument.
</p>

<p>
The interval reduction is performed using
inverse quadratic interpolation (interpolating with a quadratic polynomial
through the last 3 points and computing the zero). If this fails,
bisection is used, which always reduces the interval by a factor of 2.
The inverse quadratic interpolation method has superlinear convergence.
This is roughly the same convergence rate as a globally convergent Newton
method, but without the need to compute derivatives of the non-linear
function. The solver function is a direct mapping of the Algol 60 procedure
\"zero\" to Modelica, from:
</p>

<blockquote>
<dl>
<dt> Brent R.P.:</dt>
<dd> <strong>Algorithms for Minimization without derivatives</strong>.
     Prentice Hall, 1973, pp. 58-59.<br>
     Download: <a href=\"https://maths-people.anu.edu.au/~brent/pd/rpb011i.pdf\">https://maths-people.anu.edu.au/~brent/pd/rpb011i.pdf</a><br>
     Errata and new print: <a href=\"https://maths-people.anu.edu.au/~brent/pub/pub011.html\">https://maths-people.anu.edu.au/~brent/pub/pub011.html</a>
</dd>
</dl>
</blockquote>

<h4>Example</h4>

<p>
See the examples in <a href=\"modelica://Modelica.Math.Nonlinear.Examples\">Modelica.Math.Nonlinear.Examples</a>.
</p>
</html>"));
      end solveOneNonlinearEquation;
      annotation (Documentation(info="<html>
<p>
This package contains functions to perform tasks such as numerically integrating
a function, or solving a nonlinear algebraic equation system.
The common feature of the functions in this package is
that the nonlinear characteristics are passed as user definable
functions.
</p>

<p>
For details about how to define and to use functions as input arguments
to functions, see
<a href=\"modelica://ModelicaReference.Classes.'function'\">ModelicaReference.Classes.'function'</a>
or <a href=\"https://specification.modelica.org/v3.4/Ch12.html#functional-input-arguments-to-functions\">Section 12.4.2
(Functional Input Arguments to Functions) of the Modelica 3.4 specification</a>.
</p>

</html>",     revisions="<html>
<ul>
<li><em>July 2010 </em> by Martin Otter (DLR-RM):<br>
    Included in MSL 3.2, adapted, and documentation improved</li>

<li><em>March 2010 </em> by Andreas Pfeiffer (DLR-RM):<br>
    Adapted the quadrature function from Gerhard Schillhuber and
    the solution of one non-linear equation in one unknown from
    Modelica.Media.Common.OneNonLinearEquation so that
    function objects are used.</li>

<li><em>June 2002 </em> by Gerhard Schillhuber (master thesis at DLR-RM):<br>
       Adaptive quadrature to compute the curve length of a Spline.</li>
</ul>
</html>"),     Icon(graphics={Polygon(points={{-44,-52},{-44,-26},{-17.1,
                  44.4},{-11.4,52.6},{-5.8,57.1},{-0.2,57.8},{5.4,54.6},{11.1,47.7},
                  {16.7,37.4},{23.1,22.1},{31.17,-0.8},{48,-52},{-44,-52}},
              lineColor={135,135,135},
              fillColor={215,215,215},
              fillPattern=FillPattern.Solid)}));
    end Nonlinear;

        package Polynomials
    "Library of functions operating on polynomials (including polynomial fitting)"
          extends Modelica.Icons.FunctionsPackage;

          function evaluate "Evaluate polynomial at a given abscissa value"
            extends Modelica.Icons.Function;
            input Real p[:]
              "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real u "Abscissa value";
            output Real y "Value of polynomial at u";
          algorithm
            y := p[1];
            for j in 2:size(p, 1) loop
              y := p[j] + u*y;
            end for;
            annotation(derivative(zeroDerivative=p)=evaluate_der);
          end evaluate;

          function evaluateWithRange
            "Evaluate polynomial at a given abscissa value with linear extrapolation outside of the defined range"
            extends Modelica.Icons.Function;
            input Real p[:]
              "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real uMin "Polynomial valid in the range uMin .. uMax";
            input Real uMax "Polynomial valid in the range uMin .. uMax";
            input Real u "Abscissa value";
            output Real y
              "Value of polynomial at u. Outside of uMin,uMax, linear extrapolation is used";
          algorithm
            if u < uMin then
              y := evaluate(p, uMin) - evaluate_der(
                      p,
                      uMin,
                      uMin - u);
            elseif u > uMax then
              y := evaluate(p, uMax) + evaluate_der(
                      p,
                      uMax,
                      u - uMax);
            else
              y := evaluate(p, u);
            end if;
            annotation (derivative(
                zeroDerivative=p,
                zeroDerivative=uMin,
                zeroDerivative=uMax) = evaluateWithRange_der);
          end evaluateWithRange;

          function evaluate_der
            "Evaluate derivative of polynomial at a given abscissa value"
            extends Modelica.Icons.Function;
            input Real p[:]
              "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real u "Abscissa value";
            input Real du "Delta of abscissa value";
            output Real dy "Value of derivative of polynomial at u";
        protected
            Integer n=size(p, 1);
          algorithm
            dy := p[1]*(n - 1);
            for j in 2:size(p, 1)-1 loop
              dy := p[j]*(n - j) + u*dy;
            end for;
            dy := dy*du;
          end evaluate_der;

          function evaluateWithRange_der
            "Evaluate derivative of polynomial at a given abscissa value with extrapolation outside of the defined range"
            extends Modelica.Icons.Function;
            input Real p[:]
              "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real uMin "Polynomial valid in the range uMin .. uMax";
            input Real uMax "Polynomial valid in the range uMin .. uMax";
            input Real u "Abscissa value";
            input Real du "Delta of abscissa value";
            output Real dy "Value of derivative of polynomial at u";
          algorithm
            if u < uMin then
              dy := evaluate_der(
                      p,
                      uMin,
                      du);
            elseif u > uMax then
              dy := evaluate_der(
                      p,
                      uMax,
                      du);
            else
              dy := evaluate_der(
                      p,
                      u,
                      du);
            end if;
          end evaluateWithRange_der;
          annotation (Documentation(info="<html>
<p>
This package contains functions to operate on polynomials,
in particular to determine the derivative and the integral
of a polynomial and to use a polynomial to fit a given set
of data points.
</p>

<p>
Copyright &copy; 2004-2020, Modelica Association and contributors
</p>
</html>",         revisions="<html>
<ul>
<li><em>Oct. 22, 2004</em> by Martin Otter (DLR):<br>
       Renamed functions to not have abbreviations.<br>
       Based fitting on LAPACK<br>
       New function to return the polynomial of an indefinite integral</li>
<li><em>Sept. 3, 2004</em> by Jonas Eborn (Scynamics):<br>
       polyderval, polyintval added</li>
<li><em>March 1, 2004</em> by Martin Otter (DLR):<br>
       first version implemented</li>
</ul>
</html>"));
        end Polynomials;

  package Icons "Icons for Math"
    extends Modelica.Icons.IconsPackage;

    partial function AxisLeft
      "Basic icon for mathematical function with y-axis on left side"

      annotation (
        Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                100}}), graphics={
            Rectangle(
              extent={{-100,100},{100,-100}},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Line(points={{-80,-80},{-80,68}}, color={192,192,192}),
            Polygon(
              points={{-80,90},{-88,68},{-72,68},{-80,90}},
              lineColor={192,192,192},
              fillColor={192,192,192},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-150,150},{150,110}},
              textString="%name",
              textColor={0,0,255})}),
        Documentation(info="<html>
<p>
Icon for a mathematical function, consisting of an y-axis on the left side.
It is expected, that an x-axis is added and a plot of the function.
</p>
</html>"));
    end AxisLeft;

    partial function AxisCenter
      "Basic icon for mathematical function with y-axis in the center"

      annotation (
        Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
                100}}), graphics={
            Rectangle(
              extent={{-100,100},{100,-100}},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid),
            Line(points={{0,-80},{0,68}}, color={192,192,192}),
            Polygon(
              points={{0,90},{-8,68},{8,68},{0,90}},
              lineColor={192,192,192},
              fillColor={192,192,192},
              fillPattern=FillPattern.Solid),
            Text(
              extent={{-150,150},{150,110}},
              textString="%name",
              textColor={0,0,255})}),
        Documentation(info="<html>
<p>
Icon for a mathematical function, consisting of an y-axis in the middle.
It is expected, that an x-axis is added and a plot of the function.
</p>
</html>"));
    end AxisCenter;
  end Icons;

  function cos "Cosine"
    extends Modelica.Math.Icons.AxisLeft;
    input Modelica.Units.SI.Angle u "Independent variable";
    output Real y "Dependent variable y=cos(u)";

  external "builtin" y = cos(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,80},{-74.4,78.1},{-68.7,72.3},{-63.1,63},{-56.7,48.7},
                {-48.6,26.6},{-29.3,-32.5},{-22.1,-51.7},{-15.7,-65.3},{-10.1,-73.8},
                {-4.42,-78.8},{1.21,-79.9},{6.83,-77.1},{12.5,-70.6},{18.1,-60.6},
                {24.5,-45.7},{32.6,-23},{50.3,31.3},{57.5,50.7},{63.9,64.6},{69.5,
                73.4},{75.2,78.6},{80,80}}),
          Text(
            extent={{-36,82},{36,34}},
            textColor={192,192,192},
            textString="cos")}),
      Documentation(info="<html>
<p>
This function returns y = cos(u), with -&infin; &lt; u &lt; &infin;:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/cos.png\">
</p>
</html>"));
  end cos;

  function tan "Tangent (u shall not be -pi/2, pi/2, 3*pi/2, ...)"
    extends Modelica.Math.Icons.AxisCenter;
    input Modelica.Units.SI.Angle u "Independent variable";
    output Real y "Dependent variable y=tan(u)";

  external "builtin" y = tan(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-78.4,-68.4},{-76.8,-59.7},{-74.4,-50},{-71.2,-40.9},
                {-67.1,-33},{-60.7,-24.8},{-51.1,-17.2},{-35.8,-9.98},{-4.42,-1.07},
                {33.4,9.12},{49.4,16.2},{59.1,23.2},{65.5,30.6},{70.4,39.1},{73.6,
                47.4},{76,56.1},{77.6,63.8},{80,80}}),
          Text(
            extent={{-90,72},{-18,24}},
            textColor={192,192,192},
            textString="tan")}),
      Documentation(info="<html>
<p>
This function returns y = tan(u), with -&infin; &lt; u &lt; &infin;
(if u is a multiple of (2n-1)*pi/2, y = tan(u) is +/- infinity).
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/tan.png\">
</p>
</html>"));
  end tan;

  function asin "Inverse sine (-1 <= u <= 1)"
    extends Modelica.Math.Icons.AxisCenter;
    input Real u "Independent variable";
    output Modelica.Units.SI.Angle y "Dependent variable y=asin(u)";

  external "builtin" y = asin(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-79.2,-72.8},{-77.6,-67.5},{-73.6,-59.4},{-66.3,
                -49.8},{-53.5,-37.3},{-30.2,-19.7},{37.4,24.8},{57.5,40.8},{68.7,
                52.7},{75.2,62.2},{77.6,67.5},{80,80}}),
          Text(
            extent={{-88,78},{-16,30}},
            textColor={192,192,192},
            textString="asin")}),
      Documentation(info="<html>
<p>
This function returns y = asin(u), with -1 &le; u &le; +1:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
</p>
</html>"));
  end asin;

  function acos "Inverse cosine (-1 <= u <= 1)"
    extends Modelica.Math.Icons.AxisCenter;
    input Real u "Independent variable";
    output Modelica.Units.SI.Angle y "Dependent variable y=acos(u)";

  external "builtin" y = acos(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={
          Line(points={{-90,-80},{68,-80}}, color={192,192,192}),
          Polygon(
            points={{90,-80},{68,-72},{68,-88},{90,-80}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,80},{-79.2,72.8},{-77.6,67.5},{-73.6,59.4},{-66.3,
                49.8},{-53.5,37.3},{-30.2,19.7},{37.4,-24.8},{57.5,-40.8},{68.7,-52.7},
                {75.2,-62.2},{77.6,-67.5},{80,-80}}),
          Text(
            extent={{-86,-14},{-14,-62}},
            textColor={192,192,192},
            textString="acos")}),
      Documentation(info="<html>
<p>
This function returns y = acos(u), with -1 &le; u &le; +1:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/acos.png\">
</p>
</html>"));
  end acos;

  function cosh "Hyperbolic cosine"
    extends Modelica.Math.Icons.AxisCenter;
    input Real u "Independent variable";
    output Real y "Dependent variable y=cosh(u)";

  external "builtin" y = cosh(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={
          Line(points={{-90,-86.083},{68,-86.083}}, color={192,192,192}),
          Polygon(
            points={{90,-86.083},{68,-78.083},{68,-94.083},{90,-86.083}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,80},{-77.6,61.1},{-74.4,39.3},{-71.2,20.7},{-67.1,
                1.29},{-63.1,-14.6},{-58.3,-29.8},{-52.7,-43.5},{-46.2,-55.1},{-39,
                -64.3},{-30.2,-71.7},{-18.9,-77.1},{-4.42,-79.9},{10.9,-79.1},{
                23.7,-75.2},{34.2,-68.7},{42.2,-60.6},{48.6,-51.2},{54.3,-40},{
                59.1,-27.5},{63.1,-14.6},{67.1,1.29},{71.2,20.7},{74.4,39.3},{
                77.6,61.1},{80,80}}),
          Text(
            extent={{4,66},{66,20}},
            textColor={192,192,192},
            textString="cosh")}),
      Documentation(info="<html>
<p>
This function returns y = cosh(u), with -&infin; &lt; u &lt; &infin;:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/cosh.png\">
</p>
</html>"));
  end cosh;

  function tanh "Hyperbolic tangent"
    extends Modelica.Math.Icons.AxisCenter;
    input Real u "Independent variable";
    output Real y "Dependent variable y=tanh(u)";

  external "builtin" y = tanh(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-47.8,-78.7},{-35.8,-75.7},{-27.7,-70.6},{-22.1,
                -64.2},{-17.3,-55.9},{-12.5,-44.3},{-7.64,-29.2},{-1.21,-4.82},{
                6.83,26.3},{11.7,42},{16.5,54.2},{21.3,63.1},{26.9,69.9},{34.2,75},
                {45.4,78.4},{72,79.9},{80,80}}),
          Text(
            extent={{-88,72},{-16,24}},
            textColor={192,192,192},
            textString="tanh")}),
      Documentation(info="<html>
<p>
This function returns y = tanh(u), with -&infin; &lt; u &lt; &infin;:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/tanh.png\">
</p>
</html>"));
  end tanh;

  function exp "Exponential, base e"
    extends Modelica.Math.Icons.AxisCenter;
    input Real u "Independent variable";
    output Real y "Dependent variable y=exp(u)";

  external "builtin" y = exp(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={
          Line(points={{-90,-80.3976},{68,-80.3976}}, color={192,192,192}),
          Polygon(
            points={{90,-80.3976},{68,-72.3976},{68,-88.3976},{90,-80.3976}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-31,-77.9},{-6.03,-74},{10.9,-68.4},{23.7,-61},
                {34.2,-51.6},{43,-40.3},{50.3,-27.8},{56.7,-13.5},{62.3,2.23},{
                67.1,18.6},{72,38.2},{76,57.6},{80,80}}),
          Text(
            extent={{-86,50},{-14,2}},
            textColor={192,192,192},
            textString="exp")}),
      Documentation(info="<html>
<p>
This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
</p>
</html>"));
  end exp;

  function log "Natural (base e) logarithm (u shall be > 0)"
    extends Modelica.Math.Icons.AxisLeft;
    input Real u "Independent variable";
    output Real y "Dependent variable y=ln(u)";

  external "builtin" y = log(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-80,-80},{-79.2,-50.6},{-78.4,-37},{-77.6,-28},{-76.8,-21.3},
                {-75.2,-11.4},{-72.8,-1.31},{-69.5,8.08},{-64.7,17.9},{-57.5,28},
                {-47,38.1},{-31.8,48.1},{-10.1,58},{22.1,68},{68.7,78.1},{80,80}}),
          Text(
            extent={{-6,-24},{66,-72}},
            textColor={192,192,192},
            textString="log")}),
      Documentation(info="<html>
<p>
This function returns y = log(10) (the natural logarithm of u),
with u &gt; 0:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/log.png\">
</p>
</html>"));
  end log;

  function log10 "Base 10 logarithm (u shall be > 0)"
    extends Modelica.Math.Icons.AxisLeft;
    input Real u "Independent variable";
    output Real y "Dependent variable y=lg(u)";

  external "builtin" y = log10(u);
    annotation (
      Icon(coordinateSystem(
          preserveAspectRatio=true,
          extent={{-100,-100},{100,100}}), graphics={
          Line(points={{-90,0},{68,0}}, color={192,192,192}),
          Polygon(
            points={{90,0},{68,8},{68,-8},{90,0}},
            lineColor={192,192,192},
            fillColor={192,192,192},
            fillPattern=FillPattern.Solid),
          Line(points={{-79.8,-80},{-79.2,-50.6},{-78.4,-37},{-77.6,-28},{-76.8,-21.3},
                {-75.2,-11.4},{-72.8,-1.31},{-69.5,8.08},{-64.7,17.9},{-57.5,28},
                {-47,38.1},{-31.8,48.1},{-10.1,58},{22.1,68},{68.7,78.1},{80,80}}),
          Text(
            extent={{-30,-22},{60,-70}},
            textColor={192,192,192},
            textString="log10")}),
      Documentation(info="<html>
<p>
This function returns y = log10(u),
with u &gt; 0:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/Math/log10.png\">
</p>
</html>"));
  end log10;
  annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},
            {100,100}}), graphics={Line(points={{-80,0},{-68.7,34.2},{-61.5,53.1},
              {-55.1,66.4},{-49.4,74.6},{-43.8,79.1},{-38.2,79.8},{-32.6,76.6},{
              -26.9,69.7},{-21.3,59.4},{-14.9,44.1},{-6.83,21.2},{10.1,-30.8},{17.3,
              -50.2},{23.7,-64.2},{29.3,-73.1},{35,-78.4},{40.6,-80},{46.2,-77.6},
              {51.9,-71.5},{57.5,-61.9},{63.9,-47.2},{72,-24.8},{80,0}}, color={
              0,0,0}, smooth=Smooth.Bezier)}), Documentation(info="<html>
<p>
This package contains <strong>basic mathematical functions</strong> (such as sin(..)),
as well as functions operating on
<a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
<a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
<a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
<a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
</p>

<h4>Main Authors</h4>
<p><a href=\"http://www.robotic.dlr.de/Martin.Otter/\"><strong>Martin Otter</strong></a>
and <strong>Marcus Baur</strong><br>
Deutsches Zentrum f&uuml;r Luft- und Raumfahrt e.V. (DLR)<br>
Institut f&uuml;r Systemdynamik und Regelungstechnik (DLR-SR)<br>
Forschungszentrum Oberpfaffenhofen<br>
D-82234 Wessling<br>
Germany<br>
email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a>
</p>

<p>
Copyright &copy; 1998-2020, Modelica Association and contributors
</p>
</html>",   revisions="<html>
<ul>
<li><em>June 22, 2019</em>
       by Thomas Beutlich: Functions tempInterpol1/tempInterpol2 moved to ObsoleteModelica4</li>
<li><em>August 24, 2016</em>
       by Christian Kral: added wrapAngle</li>
<li><em>October 21, 2002</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
       and Christian Schweiger:<br>
       Function tempInterpol2 added.</li>
<li><em>Oct. 24, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Icons for icon and diagram level introduced.</li>
<li><em>June 30, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
</html>"));
  end Math;

  package Utilities
  "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)"
    extends Modelica.Icons.UtilitiesPackage;

    package Streams "Read from files and write to files"
      extends Modelica.Icons.FunctionsPackage;

      pure function error "Print error message and cancel all actions - in case of an unrecoverable error"
        extends Modelica.Icons.Function;
        input String string "String to be printed to error message window";
        external "C" ModelicaError(string) annotation(IncludeDirectory="modelica://Modelica/Resources/C-Sources", Include="#include \"ModelicaUtilities.h\"", Library="ModelicaExternalC");
        annotation (Documentation(info="<html>
<h4>Syntax</h4>
<blockquote><pre>
Streams.<strong>error</strong>(string);
</pre></blockquote>
<h4>Description</h4>
<p>
In case of an unrecoverable error (i.e., if the solver is unable to recover from the error),
print the string \"string\" as error message and cancel all actions.
This function is semantically equivalent with the built-in function <strong>assert</strong> if called with the (default) <strong>AssertionLevel.error</strong>.
Line breaks are characterized by \"\\n\" in the string.
</p>
<h4>Example</h4>
<blockquote><pre>
Streams.error(\"x (= \" + String(x) + \")\\nhas to be in the range 0 .. 1\");
</pre></blockquote>
<h4>See also</h4>
<p>
<a href=\"modelica://Modelica.Utilities.Streams\">Streams</a>,
<a href=\"modelica://Modelica.Utilities.Streams.print\">Streams.print</a>,
<a href=\"modelica://ModelicaReference.Operators.'assert()'\">ModelicaReference.Operators.'assert()'</a>
<a href=\"modelica://ModelicaReference.Operators.'String()'\">ModelicaReference.Operators.'String()'</a>
</p>
</html>"));
      end error;
      annotation (
        Documentation(info="<html>
<h4>Library content</h4>
<p>
Package <strong>Streams</strong> contains functions to input and output strings
to a message window or on files, as well as reading matrices from file
and writing matrices to file. Note that a string is interpreted
and displayed as html text (e.g., with print(..) or error(..))
if it is enclosed with the Modelica html quotation, e.g.,
</p>
<blockquote><p>
string = \"&lt;html&gt; first line &lt;br&gt; second line &lt;/html&gt;\".
</p></blockquote>
<p>
It is a quality of implementation, whether (a) all tags of html are supported
or only a subset, (b) how html tags are interpreted if the output device
does not allow to display formatted text.
</p>
<p>
In the table below an example call to every function is given:
</p>
<table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
  <tr><th><strong><em>Function/type</em></strong></th><th><strong><em>Description</em></strong></th></tr>
  <tr><td><a href=\"modelica://Modelica.Utilities.Streams.print\">print</a>(string)<br>
          <a href=\"modelica://Modelica.Utilities.Streams.print\">print</a>(string,fileName)</td>
      <td> Print string \"string\" or vector of strings to message window or on
           file \"fileName\".</td>
  </tr>
  <tr><td>stringVector =
         <a href=\"modelica://Modelica.Utilities.Streams.readFile\">readFile</a>(fileName)</td>
      <td> Read complete text file and return it as a vector of strings.</td>
  </tr>
  <tr><td>(string, endOfFile) =
         <a href=\"modelica://Modelica.Utilities.Streams.readLine\">readLine</a>(fileName, lineNumber)</td>
      <td>Returns from the file the content of line lineNumber.</td>
  </tr>
  <tr><td>lines =
         <a href=\"modelica://Modelica.Utilities.Streams.countLines\">countLines</a>(fileName)</td>
      <td>Returns the number of lines in a file.</td>
  </tr>
  <tr><td><a href=\"modelica://Modelica.Utilities.Streams.error\">error</a>(string)</td>
      <td> Print error message \"string\" to message window
           and cancel all actions</td>
  </tr>
  <tr><td><a href=\"modelica://Modelica.Utilities.Streams.close\">close</a>(fileName)</td>
      <td> Close file if it is still open. Ignore call if
           file is already closed or does not exist. </td>
  </tr>
  <tr><td><a href=\"modelica://Modelica.Utilities.Streams.readMatrixSize\">readMatrixSize</a>(fileName, matrixName)</td>
      <td> Read dimensions of a Real matrix from a MATLAB MAT file. </td></tr>
  <tr><td><a href=\"modelica://Modelica.Utilities.Streams.readRealMatrix\">readRealMatrix</a>(fileName, matrixName, nrow, ncol)</td>
      <td> Read a Real matrix from a MATLAB MAT file. </td></tr>
  <tr><td><a href=\"modelica://Modelica.Utilities.Streams.writeRealMatrix\">writeRealMatrix</a>(fileName, matrixName, matrix, append, format)</td>
      <td> Write Real matrix to a MATLAB MAT file. </td></tr>
</table>
<p>
Use functions <strong>scanXXX</strong> from package
<a href=\"modelica://Modelica.Utilities.Strings\">Strings</a>
to parse a string.
</p>
<p>
If Real, Integer or Boolean values shall be printed
or used in an error message, they have to be first converted
to strings with the builtin operator
<a href=\"modelica://ModelicaReference.Operators.'String()'\">ModelicaReference.Operators.'String()'</a>(...).
Example:
</p>
<blockquote><pre>
<strong>if</strong> x &lt; 0 <strong>or</strong> x &gt; 1 <strong>then</strong>
   Streams.error(\"x (= \" + String(x) + \") has to be in the range 0 .. 1\");
<strong>end if</strong>;
</pre></blockquote>
</html>"));
    end Streams;
      annotation (
  Documentation(info="<html>
<p>
This package contains Modelica <strong>functions</strong> that are
especially suited for <strong>scripting</strong>. The functions might
be used to work with strings, read data from file, write data
to file or copy, move and remove files.
</p>
<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"modelica://Modelica.Utilities.UsersGuide\">Modelica.Utilities.User's Guide</a>
     discusses the most important aspects of this library.</li>
<li> <a href=\"modelica://Modelica.Utilities.Examples\">Modelica.Utilities.Examples</a>
     contains examples that demonstrate the usage of this library.</li>
</ul>
<p>
The following main sublibraries are available:
</p>
<ul>
<li> <a href=\"modelica://Modelica.Utilities.Files\">Files</a>
     provides functions to operate on files and directories, e.g.,
     to copy, move, remove files.</li>
<li> <a href=\"modelica://Modelica.Utilities.Streams\">Streams</a>
     provides functions to read from files and write to files.</li>
<li> <a href=\"modelica://Modelica.Utilities.Strings\">Strings</a>
     provides functions to operate on strings. E.g.
     substring, find, replace, sort, scanToken.</li>
<li> <a href=\"modelica://Modelica.Utilities.System\">System</a>
     provides functions to interact with the environment.
     E.g., get or set the working directory or environment
     variables and to send a command to the default shell.</li>
</ul>

<p>
Copyright &copy; 1998-2020, Modelica Association and contributors
</p>
</html>"));
  end Utilities;

  package Constants
  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    import Modelica.Units.SI;
    import Modelica.Units.NonSI;

    final constant Real pi=2*Modelica.Math.asin(1.0);

    final constant Real eps=ModelicaServices.Machine.eps
      "Biggest number such that 1.0 + eps = 1.0";

    final constant Real small=ModelicaServices.Machine.small
      "Smallest number such that small and -small are representable on the machine";

    final constant Real inf=ModelicaServices.Machine.inf
      "Biggest Real number such that inf and -inf are representable on the machine";

    final constant SI.Acceleration g_n=9.80665
      "Standard acceleration of gravity on earth";

    final constant Real k(final unit="J/K") = 1.380649e-23
      "Boltzmann constant";

    final constant Real R(final unit="J/(mol.K)") = k*N_A
      "Molar gas constant";

    final constant Real N_A(final unit="1/mol") = 6.02214076e23
      "Avogadro constant";

    final constant NonSI.Temperature_degC T_zero=-273.15
      "Absolute zero temperature";
    annotation (
      Documentation(info="<html>
<p>
This package provides often needed constants from mathematics, machine
dependent constants and constants from nature. The latter constants
(name, value, description) are from the following source (based on the second source):
</p>
<dl>
<dt>Michael Stock, Richard Davis, Estefan&iacute;a de Mirand&eacute;s and Martin J T Milton:</dt>
<dd><strong>The revision of the SI-the result of three decades of progress in metrology</strong> in Metrologia, Volume 56, Number 2.
<a href= \"https://iopscience.iop.org/article/10.1088/1681-7575/ab0013/pdf\">https://iopscience.iop.org/article/10.1088/1681-7575/ab0013/pdf</a>, 2019.
</dd>
</dl>
<dl>
<dt>D B Newell, F Cabiati, J Fischer, K Fujii, S G Karshenboim, H S Margolis , E de Mirand&eacute;s, P J Mohr, F Nez, K Pachucki, T J Quinn, B N Taylor, M Wang, B M Wood and Z Zhang:</dt>
<dd><strong>The CODATA 2017 values of h, e, k, and NA for the revision of the SI</strong> in Metrologia, Volume 55, Number 1.
<a href= \"https://iopscience.iop.org/article/10.1088/1681-7575/aa950a/pdf\">https://iopscience.iop.org/article/10.1088/1681-7575/aa950a/pdf</a>, 2017.
</dd>
</dl>
<p>BIPM is Bureau International des Poids et Mesures (they publish the SI-standard).</p>
<p>CODATA is the Committee on Data for Science and Technology.</p>

<dl>
<dt><strong>Main Author:</strong></dt>
<dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
    Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
    Oberpfaffenhofen<br>
    Postfach 1116<br>
    D-82230 We&szlig;ling<br>
    email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
</dl>

<p>
Copyright &copy; 1998-2020, Modelica Association and contributors
</p>
</html>",   revisions="<html>
<ul>
<li><em>Dec 4, 2019</em>
       by Thomas Beutlich:<br>
       Constant G updated according to 2018 CODATA value.</li>
<li><em>Mar 25, 2019</em>
       by Hans Olsson:<br>
       Constants updated according to 2017 CODATA values and new SI-standard.</li>
<li><em>Nov 4, 2015</em>
       by Thomas Beutlich:<br>
       Constants updated according to 2014 CODATA values.</li>
<li><em>Nov 8, 2004</em>
       by Christian Schweiger:<br>
       Constants updated according to 2002 CODATA values.</li>
<li><em>Dec 9, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Constants updated according to 1998 CODATA values. Using names, values
       and description text from this source. Included magnetic and
       electric constant.</li>
<li><em>Sep 18, 1999</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Constants eps, inf, small introduced.</li>
<li><em>Nov 15, 1997</em>
       by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
       Realized.</li>
</ul>
</html>"),
      Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}), graphics={
        Polygon(
          origin={-9.2597,25.6673},
          fillColor={102,102,102},
          pattern=LinePattern.None,
          fillPattern=FillPattern.Solid,
          points={{48.017,11.336},{48.017,11.336},{10.766,11.336},{-25.684,10.95},{-34.944,-15.111},{-34.944,-15.111},{-32.298,-15.244},{-32.298,-15.244},{-22.112,0.168},{11.292,0.234},{48.267,-0.097},{48.267,-0.097}},
          smooth=Smooth.Bezier),
        Polygon(
          origin={-19.9923,-8.3993},
          fillColor={102,102,102},
          pattern=LinePattern.None,
          fillPattern=FillPattern.Solid,
          points={{3.239,37.343},{3.305,37.343},{-0.399,2.683},{-16.936,-20.071},{-7.808,-28.604},{6.811,-22.519},{9.986,37.145},{9.986,37.145}},
          smooth=Smooth.Bezier),
        Polygon(
          origin={23.753,-11.5422},
          fillColor={102,102,102},
          pattern=LinePattern.None,
          fillPattern=FillPattern.Solid,
          points={{-10.873,41.478},{-10.873,41.478},{-14.048,-4.162},{-9.352,-24.8},{7.912,-24.469},{16.247,0.27},{16.247,0.27},{13.336,0.071},{13.336,0.071},{7.515,-9.983},{-3.134,-7.271},{-2.671,41.214},{-2.671,41.214}},
          smooth=Smooth.Bezier)}));
  end Constants;

  package Icons "Library of icons"
    extends Icons.Package;

    partial package ExamplesPackage
    "Icon for packages containing runnable examples"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Polygon(
              origin={8.0,14.0},
              lineColor={78,138,73},
              fillColor={78,138,73},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              points={{-58.0,46.0},{42.0,-14.0},{-58.0,-74.0},{-58.0,46.0}})}), Documentation(info="<html>
<p>This icon indicates a package that contains executable examples.</p>
</html>"));
    end ExamplesPackage;

    partial model Example "Icon for runnable examples"

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={
            Ellipse(lineColor = {75,138,73},
                    fillColor={255,255,255},
                    fillPattern = FillPattern.Solid,
                    extent = {{-100,-100},{100,100}}),
            Polygon(lineColor = {0,0,255},
                    fillColor = {75,138,73},
                    pattern = LinePattern.None,
                    fillPattern = FillPattern.Solid,
                    points = {{-36,60},{64,0},{-36,-60},{-36,60}})}), Documentation(info="<html>
<p>This icon indicates an example. The play button suggests that the example can be executed.</p>
</html>"));
    end Example;

    partial package Package "Icon for standard packages"
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={
            Rectangle(
              lineColor={200,200,200},
              fillColor={248,248,248},
              fillPattern=FillPattern.HorizontalCylinder,
              extent={{-100.0,-100.0},{100.0,100.0}},
              radius=25.0),
            Rectangle(
              lineColor={128,128,128},
              extent={{-100.0,-100.0},{100.0,100.0}},
              radius=25.0)}), Documentation(info="<html>
<p>Standard package icon.</p>
</html>"));
    end Package;

    partial package BasesPackage "Icon for packages containing base classes"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Ellipse(
              extent={{-30.0,-30.0},{30.0,30.0}},
              lineColor={128,128,128},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid)}),
                                Documentation(info="<html>
<p>This icon shall be used for a package/library that contains base models and classes, respectively.</p>
</html>"));
    end BasesPackage;

    partial package VariantsPackage "Icon for package containing variants"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},
                {100,100}}), graphics={
            Ellipse(
              origin={10.0,10.0},
              fillColor={76,76,76},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              extent={{-80.0,-80.0},{-20.0,-20.0}}),
            Ellipse(
              origin={10.0,10.0},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              extent={{0.0,-80.0},{60.0,-20.0}}),
            Ellipse(
              origin={10.0,10.0},
              fillColor={128,128,128},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              extent={{0.0,0.0},{60.0,60.0}}),
            Ellipse(
              origin={10.0,10.0},
              lineColor={128,128,128},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid,
              extent={{-80.0,0.0},{-20.0,60.0}})}),
                                Documentation(info="<html>
<p>This icon shall be used for a package/library that contains several variants of one component.</p>
</html>"));
    end VariantsPackage;

    partial package InterfacesPackage "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Polygon(origin={20.0,0.0},
              lineColor={64,64,64},
              fillColor={255,255,255},
              fillPattern=FillPattern.Solid,
              points={{-10.0,70.0},{10.0,70.0},{40.0,20.0},{80.0,20.0},{80.0,-20.0},{40.0,-20.0},{10.0,-70.0},{-10.0,-70.0}}),
            Polygon(fillColor={102,102,102},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              points={{-100.0,20.0},{-60.0,20.0},{-30.0,70.0},{-10.0,70.0},{-10.0,-70.0},{-30.0,-70.0},{-60.0,-20.0},{-100.0,-20.0}})}),
                                Documentation(info="<html>
<p>This icon indicates packages containing interfaces.</p>
</html>"));
    end InterfacesPackage;

    partial package SourcesPackage "Icon for packages containing sources"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Polygon(origin={23.3333,0.0},
              fillColor={128,128,128},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              points={{-23.333,30.0},{46.667,0.0},{-23.333,-30.0}}),
            Rectangle(
              fillColor = {128,128,128},
              pattern = LinePattern.None,
              fillPattern = FillPattern.Solid,
              extent = {{-70,-4.5},{0,4.5}})}),
                                Documentation(info="<html>
<p>This icon indicates a package which contains sources.</p>
</html>"));
    end SourcesPackage;

    partial package UtilitiesPackage "Icon for utility packages"
      extends Modelica.Icons.Package;
       annotation (Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}), graphics={
      Polygon(
        origin={1.3835,-4.1418},
        rotation=45.0,
        fillColor={64,64,64},
        pattern=LinePattern.None,
        fillPattern=FillPattern.Solid,
        points={{-15.0,93.333},{-15.0,68.333},{0.0,58.333},{15.0,68.333},{15.0,93.333},{20.0,93.333},{25.0,83.333},{25.0,58.333},{10.0,43.333},{10.0,-41.667},{25.0,-56.667},{25.0,-76.667},{10.0,-91.667},{0.0,-91.667},{0.0,-81.667},{5.0,-81.667},{15.0,-71.667},{15.0,-61.667},{5.0,-51.667},{-5.0,-51.667},{-15.0,-61.667},{-15.0,-71.667},{-5.0,-81.667},{0.0,-81.667},{0.0,-91.667},{-10.0,-91.667},{-25.0,-76.667},{-25.0,-56.667},{-10.0,-41.667},{-10.0,43.333},{-25.0,58.333},{-25.0,83.333},{-20.0,93.333}}),
      Polygon(
        origin={10.1018,5.218},
        rotation=-45.0,
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid,
        points={{-15.0,87.273},{15.0,87.273},{20.0,82.273},{20.0,27.273},{10.0,17.273},{10.0,7.273},{20.0,2.273},{20.0,-2.727},{5.0,-2.727},{5.0,-77.727},{10.0,-87.727},{5.0,-112.727},{-5.0,-112.727},{-10.0,-87.727},{-5.0,-77.727},{-5.0,-2.727},{-20.0,-2.727},{-20.0,2.273},{-10.0,7.273},{-10.0,17.273},{-20.0,27.273},{-20.0,82.273}})}),
      Documentation(info="<html>
<p>This icon indicates a package containing utility classes.</p>
</html>"));
    end UtilitiesPackage;

    partial package TypesPackage
    "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Polygon(
              origin={-12.167,-23},
              fillColor={128,128,128},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              points={{12.167,65},{14.167,93},{36.167,89},{24.167,20},{4.167,-30},
                  {14.167,-30},{24.167,-30},{24.167,-40},{-5.833,-50},{-15.833,
                  -30},{4.167,20},{12.167,65}},
              smooth=Smooth.Bezier), Polygon(
              origin={2.7403,1.6673},
              fillColor={128,128,128},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              points={{49.2597,22.3327},{31.2597,24.3327},{7.2597,18.3327},{-26.7403,
                10.3327},{-46.7403,14.3327},{-48.7403,6.3327},{-32.7403,0.3327},{-6.7403,
                4.3327},{33.2597,14.3327},{49.2597,14.3327},{49.2597,22.3327}},
              smooth=Smooth.Bezier)}));
    end TypesPackage;

    partial package FunctionsPackage "Icon for packages containing functions"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
              Text(
                textColor={128,128,128},
                extent={{-90,-90},{90,90}},
                textString="f")}));
    end FunctionsPackage;

    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Polygon(
              origin={-8.167,-17},
              fillColor={128,128,128},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              points={{-15.833,20.0},{-15.833,30.0},{14.167,40.0},{24.167,20.0},{
                  4.167,-30.0},{14.167,-30.0},{24.167,-30.0},{24.167,-40.0},{-5.833,
                  -50.0},{-15.833,-30.0},{4.167,20.0},{-5.833,20.0}},
              smooth=Smooth.Bezier), Ellipse(
              origin={-0.5,56.5},
              fillColor={128,128,128},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              extent={{-12.5,-12.5},{12.5,12.5}})}));
    end IconsPackage;

    partial package InternalPackage
    "Icon for an internal package (indicating that the package should not be directly utilized by user)"
    annotation (
      Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,
              100}}), graphics={
          Rectangle(
            lineColor={215,215,215},
            fillColor={255,255,255},
            fillPattern=FillPattern.HorizontalCylinder,
            extent={{-100,-100},{100,100}},
            radius=25),
          Rectangle(
            lineColor={215,215,215},
            extent={{-100,-100},{100,100}},
            radius=25),
          Ellipse(
            extent={{-80,80},{80,-80}},
            lineColor={215,215,215},
            fillColor={215,215,215},
            fillPattern=FillPattern.Solid),
          Ellipse(
            extent={{-55,55},{55,-55}},
            lineColor={255,255,255},
            fillColor={255,255,255},
            fillPattern=FillPattern.Solid),
          Rectangle(
            extent={{-60,14},{60,-14}},
            lineColor={215,215,215},
            fillColor={215,215,215},
            fillPattern=FillPattern.Solid,
            rotation=45)}),
      Documentation(info="<html>

<p>
This icon shall be used for a package that contains internal classes not to be
directly utilized by a user.
</p>
</html>"));
    end InternalPackage;

    partial package MaterialPropertiesPackage
    "Icon for package containing property classes"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Ellipse(
              lineColor={102,102,102},
              fillColor={204,204,204},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Sphere,
              extent={{-60.0,-60.0},{60.0,60.0}})}),
                                Documentation(info="<html>
<p>This icon indicates a package that contains properties</p>
</html>"));
    end MaterialPropertiesPackage;

    partial package RecordsPackage "Icon for package containing records"
      extends Modelica.Icons.Package;
      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={
            Rectangle(
              origin={0,-20},
              lineColor={64,64,64},
              fillColor={255,215,136},
              fillPattern=FillPattern.Solid,
              extent={{-80,-60},{80,60}},
              radius=25.0),
            Line(
              points={{-80,0},{80,0}},
              color={64,64,64}),
            Line(
              origin={0,-40},
              points={{-80,0},{80,0}},
              color={64,64,64}),
            Line(
              origin={0,-5},
              points={{0,45},{0,-75}},
              color={64,64,64})}),
                                Documentation(info="<html>
<p>This icon indicates a package that contains records</p>
</html>"));
    end RecordsPackage;

    partial function Function "Icon for functions"

      annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={
            Text(
              textColor={0,0,255},
              extent={{-150,105},{150,145}},
              textString="%name"),
            Ellipse(
              lineColor = {108,88,49},
              fillColor = {255,215,136},
              fillPattern = FillPattern.Solid,
              extent = {{-100,-100},{100,100}}),
            Text(
              textColor={108,88,49},
              extent={{-90.0,-90.0},{90.0,90.0}},
              textString="f")}),
    Documentation(info="<html>
<p>This icon indicates Modelica functions.</p>
</html>"));
    end Function;

    partial record Record "Icon for records"

      annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,100}}), graphics={
            Text(
              textColor={0,0,255},
              extent={{-150,60},{150,100}},
              textString="%name"),
            Rectangle(
              origin={0.0,-25.0},
              lineColor={64,64,64},
              fillColor={255,215,136},
              fillPattern=FillPattern.Solid,
              extent={{-100.0,-75.0},{100.0,75.0}},
              radius=25.0),
            Line(
              points={{-100.0,0.0},{100.0,0.0}},
              color={64,64,64}),
            Line(
              origin={0.0,-50.0},
              points={{-100.0,0.0},{100.0,0.0}},
              color={64,64,64}),
            Line(
              origin={0.0,-25.0},
              points={{0.0,75.0},{0.0,-75.0}},
              color={64,64,64})}), Documentation(info="<html>
<p>
This icon is indicates a record.
</p>
</html>"));
    end Record;

    type TypeReal "Icon for Real types"
        extends Real;
        annotation(Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics={
              Rectangle(
                lineColor={160,160,164},
                fillColor={160,160,164},
                fillPattern=FillPattern.Solid,
                extent={{-100.0,-100.0},{100.0,100.0}},
                radius=25.0),
              Text(
                textColor={255,255,255},
                extent={{-90.0,-50.0},{90.0,50.0}},
                textString="R")}),Documentation(info="<html>
<p>
This icon is designed for a <strong>Real</strong> type.
</p>
</html>"));
    end TypeReal;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,
                -100},{100,100}}), graphics={Polygon(
              origin={-8.167,-17},
              fillColor={128,128,128},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              points={{-15.833,20.0},{-15.833,30.0},{14.167,40.0},{24.167,20.0},{
                  4.167,-30.0},{14.167,-30.0},{24.167,-30.0},{24.167,-40.0},{-5.833,
                  -50.0},{-15.833,-30.0},{4.167,20.0},{-5.833,20.0}},
              smooth=Smooth.Bezier), Ellipse(
              origin={-0.5,56.5},
              fillColor={128,128,128},
              pattern=LinePattern.None,
              fillPattern=FillPattern.Solid,
              extent={{-12.5,-12.5},{12.5,12.5}})}), Documentation(info="<html>
<p>This package contains definitions for the graphical layout of components which may be used in different libraries. The icons can be utilized by inheriting them in the desired class using &quot;extends&quot; or by directly copying the &quot;icon&quot; layer.</p>

<h4>Main Authors</h4>

<dl>
<dt><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a></dt>
    <dd>Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)</dd>
    <dd>Oberpfaffenhofen</dd>
    <dd>Postfach 1116</dd>
    <dd>D-82230 Wessling</dd>
    <dd>email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
<dt>Christian Kral</dt>

    <dd>  <a href=\"https://christiankral.net/\">Electric Machines, Drives and Systems</a><br>
</dd>
    <dd>1060 Vienna, Austria</dd>
    <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>
<dt>Johan Andreasson</dt>
    <dd><a href=\"https://www.modelon.com/\">Modelon AB</a></dd>
    <dd>Ideon Science Park</dd>
    <dd>22370 Lund, Sweden</dd>
    <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
</dl>

<p>
Copyright &copy; 1998-2020, Modelica Association and contributors
</p>
</html>"));
  end Icons;

  package Units "Library of type and unit definitions"
    extends Modelica.Icons.Package;

    package SI "Library of SI unit definitions"
      extends Modelica.Icons.Package;

      type Angle = Real (
          final quantity="Angle",
          final unit="rad",
          displayUnit="deg");

      type Length = Real (final quantity="Length", final unit="m");

      type Diameter = Length(min=0);

      type Area = Real (final quantity="Area", final unit="m2");

      type Volume = Real (final quantity="Volume", final unit="m3");

      type Time = Real (final quantity="Time", final unit="s");

      type Velocity = Real (final quantity="Velocity", final unit="m/s");

      type Acceleration = Real (final quantity="Acceleration", final unit="m/s2");

      type Mass = Real (
          quantity="Mass",
          final unit="kg",
          min=0);

      type Density = Real (
          final quantity="Density",
          final unit="kg/m3",
          displayUnit="g/cm3",
          min=0.0);

      type SpecificVolume = Real (
          final quantity="SpecificVolume",
          final unit="m3/kg",
          min=0.0);

      type Momentum = Real (final quantity="Momentum", final unit="kg.m/s");

      type Force = Real (final quantity="Force", final unit="N");

      type Pressure = Real (
          final quantity="Pressure",
          final unit="Pa",
          displayUnit="bar");

      type AbsolutePressure = Pressure (min=0.0, nominal = 1e5);

      type DynamicViscosity = Real (
          final quantity="DynamicViscosity",
          final unit="Pa.s",
          min=0);

      type SurfaceTension = Real (final quantity="SurfaceTension", final unit="N/m");

      type Energy = Real (final quantity="Energy", final unit="J");

      type Power = Real (final quantity="Power", final unit="W");

      type EnthalpyFlowRate = Real (final quantity="EnthalpyFlowRate", final unit=
              "W");

      type MassFlowRate = Real (quantity="MassFlowRate", final unit="kg/s");

      type ThermodynamicTemperature = Real (
          final quantity="ThermodynamicTemperature",
          final unit="K",
          min = 0.0,
          start = 288.15,
          nominal = 300,
          displayUnit="degC")
        "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue=true);

      type Temperature = ThermodynamicTemperature;

      type TemperatureDifference = Real (
          final quantity="ThermodynamicTemperature",
          final unit="K") annotation(absoluteValue=false);

      type RelativePressureCoefficient = Real (final quantity=
              "RelativePressureCoefficient", final unit="1/K");

      type Compressibility = Real (final quantity="Compressibility", final unit=
              "1/Pa");

      type IsothermalCompressibility = Compressibility;

      type HeatFlowRate = Real (final quantity="Power", final unit="W");

      type ThermalConductivity = Real (final quantity="ThermalConductivity", final unit=
                 "W/(m.K)");

      type CoefficientOfHeatTransfer = Real (final quantity=
              "CoefficientOfHeatTransfer", final unit="W/(m2.K)");

      type SpecificHeatCapacity = Real (final quantity="SpecificHeatCapacity",
            final unit="J/(kg.K)");

      type RatioOfSpecificHeatCapacities = Real (final quantity=
              "RatioOfSpecificHeatCapacities", final unit="1");

      type SpecificEntropy = Real (final quantity="SpecificEntropy",
                                   final unit="J/(kg.K)");

      type SpecificEnergy = Real (final quantity="SpecificEnergy",
                                  final unit="J/kg");

      type SpecificInternalEnergy = SpecificEnergy;

      type SpecificEnthalpy = SpecificEnergy;

      type DerDensityByEnthalpy = Real (final unit="kg.s2/m5");

      type DerDensityByPressure = Real (final unit="s2/m2");

      type DerDensityByTemperature = Real (final unit="kg/(m3.K)");

      type DerEnthalpyByPressure = Real (final unit="J.m.s2/kg2");

      type MolarMass = Real (final quantity="MolarMass", final unit="kg/mol", min=0);

      type MolarVolume = Real (final quantity="MolarVolume", final unit="m3/mol", min=0);

      type MassFraction = Real (final quantity="MassFraction", final unit="1",
                                min=0, max=1);

      type MoleFraction = Real (final quantity="MoleFraction", final unit="1",
                                min = 0, max = 1);

      type ReynoldsNumber = Real (final quantity="ReynoldsNumber", final unit="1");

      type NusseltNumber = Real (final quantity="NusseltNumber", final unit="1");

      type PrandtlNumber = Real (final quantity="PrandtlNumber", final unit="1");
      annotation (Icon(graphics={Text(
              extent={{-80,80},{80,-78}},
              textColor={128,128,128},
              fillColor={128,128,128},
              fillPattern=FillPattern.None,
              fontName="serif",
              textString="SI",
              textStyle={TextStyle.Italic})}),
                                       Documentation(info="<html>
<p>This package provides predefined types based on the international standard
on units.
</p>
<p>
For an introduction to the conventions used in this package, have a look at:
<a href=\"modelica://Modelica.Units.UsersGuide.Conventions\">Conventions</a>.
</p>
</html>"));
    end SI;

    package NonSI "Type definitions of non SI and other units"
      extends Modelica.Icons.Package;

      type Temperature_degC = Real (final quantity="ThermodynamicTemperature",
            final unit="degC")
        "Absolute temperature in degree Celsius (for relative temperature use Modelica.Units.SI.TemperatureDifference)" annotation(absoluteValue=true);

      type Pressure_bar = Real (final quantity="Pressure", final unit="bar")
        "Absolute pressure in bar";
      annotation (Documentation(info="<html>
<p>
This package provides predefined types, such as <strong>Angle_deg</strong> (angle in
degree), <strong>AngularVelocity_rpm</strong> (angular velocity in revolutions per
minute) or <strong>Temperature_degF</strong> (temperature in degree Fahrenheit),
which are in common use but are not part of the international standard on
units according to ISO 31-1992 \"General principles concerning quantities,
units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
the use of their multiples and of certain other units\".</p>
<p>If possible, the types in this package should not be used. Use instead
types of package <code>Modelica.Units.SI</code>. For more information on units, see also
the book of Francois Cardarelli <strong>Scientific Unit Conversion - A
Practical Guide to Metrication</strong> (Springer 1997).</p>
</html>"), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(
              extent={{-10,10},{10,-10}},
              lineColor={128,128,128},
              fillColor={128,128,128},
              fillPattern=FillPattern.Solid), Ellipse(
              extent={{-60,10},{-40,-10}},
              lineColor={128,128,128},
              fillColor={128,128,128},
              fillPattern=FillPattern.Solid), Ellipse(
              extent={{40,10},{60,-10}},
              lineColor={128,128,128},
              fillColor={128,128,128},
              fillPattern=FillPattern.Solid)}));
    end NonSI;

    package Conversions
    "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      function to_degC "Convert from kelvin to degree Celsius"
        extends Modelica.Units.Icons.Conversion;
        input SI.Temperature Kelvin "Value in kelvin";
        output Modelica.Units.NonSI.Temperature_degC Celsius "Value in degree Celsius";
      algorithm
        Celsius := Kelvin + Modelica.Constants.T_zero;
        annotation (Inline=true,Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={Text(
                extent={{-20,100},{-100,20}},
                textString="K"), Text(
                extent={{100,-20},{20,-100}},
                textString="degC")}));
      end to_degC;

      function from_degC "Convert from degree Celsius to kelvin"
        extends Modelica.Units.Icons.Conversion;
        input Modelica.Units.NonSI.Temperature_degC Celsius "Value in degree Celsius";
        output SI.Temperature Kelvin "Value in kelvin";
      algorithm
        Kelvin := Celsius - Modelica.Constants.T_zero;
        annotation (Inline=true,Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={Text(
                extent={{-20,100},{-100,20}},
                textString="degC"), Text(
                extent={{100,-20},{20,-100}},
                textString="K")}));
      end from_degC;

      function to_bar "Convert from Pascal to bar"
        extends Modelica.Units.Icons.Conversion;
        input SI.Pressure Pa "Value in Pascal";
        output Modelica.Units.NonSI.Pressure_bar bar "Value in bar";
      algorithm
        bar := Pa/1e5;
        annotation (Inline=true,Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={Text(
                extent={{-12,100},{-100,56}},
                textString="Pa"), Text(
                extent={{98,-52},{-4,-100}},
                textString="bar")}));
      end to_bar;
      annotation (Documentation(info="<html>
<p>This package provides conversion functions from the non SI Units
defined in package <code>Modelica.Units.NonSI</code> to the
corresponding SI Units defined in package <code>Modelica.Units.SI</code> and vice
versa. It is recommended to use these functions in the following
way (note, that all functions have one Real input and one Real output
argument):</p>
<blockquote><pre>
<strong>import</strong> Modelica.Units.SI;
<strong>import</strong> Modelica.Units.Conversions.{from_degC, from_deg, from_rpm};
   ...
<strong>parameter</strong> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to kelvin
<strong>parameter</strong> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
<strong>parameter</strong> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                   // to radian per seconds
</pre></blockquote>

</html>"),     Icon(graphics={
            Polygon(
              points={{80,0},{20,20},{20,-20},{80,0}},
              lineColor={191,0,0},
              fillColor={191,0,0},
              fillPattern=FillPattern.Solid),
            Line(points={{-80,0},{20,0}}, color={191,0,0})}));
    end Conversions;

    package Icons "Icons for Units"
      extends Modelica.Icons.IconsPackage;

      partial function Conversion "Base icon for conversion functions"

        annotation (Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,
                  -100},{100,100}}), graphics={
              Rectangle(
                extent={{-100,100},{100,-100}},
                lineColor={191,0,0},
                fillColor={255,255,255},
                fillPattern=FillPattern.Solid),
              Line(points={{-90,0},{30,0}}, color={191,0,0}),
              Polygon(
                points={{90,0},{30,20},{30,-20},{90,0}},
                lineColor={191,0,0},
                fillColor={191,0,0},
                fillPattern=FillPattern.Solid),
              Text(
                extent={{-115,155},{115,105}},
                textString="%name",
                textColor={0,0,255})}));
      end Conversion;
    end Icons;
    annotation (Icon(graphics={
        Polygon(
          fillColor = {128,128,128},
          pattern = LinePattern.None,
          fillPattern = FillPattern.Solid,
          points = {{-80,-40},{-80,-40},{-55,50},{-52.5,62.5},{-65,60},{-65,65},{-35,77.5},{-32.5,60},{-50,0},{-50,0},{-30,15},{-20,27.5},{-32.5,27.5},{-32.5,27.5},{-32.5,32.5},{-32.5,32.5},{2.5,32.5},{2.5,32.5},{2.5,27.5},{2.5,27.5},{-7.5,27.5},{-30,7.5},{-30,7.5},{-25,-25},{-17.5,-28.75},{-10,-25},{-5,-26.25},{-5,-32.5},{-16.25,-41.25},{-31.25,-43.75},{-40,-33.75},{-45,-5},{-45,-5},{-52.5,-10},{-52.5,-10},{-60,-40},{-60,-40}},
          smooth = Smooth.Bezier),
        Polygon(
          fillColor = {128,128,128},
          pattern = LinePattern.None,
          fillPattern = FillPattern.Solid,
          points = {{87.5,30},{62.5,30},{62.5,30},{55,33.75},{36.25,35},{16.25,25},{7.5,6.25},{11.25,-7.5},{22.5,-12.5},{22.5,-12.5},{6.25,-22.5},{6.25,-35},{16.25,-38.75},{16.25,-38.75},{21.25,-41.25},{21.25,-41.25},{45,-48.75},{47.5,-61.25},{32.5,-70},{12.5,-65},{7.5,-51.25},{21.25,-41.25},{21.25,-41.25},{16.25,-38.75},{16.25,-38.75},{6.25,-41.25},{-6.25,-50},{-3.75,-68.75},{30,-76.25},{65,-62.5},{63.75,-35},{27.5,-26.25},{22.5,-20},{27.5,-15},{27.5,-15},{30,-7.5},{30,-7.5},{27.5,-2.5},{28.75,11.25},{36.25,27.5},{47.5,30},{53.75,22.5},{51.25,8.75},{45,-6.25},{35,-11.25},{30,-7.5},{30,-7.5},{27.5,-15},{27.5,-15},{43.75,-16.25},{65,-6.25},{72.5,10},{70,20},{70,20},{80,20}},
          smooth = Smooth.Bezier)}), Documentation(info="<html>
<p>This package provides predefined types, such as <em>Mass</em>,
<em>Angle</em>, <em>Time</em>, based on the international standard
on units, e.g.,
</p>

<blockquote><pre>
<strong>type</strong> Angle = Real(<strong>final</strong> quantity = \"Angle\",
                  <strong>final</strong> unit     = \"rad\",
                  displayUnit   = \"deg\");
</pre></blockquote>

<p>
Some of the types are derived SI units that are utilized in package Modelica
(such as ComplexCurrent, which is a complex number where both the real and imaginary
part have the SI unit Ampere).
</p>

<p>
Furthermore, conversion functions from non SI-units to SI-units and vice versa
are provided in subpackage
<a href=\"modelica://Modelica.Units.Conversions\">Conversions</a>.
</p>

<p>
For an introduction how units are used in the Modelica Standard Library
with package Units, have a look at:
<a href=\"modelica://Modelica.Units.UsersGuide.HowToUseUnits\">How to use Units</a>.
</p>

<p>
Copyright &copy; 1998-2020, Modelica Association and contributors
</p>
</html>",   revisions="<html>
<ul>
<li><em>May 25, 2011</em> by Stefan Wischhusen:<br>Added molar units for energy and enthalpy.</li>
<li><em>Jan. 27, 2010</em> by Christian Kral:<br>Added complex units.</li>
<li><em>Dec. 14, 2005</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>Add User&#39;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
<li><em>October 21, 2002</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Christian Schweiger:<br>Added new package <strong>Conversions</strong>. Corrected typo <em>Wavelenght</em>.</li>
<li><em>June 6, 2000</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>Introduced the following new types<br>type Temperature = ThermodynamicTemperature;<br>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
<li><em>Oct. 27, 1999</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
<li><em>Sept. 18, 1999</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
<li><em>Aug 12, 1999</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
<li><em>June 29, 1999</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
<li><em>April 8, 1998</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br>Complete ISO 31 chapters realized.</li>
<li><em>Nov. 15, 1997</em> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Hubertus Tummescheit:<br>Some chapters realized.</li>
</ul>
</html>"));
  end Units;
annotation (
preferredView="info",
version="4.0.0",
versionDate="2020-06-04",
dateModified = "2020-06-04 11:00:00Z",
revisionId="6626538a2 2020-06-04 19:56:34 +0200",
conversion(
 from(version={"3.0", "3.0.1", "3.1", "3.2", "3.2.1", "3.2.2", "3.2.3"}, script="modelica://Modelica/Resources/Scripts/Conversion/ConvertModelica_from_3.2.3_to_4.0.0.mos")),
Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}), graphics={
  Polygon(
    origin={-6.9888,20.048},
    pattern=LinePattern.None,
    fillPattern=FillPattern.Solid,
    points={{-93.0112,10.3188},{-93.0112,10.3188},{-73.011,24.6},{-63.011,31.221},{-51.219,36.777},{-39.842,38.629},{-31.376,36.248},{-25.819,29.369},{-24.232,22.49},{-23.703,17.463},{-15.501,25.135},{-6.24,32.015},{3.02,36.777},{15.191,39.423},{27.097,37.306},{32.653,29.633},{35.035,20.108},{43.501,28.046},{54.085,35.19},{65.991,39.952},{77.897,39.688},{87.422,33.338},{91.126,21.696},{90.068,9.525},{86.099,-1.058},{79.749,-10.054},{71.283,-21.431},{62.816,-33.337},{60.964,-32.808},{70.489,-16.14},{77.368,-2.381},{81.072,10.054},{79.749,19.05},{72.605,24.342},{61.758,23.019},{49.587,14.817},{39.003,4.763},{29.214,-6.085},{21.012,-16.669},{13.339,-26.458},{5.401,-36.777},{-1.213,-46.037},{-6.24,-53.446},{-8.092,-52.387},{-0.684,-40.746},{5.401,-30.692},{12.81,-17.198},{19.424,-3.969},{23.658,7.938},{22.335,18.785},{16.514,23.283},{8.047,23.019},{-1.478,19.05},{-11.267,11.113},{-19.734,2.381},{-29.259,-8.202},{-38.519,-19.579},{-48.044,-31.221},{-56.511,-43.392},{-64.449,-55.298},{-72.386,-66.939},{-77.678,-74.612},{-79.53,-74.083},{-71.857,-61.383},{-62.861,-46.037},{-52.278,-28.046},{-44.869,-15.346},{-38.784,-2.117},{-35.344,8.731},{-36.403,19.844},{-42.488,23.813},{-52.013,22.49},{-60.744,16.933},{-68.947,10.054},{-76.884,2.646},{-93.0112,-12.1707},{-93.0112,-12.1707}},
    smooth=Smooth.Bezier),
  Ellipse(
    origin={40.8208,-37.7602},
    fillColor={161,0,4},
    pattern=LinePattern.None,
    fillPattern=FillPattern.Solid,
    extent={{-17.8562,-17.8563},{17.8563,17.8562}})}),
Documentation(info="<html>
<p>
<img src=\"modelica://Modelica/Resources/Images/Logos/Modelica_Libraries.svg\" width=\"250\">
</p>

<p>
The package <strong>Modelica&reg;</strong> is a <strong>standardized</strong> and <strong>free</strong> package
that is developed by the \"<strong>Modelica Association Project - Libraries</strong>\".</p>
<p>
Its development is coordinated with the Modelica&reg; language from the
Modelica Association, see <a href=\"https://www.Modelica.org\">https://www.Modelica.org</a>.
It is also called <strong>Modelica Standard Library</strong>.
It provides model components in many domains that are based on
standardized interface definitions. Some typical examples are shown
in the next figure:
</p>

<p>
<img src=\"modelica://Modelica/Resources/Images/UsersGuide/ModelicaLibraries.png\">
</p>

<p>
For an introduction, have especially a look at:
</p>
<ul>
<li> <a href=\"modelica://Modelica.UsersGuide.Overview\">Overview</a>
  provides an overview of the Modelica Standard Library
  inside the <a href=\"modelica://Modelica.UsersGuide\">User's Guide</a>.</li>
<li><a href=\"modelica://Modelica.UsersGuide.ReleaseNotes\">Release Notes</a>
 summarizes the changes of new versions of this package.</li>
<li> <a href=\"modelica://Modelica.UsersGuide.Contact\">Contact</a>
  lists the contributors of the Modelica Standard Library.</li>
<li> The <strong>Examples</strong> packages in the various libraries, demonstrate
  how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
This version of the Modelica Standard Library consists of
</p>
<ul>
<li><strong>1417</strong> component models and blocks,</li>
<li><strong>512</strong> example models, and</li>
<li><strong>1219</strong> functions</li>
</ul>
<p>
that are directly usable (= number of public, non-partial, non-internal and non-obsolete classes). It is fully compliant
to <a href=\"https://modelica.org/documents/ModelicaSpec34.pdf\">Modelica Specification version 3.4</a>
and it has been tested with Modelica tools from different vendors.
</p>

<p>
<strong>Licensed by the Modelica Association under the 3-Clause BSD License</strong><br>
Copyright &copy; 1998-2020, Modelica Association and <a href=\"modelica://Modelica.UsersGuide.Contact\">contributors</a>.
</p>

<p>
<em>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the 3-Clause BSD license. For license conditions (including the disclaimer of warranty) visit <a href=\"https://modelica.org/licenses/modelica-3-clause-bsd\">https://modelica.org/licenses/modelica-3-clause-bsd</a>.</em>
</p>

<p>
<strong>Modelica&reg;</strong> is a registered trademark of the Modelica Association.
</p>
</html>"));
end Modelica;
model Modelica_Fluid_Examples_HeatExchanger_HeatExchangerSimulation
 extends Modelica.Fluid.Examples.HeatExchanger.HeatExchangerSimulation;
  annotation(experiment(StopTime=200, Tolerance=1e-005),uses(Modelica(version="4.0.0")));
end Modelica_Fluid_Examples_HeatExchanger_HeatExchangerSimulation;
