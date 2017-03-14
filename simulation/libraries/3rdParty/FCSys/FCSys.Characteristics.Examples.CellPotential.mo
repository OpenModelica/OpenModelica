package ModelicaServices  "ModelicaServices (OpenModelica implementation) - Models and functions used in the Modelica Standard Library requiring a tool specific implementation"
  extends Modelica.Icons.Package;

  package Machine
    extends Modelica.Icons.Package;
    final constant Real eps = 1.e-15 "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = 1.e-60 "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = 1.e+60 "Biggest Real number such that inf and -inf are representable on the machine";
    final constant Integer Integer_inf = OpenModelica.Internal.Architecture.integerMax() "Biggest Integer number such that Integer_inf and -Integer_inf are representable on the machine";
    annotation(Documentation(info = "<html>
  <p>
  Package in which processor specific constants are defined that are needed
  by numerical algorithms. Typically these constants are not directly used,
  but indirectly via the alias definition in
  <a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.
  </p>
  </html>"));
  end Machine;
  annotation(Protection(access = Access.hide), preferredView = "info", version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z", revisionId = "$Id::                                       $", uses(Modelica(version = "3.2.1")), conversion(noneFromVersion = "1.0", noneFromVersion = "1.1", noneFromVersion = "1.2"), Documentation(info = "<html>
<p>
This package contains a set of functions and models to be used in the
Modelica Standard Library that requires a tool specific implementation.
These are:
</p>

<ul>
<li> <a href=\"modelica://ModelicaServices.Animation.Shape\">Shape</a>
     provides a 3-dim. visualization of elementary
     mechanical objects. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Shape</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Animation.Surface\">Surface</a>
     provides a 3-dim. visualization of
     moveable parameterized surface. It is used in
<a href=\"modelica://Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface\">Modelica.Mechanics.MultiBody.Visualizers.Advanced.Surface</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.ExternalReferences.loadResource\">loadResource</a>
     provides a function to return the absolute path name of an URI or a local file name. It is used in
<a href=\"modelica://Modelica.Utilities.Files.loadResource\">Modelica.Utilities.Files.loadResource</a>
     via inheritance.</li>

<li> <a href=\"modelica://ModelicaServices.Machine\">ModelicaServices.Machine</a>
     provides a package of machine constants. It is used in
<a href=\"modelica://Modelica.Constants\">Modelica.Constants</a>.</li>

<li> <a href=\"modelica://ModelicaServices.Types.SolverMethod\">Types.SolverMethod</a>
     provides a string defining the integration method to solve differential equations in
     a clocked discretized continuous-time partition (see Modelica 3.3 language specification).
     It is not yet used in the Modelica Standard Library, but in the Modelica_Synchronous library
     that provides convenience blocks for the clock operators of Modelica version &ge; 3.3.</li>
</ul>

<p>
This is the default implementation, if no tool-specific implementation is available.
This ModelicaServices package provides only \"dummy\" models that do nothing.
</p>

<p>
<b>Licensed by DLR and Dassault Syst&egrave;mes AB under the Modelica License 2</b><br>
Copyright &copy; 2009-2015, DLR and Dassault Syst&egrave;mes AB.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

</html>"));
end ModelicaServices;

package Modelica  "Modelica Standard Library - Version 3.2.1 (Build 4)"
  extends Modelica.Icons.Package;

  package Blocks  "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    extends Modelica.Icons.Package;

    package Interfaces  "Library of connectors and partial models for input/output blocks"
      extends Modelica.Icons.InterfacesPackage;
      connector RealOutput = output Real "'output Real' as connector" annotation(defaultComponentName = "y", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 100.0}, {100.0, 0.0}, {-100.0, -100.0}})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 50.0}, {0.0, 0.0}, {-100.0, -50.0}}), Text(lineColor = {0, 0, 127}, extent = {{30.0, 60.0}, {30.0, 110.0}}, textString = "%name")}), Documentation(info = "<html>
      <p>
      Connector with one output signal of type Real.
      </p>
      </html>"));

      partial block SO  "Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealOutput y "Connector of Real output signal" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}}, rotation = 0)));
        annotation(Documentation(info = "<html>
      <p>
      Block has one continuous Real output signal.
      </p>
      </html>"));
      end SO;
      annotation(Documentation(info = "<HTML>
    <p>
    This package contains interface definitions for
    <b>continuous</b> input/output blocks with Real,
    Integer and Boolean signals. Furthermore, it contains
    partial models for continuous and discrete blocks.
    </p>

    </html>", revisions = "<html>
    <ul>
    <li><i>Oct. 21, 2002</i>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
           and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
           Added several new interfaces.
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
    </html>"));
    end Interfaces;

    package Sources  "Library of signal source blocks generating Real and Boolean signals"
      extends Modelica.Icons.SourcesPackage;

      block Ramp  "Generate ramp signal"
        parameter Real height = 1 "Height of ramps";
        parameter Modelica.SIunits.Time duration(min = 0.0, start = 2) "Duration of ramp (= 0.0 gives a Step)";
        parameter Real offset = 0 "Offset of output signal";
        parameter Modelica.SIunits.Time startTime = 0 "Output = offset for time < startTime";
        extends .Modelica.Blocks.Interfaces.SO;
      equation
        y = offset + (if time < startTime then 0 else if time < startTime + duration then (time - startTime) * height / duration else height);
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 68}, {-80, -80}}, color = {192, 192, 192}), Polygon(points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-90, -70}, {82, -70}}, color = {192, 192, 192}), Polygon(points = {{90, -70}, {68, -62}, {68, -78}, {90, -70}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -70}, {-40, -70}, {31, 38}}, color = {0, 0, 0}), Text(extent = {{-150, -150}, {150, -110}}, lineColor = {0, 0, 0}, textString = "duration=%duration"), Line(points = {{31, 38}, {86, 38}}, color = {0, 0, 0})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-80, 90}, {-86, 68}, {-74, 68}, {-80, 90}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 68}, {-80, -80}}, color = {95, 95, 95}), Line(points = {{-80, -20}, {-20, -20}, {50, 50}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-90, -70}, {82, -70}}, color = {95, 95, 95}), Polygon(points = {{90, -70}, {68, -64}, {68, -76}, {90, -70}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Polygon(points = {{-40, -20}, {-42, -30}, {-38, -30}, {-40, -20}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-40, -20}, {-40, -70}}, color = {95, 95, 95}, thickness = 0.25, arrow = {Arrow.None, Arrow.None}), Polygon(points = {{-40, -70}, {-42, -60}, {-38, -60}, {-40, -70}, {-40, -70}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Text(extent = {{-72, -39}, {-34, -50}}, lineColor = {0, 0, 0}, textString = "offset"), Text(extent = {{-38, -72}, {6, -83}}, lineColor = {0, 0, 0}, textString = "startTime"), Text(extent = {{-78, 92}, {-37, 72}}, lineColor = {0, 0, 0}, textString = "y"), Text(extent = {{70, -80}, {94, -91}}, lineColor = {0, 0, 0}, textString = "time"), Line(points = {{-20, -20}, {-20, -70}}, color = {95, 95, 95}), Line(points = {{-19, -20}, {50, -20}}, color = {95, 95, 95}, thickness = 0.25, arrow = {Arrow.None, Arrow.None}), Line(points = {{50, 50}, {101, 50}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{50, 50}, {50, -20}}, color = {95, 95, 95}, thickness = 0.25, arrow = {Arrow.None, Arrow.None}), Polygon(points = {{50, -20}, {42, -18}, {42, -22}, {50, -20}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Polygon(points = {{-20, -20}, {-11, -18}, {-11, -22}, {-20, -20}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Polygon(points = {{50, 50}, {48, 40}, {52, 40}, {50, 50}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Polygon(points = {{50, -20}, {48, -10}, {52, -10}, {50, -20}, {50, -20}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Text(extent = {{53, 23}, {82, 10}}, lineColor = {0, 0, 0}, textString = "height"), Text(extent = {{-2, -21}, {37, -33}}, lineColor = {0, 0, 0}, textString = "duration")}), Documentation(info = "<html>
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
      annotation(Documentation(info = "<HTML>
    <p>
    This package contains <b>source</b> components, i.e., blocks which
    have only output signals. These blocks are used as signal generators
    for Real, Integer and Boolean signals.
    </p>

    <p>
    All Real source signals (with the exception of the Constant source)
    have at least the following two parameters:
    </p>

    <table border=1 cellspacing=0 cellpadding=2>
      <tr><td valign=\"top\"><b>offset</b></td>
          <td valign=\"top\">Value which is added to the signal</td>
      </tr>
      <tr><td valign=\"top\"><b>startTime</b></td>
          <td valign=\"top\">Start time of signal. For time &lt; startTime,
                    the output y is set to offset.</td>
      </tr>
    </table>

    <p>
    The <b>offset</b> parameter is especially useful in order to shift
    the corresponding source, such that at initial time the system
    is stationary. To determine the corresponding value of offset,
    usually requires a trimming calculation.
    </p>
    </html>", revisions = "<html>
    <ul>
    <li><i>October 21, 2002</i>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
           and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
           Integer sources added. Step, TimeTable and BooleanStep slightly changed.</li>
    <li><i>Nov. 8, 1999</i>
           by <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
           <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
           <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           New sources: Exponentials, TimeTable. Trapezoid slightly enhanced
           (nperiod=-1 is an infinite number of periods).</li>
    <li><i>Oct. 31, 1999</i>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           <a href=\"mailto:clauss@eas.iis.fhg.de\">Christoph Clau&szlig;</a>,
           <a href=\"mailto:Andre.Schneider@eas.iis.fraunhofer.de\">Andre.Schneider@eas.iis.fraunhofer.de</a>,
           All sources vectorized. New sources: ExpSine, Trapezoid,
           BooleanConstant, BooleanStep, BooleanPulse, SampleTrigger.
           Improved documentation, especially detailed description of
           signals in diagram layer.</li>
    <li><i>June 29, 1999</i>
           by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
           Realized a first version, based on an existing Dymola library
           of Dieter Moormann and Hilding Elmqvist.</li>
    </ul>
    </html>"));
    end Sources;

    package Icons  "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block  "Basic graphical layout of input/output block"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, -100}, {100, 100}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<html>
      <p>
      Block that has only the basic icon for an input/output
      block (no declarations, no equations). Most blocks
      of package Modelica.Blocks inherit directly or indirectly
      from this block.
      </p>
      </html>")); end Block;
    end Icons;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Rectangle(origin = {0.0, 35.1488}, fillColor = {255, 255, 255}, extent = {{-30.0, -20.1488}, {30.0, 20.1488}}), Rectangle(origin = {0.0, -34.8512}, fillColor = {255, 255, 255}, extent = {{-30.0, -20.1488}, {30.0, 20.1488}}), Line(origin = {-51.25, 0.0}, points = {{21.25, -35.0}, {-13.75, -35.0}, {-13.75, 35.0}, {6.25, 35.0}}), Polygon(origin = {-40.0, 35.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{10.0, 0.0}, {-5.0, 5.0}, {-5.0, -5.0}}), Line(origin = {51.25, 0.0}, points = {{-21.25, 35.0}, {13.75, 35.0}, {13.75, -35.0}, {-6.25, -35.0}}), Polygon(origin = {40.0, -35.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.0, 0.0}, {5.0, 5.0}, {5.0, -5.0}})}), Documentation(info = "<html>
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
  Copyright &copy; 1998-2015, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>June 23, 2004</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Introduced new block connectors and adapted all blocks to the new connectors.
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
  end Blocks;

  package Media  "Library of media property models"
    extends Modelica.Icons.Package;

    package Interfaces  "Interfaces for media models"
      extends Modelica.Icons.InterfacesPackage;

      partial package PartialMedium  "Partial medium properties (base package of all media packages)"
        extends Modelica.Media.Interfaces.Types;
        extends Modelica.Icons.MaterialPropertiesPackage;
        constant Modelica.Media.Interfaces.Choices.IndependentVariables ThermoStates "Enumeration type for independent variables";
        constant String mediumName = "unusablePartialMedium" "Name of the medium";
        constant String[:] substanceNames = {mediumName} "Names of the mixture substances. Set substanceNames={mediumName} if only one substance.";
        constant String[:] extraPropertiesNames = fill("", 0) "Names of the additional (extra) transported properties. Set extraPropertiesNames=fill(\"\",0) if unused";
        constant Boolean singleState "= true, if u and d are not a function of pressure";
        constant Boolean reducedX = true "= true if medium contains the equation sum(X) = 1.0; set reducedX=true if only one substance (see docu for details)";
        constant Boolean fixedX = false "= true if medium contains the equation X = reference_X";
        constant AbsolutePressure reference_p = 101325 "Reference pressure of Medium: default 1 atmosphere";
        constant MassFraction[nX] reference_X = fill(1 / nX, nX) "Default mass fractions of medium";
        constant AbsolutePressure p_default = 101325 "Default value for pressure of medium (for initialization)";
        constant Temperature T_default = Modelica.SIunits.Conversions.from_degC(20) "Default value for temperature of medium (for initialization)";
        constant MassFraction[nX] X_default = reference_X "Default value for mass fractions of medium (for initialization)";
        final constant Integer nS = size(substanceNames, 1) "Number of substances" annotation(Evaluate = true);
        constant Integer nX = nS "Number of mass fractions" annotation(Evaluate = true);
        constant Integer nXi = if fixedX then 0 else if reducedX then nS - 1 else nS "Number of structurally independent mass fractions (see docu for details)" annotation(Evaluate = true);
        final constant Integer nC = size(extraPropertiesNames, 1) "Number of extra (outside of standard mass-balance) transported properties" annotation(Evaluate = true);
        replaceable record FluidConstants = Modelica.Media.Interfaces.Types.Basic.FluidConstants "Critical, triple, molecular and other standard data of fluid";

        replaceable record ThermodynamicState  "Minimal variable set that is available as input argument to every medium function"
          extends Modelica.Icons.Record;
        end ThermodynamicState;

        replaceable partial model BaseProperties  "Base properties (p, d, T, h, u, R, MM and, if applicable, X and Xi) of a medium"
          InputAbsolutePressure p "Absolute pressure of medium";
          InputMassFraction[nXi] Xi(start = reference_X[1:nXi]) "Structurally independent mass fractions";
          InputSpecificEnthalpy h "Specific enthalpy of medium";
          Density d "Density of medium";
          Temperature T "Temperature of medium";
          MassFraction[nX] X(start = reference_X) "Mass fractions (= (component mass)/total mass  m_i/m)";
          SpecificInternalEnergy u "Specific internal energy of medium";
          SpecificHeatCapacity R "Gas constant (of mixture if applicable)";
          MolarMass MM "Molar mass (of mixture or single fluid)";
          ThermodynamicState state "Thermodynamic state record for optional functions";
          parameter Boolean preferredMediumStates = false "= true if StateSelect.prefer shall be used for the independent property variables of the medium" annotation(Evaluate = true, Dialog(tab = "Advanced"));
          parameter Boolean standardOrderComponents = true "If true, and reducedX = true, the last element of X will be computed from the other ones";
          .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_degC = Modelica.SIunits.Conversions.to_degC(T) "Temperature of medium in [degC]";
          .Modelica.SIunits.Conversions.NonSIunits.Pressure_bar p_bar = Modelica.SIunits.Conversions.to_bar(p) "Absolute pressure of medium in [bar]";
          connector InputAbsolutePressure = input .Modelica.SIunits.AbsolutePressure "Pressure as input signal connector";
          connector InputSpecificEnthalpy = input .Modelica.SIunits.SpecificEnthalpy "Specific enthalpy as input signal connector";
          connector InputMassFraction = input .Modelica.SIunits.MassFraction "Mass fraction as input signal connector";
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
              assert(X[i] >= (-1.e-5) and X[i] <= 1 + 1.e-5, "Mass fraction X[" + String(i) + "] = " + String(X[i]) + "of substance " + substanceNames[i] + "\nof medium " + mediumName + " is not in the range 0..1");
            end for;
          end if;
          assert(p >= 0.0, "Pressure (= " + String(p) + " Pa) of medium \"" + mediumName + "\" is negative\n(Temperature = " + String(T) + " K)");
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 255}), Text(extent = {{-152, 164}, {152, 102}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<html>
        <p>
        Model <b>BaseProperties</b> is a model within package <b>PartialMedium</b>
        and contains the <b>declarations</b> of the minimum number of
        variables that every medium model is supposed to support.
        A specific medium inherits from model <b>BaseProperties</b> and provides
        the equations for the basic properties.</p>
        <p>
        The BaseProperties model contains the following <b>7+nXi variables</b>
        (nXi is the number of independent mass fractions defined in package
        PartialMedium):
        </p>
        <table border=1 cellspacing=0 cellpadding=2>
          <tr><td valign=\"top\"><b>Variable</b></td>
              <td valign=\"top\"><b>Unit</b></td>
              <td valign=\"top\"><b>Description</b></td></tr>
          <tr><td valign=\"top\">T</td>
              <td valign=\"top\">K</td>
              <td valign=\"top\">temperature</td></tr>
          <tr><td valign=\"top\">p</td>
              <td valign=\"top\">Pa</td>
              <td valign=\"top\">absolute pressure</td></tr>
          <tr><td valign=\"top\">d</td>
              <td valign=\"top\">kg/m3</td>
              <td valign=\"top\">density</td></tr>
          <tr><td valign=\"top\">h</td>
              <td valign=\"top\">J/kg</td>
              <td valign=\"top\">specific enthalpy</td></tr>
          <tr><td valign=\"top\">u</td>
              <td valign=\"top\">J/kg</td>
              <td valign=\"top\">specific internal energy</td></tr>
          <tr><td valign=\"top\">Xi[nXi]</td>
              <td valign=\"top\">kg/kg</td>
              <td valign=\"top\">independent mass fractions m_i/m</td></tr>
          <tr><td valign=\"top\">R</td>
              <td valign=\"top\">J/kg.K</td>
              <td valign=\"top\">gas constant</td></tr>
          <tr><td valign=\"top\">M</td>
              <td valign=\"top\">kg/mol</td>
              <td valign=\"top\">molar mass</td></tr>
        </table>
        <p>
        In order to implement an actual medium model, one can extend from this
        base model and add <b>5 equations</b> that provide relations among
        these variables. Equations will also have to be added in order to
        set all the variables within the ThermodynamicState record state.</p>
        <p>
        If standardOrderComponents=true, the full composition vector X[nX]
        is determined by the equations contained in this base class, depending
        on the independent mass fraction vector Xi[nXi].</p>
        <p>Additional <b>2 + nXi</b> equations will have to be provided
        when using the BaseProperties model, in order to fully specify the
        thermodynamic conditions. The input connector qualifier applied to
        p, h, and nXi indirectly declares the number of missing equations,
        permitting advanced equation balance checking by Modelica tools.
        Please note that this doesn't mean that the additional equations
        should be connection equations, nor that exactly those variables
        should be supplied, in order to complete the model.
        For further information, see the Modelica.Media User's guide, and
        Section 4.7 (Balanced Models) of the Modelica 3.0 specification.</p>
        </html>"));
        end BaseProperties;

        replaceable partial function setState_pTX  "Return thermodynamic state as function of p, T and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_pTX;

        replaceable partial function setState_phX  "Return thermodynamic state as function of p, h and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_phX;

        replaceable partial function setState_psX  "Return thermodynamic state as function of p, s and composition X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_psX;

        replaceable partial function setState_dTX  "Return thermodynamic state as function of d, T and composition X or Xi"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state record";
        end setState_dTX;

        replaceable partial function setSmoothState  "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
          extends Modelica.Icons.Function;
          input Real x "m_flow or dp";
          input ThermodynamicState state_a "Thermodynamic state if x > 0";
          input ThermodynamicState state_b "Thermodynamic state if x < 0";
          input Real x_small(min = 0) "Smooth transition in the region -x_small < x < x_small";
          output ThermodynamicState state "Smooth thermodynamic state for all x (continuous and differentiable)";
          annotation(Documentation(info = "<html>
        <p>
        This function is used to approximate the equation
        </p>
        <pre>
            state = <b>if</b> x &gt; 0 <b>then</b> state_a <b>else</b> state_b;
        </pre>

        <p>
        by a smooth characteristic, so that the expression is continuous and differentiable:
        </p>

        <pre>
           state := <b>smooth</b>(1, <b>if</b> x &gt;  x_small <b>then</b> state_a <b>else</b>
                              <b>if</b> x &lt; -x_small <b>then</b> state_b <b>else</b> f(state_a, state_b));
        </pre>

        <p>
        This is performed by applying function <b>Media.Common.smoothStep</b>(..)
        on every element of the thermodynamic state record.
        </p>

        <p>
        If <b>mass fractions</b> X[:] are approximated with this function then this can be performed
        for all <b>nX</b> mass fractions, instead of applying it for nX-1 mass fractions and computing
        the last one by the mass fraction constraint sum(X)=1. The reason is that the approximating function has the
        property that sum(state.X) = 1, provided sum(state_a.X) = sum(state_b.X) = 1.
        This can be shown by evaluating the approximating function in the abs(x) &lt; x_small
        region (otherwise state.X is either state_a.X or state_b.X):
        </p>

        <pre>
            X[1]  = smoothStep(x, X_a[1] , X_b[1] , x_small);
            X[2]  = smoothStep(x, X_a[2] , X_b[2] , x_small);
               ...
            X[nX] = smoothStep(x, X_a[nX], X_b[nX], x_small);
        </pre>

        <p>
        or
        </p>

        <pre>
            X[1]  = c*(X_a[1]  - X_b[1])  + (X_a[1]  + X_b[1])/2
            X[2]  = c*(X_a[2]  - X_b[2])  + (X_a[2]  + X_b[2])/2;
               ...
            X[nX] = c*(X_a[nX] - X_b[nX]) + (X_a[nX] + X_b[nX])/2;
            c     = (x/x_small)*((x/x_small)^2 - 3)/4
        </pre>

        <p>
        Summing all mass fractions together results in
        </p>

        <pre>
            sum(X) = c*(sum(X_a) - sum(X_b)) + (sum(X_a) + sum(X_b))/2
                   = c*(1 - 1) + (1 + 1)/2
                   = 1
        </pre>

        </html>"));
        end setSmoothState;

        replaceable partial function dynamicViscosity  "Return dynamic viscosity"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DynamicViscosity eta "Dynamic viscosity";
        end dynamicViscosity;

        replaceable partial function thermalConductivity  "Return thermal conductivity"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output ThermalConductivity lambda "Thermal conductivity";
        end thermalConductivity;

        replaceable partial function pressure  "Return pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output AbsolutePressure p "Pressure";
        end pressure;

        replaceable partial function temperature  "Return temperature"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Temperature T "Temperature";
        end temperature;

        replaceable partial function density  "Return density"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Density d "Density";
        end density;

        replaceable partial function specificEnthalpy  "Return specific enthalpy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnthalpy h "Specific enthalpy";
        end specificEnthalpy;

        replaceable partial function specificInternalEnergy  "Return specific internal energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy u "Specific internal energy";
        end specificInternalEnergy;

        replaceable partial function specificEntropy  "Return specific entropy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEntropy s "Specific entropy";
        end specificEntropy;

        replaceable partial function specificGibbsEnergy  "Return specific Gibbs energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy g "Specific Gibbs energy";
        end specificGibbsEnergy;

        replaceable partial function specificHelmholtzEnergy  "Return specific Helmholtz energy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificEnergy f "Specific Helmholtz energy";
        end specificHelmholtzEnergy;

        replaceable partial function specificHeatCapacityCp  "Return specific heat capacity at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cp "Specific heat capacity at constant pressure";
        end specificHeatCapacityCp;

        replaceable partial function specificHeatCapacityCv  "Return specific heat capacity at constant volume"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output SpecificHeatCapacity cv "Specific heat capacity at constant volume";
        end specificHeatCapacityCv;

        replaceable partial function isentropicExponent  "Return isentropic exponent"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output IsentropicExponent gamma "Isentropic exponent";
        end isentropicExponent;

        replaceable partial function isentropicEnthalpy  "Return isentropic enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p_downstream "Downstream pressure";
          input ThermodynamicState refState "Reference state for entropy";
          output SpecificEnthalpy h_is "Isentropic enthalpy";
          annotation(Documentation(info = "<html>
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

        replaceable partial function velocityOfSound  "Return velocity of sound"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output VelocityOfSound a "Velocity of sound";
        end velocityOfSound;

        replaceable partial function isobaricExpansionCoefficient  "Return overall the isobaric expansion coefficient beta"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output IsobaricExpansionCoefficient beta "Isobaric expansion coefficient";
          annotation(Documentation(info = "<html>
        <pre>
        beta is defined as  1/v * der(v,T), with v = 1/d, at constant pressure p.
        </pre>
        </html>"));
        end isobaricExpansionCoefficient;

        replaceable partial function isothermalCompressibility  "Return overall the isothermal compressibility factor"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output .Modelica.SIunits.IsothermalCompressibility kappa "Isothermal compressibility";
          annotation(Documentation(info = "<html>
        <pre>

        kappa is defined as - 1/v * der(v,p), with v = 1/d at constant temperature T.

        </pre>
        </html>"));
        end isothermalCompressibility;

        replaceable partial function density_derp_h  "Return density derivative w.r.t. pressure at const specific enthalpy"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByPressure ddph "Density derivative w.r.t. pressure";
        end density_derp_h;

        replaceable partial function density_derh_p  "Return density derivative w.r.t. specific enthalpy at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByEnthalpy ddhp "Density derivative w.r.t. specific enthalpy";
        end density_derh_p;

        replaceable partial function density_derp_T  "Return density derivative w.r.t. pressure at const temperature"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByPressure ddpT "Density derivative w.r.t. pressure";
        end density_derp_T;

        replaceable partial function density_derT_p  "Return density derivative w.r.t. temperature at constant pressure"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output DerDensityByTemperature ddTp "Density derivative w.r.t. temperature";
        end density_derT_p;

        replaceable partial function density_derX  "Return density derivative w.r.t. mass fraction"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output Density[nX] dddX "Derivative of density w.r.t. mass fraction";
        end density_derX;

        replaceable partial function molarMass  "Return the molar mass of the medium"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state record";
          output MolarMass MM "Mixture molar mass";
        end molarMass;

        replaceable function specificEnthalpy_pTX  "Return specific enthalpy from p, T, and X or Xi"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output SpecificEnthalpy h "Specific enthalpy";
        algorithm
          h := specificEnthalpy(setState_pTX(p, T, X));
          annotation(inverse(T = temperature_phX(p, h, X)));
        end specificEnthalpy_pTX;
        annotation(Documentation(info = "<html>
      <p>
      <b>PartialMedium</b> is a package and contains all <b>declarations</b> for
      a medium. This means that constants, models, and functions
      are defined that every medium is supposed to support
      (some of them are optional). A medium package
      inherits from <b>PartialMedium</b> and provides the
      equations for the medium. The details of this package
      are described in
      <a href=\"modelica://Modelica.Media.UsersGuide\">Modelica.Media.UsersGuide</a>.
      </p>
      </html>", revisions = "<html>

      </html>"));
      end PartialMedium;

      partial package PartialMixtureMedium  "Base class for pure substances of several chemical substances"
        extends PartialMedium(redeclare replaceable record FluidConstants = Modelica.Media.Interfaces.Types.IdealGas.FluidConstants);

        redeclare replaceable record extends ThermodynamicState  "Thermodynamic state variables"
          AbsolutePressure p "Absolute pressure of medium";
          Temperature T "Temperature of medium";
          MassFraction[nX] X "Mass fractions (= (component mass)/total mass  m_i/m)";
        end ThermodynamicState;

        constant FluidConstants[nS] fluidConstants "Constant data for the fluid";

        replaceable function gasConstant  "Return the gas constant of the mixture (also for liquids)"
          extends Modelica.Icons.Function;
          input ThermodynamicState state "Thermodynamic state";
          output .Modelica.SIunits.SpecificHeatCapacity R "Mixture gas constant";
        end gasConstant;

        function massToMoleFractions  "Return mole fractions from mass fractions X"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.MassFraction[:] X "Mass fractions of mixture";
          input .Modelica.SIunits.MolarMass[:] MMX "Molar masses of components";
          output .Modelica.SIunits.MoleFraction[size(X, 1)] moleFractions "Mole fractions of gas mixture";
        protected
          Real[size(X, 1)] invMMX "Inverses of molar weights";
          .Modelica.SIunits.MolarMass Mmix "Molar mass of mixture";
        algorithm
          for i in 1:size(X, 1) loop
            invMMX[i] := 1 / MMX[i];
          end for;
          Mmix := 1 / (X * invMMX);
          for i in 1:size(X, 1) loop
            moleFractions[i] := Mmix * X[i] / MMX[i];
          end for;
          annotation(smoothOrder = 5);
        end massToMoleFractions;
      end PartialMixtureMedium;

      partial package PartialCondensingGases  "Base class for mixtures of condensing and non-condensing gases"
        extends PartialMixtureMedium(ThermoStates = Choices.IndependentVariables.pTX);

        replaceable partial function saturationPressure  "Return saturation pressure of condensing fluid"
          extends Modelica.Icons.Function;
          input Temperature Tsat "Saturation temperature";
          output AbsolutePressure psat "Saturation pressure";
        end saturationPressure;

        replaceable partial function enthalpyOfVaporization  "Return vaporization enthalpy of condensing fluid"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output SpecificEnthalpy r0 "Vaporization enthalpy";
        end enthalpyOfVaporization;

        replaceable partial function enthalpyOfLiquid  "Return liquid enthalpy of condensing fluid"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output SpecificEnthalpy h "Liquid enthalpy";
        end enthalpyOfLiquid;

        replaceable partial function enthalpyOfGas  "Return enthalpy of non-condensing gas mixture"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          input MassFraction[:] X "Vector of mass fractions";
          output SpecificEnthalpy h "Specific enthalpy";
        end enthalpyOfGas;

        replaceable partial function enthalpyOfCondensingGas  "Return enthalpy of condensing gas (most often steam)"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output SpecificEnthalpy h "Specific enthalpy";
        end enthalpyOfCondensingGas;

        replaceable partial function enthalpyOfNonCondensingGas  "Return enthalpy of the non-condensing species"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output SpecificEnthalpy h "Specific enthalpy";
        end enthalpyOfNonCondensingGas;
      end PartialCondensingGases;

      package Choices  "Types, constants to define menu choices"
        extends Modelica.Icons.Package;
        type IndependentVariables = enumeration(T "Temperature", pT "Pressure, Temperature", ph "Pressure, Specific Enthalpy", phX "Pressure, Specific Enthalpy, Mass Fraction", pTX "Pressure, Temperature, Mass Fractions", dTX "Density, Temperature, Mass Fractions") "Enumeration defining the independent variables of a medium";
        type ReferenceEnthalpy = enumeration(ZeroAt0K "The enthalpy is 0 at 0 K (default), if the enthalpy of formation is excluded", ZeroAt25C "The enthalpy is 0 at 25 degC, if the enthalpy of formation is excluded", UserDefined "The user-defined reference enthalpy is used at 293.15 K (25 degC)") "Enumeration defining the reference enthalpy of a medium" annotation(Evaluate = true);
        annotation(Documentation(info = "<html>
      <p>
      Enumerations and data types for all types of fluids
      </p>

      <p>
      Note: Reference enthalpy might have to be extended with enthalpy of formation.
      </p>
      </html>"));
      end Choices;

      package Types  "Types to be used in fluid models"
        extends Modelica.Icons.Package;
        type AbsolutePressure = .Modelica.SIunits.AbsolutePressure(min = 0, max = 1.e8, nominal = 1.e5, start = 1.e5) "Type for absolute pressure with medium specific attributes";
        type Density = .Modelica.SIunits.Density(min = 0, max = 1.e5, nominal = 1, start = 1) "Type for density with medium specific attributes";
        type DynamicViscosity = .Modelica.SIunits.DynamicViscosity(min = 0, max = 1.e8, nominal = 1.e-3, start = 1.e-3) "Type for dynamic viscosity with medium specific attributes";
        type MassFraction = Real(quantity = "MassFraction", final unit = "kg/kg", min = 0, max = 1, nominal = 0.1) "Type for mass fraction with medium specific attributes";
        type MoleFraction = Real(quantity = "MoleFraction", final unit = "mol/mol", min = 0, max = 1, nominal = 0.1) "Type for mole fraction with medium specific attributes";
        type MolarMass = .Modelica.SIunits.MolarMass(min = 0.001, max = 0.25, nominal = 0.032) "Type for molar mass with medium specific attributes";
        type MolarVolume = .Modelica.SIunits.MolarVolume(min = 1e-6, max = 1.0e6, nominal = 1.0) "Type for molar volume with medium specific attributes";
        type IsentropicExponent = .Modelica.SIunits.RatioOfSpecificHeatCapacities(min = 1, max = 500000, nominal = 1.2, start = 1.2) "Type for isentropic exponent with medium specific attributes";
        type SpecificEnergy = .Modelica.SIunits.SpecificEnergy(min = -1.0e8, max = 1.e8, nominal = 1.e6) "Type for specific energy with medium specific attributes";
        type SpecificInternalEnergy = SpecificEnergy "Type for specific internal energy with medium specific attributes";
        type SpecificEnthalpy = .Modelica.SIunits.SpecificEnthalpy(min = -1.0e10, max = 1.e10, nominal = 1.e6) "Type for specific enthalpy with medium specific attributes";
        type SpecificEntropy = .Modelica.SIunits.SpecificEntropy(min = -1.e7, max = 1.e7, nominal = 1.e3) "Type for specific entropy with medium specific attributes";
        type SpecificHeatCapacity = .Modelica.SIunits.SpecificHeatCapacity(min = 0, max = 1.e7, nominal = 1.e3, start = 1.e3) "Type for specific heat capacity with medium specific attributes";
        type Temperature = .Modelica.SIunits.Temperature(min = 1, max = 1.e4, nominal = 300, start = 300) "Type for temperature with medium specific attributes";
        type ThermalConductivity = .Modelica.SIunits.ThermalConductivity(min = 0, max = 500, nominal = 1, start = 1) "Type for thermal conductivity with medium specific attributes";
        type VelocityOfSound = .Modelica.SIunits.Velocity(min = 0, max = 1.e5, nominal = 1000, start = 1000) "Type for velocity of sound with medium specific attributes";
        type IsobaricExpansionCoefficient = Real(min = 0, max = 1.0e8, unit = "1/K") "Type for isobaric expansion coefficient with medium specific attributes";
        type DipoleMoment = Real(min = 0.0, max = 2.0, unit = "debye", quantity = "ElectricDipoleMoment") "Type for dipole moment with medium specific attributes";
        type DerDensityByPressure = .Modelica.SIunits.DerDensityByPressure "Type for partial derivative of density with respect to pressure with medium specific attributes";
        type DerDensityByEnthalpy = .Modelica.SIunits.DerDensityByEnthalpy "Type for partial derivative of density with respect to enthalpy with medium specific attributes";
        type DerDensityByTemperature = .Modelica.SIunits.DerDensityByTemperature "Type for partial derivative of density with respect to temperature with medium specific attributes";

        package Basic  "The most basic version of a record used in several degrees of detail"
          extends Icons.Package;

          record FluidConstants  "Critical, triple, molecular and other standard data of fluid"
            extends Modelica.Icons.Record;
            String iupacName "Complete IUPAC name (or common name, if non-existent)";
            String casRegistryNumber "Chemical abstracts sequencing number (if it exists)";
            String chemicalFormula "Chemical formula, (brutto, nomenclature according to Hill";
            String structureFormula "Chemical structure formula";
            MolarMass molarMass "Molar mass";
          end FluidConstants;
        end Basic;

        package IdealGas  "The ideal gas version of a record used in several degrees of detail"
          extends Icons.Package;

          record FluidConstants  "Extended fluid constants"
            extends Modelica.Media.Interfaces.Types.Basic.FluidConstants;
            Temperature criticalTemperature "Critical temperature";
            AbsolutePressure criticalPressure "Critical pressure";
            MolarVolume criticalMolarVolume "Critical molar Volume";
            Real acentricFactor "Pitzer acentric factor";
            Temperature meltingPoint "Melting point at 101325 Pa";
            Temperature normalBoilingPoint "Normal boiling point (at 101325 Pa)";
            DipoleMoment dipoleMoment "Dipole moment of molecule in Debye (1 debye = 3.33564e10-30 C.m)";
            Boolean hasIdealGasHeatCapacity = false "True if ideal gas heat capacity is available";
            Boolean hasCriticalData = false "True if critical data are known";
            Boolean hasDipoleMoment = false "True if a dipole moment known";
            Boolean hasFundamentalEquation = false "True if a fundamental equation";
            Boolean hasLiquidHeatCapacity = false "True if liquid heat capacity is available";
            Boolean hasSolidHeatCapacity = false "True if solid heat capacity is available";
            Boolean hasAccurateViscosityData = false "True if accurate data for a viscosity function is available";
            Boolean hasAccurateConductivityData = false "True if accurate data for thermal conductivity is available";
            Boolean hasVapourPressureCurve = false "True if vapour pressure data, e.g., Antoine coefficents are known";
            Boolean hasAcentricFactor = false "True if Pitzer accentric factor is known";
            SpecificEnthalpy HCRIT0 = 0.0 "Critical specific enthalpy of the fundamental equation";
            SpecificEntropy SCRIT0 = 0.0 "Critical specific entropy of the fundamental equation";
            SpecificEnthalpy deltah = 0.0 "Difference between specific enthalpy model (h_m) and f.eq. (h_f) (h_m - h_f)";
            SpecificEntropy deltas = 0.0 "Difference between specific enthalpy model (s_m) and f.eq. (s_f) (s_m - s_f)";
          end FluidConstants;
        end IdealGas;
      end Types;
      annotation(Documentation(info = "<HTML>
    <p>
    This package provides basic interfaces definitions of media models for different
    kind of media.
    </p>
    </HTML>"));
    end Interfaces;

    package Common  "Data structures and fundamental functions for fluid properties"
      extends Modelica.Icons.Package;
      constant Real MINPOS = 1.0e-9 "Minimal value for physical variables which are always > 0.0";

      function smoothStep  "Approximation of a general step, such that the characteristic is continuous and differentiable"
        extends Modelica.Icons.Function;
        input Real x "Abscissa value";
        input Real y1 "Ordinate value for x > 0";
        input Real y2 "Ordinate value for x < 0";
        input Real x_small(min = 0) = 1e-5 "Approximation of step for -x_small <= x <= x_small; x_small > 0 required";
        output Real y "Ordinate value to approximate y = if x > 0 then y1 else y2";
      algorithm
        y := smooth(1, if x > x_small then y1 else if x < (-x_small) then y2 else if abs(x_small) > 0 then x / x_small * ((x / x_small) ^ 2 - 3) * (y2 - y1) / 4 + (y1 + y2) / 2 else (y1 + y2) / 2);
        annotation(Inline = true, smoothOrder = 1, Documentation(revisions = "<html>
      <ul>
      <li><i>April 29, 2008</i>
          by <a href=\"mailto:Martin.Otter@DLR.de\">Martin Otter</a>:<br>
          Designed and implemented.</li>
      <li><i>August 12, 2008</i>
          by <a href=\"mailto:Michael.Sielemann@dlr.de\">Michael Sielemann</a>:<br>
          Minor modification to cover the limit case <code>x_small -> 0</code> without division by zero.</li>
      </ul>
      </html>", info = "<html>
      <p>
      This function is used to approximate the equation
      </p>
      <pre>
          y = <b>if</b> x &gt; 0 <b>then</b> y1 <b>else</b> y2;
      </pre>

      <p>
      by a smooth characteristic, so that the expression is continuous and differentiable:
      </p>

      <pre>
         y = <b>smooth</b>(1, <b>if</b> x &gt;  x_small <b>then</b> y1 <b>else</b>
                       <b>if</b> x &lt; -x_small <b>then</b> y2 <b>else</b> f(y1, y2));
      </pre>

      <p>
      In the region -x_small &lt; x &lt; x_small a 2nd order polynomial is used
      for a smooth transition from y1 to y2.
      </p>

      <p>
      If <b>mass fractions</b> X[:] are approximated with this function then this can be performed
      for all <b>nX</b> mass fractions, instead of applying it for nX-1 mass fractions and computing
      the last one by the mass fraction constraint sum(X)=1. The reason is that the approximating function has the
      property that sum(X) = 1, provided sum(X_a) = sum(X_b) = 1
      (and y1=X_a[i], y2=X_b[i]).
      This can be shown by evaluating the approximating function in the abs(x) &lt; x_small
      region (otherwise X is either X_a or X_b):
      </p>

      <pre>
          X[1]  = smoothStep(x, X_a[1] , X_b[1] , x_small);
          X[2]  = smoothStep(x, X_a[2] , X_b[2] , x_small);
             ...
          X[nX] = smoothStep(x, X_a[nX], X_b[nX], x_small);
      </pre>

      <p>
      or
      </p>

      <pre>
          X[1]  = c*(X_a[1]  - X_b[1])  + (X_a[1]  + X_b[1])/2
          X[2]  = c*(X_a[2]  - X_b[2])  + (X_a[2]  + X_b[2])/2;
             ...
          X[nX] = c*(X_a[nX] - X_b[nX]) + (X_a[nX] + X_b[nX])/2;
          c     = (x/x_small)*((x/x_small)^2 - 3)/4
      </pre>

      <p>
      Summing all mass fractions together results in
      </p>

      <pre>
          sum(X) = c*(sum(X_a) - sum(X_b)) + (sum(X_a) + sum(X_b))/2
                 = c*(1 - 1) + (1 + 1)/2
                 = 1
      </pre>
      </html>"));
      end smoothStep;

      package OneNonLinearEquation  "Determine solution of a non-linear algebraic equation in one unknown without derivatives in a reliable and efficient way"
        extends Modelica.Icons.Package;

        replaceable record f_nonlinear_Data  "Data specific for function f_nonlinear"
          extends Modelica.Icons.Record;
        end f_nonlinear_Data;

        replaceable partial function f_nonlinear  "Nonlinear algebraic equation in one unknown: y = f_nonlinear(x,p,X)"
          extends Modelica.Icons.Function;
          input Real x "Independent variable of function";
          input Real p = 0.0 "Disregarded variables (here always used for pressure)";
          input Real[:] X = fill(0, 0) "Disregarded variables (her always used for composition)";
          input f_nonlinear_Data f_nonlinear_data "Additional data for the function";
          output Real y "= f_nonlinear(x)";
        end f_nonlinear;

        replaceable function solve  "Solve f_nonlinear(x_zero)=y_zero; f_nonlinear(x_min) - y_zero and f_nonlinear(x_max)-y_zero must have different sign"
          extends Modelica.Icons.Function;
          input Real y_zero "Determine x_zero, such that f_nonlinear(x_zero) = y_zero";
          input Real x_min "Minimum value of x";
          input Real x_max "Maximum value of x";
          input Real pressure = 0.0 "Disregarded variables (here always used for pressure)";
          input Real[:] X = fill(0, 0) "Disregarded variables (here always used for composition)";
          input f_nonlinear_Data f_nonlinear_data "Additional data for function f_nonlinear";
          input Real x_tol = 100 * Modelica.Constants.eps "Relative tolerance of the result";
          output Real x_zero "f_nonlinear(x_zero) = y_zero";
        protected
          constant Real eps = Modelica.Constants.eps "Machine epsilon";
          constant Real x_eps = 1e-10 "Slight modification of x_min, x_max, since x_min, x_max are usually exactly at the borders T_min/h_min and then small numeric noise may make the interval invalid";
          Real x_min2 = x_min - x_eps;
          Real x_max2 = x_max + x_eps;
          Real a = x_min2 "Current best minimum interval value";
          Real b = x_max2 "Current best maximum interval value";
          Real c "Intermediate point a <= c <= b";
          Real d;
          Real e "b - a";
          Real m;
          Real s;
          Real p;
          Real q;
          Real r;
          Real tol;
          Real fa "= f_nonlinear(a) - y_zero";
          Real fb "= f_nonlinear(b) - y_zero";
          Real fc;
          Boolean found = false;
        algorithm
          fa := f_nonlinear(x_min2, pressure, X, f_nonlinear_data) - y_zero;
          fb := f_nonlinear(x_max2, pressure, X, f_nonlinear_data) - y_zero;
          fc := fb;
          if fa > 0.0 and fb > 0.0 or fa < 0.0 and fb < 0.0 then
            .Modelica.Utilities.Streams.error("The arguments x_min and x_max to OneNonLinearEquation.solve(..)\n" + "do not bracket the root of the single non-linear equation:\n" + "  x_min  = " + String(x_min2) + "\n" + "  x_max  = " + String(x_max2) + "\n" + "  y_zero = " + String(y_zero) + "\n" + "  fa = f(x_min) - y_zero = " + String(fa) + "\n" + "  fb = f(x_max) - y_zero = " + String(fb) + "\n" + "fa and fb must have opposite sign which is not the case");
          else
          end if;
          c := a;
          fc := fa;
          e := b - a;
          d := e;
          while not found loop
            if abs(fc) < abs(fb) then
              a := b;
              b := c;
              c := a;
              fa := fb;
              fb := fc;
              fc := fa;
            else
            end if;
            tol := 2 * eps * abs(b) + x_tol;
            m := (c - b) / 2;
            if abs(m) <= tol or fb == 0.0 then
              found := true;
              x_zero := b;
            else
              if abs(e) < tol or abs(fa) <= abs(fb) then
                e := m;
                d := e;
              else
                s := fb / fa;
                if a == c then
                  p := 2 * m * s;
                  q := 1 - s;
                else
                  q := fa / fc;
                  r := fb / fc;
                  p := s * (2 * m * q * (q - r) - (b - a) * (r - 1));
                  q := (q - 1) * (r - 1) * (s - 1);
                end if;
                if p > 0 then
                  q := -q;
                else
                  p := -p;
                end if;
                s := e;
                e := d;
                if 2 * p < 3 * m * q - abs(tol * q) and p < abs(0.5 * s * q) then
                  d := p / q;
                else
                  e := m;
                  d := e;
                end if;
              end if;
              a := b;
              fa := fb;
              b := b + (if abs(d) > tol then d else if m > 0 then tol else -tol);
              fb := f_nonlinear(b, pressure, X, f_nonlinear_data) - y_zero;
              if fb > 0 and fc > 0 or fb < 0 and fc < 0 then
                c := a;
                fc := fa;
                e := b - a;
                d := e;
              else
              end if;
            end if;
          end while;
        end solve;
        annotation(Documentation(info = "<html>
      <p>
      This function should currently only be used in Modelica.Media,
      since it might be replaced in the future by another strategy,
      where the tool is responsible for the solution of the non-linear
      equation.
      </p>

      <p>
      This library determines the solution of one non-linear algebraic equation \"y=f(x)\"
      in one unknown \"x\" in a reliable way. As input, the desired value y of the
      non-linear function has to be given, as well as an interval x_min, x_max that
      contains the solution, i.e., \"f(x_min) - y\" and \"f(x_max) - y\" must
      have a different sign. If possible, a smaller interval is computed by
      inverse quadratic interpolation (interpolating with a quadratic polynomial
      through the last 3 points and computing the zero). If this fails,
      bisection is used, which always reduces the interval by a factor of 2.
      The inverse quadratic interpolation method has superlinear convergence.
      This is roughly the same convergence rate as a globally convergent Newton
      method, but without the need to compute derivatives of the non-linear
      function. The solver function is a direct mapping of the Algol 60 procedure
      \"zero\" to Modelica, from:
      </p>

      <dl>
      <dt> Brent R.P.:</dt>
      <dd> <b>Algorithms for Minimization without derivatives</b>.
           Prentice Hall, 1973, pp. 58-59.</dd>
      </dl>

      <p>
      Due to current limitations of the
      Modelica language (not possible to pass a function reference to a function),
      the construction to use this solver on a user-defined function is a bit
      complicated (this method is from Hans Olsson, Dassault Syst&egrave;mes AB). A user has to
      provide a package in the following way:
      </p>

      <pre>
        <b>package</b> MyNonLinearSolver
          <b>extends</b> OneNonLinearEquation;

          <b>redeclare record extends</b> Data
            // Define data to be passed to user function
            ...
          <b>end</b> Data;

          <b>redeclare function extends</b> f_nonlinear
          <b>algorithm</b>
             // Compute the non-linear equation: y = f(x, Data)
          <b>end</b> f_nonlinear;

          // Dummy definition that has to be present for current Dymola
          <b>redeclare function extends</b> solve
          <b>end</b> solve;
        <b>end</b> MyNonLinearSolver;

        x_zero = MyNonLinearSolver.solve(y_zero, x_min, x_max, data=data);
      </pre>
      </html>"));
      end OneNonLinearEquation;
      annotation(Documentation(info = "<HTML><h4>Package description</h4>
          <p>Package Modelica.Media.Common provides records and functions shared by many of the property sub-packages.
          High accuracy fluid property models share a lot of common structure, even if the actual models are different.
          Common data structures and computations shared by these property models are collected in this library.
       </p>

    </html>", revisions = "<html>
          <ul>
          <li>First implemented: <i>July, 2000</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>
          for the ThermoFluid Library with help from Jonas Eborn and Falko Jens Wagner
          </li>
          <li>Code reorganization, enhanced documentation, additional functions: <i>December, 2002</i>
          by <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a> and move to Modelica
                                properties library.</li>
          <li>Inclusion into Modelica.Media: September 2003 </li>
          </ul>

          <address>Author: Hubertus Tummescheit, <br>
          Lund University<br>
          Department of Automatic Control<br>
          Box 118, 22100 Lund, Sweden<br>
          email: hubertus@control.lth.se
          </address>
    </html>"));
    end Common;

    package Air  "Medium models for air"
      extends Modelica.Icons.VariantsPackage;

      package MoistAir  "Air: Moist air model (190 ... 647 K)"
        extends .Modelica.Media.Interfaces.PartialCondensingGases(mediumName = "Moist air", substanceNames = {"water", "air"}, final reducedX = true, final singleState = false, reference_X = {0.01, 0.99}, fluidConstants = {IdealGases.Common.FluidData.H2O, IdealGases.Common.FluidData.N2}, Temperature(min = 190, max = 647));
        constant Integer Water = 1 "Index of water (in substanceNames, massFractions X, etc.)";
        constant Integer Air = 2 "Index of air (in substanceNames, massFractions X, etc.)";
        constant Real k_mair = steam.MM / dryair.MM "Ratio of molar weights";
        constant IdealGases.Common.DataRecord dryair = IdealGases.Common.SingleGasesData.Air;
        constant IdealGases.Common.DataRecord steam = IdealGases.Common.SingleGasesData.H2O;
        constant .Modelica.SIunits.MolarMass[2] MMX = {steam.MM, dryair.MM} "Molar masses of components";

        redeclare record extends ThermodynamicState  "ThermodynamicState record for moist air" end ThermodynamicState;

        redeclare replaceable model extends BaseProperties(T(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), p(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), Xi(each stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), final standardOrderComponents = true)  "Moist air base properties record"
          MassFraction x_water "Mass of total water/mass of dry air";
          Real phi "Relative humidity";
        protected
          MassFraction X_liquid "Mass fraction of liquid or solid water";
          MassFraction X_steam "Mass fraction of steam water";
          MassFraction X_air "Mass fraction of air";
          MassFraction X_sat "Steam water mass fraction of saturation boundary in kg_water/kg_moistair";
          MassFraction x_sat "Steam water mass content of saturation boundary in kg_water/kg_dryair";
          AbsolutePressure p_steam_sat "partial saturation pressure of steam";
        equation
          assert(T >= 190 and T <= 647, "
        Temperature T is not in the allowed range
        190.0 K <= (T =" + String(T) + " K) <= 647.0 K
        required from medium model \"" + mediumName + "\".");
          MM = 1 / (Xi[Water] / MMX[Water] + (1.0 - Xi[Water]) / MMX[Air]);
          p_steam_sat = min(saturationPressure(T), 0.999 * p);
          X_sat = min(p_steam_sat * k_mair / max(100 * .Modelica.Constants.eps, p - p_steam_sat) * (1 - Xi[Water]), 1.0) "Water content at saturation with respect to actual water content";
          X_liquid = max(Xi[Water] - X_sat, 0.0);
          X_steam = Xi[Water] - X_liquid;
          X_air = 1 - Xi[Water];
          h = specificEnthalpy_pTX(p, T, Xi);
          R = dryair.R * (X_air / (1 - X_liquid)) + steam.R * X_steam / (1 - X_liquid);
          u = h - R * T;
          d = p / (R * T);
          state.p = p;
          state.T = T;
          state.X = X;
          x_sat = k_mair * p_steam_sat / max(100 * .Modelica.Constants.eps, p - p_steam_sat);
          x_water = Xi[Water] / max(X_air, 100 * .Modelica.Constants.eps);
          phi = p / p_steam_sat * Xi[Water] / (Xi[Water] + k_mair * X_air);
          annotation(Documentation(info = "<html>
        <p>This model computes thermodynamic properties of moist air from three independent (thermodynamic or/and numerical) state variables. Preferred numerical states are temperature T, pressure p and the reduced composition vector Xi, which contains the water mass fraction only. As an EOS the <b>ideal gas law</b> is used and associated restrictions apply. The model can also be used in the <b>fog region</b>, when moisture is present in its liquid state. However, it is assumed that the liquid water volume is negligible compared to that of the gas phase. Computation of thermal properties is based on property data of <a href=\"modelica://Modelica.Media.Air.DryAirNasa\"> dry air</a> and water (source: VDI-W&auml;rmeatlas), respectively. Besides the standard thermodynamic variables <b>absolute and relative humidity</b>, x_water and phi, respectively, are given by the model. Upper case X denotes absolute humidity with respect to mass of moist air while absolute humidity with respect to mass of dry air only is denoted by a lower case x throughout the model. See <a href=\"modelica://Modelica.Media.Air.MoistAir\">package description</a> for further information.</p>
        </html>"));
        end BaseProperties;

        redeclare function setState_pTX  "Return thermodynamic state as function of pressure p, temperature T and composition X"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state";
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T, X = X) else ThermodynamicState(p = p, T = T, X = cat(1, X, {1 - sum(X)}));
          annotation(smoothOrder = 2, Documentation(info = "<html>
        The <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state record</a> is computed from pressure p, temperature T and composition X.
        </html>"));
        end setState_pTX;

        redeclare function setState_phX  "Return thermodynamic state as function of pressure p, specific enthalpy h and composition X"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state";
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T_phX(p, h, X), X = X) else ThermodynamicState(p = p, T = T_phX(p, h, X), X = cat(1, X, {1 - sum(X)}));
          annotation(smoothOrder = 2, Documentation(info = "<html>
        The <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state record</a> is computed from pressure p, specific enthalpy h and composition X.
        </html>"));
        end setState_phX;

        redeclare function setState_dTX  "Return thermodynamic state as function of density d, temperature T and composition X"
          extends Modelica.Icons.Function;
          input Density d "Density";
          input Temperature T "Temperature";
          input MassFraction[:] X = reference_X "Mass fractions";
          output ThermodynamicState state "Thermodynamic state";
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = d * ({steam.R, dryair.R} * X) * T, T = T, X = X) else ThermodynamicState(p = d * ({steam.R, dryair.R} * cat(1, X, {1 - sum(X)})) * T, T = T, X = cat(1, X, {1 - sum(X)}));
          annotation(smoothOrder = 2, Documentation(info = "<html>
        The <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state record</a> is computed from density d, temperature T and composition X.
        </html>"));
        end setState_dTX;

        redeclare function extends setSmoothState  "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
        algorithm
          state := ThermodynamicState(p = Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), T = Media.Common.smoothStep(x, state_a.T, state_b.T, x_small), X = Media.Common.smoothStep(x, state_a.X, state_b.X, x_small));
        end setSmoothState;

        redeclare function extends gasConstant  "Return ideal gas constant as a function from thermodynamic state, only valid for phi<1"
        algorithm
          R := dryair.R * (1 - state.X[Water]) + steam.R * state.X[Water];
          annotation(smoothOrder = 2, Documentation(info = "<html>
        The ideal gas constant for moist air is computed from <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state</a> assuming that all water is in the gas phase.
        </html>"));
        end gasConstant;

        function saturationPressureLiquid  "Return saturation pressure of water as a function of temperature T in the range of 273.16 to 647.096 K"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat "Saturation temperature";
          output .Modelica.SIunits.AbsolutePressure psat "Saturation pressure";
        protected
          .Modelica.SIunits.Temperature Tcritical = 647.096 "Critical temperature";
          .Modelica.SIunits.AbsolutePressure pcritical = 22.064e6 "Critical pressure";
          Real r1 = 1 - Tsat / Tcritical "Common subexpression";
          Real[:] a = {-7.85951783, 1.84408259, -11.7866497, 22.6807411, -15.9618719, 1.80122502} "Coefficients a[:]";
          Real[:] n = {1.0, 1.5, 3.0, 3.5, 4.0, 7.5} "Coefficients n[:]";
        algorithm
          psat := exp((a[1] * r1 ^ n[1] + a[2] * r1 ^ n[2] + a[3] * r1 ^ n[3] + a[4] * r1 ^ n[4] + a[5] * r1 ^ n[5] + a[6] * r1 ^ n[6]) * Tcritical / Tsat) * pcritical;
          annotation(derivative = saturationPressureLiquid_der, Inline = false, smoothOrder = 5, Documentation(info = "<html>
        <p>Saturation pressure of water above the triple point temperature is computed from temperature. </p>
        <p>Source: A Saul, W Wagner: &quot;International equations for the saturation properties of ordinary water substance&quot;, equation 2.1 </p>
        </html>"));
        end saturationPressureLiquid;

        function saturationPressureLiquid_der  "Derivative function for 'saturationPressureLiquid'"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat "Saturation temperature";
          input Real dTsat(unit = "K/s") "Saturation temperature derivative";
          output Real psat_der(unit = "Pa/s") "Saturation pressure derivative";
        protected
          .Modelica.SIunits.Temperature Tcritical = 647.096 "Critical temperature";
          .Modelica.SIunits.AbsolutePressure pcritical = 22.064e6 "Critical pressure";
          Real r1 = 1 - Tsat / Tcritical "Common subexpression 1";
          Real r1_der = -1 / Tcritical * dTsat "Derivative of common subexpression 1";
          Real[:] a = {-7.85951783, 1.84408259, -11.7866497, 22.6807411, -15.9618719, 1.80122502} "Coefficients a[:]";
          Real[:] n = {1.0, 1.5, 3.0, 3.5, 4.0, 7.5} "Coefficients n[:]";
          Real r2 = a[1] * r1 ^ n[1] + a[2] * r1 ^ n[2] + a[3] * r1 ^ n[3] + a[4] * r1 ^ n[4] + a[5] * r1 ^ n[5] + a[6] * r1 ^ n[6] "Common subexpression 2";
        algorithm
          psat_der := exp(r2 * Tcritical / Tsat) * pcritical * ((a[1] * (r1 ^ (n[1] - 1) * n[1] * r1_der) + a[2] * (r1 ^ (n[2] - 1) * n[2] * r1_der) + a[3] * (r1 ^ (n[3] - 1) * n[3] * r1_der) + a[4] * (r1 ^ (n[4] - 1) * n[4] * r1_der) + a[5] * (r1 ^ (n[5] - 1) * n[5] * r1_der) + a[6] * (r1 ^ (n[6] - 1) * n[6] * r1_der)) * Tcritical / Tsat - r2 * Tcritical * dTsat / Tsat ^ 2);
          annotation(Inline = false, smoothOrder = 5, Documentation(info = "<html>
        <p>Saturation pressure of water above the triple point temperature is computed from temperature. </p>
        <p>Source: A Saul, W Wagner: &quot;International equations for the saturation properties of ordinary water substance&quot;, equation 2.1 </p>
        </html>"));
        end saturationPressureLiquid_der;

        function sublimationPressureIce  "Return sublimation pressure of water as a function of temperature T between 190 and 273.16 K"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat "Sublimation temperature";
          output .Modelica.SIunits.AbsolutePressure psat "Sublimation pressure";
        protected
          .Modelica.SIunits.Temperature Ttriple = 273.16 "Triple point temperature";
          .Modelica.SIunits.AbsolutePressure ptriple = 611.657 "Triple point pressure";
          Real r1 = Tsat / Ttriple "Common subexpression";
          Real[:] a = {-13.9281690, 34.7078238} "Coefficients a[:]";
          Real[:] n = {-1.5, -1.25} "Coefficients n[:]";
        algorithm
          psat := exp(a[1] - a[1] * r1 ^ n[1] + a[2] - a[2] * r1 ^ n[2]) * ptriple;
          annotation(Inline = false, smoothOrder = 5, derivative = sublimationPressureIce_der, Documentation(info = "<html>
        <p>Sublimation pressure of water below the triple point temperature is computed from temperature.</p>
        <p>Source: W Wagner, A Saul, A Pruss: &quot;International equations for the pressure along the melting and along the sublimation curve of ordinary water substance&quot;, equation 3.5</p>
        </html>"));
        end sublimationPressureIce;

        function sublimationPressureIce_der  "Derivative function for 'sublimationPressureIce'"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature Tsat "Sublimation temperature";
          input Real dTsat(unit = "K/s") "Sublimation temperature derivative";
          output Real psat_der(unit = "Pa/s") "Sublimation pressure derivative";
        protected
          .Modelica.SIunits.Temperature Ttriple = 273.16 "Triple point temperature";
          .Modelica.SIunits.AbsolutePressure ptriple = 611.657 "Triple point pressure";
          Real r1 = Tsat / Ttriple "Common subexpression 1";
          Real r1_der = dTsat / Ttriple "Derivative of common subexpression 1";
          Real[:] a = {-13.9281690, 34.7078238} "Coefficients a[:]";
          Real[:] n = {-1.5, -1.25} "Coefficients n[:]";
        algorithm
          psat_der := exp(a[1] - a[1] * r1 ^ n[1] + a[2] - a[2] * r1 ^ n[2]) * ptriple * ((-a[1] * (r1 ^ (n[1] - 1) * n[1] * r1_der)) - a[2] * (r1 ^ (n[2] - 1) * n[2] * r1_der));
          annotation(Inline = false, smoothOrder = 5, Documentation(info = "<html>
        <p>Sublimation pressure of water below the triple point temperature is computed from temperature.</p>
        <p>Source: W Wagner, A Saul, A Pruss: &quot;International equations for the pressure along the melting and along the sublimation curve of ordinary water substance&quot;, equation 3.5</p>
        </html>"));
        end sublimationPressureIce_der;

        redeclare function extends saturationPressure  "Return saturation pressure of water as a function of temperature T between 190 and 647.096 K"
        algorithm
          psat := Utilities.spliceFunction(saturationPressureLiquid(Tsat), sublimationPressureIce(Tsat), Tsat - 273.16, 1.0);
          annotation(Inline = false, smoothOrder = 5, derivative = saturationPressure_der, Documentation(info = "<html>
        Saturation pressure of water in the liquid and the solid region is computed using correlations. Functions for the
        <a href=\"modelica://Modelica.Media.Air.MoistAir.sublimationPressureIce\">solid</a> and the <a href=\"modelica://Modelica.Media.Air.MoistAir.saturationPressureLiquid\"> liquid</a> region, respectively, are combined using the first derivative continuous <a href=\"modelica://Modelica.Media.Air.MoistAir.Utilities.spliceFunction\">spliceFunction</a>. This functions range of validity is from 190 to 647.096 K. For more information on the type of correlation used, see the documentation of the linked functions.
        </html>"));
        end saturationPressure;

        function saturationPressure_der  "Derivative function for 'saturationPressure'"
          extends Modelica.Icons.Function;
          input Temperature Tsat "Saturation temperature";
          input Real dTsat(unit = "K/s") "Time derivative of saturation temperature";
          output Real psat_der(unit = "Pa/s") "Saturation pressure";
        algorithm
          psat_der := Utilities.spliceFunction_der(saturationPressureLiquid(Tsat), sublimationPressureIce(Tsat), Tsat - 273.16, 1.0, saturationPressureLiquid_der(Tsat = Tsat, dTsat = dTsat), sublimationPressureIce_der(Tsat = Tsat, dTsat = dTsat), dTsat, 0);
          annotation(Inline = false, smoothOrder = 5, Documentation(info = "<html>
        Derivative function of <a href=\"modelica://Modelica.Media.Air.MoistAir.saturationPressure\">saturationPressure</a>
        </html>"));
        end saturationPressure_der;

        redeclare function extends enthalpyOfVaporization  "Return enthalpy of vaporization of water as a function of temperature T, 273.16 to 647.096 K"
        protected
          Real Tcritical = 647.096 "Critical temperature";
          Real dcritical = 322 "Critical density";
          Real pcritical = 22.064e6 "Critical pressure";
          Real[:] n = {1, 1.5, 3, 3.5, 4, 7.5} "Powers in equation (1)";
          Real[:] a = {-7.85951783, 1.84408259, -11.7866497, 22.6807411, -15.9618719, 1.80122502} "Coefficients in equation (1) of [1]";
          Real[:] m = {1 / 3, 2 / 3, 5 / 3, 16 / 3, 43 / 3, 110 / 3} "Powers in equation (2)";
          Real[:] b = {1.99274064, 1.09965342, -0.510839303, -1.75493479, -45.5170352, -6.74694450e5} "Coefficients in equation (2) of [1]";
          Real[:] o = {2 / 6, 4 / 6, 8 / 6, 18 / 6, 37 / 6, 71 / 6} "Powers in equation (3)";
          Real[:] c = {-2.03150240, -2.68302940, -5.38626492, -17.2991605, -44.7586581, -63.9201063} "Coefficients in equation (3) of [1]";
          Real tau = 1 - T / Tcritical "Temperature expression";
          Real r1 = a[1] * Tcritical * tau ^ n[1] / T + a[2] * Tcritical * tau ^ n[2] / T + a[3] * Tcritical * tau ^ n[3] / T + a[4] * Tcritical * tau ^ n[4] / T + a[5] * Tcritical * tau ^ n[5] / T + a[6] * Tcritical * tau ^ n[6] / T "Expression 1";
          Real r2 = a[1] * n[1] * tau ^ n[1] + a[2] * n[2] * tau ^ n[2] + a[3] * n[3] * tau ^ n[3] + a[4] * n[4] * tau ^ n[4] + a[5] * n[5] * tau ^ n[5] + a[6] * n[6] * tau ^ n[6] "Expression 2";
          Real dp = dcritical * (1 + b[1] * tau ^ m[1] + b[2] * tau ^ m[2] + b[3] * tau ^ m[3] + b[4] * tau ^ m[4] + b[5] * tau ^ m[5] + b[6] * tau ^ m[6]) "Density of saturated liquid";
          Real dpp = dcritical * exp(c[1] * tau ^ o[1] + c[2] * tau ^ o[2] + c[3] * tau ^ o[3] + c[4] * tau ^ o[4] + c[5] * tau ^ o[5] + c[6] * tau ^ o[6]) "Density of saturated vapor";
        algorithm
          r0 := -(dp - dpp) * exp(r1) * pcritical * (r2 + r1 * tau) / (dp * dpp * tau) "Difference of equations (7) and (6)";
          annotation(smoothOrder = 2, Documentation(info = "<html>
        <p>Enthalpy of vaporization of water is computed from temperature in the region of 273.16 to 647.096 K.</p>
        <p>Source: W Wagner, A Pruss: \"International equations for the saturation properties of ordinary water substance. Revised according to the international temperature scale of 1990\" (1993).</p>
        </html>"));
        end enthalpyOfVaporization;

        redeclare function extends enthalpyOfLiquid  "Return enthalpy of liquid water as a function of temperature T(use enthalpyOfWater instead)"
        algorithm
          h := (T - 273.15) * 1e3 * (4.2166 - 0.5 * (T - 273.15) * (0.0033166 + 0.333333 * (T - 273.15) * (0.00010295 - 0.25 * (T - 273.15) * (1.3819e-6 + 0.2 * (T - 273.15) * 7.3221e-9))));
          annotation(Inline = false, smoothOrder = 5, Documentation(info = "<html>
        Specific enthalpy of liquid water is computed from temperature using a polynomial approach. Kept for compatibility reasons, better use <a href=\"modelica://Modelica.Media.Air.MoistAir.enthalpyOfWater\">enthalpyOfWater</a> instead.
        </html>"));
        end enthalpyOfLiquid;

        redeclare function extends enthalpyOfGas  "Return specific enthalpy of gas (air and steam) as a function of temperature T and composition X"
        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5) * X[Water] + Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684) * (1.0 - X[Water]);
          annotation(Inline = false, smoothOrder = 5, Documentation(info = "<html>
        Specific enthalpy of moist air is computed from temperature, provided all water is in the gaseous state. The first entry in the composition vector X must be the mass fraction of steam. For a function that also covers the fog region please refer to <a href=\"modelica://Modelica.Media.Air.MoistAir.h_pTX\">h_pTX</a>.
        </html>"));
        end enthalpyOfGas;

        redeclare function extends enthalpyOfCondensingGas  "Return specific enthalpy of steam as a function of temperature T"
        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5);
          annotation(Inline = false, smoothOrder = 5, Documentation(info = "<html>
        Specific enthalpy of steam is computed from temperature.
        </html>"));
        end enthalpyOfCondensingGas;

        redeclare function extends enthalpyOfNonCondensingGas  "Return specific enthalpy of dry air as a function of temperature T"
        algorithm
          h := Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684);
          annotation(Inline = false, smoothOrder = 1, Documentation(info = "<html>
        Specific enthalpy of dry air is computed from temperature.
        </html>"));
        end enthalpyOfNonCondensingGas;

        function enthalpyOfWater  "Computes specific enthalpy of water (solid/liquid) near atmospheric pressure from temperature T"
          extends Modelica.Icons.Function;
          input SIunits.Temperature T "Temperature";
          output SIunits.SpecificEnthalpy h "Specific enthalpy of water";
        algorithm
          h := Utilities.spliceFunction(4200 * (T - 273.15), 2050 * (T - 273.15) - 333000, T - 273.16, 0.1);
          annotation(derivative = enthalpyOfWater_der, Documentation(info = "<html>
        Specific enthalpy of water (liquid and solid) is computed from temperature using constant properties as follows:<br>
        <ul>
        <li>  heat capacity of liquid water:4200 J/kg
        <li>  heat capacity of solid water: 2050 J/kg
        <li>  enthalpy of fusion (liquid=>solid): 333000 J/kg
        </ul>
        Pressure is assumed to be around 1 bar. This function is usually used to determine the specific enthalpy of the liquid or solid fraction of moist air.
        </html>"));
        end enthalpyOfWater;

        function enthalpyOfWater_der  "Derivative function of enthalpyOfWater"
          extends Modelica.Icons.Function;
          input SIunits.Temperature T "Temperature";
          input Real dT(unit = "K/s") "Time derivative of temperature";
          output Real dh(unit = "J/(kg.s)") "Time derivative of specific enthalpy";
        algorithm
          dh := Utilities.spliceFunction_der(4200 * (T - 273.15), 2050 * (T - 273.15) - 333000, T - 273.16, 0.1, 4200 * dT, 2050 * dT, dT, 0);
          annotation(Documentation(info = "<html>
        Derivative function for <a href=\"modelica://Modelica.Media.Air.MoistAir.enthalpyOfWater\">enthalpyOfWater</a>.

        </html>"));
        end enthalpyOfWater_der;

        redeclare function extends pressure  "Returns pressure of ideal gas as a function of the thermodynamic state record"
        algorithm
          p := state.p;
          annotation(smoothOrder = 2, Documentation(info = "<html>
        Pressure is returned from the thermodynamic state record input as a simple assignment.
        </html>"));
        end pressure;

        redeclare function extends temperature  "Return temperature of ideal gas as a function of the thermodynamic state record"
        algorithm
          T := state.T;
          annotation(smoothOrder = 2, Documentation(info = "<html>
        Temperature is returned from the thermodynamic state record input as a simple assignment.
        </html>"));
        end temperature;

        function T_phX  "Return temperature as a function of pressure p, specific enthalpy h and composition X"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          input MassFraction[:] X "Mass fractions of composition";
          output Temperature T "Temperature";

        protected
          package Internal  "Solve h(data,T) for T with given h (use only indirectly via temperature_phX)"
            extends Modelica.Media.Common.OneNonLinearEquation;

            redeclare record extends f_nonlinear_Data  "Data to be passed to non-linear function"
              extends Modelica.Media.IdealGases.Common.DataRecord;
            end f_nonlinear_Data;

            redeclare function extends f_nonlinear
            algorithm
              y := h_pTX(p, x, X);
            end f_nonlinear;

            redeclare function extends solve  end solve;
          end Internal;
        algorithm
          T := Internal.solve(h, 190, 647, p, X[1:nXi], steam);
          annotation(Documentation(info = "<html>
        Temperature is computed from pressure, specific enthalpy and composition via numerical inversion of function <a href=\"modelica://Modelica.Media.Air.MoistAir.h_pTX\">h_pTX</a>.
        </html>"));
        end T_phX;

        redeclare function extends density  "Returns density of ideal gas as a function of the thermodynamic state record"
        algorithm
          d := state.p / (gasConstant(state) * state.T);
          annotation(smoothOrder = 2, Documentation(info = "<html>
        Density is computed from pressure, temperature and composition in the thermodynamic state record applying the ideal gas law.
        </html>"));
        end density;

        redeclare function extends specificEnthalpy  "Return specific enthalpy of moist air as a function of the thermodynamic state record"
        algorithm
          h := h_pTX(state.p, state.T, state.X);
          annotation(smoothOrder = 2, Documentation(info = "<html>
        Specific enthalpy of moist air is computed from the thermodynamic state record. The fog region is included for both, ice and liquid fog.
        </html>"));
        end specificEnthalpy;

        function h_pTX  "Return specific enthalpy of moist air as a function of pressure p, temperature T and composition X"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input .Modelica.SIunits.MassFraction[:] X "Mass fractions of moist air";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy at p, T, X";
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat "partial saturation pressure of steam";
          .Modelica.SIunits.MassFraction X_sat "Absolute humidity per unit mass of moist air";
          .Modelica.SIunits.MassFraction X_liquid "Mass fraction of liquid water";
          .Modelica.SIunits.MassFraction X_steam "Mass fraction of steam water";
          .Modelica.SIunits.MassFraction X_air "Mass fraction of air";
        algorithm
          p_steam_sat := saturationPressure(T);
          X_sat := min(p_steam_sat * k_mair / max(100 * .Modelica.Constants.eps, p - p_steam_sat) * (1 - X[Water]), 1.0);
          X_liquid := max(X[Water] - X_sat, 0.0);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          h := {Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5), Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684)} * {X_steam, X_air} + enthalpyOfWater(T) * X_liquid;
          annotation(derivative = h_pTX_der, Inline = false, Documentation(info = "<html>
        Specific enthalpy of moist air is computed from pressure, temperature and composition with X[1] as the total water mass fraction. The fog region is included for both, ice and liquid fog.
        </html>"));
        end h_pTX;

        function h_pTX_der  "Derivative function of h_pTX"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input .Modelica.SIunits.MassFraction[:] X "Mass fractions of moist air";
          input Real dp(unit = "Pa/s") "Pressure derivative";
          input Real dT(unit = "K/s") "Temperature derivative";
          input Real[:] dX(each unit = "1/s") "Composition derivative";
          output Real h_der(unit = "J/(kg.s)") "Time derivative of specific enthalpy";
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat "partial saturation pressure of steam";
          .Modelica.SIunits.MassFraction X_sat "Absolute humidity per unit mass of moist air";
          .Modelica.SIunits.MassFraction X_liquid "Mass fraction of liquid water";
          .Modelica.SIunits.MassFraction X_steam "Mass fraction of steam water";
          .Modelica.SIunits.MassFraction X_air "Mass fraction of air";
          .Modelica.SIunits.MassFraction x_sat "Absolute humidity per unit mass of dry air at saturation";
          Real dX_steam(unit = "1/s") "Time derivative of steam mass fraction";
          Real dX_air(unit = "1/s") "Time derivative of dry air mass fraction";
          Real dX_liq(unit = "1/s") "Time derivative of liquid/solid water mass fraction";
          Real dps(unit = "Pa/s") "Time derivative of saturation pressure";
          Real dx_sat(unit = "1/s") "Time derivative of absolute humidity per unit mass of dry air";
        algorithm
          p_steam_sat := saturationPressure(T);
          x_sat := p_steam_sat * k_mair / max(100 * Modelica.Constants.eps, p - p_steam_sat);
          X_sat := min(x_sat * (1 - X[Water]), 1.0);
          X_liquid := Utilities.smoothMax(X[Water] - X_sat, 0.0, 1e-5);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          dX_air := -dX[Water];
          dps := saturationPressure_der(Tsat = T, dTsat = dT);
          dx_sat := k_mair * (dps * (p - p_steam_sat) - p_steam_sat * (dp - dps)) / (p - p_steam_sat) / (p - p_steam_sat);
          dX_liq := Utilities.smoothMax_der(X[Water] - X_sat, 0.0, 1e-5, (1 + x_sat) * dX[Water] - (1 - X[Water]) * dx_sat, 0, 0);
          dX_steam := dX[Water] - dX_liq;
          h_der := X_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5, dT = dT) + dX_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5) + X_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684, dT = dT) + dX_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684) + X_liquid * enthalpyOfWater_der(T = T, dT = dT) + dX_liq * enthalpyOfWater(T);
          annotation(Inline = false, smoothOrder = 1, Documentation(info = "<html>
        Derivative function for <a href=\"modelica://Modelica.Media.Air.MoistAir.h_pTX\">h_pTX</a>.
        </html>"));
        end h_pTX_der;

        redeclare function extends isentropicExponent  "Return isentropic exponent (only for gas fraction!)"
        algorithm
          gamma := specificHeatCapacityCp(state) / specificHeatCapacityCv(state);
        end isentropicExponent;

        redeclare function extends specificInternalEnergy  "Return specific internal energy of moist air as a function of the thermodynamic state record"
          extends Modelica.Icons.Function;
          output .Modelica.SIunits.SpecificInternalEnergy u "Specific internal energy";
        algorithm
          u := specificInternalEnergy_pTX(state.p, state.T, state.X);
          annotation(smoothOrder = 2, Documentation(info = "<html>
        Specific internal energy is determined from the thermodynamic state record, assuming that the liquid or solid water volume is negligible.
        </html>"));
        end specificInternalEnergy;

        function specificInternalEnergy_pTX  "Return specific internal energy of moist air as a function of pressure p, temperature T and composition X"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input .Modelica.SIunits.MassFraction[:] X "Mass fractions of moist air";
          output .Modelica.SIunits.SpecificInternalEnergy u "Specific internal energy";
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat "partial saturation pressure of steam";
          .Modelica.SIunits.MassFraction X_liquid "Mass fraction of liquid water";
          .Modelica.SIunits.MassFraction X_steam "Mass fraction of steam water";
          .Modelica.SIunits.MassFraction X_air "Mass fraction of air";
          .Modelica.SIunits.MassFraction X_sat "Absolute humidity per unit mass of moist air";
          Real R_gas "Ideal gas constant";
        algorithm
          p_steam_sat := saturationPressure(T);
          X_sat := min(p_steam_sat * k_mair / max(100 * .Modelica.Constants.eps, p - p_steam_sat) * (1 - X[Water]), 1.0);
          X_liquid := max(X[Water] - X_sat, 0.0);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          R_gas := dryair.R * X_air / (1 - X_liquid) + steam.R * X_steam / (1 - X_liquid);
          u := X_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5) + X_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684) + enthalpyOfWater(T) * X_liquid - R_gas * T;
          annotation(derivative = specificInternalEnergy_pTX_der, Documentation(info = "<html>
        Specific internal energy is determined from pressure p, temperature T and composition X, assuming that the liquid or solid water volume is negligible.
        </html>"));
        end specificInternalEnergy_pTX;

        function specificInternalEnergy_pTX_der  "Derivative function for specificInternalEnergy_pTX"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input .Modelica.SIunits.MassFraction[:] X "Mass fractions of moist air";
          input Real dp(unit = "Pa/s") "Pressure derivative";
          input Real dT(unit = "K/s") "Temperature derivative";
          input Real[:] dX(each unit = "1/s") "Mass fraction derivatives";
          output Real u_der(unit = "J/(kg.s)") "Specific internal energy derivative";
        protected
          .Modelica.SIunits.AbsolutePressure p_steam_sat "partial saturation pressure of steam";
          .Modelica.SIunits.MassFraction X_liquid "Mass fraction of liquid water";
          .Modelica.SIunits.MassFraction X_steam "Mass fraction of steam water";
          .Modelica.SIunits.MassFraction X_air "Mass fraction of air";
          .Modelica.SIunits.MassFraction X_sat "Absolute humidity per unit mass of moist air";
          .Modelica.SIunits.SpecificHeatCapacity R_gas "Ideal gas constant";
          .Modelica.SIunits.MassFraction x_sat "Absolute humidity per unit mass of dry air at saturation";
          Real dX_steam(unit = "1/s") "Time derivative of steam mass fraction";
          Real dX_air(unit = "1/s") "Time derivative of dry air mass fraction";
          Real dX_liq(unit = "1/s") "Time derivative of liquid/solid water mass fraction";
          Real dps(unit = "Pa/s") "Time derivative of saturation pressure";
          Real dx_sat(unit = "1/s") "Time derivative of absolute humidity per unit mass of dry air";
          Real dR_gas(unit = "J/(kg.K.s)") "Time derivative of ideal gas constant";
        algorithm
          p_steam_sat := saturationPressure(T);
          x_sat := p_steam_sat * k_mair / max(100 * Modelica.Constants.eps, p - p_steam_sat);
          X_sat := min(x_sat * (1 - X[Water]), 1.0);
          X_liquid := Utilities.spliceFunction(X[Water] - X_sat, 0.0, X[Water] - X_sat, 1e-6);
          X_steam := X[Water] - X_liquid;
          X_air := 1 - X[Water];
          R_gas := steam.R * X_steam / (1 - X_liquid) + dryair.R * X_air / (1 - X_liquid);
          dX_air := -dX[Water];
          dps := saturationPressure_der(Tsat = T, dTsat = dT);
          dx_sat := k_mair * (dps * (p - p_steam_sat) - p_steam_sat * (dp - dps)) / (p - p_steam_sat) / (p - p_steam_sat);
          dX_liq := Utilities.spliceFunction_der(X[Water] - X_sat, 0.0, X[Water] - X_sat, 1e-6, (1 + x_sat) * dX[Water] - (1 - X[Water]) * dx_sat, 0.0, (1 + x_sat) * dX[Water] - (1 - X[Water]) * dx_sat, 0.0);
          dX_steam := dX[Water] - dX_liq;
          dR_gas := (steam.R * (dX_steam * (1 - X_liquid) + dX_liq * X_steam) + dryair.R * (dX_air * (1 - X_liquid) + dX_liq * X_air)) / (1 - X_liquid) / (1 - X_liquid);
          u_der := X_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5, dT = dT) + dX_steam * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = steam, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 46479.819 + 2501014.5) + X_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow_der(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684, dT = dT) + dX_air * Modelica.Media.IdealGases.Common.Functions.h_Tlow(data = dryair, T = T, refChoice = .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined, h_off = 25104.684) + X_liquid * enthalpyOfWater_der(T = T, dT = dT) + dX_liq * enthalpyOfWater(T) - dR_gas * T - R_gas * dT;
          annotation(Documentation(info = "<html>
        Derivative function for <a href=\"modelica://Modelica.Media.Air.MoistAir.specificInternalEnergy_pTX\">specificInternalEnergy_pTX</a>.
        </html>"));
        end specificInternalEnergy_pTX_der;

        redeclare function extends specificEntropy  "Return specific entropy from thermodynamic state record, only valid for phi<1"
        algorithm
          s := s_pTX(state.p, state.T, state.X);
          annotation(Inline = false, smoothOrder = 2, Documentation(info = "<html>
        Specific entropy is calculated from the thermodynamic state record, assuming ideal gas behavior and including entropy of mixing. Liquid or solid water is not taken into account, the entire water content X[1] is assumed to be in the vapor state (relative humidity below 1.0).
        </html>"));
        end specificEntropy;

        redeclare function extends specificGibbsEnergy  "Return specific Gibbs energy as a function of the thermodynamic state record, only valid for phi<1"
          extends Modelica.Icons.Function;
        algorithm
          g := h_pTX(state.p, state.T, state.X) - state.T * specificEntropy(state);
          annotation(smoothOrder = 2, Documentation(info = "<html>
        The Gibbs Energy is computed from the thermodynamic state record for moist air with a water content below saturation.
        </html>"));
        end specificGibbsEnergy;

        redeclare function extends specificHelmholtzEnergy  "Return specific Helmholtz energy as a function of the thermodynamic state record, only valid for phi<1"
          extends Modelica.Icons.Function;
        algorithm
          f := h_pTX(state.p, state.T, state.X) - gasConstant(state) * state.T - state.T * specificEntropy(state);
          annotation(smoothOrder = 2, Documentation(info = "<html>
        The Specific Helmholtz Energy is computed from the thermodynamic state record for moist air with a water content below saturation.
        </html>"));
        end specificHelmholtzEnergy;

        redeclare function extends specificHeatCapacityCp  "Return specific heat capacity at constant pressure as a function of the thermodynamic state record"
        protected
          Real dT(unit = "s/K") = 1.0;
        algorithm
          cp := h_pTX_der(state.p, state.T, state.X, 0.0, 1.0, zeros(size(state.X, 1))) * dT "Definition of cp: dh/dT @ constant p";
          annotation(Inline = false, smoothOrder = 2, Documentation(info = "<html>
        The specific heat capacity at constant pressure <b>cp</b> is computed from temperature and composition for a mixture of steam (X[1]) and dry air. All water is assumed to be in the vapor state.
        </html>"));
        end specificHeatCapacityCp;

        redeclare function extends specificHeatCapacityCv  "Return specific heat capacity at constant volume as a function of the thermodynamic state record"
        algorithm
          cv := Modelica.Media.IdealGases.Common.Functions.cp_Tlow(dryair, state.T) * (1 - state.X[Water]) + Modelica.Media.IdealGases.Common.Functions.cp_Tlow(steam, state.T) * state.X[Water] - gasConstant(state);
          annotation(Inline = false, smoothOrder = 2, Documentation(info = "<html>
        The specific heat capacity at constant density <b>cv</b> is computed from temperature and composition for a mixture of steam (X[1]) and dry air. All water is assumed to be in the vapor state.
        </html>"));
        end specificHeatCapacityCv;

        redeclare function extends dynamicViscosity  "Return dynamic viscosity as a function of the thermodynamic state record, valid from 123.15 K to 1273.15 K"
        algorithm
          eta := 1e-6 * .Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluateWithRange({9.7391102886305869E-15, -3.1353724870333906E-11, 4.3004876595642225E-08, -3.8228016291758240E-05, 5.0427874367180762E-02, 1.7239260139242528E+01}, .Modelica.SIunits.Conversions.to_degC(123.15), .Modelica.SIunits.Conversions.to_degC(1273.15), .Modelica.SIunits.Conversions.to_degC(state.T));
          annotation(smoothOrder = 2, Documentation(info = "<html>
        <p>Dynamic viscosity is computed from temperature using a simple polynomial for dry air. Range of validity is from 123.15 K to 1273.15 K. The influence of pressure and moisture is neglected. </p>
        <p>Source: VDI Waermeatlas, 8th edition. </p>
        </html>"));
        end dynamicViscosity;

        redeclare function extends thermalConductivity  "Return thermal conductivity as a function of the thermodynamic state record, valid from 123.15 K to 1273.15 K"
        algorithm
          lambda := 1e-3 * .Modelica.Media.Incompressible.TableBased.Polynomials_Temp.evaluateWithRange({6.5691470817717812E-15, -3.4025961923050509E-11, 5.3279284846303157E-08, -4.5340839289219472E-05, 7.6129675309037664E-02, 2.4169481088097051E+01}, .Modelica.SIunits.Conversions.to_degC(123.15), .Modelica.SIunits.Conversions.to_degC(1273.15), .Modelica.SIunits.Conversions.to_degC(state.T));
          annotation(smoothOrder = 2, Documentation(info = "<html>
        <p>Thermal conductivity is computed from temperature using a simple polynomial for dry air. Range of validity is from 123.15 K to 1273.15 K. The influence of pressure and moisture is neglected. </p>
        <p>Source: VDI Waermeatlas, 8th edition. </p>
        </html>"));
        end thermalConductivity;

        redeclare function extends velocityOfSound
        algorithm
          a := sqrt(isentropicExponent(state) * gasConstant(state) * temperature(state));
          annotation(Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end velocityOfSound;

        redeclare function extends isobaricExpansionCoefficient
        algorithm
          beta := 1 / temperature(state);
          annotation(Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end isobaricExpansionCoefficient;

        redeclare function extends isothermalCompressibility
        algorithm
          kappa := 1 / pressure(state);
          annotation(Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end isothermalCompressibility;

        redeclare function extends density_derp_h
        algorithm
          ddph := 1 / (gasConstant(state) * temperature(state));
          annotation(Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end density_derp_h;

        redeclare function extends density_derh_p
        algorithm
          ddhp := -density(state) / (specificHeatCapacityCp(state) * temperature(state));
          annotation(Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end density_derh_p;

        redeclare function extends density_derp_T
        algorithm
          ddpT := 1 / (gasConstant(state) * temperature(state));
          annotation(Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end density_derp_T;

        redeclare function extends density_derT_p
        algorithm
          ddTp := -density(state) / temperature(state);
          annotation(Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end density_derT_p;

        redeclare function extends density_derX
        algorithm
          dddX[Water] := pressure(state) * (steam.R - dryair.R) / ((steam.R - dryair.R) * state.X[Water] * temperature(state) + dryair.R * temperature(state)) ^ 2;
          dddX[Air] := pressure(state) * (dryair.R - steam.R) / ((dryair.R - steam.R) * state.X[Air] * temperature(state) + steam.R * temperature(state)) ^ 2;
          annotation(Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end density_derX;

        redeclare function extends molarMass
        algorithm
          MM := Modelica.Media.Air.MoistAir.gasConstant(state) / Modelica.Constants.R;
          annotation(Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end molarMass;

        function T_psX  "Return temperature as a function of pressure p, specific entropy s and composition X"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          input MassFraction[:] X "Mass fractions of composition";
          output Temperature T "Temperature";

        protected
          package Internal  "Solve s(data,T) for T with given s"
            extends Modelica.Media.Common.OneNonLinearEquation;

            redeclare record extends f_nonlinear_Data  "Data to be passed to non-linear function"
              extends Modelica.Media.IdealGases.Common.DataRecord;
            end f_nonlinear_Data;

            redeclare function extends f_nonlinear
            algorithm
              y := s_pTX(p, x, X);
            end f_nonlinear;

            redeclare function extends solve  end solve;
          end Internal;
        algorithm
          T := Internal.solve(s, 190, 647, p, X[1:nX], steam);
          annotation(Documentation(info = "<html>
        Temperature is computed from pressure, specific entropy and composition via numerical inversion of function <a href=\"modelica://Modelica.Media.Air.MoistAir.specificEntropy\">specificEntropy</a>.
        </html>", revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end T_psX;

        redeclare function extends setState_psX
        algorithm
          state := if size(X, 1) == nX then ThermodynamicState(p = p, T = T_psX(p, s, X), X = X) else ThermodynamicState(p = p, T = T_psX(p, s, X), X = cat(1, X, {1 - sum(X)}));
          annotation(smoothOrder = 2, Documentation(info = "<html>
        The <a href=\"modelica://Modelica.Media.Air.MoistAir.ThermodynamicState\">thermodynamic state record</a> is computed from pressure p, specific enthalpy h and composition X.
        </html>", revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end setState_psX;

        function s_pTX  "Return specific entropy of moist air as a function of pressure p, temperature T and composition X (only valid for phi<1)"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input .Modelica.SIunits.MassFraction[:] X "Mass fractions of moist air";
          output .Modelica.SIunits.SpecificEntropy s "Specific entropy at p, T, X";
        protected
          MoleFraction[2] Y = massToMoleFractions(X, {steam.MM, dryair.MM}) "Molar fraction";
        algorithm
          s := Modelica.Media.IdealGases.Common.Functions.s0_Tlow(dryair, T) * (1 - X[Water]) + Modelica.Media.IdealGases.Common.Functions.s0_Tlow(steam, T) * X[Water] - Modelica.Constants.R * (Utilities.smoothMax(X[Water] / MMX[Water] * Modelica.Math.log(max(Y[Water], Modelica.Constants.eps) * p / reference_p), 0.0, 1e-9) - Utilities.smoothMax((1 - X[Water]) / MMX[Air] * Modelica.Math.log(max(Y[Air], Modelica.Constants.eps) * p / reference_p), 0.0, 1e-9));
          annotation(derivative = s_pTX_der, Inline = false, Documentation(info = "<html>
        Specific entropy of moist air is computed from pressure, temperature and composition with X[1] as the total water mass fraction.
        </html>", revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"), Icon(graphics = {Text(extent = {{-100, 100}, {100, -100}}, lineColor = {255, 127, 0}, textString = "f")}));
        end s_pTX;

        function s_pTX_der  "Return specific entropy of moist air as a function of pressure p, temperature T and composition X (only valid for phi<1)"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input .Modelica.SIunits.MassFraction[:] X "Mass fractions of moist air";
          input Real dp(unit = "Pa/s") "Derivative of pressure";
          input Real dT(unit = "K/s") "Derivative of temperature";
          input Real[nX] dX(unit = "1/s") "Derivative of mass fractions";
          output Real ds(unit = "J/(kg.K.s)") "Specific entropy at p, T, X";
        protected
          MoleFraction[2] Y = massToMoleFractions(X, {steam.MM, dryair.MM}) "Molar fraction";
        algorithm
          ds := Modelica.Media.IdealGases.Common.Functions.s0_Tlow_der(dryair, T, dT) * (1 - X[Water]) + Modelica.Media.IdealGases.Common.Functions.s0_Tlow_der(steam, T, dT) * X[Water] + Modelica.Media.IdealGases.Common.Functions.s0_Tlow(dryair, T) * dX[Air] + Modelica.Media.IdealGases.Common.Functions.s0_Tlow(steam, T) * dX[Water] - Modelica.Constants.R * (1 / MMX[Water] * Utilities.smoothMax_der(X[Water] * Modelica.Math.log(max(Y[Water], Modelica.Constants.eps) * p / reference_p), 0.0, 1e-9, (Modelica.Math.log(max(Y[Water], Modelica.Constants.eps) * p / reference_p) + X[Water] / Y[Water] * (X[Air] * MMX[Water] / (X[Air] * MMX[Water] + X[Water] * MMX[Air]) ^ 2)) * dX[Water] + X[Water] * reference_p / p * dp, 0, 0) - 1 / MMX[Air] * Utilities.smoothMax_der((1 - X[Water]) * Modelica.Math.log(max(Y[Air], Modelica.Constants.eps) * p / reference_p), 0.0, 1e-9, (Modelica.Math.log(max(Y[Air], Modelica.Constants.eps) * p / reference_p) + X[Air] / Y[Air] * (X[Water] * MMX[Air] / (X[Air] * MMX[Water] + X[Water] * MMX[Air]) ^ 2)) * dX[Air] + X[Air] * reference_p / p * dp, 0, 0));
          annotation(Inline = false, smoothOrder = 1, Documentation(info = "<html>
        Specific entropy of moist air is computed from pressure, temperature and composition with X[1] as the total water mass fraction.
        </html>", revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"), Icon(graphics = {Text(extent = {{-100, 100}, {100, -100}}, lineColor = {255, 127, 0}, textString = "f")}));
        end s_pTX_der;

        redeclare function extends isentropicEnthalpy  "Isentropic enthalpy (only valid for phi<1)"
          extends Modelica.Icons.Function;
        algorithm
          h_is := Modelica.Media.Air.MoistAir.h_pTX(p_downstream, Modelica.Media.Air.MoistAir.T_psX(p_downstream, Modelica.Media.Air.MoistAir.specificEntropy(refState), refState.X), refState.X);
          annotation(Icon(graphics = {Text(extent = {{-100, 100}, {100, -100}}, lineColor = {255, 127, 0}, textString = "f")}), Documentation(revisions = "<html>
        <p>2012-01-12        Stefan Wischhusen: Initial Release.</p>
        </html>"));
        end isentropicEnthalpy;

        package Utilities  "Utility functions"
          extends Modelica.Icons.UtilitiesPackage;

          function spliceFunction  "Spline interpolation of two functions"
            extends Modelica.Icons.Function;
            input Real pos "Returned value for x-deltax >= 0";
            input Real neg "Returned value for x+deltax <= 0";
            input Real x "Function argument";
            input Real deltax = 1 "Region around x with spline interpolation";
            output Real out;
          protected
            Real scaledX;
            Real scaledX1;
            Real y;
          algorithm
            scaledX1 := x / deltax;
            scaledX := scaledX1 * Modelica.Math.asin(1);
            if scaledX1 <= (-0.999999999) then
              y := 0;
            elseif scaledX1 >= 0.999999999 then
              y := 1;
            else
              y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX)) + 1) / 2;
            end if;
            out := pos * y + (1 - y) * neg;
            annotation(derivative = spliceFunction_der);
          end spliceFunction;

          function spliceFunction_der  "Derivative of spliceFunction"
            extends Modelica.Icons.Function;
            input Real pos;
            input Real neg;
            input Real x;
            input Real deltax = 1;
            input Real dpos;
            input Real dneg;
            input Real dx;
            input Real ddeltax = 0;
            output Real out;
          protected
            Real scaledX;
            Real scaledX1;
            Real dscaledX1;
            Real y;
          algorithm
            scaledX1 := x / deltax;
            scaledX := scaledX1 * Modelica.Math.asin(1);
            dscaledX1 := (dx - scaledX1 * ddeltax) / deltax;
            if scaledX1 <= (-0.99999999999) then
              y := 0;
            elseif scaledX1 >= 0.9999999999 then
              y := 1;
            else
              y := (Modelica.Math.tanh(Modelica.Math.tan(scaledX)) + 1) / 2;
            end if;
            out := dpos * y + (1 - y) * dneg;
            if abs(scaledX1) < 1 then
              out := out + (pos - neg) * dscaledX1 * Modelica.Math.asin(1) / 2 / (Modelica.Math.cosh(Modelica.Math.tan(scaledX)) * Modelica.Math.cos(scaledX)) ^ 2;
            else
            end if;
          end spliceFunction_der;

          function smoothMax
            extends Modelica.Icons.Function;
            input Real x1 "First argument of smooth max operator";
            input Real x2 "Second argument of smooth max operator";
            input Real dx "Approximate difference between x1 and x2, below which regularization starts";
            output Real y "Result of smooth max operator";
          algorithm
            y := max(x1, x2) + .Modelica.Math.log(exp(4 / dx * (x1 - max(x1, x2))) + exp(4 / dx * (x2 - max(x1, x2)))) / (4 / dx);
            annotation(smoothOrder = 2, Documentation(info = "<html>
          <p>An implementation of Kreisselmeier Steinhauser smooth maximum</p>
          </html>"));
          end smoothMax;

          function smoothMax_der
            extends Modelica.Icons.Function;
            input Real x1 "First argument of smooth max operator";
            input Real x2 "Second argument of smooth max operator";
            input Real dx "Approximate difference between x1 and x2, below which regularization starts";
            input Real dx1;
            input Real dx2;
            input Real ddx;
            output Real dy "Derivative of smooth max operator";
          algorithm
            dy := (if x1 > x2 then dx1 else dx2) + 0.25 * (((4 * (dx1 - (if x1 > x2 then dx1 else dx2)) / dx - 4 * (x1 - max(x1, x2)) * ddx / dx ^ 2) * .Modelica.Math.exp(4 * (x1 - max(x1, x2)) / dx) + (4 * (dx2 - (if x1 > x2 then dx1 else dx2)) / dx - 4 * (x2 - max(x1, x2)) * ddx / dx ^ 2) * .Modelica.Math.exp(4 * (x2 - max(x1, x2)) / dx)) * dx / (.Modelica.Math.exp(4 * (x1 - max(x1, x2)) / dx) + .Modelica.Math.exp(4 * (x2 - max(x1, x2)) / dx)) + .Modelica.Math.log(.Modelica.Math.exp(4 * (x1 - max(x1, x2)) / dx) + .Modelica.Math.exp(4 * (x2 - max(x1, x2)) / dx)) * ddx);
            annotation(Documentation(info = "<html>
          <p>An implementation of Kreisselmeier Steinhauser smooth maximum</p>
          </html>"));
          end smoothMax_der;
        end Utilities;
        annotation(Documentation(info = "<html>
      <h4>Thermodynamic Model</h4>
      <p>This package provides a full thermodynamic model of moist air including the fog region and temperatures below zero degC.
      The governing assumptions in this model are:</p>
      <ul>
      <li>the perfect gas law applies</li>
      <li>water volume other than that of steam is neglected</li></ul>
      <p>All extensive properties are expressed in terms of the total mass in order to comply with other media in this library. However, for moist air it is rather common to express the absolute humidity in terms of mass of dry air only, which has advantages when working with charts. In addition, care must be taken, when working with mass fractions with respect to total mass, that all properties refer to the same water content when being used in mathematical operations (which is always the case if based on dry air only). Therefore two absolute humidities are computed in the <b>BaseProperties</b> model: <b>X</b> denotes the absolute humidity in terms of the total mass while <b>x</b> denotes the absolute humidity per unit mass of dry air. In addition, the relative humidity <b>phi</b> is also computed.</p>
      <p>At the triple point temperature of water of 0.01 &deg;C or 273.16 K and a relative humidity greater than 1 fog may be present as liquid and as ice resulting in a specific enthalpy somewhere between those of the two isotherms for solid and liquid fog, respectively. For numerical reasons a coexisting mixture of 50% solid and 50% liquid fog is assumed in the fog region at the triple point in this model.</p>

      <h4>Range of validity</h4>
      <p>From the assumptions mentioned above it follows that the <b>pressure</b> should be in the region around <b>atmospheric</b> conditions or below (a few bars may still be fine though). Additionally a very high water content at low temperatures would yield incorrect densities, because the volume of the liquid or solid phase would not be negligible anymore. The model does not provide information on limits for water drop size in the fog region or transport information for the actual condensation or evaporation process in combination with surfaces. All excess water which is not in its vapour state is assumed to be still present in the air regarding its energy but not in terms of its spatial extent.<br><br>
      The thermodynamic model may be used for <b>temperatures</b> ranging from <b>190 ... 647 K</b>. This holds for all functions unless otherwise stated in their description. However, although the model works at temperatures above the saturation temperature it is questionable to use the term \"relative humidity\" in this region. Please note, that although several functions compute pure water properties, they are designed to be used within the moist air medium model where properties are dominated by air and steam in their vapor states, and not for pure liquid water applications.</p>

      <h4>Transport Properties</h4>
      <p>Several additional functions that are not needed to describe the thermodynamic system, but are required to model transport processes, like heat and mass transfer, may be called. They usually neglect the moisture influence unless otherwise stated.</p>

      <h4>Application</h4>
      <p>The model's main area of application is all processes that involve moist air cooling under near atmospheric pressure with possible moisture condensation. This is the case in all domestic and industrial air conditioning applications. Another large domain of moist air applications covers all processes that deal with dehydration of bulk material using air as a transport medium. Engineering tasks involving moist air are often performed (or at least visualized) by using charts that contain all relevant thermodynamic data for a moist air system. These so called psychrometric charts can be generated from the medium properties in this package. The model <a href=\"modelica://Modelica.Media.Examples.PsychrometricData\">PsychrometricData</a> may be used for this purpose in order to obtain data for figures like those below (the plotting itself is not part of the model though).</p>

      <p>
      <img src=\"modelica://Modelica/Resources/Images/Media/Air/Mollier.png\"><br>
      <img src=\"modelica://Modelica/Resources/Images/Media/Air/PsycroChart.png\">
      </p>

      <p>
      <b>Legend:</b> blue - constant specific enthalpy, red - constant temperature, black - constant relative humidity</p>

      </html>"));
      end MoistAir;
      annotation(Documentation(info = "<html>
      <p>This package contains different medium models for air:</p>
    <ul>
    <li><b>SimpleAir</b><br>
        Simple dry air medium in a limited temperature range.</li>
    <li><b>DryAirNasa</b><br>
        Dry air as an ideal gas from Media.IdealGases.MixtureGases.Air.</li>
    <li><b>MoistAir</b><br>
        Moist air as an ideal gas mixture of steam and dry air with fog below and above the triple point temperature.</li>
    </ul>
    </html>"));
    end Air;

    package IdealGases  "Data and models of ideal gases (single, fixed and dynamic mixtures) from NASA source"
      extends Modelica.Icons.VariantsPackage;

      package Common  "Common packages and data for the ideal gas models"
        extends Modelica.Icons.Package;

        record DataRecord  "Coefficient data record for properties of ideal gases based on NASA source"
          extends Modelica.Icons.Record;
          String name "Name of ideal gas";
          .Modelica.SIunits.MolarMass MM "Molar mass";
          .Modelica.SIunits.SpecificEnthalpy Hf "Enthalpy of formation at 298.15K";
          .Modelica.SIunits.SpecificEnthalpy H0 "H0(298.15K) - H0(0K)";
          .Modelica.SIunits.Temperature Tlimit "Temperature limit between low and high data sets";
          Real[7] alow "Low temperature coefficients a";
          Real[2] blow "Low temperature constants b";
          Real[7] ahigh "High temperature coefficients a";
          Real[2] bhigh "High temperature constants b";
          .Modelica.SIunits.SpecificHeatCapacity R "Gas constant";
          annotation(Documentation(info = "<HTML>
        <p>
        This data record contains the coefficients for the
        ideal gas equations according to:
        </p>
        <blockquote>
          <p>McBride B.J., Zehe M.J., and Gordon S. (2002): <b>NASA Glenn Coefficients
          for Calculating Thermodynamic Properties of Individual Species</b>. NASA
          report TP-2002-211556</p>
        </blockquote>
        <p>
        The equations have the following structure:
        </p>
        <IMG src=\"modelica://Modelica/Resources/Images/Media/IdealGases/singleEquations.png\">
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
        </HTML>"));
        end DataRecord;

        package Functions  "Basic Functions for ideal gases: cp, h, s, thermal conductivity, viscosity"
          extends Modelica.Icons.Package;
          constant Boolean excludeEnthalpyOfFormation = true "If true, enthalpy of formation Hf is not included in specific enthalpy h";
          constant Modelica.Media.Interfaces.Choices.ReferenceEnthalpy referenceChoice = Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K "Choice of reference enthalpy";
          constant Modelica.Media.Interfaces.Types.SpecificEnthalpy h_offset = 0.0 "User defined offset for reference enthalpy, if referenceChoice = UserDefined";

          function cp_Tlow  "Compute specific heat capacity at constant pressure, low T region"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input .Modelica.SIunits.Temperature T "Temperature";
            output .Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity at temperature T";
          algorithm
            cp := data.R * (1 / (T * T) * (data.alow[1] + T * (data.alow[2] + T * (1. * data.alow[3] + T * (data.alow[4] + T * (data.alow[5] + T * (data.alow[6] + data.alow[7] * T)))))));
            annotation(Inline = false, derivative(zeroDerivative = data) = cp_Tlow_der);
          end cp_Tlow;

          function cp_Tlow_der  "Compute specific heat capacity at constant pressure, low T region"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input .Modelica.SIunits.Temperature T "Temperature";
            input Real dT "Temperature derivative";
            output Real cp_der "Derivative of specific heat capacity";
          algorithm
            cp_der := dT * data.R / (T * T * T) * ((-2 * data.alow[1]) + T * ((-data.alow[2]) + T * T * (data.alow[4] + T * (2. * data.alow[5] + T * (3. * data.alow[6] + 4. * data.alow[7] * T)))));
            annotation(smoothOrder = 2);
          end cp_Tlow_der;

          function h_Tlow  "Compute specific enthalpy, low T region; reference is decided by the
              refChoice input, or by the referenceChoice package constant by default"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input .Modelica.SIunits.Temperature T "Temperature";
            input Boolean exclEnthForm = excludeEnthalpyOfFormation "If true, enthalpy of formation Hf is not included in specific enthalpy h";
            input Modelica.Media.Interfaces.Choices.ReferenceEnthalpy refChoice = referenceChoice "Choice of reference enthalpy";
            input .Modelica.SIunits.SpecificEnthalpy h_off = h_offset "User defined offset for reference enthalpy, if referenceChoice = UserDefined";
            output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy at temperature T";
          algorithm
            h := data.R * (((-data.alow[1]) + T * (data.blow[1] + data.alow[2] * Math.log(T) + T * (1. * data.alow[3] + T * (0.5 * data.alow[4] + T * (1 / 3 * data.alow[5] + T * (0.25 * data.alow[6] + 0.2 * data.alow[7] * T)))))) / T) + (if exclEnthForm then -data.Hf else 0.0) + (if refChoice == .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.ZeroAt0K then data.H0 else 0.0) + (if refChoice == .Modelica.Media.Interfaces.Choices.ReferenceEnthalpy.UserDefined then h_off else 0.0);
            annotation(Inline = false, smoothOrder = 2);
          end h_Tlow;

          function h_Tlow_der  "Compute specific enthalpy, low T region; reference is decided by the
              refChoice input, or by the referenceChoice package constant by default"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input .Modelica.SIunits.Temperature T "Temperature";
            input Boolean exclEnthForm = excludeEnthalpyOfFormation "If true, enthalpy of formation Hf is not included in specific enthalpy h";
            input Modelica.Media.Interfaces.Choices.ReferenceEnthalpy refChoice = referenceChoice "Choice of reference enthalpy";
            input .Modelica.SIunits.SpecificEnthalpy h_off = h_offset "User defined offset for reference enthalpy, if referenceChoice = UserDefined";
            input Real dT(unit = "K/s") "Temperature derivative";
            output Real h_der(unit = "J/(kg.s)") "Derivative of specific enthalpy at temperature T";
          algorithm
            h_der := dT * Modelica.Media.IdealGases.Common.Functions.cp_Tlow(data, T);
            annotation(Inline = true, smoothOrder = 2);
          end h_Tlow_der;

          function s0_Tlow  "Compute specific entropy, low T region"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input .Modelica.SIunits.Temperature T "Temperature";
            output .Modelica.SIunits.SpecificEntropy s "Specific entropy at temperature T";
          algorithm
            s := data.R * (data.blow[2] - 0.5 * data.alow[1] / (T * T) - data.alow[2] / T + data.alow[3] * Math.log(T) + T * (data.alow[4] + T * (0.5 * data.alow[5] + T * (1 / 3 * data.alow[6] + 0.25 * data.alow[7] * T))));
            annotation(Inline = true);
          end s0_Tlow;

          function s0_Tlow_der  "Compute derivative of specific entropy, low T region"
            extends Modelica.Icons.Function;
            input IdealGases.Common.DataRecord data "Ideal gas data";
            input .Modelica.SIunits.Temperature T "Temperature";
            input Real T_der "Temperature derivative";
            output .Modelica.SIunits.SpecificEntropy s "Specific entropy at temperature T";
          algorithm
            s := data.R * (data.blow[2] - 0.5 * data.alow[1] / (T * T) - data.alow[2] / T + data.alow[3] * Math.log(T) + T * (data.alow[4] + T * (0.5 * data.alow[5] + T * (1 / 3 * data.alow[6] + 0.25 * data.alow[7] * T))));
            annotation(Inline = true);
          end s0_Tlow_der;
        end Functions;

        package FluidData  "Critical data, dipole moments and related data"
          extends Modelica.Icons.Package;
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants N2(chemicalFormula = "N2", iupacName = "unknown", structureFormula = "unknown", casRegistryNumber = "7727-37-9", meltingPoint = 63.15, normalBoilingPoint = 77.35, criticalTemperature = 126.20, criticalPressure = 33.98e5, criticalMolarVolume = 90.10e-6, acentricFactor = 0.037, dipoleMoment = 0.0, molarMass = SingleGasesData.N2.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true);
          constant Modelica.Media.Interfaces.Types.IdealGas.FluidConstants H2O(chemicalFormula = "H2O", iupacName = "oxidane", structureFormula = "H2O", casRegistryNumber = "7732-18-5", meltingPoint = 273.15, normalBoilingPoint = 373.124, criticalTemperature = 647.096, criticalPressure = 220.64e5, criticalMolarVolume = 55.95e-6, acentricFactor = 0.344, dipoleMoment = 1.8, molarMass = SingleGasesData.H2O.MM, hasDipoleMoment = true, hasIdealGasHeatCapacity = true, hasCriticalData = true, hasAcentricFactor = true);
          annotation(Documentation(info = "<html>
        <p>
        This package contains FluidConstants data records for the following 37 gases
        (see also the description in
        <a href=\"modelica://Modelica.Media.IdealGases\">Modelica.Media.IdealGases</a>):
        </p>
        <pre>
        Argon             Methane          Methanol       Carbon Monoxide  Carbon Dioxide
        Acetylene         Ethylene         Ethanol        Ethane           Propylene
        Propane           1-Propanol       1-Butene       N-Butane         1-Pentene
        N-Pentane         Benzene          1-Hexene       N-Hexane         1-Heptane
        N-Heptane         Ethylbenzene     N-Octane       Chlorine         Fluorine
        Hydrogen          Steam            Helium         Ammonia          Nitric Oxide
        Nitrogen Dioxide  Nitrogen         Nitrous        Oxide            Neon Oxygen
        Sulfur Dioxide    Sulfur Trioxide
        </pre>

        </html>"));
        end FluidData;

        package SingleGasesData  "Ideal gas data based on the NASA Glenn coefficients"
          extends Modelica.Icons.Package;
          constant IdealGases.Common.DataRecord Air(name = "Air", MM = 0.0289651159, Hf = -4333.833858403446, H0 = 298609.6803431054, Tlimit = 1000, alow = {10099.5016, -196.827561, 5.00915511, -0.00576101373, 1.06685993e-005, -7.94029797e-009, 2.18523191e-012}, blow = {-176.796731, -3.921504225}, ahigh = {241521.443, -1257.8746, 5.14455867, -0.000213854179, 7.06522784e-008, -1.07148349e-011, 6.57780015e-016}, bhigh = {6462.26319, -8.147411905}, R = 287.0512249529787);
          constant IdealGases.Common.DataRecord Ar(name = "Ar", MM = 0.039948, Hf = 0, H0 = 155137.3785921698, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 4.37967491}, ahigh = {20.10538475, -0.05992661069999999, 2.500069401, -3.99214116e-008, 1.20527214e-011, -1.819015576e-015, 1.078576636e-019}, bhigh = {-744.993961, 4.37918011}, R = 208.1323720837088);
          constant IdealGases.Common.DataRecord CH4(name = "CH4", MM = 0.01604246, Hf = -4650159.63885838, H0 = 624355.7409524474, Tlimit = 1000, alow = {-176685.0998, 2786.18102, -12.0257785, 0.0391761929, -3.61905443e-005, 2.026853043e-008, -4.976705489999999e-012}, blow = {-23313.1436, 89.0432275}, ahigh = {3730042.76, -13835.01485, 20.49107091, -0.001961974759, 4.72731304e-007, -3.72881469e-011, 1.623737207e-015}, bhigh = {75320.6691, -121.9124889}, R = 518.2791167938085);
          constant IdealGases.Common.DataRecord CH3OH(name = "CH3OH", MM = 0.03204186, Hf = -6271171.523750494, H0 = 356885.5553329301, Tlimit = 1000, alow = {-241664.2886, 4032.14719, -20.46415436, 0.0690369807, -7.59893269e-005, 4.59820836e-008, -1.158706744e-011}, blow = {-44332.61169999999, 140.014219}, ahigh = {3411570.76, -13455.00201, 22.61407623, -0.002141029179, 3.73005054e-007, -3.49884639e-011, 1.366073444e-015}, bhigh = {56360.8156, -127.7814279}, R = 259.4878075117987);
          constant IdealGases.Common.DataRecord CO(name = "CO", MM = 0.0280101, Hf = -3946262.098314536, H0 = 309570.6191695138, Tlimit = 1000, alow = {14890.45326, -292.2285939, 5.72452717, -0.008176235030000001, 1.456903469e-005, -1.087746302e-008, 3.027941827e-012}, blow = {-13031.31878, -7.85924135}, ahigh = {461919.725, -1944.704863, 5.91671418, -0.0005664282830000001, 1.39881454e-007, -1.787680361e-011, 9.62093557e-016}, bhigh = {-2466.261084, -13.87413108}, R = 296.8383547363272);
          constant IdealGases.Common.DataRecord CO2(name = "CO2", MM = 0.0440095, Hf = -8941478.544405185, H0 = 212805.6215135368, Tlimit = 1000, alow = {49436.5054, -626.411601, 5.30172524, 0.002503813816, -2.127308728e-007, -7.68998878e-010, 2.849677801e-013}, blow = {-45281.9846, -7.04827944}, ahigh = {117696.2419, -1788.791477, 8.29152319, -9.22315678e-005, 4.86367688e-009, -1.891053312e-012, 6.330036589999999e-016}, bhigh = {-39083.5059, -26.52669281}, R = 188.9244822140674);
          constant IdealGases.Common.DataRecord C2H2_vinylidene(name = "C2H2_vinylidene", MM = 0.02603728, Hf = 15930556.80163212, H0 = 417638.4015534649, Tlimit = 1000, alow = {-14660.42239, 278.9475593, 1.276229776, 0.01395015463, -1.475702649e-005, 9.476298110000001e-009, -2.567602217e-012}, blow = {47361.1018, 16.58225704}, ahigh = {1940838.725, -6892.718150000001, 13.39582494, -0.0009368968669999999, 1.470804368e-007, -1.220040365e-011, 4.12239166e-016}, bhigh = {91071.1293, -63.3750293}, R = 319.3295152181795);
          constant IdealGases.Common.DataRecord C2H4(name = "C2H4", MM = 0.02805316, Hf = 1871446.924339362, H0 = 374955.5843263291, Tlimit = 1000, alow = {-116360.5836, 2554.85151, -16.09746428, 0.0662577932, -7.885081859999999e-005, 5.12522482e-008, -1.370340031e-011}, blow = {-6176.19107, 109.3338343}, ahigh = {3408763.67, -13748.47903, 23.65898074, -0.002423804419, 4.43139566e-007, -4.35268339e-011, 1.775410633e-015}, bhigh = {88204.2938, -137.1278108}, R = 296.3827247982046);
          constant IdealGases.Common.DataRecord C2H6(name = "C2H6", MM = 0.03006904, Hf = -2788633.890539904, H0 = 395476.3437741943, Tlimit = 1000, alow = {-186204.4161, 3406.19186, -19.51705092, 0.0756583559, -8.20417322e-005, 5.0611358e-008, -1.319281992e-011}, blow = {-27029.3289, 129.8140496}, ahigh = {5025782.13, -20330.22397, 33.2255293, -0.00383670341, 7.23840586e-007, -7.3191825e-011, 3.065468699e-015}, bhigh = {111596.395, -203.9410584}, R = 276.5127187299628);
          constant IdealGases.Common.DataRecord C2H5OH(name = "C2H5OH", MM = 0.04606844, Hf = -5100020.751733725, H0 = 315659.1801241805, Tlimit = 1000, alow = {-234279.1392, 4479.18055, -27.44817302, 0.1088679162, -0.0001305309334, 8.437346399999999e-008, -2.234559017e-011}, blow = {-50222.29, 176.4829211}, ahigh = {4694817.65, -19297.98213, 34.4758404, -0.00323616598, 5.78494772e-007, -5.56460027e-011, 2.2262264e-015}, bhigh = {86016.22709999999, -203.4801732}, R = 180.4808671619877);
          constant IdealGases.Common.DataRecord C3H6_propylene(name = "C3H6_propylene", MM = 0.04207974, Hf = 475288.1077687267, H0 = 322020.9535515191, Tlimit = 1000, alow = {-191246.2174, 3542.07424, -21.14878626, 0.0890148479, -0.0001001429154, 6.267959389999999e-008, -1.637870781e-011}, blow = {-15299.61824, 140.7641382}, ahigh = {5017620.34, -20860.84035, 36.4415634, -0.00388119117, 7.27867719e-007, -7.321204500000001e-011, 3.052176369e-015}, bhigh = {126124.5355, -219.5715757}, R = 197.588483198803);
          constant IdealGases.Common.DataRecord C3H8(name = "C3H8", MM = 0.04409562, Hf = -2373931.923397381, H0 = 334301.1845620949, Tlimit = 1000, alow = {-243314.4337, 4656.27081, -29.39466091, 0.1188952745, -0.0001376308269, 8.814823909999999e-008, -2.342987994e-011}, blow = {-35403.3527, 184.1749277}, ahigh = {6420731.680000001, -26597.91134, 45.3435684, -0.00502066392, 9.471216939999999e-007, -9.57540523e-011, 4.00967288e-015}, bhigh = {145558.2459, -281.8374734}, R = 188.5555073270316);
          constant IdealGases.Common.DataRecord C4H8_1_butene(name = "C4H8_1_butene", MM = 0.05610631999999999, Hf = -9624.584182316718, H0 = 305134.9651875226, Tlimit = 1000, alow = {-272149.2014, 5100.079250000001, -31.8378625, 0.1317754442, -0.0001527359339, 9.714761109999999e-008, -2.56020447e-011}, blow = {-25230.96386, 200.6932108}, ahigh = {6257948.609999999, -26603.76305, 47.6492005, -0.00438326711, 7.12883844e-007, -5.991020839999999e-011, 2.051753504e-015}, bhigh = {156925.2657, -291.3869761}, R = 148.1913623991023);
          constant IdealGases.Common.DataRecord C4H10_n_butane(name = "C4H10_n_butane", MM = 0.0581222, Hf = -2164233.28779709, H0 = 330832.0228759407, Tlimit = 1000, alow = {-317587.254, 6176.331819999999, -38.9156212, 0.1584654284, -0.0001860050159, 1.199676349e-007, -3.20167055e-011}, blow = {-45403.63390000001, 237.9488665}, ahigh = {7682322.45, -32560.5151, 57.3673275, -0.00619791681, 1.180186048e-006, -1.221893698e-010, 5.250635250000001e-015}, bhigh = {177452.656, -358.791876}, R = 143.0515706563069);
          constant IdealGases.Common.DataRecord C5H10_1_pentene(name = "C5H10_1_pentene", MM = 0.07013290000000001, Hf = -303423.9279995551, H0 = 309127.3852927798, Tlimit = 1000, alow = {-534054.813, 9298.917380000001, -56.6779245, 0.2123100266, -0.000257129829, 1.666834304e-007, -4.43408047e-011}, blow = {-47906.8218, 339.60364}, ahigh = {3744014.97, -21044.85321, 47.3612699, -0.00042442012, -3.89897505e-008, 1.367074243e-011, -9.31319423e-016}, bhigh = {115409.1373, -278.6177449000001}, R = 118.5530899192818);
          constant IdealGases.Common.DataRecord C5H12_n_pentane(name = "C5H12_n_pentane", MM = 0.07214878, Hf = -2034130.029641527, H0 = 335196.2430965569, Tlimit = 1000, alow = {-276889.4625, 5834.28347, -36.1754148, 0.1533339707, -0.0001528395882, 8.191092e-008, -1.792327902e-011}, blow = {-46653.7525, 226.5544053}, ahigh = {-2530779.286, -8972.59326, 45.3622326, -0.002626989916, 3.135136419e-006, -5.31872894e-010, 2.886896868e-014}, bhigh = {14846.16529, -251.6550384}, R = 115.2406457877736);
          constant IdealGases.Common.DataRecord C6H6(name = "C6H6", MM = 0.07811184, Hf = 1061042.730525872, H0 = 181735.4577743912, Tlimit = 1000, alow = {-167734.0902, 4404.50004, -37.1737791, 0.1640509559, -0.0002020812374, 1.307915264e-007, -3.4442841e-011}, blow = {-10354.55401, 216.9853345}, ahigh = {4538575.72, -22605.02547, 46.940073, -0.004206676830000001, 7.90799433e-007, -7.9683021e-011, 3.32821208e-015}, bhigh = {139146.4686, -286.8751333}, R = 106.4431717393932);
          constant IdealGases.Common.DataRecord C6H12_1_hexene(name = "C6H12_1_hexene", MM = 0.08415948000000001, Hf = -498458.4030224521, H0 = 311788.9986962847, Tlimit = 1000, alow = {-666883.165, 11768.64939, -72.70998330000001, 0.2709398396, -0.00033332464, 2.182347097e-007, -5.85946882e-011}, blow = {-62157.8054, 428.682564}, ahigh = {733290.696, -14488.48641, 46.7121549, 0.00317297847, -5.24264652e-007, 4.28035582e-011, -1.472353254e-015}, bhigh = {66977.4041, -262.3643854}, R = 98.79424159940152);
          constant IdealGases.Common.DataRecord C6H14_n_hexane(name = "C6H14_n_hexane", MM = 0.08617535999999999, Hf = -1936980.593988816, H0 = 333065.0431863586, Tlimit = 1000, alow = {-581592.67, 10790.97724, -66.3394703, 0.2523715155, -0.0002904344705, 1.802201514e-007, -4.617223680000001e-011}, blow = {-72715.4457, 393.828354}, ahigh = {-3106625.684, -7346.087920000001, 46.94131760000001, 0.001693963977, 2.068996667e-006, -4.21214168e-010, 2.452345845e-014}, bhigh = {523.750312, -254.9967718}, R = 96.48317105956971);
          constant IdealGases.Common.DataRecord C7H14_1_heptene(name = "C7H14_1_heptene", MM = 0.09818605999999999, Hf = -639194.6066478277, H0 = 313588.3036756949, Tlimit = 1000, alow = {-744940.284, 13321.79893, -82.81694379999999, 0.3108065994, -0.000378677992, 2.446841042e-007, -6.488763869999999e-011}, blow = {-72178.8501, 485.667149}, ahigh = {-1927608.174, -9125.024420000002, 47.4817797, 0.00606766053, -8.684859080000001e-007, 5.81399526e-011, -1.473979569e-015}, bhigh = {26009.14656, -256.2880707}, R = 84.68077851377274);
          constant IdealGases.Common.DataRecord C7H16_n_heptane(name = "C7H16_n_heptane", MM = 0.10020194, Hf = -1874015.612871368, H0 = 331540.487140269, Tlimit = 1000, alow = {-612743.289, 11840.85437, -74.87188599999999, 0.2918466052, -0.000341679549, 2.159285269e-007, -5.65585273e-011}, blow = {-80134.0894, 440.721332}, ahigh = {9135632.469999999, -39233.1969, 78.8978085, -0.00465425193, 2.071774142e-006, -3.4425393e-010, 1.976834775e-014}, bhigh = {205070.8295, -485.110402}, R = 82.97715593131233);
          constant IdealGases.Common.DataRecord C8H10_ethylbenz(name = "C8H10_ethylbenz", MM = 0.106165, Hf = 281825.4603682946, H0 = 209862.0072528611, Tlimit = 1000, alow = {-469494, 9307.16836, -65.2176947, 0.2612080237, -0.000318175348, 2.051355473e-007, -5.40181735e-011}, blow = {-40738.7021, 378.090436}, ahigh = {5551564.100000001, -28313.80598, 60.6124072, 0.001042112857, -1.327426719e-006, 2.166031743e-010, -1.142545514e-014}, bhigh = {164224.1062, -369.176982}, R = 78.31650732350586);
          constant IdealGases.Common.DataRecord C8H18_n_octane(name = "C8H18_n_octane", MM = 0.11422852, Hf = -1827477.060895125, H0 = 330740.51909278, Tlimit = 1000, alow = {-698664.715, 13385.01096, -84.1516592, 0.327193666, -0.000377720959, 2.339836988e-007, -6.01089265e-011}, blow = {-90262.2325, 493.922214}, ahigh = {6365406.949999999, -31053.64657, 69.6916234, 0.01048059637, -4.12962195e-006, 5.543226319999999e-010, -2.651436499e-014}, bhigh = {150096.8785, -416.989565}, R = 72.78805678301707);
          constant IdealGases.Common.DataRecord CL2(name = "CL2", MM = 0.07090600000000001, Hf = 0, H0 = 129482.8364313316, Tlimit = 1000, alow = {34628.1517, -554.7126520000001, 6.20758937, -0.002989632078, 3.17302729e-006, -1.793629562e-009, 4.260043590000001e-013}, blow = {1534.069331, -9.438331107}, ahigh = {6092569.42, -19496.27662, 28.54535795, -0.01449968764, 4.46389077e-006, -6.35852586e-010, 3.32736029e-014}, bhigh = {121211.7724, -169.0778824}, R = 117.2604857134798);
          constant IdealGases.Common.DataRecord F2(name = "F2", MM = 0.0379968064, Hf = 0, H0 = 232259.1511269747, Tlimit = 1000, alow = {10181.76308, 22.74241183, 1.97135304, 0.008151604010000001, -1.14896009e-005, 7.95865253e-009, -2.167079526e-012}, blow = {-958.6943, 11.30600296}, ahigh = {-2941167.79, 9456.5977, -7.73861615, 0.00764471299, -2.241007605e-006, 2.915845236e-010, -1.425033974e-014}, bhigh = {-60710.0561, 84.23835080000001}, R = 218.8202848542556);
          constant IdealGases.Common.DataRecord H2(name = "H2", MM = 0.00201588, Hf = 0, H0 = 4200697.462150524, Tlimit = 1000, alow = {40783.2321, -800.918604, 8.21470201, -0.01269714457, 1.753605076e-005, -1.20286027e-008, 3.36809349e-012}, blow = {2682.484665, -30.43788844}, ahigh = {560812.801, -837.150474, 2.975364532, 0.001252249124, -3.74071619e-007, 5.936625200000001e-011, -3.6069941e-015}, bhigh = {5339.82441, -2.202774769}, R = 4124.487568704486);
          constant IdealGases.Common.DataRecord H2O(name = "H2O", MM = 0.01801528, Hf = -13423382.81725291, H0 = 549760.6476280135, Tlimit = 1000, alow = {-39479.6083, 575.573102, 0.931782653, 0.00722271286, -7.34255737e-006, 4.95504349e-009, -1.336933246e-012}, blow = {-33039.7431, 17.24205775}, ahigh = {1034972.096, -2412.698562, 4.64611078, 0.002291998307, -6.836830479999999e-007, 9.426468930000001e-011, -4.82238053e-015}, bhigh = {-13842.86509, -7.97814851}, R = 461.5233290850878);
          constant IdealGases.Common.DataRecord He(name = "He", MM = 0.004002602, Hf = 0, H0 = 1548349.798456104, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 0.9287239740000001}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-745.375, 0.9287239740000001}, R = 2077.26673798694);
          constant IdealGases.Common.DataRecord NH3(name = "NH3", MM = 0.01703052, Hf = -2697510.117130892, H0 = 589713.1150428759, Tlimit = 1000, alow = {-76812.26149999999, 1270.951578, -3.89322913, 0.02145988418, -2.183766703e-005, 1.317385706e-008, -3.33232206e-012}, blow = {-12648.86413, 43.66014588}, ahigh = {2452389.535, -8040.89424, 12.71346201, -0.000398018658, 3.55250275e-008, 2.53092357e-012, -3.32270053e-016}, bhigh = {43861.91959999999, -64.62330602}, R = 488.2101075011215);
          constant IdealGases.Common.DataRecord NO(name = "NO", MM = 0.0300061, Hf = 3041758.509103149, H0 = 305908.1320131574, Tlimit = 1000, alow = {-11439.16503, 153.6467592, 3.43146873, -0.002668592368, 8.48139912e-006, -7.685111050000001e-009, 2.386797655e-012}, blow = {9098.214410000001, 6.72872549}, ahigh = {223901.8716, -1289.651623, 5.43393603, -0.00036560349, 9.880966450000001e-008, -1.416076856e-011, 9.380184619999999e-016}, bhigh = {17503.17656, -8.50166909}, R = 277.0927244793559);
          constant IdealGases.Common.DataRecord NO2(name = "NO2", MM = 0.0460055, Hf = 743237.6346306421, H0 = 221890.3174620426, Tlimit = 1000, alow = {-56420.3878, 963.308572, -2.434510974, 0.01927760886, -1.874559328e-005, 9.145497730000001e-009, -1.777647635e-012}, blow = {-1547.925037, 40.6785121}, ahigh = {721300.157, -3832.6152, 11.13963285, -0.002238062246, 6.54772343e-007, -7.6113359e-011, 3.32836105e-015}, bhigh = {25024.97403, -43.0513004}, R = 180.7277825477389);
          constant IdealGases.Common.DataRecord N2(name = "N2", MM = 0.0280134, Hf = 0, H0 = 309498.4543111511, Tlimit = 1000, alow = {22103.71497, -381.846182, 6.08273836, -0.00853091441, 1.384646189e-005, -9.62579362e-009, 2.519705809e-012}, blow = {710.846086, -10.76003744}, ahigh = {587712.406, -2239.249073, 6.06694922, -0.00061396855, 1.491806679e-007, -1.923105485e-011, 1.061954386e-015}, bhigh = {12832.10415, -15.86640027}, R = 296.8033869505308);
          constant IdealGases.Common.DataRecord N2O(name = "N2O", MM = 0.0440128, Hf = 1854006.107314236, H0 = 217685.1961247637, Tlimit = 1000, alow = {42882.2597, -644.011844, 6.03435143, 0.0002265394436, 3.47278285e-006, -3.62774864e-009, 1.137969552e-012}, blow = {11794.05506, -10.0312857}, ahigh = {343844.804, -2404.557558, 9.125636220000001, -0.000540166793, 1.315124031e-007, -1.4142151e-011, 6.38106687e-016}, bhigh = {21986.32638, -31.47805016}, R = 188.9103169986913);
          constant IdealGases.Common.DataRecord Ne(name = "Ne", MM = 0.0201797, Hf = 0, H0 = 307111.9986917546, Tlimit = 1000, alow = {0, 0, 2.5, 0, 0, 0, 0}, blow = {-745.375, 3.35532272}, ahigh = {0, 0, 2.5, 0, 0, 0, 0}, bhigh = {-745.375, 3.35532272}, R = 412.0215860493466);
          constant IdealGases.Common.DataRecord O2(name = "O2", MM = 0.0319988, Hf = 0, H0 = 271263.4223783392, Tlimit = 1000, alow = {-34255.6342, 484.700097, 1.119010961, 0.00429388924, -6.83630052e-007, -2.0233727e-009, 1.039040018e-012}, blow = {-3391.45487, 18.4969947}, ahigh = {-1037939.022, 2344.830282, 1.819732036, 0.001267847582, -2.188067988e-007, 2.053719572e-011, -8.193467050000001e-016}, bhigh = {-16890.10929, 17.38716506}, R = 259.8369938872708);
          constant IdealGases.Common.DataRecord SO2(name = "SO2", MM = 0.0640638, Hf = -4633037.690552231, H0 = 164650.3485587805, Tlimit = 1000, alow = {-53108.4214, 909.031167, -2.356891244, 0.02204449885, -2.510781471e-005, 1.446300484e-008, -3.36907094e-012}, blow = {-41137.52080000001, 40.45512519}, ahigh = {-112764.0116, -825.226138, 7.61617863, -0.000199932761, 5.65563143e-008, -5.45431661e-012, 2.918294102e-016}, bhigh = {-33513.0869, -16.55776085}, R = 129.7842463294403);
          constant IdealGases.Common.DataRecord SO3(name = "SO3", MM = 0.0800632, Hf = -4944843.573576874, H0 = 145990.9046852986, Tlimit = 1000, alow = {-39528.5529, 620.857257, -1.437731716, 0.02764126467, -3.144958662e-005, 1.792798e-008, -4.12638666e-012}, blow = {-51841.0617, 33.91331216}, ahigh = {-216692.3781, -1301.022399, 10.96287985, -0.000383710002, 8.466889039999999e-008, -9.70539929e-012, 4.49839754e-016}, bhigh = {-43982.83990000001, -36.55217314}, R = 103.8488594010732);
          annotation(Documentation(info = "<HTML>
        <p>This package contains ideal gas models for the 1241 ideal gases from</p>
        <blockquote>
          <p>McBride B.J., Zehe M.J., and Gordon S. (2002): <b>NASA Glenn Coefficients
          for Calculating Thermodynamic Properties of Individual Species</b>. NASA
          report TP-2002-211556</p>
        </blockquote>

        <pre>
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
        </pre>
        </HTML>"));
        end SingleGasesData;
        annotation(Documentation(info = "<html>

      </html>"));
      end Common;
      annotation(Documentation(info = "<HTML>
    <p>This package contains data for the 1241 ideal gases from</p>
    <blockquote>
      <p>McBride B.J., Zehe M.J., and Gordon S. (2002): <b>NASA Glenn Coefficients
      for Calculating Thermodynamic Properties of Individual Species</b>. NASA
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
    <a href=\"modelica://Modelica.Media.Interfaces.PartialMedium.FluidConstants\">FluidConstants</a> record filled with data, a medium package has to be written. Note that only the dipole moment, the accentric factor and critical data are necessary for the viscosity and thermal conductivity functions.</li>
    <li><ul>
    <li>For single components, a new package following the pattern in
    <a href=\"modelica://Modelica.Media.IdealGases.SingleGases\">IdealGases.SingleGases</a> has to be created, pointing both to a data record for cp and to a user-defined fluidContants record.</li>
    <li>For mixtures of several components, a new package following the pattern in
    <a href=\"modelica://Modelica.Media.IdealGases.MixtureGases\">IdealGases.MixtureGases</a> has to be created, building an array of data records for cp and an array of (partly) user-defined fluidContants records.</li>
    </ul></li>
    </ol>
    <p>Note that many properties can computed for the full set of 1241 gases listed below, but due to the missing viscosity and thermal conductivity functions, no fully Modelica.Media-compliant media can be defined.</p>
    <p>
    Data records for heat capacity, specific enthalpy and specific entropy exist for the following substances and ions:
    </p>
    <pre>
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
    </pre></HTML>"));
    end IdealGases;

    package Incompressible  "Medium model for T-dependent properties, defined by tables or polynomials"
      extends Modelica.Icons.VariantsPackage;

      package Common  "Common data structures"
        extends Modelica.Icons.Package;

        record BaseProps_Tpoly  "Fluid state record"
          extends Modelica.Icons.Record;
          .Modelica.SIunits.Temperature T "Temperature";
          .Modelica.SIunits.Pressure p "Pressure";
        end BaseProps_Tpoly;
      end Common;

      package TableBased  "Incompressible medium properties based on tables"
        extends Modelica.Media.Interfaces.PartialMedium(ThermoStates = if enthalpyOfT then Modelica.Media.Interfaces.Choices.IndependentVariables.T else Modelica.Media.Interfaces.Choices.IndependentVariables.pT, final reducedX = true, final fixedX = true, mediumName = "tableMedium", redeclare record ThermodynamicState = Common.BaseProps_Tpoly, singleState = true, reference_p = 1.013e5, Temperature(min = T_min, max = T_max));
        constant Boolean enthalpyOfT = true "True if enthalpy is approximated as a function of T only, (p-dependence neglected)";
        constant Boolean densityOfT = size(tableDensity, 1) > 1 "True if density is a function of temperature";
        constant Modelica.SIunits.Temperature T_min "Minimum temperature valid for medium model";
        constant Modelica.SIunits.Temperature T_max "Maximum temperature valid for medium model";
        constant Temperature T0 = 273.15 "Reference Temperature";
        constant SpecificEnthalpy h0 = 0 "Reference enthalpy at T0, reference_p";
        constant SpecificEntropy s0 = 0 "Reference entropy at T0, reference_p";
        constant MolarMass MM_const = 0.1 "Molar mass";
        constant Integer npol = 2 "Degree of polynomial used for fitting";
        constant Integer npolDensity = npol "Degree of polynomial used for fitting rho(T)";
        constant Integer npolHeatCapacity = npol "Degree of polynomial used for fitting Cp(T)";
        constant Integer npolViscosity = npol "Degree of polynomial used for fitting eta(T)";
        constant Integer npolVaporPressure = npol "Degree of polynomial used for fitting pVap(T)";
        constant Integer npolConductivity = npol "Degree of polynomial used for fitting lambda(T)";
        constant Integer neta = size(tableViscosity, 1) "Number of data points for viscosity";
        constant Real[:, 2] tableDensity "Table for rho(T)";
        constant Real[:, 2] tableHeatCapacity "Table for Cp(T)";
        constant Real[:, 2] tableViscosity "Table for eta(T)";
        constant Real[:, 2] tableVaporPressure "Table for pVap(T)";
        constant Real[:, 2] tableConductivity "Table for lambda(T)";
        constant Boolean TinK "True if T[K],Kelvin used for table temperatures";
        constant Boolean hasDensity = not size(tableDensity, 1) == 0 "True if table tableDensity is present";
        constant Boolean hasHeatCapacity = not size(tableHeatCapacity, 1) == 0 "True if table tableHeatCapacity is present";
        constant Boolean hasViscosity = not size(tableViscosity, 1) == 0 "True if table tableViscosity is present";
        constant Boolean hasVaporPressure = not size(tableVaporPressure, 1) == 0 "True if table tableVaporPressure is present";
        final constant Real[neta] invTK = if size(tableViscosity, 1) > 0 then if TinK then 1 ./ tableViscosity[:, 1] else 1 ./ .Modelica.SIunits.Conversions.from_degC(tableViscosity[:, 1]) else fill(0, neta);
        final constant Real[:] poly_rho = if hasDensity then Polynomials_Temp.fitting(tableDensity[:, 1], tableDensity[:, 2], npolDensity) else zeros(npolDensity + 1);
        final constant Real[:] poly_Cp = if hasHeatCapacity then Polynomials_Temp.fitting(tableHeatCapacity[:, 1], tableHeatCapacity[:, 2], npolHeatCapacity) else zeros(npolHeatCapacity + 1);
        final constant Real[:] poly_eta = if hasViscosity then Polynomials_Temp.fitting(invTK, .Modelica.Math.log(tableViscosity[:, 2]), npolViscosity) else zeros(npolViscosity + 1);
        final constant Real[:] poly_lam = if size(tableConductivity, 1) > 0 then Polynomials_Temp.fitting(tableConductivity[:, 1], tableConductivity[:, 2], npolConductivity) else zeros(npolConductivity + 1);

        redeclare model extends BaseProperties(final standardOrderComponents = true, p_bar = .Modelica.SIunits.Conversions.to_bar(p), T_degC(start = T_start - 273.15) = .Modelica.SIunits.Conversions.to_degC(T), T(start = T_start, stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default))  "Base properties of T dependent medium"
          .Modelica.SIunits.SpecificHeatCapacity cp "Specific heat capacity";
          parameter .Modelica.SIunits.Temperature T_start = 298.15 "Initial temperature";
        equation
          assert(hasDensity, "Medium " + mediumName + " can not be used without assigning tableDensity.");
          assert(T >= T_min and T <= T_max, "Temperature T (= " + String(T) + " K) is not in the allowed range (" + String(T_min) + " K <= T <= " + String(T_max) + " K) required from medium model \"" + mediumName + "\".");
          R = Modelica.Constants.R;
          cp = Polynomials_Temp.evaluate(poly_Cp, if TinK then T else T_degC);
          h = if enthalpyOfT then h_T(T) else h_pT(p, T, densityOfT);
          u = h - (if singleState then reference_p / d else state.p / d);
          d = Polynomials_Temp.evaluate(poly_rho, if TinK then T else T_degC);
          state.T = T;
          state.p = p;
          MM = MM_const;
          annotation(Documentation(info = "<html>
        <p>
        Note that the inner energy neglects the pressure dependence, which is only
        true for an incompressible medium with d = constant. The neglected term is
        p-reference_p)/rho*(T/rho)*(partial rho /partial T). This is very small for
        liquids due to proportionality to 1/d^2, but can be problematic for gases that are
        modeled incompressible.
        </p>
        <p>It should be noted that incompressible media only have 1 state per control volume (usually T),
        but have both T and p as inputs for fully correct properties. The error of using only T-dependent
        properties is small, therefore a Boolean flag enthalpyOfT exists. If it is true, the
        enumeration Choices.independentVariables  is set to  Choices.independentVariables.T otherwise
        it is set to Choices.independentVariables.pT.</p>
        <p>
        Enthalpy is never a function of T only (h = h(T) + (p-reference_p)/d), but the
        error is also small and non-linear systems can be avoided. In particular,
        non-linear systems are small and local as opposed to large and over all volumes.
        </p>

        <p>
        Entropy is calculated as
        </p>
        <pre>
          s = s0 + integral(Cp(T)/T,dt)
        </pre>
        <p>
        which is only exactly true for a fluid with constant density d=d0.
        </p>
        </html>"));
        end BaseProperties;

        redeclare function extends setState_pTX  "Returns state record, given pressure and temperature"
        algorithm
          state := ThermodynamicState(p = p, T = T);
          annotation(smoothOrder = 3);
        end setState_pTX;

        redeclare function extends setState_dTX  "Returns state record, given pressure and temperature"
        algorithm
          assert(false, "For incompressible media with d(T) only, state can not be set from density and temperature");
        end setState_dTX;

        redeclare function extends setState_phX  "Returns state record, given pressure and specific enthalpy"
        algorithm
          state := ThermodynamicState(p = p, T = T_ph(p, h));
          annotation(Inline = true, smoothOrder = 3);
        end setState_phX;

        redeclare function extends setState_psX  "Returns state record, given pressure and specific entropy"
        algorithm
          state := ThermodynamicState(p = p, T = T_ps(p, s));
          annotation(Inline = true, smoothOrder = 3);
        end setState_psX;

        redeclare function extends setSmoothState  "Return thermodynamic state so that it smoothly approximates: if x > 0 then state_a else state_b"
        algorithm
          state := ThermodynamicState(p = Media.Common.smoothStep(x, state_a.p, state_b.p, x_small), T = Media.Common.smoothStep(x, state_a.T, state_b.T, x_small));
          annotation(Inline = true, smoothOrder = 3);
        end setSmoothState;

        redeclare function extends specificHeatCapacityCv  "Specific heat capacity at constant volume (or pressure) of medium"
        algorithm
          assert(hasHeatCapacity, "Specific Heat Capacity, Cv, is not defined for medium " + mediumName + ".");
          cv := Polynomials_Temp.evaluate(poly_Cp, if TinK then state.T else state.T - 273.15);
          annotation(smoothOrder = 2);
        end specificHeatCapacityCv;

        redeclare function extends specificHeatCapacityCp  "Specific heat capacity at constant volume (or pressure) of medium"
        algorithm
          assert(hasHeatCapacity, "Specific Heat Capacity, Cv, is not defined for medium " + mediumName + ".");
          cp := Polynomials_Temp.evaluate(poly_Cp, if TinK then state.T else state.T - 273.15);
          annotation(smoothOrder = 2);
        end specificHeatCapacityCp;

        redeclare function extends dynamicViscosity  "Return dynamic viscosity as a function of the thermodynamic state record"
        algorithm
          assert(size(tableViscosity, 1) > 0, "DynamicViscosity, eta, is not defined for medium " + mediumName + ".");
          eta := .Modelica.Math.exp(Polynomials_Temp.evaluate(poly_eta, 1 / state.T));
          annotation(smoothOrder = 2);
        end dynamicViscosity;

        redeclare function extends thermalConductivity  "Return thermal conductivity as a function of the thermodynamic state record"
        algorithm
          assert(size(tableConductivity, 1) > 0, "ThermalConductivity, lambda, is not defined for medium " + mediumName + ".");
          lambda := Polynomials_Temp.evaluate(poly_lam, if TinK then state.T else .Modelica.SIunits.Conversions.to_degC(state.T));
          annotation(smoothOrder = 2);
        end thermalConductivity;

        function s_T  "Compute specific entropy"
          extends Modelica.Icons.Function;
          input Temperature T "Temperature";
          output SpecificEntropy s "Specific entropy";
        algorithm
          s := s0 + (if TinK then Polynomials_Temp.integralValue(poly_Cp[1:npol], T, T0) else Polynomials_Temp.integralValue(poly_Cp[1:npol], .Modelica.SIunits.Conversions.to_degC(T), .Modelica.SIunits.Conversions.to_degC(T0))) + Modelica.Math.log(T / T0) * Polynomials_Temp.evaluate(poly_Cp, if TinK then 0 else Modelica.Constants.T_zero);
          annotation(Inline = true, smoothOrder = 2);
        end s_T;

        redeclare function extends specificEntropy  "Return specific entropy
         as a function of the thermodynamic state record"
        protected
          Integer npol = size(poly_Cp, 1) - 1;
        algorithm
          assert(hasHeatCapacity, "Specific Entropy, s(T), is not defined for medium " + mediumName + ".");
          s := s_T(state.T);
          annotation(smoothOrder = 2);
        end specificEntropy;

        function h_T  "Compute specific enthalpy from temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature T "Temperature";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy at p, T";
        algorithm
          h := h0 + Polynomials_Temp.integralValue(poly_Cp, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T), if TinK then T0 else .Modelica.SIunits.Conversions.to_degC(T0));
          annotation(derivative = h_T_der);
        end h_T;

        function h_T_der  "Compute specific enthalpy from temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Temperature T "Temperature";
          input Real dT "Temperature derivative";
          output Real dh "Derivative of Specific enthalpy at T";
        algorithm
          dh := Polynomials_Temp.evaluate(poly_Cp, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T)) * dT;
          annotation(smoothOrder = 1);
        end h_T_der;

        function h_pT  "Compute specific enthalpy from pressure and temperature"
          extends Modelica.Icons.Function;
          input .Modelica.SIunits.Pressure p "Pressure";
          input .Modelica.SIunits.Temperature T "Temperature";
          input Boolean densityOfT = false "Include or neglect density derivative dependence of enthalpy";
          output .Modelica.SIunits.SpecificEnthalpy h "Specific enthalpy at p, T";
        algorithm
          h := h0 + Polynomials_Temp.integralValue(poly_Cp, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T), if TinK then T0 else .Modelica.SIunits.Conversions.to_degC(T0)) + (p - reference_p) / Polynomials_Temp.evaluate(poly_rho, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T)) * (if densityOfT then 1 + T / Polynomials_Temp.evaluate(poly_rho, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T)) * Polynomials_Temp.derivativeValue(poly_rho, if TinK then T else .Modelica.SIunits.Conversions.to_degC(T)) else 1.0);
          annotation(smoothOrder = 2);
        end h_pT;

        redeclare function extends temperature  "Return temperature as a function of the thermodynamic state record"
        algorithm
          T := state.T;
          annotation(Inline = true, smoothOrder = 2);
        end temperature;

        redeclare function extends pressure  "Return pressure as a function of the thermodynamic state record"
        algorithm
          p := state.p;
          annotation(Inline = true, smoothOrder = 2);
        end pressure;

        redeclare function extends density  "Return density as a function of the thermodynamic state record"
        algorithm
          d := Polynomials_Temp.evaluate(poly_rho, if TinK then state.T else .Modelica.SIunits.Conversions.to_degC(state.T));
          annotation(Inline = true, smoothOrder = 2);
        end density;

        redeclare function extends specificEnthalpy  "Return specific enthalpy as a function of the thermodynamic state record"
        algorithm
          h := if enthalpyOfT then h_T(state.T) else h_pT(state.p, state.T);
          annotation(Inline = true, smoothOrder = 2);
        end specificEnthalpy;

        redeclare function extends specificInternalEnergy  "Return specific internal energy as a function of the thermodynamic state record"
        algorithm
          u := (if enthalpyOfT then h_T(state.T) else h_pT(state.p, state.T)) - (if singleState then reference_p else state.p) / density(state);
          annotation(Inline = true, smoothOrder = 2);
        end specificInternalEnergy;

        function T_ph  "Compute temperature from pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEnthalpy h "Specific enthalpy";
          output Temperature T "Temperature";

        protected
          package Internal  "Solve h(T) for T with given h (use only indirectly via temperature_phX)"
            extends Modelica.Media.Common.OneNonLinearEquation;

            redeclare record extends f_nonlinear_Data  "Superfluous record, fix later when better structure of inverse functions exists"
              constant Real[5] dummy = {1, 2, 3, 4, 5};
            end f_nonlinear_Data;

            redeclare function extends f_nonlinear  "P is smuggled in via vector"
            algorithm
              y := if singleState then h_T(x) else h_pT(p, x);
            end f_nonlinear;
          end Internal;
        algorithm
          T := Internal.solve(h, T_min, T_max, p, {1}, Internal.f_nonlinear_Data());
          annotation(Inline = false, LateInline = true, inverse(h = h_pT(p, T)));
        end T_ph;

        function T_ps  "Compute temperature from pressure and specific enthalpy"
          extends Modelica.Icons.Function;
          input AbsolutePressure p "Pressure";
          input SpecificEntropy s "Specific entropy";
          output Temperature T "Temperature";

        protected
          package Internal  "Solve h(T) for T with given h (use only indirectly via temperature_phX)"
            extends Modelica.Media.Common.OneNonLinearEquation;

            redeclare record extends f_nonlinear_Data  "Superfluous record, fix later when better structure of inverse functions exists"
              constant Real[5] dummy = {1, 2, 3, 4, 5};
            end f_nonlinear_Data;

            redeclare function extends f_nonlinear  "P is smuggled in via vector"
            algorithm
              y := s_T(x);
            end f_nonlinear;
          end Internal;
        algorithm
          T := Internal.solve(s, T_min, T_max, p, {1}, Internal.f_nonlinear_Data());
        end T_ps;

        package Polynomials_Temp  "Temporary Functions operating on polynomials (including polynomial fitting); only to be used in Modelica.Media.Incompressible.TableBased"
          extends Modelica.Icons.Package;

          function evaluate  "Evaluate polynomial at a given abscissa value"
            extends Modelica.Icons.Function;
            input Real[:] p "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real u "Abscissa value";
            output Real y "Value of polynomial at u";
          algorithm
            y := p[1];
            for j in 2:size(p, 1) loop
              y := p[j] + u * y;
            end for;
            annotation(derivative(zeroDerivative = p) = evaluate_der);
          end evaluate;

          function evaluateWithRange  "Evaluate polynomial at a given abscissa value with linear extrapolation outside of the defined range"
            extends Modelica.Icons.Function;
            input Real[:] p "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real uMin "Polynomial valid in the range uMin .. uMax";
            input Real uMax "Polynomial valid in the range uMin .. uMax";
            input Real u "Abscissa value";
            output Real y "Value of polynomial at u. Outside of uMin,uMax, linear extrapolation is used";
          algorithm
            if u < uMin then
              y := evaluate(p, uMin) - evaluate_der(p, uMin, uMin - u);
            elseif u > uMax then
              y := evaluate(p, uMax) + evaluate_der(p, uMax, u - uMax);
            else
              y := evaluate(p, u);
            end if;
            annotation(derivative(zeroDerivative = p, zeroDerivative = uMin, zeroDerivative = uMax) = evaluateWithRange_der);
          end evaluateWithRange;

          function derivativeValue  "Value of derivative of polynomial at abscissa value u"
            extends Modelica.Icons.Function;
            input Real[:] p "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real u "Abscissa value";
            output Real y "Value of derivative of polynomial at u";
          protected
            Integer n = size(p, 1);
          algorithm
            y := p[1] * (n - 1);
            for j in 2:size(p, 1) - 1 loop
              y := p[j] * (n - j) + u * y;
            end for;
            annotation(derivative(zeroDerivative = p) = derivativeValue_der);
          end derivativeValue;

          function secondDerivativeValue  "Value of 2nd derivative of polynomial at abscissa value u"
            extends Modelica.Icons.Function;
            input Real[:] p "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real u "Abscissa value";
            output Real y "Value of 2nd derivative of polynomial at u";
          protected
            Integer n = size(p, 1);
          algorithm
            y := p[1] * (n - 1) * (n - 2);
            for j in 2:size(p, 1) - 2 loop
              y := p[j] * (n - j) * (n - j - 1) + u * y;
            end for;
          end secondDerivativeValue;

          function integralValue  "Integral of polynomial p(u) from u_low to u_high"
            extends Modelica.Icons.Function;
            input Real[:] p "Polynomial coefficients";
            input Real u_high "High integrand value";
            input Real u_low = 0 "Low integrand value, default 0";
            output Real integral = 0.0 "Integral of polynomial p from u_low to u_high";
          protected
            Integer n = size(p, 1) "Degree of integrated polynomial";
            Real y_low = 0 "Value at lower integrand";
          algorithm
            for j in 1:n loop
              integral := u_high * (p[j] / (n - j + 1) + integral);
              y_low := u_low * (p[j] / (n - j + 1) + y_low);
            end for;
            integral := integral - y_low;
            annotation(derivative(zeroDerivative = p) = integralValue_der);
          end integralValue;

          function fitting  "Computes the coefficients of a polynomial that fits a set of data points in a least-squares sense"
            extends Modelica.Icons.Function;
            input Real[:] u "Abscissa data values";
            input Real[size(u, 1)] y "Ordinate data values";
            input Integer n(min = 1) "Order of desired polynomial that fits the data points (u,y)";
            output Real[n + 1] p "Polynomial coefficients of polynomial that fits the date points";
          protected
            Real[size(u, 1), n + 1] V "Vandermonde matrix";
          algorithm
            V[:, n + 1] := ones(size(u, 1));
            for j in n:(-1):1 loop
              V[:, j] := {u[i] * V[i, j + 1] for i in 1:size(u, 1)};
            end for;
            p := Modelica.Math.Matrices.leastSquares(V, y);
            annotation(Documentation(info = "<HTML>
          <p>
          Polynomials.fitting(u,y,n) computes the coefficients of a polynomial
          p(u) of degree \"n\" that fits the data \"p(u[i]) - y[i]\"
          in a least squares sense. The polynomial is
          returned as a vector p[n+1] that has the following definition:
          </p>
          <pre>
            p(u) = p[1]*u^n + p[2]*u^(n-1) + ... + p[n]*u + p[n+1];
          </pre>
          </HTML>"));
          end fitting;

          function evaluate_der  "Evaluate derivative of polynomial at a given abscissa value"
            extends Modelica.Icons.Function;
            input Real[:] p "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real u "Abscissa value";
            input Real du "Delta of abscissa value";
            output Real dy "Value of derivative of polynomial at u";
          protected
            Integer n = size(p, 1);
          algorithm
            dy := p[1] * (n - 1);
            for j in 2:size(p, 1) - 1 loop
              dy := p[j] * (n - j) + u * dy;
            end for;
            dy := dy * du;
          end evaluate_der;

          function evaluateWithRange_der  "Evaluate derivative of polynomial at a given abscissa value with extrapolation outside of the defined range"
            extends Modelica.Icons.Function;
            input Real[:] p "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real uMin "Polynomial valid in the range uMin .. uMax";
            input Real uMax "Polynomial valid in the range uMin .. uMax";
            input Real u "Abscissa value";
            input Real du "Delta of abscissa value";
            output Real dy "Value of derivative of polynomial at u";
          algorithm
            if u < uMin then
              dy := evaluate_der(p, uMin, du);
            elseif u > uMax then
              dy := evaluate_der(p, uMax, du);
            else
              dy := evaluate_der(p, u, du);
            end if;
          end evaluateWithRange_der;

          function integralValue_der  "Time derivative of integral of polynomial p(u) from u_low to u_high, assuming only u_high as time-dependent (Leibnitz rule)"
            extends Modelica.Icons.Function;
            input Real[:] p "Polynomial coefficients";
            input Real u_high "High integrand value";
            input Real u_low = 0 "Low integrand value, default 0";
            input Real du_high "High integrand value";
            input Real du_low = 0 "Low integrand value, default 0";
            output Real dintegral = 0.0 "Integral of polynomial p from u_low to u_high";
          algorithm
            dintegral := evaluate(p, u_high) * du_high;
          end integralValue_der;

          function derivativeValue_der  "Time derivative of derivative of polynomial"
            extends Modelica.Icons.Function;
            input Real[:] p "Polynomial coefficients (p[1] is coefficient of highest power)";
            input Real u "Abscissa value";
            input Real du "Delta of abscissa value";
            output Real dy "Time-derivative of derivative of polynomial w.r.t. input variable at u";
          protected
            Integer n = size(p, 1);
          algorithm
            dy := secondDerivativeValue(p, u) * du;
          end derivativeValue_der;
          annotation(Documentation(info = "<HTML>
        <p>
        This package contains functions to operate on polynomials,
        in particular to determine the derivative and the integral
        of a polynomial and to use a polynomial to fit a given set
        of data points.
        </p>

        <p><b>Copyright &copy; 2004-2015, Modelica Association and DLR.</b></p>

        <p><i>
        This package is <b>free</b> software. It can be redistributed and/or modified
        under the terms of the <b>Modelica license</b>, see the license conditions
        and the accompanying <b>disclaimer</b> in the documentation of package
        Modelica in file \"Modelica/package.mo\".
        </i>
        </p>

        </html>", revisions = "<html>
        <ul>
        <li><i>Oct. 22, 2004</i> by Martin Otter (DLR):<br>
               Renamed functions to not have abbreviations.<br>
               Based fitting on LAPACK<br>
               New function to return the polynomial of an indefinite integral</li>
        <li><i>Sept. 3, 2004</i> by Jonas Eborn (Scynamics):<br>
               polyderval, polyintval added</li>
        <li><i>March 1, 2004</i> by Martin Otter (DLR):<br>
               first version implemented</li>
        </ul>
        </html>"));
        end Polynomials_Temp;
        annotation(Documentation(info = "<HTML>
      <p>
      This is the base package for medium models of incompressible fluids based on
      tables. The minimal data to provide for a useful medium description is tables
      of density and heat capacity as functions of temperature.
      </p>

      <p>It should be noted that incompressible media only have 1 state per control volume (usually T),
      but have both T and p as inputs for fully correct properties. The error of using only T-dependent
      properties is small, therefore a Boolean flag enthalpyOfT exists. If it is true, the
      enumeration Choices.independentVariables  is set to  Choices.independentVariables.T otherwise
      it is set to Choices.independentVariables.pT.</p>

      <h4>Using the package TableBased</h4>
      <p>
      To implement a new medium model, create a package that <b>extends</b> TableBased
      and provides one or more of the constant tables:
      </p>

      <pre>
      tableDensity        = [T, d];
      tableHeatCapacity   = [T, Cp];
      tableConductivity   = [T, lam];
      tableViscosity      = [T, eta];
      tableVaporPressure  = [T, pVap];
      </pre>

      <p>
      The table data is used to fit constant polynomials of order <b>npol</b>, the
      temperature data points do not need to be same for different properties. Properties
      like enthalpy, inner energy and entropy are calculated consistently from integrals
      and derivatives of d(T) and Cp(T). The minimal
      data for a useful medium model is thus density and heat capacity. Transport
      properties and vapor pressure are optional, if the data tables are empty the corresponding
      function calls can not be used.
      </p>
      </HTML>"));
      end TableBased;
      annotation(Documentation(info = "<HTML>
    <h4>Incompressible media package</h4>
    <p>
    This package provides a structure and examples of how to create simple
    medium models of incompressible fluids, meaning fluids with very little
    pressure influence on density. The medium properties is typically described
    in terms of tables, functions or polynomial coefficients.
    </p>
    <h4>Definitions</h4>
    <p>
    The common meaning of <em>incompressible</em> is that properties like density
    and enthalpy are independent of pressure. Thus properties are conveniently
    described as functions of temperature, e.g., as polynomials density(T) and cp(T).
    However, enthalpy can not be independent of pressure since h = u - p/d. For liquids
    it is anyway
    common to neglect this dependence since for constant density the neglected term
    is (p - p0)/d, which in comparison with cp is very small for most liquids. For
    water, the equivalent change of temperature to increasing pressure 1 bar is
    0.025 Kelvin.
    </p>
    <p>
    Two Boolean flags are used to choose how enthalpy and inner energy is calculated:
    </p>
    <ul>
    <li><b>enthalpyOfT</b>=true, means assuming that enthalpy is only a function
    of temperature, neglecting the pressure dependent term.</li>
    <li><b>singleState</b>=true, means also neglect the pressure influence on inner
    energy, which makes all medium properties pure functions of temperature.</li>
    </ul>
    <p>
    The default setting for both these flags is true, which enables the simulation tool
    to choose temperature as the only medium state and avoids non-linear equation
    systems, see the section about
    <a href=\"modelica://Modelica.Media.UsersGuide.MediumDefinition.StaticStateSelection\">Static
    state selection</a> in the Modelica.Media User's Guide.
    </p>

    <h4>Contents</h4>
    <p>
    Currently, the package contains the following parts:
    </p>
    <ol>
    <li> <a href=\"modelica://Modelica.Media.Incompressible.TableBased\">
          Table based medium models</a></li>
    <li> <a href=\"modelica://Modelica.Media.Incompressible.Examples\">
          Example medium models</a></li>
    </ol>

    <p>
    A few examples are given in the Examples package. The model
    <a href=\"modelica://Modelica.Media.Incompressible.Examples.Glycol47\">
    Examples.Glycol47</a> shows how the medium models can be used. For more
    realistic examples of how to implement volume models with medium properties
    look in the <a href=\"modelica://Modelica.Media.UsersGuide.MediumUsage\">Medium
    usage section</a> of the User's Guide.
    </p>

    </HTML>"));
    end Incompressible;
    annotation(preferredView = "info", Documentation(info = "<HTML>
  <p>
  This library contains <a href=\"modelica://Modelica.Media.Interfaces\">interface</a>
  definitions for media and the following <b>property</b> models for
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
  The following parts are useful, when newly starting with this library:
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
  Copyright &copy; 1998-2015, Modelica Association.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </HTML>", revisions = "<html>
  <ul>
  <li><i>May 16, 2013</i> by Stefan Wischhusen (XRG Simulation):<br/>
      Added new media models Air.ReferenceMoistAir, Air.ReferenceAir, R134a.</li>
  <li><i>May 25, 2011</i> by Francesco Casella:<br/>Added min/max attributes to Water, TableBased, MixtureGasNasa, SimpleAir and MoistAir local types.</li>
  <li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added individual settings for polynomial fittings of properties.</li>
  </ul>
  </html>"), Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-76, -80}, {-62, -30}, {-32, 40}, {4, 66}, {48, 66}, {73, 45}, {62, -8}, {48, -50}, {38, -80}}, color = {64, 64, 64}, smooth = Smooth.Bezier), Line(points = {{-40, 20}, {68, 20}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-40, 20}, {-44, 88}, {-44, 88}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{68, 20}, {86, -58}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-60, -28}, {56, -28}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-60, -28}, {-74, 84}, {-74, 84}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{56, -28}, {70, -80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-76, -80}, {38, -80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-76, -80}, {-94, -16}, {-94, -16}}, color = {175, 175, 175}, smooth = Smooth.None)}));
  end Media;

  package Math  "Library of mathematical functions (e.g., sin, cos) and of functions operating on vectors and matrices"
    extends Modelica.Icons.Package;

    package Icons  "Icons for Math"
      extends Modelica.Icons.IconsPackage;

      partial function AxisLeft  "Basic icon for mathematical function with y-axis on left side"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-80, 68}}, color = {192, 192, 192}), Polygon(points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 80}, {-88, 80}}, color = {95, 95, 95}), Line(points = {{-80, -80}, {-88, -80}}, color = {95, 95, 95}), Line(points = {{-80, -90}, {-80, 84}}, color = {95, 95, 95}), Text(extent = {{-75, 104}, {-55, 84}}, lineColor = {95, 95, 95}, textString = "y"), Polygon(points = {{-80, 98}, {-86, 82}, {-74, 82}, {-80, 98}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
      <p>
      Icon for a mathematical function, consisting of an y-axis on the left side.
      It is expected, that an x-axis is added and a plot of the function.
      </p>
      </html>")); end AxisLeft;

      partial function AxisCenter  "Basic icon for mathematical function with y-axis in the center"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{0, -80}, {0, 68}}, color = {192, 192, 192}), Polygon(points = {{0, 90}, {-8, 68}, {8, 68}, {0, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(graphics = {Line(points = {{0, 80}, {-8, 80}}, color = {95, 95, 95}), Line(points = {{0, -80}, {-8, -80}}, color = {95, 95, 95}), Line(points = {{0, -90}, {0, 84}}, color = {95, 95, 95}), Text(extent = {{5, 104}, {25, 84}}, lineColor = {95, 95, 95}, textString = "y"), Polygon(points = {{0, 98}, {-6, 82}, {6, 82}, {0, 98}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
      <p>
      Icon for a mathematical function, consisting of an y-axis in the middle.
      It is expected, that an x-axis is added and a plot of the function.
      </p>
      </html>")); end AxisCenter;
    end Icons;

    package Matrices  "Library of functions operating on matrices"
      extends Modelica.Icons.Package;

      function leastSquares  "Solve linear equation A*x = b (exactly if possible, or otherwise in a least square sense; A may be non-square and may be rank deficient)"
        extends Modelica.Icons.Function;
        input Real[:, :] A "Matrix A";
        input Real[size(A, 1)] b "Vector b";
        input Real rcond = 100 * Modelica.Constants.eps "Reciprocal condition number to estimate the rank of A";
        output Real[size(A, 2)] x "Vector x such that min|A*x-b|^2 if size(A,1) >= size(A,2) or min|x|^2 and A*x=b, if size(A,1) < size(A,2)";
        output Integer rank "Rank of A";
      protected
        Integer info;
        Real[max(size(A, 1), size(A, 2))] xx;
      algorithm
        if min(size(A)) > 0 then
          (xx, info, rank) := LAPACK.dgelsx_vec(A, b, rcond);
          x := xx[1:size(A, 2)];
          assert(info == 0, "Solving an overdetermined or underdetermined linear system\n" + "of equations with function \"Matrices.leastSquares\" failed.");
        else
          x := fill(0.0, size(A, 2));
        end if;
        annotation(Documentation(info = "<html>
      <h4>Syntax</h4>
      <blockquote><pre>
      x = Matrices.<b>leastSquares</b>(A,b);
      </pre></blockquote>
      <h4>Description</h4>
      <p>
      Returns a solution of equation A*x = b in a least
      square sense (A may be rank deficient):
      </p>
      <pre>
        minimize | A*x - b |
      </pre>

      <p>
      Several different cases can be distinguished (note, <b>rank</b> is an
      output argument of this function):
      </p>

      <p>
      <b>size(A,1) = size(A,2)</b>
      </p>

      <p> A solution is returned for a regular, as well as a singular matrix A:
      </p>

      <ul>
      <li> <b>rank</b> = size(A,1):<br>
           A is <b>regular</b> and the returned solution x fulfills the equation
           A*x = b uniquely.</li>

      <li> <b>rank</b> &lt; size(A,1):<br>
           A is <b>singular</b> and no unique solution for equation A*x = b exists.
           <ul>
           <li>  If an infinite number of solutions exists, the one is selected that fulfills
                 the equation and at the same time has the minimum norm |x| for all solution
                 vectors that fulfill the equation.</li>
           <li>  If no solution exists, x is selected such that |A*x - b| is as small as
                 possible (but A*x - b is not zero).</li>
           </ul>
      </ul>

      <p>
      <b>size(A,1) &gt; size(A,2):</b>
      </p>

      <p>
      The equation A*x = b has no unique solution. The solution x is selected such that
      |A*x - b| is as small as possible. If rank = size(A,2), this minimum norm solution is
      unique. If rank &lt; size(A,2), there are an infinite number of solutions leading to the
      same minimum value of |A*x - b|. From these infinite number of solutions, the one with the
      minimum norm |x| is selected. This gives a unique solution that minimizes both
      |A*x - b| and |x|.
      </p>

      <p>
      <b>size(A,1) &lt; size(A,2):</b>
      </p>

      <ul>
      <li> <b>rank</b> = size(A,1):<br>
           There are an infinite number of solutions that fulfill the equation A*x = b.
           From this infinite number, the unique solution is selected that minimizes |x|.
           </li>

      <li> <b>rank</b> &lt; size(A,1):<br>
           There is either no solution of equation A*x = b, or there are again an infinite
           number of solutions. The unique solution x is returned that minimizes
            both |A*x - b| and |x|.</li>
      </ul>

      <p>
      Note, the solution is computed with the LAPACK function \"dgelsx\",
      i.e., QR or LQ factorization of A with column pivoting.
      </p>

      <h4>Algorithmic details</h4>

      <p>
      The function first computes a QR factorization with column pivoting:
      </p>

      <pre>
            A * P = Q * [ R11 R12 ]
                        [  0  R22 ]
      </pre>

      <p>
      with R11 defined as the largest leading submatrix whose estimated
      condition number is less than 1/rcond.  The order of R11, <b>rank</b>,
      is the effective rank of A.
      </p>

      <p>
      Then, R22 is considered to be negligible, and R12 is annihilated
      by orthogonal transformations from the right, arriving at the
      complete orthogonal factorization:
      </p>

      <pre>
           A * P = Q * [ T11 0 ] * Z
                       [  0  0 ]
      </pre>

      <p>
      The minimum-norm solution is then
      </p>

      <pre>
           x = P * Z' [ inv(T11)*Q1'*b ]
                      [        0       ]
      </pre>

      <p>
      where Q1 consists of the first \"rank\" columns of Q.
      </p>

      <h4>See also</h4>

      <p>
      <a href=\"modelica://Modelica.Math.Matrices.leastSquares2\">Matrices.leastSquares2</a>
      (same as leastSquares, but with a right hand side matrix), <br>
      <a href=\"modelica://Modelica.Math.Matrices.solve\">Matrices.solve</a>
      (for square, regular matrices A)
      </p>

      </html>"));
      end leastSquares;

      package LAPACK  "Interface to LAPACK library (should usually not directly be used but only indirectly via Modelica.Math.Matrices)"
        extends Modelica.Icons.Package;

        function dgelsx_vec  "Computes the minimum-norm solution to a real linear least squares problem with rank deficient A"
          extends Modelica.Icons.Function;
          input Real[:, :] A;
          input Real[size(A, 1)] b;
          input Real rcond = 0.0 "Reciprocal condition number to estimate rank";
          output Real[max(size(A, 1), size(A, 2))] x = cat(1, b, zeros(max(nrow, ncol) - nrow)) "solution is in first size(A,2) rows";
          output Integer info;
          output Integer rank "Effective rank of A";
        protected
          Integer nrow = size(A, 1);
          Integer ncol = size(A, 2);
          Integer nx = max(nrow, ncol);
          Real[max(min(size(A, 1), size(A, 2)) + 3 * size(A, 2), 2 * min(size(A, 1), size(A, 2)) + 1)] work;
          Real[size(A, 1), size(A, 2)] Awork = A;
          Integer[size(A, 2)] jpvt = zeros(ncol);
          external "FORTRAN 77" dgelsx(nrow, ncol, 1, Awork, nrow, x, nx, jpvt, rcond, rank, work, info) annotation(Library = "lapack", Documentation(info = "Lapack documentation
            Purpose
            =======

            This routine is deprecated and has been replaced by routine DGELSY.

            DGELSX computes the minimum-norm solution to a real linear least
            squares problem:
                minimize || A * X - B ||
            using a complete orthogonal factorization of A.  A is an M-by-N
            matrix which may be rank-deficient.

            Several right hand side vectors b and solution vectors x can be
            handled in a single call; they are stored as the columns of the
            M-by-NRHS right hand side matrix B and the N-by-NRHS solution
            matrix X.

            The routine first computes a QR factorization with column pivoting:
                A * P = Q * [ R11 R12 ]
                            [  0  R22 ]
            with R11 defined as the largest leading submatrix whose estimated
            condition number is less than 1/RCOND.  The order of R11, RANK,
            is the effective rank of A.

            Then, R22 is considered to be negligible, and R12 is annihilated
            by orthogonal transformations from the right, arriving at the
            complete orthogonal factorization:
               A * P = Q * [ T11 0 ] * Z
                           [  0  0 ]
            The minimum-norm solution is then
               X = P * Z' [ inv(T11)*Q1'*B ]
                          [        0       ]
            where Q1 consists of the first RANK columns of Q.

            Arguments
            =========

            M       (input) INTEGER
                    The number of rows of the matrix A.  M >= 0.

            N       (input) INTEGER
                    The number of columns of the matrix A.  N >= 0.

            NRHS    (input) INTEGER
                    The number of right hand sides, i.e., the number of
                    columns of matrices B and X. NRHS >= 0.

            A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
                    On entry, the M-by-N matrix A.
                    On exit, A has been overwritten by details of its
                    complete orthogonal factorization.

            LDA     (input) INTEGER
                    The leading dimension of the array A.  LDA >= max(1,M).

            B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
                    On entry, the M-by-NRHS right hand side matrix B.
                    On exit, the N-by-NRHS solution matrix X.
                    If m >= n and RANK = n, the residual sum-of-squares for
                    the solution in the i-th column is given by the sum of
                    squares of elements N+1:M in that column.

            LDB     (input) INTEGER
                    The leading dimension of the array B. LDB >= max(1,M,N).

            JPVT    (input/output) INTEGER array, dimension (N)
                    On entry, if JPVT(i) .ne. 0, the i-th column of A is an
                    initial column, otherwise it is a free column.  Before
                    the QR factorization of A, all initial columns are
                    permuted to the leading positions; only the remaining
                    free columns are moved as a result of column pivoting
                    during the factorization.
                    On exit, if JPVT(i) = k, then the i-th column of A*P
                    was the k-th column of A.

            RCOND   (input) DOUBLE PRECISION
                    RCOND is used to determine the effective rank of A, which
                    is defined as the order of the largest leading triangular
                    submatrix R11 in the QR factorization with pivoting of A,
                    whose estimated condition number < 1/RCOND.

            RANK    (output) INTEGER
                    The effective rank of A, i.e., the order of the submatrix
                    R11.  This is the same as the order of the submatrix T11
                    in the complete orthogonal factorization of A.

            WORK    (workspace) DOUBLE PRECISION array, dimension
                                (max( min(M,N)+3*N, 2*min(M,N)+NRHS )),

            INFO    (output) INTEGER
                    = 0:  successful exit
                    < 0:  if INFO = -i, the i-th argument had an illegal value
          "));
          annotation(Documentation(info = "Lapack documentation
            Purpose
            =======

            This routine is deprecated and has been replaced by routine DGELSY.

            DGELSX computes the minimum-norm solution to a real linear least
            squares problem:
                minimize || A * X - B ||
            using a complete orthogonal factorization of A.  A is an M-by-N
            matrix which may be rank-deficient.

            Several right hand side vectors b and solution vectors x can be
            handled in a single call; they are stored as the columns of the
            M-by-NRHS right hand side matrix B and the N-by-NRHS solution
            matrix X.

            The routine first computes a QR factorization with column pivoting:
                A * P = Q * [ R11 R12 ]
                            [  0  R22 ]
            with R11 defined as the largest leading submatrix whose estimated
            condition number is less than 1/RCOND.  The order of R11, RANK,
            is the effective rank of A.

            Then, R22 is considered to be negligible, and R12 is annihilated
            by orthogonal transformations from the right, arriving at the
            complete orthogonal factorization:
               A * P = Q * [ T11 0 ] * Z
                           [  0  0 ]
            The minimum-norm solution is then
               X = P * Z' [ inv(T11)*Q1'*B ]
                          [        0       ]
            where Q1 consists of the first RANK columns of Q.

            Arguments
            =========

            M       (input) INTEGER
                    The number of rows of the matrix A.  M >= 0.

            N       (input) INTEGER
                    The number of columns of the matrix A.  N >= 0.

            NRHS    (input) INTEGER
                    The number of right hand sides, i.e., the number of
                    columns of matrices B and X. NRHS >= 0.

            A       (input/output) DOUBLE PRECISION array, dimension (LDA,N)
                    On entry, the M-by-N matrix A.
                    On exit, A has been overwritten by details of its
                    complete orthogonal factorization.

            LDA     (input) INTEGER
                    The leading dimension of the array A.  LDA >= max(1,M).

            B       (input/output) DOUBLE PRECISION array, dimension (LDB,NRHS)
                    On entry, the M-by-NRHS right hand side matrix B.
                    On exit, the N-by-NRHS solution matrix X.
                    If m >= n and RANK = n, the residual sum-of-squares for
                    the solution in the i-th column is given by the sum of
                    squares of elements N+1:M in that column.

            LDB     (input) INTEGER
                    The leading dimension of the array B. LDB >= max(1,M,N).

            JPVT    (input/output) INTEGER array, dimension (N)
                    On entry, if JPVT(i) .ne. 0, the i-th column of A is an
                    initial column, otherwise it is a free column.  Before
                    the QR factorization of A, all initial columns are
                    permuted to the leading positions; only the remaining
                    free columns are moved as a result of column pivoting
                    during the factorization.
                    On exit, if JPVT(i) = k, then the i-th column of A*P
                    was the k-th column of A.

            RCOND   (input) DOUBLE PRECISION
                    RCOND is used to determine the effective rank of A, which
                    is defined as the order of the largest leading triangular
                    submatrix R11 in the QR factorization with pivoting of A,
                    whose estimated condition number < 1/RCOND.

            RANK    (output) INTEGER
                    The effective rank of A, i.e., the order of the submatrix
                    R11.  This is the same as the order of the submatrix T11
                    in the complete orthogonal factorization of A.

            WORK    (workspace) DOUBLE PRECISION array, dimension
                                (max( min(M,N)+3*N, 2*min(M,N)+NRHS )),

            INFO    (output) INTEGER
                    = 0:  successful exit
                    < 0:  if INFO = -i, the i-th argument had an illegal value
        "));
        end dgelsx_vec;
        annotation(Documentation(info = "<html>
      <p>
      This package contains external Modelica functions as interface to the
      LAPACK library
      (<a href=\"http://www.netlib.org/lapack\">http://www.netlib.org/lapack</a>)
      that provides FORTRAN subroutines to solve linear algebra
      tasks. Usually, these functions are not directly called, but only via
      the much more convenient interface of
      <a href=\"modelica://Modelica.Math.Matrices\">Modelica.Math.Matrices</a>.
      The documentation of the LAPACK functions is a copy of the original
      FORTRAN code. The details of LAPACK are described in:
      </p>

      <dl>
      <dt>Anderson E., Bai Z., Bischof C., Blackford S., Demmel J., Dongarra J.,
          Du Croz J., Greenbaum A., Hammarling S., McKenney A., and Sorensen D.:</dt>
      <dd> <a href=\"http://www.netlib.org/lapack/lug/lapack_lug.html\">Lapack Users' Guide</a>.
           Third Edition, SIAM, 1999.</dd>
      </dl>

      <p>
      See also <a href=\"http://en.wikipedia.org/wiki/Lapack\">http://en.wikipedia.org/wiki/Lapack</a>.
      </p>

      <p>
      This package contains a direct interface to the LAPACK subroutines
      </p>

      </html>"));
      end LAPACK;
      annotation(Documentation(info = "<HTML>
    <h4>Library content</h4>
    <p>
    This library provides functions operating on matrices. Below, the
    functions are ordered according to categories and a typical
    call of the respective function is shown.
    Most functions are solely an interface to the external
    <a href=\"modelica://Modelica.Math.Matrices.LAPACK\">LAPACK</a> library.
    </p>

    <p>
    Note: A' is a short hand notation of transpose(A):
    </p>

    <p><b>Basic Information</b></p>
    <ul>
    <li> <a href=\"modelica://Modelica.Math.Matrices.toString\">toString</a>(A)
         - returns the string representation of matrix A.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.isEqual\">isEqual</a>(M1, M2)
         - returns true if matrices M1 and M2 have the same size and the same elements.</li>
    </ul>

    <p><b>Linear Equations</b></p>
    <ul>
    <li> <a href=\"modelica://Modelica.Math.Matrices.solve\">solve</a>(A,b)
         - returns solution x of the linear equation A*x=b (where b is a vector,
           and A is a square matrix that must be regular).</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.solve2\">solve2</a>(A,B)
         - returns solution X of the linear equation A*X=B (where B is a matrix,
           and A is a square matrix that must be regular)</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.leastSquares\">leastSquares</a>(A,b)
         - returns solution x of the linear equation A*x=b in a least squares sense
           (where b is a vector and A may be non-square and may be rank deficient)</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.leastSquares2\">leastSquares2</a>(A,B)
         - returns solution X of the linear equation A*X=B in a least squares sense
           (where B is a matrix and A may be non-square and may be rank deficient)</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.equalityLeastSquares\">equalityLeastSquares</a>(A,a,B,b)
         - returns solution x of a linear equality constrained least squares problem:
           min|A*x-a|^2 subject to B*x=b</<li>

    <li> (LU,p,info) = <a href=\"modelica://Modelica.Math.Matrices.LU\">LU</a>(A)
         - returns the LU decomposition with row pivoting of a rectangular matrix A.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.LU_solve\">LU_solve</a>(LU,p,b)
         - returns solution x of the linear equation L*U*x[p]=b with a b
           vector and an LU decomposition from \"LU(..)\".</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.LU_solve2\">LU_solve2</a>(LU,p,B)
         - returns solution X of the linear equation L*U*X[p,:]=B with a B
           matrix and an LU decomposition from \"LU(..)\".</li>
    </ul>

    <p><b>Matrix Factorizations</b></p>
    <ul>
    <li> (eval,evec) = <a href=\"modelica://Modelica.Math.Matrices.eigenValues\">eigenValues</a>(A)
         - returns eigen values \"eval\" and eigen vectors \"evec\" for a real,
           nonsymmetric matrix A in a Real representation.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.eigenValueMatrix\">eigenValueMatrix</a>(eval)
         - returns real valued block diagonal matrix of the eigenvalues \"eval\" of matrix A.</li>

    <li> (sigma,U,VT) = <a href=\"modelica://Modelica.Math.Matrices.singularValues\">singularValues</a>(A)
         - returns singular values \"sigma\" and left and right singular vectors U and VT
           of a rectangular matrix A.</li>

    <li> (Q,R,p) = <a href=\"modelica://Modelica.Math.Matrices.QR\">QR</a>(A)
         - returns the QR decomposition with column pivoting of a rectangular matrix A
           such that Q*R = A[:,p].</li>

    <li> (H,U) = <a href=\"modelica://Modelica.Math.Matrices.hessenberg\">hessenberg</a>(A)
         - returns the upper Hessenberg form H and the orthogonal transformation matrix U
           of a square matrix A such that H = U'*A*U.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.realSchur\">realSchur</a>(A)
         - returns the real Schur form of a square matrix A.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.cholesky\">cholesky</a>(A)
         - returns the cholesky factor H of a real symmetric positive definite matrix A so that A = H'*H.</li>

    <li> (D,Aimproved) = <a href=\"modelica://Modelica.Math.Matrices.balance\">balance</a>(A)
         - returns an improved form Aimproved of a square matrix A that has a smaller condition as A,
           with Aimproved = inv(diagonal(D))*A*diagonal(D).</li>
    </ul>

    <p><b>Matrix Properties</b></p>
    <ul>
    <li> <a href=\"modelica://Modelica.Math.Matrices.trace\">trace</a>(A)
         - returns the trace of square matrix A, i.e., the sum of the diagonal elements.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.det\">det</a>(A)
         - returns the determinant of square matrix A (using LU decomposition; try to avoid det(..))</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.inv\">inv</a>(A)
         - returns the inverse of square matrix A (try to avoid, use instead \"solve2(..) with B=identity(..))</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.rank\">rank</a>(A)
         - returns the rank of square matrix A (computed with singular value decomposition)</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.conditionNumber\">conditionNumber</a>(A)
         - returns the condition number norm(A)*norm(inv(A)) of a square matrix A in the range 1..&infin;.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.rcond\">rcond</a>(A)
         - returns the reciprocal condition number 1/conditionNumber(A) of a square matrix A in the range 0..1.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.norm\">norm</a>(A)
         - returns the 1-, 2-, or infinity-norm of matrix A.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.frobeniusNorm\">frobeniusNorm</a>(A)
         - returns the Frobenius norm of matrix A.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.nullSpace\">nullSpace</a>(A)
         - returns the null space of matrix A.</li>
    </ul>

    <p><b>Matrix Exponentials</b></p>
    <ul>
    <li> <a href=\"modelica://Modelica.Math.Matrices.exp\">exp</a>(A)
         - returns the exponential e^A of a matrix A by adaptive Taylor series
           expansion with scaling and balancing</li>

    <li> (phi, gamma) = <a href=\"modelica://Modelica.Math.Matrices.integralExp\">integralExp</a>(A,B)
         - returns the exponential phi=e^A and the integral gamma=integral(exp(A*t)*dt)*B as needed
           for a discretized system with zero order hold.</li>

    <li> (phi, gamma, gamma1) = <a href=\"modelica://Modelica.Math.Matrices.integralExpT\">integralExpT</a>(A,B)
         - returns the exponential phi=e^A, the integral gamma=integral(exp(A*t)*dt)*B,
           and the time-weighted integral gamma1 = integral((T-t)*exp(A*t)*dt)*B as needed
           for a discretized system with first order hold.</li>
    </ul>

    <p><b>Matrix Equations</b></p>
    <ul>
    <li> <a href=\"modelica://Modelica.Math.Matrices.continuousLyapunov\">continuousLyapunov</a>(A,C)
         - returns solution X of the continuous-time Lyapunov equation X*A + A'*X = C</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.continuousSylvester\">continuousSylvester</a>(A,B,C)
         - returns solution X of the continuous-time Sylvester equation A*X + X*B = C</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.continuousRiccati\">continuousRiccati</a>(A,B,R,Q)
         - returns solution X of the continuous-time algebraic Riccati equation
           A'*X + X*A - X*B*inv(R)*B'*X + Q = 0</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.discreteLyapunov\">discreteLyapunov</a>(A,C)
         - returns solution X of the discrete-time Lyapunov equation A'*X*A + sgn*X = C</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.discreteSylvester\">discreteSylvester</a>(A,B,C)
         - returns solution X of the discrete-time Sylvester equation A*X*B + sgn*X = C</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.discreteRiccati\">discreteRiccati</a>(A,B,R,Q)
         - returns solution X of the discrete-time algebraic Riccati equation
           A'*X*A - X - A'*X*B*inv(R + B'*X*B)*B'*X*A + Q = 0</li>
    </ul>

    <p><b>Matrix Manipulation</b></p>
    <ul>
    <li> <a href=\"modelica://Modelica.Math.Matrices.sort\">sort</a>(M)
         - returns the sorted rows or columns of matrix M in ascending or descending order.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.flipLeftRight\">flipLeftRight</a>(M)
         - returns matrix M so that the columns of M are flipped in left/right direction.</li>

    <li> <a href=\"modelica://Modelica.Math.Matrices.flipUpDown\">flipUpDown</a>(M)
         - returns matrix M so that the rows of M are flipped in up/down direction.</li>
    </ul>

    <h4>See also</h4>
    <a href=\"modelica://Modelica.Math.Vectors\">Vectors</a>

    </html>"));
    end Matrices;

    package BooleanVectors  "Library of functions operating on Boolean vectors"
      extends Modelica.Icons.Package;

      function anyTrue  "Returns true, if at least on element of the Boolean input vector is true ('or')"
        extends Modelica.Icons.Function;
        input Boolean[:] b;
        output Boolean result;
      algorithm
        result := false;
        for i in 1:size(b, 1) loop
          result := result or b[i];
        end for;
        annotation(Documentation(info = "<html>
      <h4>Syntax</h4>
      <blockquote><pre>
      <b>anyTrue</b>(b);
      </pre></blockquote>

      <h4>Description</h4>
      <p>
      Returns <b>true</b> if at least one elements of the input Boolean vector b is <b>true</b>.
      Otherwise the function returns <b>false</b>. If b is an empty vector,
      i.e., size(b,1)=0, the function returns <b>false</b>.
      </p>

      <h4>Example</h4>
      <blockquote><pre>
        Boolean b1[3] = {false, false, false};
        Boolean b2[3] = {false, true, false};
        Boolean r1, r2;
      <b>algorithm</b>
        r1 = anyTrue(b1);  // r1 = false
        r2 = anyTrue(b2);  // r2 = true
      </pre></blockquote>

      <h4>See also</h4>
      <p>
      <a href=\"modelica://Modelica.Math.BooleanVectors.allTrue\">allTrue</a>,
      <a href=\"modelica://Modelica.Math.BooleanVectors.countTrue\">countTrue</a>,
      <a href=\"modelica://Modelica.Math.BooleanVectors.enumerate\">enumerate</a>,
      <a href=\"modelica://Modelica.Math.BooleanVectors.firstTrueIndex\">firstTrueIndex</a>,
      <a href=\"modelica://Modelica.Math.BooleanVectors.index\">index</a>, and
      <a href=\"modelica://Modelica.Math.BooleanVectors.oneTrue\">oneTrue</a>.
      </p>
      </html>"));
      end anyTrue;
      annotation(Documentation(info = "<html>
    <p>
    This library provides functions operating on vectors that have
    a Boolean vector as input argument.
    </p>
    </html>"));
    end BooleanVectors;

    function cos  "Cosine"
      extends Modelica.Math.Icons.AxisLeft;
      input .Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = cos(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-74.4, 78.1}, {-68.7, 72.3}, {-63.1, 63}, {-56.7, 48.7}, {-48.6, 26.6}, {-29.3, -32.5}, {-22.1, -51.7}, {-15.7, -65.3}, {-10.1, -73.8}, {-4.42, -78.8}, {1.21, -79.9}, {6.83, -77.1}, {12.5, -70.6}, {18.1, -60.6}, {24.5, -45.7}, {32.6, -23}, {50.3, 31.3}, {57.5, 50.7}, {63.9, 64.6}, {69.5, 73.4}, {75.2, 78.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-36, 82}, {36, 34}}, lineColor = {192, 192, 192}, textString = "cos")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-103, 72}, {-83, 88}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{-103, -72}, {-83, -88}}, textString = "-1", lineColor = {0, 0, 255}), Text(extent = {{70, 25}, {90, 5}}, textString = "2*pi", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-74.4, 78.1}, {-68.7, 72.3}, {-63.1, 63}, {-56.7, 48.7}, {-48.6, 26.6}, {-29.3, -32.5}, {-22.1, -51.7}, {-15.7, -65.3}, {-10.1, -73.8}, {-4.42, -78.8}, {1.21, -79.9}, {6.83, -77.1}, {12.5, -70.6}, {18.1, -60.6}, {24.5, -45.7}, {32.6, -23}, {50.3, 31.3}, {57.5, 50.7}, {63.9, 64.6}, {69.5, 73.4}, {75.2, 78.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{78, -6}, {98, -26}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{-80, -80}, {18, -80}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = cos(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/cos.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-74.4, 78.1}, {-68.7, 72.3}, {-63.1, 63}, {-56.7, 48.7}, {-48.6, 26.6}, {-29.3, -32.5}, {-22.1, -51.7}, {-15.7, -65.3}, {-10.1, -73.8}, {-4.42, -78.8}, {1.21, -79.9}, {6.83, -77.1}, {12.5, -70.6}, {18.1, -60.6}, {24.5, -45.7}, {32.6, -23}, {50.3, 31.3}, {57.5, 50.7}, {63.9, 64.6}, {69.5, 73.4}, {75.2, 78.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-36, 82}, {36, 34}}, lineColor = {192, 192, 192}, textString = "cos")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-103, 72}, {-83, 88}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{-103, -72}, {-83, -88}}, textString = "-1", lineColor = {0, 0, 255}), Text(extent = {{70, 25}, {90, 5}}, textString = "2*pi", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-74.4, 78.1}, {-68.7, 72.3}, {-63.1, 63}, {-56.7, 48.7}, {-48.6, 26.6}, {-29.3, -32.5}, {-22.1, -51.7}, {-15.7, -65.3}, {-10.1, -73.8}, {-4.42, -78.8}, {1.21, -79.9}, {6.83, -77.1}, {12.5, -70.6}, {18.1, -60.6}, {24.5, -45.7}, {32.6, -23}, {50.3, 31.3}, {57.5, 50.7}, {63.9, 64.6}, {69.5, 73.4}, {75.2, 78.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{78, -6}, {98, -26}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{-80, -80}, {18, -80}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = cos(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/cos.png\">
    </p>
    </html>"));
    end cos;

    function tan  "Tangent (u shall not be -pi/2, pi/2, 3*pi/2, ...)"
      extends Modelica.Math.Icons.AxisCenter;
      input .Modelica.SIunits.Angle u;
      output Real y;
      external "builtin" y = tan(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-78.4, -68.4}, {-76.8, -59.7}, {-74.4, -50}, {-71.2, -40.9}, {-67.1, -33}, {-60.7, -24.8}, {-51.1, -17.2}, {-35.8, -9.98}, {-4.42, -1.07}, {33.4, 9.12}, {49.4, 16.2}, {59.1, 23.2}, {65.5, 30.6}, {70.4, 39.1}, {73.6, 47.4}, {76, 56.1}, {77.6, 63.8}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-90, 72}, {-18, 24}}, lineColor = {192, 192, 192}, textString = "tan")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-37, -72}, {-17, -88}}, textString = "-5.8", lineColor = {0, 0, 255}), Text(extent = {{-33, 86}, {-13, 70}}, textString = " 5.8", lineColor = {0, 0, 255}), Text(extent = {{68, -13}, {88, -33}}, textString = "1.4", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-78.4, -68.4}, {-76.8, -59.7}, {-74.4, -50}, {-71.2, -40.9}, {-67.1, -33}, {-60.7, -24.8}, {-51.1, -17.2}, {-35.8, -9.98}, {-4.42, -1.07}, {33.4, 9.12}, {49.4, 16.2}, {59.1, 23.2}, {65.5, 30.6}, {70.4, 39.1}, {73.6, 47.4}, {76, 56.1}, {77.6, 63.8}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 22}, {102, 2}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 88}, {80, -16}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = tan(u), with -&infin; &lt; u &lt; &infin;
    (if u is a multiple of (2n-1)*pi/2, y = tan(u) is +/- infinity).
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/tan.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-78.4, -68.4}, {-76.8, -59.7}, {-74.4, -50}, {-71.2, -40.9}, {-67.1, -33}, {-60.7, -24.8}, {-51.1, -17.2}, {-35.8, -9.98}, {-4.42, -1.07}, {33.4, 9.12}, {49.4, 16.2}, {59.1, 23.2}, {65.5, 30.6}, {70.4, 39.1}, {73.6, 47.4}, {76, 56.1}, {77.6, 63.8}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-90, 72}, {-18, 24}}, lineColor = {192, 192, 192}, textString = "tan")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-37, -72}, {-17, -88}}, textString = "-5.8", lineColor = {0, 0, 255}), Text(extent = {{-33, 86}, {-13, 70}}, textString = " 5.8", lineColor = {0, 0, 255}), Text(extent = {{68, -13}, {88, -33}}, textString = "1.4", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-78.4, -68.4}, {-76.8, -59.7}, {-74.4, -50}, {-71.2, -40.9}, {-67.1, -33}, {-60.7, -24.8}, {-51.1, -17.2}, {-35.8, -9.98}, {-4.42, -1.07}, {33.4, 9.12}, {49.4, 16.2}, {59.1, 23.2}, {65.5, 30.6}, {70.4, 39.1}, {73.6, 47.4}, {76, 56.1}, {77.6, 63.8}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 22}, {102, 2}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 88}, {80, -16}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = tan(u), with -&infin; &lt; u &lt; &infin;
    (if u is a multiple of (2n-1)*pi/2, y = tan(u) is +/- infinity).
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/tan.png\">
    </p>
    </html>"));
    end tan;

    function asin  "Inverse sine (-1 <= u <= 1)"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output .Modelica.SIunits.Angle y;
      external "builtin" y = asin(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = asin(u), with -1 &le; u &le; +1:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 78}, {-16, 30}}, lineColor = {192, 192, 192}, textString = "asin")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-40, -72}, {-15, -88}}, textString = "-pi/2", lineColor = {0, 0, 255}), Text(extent = {{-38, 88}, {-13, 72}}, textString = " pi/2", lineColor = {0, 0, 255}), Text(extent = {{68, -9}, {88, -29}}, textString = "+1", lineColor = {0, 0, 255}), Text(extent = {{-90, 21}, {-70, 1}}, textString = "-1", lineColor = {0, 0, 255}), Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{98, 0}, {82, 6}, {82, -6}, {98, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -72.8}, {-77.6, -67.5}, {-73.6, -59.4}, {-66.3, -49.8}, {-53.5, -37.3}, {-30.2, -19.7}, {37.4, 24.8}, {57.5, 40.8}, {68.7, 52.7}, {75.2, 62.2}, {77.6, 67.5}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{82, 24}, {102, 4}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {86, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 86}, {80, -10}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = asin(u), with -1 &le; u &le; +1:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/asin.png\">
    </p>
    </html>"));
    end asin;

    function cosh  "Hyperbolic cosine"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = cosh(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -86.083}, {68, -86.083}}, color = {192, 192, 192}), Polygon(points = {{90, -86.083}, {68, -78.083}, {68, -94.083}, {90, -86.083}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-77.6, 61.1}, {-74.4, 39.3}, {-71.2, 20.7}, {-67.1, 1.29}, {-63.1, -14.6}, {-58.3, -29.8}, {-52.7, -43.5}, {-46.2, -55.1}, {-39, -64.3}, {-30.2, -71.7}, {-18.9, -77.1}, {-4.42, -79.9}, {10.9, -79.1}, {23.7, -75.2}, {34.2, -68.7}, {42.2, -60.6}, {48.6, -51.2}, {54.3, -40}, {59.1, -27.5}, {63.1, -14.6}, {67.1, 1.29}, {71.2, 20.7}, {74.4, 39.3}, {77.6, 61.1}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{4, 66}, {66, 20}}, lineColor = {192, 192, 192}, textString = "cosh")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -84.083}, {84, -84.083}}, color = {95, 95, 95}), Polygon(points = {{98, -84.083}, {82, -78.083}, {82, -90.083}, {98, -84.083}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-77.6, 61.1}, {-74.4, 39.3}, {-71.2, 20.7}, {-67.1, 1.29}, {-63.1, -14.6}, {-58.3, -29.8}, {-52.7, -43.5}, {-46.2, -55.1}, {-39, -64.3}, {-30.2, -71.7}, {-18.9, -77.1}, {-4.42, -79.9}, {10.9, -79.1}, {23.7, -75.2}, {34.2, -68.7}, {42.2, -60.6}, {48.6, -51.2}, {54.3, -40}, {59.1, -27.5}, {63.1, -14.6}, {67.1, 1.29}, {71.2, 20.7}, {74.4, 39.3}, {77.6, 61.1}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "27", lineColor = {0, 0, 255}), Text(extent = {{64, -83}, {84, -103}}, textString = "4", lineColor = {0, 0, 255}), Text(extent = {{-94, -63}, {-74, -83}}, textString = "-4", lineColor = {0, 0, 255}), Text(extent = {{80, -60}, {100, -80}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -90}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = cosh(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/cosh.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -86.083}, {68, -86.083}}, color = {192, 192, 192}), Polygon(points = {{90, -86.083}, {68, -78.083}, {68, -94.083}, {90, -86.083}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-77.6, 61.1}, {-74.4, 39.3}, {-71.2, 20.7}, {-67.1, 1.29}, {-63.1, -14.6}, {-58.3, -29.8}, {-52.7, -43.5}, {-46.2, -55.1}, {-39, -64.3}, {-30.2, -71.7}, {-18.9, -77.1}, {-4.42, -79.9}, {10.9, -79.1}, {23.7, -75.2}, {34.2, -68.7}, {42.2, -60.6}, {48.6, -51.2}, {54.3, -40}, {59.1, -27.5}, {63.1, -14.6}, {67.1, 1.29}, {71.2, 20.7}, {74.4, 39.3}, {77.6, 61.1}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{4, 66}, {66, 20}}, lineColor = {192, 192, 192}, textString = "cosh")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -84.083}, {84, -84.083}}, color = {95, 95, 95}), Polygon(points = {{98, -84.083}, {82, -78.083}, {82, -90.083}, {98, -84.083}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 80}, {-77.6, 61.1}, {-74.4, 39.3}, {-71.2, 20.7}, {-67.1, 1.29}, {-63.1, -14.6}, {-58.3, -29.8}, {-52.7, -43.5}, {-46.2, -55.1}, {-39, -64.3}, {-30.2, -71.7}, {-18.9, -77.1}, {-4.42, -79.9}, {10.9, -79.1}, {23.7, -75.2}, {34.2, -68.7}, {42.2, -60.6}, {48.6, -51.2}, {54.3, -40}, {59.1, -27.5}, {63.1, -14.6}, {67.1, 1.29}, {71.2, 20.7}, {74.4, 39.3}, {77.6, 61.1}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "27", lineColor = {0, 0, 255}), Text(extent = {{64, -83}, {84, -103}}, textString = "4", lineColor = {0, 0, 255}), Text(extent = {{-94, -63}, {-74, -83}}, textString = "-4", lineColor = {0, 0, 255}), Text(extent = {{80, -60}, {100, -80}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -90}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = cosh(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/cosh.png\">
    </p>
    </html>"));
    end cosh;

    function tanh  "Hyperbolic tangent"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = tanh(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-47.8, -78.7}, {-35.8, -75.7}, {-27.7, -70.6}, {-22.1, -64.2}, {-17.3, -55.9}, {-12.5, -44.3}, {-7.64, -29.2}, {-1.21, -4.82}, {6.83, 26.3}, {11.7, 42}, {16.5, 54.2}, {21.3, 63.1}, {26.9, 69.9}, {34.2, 75}, {45.4, 78.4}, {72, 79.9}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 72}, {-16, 24}}, lineColor = {192, 192, 192}, textString = "tanh")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{96, 0}, {80, 6}, {80, -6}, {96, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80.5}, {-47.8, -79.2}, {-35.8, -76.2}, {-27.7, -71.1}, {-22.1, -64.7}, {-17.3, -56.4}, {-12.5, -44.8}, {-7.64, -29.7}, {-1.21, -5.32}, {6.83, 25.8}, {11.7, 41.5}, {16.5, 53.7}, {21.3, 62.6}, {26.9, 69.4}, {34.2, 74.5}, {45.4, 77.9}, {72, 79.4}, {80, 79.5}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-29, 72}, {-9, 88}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{3, -72}, {23, -88}}, textString = "-1", lineColor = {0, 0, 255}), Text(extent = {{82, -2}, {102, -22}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = tanh(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/tanh.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-47.8, -78.7}, {-35.8, -75.7}, {-27.7, -70.6}, {-22.1, -64.2}, {-17.3, -55.9}, {-12.5, -44.3}, {-7.64, -29.2}, {-1.21, -4.82}, {6.83, 26.3}, {11.7, 42}, {16.5, 54.2}, {21.3, 63.1}, {26.9, 69.9}, {34.2, 75}, {45.4, 78.4}, {72, 79.9}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-88, 72}, {-16, 24}}, lineColor = {192, 192, 192}, textString = "tanh")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{96, 0}, {80, 6}, {80, -6}, {96, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80.5}, {-47.8, -79.2}, {-35.8, -76.2}, {-27.7, -71.1}, {-22.1, -64.7}, {-17.3, -56.4}, {-12.5, -44.8}, {-7.64, -29.7}, {-1.21, -5.32}, {6.83, 25.8}, {11.7, 41.5}, {16.5, 53.7}, {21.3, 62.6}, {26.9, 69.4}, {34.2, 74.5}, {45.4, 77.9}, {72, 79.4}, {80, 79.5}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-29, 72}, {-9, 88}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{3, -72}, {23, -88}}, textString = "-1", lineColor = {0, 0, 255}), Text(extent = {{82, -2}, {102, -22}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = tanh(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/tanh.png\">
    </p>
    </html>"));
    end tanh;

    function exp  "Exponential, base e"
      extends Modelica.Math.Icons.AxisCenter;
      input Real u;
      output Real y;
      external "builtin" y = exp(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, -80.3976}, {68, -80.3976}}, color = {192, 192, 192}), Polygon(points = {{90, -80.3976}, {68, -72.3976}, {68, -88.3976}, {90, -80.3976}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-86, 50}, {-14, 2}}, lineColor = {192, 192, 192}, textString = "exp")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, -80.3976}, {84, -80.3976}}, color = {95, 95, 95}), Polygon(points = {{98, -80.3976}, {82, -74.3976}, {82, -86.3976}, {98, -80.3976}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-31, -77.9}, {-6.03, -74}, {10.9, -68.4}, {23.7, -61}, {34.2, -51.6}, {43, -40.3}, {50.3, -27.8}, {56.7, -13.5}, {62.3, 2.23}, {67.1, 18.6}, {72, 38.2}, {76, 57.6}, {80, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-31, 72}, {-11, 88}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-92, -81}, {-72, -101}}, textString = "-3", lineColor = {0, 0, 255}), Text(extent = {{66, -81}, {86, -101}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{2, -69}, {22, -89}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{78, -54}, {98, -74}}, lineColor = {95, 95, 95}, textString = "u"), Line(points = {{0, 80}, {88, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{80, 84}, {80, -84}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = exp(u), with -&infin; &lt; u &lt; &infin;:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/exp.png\">
    </p>
    </html>"));
    end exp;

    function log  "Natural (base e) logarithm (u shall be > 0)"
      extends Modelica.Math.Icons.AxisLeft;
      input Real u;
      output Real y;
      external "builtin" y = log(u) annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -50.6}, {-78.4, -37}, {-77.6, -28}, {-76.8, -21.3}, {-75.2, -11.4}, {-72.8, -1.31}, {-69.5, 8.08}, {-64.7, 17.9}, {-57.5, 28}, {-47, 38.1}, {-31.8, 48.1}, {-10.1, 58}, {22.1, 68}, {68.7, 78.1}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-6, -24}, {66, -72}}, lineColor = {192, 192, 192}, textString = "log")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{100, 0}, {84, 6}, {84, -6}, {100, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-78, -80}, {-77.2, -50.6}, {-76.4, -37}, {-75.6, -28}, {-74.8, -21.3}, {-73.2, -11.4}, {-70.8, -1.31}, {-67.5, 8.08}, {-62.7, 17.9}, {-55.5, 28}, {-45, 38.1}, {-29.8, 48.1}, {-8.1, 58}, {24.1, 68}, {70.7, 78.1}, {82, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-105, 72}, {-85, 88}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{60, -3}, {80, -23}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-78, -7}, {-58, -27}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{84, 26}, {104, 6}}, lineColor = {95, 95, 95}, textString = "u"), Text(extent = {{-100, 9}, {-80, -11}}, textString = "0", lineColor = {0, 0, 255}), Line(points = {{-80, 80}, {84, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{82, 82}, {82, -6}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = log(10) (the natural logarithm of u),
    with u &gt; 0:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/log.png\">
    </p>
    </html>"));
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-90, 0}, {68, 0}}, color = {192, 192, 192}), Polygon(points = {{90, 0}, {68, 8}, {68, -8}, {90, 0}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, -80}, {-79.2, -50.6}, {-78.4, -37}, {-77.6, -28}, {-76.8, -21.3}, {-75.2, -11.4}, {-72.8, -1.31}, {-69.5, 8.08}, {-64.7, 17.9}, {-57.5, 28}, {-47, 38.1}, {-31.8, 48.1}, {-10.1, 58}, {22.1, 68}, {68.7, 78.1}, {80, 80}}, color = {0, 0, 0}), Text(extent = {{-6, -24}, {66, -72}}, lineColor = {192, 192, 192}, textString = "log")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-100, 0}, {84, 0}}, color = {95, 95, 95}), Polygon(points = {{100, 0}, {84, 6}, {84, -6}, {100, 0}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-78, -80}, {-77.2, -50.6}, {-76.4, -37}, {-75.6, -28}, {-74.8, -21.3}, {-73.2, -11.4}, {-70.8, -1.31}, {-67.5, 8.08}, {-62.7, 17.9}, {-55.5, 28}, {-45, 38.1}, {-29.8, 48.1}, {-8.1, 58}, {24.1, 68}, {70.7, 78.1}, {82, 80}}, color = {0, 0, 255}, thickness = 0.5), Text(extent = {{-105, 72}, {-85, 88}}, textString = "3", lineColor = {0, 0, 255}), Text(extent = {{60, -3}, {80, -23}}, textString = "20", lineColor = {0, 0, 255}), Text(extent = {{-78, -7}, {-58, -27}}, textString = "1", lineColor = {0, 0, 255}), Text(extent = {{84, 26}, {104, 6}}, lineColor = {95, 95, 95}, textString = "u"), Text(extent = {{-100, 9}, {-80, -11}}, textString = "0", lineColor = {0, 0, 255}), Line(points = {{-80, 80}, {84, 80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{82, 82}, {82, -6}}, color = {175, 175, 175}, smooth = Smooth.None)}), Documentation(info = "<html>
    <p>
    This function returns y = log(10) (the natural logarithm of u),
    with u &gt; 0:
    </p>

    <p>
    <img src=\"modelica://Modelica/Resources/Images/Math/log.png\">
    </p>
    </html>"));
    end log;
    annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.4}, {-49.4, 74.6}, {-43.8, 79.1}, {-38.2, 79.8}, {-32.6, 76.6}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.1}, {35, -78.4}, {40.6, -80}, {46.2, -77.6}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 0}, smooth = Smooth.Bezier)}), Documentation(info = "<HTML>
  <p>
  This package contains <b>basic mathematical functions</b> (such as sin(..)),
  as well as functions operating on
  <a href=\"modelica://Modelica.Math.Vectors\">vectors</a>,
  <a href=\"modelica://Modelica.Math.Matrices\">matrices</a>,
  <a href=\"modelica://Modelica.Math.Nonlinear\">nonlinear functions</a>, and
  <a href=\"modelica://Modelica.Math.BooleanVectors\">Boolean vectors</a>.
  </p>

  <dl>
  <dt><b>Main Authors:</b>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and
      Marcus Baur<br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e.V. (DLR)<br>
      Institut f&uuml;r Robotik und Mechatronik<br>
      Postfach 1116<br>
      D-82230 Wessling<br>
      Germany<br>
      email: <A HREF=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</A><br>
  </dl>

  <p>
  Copyright &copy; 1998-2015, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>October 21, 2002</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>
         and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
         Function tempInterpol2 added.</li>
  <li><i>Oct. 24, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Icons for icon and diagram level introduced.</li>
  <li><i>June 30, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized.</li>
  </ul>

  </html>"));
  end Math;

  package Utilities  "Library of utility functions dedicated to scripting (operating on files, streams, strings, system)"
    extends Modelica.Icons.Package;

    package Streams  "Read from files and write to files"
      extends Modelica.Icons.Package;

      function error  "Print error message and cancel all actions"
        extends Modelica.Icons.Function;
        input String string "String to be printed to error message window";
        external "C" ModelicaError(string) annotation(Library = "ModelicaExternalC", Documentation(info = "<html>
      <h4>Syntax</h4>
      <blockquote><pre>
      Streams.<b>error</b>(string);
      </pre></blockquote>
      <h4>Description</h4>
      <p>
      Print the string \"string\" as error message and
      cancel all actions. Line breaks are characterized
      by \"\\n\" in the string.
      </p>
      <h4>Example</h4>
      <blockquote><pre>
        Streams.error(\"x (= \" + String(x) + \")\\nhas to be in the range 0 .. 1\");
      </pre></blockquote>
      <h4>See also</h4>
      <p>
      <a href=\"modelica://Modelica.Utilities.Streams\">Streams</a>,
      <a href=\"modelica://Modelica.Utilities.Streams.print\">Streams.print</a>,
      <a href=\"modelica://ModelicaReference.Operators.'String()'\">ModelicaReference.Operators.'String()'</a>
      </p>
      </html>"));
        annotation(Documentation(info = "<html>
      <h4>Syntax</h4>
      <blockquote><pre>
      Streams.<b>error</b>(string);
      </pre></blockquote>
      <h4>Description</h4>
      <p>
      Print the string \"string\" as error message and
      cancel all actions. Line breaks are characterized
      by \"\\n\" in the string.
      </p>
      <h4>Example</h4>
      <blockquote><pre>
        Streams.error(\"x (= \" + String(x) + \")\\nhas to be in the range 0 .. 1\");
      </pre></blockquote>
      <h4>See also</h4>
      <p>
      <a href=\"modelica://Modelica.Utilities.Streams\">Streams</a>,
      <a href=\"modelica://Modelica.Utilities.Streams.print\">Streams.print</a>,
      <a href=\"modelica://ModelicaReference.Operators.'String()'\">ModelicaReference.Operators.'String()'</a>
      </p>
      </html>"));
      end error;
      annotation(Documentation(info = "<HTML>
    <h4>Library content</h4>
    <p>
    Package <b>Streams</b> contains functions to input and output strings
    to a message window or on files. Note that a string is interpreted
    and displayed as html text (e.g., with print(..) or error(..))
    if it is enclosed with the Modelica html quotation, e.g.,
    </p>
    <center>
    string = \"&lt;html&gt; first line &lt;br&gt; second line &lt;/html&gt;\".
    </center>
    <p>
    It is a quality of implementation, whether (a) all tags of html are supported
    or only a subset, (b) how html tags are interpreted if the output device
    does not allow to display formatted text.
    </p>
    <p>
    In the table below an example call to every function is given:
    </p>
    <table border=1 cellspacing=0 cellpadding=2>
      <tr><th><b><i>Function/type</i></b></th><th><b><i>Description</i></b></th></tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Streams.print\">print</a>(string)<br>
              <a href=\"modelica://Modelica.Utilities.Streams.print\">print</a>(string,fileName)</td>
          <td valign=\"top\"> Print string \"string\" or vector of strings to message window or on
               file \"fileName\".</td>
      </tr>
      <tr><td valign=\"top\">stringVector =
             <a href=\"modelica://Modelica.Utilities.Streams.readFile\">readFile</a>(fileName)</td>
          <td valign=\"top\"> Read complete text file and return it as a vector of strings.</td>
      </tr>
      <tr><td valign=\"top\">(string, endOfFile) =
             <a href=\"modelica://Modelica.Utilities.Streams.readLine\">readLine</a>(fileName, lineNumber)</td>
          <td valign=\"top\">Returns from the file the content of line lineNumber.</td>
      </tr>
      <tr><td valign=\"top\">lines =
             <a href=\"modelica://Modelica.Utilities.Streams.countLines\">countLines</a>(fileName)</td>
          <td valign=\"top\">Returns the number of lines in a file.</td>
      </tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Streams.error\">error</a>(string)</td>
          <td valign=\"top\"> Print error message \"string\" to message window
               and cancel all actions</td>
      </tr>
      <tr><td valign=\"top\"><a href=\"modelica://Modelica.Utilities.Streams.close\">close</a>(fileName)</td>
          <td valign=\"top\"> Close file if it is still open. Ignore call if
               file is already closed or does not exist. </td>
      </tr>
    </table>
    <p>
    Use functions <b>scanXXX</b> from package
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
    <pre>
      <b>if</b> x &lt; 0 <b>or</b> x &gt; 1 <b>then</b>
         Streams.error(\"x (= \" + String(x) + \") has to be in the range 0 .. 1\");
      <b>end if</b>;
    </pre>
    </html>"));
    end Streams;
    annotation(Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {1.3835, -4.1418}, rotation = 45.0, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.0, 93.333}, {-15.0, 68.333}, {0.0, 58.333}, {15.0, 68.333}, {15.0, 93.333}, {20.0, 93.333}, {25.0, 83.333}, {25.0, 58.333}, {10.0, 43.333}, {10.0, -41.667}, {25.0, -56.667}, {25.0, -76.667}, {10.0, -91.667}, {0.0, -91.667}, {0.0, -81.667}, {5.0, -81.667}, {15.0, -71.667}, {15.0, -61.667}, {5.0, -51.667}, {-5.0, -51.667}, {-15.0, -61.667}, {-15.0, -71.667}, {-5.0, -81.667}, {0.0, -81.667}, {0.0, -91.667}, {-10.0, -91.667}, {-25.0, -76.667}, {-25.0, -56.667}, {-10.0, -41.667}, {-10.0, 43.333}, {-25.0, 58.333}, {-25.0, 83.333}, {-20.0, 93.333}}), Polygon(origin = {10.1018, 5.218}, rotation = -45.0, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-15.0, 87.273}, {15.0, 87.273}, {20.0, 82.273}, {20.0, 27.273}, {10.0, 17.273}, {10.0, 7.273}, {20.0, 2.273}, {20.0, -2.727}, {5.0, -2.727}, {5.0, -77.727}, {10.0, -87.727}, {5.0, -112.727}, {-5.0, -112.727}, {-10.0, -87.727}, {-5.0, -77.727}, {-5.0, -2.727}, {-20.0, -2.727}, {-20.0, 2.273}, {-10.0, 7.273}, {-10.0, 17.273}, {-20.0, 27.273}, {-20.0, 82.273}})}), Documentation(info = "<html>
  <p>
  This package contains Modelica <b>functions</b> that are
  especially suited for <b>scripting</b>. The functions might
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
  Copyright &copy; 1998-2015, Modelica Association, DLR, and Dassault Syst&egrave;mes AB.
  </p>

  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>

  </html>"));
  end Utilities;

  package Constants  "Library of mathematical constants and constants of nature (e.g., pi, eps, R, sigma)"
    extends Modelica.Icons.Package;
    final constant Real pi = 2 * Math.asin(1.0);
    final constant Real eps = ModelicaServices.Machine.eps "Biggest number such that 1.0 + eps = 1.0";
    final constant Real small = ModelicaServices.Machine.small "Smallest number such that small and -small are representable on the machine";
    final constant Real inf = ModelicaServices.Machine.inf "Biggest Real number such that inf and -inf are representable on the machine";
    final constant .Modelica.SIunits.Velocity c = 299792458 "Speed of light in vacuum";
    final constant .Modelica.SIunits.Acceleration g_n = 9.80665 "Standard acceleration of gravity on earth";
    final constant Real R(final unit = "J/(mol.K)") = 8.314472 "Molar gas constant";
    final constant Real mue_0(final unit = "N/A2") = 4 * pi * 1.e-7 "Magnetic constant";
    final constant .Modelica.SIunits.Conversions.NonSIunits.Temperature_degC T_zero = -273.15 "Absolute zero temperature";
    annotation(Documentation(info = "<html>
  <p>
  This package provides often needed constants from mathematics, machine
  dependent constants and constants from nature. The latter constants
  (name, value, description) are from the following source:
  </p>

  <dl>
  <dt>Peter J. Mohr and Barry N. Taylor (1999):</dt>
  <dd><b>CODATA Recommended Values of the Fundamental Physical Constants: 1998</b>.
      Journal of Physical and Chemical Reference Data, Vol. 28, No. 6, 1999 and
      Reviews of Modern Physics, Vol. 72, No. 2, 2000. See also <a href=
  \"http://physics.nist.gov/cuu/Constants/\">http://physics.nist.gov/cuu/Constants/</a></dd>
  </dl>

  <p>CODATA is the Committee on Data for Science and Technology.</p>

  <dl>
  <dt><b>Main Author:</b></dt>
  <dd><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a><br>
      Deutsches Zentrum f&uuml;r Luft und Raumfahrt e. V. (DLR)<br>
      Oberpfaffenhofen<br>
      Postfach 11 16<br>
      D-82230 We&szlig;ling<br>
      email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
  </dl>

  <p>
  Copyright &copy; 1998-2015, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>Nov 8, 2004</i>
         by <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br>
         Constants updated according to 2002 CODATA values.</li>
  <li><i>Dec 9, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Constants updated according to 1998 CODATA values. Using names, values
         and description text from this source. Included magnetic and
         electric constant.</li>
  <li><i>Sep 18, 1999</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Constants eps, inf, small introduced.</li>
  <li><i>Nov 15, 1997</i>
         by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br>
         Realized.</li>
  </ul>
  </html>"), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-9.2597, 25.6673}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{48.017, 11.336}, {48.017, 11.336}, {10.766, 11.336}, {-25.684, 10.95}, {-34.944, -15.111}, {-34.944, -15.111}, {-32.298, -15.244}, {-32.298, -15.244}, {-22.112, 0.168}, {11.292, 0.234}, {48.267, -0.097}, {48.267, -0.097}}, smooth = Smooth.Bezier), Polygon(origin = {-19.9923, -8.3993}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{3.239, 37.343}, {3.305, 37.343}, {-0.399, 2.683}, {-16.936, -20.071}, {-7.808, -28.604}, {6.811, -22.519}, {9.986, 37.145}, {9.986, 37.145}}, smooth = Smooth.Bezier), Polygon(origin = {23.753, -11.5422}, fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-10.873, 41.478}, {-10.873, 41.478}, {-14.048, -4.162}, {-9.352, -24.8}, {7.912, -24.469}, {16.247, 0.27}, {16.247, 0.27}, {13.336, 0.071}, {13.336, 0.071}, {7.515, -9.983}, {-3.134, -7.271}, {-2.671, 41.214}, {-2.671, 41.214}}, smooth = Smooth.Bezier)}));
  end Constants;

  package Icons  "Library of icons"
    extends Icons.Package;

    partial package ExamplesPackage  "Icon for packages containing runnable examples"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {8.0, 14.0}, lineColor = {78, 138, 73}, fillColor = {78, 138, 73}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-58.0, 46.0}, {42.0, -14.0}, {-58.0, -74.0}, {-58.0, 46.0}})}), Documentation(info = "<html>
    <p>This icon indicates a package that contains executable examples.</p>
    </html>"));
    end ExamplesPackage;

    partial model Example  "Icon for runnable examples"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {75, 138, 73}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Polygon(lineColor = {0, 0, 255}, fillColor = {75, 138, 73}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-36, 60}, {64, 0}, {-36, -60}, {-36, 60}})}), Documentation(info = "<html>
    <p>This icon indicates an example. The play button suggests that the example can be executed.</p>
    </html>")); end Example;

    partial package Package  "Icon for standard packages"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {248, 248, 248}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Rectangle(lineColor = {128, 128, 128}, fillPattern = FillPattern.None, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0)}), Documentation(info = "<html>
    <p>Standard package icon.</p>
    </html>")); end Package;

    partial package BasesPackage  "Icon for packages containing base classes"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-30.0, -30.0}, {30.0, 30.0}}, lineColor = {128, 128, 128}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
    <p>This icon shall be used for a package/library that contains base models and classes, respectively.</p>
    </html>"));
    end BasesPackage;

    partial package VariantsPackage  "Icon for package containing variants"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(origin = {10.0, 10.0}, fillColor = {76, 76, 76}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-80.0, -80.0}, {-20.0, -20.0}}), Ellipse(origin = {10.0, 10.0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{0.0, -80.0}, {60.0, -20.0}}), Ellipse(origin = {10.0, 10.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{0.0, 0.0}, {60.0, 60.0}}), Ellipse(origin = {10.0, 10.0}, lineColor = {128, 128, 128}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-80.0, 0.0}, {-20.0, 60.0}})}), Documentation(info = "<html>
    <p>This icon shall be used for a package/library that contains several variants of one component.</p>
    </html>"));
    end VariantsPackage;

    partial package InterfacesPackage  "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {20.0, 0.0}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-10.0, 70.0}, {10.0, 70.0}, {40.0, 20.0}, {80.0, 20.0}, {80.0, -20.0}, {40.0, -20.0}, {10.0, -70.0}, {-10.0, -70.0}}), Polygon(fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-100.0, 20.0}, {-60.0, 20.0}, {-30.0, 70.0}, {-10.0, 70.0}, {-10.0, -70.0}, {-30.0, -70.0}, {-60.0, -20.0}, {-100.0, -20.0}})}), Documentation(info = "<html>
    <p>This icon indicates packages containing interfaces.</p>
    </html>"));
    end InterfacesPackage;

    partial package SourcesPackage  "Icon for packages containing sources"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {23.3333, 0.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-23.333, 30.0}, {46.667, 0.0}, {-23.333, -30.0}}), Rectangle(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-70, -4.5}, {0, 4.5}})}), Documentation(info = "<html>
    <p>This icon indicates a package which contains sources.</p>
    </html>"));
    end SourcesPackage;

    partial package UtilitiesPackage  "Icon for utility packages"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {1.3835, -4.1418}, rotation = 45.0, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.0, 93.333}, {-15.0, 68.333}, {0.0, 58.333}, {15.0, 68.333}, {15.0, 93.333}, {20.0, 93.333}, {25.0, 83.333}, {25.0, 58.333}, {10.0, 43.333}, {10.0, -41.667}, {25.0, -56.667}, {25.0, -76.667}, {10.0, -91.667}, {0.0, -91.667}, {0.0, -81.667}, {5.0, -81.667}, {15.0, -71.667}, {15.0, -61.667}, {5.0, -51.667}, {-5.0, -51.667}, {-15.0, -61.667}, {-15.0, -71.667}, {-5.0, -81.667}, {0.0, -81.667}, {0.0, -91.667}, {-10.0, -91.667}, {-25.0, -76.667}, {-25.0, -56.667}, {-10.0, -41.667}, {-10.0, 43.333}, {-25.0, 58.333}, {-25.0, 83.333}, {-20.0, 93.333}}), Polygon(origin = {10.1018, 5.218}, rotation = -45.0, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-15.0, 87.273}, {15.0, 87.273}, {20.0, 82.273}, {20.0, 27.273}, {10.0, 17.273}, {10.0, 7.273}, {20.0, 2.273}, {20.0, -2.727}, {5.0, -2.727}, {5.0, -77.727}, {10.0, -87.727}, {5.0, -112.727}, {-5.0, -112.727}, {-10.0, -87.727}, {-5.0, -77.727}, {-5.0, -2.727}, {-20.0, -2.727}, {-20.0, 2.273}, {-10.0, 7.273}, {-10.0, 17.273}, {-20.0, 27.273}, {-20.0, 82.273}})}), Documentation(info = "<html>
    <p>This icon indicates a package containing utility classes.</p>
    </html>"));
    end UtilitiesPackage;

    partial package TypesPackage  "Icon for packages containing type definitions"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-12.167, -23}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{12.167, 65}, {14.167, 93}, {36.167, 89}, {24.167, 20}, {4.167, -30}, {14.167, -30}, {24.167, -30}, {24.167, -40}, {-5.833, -50}, {-15.833, -30}, {4.167, 20}, {12.167, 65}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Polygon(origin = {2.7403, 1.6673}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{49.2597, 22.3327}, {31.2597, 24.3327}, {7.2597, 18.3327}, {-26.7403, 10.3327}, {-46.7403, 14.3327}, {-48.7403, 6.3327}, {-32.7403, 0.3327}, {-6.7403, 4.3327}, {33.2597, 14.3327}, {49.2597, 14.3327}, {49.2597, 22.3327}}, smooth = Smooth.Bezier)}));
    end TypesPackage;

    partial package IconsPackage  "Icon for packages containing icons"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}));
    end IconsPackage;

    partial package MaterialPropertiesPackage  "Icon for package containing property classes"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {102, 102, 102}, fillColor = {204, 204, 204}, pattern = LinePattern.None, fillPattern = FillPattern.Sphere, extent = {{-60.0, -60.0}, {60.0, 60.0}})}), Documentation(info = "<html>
    <p>This icon indicates a package that contains properties</p>
    </html>"));
    end MaterialPropertiesPackage;

    partial function Function  "Icon for functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 105}, {150, 145}}, textString = "%name"), Ellipse(lineColor = {108, 88, 49}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Text(lineColor = {108, 88, 49}, extent = {{-90.0, -90.0}, {90.0, 90.0}}, textString = "f")}), Documentation(info = "<html>
    <p>This icon indicates Modelica functions.</p>
    </html>")); end Function;

    partial record Record  "Icon for records"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(lineColor = {0, 0, 255}, extent = {{-150, 60}, {150, 100}}, textString = "%name"), Rectangle(origin = {0.0, -25.0}, lineColor = {64, 64, 64}, fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, extent = {{-100.0, -75.0}, {100.0, 75.0}}, radius = 25.0), Line(points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -50.0}, points = {{-100.0, 0.0}, {100.0, 0.0}}, color = {64, 64, 64}), Line(origin = {0.0, -25.0}, points = {{0.0, 75.0}, {0.0, -75.0}}, color = {64, 64, 64})}), Documentation(info = "<html>
    <p>
    This icon is indicates a record.
    </p>
    </html>")); end Record;

    type TypeReal  "Icon for Real types"
      extends Real;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {160, 160, 164}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Text(lineColor = {255, 255, 255}, extent = {{-90.0, -50.0}, {90.0, 50.0}}, textString = "R")}), Documentation(info = "<html>
    <p>
    This icon is designed for a <b>Real</b> type.
    </p>
    </html>"));
    end TypeReal;
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}), Documentation(info = "<html>
  <p>This package contains definitions for the graphical layout of components which may be used in different libraries. The icons can be utilized by inheriting them in the desired class using &quot;extends&quot; or by directly copying the &quot;icon&quot; layer. </p>

  <h4>Main Authors:</h4>

  <dl>
  <dt><a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a></dt>
      <dd>Deutsches Zentrum fuer Luft und Raumfahrt e.V. (DLR)</dd>
      <dd>Oberpfaffenhofen</dd>
      <dd>Postfach 1116</dd>
      <dd>D-82230 Wessling</dd>
      <dd>email: <a href=\"mailto:Martin.Otter@dlr.de\">Martin.Otter@dlr.de</a></dd>
  <dt>Christian Kral</dt>
      <dd><a href=\"http://christiankral.net/\">Electric Machines, Drives and Systems</a></dd>
      <dd>1060 Vienna, Austria</dd>
      <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>
  <dt>Johan Andreasson</dt>
      <dd><a href=\"http://www.modelon.se/\">Modelon AB</a></dd>
      <dd>Ideon Science Park</dd>
      <dd>22370 Lund, Sweden</dd>
      <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>
  </dl>

  <p>Copyright &copy; 1998-2015, Modelica Association, DLR, AIT, and Modelon AB. </p>
  <p><i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified under the terms of the <b>Modelica license</b>, see the license conditions and the accompanying <b>disclaimer</b> in <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a>.</i> </p>
  </html>"));
  end Icons;

  package SIunits  "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;

    package Icons  "Icons for SIunits"
      extends Modelica.Icons.IconsPackage;

      partial function Conversion  "Base icon for conversion functions"  annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {191, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-90, 0}, {30, 0}}, color = {191, 0, 0}), Polygon(points = {{90, 0}, {30, 20}, {30, -20}, {90, 0}}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-115, 155}, {115, 105}}, textString = "%name", lineColor = {0, 0, 255})})); end Conversion;
    end Icons;

    package Conversions  "Conversion functions to/from non SI units and type definitions of non SI units"
      extends Modelica.Icons.Package;

      package NonSIunits  "Type definitions of non SI units"
        extends Modelica.Icons.Package;
        type Temperature_degC = Real(final quantity = "ThermodynamicTemperature", final unit = "degC") "Absolute temperature in degree Celsius (for relative temperature use SIunits.TemperatureDifference)" annotation(absoluteValue = true);
        type Pressure_bar = Real(final quantity = "Pressure", final unit = "bar") "Absolute pressure in bar";
        annotation(Documentation(info = "<HTML>
      <p>
      This package provides predefined types, such as <b>Angle_deg</b> (angle in
      degree), <b>AngularVelocity_rpm</b> (angular velocity in revolutions per
      minute) or <b>Temperature_degF</b> (temperature in degree Fahrenheit),
      which are in common use but are not part of the international standard on
      units according to ISO 31-1992 \"General principles concerning quantities,
      units and symbols\" and ISO 1000-1992 \"SI units and recommendations for
      the use of their multiples and of certain other units\".</p>
      <p>If possible, the types in this package should not be used. Use instead
      types of package Modelica.SIunits. For more information on units, see also
      the book of Francois Cardarelli <b>Scientific Unit Conversion - A
      Practical Guide to Metrication</b> (Springer 1997).</p>
      <p>Some units, such as <b>Temperature_degC/Temp_C</b> are both defined in
      Modelica.SIunits and in Modelica.Conversions.NonSIunits. The reason is that these
      definitions have been placed erroneously in Modelica.SIunits although they
      are not SIunits. For backward compatibility, these type definitions are
      still kept in Modelica.SIunits.</p>
      </html>"), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}), graphics = {Text(origin = {15.0, 51.8518}, extent = {{-105.0, -86.8518}, {75.0, -16.8518}}, lineColor = {0, 0, 0}, textString = "[km/h]")}));
      end NonSIunits;

      function to_degC  "Convert from Kelvin to degCelsius"
        extends Modelica.SIunits.Icons.Conversion;
        input Temperature Kelvin "Kelvin value";
        output NonSIunits.Temperature_degC Celsius "Celsius value";
      algorithm
        Celsius := Kelvin + Modelica.Constants.T_zero;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-20, 100}, {-100, 20}}, lineColor = {0, 0, 0}, textString = "K"), Text(extent = {{100, -20}, {20, -100}}, lineColor = {0, 0, 0}, textString = "degC")}));
      end to_degC;

      function from_degC  "Convert from degCelsius to Kelvin"
        extends Modelica.SIunits.Icons.Conversion;
        input NonSIunits.Temperature_degC Celsius "Celsius value";
        output Temperature Kelvin "Kelvin value";
      algorithm
        Kelvin := Celsius - Modelica.Constants.T_zero;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-20, 100}, {-100, 20}}, lineColor = {0, 0, 0}, textString = "degC"), Text(extent = {{100, -20}, {20, -100}}, lineColor = {0, 0, 0}, textString = "K")}));
      end from_degC;

      function to_bar  "Convert from Pascal to bar"
        extends Modelica.SIunits.Icons.Conversion;
        input Pressure Pa "Pascal value";
        output NonSIunits.Pressure_bar bar "bar value";
      algorithm
        bar := Pa / 1e5;
        annotation(Inline = true, Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-12, 100}, {-100, 56}}, lineColor = {0, 0, 0}, textString = "Pa"), Text(extent = {{98, -52}, {-4, -100}}, lineColor = {0, 0, 0}, textString = "bar")}));
      end to_bar;
      annotation(Documentation(info = "<HTML>
    <p>This package provides conversion functions from the non SI Units
    defined in package Modelica.SIunits.Conversions.NonSIunits to the
    corresponding SI Units defined in package Modelica.SIunits and vice
    versa. It is recommended to use these functions in the following
    way (note, that all functions have one Real input and one Real output
    argument):</p>
    <pre>
      <b>import</b> SI = Modelica.SIunits;
      <b>import</b> Modelica.SIunits.Conversions.*;
         ...
      <b>parameter</b> SI.Temperature     T   = from_degC(25);   // convert 25 degree Celsius to Kelvin
      <b>parameter</b> SI.Angle           phi = from_deg(180);   // convert 180 degree to radian
      <b>parameter</b> SI.AngularVelocity w   = from_rpm(3600);  // convert 3600 revolutions per minutes
                                                          // to radian per seconds
    </pre>

    </html>"));
    end Conversions;

    type Angle = Real(final quantity = "Angle", final unit = "rad", displayUnit = "deg");
    type Area = Real(final quantity = "Area", final unit = "m2");
    type Volume = Real(final quantity = "Volume", final unit = "m3");
    type Time = Real(final quantity = "Time", final unit = "s");
    type Velocity = Real(final quantity = "Velocity", final unit = "m/s");
    type Acceleration = Real(final quantity = "Acceleration", final unit = "m/s2");
    type Mass = Real(quantity = "Mass", final unit = "kg", min = 0);
    type Density = Real(final quantity = "Density", final unit = "kg/m3", displayUnit = "g/cm3", min = 0.0);
    type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
    type AbsolutePressure = Pressure(min = 0.0, nominal = 1e5);
    type DynamicViscosity = Real(final quantity = "DynamicViscosity", final unit = "Pa.s", min = 0);
    type Energy = Real(final quantity = "Energy", final unit = "J");
    type Power = Real(final quantity = "Power", final unit = "W");
    type MassFlowRate = Real(quantity = "MassFlowRate", final unit = "kg/s");
    type MomentumFlux = Real(final quantity = "MomentumFlux", final unit = "N");
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC") "Absolute temperature (use type TemperatureDifference for relative temperatures)" annotation(absoluteValue = true);
    type Temperature = ThermodynamicTemperature;
    type Compressibility = Real(final quantity = "Compressibility", final unit = "1/Pa");
    type IsothermalCompressibility = Compressibility;
    type ThermalConductivity = Real(final quantity = "ThermalConductivity", final unit = "W/(m.K)");
    type SpecificHeatCapacity = Real(final quantity = "SpecificHeatCapacity", final unit = "J/(kg.K)");
    type RatioOfSpecificHeatCapacities = Real(final quantity = "RatioOfSpecificHeatCapacities", final unit = "1");
    type Entropy = Real(final quantity = "Entropy", final unit = "J/K");
    type SpecificEntropy = Real(final quantity = "SpecificEntropy", final unit = "J/(kg.K)");
    type SpecificEnergy = Real(final quantity = "SpecificEnergy", final unit = "J/kg");
    type SpecificInternalEnergy = SpecificEnergy;
    type SpecificEnthalpy = SpecificEnergy;
    type DerDensityByEnthalpy = Real(final unit = "kg.s2/m5");
    type DerDensityByPressure = Real(final unit = "s2/m2");
    type DerDensityByTemperature = Real(final unit = "kg/(m3.K)");
    type AmountOfSubstance = Real(final quantity = "AmountOfSubstance", final unit = "mol", min = 0);
    type MolarMass = Real(final quantity = "MolarMass", final unit = "kg/mol", min = 0);
    type MolarVolume = Real(final quantity = "MolarVolume", final unit = "m3/mol", min = 0);
    type MassFraction = Real(final quantity = "MassFraction", final unit = "1", min = 0, max = 1);
    type MoleFraction = Real(final quantity = "MoleFraction", final unit = "1", min = 0, max = 1);
    type FaradayConstant = Real(final quantity = "FaradayConstant", final unit = "C/mol");
    annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-66, 78}, {-66, -40}}, color = {64, 64, 64}, smooth = Smooth.None), Ellipse(extent = {{12, 36}, {68, -38}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-74, 78}, {-66, -40}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-66, -4}, {-66, 6}, {-16, 56}, {-16, 46}, {-66, -4}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-46, 16}, {-40, 22}, {-2, -40}, {-10, -40}, {-46, 16}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Ellipse(extent = {{22, 26}, {58, -28}}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{68, 2}, {68, -46}, {64, -60}, {58, -68}, {48, -72}, {18, -72}, {18, -64}, {46, -64}, {54, -60}, {58, -54}, {60, -46}, {60, -26}, {64, -20}, {68, -6}, {68, 2}}, lineColor = {64, 64, 64}, smooth = Smooth.Bezier, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid)}), Documentation(info = "<html>
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
  <a href=\"modelica://Modelica.SIunits.Conversions\">Conversions</a>.
  </p>

  <p>
  For an introduction how units are used in the Modelica standard library
  with package SIunits, have a look at:
  <a href=\"modelica://Modelica.SIunits.UsersGuide.HowToUseSIunits\">How to use SIunits</a>.
  </p>

  <p>
  Copyright &copy; 1998-2015, Modelica Association and DLR.
  </p>
  <p>
  <i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
  </p>
  </html>", revisions = "<html>
  <ul>
  <li><i>May 25, 2011</i> by Stefan Wischhusen:<br/>Added molar units for energy and enthalpy.</li>
  <li><i>Jan. 27, 2010</i> by Christian Kral:<br/>Added complex units.</li>
  <li><i>Dec. 14, 2005</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Add User&#39;;s Guide and removed &quot;min&quot; values for Resistance and Conductance.</li>
  <li><i>October 21, 2002</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.robotic.dlr.de/Christian.Schweiger/\">Christian Schweiger</a>:<br/>Added new package <b>Conversions</b>. Corrected typo <i>Wavelenght</i>.</li>
  <li><i>June 6, 2000</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Introduced the following new types<br/>type Temperature = ThermodynamicTemperature;<br/>types DerDensityByEnthalpy, DerDensityByPressure, DerDensityByTemperature, DerEnthalpyByPressure, DerEnergyByDensity, DerEnergyByPressure<br/>Attribute &quot;final&quot; removed from min and max values in order that these values can still be changed to narrow the allowed range of values.<br/>Quantity=&quot;Stress&quot; removed from type &quot;Stress&quot;, in order that a type &quot;Stress&quot; can be connected to a type &quot;Pressure&quot;.</li>
  <li><i>Oct. 27, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>New types due to electrical library: Transconductance, InversePotential, Damping.</li>
  <li><i>Sept. 18, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Renamed from SIunit to SIunits. Subpackages expanded, i.e., the SIunits package, does no longer contain subpackages.</li>
  <li><i>Aug 12, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Type &quot;Pressure&quot; renamed to &quot;AbsolutePressure&quot; and introduced a new type &quot;Pressure&quot; which does not contain a minimum of zero in order to allow convenient handling of relative pressure. Redefined BulkModulus as an alias to AbsolutePressure instead of Stress, since needed in hydraulics.</li>
  <li><i>June 29, 1999</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a>:<br/>Bug-fix: Double definition of &quot;Compressibility&quot; removed and appropriate &quot;extends Heat&quot; clause introduced in package SolidStatePhysics to incorporate ThermodynamicTemperature.</li>
  <li><i>April 8, 1998</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and Astrid Jaschinski:<br/>Complete ISO 31 chapters realized.</li>
  <li><i>Nov. 15, 1997</i> by <a href=\"http://www.robotic.dlr.de/Martin.Otter/\">Martin Otter</a> and <a href=\"http://www.control.lth.se/~hubertus/\">Hubertus Tummescheit</a>:<br/>Some chapters realized.</li>
  </ul>
  </html>"));
  end SIunits;
  annotation(preferredView = "info", version = "3.2.1", versionBuild = 4, versionDate = "2013-08-14", dateModified = "2015-09-30 09:15:00Z", revisionId = "$Id::                                       $", uses(Complex(version = "3.2.1"), ModelicaServices(version = "3.2.1")), conversion(noneFromVersion = "3.2", noneFromVersion = "3.1", noneFromVersion = "3.0.1", noneFromVersion = "3.0", from(version = "2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-6.9888, 20.048}, fillColor = {0, 0, 0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-93.0112, 10.3188}, {-93.0112, 10.3188}, {-73.011, 24.6}, {-63.011, 31.221}, {-51.219, 36.777}, {-39.842, 38.629}, {-31.376, 36.248}, {-25.819, 29.369}, {-24.232, 22.49}, {-23.703, 17.463}, {-15.501, 25.135}, {-6.24, 32.015}, {3.02, 36.777}, {15.191, 39.423}, {27.097, 37.306}, {32.653, 29.633}, {35.035, 20.108}, {43.501, 28.046}, {54.085, 35.19}, {65.991, 39.952}, {77.897, 39.688}, {87.422, 33.338}, {91.126, 21.696}, {90.068, 9.525}, {86.099, -1.058}, {79.749, -10.054}, {71.283, -21.431}, {62.816, -33.337}, {60.964, -32.808}, {70.489, -16.14}, {77.368, -2.381}, {81.072, 10.054}, {79.749, 19.05}, {72.605, 24.342}, {61.758, 23.019}, {49.587, 14.817}, {39.003, 4.763}, {29.214, -6.085}, {21.012, -16.669}, {13.339, -26.458}, {5.401, -36.777}, {-1.213, -46.037}, {-6.24, -53.446}, {-8.092, -52.387}, {-0.684, -40.746}, {5.401, -30.692}, {12.81, -17.198}, {19.424, -3.969}, {23.658, 7.938}, {22.335, 18.785}, {16.514, 23.283}, {8.047, 23.019}, {-1.478, 19.05}, {-11.267, 11.113}, {-19.734, 2.381}, {-29.259, -8.202}, {-38.519, -19.579}, {-48.044, -31.221}, {-56.511, -43.392}, {-64.449, -55.298}, {-72.386, -66.939}, {-77.678, -74.612}, {-79.53, -74.083}, {-71.857, -61.383}, {-62.861, -46.037}, {-52.278, -28.046}, {-44.869, -15.346}, {-38.784, -2.117}, {-35.344, 8.731}, {-36.403, 19.844}, {-42.488, 23.813}, {-52.013, 22.49}, {-60.744, 16.933}, {-68.947, 10.054}, {-76.884, 2.646}, {-93.0112, -12.1707}, {-93.0112, -12.1707}}, smooth = Smooth.Bezier), Ellipse(origin = {40.8208, -37.7602}, fillColor = {161, 0, 4}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-17.8562, -17.8563}, {17.8563, 17.8562}})}), Documentation(info = "<HTML>
<p>
Package <b>Modelica&reg;</b> is a <b>standardized</b> and <b>free</b> package
that is developed together with the Modelica&reg; language from the
Modelica Association, see
<a href=\"https://www.Modelica.org\">https://www.Modelica.org</a>.
It is also called <b>Modelica Standard Library</b>.
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
<li> The <b>Examples</b> packages in the various libraries, demonstrate
  how to use the components of the corresponding sublibrary.</li>
</ul>

<p>
This version of the Modelica Standard Library consists of
</p>
<ul>
<li><b>1360</b> models and blocks, and</li>
<li><b>1280</b> functions</li>
</ul>
<p>
that are directly usable (= number of public, non-partial classes). It is fully compliant
to <a href=\"https://www.modelica.org/documents/ModelicaSpec32Revision2.pdf\">Modelica Specification Version 3.2 Revision 2</a>
and it has been tested with Modelica tools from different vendors.
</p>

<p>
<b>Licensed by the Modelica Association under the Modelica License 2</b><br>
Copyright &copy; 1998-2015, ABB, AIT, T.&nbsp;B&ouml;drich, DLR, Dassault Syst&egrave;mes AB, Fraunhofer, A.&nbsp;Haumer, ITI, C.&nbsp;Kral, Modelon,
TU Hamburg-Harburg, Politecnico di Milano, XRG Simulation.
</p>

<p>
<i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a> or visit <a href=\"https://www.modelica.org/licenses/ModelicaLicense2\"> https://www.modelica.org/licenses/ModelicaLicense2</a>.</i>
</p>

<p>
<b>Modelica&reg;</b> is a registered trademark of the Modelica Association.
</p>
</html>"));
end Modelica;

package FCSys  "Modelica fuel cell library"
  extends Modelica.Icons.Package;

  package Conditions  "Models to specify and measure operating conditions"
    extends Modelica.Icons.SourcesPackage;

    record Environment  "Environmental properties for a simulation"
      extends FCSys.Icons.Names.Top3;
      final constant .FCSys.Units.Bases.Base baseUnits = .FCSys.Units.base "Base constants and units";
      parameter Boolean analysis = true "Include optional variables for analysis" annotation(choices(__Dymola_checkBox = true));
      parameter .FCSys.Quantities.TemperatureAbsolute T(nominal = 300 * .FCSys.Units.K) = 298.15 * .FCSys.Units.K "Temperature" annotation(Dialog(__Dymola_label = "<html><i>T</i></html>", group = "Thermodynamics"));
      parameter .FCSys.Quantities.PressureAbsolute p(nominal = .FCSys.Units.atm) = .FCSys.Units.atm "Pressure" annotation(Dialog(__Dymola_label = "<html><i>p</i></html>", group = "Thermodynamics"));
      parameter .FCSys.Quantities.NumberAbsolute RH(displayUnit = "%", max = 1) = 0.5 "Relative humidity" annotation(Dialog(group = "Thermodynamics"));
      parameter .FCSys.Quantities.NumberAbsolute psi_O2_dry(final max = 1, displayUnit = "%") = 0.20946 "<html>Mole fraction of O<sub>2</sub> in the dry gas</html>" annotation(Dialog(__Dymola_label = "<html>&psi;<sub>O2 dry</sub></html>", group = "Thermodynamics"));
      final parameter .FCSys.Quantities.PressureAbsolute p_sat = Characteristics.H2O.p_sat(T) "Saturation pressure of H2O vapor";
      final parameter .FCSys.Quantities.PressureAbsolute p_H2O = RH * p_sat "Pressure of H2O vapor";
      final parameter .FCSys.Quantities.PressureAbsolute p_dry = p - p_H2O "Pressure of dry gases";
      final parameter .FCSys.Quantities.PressureAbsolute p_O2 = psi_O2_dry * p_dry "Pressure of O2";
      final parameter .FCSys.Quantities.NumberAbsolute psi_H2O = p_H2O / p "Mole fraction of H2O";
      final parameter .FCSys.Quantities.NumberAbsolute psi_dry = 1 - psi_H2O "Mole fraction of dry gases";
      parameter .FCSys.Quantities.Acceleration[.FCSys.Species.Enumerations.Axis] a = {0, Modelica.Constants.g_n * .FCSys.Units.m / .FCSys.Units.s ^ 2, 0} "Acceleration due to body forces" annotation(Dialog(__Dymola_label = "<html><b><i>a</i></b></html>", group = "Fields"));
      parameter .FCSys.Quantities.ForceSpecific[.FCSys.Species.Enumerations.Axis] E = {0, 0, 0} "Electric field" annotation(Dialog(__Dymola_label = "<html><b><i>E</i></b></html>", group = "Fields"));
      annotation(defaultComponentPrefixes = "inner", missingInnerMessage = "Your model is using an outer \"environment\" record, but an inner \"environment\"
    record is not defined.  For simulation, drag FCSys.Conditions.Environment into
    your model to specify global conditions and defaults.  Otherwise, the default
    settings will be used.", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-80, 60}, {80, -100}}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, pattern = LinePattern.None), Rectangle(extent = {{-70, 50}, {70, -98}}, lineColor = {255, 255, 255}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {170, 213, 255}), Rectangle(extent = {{-72, -60}, {72, -100}}, fillPattern = FillPattern.Solid, fillColor = {255, 255, 255}, pattern = LinePattern.None, lineColor = {0, 0, 0}), Line(points = {{-40, -20}, {-30, -28}, {-10, -50}, {-10, -50}, {16, -12}, {40, 0}}, color = {0, 0, 0}, smooth = Smooth.Bezier), Ellipse(extent = {{32, 8}, {48, -8}}, pattern = LinePattern.None, lineColor = {170, 213, 255}, fillColor = {50, 50, 50}, fillPattern = FillPattern.Sphere), Rectangle(extent = {{70, 50}, {76, -60}}, fillPattern = FillPattern.Solid, fillColor = {255, 255, 255}, pattern = LinePattern.None, lineColor = {0, 0, 0}), Rectangle(extent = {{-76, 50}, {-70, -60}}, fillPattern = FillPattern.Solid, fillColor = {255, 255, 255}, pattern = LinePattern.None, lineColor = {0, 0, 0}), Rectangle(extent = {{-80, 60}, {80, -100}}, lineColor = {0, 0, 0}, pattern = LinePattern.Dash), Line(points = {{-70, -60}, {70, -60}}, color = {0, 0, 0}), Line(points = {{-66, -90}, {-36, -60}}, color = {0, 0, 0}), Line(points = {{2, -90}, {32, -60}}, color = {0, 0, 0}), Line(points = {{36, -90}, {66, -60}}, color = {0, 0, 0}), Line(points = {{-32, -90}, {-2, -60}}, color = {0, 0, 0})}));
    end Environment;
    annotation(Documentation(info = "
  <html>
    <p><b>Licensed by the Hawaii Natural Energy Institute under the Modelica License 2</b><br>
  Copyright &copy; 2007&ndash;2014, <a href=\"http://www.hnei.hawaii.edu/\">Hawaii Natural Energy Institute</a> and <a href=\"http://www.gtrc.gatech.edu/\">Georgia Tech Research Corporation</a>.</p>

  <p><i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>;
  it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the
  disclaimer of warranty) see <a href=\"modelica://FCSys.UsersGuide.License\">
  FCSys.UsersGuide.License</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">
  http://www.modelica.org/licenses/ModelicaLicense2</a>.</i></p>
  </html>"));
  end Conditions;

  package Species  "Dynamic models of chemical species"
    extends Modelica.Icons.Package;

    package Enumerations  "Choices of options"
      extends Modelica.Icons.TypesPackage;
      type Axis = enumeration(x "X", y "Y", z "Z") "Enumeration for Cartesian axes";
    end Enumerations;
    annotation(Documentation(info = "
  <html>
    <p><b>Licensed by the Hawaii Natural Energy Institute under the Modelica License 2</b><br>
  Copyright &copy; 2007&ndash;2014, <a href=\"http://www.hnei.hawaii.edu/\">Hawaii Natural Energy Institute</a> and <a href=\"http://www.gtrc.gatech.edu/\">Georgia Tech Research Corporation</a>.</p>

  <p><i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>;
  it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the
  disclaimer of warranty) see <a href=\"modelica://FCSys.UsersGuide.License\">
  FCSys.UsersGuide.License</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">
  http://www.modelica.org/licenses/ModelicaLicense2</a>.</i></p>
  </html>"));
  end Species;

  package Characteristics  "Data and functions to correlate physical properties"
    extends Modelica.Icons.Package;

    package Examples  "Examples"
      extends Modelica.Icons.ExamplesPackage;

      model CellPotential  "<html>Evaluate the potential of an H<sub>2</sub>/O<sub>2</sub> cell as a function of temperature</html>"
        package H2OIG = FCSys.Characteristics.H2O.Gas(b_v = [1], n_v = {-1, 0});
        package O2IG = FCSys.Characteristics.O2.Gas(b_v = [1], n_v = {-1, 0});
        package H2IG = FCSys.Characteristics.H2.Gas(b_v = [1], n_v = {-1, 0});
        extends Modelica.Icons.Example;
        output Real T_degC = .FCSys.Units.to_degC(T) "Temperature in deg C";
        output .FCSys.Quantities.Potential w_gas = 0.5 * .FCSys.Characteristics.H2.Gas.g(T, environment.p_dry) + 0.25 * .FCSys.Characteristics.O2.Gas.g(T, environment.p_O2) - 0.5 * .FCSys.Characteristics.H2O.Gas.g(T, environment.p_H2O) "Cell potential with H2O as gas";
        output .FCSys.Quantities.Potential w_IG = 0.5 * H2IG.g(T, environment.p_dry) + 0.25 * O2IG.g(T, environment.p_O2) - 0.5 * H2OIG.g(T, environment.p_H2O) "Cell potential with ideal gases";
        output .FCSys.Quantities.Potential w_liq = 0.5 * .FCSys.Characteristics.H2.Gas.g(T, environment.p_dry) + 0.25 * .FCSys.Characteristics.O2.Gas.g(T, environment.p_O2) - 0.5 * .FCSys.Characteristics.H2O.Liquid.g(T, environment.p) "Cell potential with H2O as liquid";
        .FCSys.Quantities.TemperatureAbsolute T "Temperature";
        Modelica.Blocks.Sources.Ramp temperatureSet(height = 99 * .FCSys.Units.K, duration = 10, offset = 274.15 * .FCSys.Units.K) annotation(Placement(transformation(extent = {{-10, -50}, {10, -30}})));
        inner Conditions.Environment environment annotation(Placement(transformation(extent = {{-10, 0}, {10, 20}})));
      equation
        T = temperatureSet.y;
        annotation(experiment(StopTime = 10), Commands(file = "Resources/Scripts/Dymola/Characteristics.Examples.CellPotential.mos"));
      end CellPotential;
    end Examples;

    package H2  "<html>H<sub>2</sub></html>"
      extends Modelica.Icons.Package;

      package Gas  "H2 gas"
        extends BaseClasses.CharacteristicNASA(final formula = .Modelica.Media.IdealGases.Common.SingleGasesData.H2.name, final phase = .FCSys.Characteristics.BaseClasses.Phase.gas, final m = .Modelica.Media.IdealGases.Common.SingleGasesData.H2.MM * .FCSys.Units.kg / .FCSys.Units.mol, n_v = {-1, -3}, b_v = {{0, 0, 0, 1}, {8.0282e6 * .FCSys.Units.K ^ 3, -2.6988e5 * .FCSys.Units.K ^ 2, -129.26 * .FCSys.Units.K, 17.472} * .FCSys.Units.cm ^ 3 / .FCSys.Units.mol}, Deltah0_f = .Modelica.Media.IdealGases.Common.SingleGasesData.H2.MM * .Modelica.Media.IdealGases.Common.SingleGasesData.H2.Hf * .FCSys.Units.J / .FCSys.Units.mol, Deltah0 = .Modelica.Media.IdealGases.Common.SingleGasesData.H2.MM * .Modelica.Media.IdealGases.Common.SingleGasesData.H2.H0 * .FCSys.Units.J / .FCSys.Units.mol, T_lim_c = {200.000, .Modelica.Media.IdealGases.Common.SingleGasesData.H2.Tlimit, 6000.000, 20000.000} * .FCSys.Units.K, b_c = {.Modelica.Media.IdealGases.Common.SingleGasesData.H2.alow, .Modelica.Media.IdealGases.Common.SingleGasesData.H2.ahigh, {4.966884120e8, -3.147547149e5, 79.84121880, -8.414789210e-3, 4.753248350e-7, -1.371873492e-11, 1.605461756e-16}} .* fill({.FCSys.Units.K ^ (3 - i) for i in 1:size(.Modelica.Media.IdealGases.Common.SingleGasesData.H2.alow, 1)}, size(T_lim_c, 1) - 1), B_c = {.Modelica.Media.IdealGases.Common.SingleGasesData.H2.blow, .Modelica.Media.IdealGases.Common.SingleGasesData.H2.bhigh, {2.488433516e6, -669.5728110}} .* fill({.FCSys.Units.K, 1}, size(T_lim_c, 1) - 1) - b_c[:, 2:3] * log(.FCSys.Units.K), d = (240 + 100.3) * .FCSys.Units.pico * .FCSys.Units.m / .FCSys.Units.q, T_lim_eta_theta = {200.0, 1000.0, 5000.0, 15000.0} * .FCSys.Units.K, b_eta = {fromNASAViscosity({0.74553182, 43.555109, -3.2579340e3, 0.13556243}), fromNASAViscosity({0.96730605, 679.31897, -2.1025179e5, -1.8251697}), fromNASAViscosity({1.0126129, 1.4973739e3, -1.4428484e6, -2.3254928})}, b_theta = {fromNASAThermalConductivity({1.0059461, 279.51262, -2.9792018e4, 1.1996252}), fromNASAThermalConductivity({1.0582450, 248.75372, 1.1736907e4, 0.82758695}), fromNASAThermalConductivity({-0.22364420, -6.9650442e3, -7.7771313e4, 13.189369})});
        annotation(Documentation(info = "<html>
                  <p>Notes:</p>
           <ul>
        <li>According to [<a href=\"modelica://FCSys.UsersGuide.References.Avogadro\">Avogadro</a>], the (center-to-center)
         bond length of H-H is 100.3 pm.  The radius of H is from
         <a href=\"http://en.wikipedia.org/wiki/Hydrogen\">http://en.wikipedia.org/wiki/Hydrogen</a>.  See also
         <a href=\"http://en.wikipedia.org/wiki/Van_der_Waals_radius\">http://en.wikipedia.org/wiki/Van_der_Waals_radius</a>.</li>
        <li>The virial coefficients are from [<a href=\"modelica://FCSys.UsersGuide.References.Dymond2002\">Dymond2002</a>, p.&nbsp;41].  The
        temperature range of the coefficients is [60, 500] K, but this is not enforced in the functions.</li>
           </ul>

      <p>For more information, please see the
        <a href=\"modelica://FCSys.Characteristics.BaseClasses.Characteristic\">Characteristic</a> package.</p></html>"));
      end Gas;
    end H2;

    package H2O  "<html>H<sub>2</sub>O</html>"
      extends Modelica.Icons.Package;

      package Gas  "H2O gas"
        extends BaseClasses.CharacteristicNASA(final formula = .Modelica.Media.IdealGases.Common.SingleGasesData.H2O.name, final phase = .FCSys.Characteristics.BaseClasses.Phase.gas, final m = .Modelica.Media.IdealGases.Common.SingleGasesData.H2O.MM * .FCSys.Units.kg / .FCSys.Units.mol, n_v = {-1, -3}, b_v = {{0, 0, 0, 1}, {-5.6932e10 * .FCSys.Units.K ^ 3, 1.8189e8 * .FCSys.Units.K ^ 2, -3.0107e5 * .FCSys.Units.K, 158.83} * .FCSys.Units.cm ^ 3 / .FCSys.Units.mol}, Deltah0_f = .Modelica.Media.IdealGases.Common.SingleGasesData.H2O.MM * .Modelica.Media.IdealGases.Common.SingleGasesData.H2O.Hf * .FCSys.Units.J / .FCSys.Units.mol, Deltah0 = .Modelica.Media.IdealGases.Common.SingleGasesData.H2O.MM * .Modelica.Media.IdealGases.Common.SingleGasesData.H2O.H0 * .FCSys.Units.J / .FCSys.Units.mol, T_lim_c = {200.000, .Modelica.Media.IdealGases.Common.SingleGasesData.H2O.Tlimit, 6000.000} * .FCSys.Units.K, b_c = {.Modelica.Media.IdealGases.Common.SingleGasesData.H2O.alow, .Modelica.Media.IdealGases.Common.SingleGasesData.H2O.ahigh} .* fill({.FCSys.Units.K ^ (3 - i) for i in 1:size(.Modelica.Media.IdealGases.Common.SingleGasesData.H2O.alow, 1)}, size(T_lim_c, 1) - 1), B_c = {.Modelica.Media.IdealGases.Common.SingleGasesData.H2O.blow, .Modelica.Media.IdealGases.Common.SingleGasesData.H2O.bhigh} .* fill({.FCSys.Units.K, 1}, size(T_lim_c, 1) - 1) - b_c[:, 2:3] * log(.FCSys.Units.K), d = 282 * .FCSys.Units.pico * .FCSys.Units.m / .FCSys.Units.q, T_lim_eta_theta = {373.2, 1073.2, 5000.0, 15000.0} * .FCSys.Units.K, b_eta = {fromNASAViscosity({0.50019557, -697.12796, 8.8163892e4, 3.0836508}), fromNASAViscosity({0.58988538, -537.69814, 5.4263513e4, 2.3386375}), fromNASAViscosity({0.64330087, -95.668913, -3.7742283e5, 1.8125190})}, b_theta = {fromNASAThermalConductivity({1.0966389, -555.13429, 1.0623408e5, -0.24664550}), fromNASAThermalConductivity({0.39367933, -2.2524226e3, 6.1217458e5, 5.8011317}), fromNASAThermalConductivity({-0.41858737, -1.4096649e4, 1.9179190e7, 14.345613})});
        annotation(Documentation(info = "<html>
              <p>Notes:</p>
           <ul>
        <li>The radius of H<sub>2</sub>O is 282 pm
         (<a href=\"http://www.lsbu.ac.uk/water/molecule.html\">http://www.lsbu.ac.uk/water/molecule.html</a>).  Using the radius of H
         from <a href=\"http://en.wikipedia.org/wiki/Hydrogen\">http://en.wikipedia.org/wiki/Hydrogen</a> and the center-to-center
         distance of hydrogen atoms in H<sub>2</sub>O from [<a href=\"modelica://FCSys.UsersGuide.References.Avogadro\">Avogadro</a>],
         156.6 pm, the radius of H<sub>2</sub>O would be (120 + 156.6/2) pm = 198.3 pm.</li>
        <li>The virial coefficients are from [<a href=\"modelica://FCSys.UsersGuide.References\">Dymond2002</a>, p.&nbsp;4].  The
        temperature range of the coefficients is [350, 770] K, but this is not enforced in the functions.</li>
           </ul>

        <p>For more information, please see the
        <a href=\"modelica://FCSys.Characteristics.BaseClasses.Characteristic\">Characteristic</a> package.</p></html>"));
      end Gas;

      package Liquid  "H2O liquid"
        extends BaseClasses.Characteristic(final formula = "H2O", final phase = .FCSys.Characteristics.BaseClasses.Phase.liquid, final m = 0.01801528 * .FCSys.Units.kg / .FCSys.Units.mol, p0 = .FCSys.Units.atm, n_v = {0, 0}, b_v = [.FCSys.Units.cc * m / (0.99656 * .FCSys.Units.g)], Deltah0_f = -285830.000 * .FCSys.Units.J / .FCSys.Units.mol, Deltah0 = 13278.000 * .FCSys.Units.J / .FCSys.Units.mol, T_lim_c = {273.150, 373.150, 600.000} * .FCSys.Units.K, b_c = [1.326371304e9, -2.448295388e7, 1.879428776e5, -7.678995050e2, 1.761556813, -2.151167128e-3, 1.092570813e-6; 1.263631001e9, -1.680380249e7, 9.278234790e4, -2.722373950e2, 4.479243760e-1, -3.919397430e-4, 1.425743266e-7] .* fill({.FCSys.Units.K ^ (3 - i) for i in 1:7}, size(T_lim_c, 1) - 1), B_c = [1.101760476e8 * .FCSys.Units.K, -9.779700970e5; 8.113176880e7 * .FCSys.Units.K, -5.134418080e5] - b_c[:, 2:3] * log(.FCSys.Units.K), d = 282 * .FCSys.Units.pico * .FCSys.Units.m / .FCSys.Units.q);
        annotation(Documentation(info = "<html>     <p>Assumptions:</p>
           <ol>
           <li>Constant specific volume (i.e., incompressible and without
                thermal expansion)</li>
           </ol>

      <p>Additional notes:</p>
           <ul>
           <li>See <a href=\"modelica://FCSys.Characteristics.H2O.Gas\">Characteristics.H2O.Gas</a> regarding the radius.</li>
           <li>The default specific volume (<i>b<sub>v</sub></i> = <code>[U.cc*m/(0.99656*U.g)]</code>) is at 300&nbsp;K based on [<a href=\"modelica://FCSys.UsersGuide.References.Takenaka1990\">Takenaka1990</a>].</li>
           </ul>

      <p>For more information, please see the
        <a href=\"modelica://FCSys.Characteristics.BaseClasses.Characteristic\">Characteristic</a> package.</p></html>"));
      end Liquid;

      function p_sat  "<html>Saturation pressure (<i>p</i><sub>sat</sub>) as a function of temperature</html>"
        extends Modelica.Icons.Function;
        input .FCSys.Quantities.TemperatureAbsolute T "Temperature" annotation(Dialog(__Dymola_label = "<html><i>T</i></html>"));
        output .FCSys.Quantities.PressureAbsolute p_sat "Saturation pressure" annotation(Dialog(__Dymola_label = "<html><i>p</i><sub>sat</sub></html>"));
      algorithm
        p_sat := Modelica.Media.Air.MoistAir.saturationPressureLiquid(T / .FCSys.Units.K) * .FCSys.Units.Pa;
        annotation(Inline = true);
      end p_sat;
    end H2O;

    package O2  "<html>O<sub>2</sub></html>"
      extends Modelica.Icons.Package;

      package Gas  "O2 gas"
        extends BaseClasses.CharacteristicNASA(final formula = .Modelica.Media.IdealGases.Common.SingleGasesData.O2.name, final phase = .FCSys.Characteristics.BaseClasses.Phase.gas, final m = .Modelica.Media.IdealGases.Common.SingleGasesData.O2.MM * .FCSys.Units.kg / .FCSys.Units.mol, n_v = {-1, -4}, b_v = {{0, 0, 0, 0, 1}, {5.0855e9 * .FCSys.Units.K ^ 4, -1.6393e8 * .FCSys.Units.K ^ 3, 5.2007e5 * .FCSys.Units.K ^ 2, -1.7696e4 * .FCSys.Units.K, 42.859} * .FCSys.Units.cc / .FCSys.Units.mol}, Deltah0_f = .Modelica.Media.IdealGases.Common.SingleGasesData.O2.MM * .Modelica.Media.IdealGases.Common.SingleGasesData.O2.Hf * .FCSys.Units.J / .FCSys.Units.mol, Deltah0 = .Modelica.Media.IdealGases.Common.SingleGasesData.O2.MM * .Modelica.Media.IdealGases.Common.SingleGasesData.O2.H0 * .FCSys.Units.J / .FCSys.Units.mol, T_lim_c = {200.000, .Modelica.Media.IdealGases.Common.SingleGasesData.O2.Tlimit, 6000.000, 20000.000} * .FCSys.Units.K, b_c = {.Modelica.Media.IdealGases.Common.SingleGasesData.O2.alow, .Modelica.Media.IdealGases.Common.SingleGasesData.O2.ahigh, {4.975294300e8, -2.866106874e5, 6.690352250e1, -6.169959020e-3, 3.016396027e-7, -7.421416600e-12, 7.278175770e-17}} .* fill({.FCSys.Units.K ^ (3 - i) for i in 1:size(.Modelica.Media.IdealGases.Common.SingleGasesData.O2.alow, 1)}, size(T_lim_c, 1) - 1), B_c = {.Modelica.Media.IdealGases.Common.SingleGasesData.O2.blow, .Modelica.Media.IdealGases.Common.SingleGasesData.O2.bhigh, {2.293554027e6, -5.530621610e2}} .* fill({.FCSys.Units.K, 1}, size(T_lim_c, 1) - 1) - b_c[:, 2:3] * log(.FCSys.Units.K), d = (304 + 128.2) * .FCSys.Units.pico * .FCSys.Units.m / .FCSys.Units.q, T_lim_eta_theta = {200.0, 1000.0, 5000.0, 15000.0} * .FCSys.Units.K, b_eta = {fromNASAViscosity({0.60916180, -52.244847, -599.74009, 2.0410801}), fromNASAViscosity({0.72216486, 175.50839, -5.7974816e4, 1.0901044}), fromNASAViscosity({0.73981127, 391.94906, -3.7833168e5, 0.90931780})}, b_theta = {fromNASAThermalConductivity({0.77229167, 6.8463210, -5.8933377e3, 1.2210365}), fromNASAThermalConductivity({0.90917351, 291.24182, -7.9650171e4, 0.064851631}), fromNASAThermalConductivity({-1.1218262, -1.9286378e4, 2.3295011e7, 20.342043})});
        annotation(Documentation(info = "<html><p>Notes:</p><ul>
        <li>According to [<a href=\"modelica://FCSys.UsersGuide.References.Avogadro\">Avogadro</a>], the (center-to-center)
         bond length of O-O is 128.2 pm.  The radius of O is from
         <a href=\"http://en.wikipedia.org/wiki/Oxygen\">http://en.wikipedia.org/wiki/Oxygen</a>.  See also
         <a href=\"http://en.wikipedia.org/wiki/Van_der_Waals_radius\">http://en.wikipedia.org/wiki/Van_der_Waals_radius</a>.</li>
        <li>The virial coefficients are from [<a href=\"modelica://FCSys.UsersGuide.References.Dymond2002\">Dymond2002</a>, p.&nbsp;69].  The
        temperature range of the coefficients is [70, 495] K, but this is not enforced in the functions.</li>
           </ul>

      <p>For more information, please see the
        <a href=\"modelica://FCSys.Characteristics.BaseClasses.Characteristic\">Characteristic</a> package.</p></html>"));
      end Gas;
    end O2;

    package BaseClasses  "Base classes (generally not for direct use)"
      extends Modelica.Icons.BasesPackage;

      package CharacteristicNASA  "Thermodynamic package with diffusive properties based on NASA CEA"
        extends Characteristic;
        constant .FCSys.Quantities.TemperatureAbsolute[:] T_lim_eta_theta = {0, Modelica.Constants.inf} "<html>Temperature limits for the rows of <i>b</i><sub>&eta;</sub> and <i>b</i><sub>&theta;</sub> (<i>T</i><sub>lim &eta; &theta;</sub>)</html>";
        constant Real[size(T_lim_eta_theta, 1) - 1, 4] b_eta "<html>Correlation constants for fluidity (<i>b</i><sub>&eta;</sub>)</html>";
        constant Real[size(T_lim_eta_theta, 1) - 1, 4] b_theta "<html>Correlation constants for thermal resistivity (<i>b</i><sub>&theta;</sub>)</html>";

      protected
        function fromNASAViscosity  "Return constants for fluidity given NASA CEA constants for viscosity"
          extends Modelica.Icons.Function;
          input Real[4] b "NASA CEA constants for viscosity" annotation(Dialog(__Dymola_label = "<html><i>b</i></html>"));
          output Real[4] b_eta "Constants for fluidity" annotation(Dialog(__Dymola_label = "<html><i>b</i><sub>&eta;<sub></html>"));
        algorithm
          b_eta := {-b[1], -b[2] * .FCSys.Units.K, -b[3] * .FCSys.Units.K ^ 2, (-b[4]) + b[1] * log(.FCSys.Units.K) + log(1e4 * .FCSys.Units.m * .FCSys.Units.s / .FCSys.Units.g)};
          annotation(Inline = true);
        end fromNASAViscosity;

        function fromNASAThermalConductivity  "Return constants for thermal resistivity given NASA CEA constants for thermal conductivity"
          extends Modelica.Icons.Function;
          input Real[4] b "NASA CEA constants for thermal conductivity" annotation(Dialog(__Dymola_label = "<html><i>b</i></html>"));
          output Real[4] b_theta "Constants for thermal resistivity" annotation(Dialog(__Dymola_label = "<html><i>b</i><sub>&theta;<sub></html>"));
        algorithm
          b_theta := {-b[1], -b[2] * .FCSys.Units.K, -b[3] * .FCSys.Units.K ^ 2, (-b[4]) + b[1] * log(.FCSys.Units.K) + log(1e4 * .FCSys.Units.m * .FCSys.Units.K / .FCSys.Units.W)};
          annotation(Inline = true);
        end fromNASAThermalConductivity;
        annotation(defaultComponentPrefixes = "replaceable", Documentation(info = "<html><p>The correlations for transport properties are available in
        [<a href=\"modelica://FCSys.UsersGuide.References.McBride1996\">McBride1996</a>,
        <a href=\"modelica://FCSys.UsersGuide.References.McBride2002\">McBride2002</a>]. For more information, please see the
        <a href=\"modelica://FCSys.Characteristics.BaseClasses.Characteristic\">Characteristic</a> package.</p></html>"));
      end CharacteristicNASA;

      package Characteristic  "Package of thermodynamic and diffusive properties"
        extends CharacteristicEOS;
        constant String formula "Chemical formula";
        constant Phase phase "Material phase";
        constant .FCSys.Quantities.MassSpecific m "Specific mass";
        constant .FCSys.Quantities.LengthSpecific d "Specific diameter";
        constant ReferenceEnthalpy referenceEnthalpy = ReferenceEnthalpy.enthalpyOfFormationAt25degC "Choice of enthalpy reference";
        constant .FCSys.Quantities.PotentialChemical Deltah0_f "<html>Enthalpy of formation at 298.15 K, <i>p</i><sup>o</sup> (&Delta;<i>h</i><sup>o</sup><sub>f</sub>)</html>";
        constant .FCSys.Quantities.PotentialChemical Deltah0 "<html><i>h</i><sup>o</sup>(298.15 K) - <i>h</i><sup>o</sup>(0 K) (&Delta;<i>h</i><sup>o</sup>)</html>";
        constant .FCSys.Quantities.PotentialChemical h_offset = 0 "<html>Additional enthalpy offset (<i>h</i><sub>offset</sub>)</html>";
        constant Integer n_c = -2 "<html>Power of <i>T</i> for 1<sup>st</sup> column of <i>b</i><sub><i>c</i></sub> (<i>n</i><sub><i>c</i></sub>)</html>";
        constant .FCSys.Quantities.TemperatureAbsolute[:] T_lim_c = {0, Modelica.Constants.inf} "<html>Temperature limits for the rows of <i>b</i><sub><i>c</i></sub> and <i>B</i><sub><i>c</i></sub> (<i>T</i><sub>lim <i>c</i></sub>)</html>";
        constant Real[size(T_lim_c, 1) - 1, :] b_c "<html>Coefficients of isobaric specific heat capacity at <i>p</i><sup>o</sup> as a polynomial in <i>T</i> (<i>b</i><sub><i>c</i></sub>)</html>";
        constant Real[size(T_lim_c, 1) - 1, 2] B_c "<html>Integration constants for specific enthalpy and entropy (<i>B</i><sub><i>c</i></sub>)</html>";

        function g  "Gibbs potential as a function of temperature and pressure"
          extends Modelica.Icons.Function;
          input .FCSys.Quantities.TemperatureAbsolute T = 298.15 * .FCSys.Units.K "Temperature" annotation(Dialog(__Dymola_label = "<html><i>T</i></html>"));
          input .FCSys.Quantities.PressureAbsolute p = p0 "Pressure" annotation(Dialog(__Dymola_label = "<html><i>p</i></html>"));
          output .FCSys.Quantities.Potential g "Gibbs potential" annotation(Dialog(__Dymola_label = "<html><i>g</i></html>"));
        algorithm
          g := h(T, p) - T * s(T, p);
          annotation(Inline = true);
        end g;

        function h  "Specific enthalpy as a function of temperature and pressure"
          extends Modelica.Icons.Function;
          input .FCSys.Quantities.TemperatureAbsolute T = 298.15 * .FCSys.Units.K "Temperature" annotation(Dialog(__Dymola_label = "<html><i>T</i></html>"));
          input .FCSys.Quantities.PressureAbsolute p = p0 "Pressure" annotation(Dialog(__Dymola_label = "<html><i>p</i></html>"));
          output .FCSys.Quantities.Potential h "Specific enthalpy" annotation(Dialog(__Dymola_label = "<html><i>h</i></html>"));

        protected
          function h0_i  "Return h0 as a function of T using one of the temperature intervals"
            input .FCSys.Quantities.TemperatureAbsolute T "Temperature";
            input Integer i "Index of the temperature interval";
            output .FCSys.Quantities.Potential h0 "Specific enthalpy at given temperature relative to enthalpy of formation at 25 degC, both at reference pressure";
          algorithm
            h0 := .FCSys.Utilities.Polynomial.F(T, b_c[i, :], n_c) + B_c[i, 1] annotation(Inline = true, derivative = dh0_i);
          end h0_i;

          function h_resid  "Residual specific enthalpy for pressure adjustment for selected rows of b_v"
            input .FCSys.Quantities.TemperatureAbsolute T "Temperature";
            input .FCSys.Quantities.PressureAbsolute p "Pressure";
            input Integer[2] rowLimits = {1, size(b_v, 1)} "Beginning and ending indices of rows of b_v to be included";
            output .FCSys.Quantities.Potential h_resid "Integral of (delh/delp)_T*dp up to p with zero integration constant (for selected rows)";
          algorithm
            h_resid := .FCSys.Utilities.Polynomial.F(p, {.FCSys.Utilities.Polynomial.f(T, b_v[i, :] .* {n_v[1] - n_v[2] + i - j + 1 for j in 1:size(b_v, 2)}, n_v[2] - n_v[1] - i + 1) for i in rowLimits[1]:rowLimits[2]}, n_v[1] + rowLimits[1] - 1) annotation(Inline = true);
          end h_resid;
        algorithm
          h := smooth(1, sum(if (T_lim_c[i] <= T or i == 1) and (T < T_lim_c[i + 1] or i == size(b_c, 1)) then h0_i(T, i) else 0 for i in 1:size(b_c, 1))) + (if referenceEnthalpy == ReferenceEnthalpy.zeroAt0K then Deltah0 else 0) - (if referenceEnthalpy == ReferenceEnthalpy.enthalpyOfFormationAt25degC then 0 else Deltah0_f) + h_offset + h_resid(T, p) - (if phase <> Phase.gas then h_resid(T, p0) else h_resid(T, p0, {1, -n_v[1]}));
          annotation(InlineNoEvent = true, Inline = true, smoothOrder = 1, Documentation(info = "<html>
          <p>For an ideal gas, this function is independent of pressure
          (although pressure remains as a valid input).</p>
            </html>"));
        end h;

        function s  "Specific entropy as a function of temperature and pressure"
          extends Modelica.Icons.Function;
          input .FCSys.Quantities.TemperatureAbsolute T = 298.15 * .FCSys.Units.K "Temperature" annotation(Dialog(__Dymola_label = "<html><i>T</i></html>"));
          input .FCSys.Quantities.PressureAbsolute p = p0 "Pressure" annotation(Dialog(__Dymola_label = "<html><i>p</i></html>"));
          output .FCSys.Quantities.NumberAbsolute s "Specific entropy" annotation(Dialog(__Dymola_label = "<html><i>s</i></html>"));

        protected
          function s0_i  "Return s0 as a function of T using one of the temperature intervals"
            input .FCSys.Quantities.TemperatureAbsolute T "Temperature";
            input Integer i "Index of the temperature interval";
            output .FCSys.Quantities.NumberAbsolute s0 "Specific entropy at given temperature and reference pressure";
          algorithm
            s0 := .FCSys.Utilities.Polynomial.F(T, b_c[i, :], n_c - 1) + B_c[i, 2];
            annotation(Inline = true, derivative = ds0_i);
          end s0_i;

          function ds0_i  "Derivative of s0_i"
            input .FCSys.Quantities.TemperatureAbsolute T "Temperature";
            input Integer i "Index of the temperature interval";
            input .FCSys.Quantities.Temperature dT "Derivative of temperature";
            output .FCSys.Quantities.Number ds0 "Derivative of specific entropy at given temperature and reference pressure";
          algorithm
            ds0 := .FCSys.Utilities.Polynomial.f(T, b_c[i, :], n_c - 1) * dT;
            annotation(Inline = true);
          end ds0_i;

          function s_resid  "Residual specific entropy for pressure adjustment for selected rows of b_v"
            input .FCSys.Quantities.TemperatureAbsolute T "Temperature";
            input .FCSys.Quantities.PressureAbsolute p "Pressure";
            input Integer[2] rowLimits = {1, size(b_v, 1)} "Beginning and ending indices of rows of b_v to be included";
            output .FCSys.Quantities.NumberAbsolute s_resid "Integral of (dels/delp)_T*dp up to p with zero integration constant (for selected rows)";
          algorithm
            s_resid := .FCSys.Utilities.Polynomial.F(p, {.FCSys.Utilities.Polynomial.f(T, b_v[i, :] .* {n_v[1] - n_v[2] + i - j for j in 1:size(b_v, 2)}, n_v[2] - n_v[1] - i) for i in rowLimits[1]:rowLimits[2]}, n_v[1] + rowLimits[1] - 1);
            annotation(Inline = true, derivative = ds_resid);
          end s_resid;

          function ds_resid  "Derivative of s_resid"
            input .FCSys.Quantities.TemperatureAbsolute T "Temperature";
            input .FCSys.Quantities.PressureAbsolute p "Pressure";
            input Integer[2] rowLimits = {1, size(b_v, 1)} "Beginning and ending indices of rows of b_v to be included";
            input .FCSys.Quantities.Temperature dT "Derivative of temperature";
            input .FCSys.Quantities.Pressure dp "Derivative of pressure";
            output .FCSys.Quantities.Number ds_resid "Derivative of integral of (dels/delp)_T*dp up to p with zero integration constant (for selected rows)";
          algorithm
            ds_resid := .FCSys.Utilities.Polynomial.dF(p, {.FCSys.Utilities.Polynomial.df(T, b_v[i, :] .* {n_v[1] - n_v[2] + i - j for j in 1:size(b_v, 2)}, n_v[2] - n_v[1] - i, dT) for i in rowLimits[1]:rowLimits[2]}, n_v[1] + rowLimits[1] - 1, dp);
            annotation(Inline = true);
          end ds_resid;
        algorithm
          s := smooth(1, sum(if (T_lim_c[i] <= T or i == 1) and (T < T_lim_c[i + 1] or i == size(b_c, 1)) then s0_i(T, i) else 0 for i in 1:size(b_c, 1))) + s_resid(T, p) - (if phase <> Phase.gas then s_resid(T, p0) else s_resid(T, p0, {1, -n_v[1]}));
          annotation(InlineNoEvent = true, Inline = true, smoothOrder = 1);
        end s;
        annotation(defaultComponentPrefixes = "replaceable", Documentation(info = "<html>
          <p>This package is compatible with NASA CEA thermodynamic data
          [<a href=\"modelica://FCSys.UsersGuide.References.McBride2002\">McBride2002</a>] and the virial equation of state
          [<a href=\"modelica://FCSys.UsersGuide.References.Dymond2002\">Dymond2002</a>].</p>

      <p>Notes regarding the constants:</p>
          <ul>
          <li>Currently, <code>formula</code> may not contain parentheses or brackets.</li>

          <li><i>d</i> is the Van der Waals diameter or the diameter for the
          rigid-sphere (\"billiard-ball\") approximation of the kinetic theory of gases
          [<a href=\"modelica://FCSys.UsersGuide.References.Present1958\">Present1958</a>].</li>

          <li><i>b<sub>c</sub></i>: The rows give the coefficients for the temperature intervals bounded
          by the values in <i>T</i><sub>lim <i>c</i></sub>.
          The powers of <i>T</i> increase
          by column.
          By default,
          the powers of <i>T</i> for the first column are each -2, which corresponds to [<a href=\"modelica://FCSys.UsersGuide.References.McBride2002\">McBride2002</a>].
          In that case, the dimensionalities of the coefficients are {L4.M2/(N2.T4), L2.M/(N.T2), 1, &hellip;}
          for each row, where L is length, M is mass, N is particle number, and T is time. (In <a href=\"modelica://FCSys\">FCSys</a>,
          temperature is a potential with dimension L2.M/(N.T2); see
          the <a href=\"modelica://FCSys.Units\">Units</a> package.)</li>

          <li><i>B<sub>c</sub></i>: As in <i>b<sub>c</sub></i>, the rows correspond to different
          temperature intervals.  The first column is for specific enthalpy and has dimensionality
          L2.M/(N.T2).  The second is for specific entropy and is dimensionless.
          The integration constants for enthalpy are defined such that the enthalpy at
          25&nbsp;&deg;C is the specific enthalpy of formation at that temperature and reference pressure
          [<a href=\"modelica://FCSys.UsersGuide.References.McBride2002\">McBride2002</a>, p.&nbsp;2].
          The integration constants for specific entropy are defined such that specific entropy is absolute.</li>

          <li><i>T</i><sub>lim <i>c</i></sub>: The first and last entries are the minimum and
          maximum valid temperatures.  The intermediate entries are the thresholds
          between rows of <i>b<sub>c</sub></i> (and <i>B<sub>c</sub></i>).  Therefore, if there are <i>n</i> temperature intervals
          (and rows in <i>b<sub>c</sub></i> and <i>B<sub>c</sub></i>), then <i>T</i><sub>lim <i>c</i></sub> must
          have <i>n</i> + 1 entries.</li>

          <li>The reference pressure is <i>p</i><sup>o</sup>.   In the
          NASA CEA data [<a href=\"modelica://FCSys.UsersGuide.References.McBride2002\">McBride2002</a>], it is 1&nbsp;bar for gases and 1&nbsp;atm for condensed
          species.  For gases, the reference state is the ideal gas at <i>p</i><sup>o</sup>.
          For example, the enthalpy of a non-ideal (real) gas at 25&nbsp;&deg;C and <i>p</i><sup>o</sup> with
          <code>ReferenceEnthalpy.zeroAt25degC</code> is not exactly zero.</li>

          <li>If the material is gaseous (<code>phase == Phase.gas</code>), then the first virial coefficient
          must be independent of temperature.  Otherwise, the function for specific enthalpy
          (<a href=\"modelica://FCSys.Characteristics.BaseClasses.Characteristic.h\"><i>h</i></a>) will be ill-posed.
          Typically, the first virial coefficient is one (or equivalently <code>U.R</code>), which satisfies
          this requirement.</li>
          </ul></html>"));
      end Characteristic;

      package CharacteristicEOS  "<html>Base thermodynamic package with only the <i>p</i>-<i>v</i>-<i>T</i> relations</html>"
        extends Modelica.Icons.MaterialPropertiesPackage;
        constant .FCSys.Quantities.PressureAbsolute p0 = .FCSys.Units.bar "<html>Reference pressure (<i>p</i><sup>o</sup>)</html>";
        constant Integer[2] n_v = {-1, 0} "<html>Powers of <i>p</i>/<i>T</i> and <i>T</i> for 1<sup>st</sup> row and column of <i>b</i><sub><i>v</i></sub> (<i>n</i><sub><i>v</i></sub>)</html>";
        constant Real[:, :] b_v = [1] "<html>Coefficients for specific volume as a polynomial in <i>p</i>/<i>T</i> and <i>T</i> (<i>b</i><sub><i>v</i></sub>)</html>";
      protected
        final constant Integer[2] n_p = {n_v[1] - size(b_v, 1) + 1, n_v[2] + 1} "<html>Powers of <i>v</i> and <i>T</i> for 1<sup>st</sup> row and column of <i>b<sub>p</sub></i></html>";
        annotation(defaultComponentPrefixes = "replaceable", Documentation(info = "<html>
          <p>This package may be used with
          the assumption of ideal gas or of constant specific volume, although it is more general than
          that.</p>

      <p>Notes regarding the constants:</p>
          <ul>
          <li><i>b<sub>v</sub></i>: The powers of <i>p</i>/<i>T</i> increase by row.  The powers of
          <i>T</i> increase by column.  If <code>n_v[1] == -1</code>, then the rows
          of <i>b<sub>v</sub></i> correspond to 1, <i>B</i><sup>*</sup><i>T</i>,
          <i>C</i><sup>*</sup><i>T</i><sup>2</sup>, <i>D</i><sup>*</sup><i>T</i><sup>3</sup>, &hellip;,
          where
          1, <i>B</i><sup>*</sup>, <i>C</i><sup>*</sup>, and <i>D</i><sup>*</sup> are
          the first, second, third, and fourth coefficients in the volume-explicit
          virial equation of state
          [<a href=\"modelica://FCSys.UsersGuide.References.Dymond2002\">Dymond2002</a>, pp.&nbsp;1&ndash;2].
          Currently,
          virial equations of state are supported up to the fourth coefficient (<i>D</i><sup>*</sup>).
          If additional terms are required, review and modify the definition of <i>b<sub>p</sub></i>.</li>

          <li>The defaults for <i>b<sub>v</sub></i> and <i>n<sub>v</sub></i> represent ideal gas.</li>
          </ul></html>"));
      end CharacteristicEOS;

      type ReferenceEnthalpy = enumeration(zeroAt0K "Enthalpy at 0 K and p0 is 0 (if no additional offset)", zeroAt25degC "Enthalpy at 25 degC and p0 is 0 (if no additional offset)", enthalpyOfFormationAt25degC "Enthalpy at 25 degC and p0 is enthalpy of formation at 25 degC and p0 (if no additional offset)") "Enumeration for the reference enthalpy of a species";
      type Phase = enumeration(gas "Gas", solid "Solid", liquid "Liquid") "Enumeration for material phases";
    end BaseClasses;
    annotation(Documentation(info = "<html>
    <p>Each species has a subpackage for each material phase in which the species
    is represented.  The thermodynamic properties are generally different for each phase.</p>

  <p>Additional materials may be included as needed.  The thermodynamic data for
    materials that are condensed at standard conditions is available in
    [<a href=\"modelica://FCSys.UsersGuide.References.McBride2002\">McBride2002</a>].
    The thermodynamic data for materials
    that are gases at standard conditions is available in
    <a href=\"modelica://Modelica.Media.IdealGases.Common.SingleGasesData\">Modelica.Media.IdealGases.Common.SingleGasesData</a>
    (and [<a href=\"modelica://FCSys.UsersGuide.References.McBride2002\">McBride2002</a>]). Virial coefficients are available in
    [<a href=\"modelica://FCSys.UsersGuide.References.Dymond2002\">Dymond2002</a>].  Transport characteristics are available in
    [<a href=\"modelica://FCSys.UsersGuide.References.McBride1996\">McBride1996</a>,
    <a href=\"modelica://FCSys.UsersGuide.References.McBride2002\">McBride2002</a>].</p>

    <p><b>Licensed by the Hawaii Natural Energy Institute under the Modelica License 2</b><br>
  Copyright &copy; 2007&ndash;2014, <a href=\"http://www.hnei.hawaii.edu/\">Hawaii Natural Energy Institute</a> and <a href=\"http://www.gtrc.gatech.edu/\">Georgia Tech Research Corporation</a>.</p>

  <p><i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>;
  it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the
  disclaimer of warranty) see <a href=\"modelica://FCSys.UsersGuide.License\">
  FCSys.UsersGuide.License</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">
  http://www.modelica.org/licenses/ModelicaLicense2</a>.</i></p>
  </html>"), Icon(graphics = {Line(points = {{-76, -80}, {-62, -30}, {-32, 40}, {4, 66}, {48, 66}, {73, 45}, {62, -8}, {48, -50}, {38, -80}}, color = {64, 64, 64}, smooth = Smooth.Bezier), Line(points = {{-40, 20}, {68, 20}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-40, 20}, {-44, 88}, {-44, 88}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{68, 20}, {86, -58}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-60, -28}, {56, -28}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-60, -28}, {-74, 84}, {-74, 84}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{56, -28}, {70, -80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-76, -80}, {38, -80}}, color = {175, 175, 175}, smooth = Smooth.None), Line(points = {{-76, -80}, {-94, -16}, {-94, -16}}, color = {175, 175, 175}, smooth = Smooth.None)}));
  end Characteristics;

  package Units  "Constants and units of physical measure"
    extends Modelica.Icons.Package;

    package Bases  "Sets of base constants and units"
      extends Modelica.Icons.Package;

      record LH  "<html>Base constants and units for Lorentz-Heaviside units (&mu;<sub>0</sub> = &epsilon;<sub>0</sub> = 1)</html>"
        extends Base(final c = 1, final R_K = 25812.8074434 / (4 * pi * 299792458 * 1e-7));
        annotation(Documentation(info = "<html><p>Lorentz-Heaviside systems of units impose:</p>
        <ul>
        <li>&mu;<sub>0</sub> = 1 &rArr; <i>R</i><sub>K</sub>/<i>c</i> = 1/(2&alpha;)</li>
        <li>&epsilon;<sub>0</sub> = 1 &rArr; <i>R</i><sub>K</sub>&nbsp;<i>c</i> = 1/(2&alpha;)</li>
        </ul>
        <p>Together, <i>c</i> = 1 and <i>R</i><sub>K</sub> = 1/(2&alpha;)</p>

      <p>The Lorentz-Heaviside conditions are not sufficient
      to fully establish the values of the base constants and units of the
      <a href=\"modelica://FCSys.Units\">Units</a> package.  Lorentz-Heaviside units
      encompass other systems of units.</p>

      <p>For more information, please see the documentation for the
        <a href=\"modelica://FCSys.Units\">Units</a> package.</p></html>"));
      end LH;

      record SImols  "<html>Base constants and units for SI with <i>k</i><sub>F</sub> and <i>R</i> normalized instead of mol and s</html>"
        extends Base(final R_inf = 10973731.568539, final c = (96485.3365 / 8.3144621) ^ (1 / 3) * 299792458, final R_K = 96485.3365 * 25812.8074434 / 8.3144621, final k_J = 483597.870e9 * sqrt(S * s) / m, final 'cd' = 1);
        annotation(Documentation(info = "<html><p>The values of the un-normalized SI base units are (see
        <a href=\"modelica://FCSys/Resources/unit-systems.cdf\">Resources/unit-systems.cdf</a>):</p>
        <ul>
        <li>mol &asymp; 4261.73</li>
        <li>s &asymp; 0.0441697</li>
        </ul>

      <p>For more information, please see the documentation for the
        <a href=\"modelica://FCSys.Units\">Units</a> package.</p></html>"), Commands(executeCall = FCSys.Units.setup()));
      end SImols;

      record Base  "Base constants and units"
        extends Modelica.Icons.Record;
        final constant .FCSys.Quantities.Angle rad = 1 "radian";
        constant .FCSys.Quantities.Wavenumber R_inf = 1 "<html>Rydberg constant (R<sub>&infin;</sub>)</html>";
        constant .FCSys.Quantities.Velocity c = 1 "<html>speed of light in vacuum (c)</html>";
        constant .FCSys.Quantities.MagneticFluxReciprocal k_J = 1 "<html>Josephson constant (k<sub>J</sub>)</html>";
        constant .FCSys.Quantities.ResistanceElectrical R_K = 1 "<html>von Klitzing constant (R<sub>K</sub>)</html>";
        constant .FCSys.Quantities.PowerRadiant 'cd' = 1 "candela";
        final constant .FCSys.Quantities.Number k_F = 1 "<html>Faraday constant (k<sub>F</sub>)</html>";
        final constant .FCSys.Quantities.Number R = 1 "gas constant";
        annotation(Documentation(info = "<html><p>Please see the notes in the Modelica code and the documentation of the
        <a href=\"modelica://FCSys.Units\">Units</a> package.</p></html>"), Commands(executeCall = FCSys.Units.setup()));
      end Base;
      annotation(Documentation(info = "<html>
      <p><a href=\"modelica://FCSys\">FCSys</a> requires that the Faraday and gas constants are
      normalized to one.  The structure of the <a href=\"modelica://FCSys.Units\">Units</a> package allows
      those constants to be relaxed, but the models in <a href=\"modelica://FCSys\">FCSys</a>
      generally do not.</p>

      <p>Some natural systems of units
      are not compatible with <a href=\"modelica://FCSys\">FCSys</a>.
      Since the Faraday and gas constants
      are both normalized, it follows that <i>k</i><sub>B</sub> = <i>q</i>.  This is not
      the case for the Planck, Rydberg, and Natural systems of units
      [<a href=\"http://en.wikipedia.org/wiki/Natural_units\">http://en.wikipedia.org/wiki/Natural_units</a>].</p>

      <p>The quasi-SI
      sets in this package are named by listing (in alphabetical order) the two units that are
      <i>not</i> normalized for the sake of setting the Faraday and gas constants equal to one.
      There are eight possible sets of this type (<a href=\"modelica://FCSys.Units.Bases.SIAK\">SIAK</a>,
      <a href=\"modelica://FCSys.Units.Bases.SIAm\">SIAm</a>,
      <a href=\"modelica://FCSys.Units.Bases.SIAs\">SIAs</a>,
      <a href=\"modelica://FCSys.Units.Bases.SIKmol\">SIKmol</a>,
      <a href=\"modelica://FCSys.Units.Bases.SIKs\">SIKs</a>,
      <a href=\"modelica://FCSys.Units.Bases.SImmol\">SImmol</a>
      <a href=\"modelica://FCSys.Units.Bases.SIms\">SIms</a>,
      <a href=\"modelica://FCSys.Units.Bases.SImols\">SImols</a>).</p>

      <p>For more information, please see the documentation for the
      <a href=\"modelica://FCSys.Units\">Units</a> package.</p></html>"), Commands(executeCall = FCSys.Units.setup()));
    end Bases;

    function to_degC  "Convert from temperature as a quantity to temperature in degree Celsius"
      extends Modelica.SIunits.Icons.Conversion;
      input .FCSys.Quantities.TemperatureAbsolute T "Thermodynamic temperature";
      output Real T_degC "Temperature in degree Celsius";
    algorithm
      T_degC := T / K - 273.15;
      annotation(Inline = true, inverse(T = FCSys.Units.from_degC(T_degC)));
    end to_degC;

    final constant .FCSys.Quantities.Number pi = 2 * acos(0) "<html>pi (<i>&pi;</i>)</html>";
    replaceable constant Bases.LH base constrainedby Bases.SImols;
    final constant .FCSys.Quantities.Angle rad = base.rad "radian";
    final constant .FCSys.Quantities.Wavenumber R_inf = base.R_inf "<html>Rydberg constant (<i>R</i><sub>&infin;</sub>)</html>";
    final constant .FCSys.Quantities.Velocity c = base.c "<html>speed of light in vacuum (<i>c</i>)</html>";
    final constant .FCSys.Quantities.MagneticFluxReciprocal k_J = base.k_J "<html>Josephson constant (<i>k</i><sub>J</sub>)</html>";
    final constant .FCSys.Quantities.ResistanceElectrical R_K = base.R_K "<html>von Klitzing constant (<i>R</i><sub>K</sub>)</html>";
    final constant .FCSys.Quantities.PowerRadiant 'cd' = base.'cd' "candela";
    final constant .FCSys.Quantities.Number k_F = base.k_F "<html>Faraday constant (<i>k</i><sub>F</sub>)</html>";
    final constant .FCSys.Quantities.Number R = base.R "gas constant";
    constant .FCSys.Quantities.Length m = 10973731.568539 * rad / R_inf "meter";
    constant .FCSys.Quantities.Time s = 299792458 * m / c "second";
    constant .FCSys.Quantities.MagneticFlux Wb = 483597.870e9 / k_J "weber";
    constant .FCSys.Quantities.ConductanceElectrical S = 25812.8074434 / R_K "siemen";
    constant .FCSys.Quantities.Amount mol = 96485.3365 * Wb * S / k_F "mole";
    constant .FCSys.Quantities.Potential K = 8.3144621 * (Wb * rad) ^ 2 * S / (s * mol * R) "kelvin";
    final constant .FCSys.Quantities.Potential V = Wb * rad / s "volt";
    final constant .FCSys.Quantities.Current A = V * S "ampere";
    final constant .FCSys.Quantities.Amount C = A * s "coulomb";
    final constant .FCSys.Quantities.Energy J = V * C "joule";
    final constant .FCSys.Quantities.Velocity2 Gy = (m / s) ^ 2 "gray";
    final constant .FCSys.Quantities.Mass kg = J / Sv "kilogram ";
    final constant .FCSys.Quantities.Number kilo = 1e3 "kilo (k)";
    final constant .FCSys.Quantities.Number deci = 1e-1 "deci (d)";
    final constant .FCSys.Quantities.Number centi = 1e-2 "centi (c)";
    final constant .FCSys.Quantities.Number milli = 1e-3 "milli (m)";
    final constant .FCSys.Quantities.Number micro = 1e-6 "micro (u)";
    final constant .FCSys.Quantities.Number nano = 1e-9 "nano (n)";
    final constant .FCSys.Quantities.Number pico = 1e-12 "pico (p)";
    final constant .FCSys.Quantities.Angle cyc = 2 * pi * rad "cycle";
    final constant .FCSys.Quantities.Frequency Hz = cyc / s "hertz";
    final constant .FCSys.Quantities.Angle2 sr = rad ^ 2 "steradian";
    final constant .FCSys.Quantities.Force N = J / m "newton";
    final constant .FCSys.Quantities.Pressure Pa = N / m ^ 2 "pascal";
    final constant .FCSys.Quantities.Power W = J / s "watt";
    final constant .FCSys.Quantities.Power lm = 'cd' * sr "lumen";
    final constant .FCSys.Quantities.Velocity2 Sv = Gy "sievert";
    final constant .FCSys.Quantities.Mass g = kg / kilo "gram";
    final constant .FCSys.Quantities.Time min = 60 * s "minute";
    final constant .FCSys.Quantities.Time hr = 60 * min "hour";
    final constant .FCSys.Quantities.Volume L = (deci * m) ^ 3 "liter (L or l)";
    final constant .FCSys.Quantities.ConductanceElectrical G_0 = 2 / R_K "<html>conductance quantum (<i>G</i><sub>0</sub>)</html>";
    final constant .FCSys.Quantities.MagneticFlux Phi_0 = 1 / k_J "<html>magnetic flux quantum (&Phi;<sub>0</sub>)</html>";
    final constant .FCSys.Quantities.Amount q = G_0 * Phi_0 "elementary charge";
    final constant .FCSys.Quantities.MomentumRotational h = 2 * q * Phi_0 "Planck constant";
    final constant .FCSys.Quantities.Number alpha = pi * 1e-7 * c * s * G_0 / (m * S) "<html>fine-structure constant (&alpha;)</html>";
    final constant .FCSys.Quantities.ResistanceElectrical Z_0 = 2 * R_K * alpha "<html>characteristic impedance of vacuum (<i>Z</i><sub>0</sub>)</html>";
    final constant .FCSys.Quantities.Permeability mu_0 = Z_0 / c "<html>magnetic constant (&mu;<sub>0</sub>)</html>";
    final constant .FCSys.Quantities.Permeability k_A = mu_0 / (4 * pi) "<html>magnetic force constant (<i>k</i><sub>A</sub>)</html>";
    final constant .FCSys.Quantities.AmountReciprocal N_A = k_F / q "<html>Avogadro constant (<i>N</i><sub>A</sub>)</html>";
    final constant .FCSys.Quantities.Amount k_B = R / N_A "<html>Boltzmann constant (<i>k</i><sub>B</sub>)</html>";
    final constant .FCSys.Quantities.PotentialPerWavenumber c_2 = h * c / k_B "<html>second radiation constant (<i>c</i><sub>2</sub>)</html>";
    final constant .FCSys.Quantities.Pressure bar = 1e5 * Pa "bar";
    final constant .FCSys.Quantities.Pressure atm = 101325 * Pa "atmosphere";
    final constant .FCSys.Quantities.Length cm = centi * m "centimeter";
    final constant .FCSys.Quantities.Volume cc = cm ^ 3 "cubic centimeter";
    annotation(Documentation(info = "<html>

    <p>The information below has been updated and adapted from
    [<a href=\"modelica://FCSys.UsersGuide.References\">Davies and Paredis, 2012</a>].  That paper
    also offers suggestions as to how the approach might be better integrated in
    <a href=\"http://www.modelica.org\">Modelica</a>.  For more information, please also see the
    documentation of the <a href=\"modelica://FCSys.Quantities\">Quantities</a> package.</p>

  <p><b>Introduction and Overview:</b></p>

  <p>Mathematical models of physical systems use variables to represent physical quantities.
  As stated by the Bureau International des Poids et Mesures (BIPM)
  [<a href=\"modelica://FCSys.UsersGuide.References.BIPM2006\">BIPM2006</a>, p.&nbsp;103]:</p>
  <blockquote>
    \"The value of a quantity is generally expressed as the product of a number and a unit.  The
    unit is simply a particular example of the quantity concerned which is used as a reference, and
    the number is the ratio of the value of the quantity to the unit.\"
  </blockquote>
  <p>In general, a unit may be the product of powers of other units, whether they are base units or
  units derived from the base units in the same manner.</p>

  <p>In <a href=\"http://www.modelica.org\">Modelica</a>, a physical quantity is represented by a variable which is
  an instance of the <code>Real</code>
  type.  Its <code>value</code> attribute is a number associated with the value of the
  quantity (not the value of the quantity itself, as will be shown).  Usually the
  <code>value</code> attribute is not referenced explicitly because it is
  automatically returned when a variable is referenced.
  The <code>unit</code> attribute is a
  string that describes the unit by which the value of the quantity has been divided to arrive at the
  number.  The <code>displayUnit</code> attribute (also
  a string) describes the unit by which the value of the quantity should be divided to arrive at the number as it
  is entered by or presented to the user.  The <code>Real</code> type contains other attributes as
  well, including the <code>quantity</code> string.</p>

  <p>The <a href=\"modelica://Modelica.SIunits\">SIunits</a> package of the <a href=\"modelica://Modelica\">Modelica Standard Library</a> contains types that
  extend from the <code>Real</code> type.  The type definitions modify the
  <code>unit</code>, <code>displayUnit</code>, and <code>quantity</code> attributes (among others)
  to represent various physical quantities.  The <code>unit</code> and <code>displayUnit</code>
  attributes are based on the International System of Units (Syst&egrave;me international d'unit&eacute;s, SI).   The <code>quantity</code> string is
  the name of the physical quantity.  For example, the <a href=\"modelica://Modelica.SIunits.Velocity\">Velocity</a> type has
  a <code>unit</code> of \"m/s\" and a <code>quantity</code> of
  \"Velocity\".  If an instance of <a href=\"modelica://Modelica.SIunits.Velocity\">Velocity</a> has
  a <code>value</code> of one (<i>v</i> = 1),
  then it is meant that \"the value of velocity is one meter per second.\"  Again, the
  <code>value</code> attribute represents the number, or the value of the quantity divided by the unit, not the
  value of the quantity itself.</p>

  <p>This apparent conflict is solved in <a href=\"modelica://FCSys\">FCSys</a> by
  establishing units (including the meter and the second) as mathematical entities and writing
  <i>v</i> = 1&nbsp;m/s (in code, <code>v = 1*U.m/U.s</code> or simply <code>v = U.m/U.s</code>).
  Here, the variable <i>v</i> directly represents the quantity.
  Its <code>value</code> attribute is truly the value of the quantity in the context of the
  statement by BIPM (above).
  One advantage is that unit conversion is handled
  naturally.  The essence of unit conversion is the phrase \"value of a quantity in a unit\" typically means
  \"value of a quantity divided by a unit.\"  Continuing with the previous example, <i>v</i>
  is divided by m/s in order to display <i>v</i> in meters per second (as a
  number).  If another unit of length like the foot is established by the
  appropriate relation (ft &asymp; 0.3048&nbsp;m) and <i>v</i> is divided by
  ft/s, the result is velocity in feet per second (&sim;3.2894).  Some units such as &deg;C, Pag, and dB involve
  offsets or nonlinear transformations between the value of the quantity and the number; these are described by
  functions besides simple division.</p>

  <p>As another example, frequency is sometimes represented by a variable
  in hertz or cycles per second (e.g., &nu;) and other times by a variable in radians
  per second (e.g., &omega;).  If the variable represents the quantity directly, then there
  is no need to specify which units it is in.  The units are included; they have not been factored
  out by division (or another function).  A common variable (e.g., <i>f</i>) can be used in both cases, which
  simplifies and standardizes the equations of a model.  The forms are algebraically equivalent due to the relationships
  among units (e.g., 1&nbsp;cycle = 2&pi;&nbsp;rad).</p>

  <p><b>Method:</b></p>

  <p>In <a href=\"modelica://FCSys\">FCSys</a>, each unit is a constant quantity.
  The values of the units, like other quantities, is the product of a number and a unit.
  Therefore, units may be derived from other units (e.g., cycle = 2&pi;&nbsp;rad).
  This recursive definition leaves several units (in SI, 7) that are locally independent
  and must be established universally.  These
  base units are established by the \"particular example of the quantity
  concerned which is used as a reference\" quoted previously
  [<a href=\"modelica://FCSys.UsersGuide.References.BIPM2006\">BIPM2006</a>].  The choice of the base
  units is somewhat arbitrary [<a href=\"modelica://FCSys.UsersGuide.References.Fritzson2004\">Fritzson2004</a>, p.&nbsp;375],
  but regardless, there are a number of units that must be defined by example.</p>

  <p>If only SI will be used, then it is easiest to set each of the base units of
  SI equal to one&mdash;the meter (m), kilogram (kg), second (s), ampere (A),
  kelvin (K), mole (mol), and candela (cd).  This is implicitly the case in
  the <a href=\"modelica://Modelica.SIunits\">SIunits</a> package, but again, it hardly captures the idea that the
  value of a quantity is the
  product of a number and a unit.</p>

  <p>Instead, in <a href=\"modelica://FCSys\">FCSys</a>, the base units are established by universal
  physical constants (except the candela, which is physically arbitrary).
  The \"particular example of the quantity\"
  [<a href=\"modelica://FCSys.UsersGuide.References.BIPM2006\">BIPM2006</a>] is an experiment that yields
  precise and universally repeatable results in determining a constant rather than a prototype
  (e.g., the International Prototype of the Kilogram) which is
  carefully controlled and distributed via replicas.
  This method of defining the base units from measured physical quantities (rather than
  vice versa) is natural and reflects the way that standards organizations (e.g., <a href=\"http://www.nist.gov/\">NIST</a>) define units.
  A system of units is considered to be natural if
  all of its base units are established by universal physical constants.
  Often, those universal constants are defined to be equal to one, but the values can be chosen to scale
  the numerical values of variables during simulation.</p>

  <p>There are physical systems where typical quantities are many orders of magnitude larger or smaller than the
  related product of powers of base SI units (e.g., the domains of astrophysics and atomic
  physics).  In modeling and simulating those systems, it may be advantageous to choose
  appropriately small or large values (respectively) for the corresponding base units so that the
  product of the number (large or small in magnitude) and the unit (small or large, respectively)
  is well-scaled.  Products of this type are often involved in initial conditions or parameter
  expressions, which are not time-varying.  Therefore, the number and the unit can be multiplied
  before the dynamic simulation.  During the simulation, only the value is important.  After the
  simulation, the trajectory of the value may be divided by the unit for display.  This scaling is
  usually unnecessary due to the wide range and appropriate distribution of the real numbers that
  are representable in floating point.  The Modelica language specification recommends that
  floating point numbers be represented in at least IEEE double precision, which covers magnitudes
  from &sim;2.225&times;10<sup>-308</sup> to &sim;1.798&times;10<sup>308</sup>
  [<a href=\"modelica://FCSys.UsersGuide.References.Modelica2010\">Modelica2010</a>, p.&nbsp;13].
  However, in some cases it may be preferable to scale the units and use lower
  precision for the sake of computational performance.  There are fields of research where,
  even today, simulations are sometimes performed in single precision
  [<a href=\"modelica://FCSys.UsersGuide.References.Brown2011\">Brown2011</a>,
  <a href=\"modelica://FCSys.UsersGuide.References.Hess2008\">Hess2008</a>]
  and where scaling is a concern
  [<a href=\"modelica://FCSys.UsersGuide.References.Rapaport2004\">Rapaport2004</a>, p.&nbsp;29].</p>

  <p>The method is neutral
  with regards to not only the values of the base units, but also the choice of the base units and
  even the number of base units.  This is an advantage because many systems of units besides SI are used in science
  and engineering. As mentioned previously, the choice of base units is somewhat
  arbitrary, and different systems of units are based on different choices.  Some systems of units
  have fewer base units (lower rank) than SI, since additional constraints are added that
  exchange base units for derived units.  For example, the Planck, Stoney, Hartree, and Rydberg
  systems of units define the Boltzmann constant to be equal to one (<i>k</i><sub>B</sub> = 1)
  [<a href=\"http://en.wikipedia.org/wiki/Natural_units\">http://en.wikipedia.org/wiki/Natural_units</a>].
  The unit K is eliminated
  [<a href=\"modelica://FCSys.UsersGuide.References.Greiner1995\">Greiner1995</a>, p.&nbsp;386]
  or, more precisely, considered a derived unit instead of a base unit.  In SI, the
  kelvin would be derived from the units kilogram, meter, and second (K
  &asymp; 1.381&times;10<sup>-23</sup>&nbsp;kg&nbsp;m<sup>2</sup>/s<sup>2</sup>).</p>

      <p>There are six independent units and constants in the <a href=\"modelica://FCSys.Units\">Units</a> package (see
      <a href=\"modelica://FCSys.Units.Bases\">Units.Bases</a>),
      but SI has seven base units (m, kg, s, A, K, mol, and cd).
      In <a href=\"modelica://FCSys\">FCSys</a>, two additional constraints are imposed in order
      to simplify the model equations and allow electrons and chemical species to be to represented by the
      same base <a href=\"modelica://FCSys.Species.Species\">Species</a> model.
      First, the Faraday constant (<i>k</i><sub>F</sub> or 96485.3399&nbsp;C/mol)
      is normalized to one. This implies that the mole (mol) is proportional to the coulomb
      (C), which is considered a number of reference particles given a charge number of one.
      Also, the gas constant (R or 8.314472&nbsp;J/(mol&nbsp;K)) is normalized to one.
      Therefore, the kelvin (K) is proportional to the volt
      (V or J/C). In addition, the radian (rad) is defined as a base constant.
      However, it must be set equal to one in the current specification of the International System of Units (SI)
      [<a href=\"modelica://FCSys.UsersGuide.References.BIPM2006\">BIPM2006</a>].</p>

  <p><b>Implementation:</b></p>

  <p>The units and constants are defined as variables in this
  <a href=\"modelica://FCSys.Units\">Units</a> package.  Each is a <code>constant</code> of
  the appropriate type from the <a href=\"modelica://FCSys.Quantities\">Quantities</a> package. The
  first section of this package establishes mathematical constants.  The next
   section establishes the base constants and units, which grouped in a <code>replaceable</code> subpackage.  The third section
   establishes the constants and units which may be derived from the base units and constants using
   accepted empirical relations.  The rest of the code establishes the SI prefixes
   and the remaining derived units and constants.  The SI prefixes are included in their
   unabbreviated form in order to avoid naming conflicts.  All of the primary units of SI
   are included (Tables 1 and 3 of
   [<a href=\"modelica://FCSys.UsersGuide.References.BIPM2006\">BIPM2006</a>]) except for &deg;C, since
   it involves an offset.  Other units such as the atmosphere (atm) are included for convenience.
   Some units that include prefixes are defined as well (e.g., kg, mm, and kPa).  However,
   most prefixes must be given as explicit factors (e.g., <code>U.kilo*U.m</code>).</p>

    <p>Besides the units and constants, this package also contains functions (e.g., <a href=\"modelica://FCSys.Units.to_degC\">to_degC</a>) that
    convert quantities from the unit system defined in <a href=\"modelica://FCSys\">FCSys</a> to quantities
    expressed in units.  These functions are
    included for units that involve offsets<!-- or other functions besides simple scaling-->.
    For conversions that require just a scaling factor, it is simpler to use the
    units directly.  For example, to convert from potential in volts use <code>v = v_V*U.V</code>,
    where <code>v</code> is potential and <code>v_V</code> is potential expressed in volts.</p>

    <p>This package (<a href=\"modelica://FCSys.Units\">Units</a>) is abbreviated as <code>U</code> for convenience throughout
    the rest of <a href=\"modelica://FCSys.FCSys\">FCSys</a>.  For example, an initial pressure might be defined as
    <i>p</i><sub>IC</sub> = <code>U.atm</code>.</p>

  <p>An instance of the <a href=\"modelica://FCSys.Conditions.Environment\">Environment</a> model is usually included
  at the top level of a model.  It records the base units and constants so that it is possible to re-derive
  all of the other units and constants.  This is important in order to properly interpret simulation results if the
  base units and constants are later re-adjusted.</p>

  <p>The <a href=\"modelica://FCSys.Units.setup\">Units.setup</a> function establishes unit conversions
  using the values of the units, constants, and prefixes.  These unit conversions may include offsets.
  The function also sets the default display units.  It is automatically called when
  <a href=\"modelica://FCSys\">FCSys</a> is
  loaded from the <a href=\"modelica://FCSys/../load.mos\">load.mos</a> script.  It can also be called manually from the
  \"Re-initialize the units\" command available in the Modelica development environment from the
  <a href=\"modelica://FCSys.Units\">Units</a> package or any subpackage.  A spreadsheet
  (<a href=\"modelica://FCSys/Resources/quantities.xls\">Resources/quantities.xls</a>) is available to help
  maintain the quantities, default units, and the setup function.</p>

  <p>The values of the units, constants, and prefixes can be evaluated by translating the
  <a href=\"modelica://FCSys.Units.Examples.Evaluate\">Units.Examples.Evaluate</a> model.  This
  defines the values in the workspace of the Modelica development environment.
  For convenience, the <a href=\"modelica://FCSys/../load.mos\">load.mos</a> script automatically
  does this and saves the result as \"units.mos\" in the working directory.</p>

  <p>Where the <code>der</code> operator is used in models, it is explicitly divided by the unit second
  (e.g., <code>der(x)/U.s</code>).  This is necessary because the global variable <code>time</code>
  is in seconds (i.e., <code>time</code> is a number, not a quantity).</p>

    <p>Although it is not necessary due to the acausal nature of <a href=\"http://www.modelica.org\">Modelica</a>, the declarations
    in this package are sorted so that they can be easily ported to imperative or causal languages (e.g.,
    <a href=\"http://www.python.org\">Python</a> and C).  In fact, this has been done in the
    included <a href=\"modelica://FCSys/Resources/Source/Python/doc/index.html\">FCRes</a> module for
    plotting and analysis.</p>

    <p><b>Licensed by the Hawaii Natural Energy Institute under the Modelica License 2</b><br>
  Copyright &copy; 2007&ndash;2014, <a href=\"http://www.hnei.hawaii.edu/\">Hawaii Natural Energy Institute</a> and <a href=\"http://www.gtrc.gatech.edu/\">Georgia Tech Research Corporation</a>.</p>

  <p><i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>;
  it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the
  disclaimer of warranty) see <a href=\"modelica://FCSys.UsersGuide.License\">
  FCSys.UsersGuide.License</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">
  http://www.modelica.org/licenses/ModelicaLicense2</a>.</i></p>
  </html>"), Commands(executeCall = FCSys.Units.setup()), Icon(graphics = {Line(points = {{-66, 78}, {-66, -40}}, color = {64, 64, 64}, smooth = Smooth.None), Ellipse(extent = {{12, 36}, {68, -38}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-74, 78}, {-66, -40}}, lineColor = {64, 64, 64}, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-66, -4}, {-66, 6}, {-16, 56}, {-16, 46}, {-66, -4}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Polygon(points = {{-46, 16}, {-40, 22}, {-2, -40}, {-10, -40}, {-46, 16}}, lineColor = {64, 64, 64}, smooth = Smooth.None, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid), Ellipse(extent = {{22, 26}, {58, -28}}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{68, 2}, {68, -46}, {64, -60}, {58, -68}, {48, -72}, {18, -72}, {18, -64}, {46, -64}, {54, -60}, {58, -54}, {60, -46}, {60, -26}, {64, -20}, {68, -6}, {68, 2}}, lineColor = {64, 64, 64}, smooth = Smooth.Bezier, fillColor = {175, 175, 175}, fillPattern = FillPattern.Solid)}));
  end Units;

  package Quantities  "Types to represent physical values"
    extends Modelica.Icons.TypesPackage;
    type Acceleration = .Modelica.Icons.TypeReal(final unit = "L/T2");
    type Amount = .Modelica.Icons.TypeReal(final unit = "N", min = 0);
    type AmountReciprocal = .Modelica.Icons.TypeReal(final unit = "1/N", min = 0) "Reciprocal of amount";
    type Angle = .Modelica.Icons.TypeReal(final unit = "A");
    type Angle2 = .Modelica.Icons.TypeReal(final unit = "A2") "Solid angle";
    type AreaSpecific = .Modelica.Icons.TypeReal(final unit = "L2/N", min = 0) "Specific area";
    type Capacitance = .Modelica.Icons.TypeReal(final unit = "N2.T2/(L2.M)", min = 0);
    type Density = .Modelica.Icons.TypeReal(final unit = "N/L3", min = 0);
    type ConductanceElectrical = .Modelica.Icons.TypeReal(final unit = "N2.T/(L2.M)", min = 0) "Electrical conductance";
    type Current = .Modelica.Icons.TypeReal(final unit = "N/T");
    type Energy = .Modelica.Icons.TypeReal(final unit = "L2.M/T2");
    type Force = .Modelica.Icons.TypeReal(final unit = "L.M/T2");
    type ForceSpecific = .Modelica.Icons.TypeReal(final unit = "L.M/(N.T2)") "Specific force";
    type Frequency = .Modelica.Icons.TypeReal(final unit = "A/T");
    type Inductance = .Modelica.Icons.TypeReal(final unit = "L2.M/N2", min = 0);
    type Length = .Modelica.Icons.TypeReal(final unit = "L", min = 0);
    type LengthSpecific = .Modelica.Icons.TypeReal(final unit = "L/N", min = 0) "Specific length";
    type MagneticFlux = .Modelica.Icons.TypeReal(final unit = "L2.M/(A.N.T)") "Magnetic flux";
    type MagneticFluxAreic = .Modelica.Icons.TypeReal(final unit = "M/(A.N.T)") "Areic magnetic flux";
    type MagneticFluxReciprocal = .Modelica.Icons.TypeReal(final unit = "A.N.T/(L2.M)") "Reciprocal of magnetic flux";
    type Mass = .Modelica.Icons.TypeReal(final unit = "M", min = 0);
    type MassSpecific = .Modelica.Icons.TypeReal(final unit = "M/N", min = 0) "Specific mass";
    type MomentumRotational = .Modelica.Icons.TypeReal(final unit = "L2.M/(A.T)") "Rotational momentum";
    type Number = .Modelica.Icons.TypeReal(final unit = "1");
    type NumberAbsolute = .Modelica.Icons.TypeReal(final unit = "1", min = 0) "Absolute number";
    type Permeability = .Modelica.Icons.TypeReal(final unit = "L.M/N2", min = 0);
    type Permittivity = .Modelica.Icons.TypeReal(final unit = "N2.T2/(L3.M)", min = 0);
    type PermittivityReciprocal = .Modelica.Icons.TypeReal(final unit = "L3.M/(N2.T2)", min = 0) "Reciprocal of permittivity";
    type Potential = .Modelica.Icons.TypeReal(final unit = "L2.M/(N.T2)");
    type PotentialAbsolute = .Modelica.Icons.TypeReal(final unit = "L2.M/(N.T2)", min = 0) "Absolute potential";
    type PotentialPerWavenumber = .Modelica.Icons.TypeReal(final unit = "L3.M/(A.N.T2)") "Potential per wavenumber";
    type Power = .Modelica.Icons.TypeReal(final unit = "L2.M/T3");
    type PowerArea = .Modelica.Icons.TypeReal(final unit = "L4.M/T3") "Power times area";
    type PowerAreic = .Modelica.Icons.TypeReal(final unit = "M/T3") "Areic power";
    type PowerAreicPerPotential4 = .Modelica.Icons.TypeReal(final unit = "M.T5/L8") "Areic power per 4th power of potential";
    type PowerRadiant = .Modelica.Icons.TypeReal(final unit = "L2.M/(A2.T3)") "Radiant power";
    type Pressure = .Modelica.Icons.TypeReal(final unit = "M/(L.T2)");
    type PressureAbsolute = .Modelica.Icons.TypeReal(final unit = "M/(L.T2)", min = 0) "Absolute pressure";
    type ResistanceElectrical = .Modelica.Icons.TypeReal(final unit = "L2.M/(N2.T)", min = 0) "Electrical resistance";
    type Time = .Modelica.Icons.TypeReal(final unit = "T");
    type Velocity = .Modelica.Icons.TypeReal(final unit = "L/T");
    type Velocity2 = .Modelica.Icons.TypeReal(final unit = "L2/T2") "Squared velocity";
    type Volume = .Modelica.Icons.TypeReal(final unit = "L3", min = 0);
    type Wavenumber = .Modelica.Icons.TypeReal(final unit = "A/L");
    type PotentialChemical = Potential(displayUnit = "J/mol") "Chemical potential";
    type Temperature = Potential(displayUnit = "K");
    type TemperatureAbsolute = PotentialAbsolute(displayUnit = "degC") "Absolute temperature";
    annotation(Documentation(info = "<html><p>In <a href=\"modelica://FCSys.FCSys\">FCSys</a>, the
  <code>unit</code> attribute of each <code>Real</code> variable actually denotes the
    dimension.<sup><a href=\"#fn1\" id=\"ref1\">1</a></sup>  The fundamental dimensions are
    angle (A), length (L), mass (M), particle number (N), and time (T).  These
    are combined according to the rules established for unit strings
    [<a href=\"modelica://FCSys.UsersGuide.References.Modelica2010\">Modelica2010</a>, p.&nbsp;210].
  Temperature and charge are derived dimensions
    (see the <a href=\"modelica://FCSys.Units\">Units</a> package).</p>

    <p>The <code>quantity</code> attribute is not used since the type <i>is</i> the quantity.
  The <code>displayUnit</code> attribute is
    only used for quantities that imply a certain display unit.</p>

    <p>Methods for unit checking
    have been established [<a href=\"modelica://FCSys.UsersGuide.References.Mattsson2008\">Mattsson2008</a>,
    <a href=\"modelica://FCSys.UsersGuide.References.Broman2008\">Broman2008</a>,
    <a href=\"modelica://FCSys.UsersGuide.References.Aronsson2009\">Aronsson2009</a>] and can, in theory, be applied to
    dimension checking instead.</p>

    <p>The <a href=\"modelica://FCSys.Quantities\">Quantities</a> package is abbreviated as <code>Q</code> throughout
    the rest of <a href=\"modelica://FCSys.FCSys\">FCSys</a>.</p>
  The quantities are generally named with adjectives following the noun so that the
    quantities are grouped when alphabetized.
  Some quantities are aliases to other quantities but with special implied display units.
  For example, <a href=\"modelica://FCSys.Quantities.Temperature\">Temperature</a> is an alias for
  <a href=\"modelica://FCSys.Quantities.Potential\">Potential</a> with a default
  display unit of K.\footnote{Temperature is a potential in the chosen system of units;
  see the next section (\ref{sec:Units}).}  Also, some quantities have minimum values
  (e.g., zero for <a href=\"modelica://FCSys.Quantities.PressureAbsolute\">PressureAbsolute</a>).
  For more information, please see the
    documentation of the <a href=\"modelica://FCSys.Units\">Units</a> package.

      <hr>

      <p id=\"fn1\"><small>1. This misnomer is necessary because <code>Real</code> variables do not have a <code>dimension</code>
      attribute.<a href=\"#ref1\" title=\"Jump back to footnote 1 in the text.\">&#8629;</a></small></p>

    <p><b>Licensed by the Hawaii Natural Energy Institute under the Modelica License 2</b><br>
  Copyright &copy; 2007&ndash;2014, <a href=\"http://www.hnei.hawaii.edu/\">Hawaii Natural Energy Institute</a> and <a href=\"http://www.gtrc.gatech.edu/\">Georgia Tech Research Corporation</a>.</p>

  <p><i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>;
  it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the
  disclaimer of warranty) see <a href=\"modelica://FCSys.UsersGuide.License\">
  FCSys.UsersGuide.License</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">
  http://www.modelica.org/licenses/ModelicaLicense2</a>.</i></p>
  </html>"));
  end Quantities;

  package Utilities  "General supporting functions"
    extends Modelica.Icons.UtilitiesPackage;

    package Chemistry  "Functions to support chemistry"
      extends Modelica.Icons.Package;

      function charge  "Return the charge of a species given its chemical formula"
        extends Modelica.Icons.Function;
        input String formula "Chemical formula";
        output Integer z "Charge number" annotation(Dialog(__Dymola_label = "<html><i>z</i></html>"));
        external "C" annotation(IncludeDirectory = "modelica://FCSys/Resources/Source/C", Include = "#include \"Chemistry.c\"", Documentation(info = "<html><p>This function returns the net
        electrical charge associated with a species represented by a chemical
        formula (<code>formula</code>).  If the charge number is
        not given explicitly in the formula, then it is assumed to be zero.  A \"+\" or \"-\" without any immediately following digits is interpreted as
        a charge of +1 or -1, respectively.  If there is an error in the chemical formula,
        then 0 is returned.</p>

        <p><b>Example:</b><br>
        <code>charge(\"Hg2+2\")</code> returns 2.</p>
        </html>"));
        annotation(IncludeDirectory = "modelica://FCSys/Resources/Source/C", Include = "#include \"Chemistry.c\"", Documentation(info = "<html><p>This function returns the net
        electrical charge associated with a species represented by a chemical
        formula (<code>formula</code>).  If the charge number is
        not given explicitly in the formula, then it is assumed to be zero.  A \"+\" or \"-\" without any immediately following digits is interpreted as
        a charge of +1 or -1, respectively.  If there is an error in the chemical formula,
        then 0 is returned.</p>

        <p><b>Example:</b><br>
        <code>charge(\"Hg2+2\")</code> returns 2.</p>
        </html>"));
      end charge;
    end Chemistry;

    package Polynomial  "Polynomial functions"
      extends Modelica.Icons.Package;

      function F  "<html>&int;<a href=\"modelica://FCSys.Utilities.Polynomial.f\">f</a>()&middot;d<i>x</i> evaluated at <i>x</i> with zero integration constant</html>"
        extends Modelica.Icons.Function;
        input Real x "Argument" annotation(Dialog(__Dymola_label = "<html><i>x</i></html>"));
        input Real[:] a "Coefficients" annotation(Dialog(__Dymola_label = "<html><i>a</i></html>"));
        input Integer n = 0 "Power associated with the first term (before integral)" annotation(Dialog(__Dymola_label = "<html><i>n</i></html>"));
        output Real F "Integral" annotation(Dialog(__Dymola_label = "<html><i>F</i></html>"));
      algorithm
        F := f(x, a .* {if n + i == 0 then log(x) else 1 / (n + i) for i in 1:size(a, 1)}, n + 1);
        annotation(Inline = true, derivative = FCSys.Utilities.Polynomial.dF, Documentation(info = "<html>
        <p>By definition, the partial derivative of this function with respect to <i>x</i>
        (with <i>a</i> constant)
        is <a href=\"modelica://FCSys.Utilities.Polynomial.f\">f</a>().  The complete derivative,
        however, is <a href=\"modelica://FCSys.Utilities.Polynomial.dF\">dF</a>().</p></html>"));
      end F;

      function dF  "<html>Derivative of <a href=\"modelica://FCSys.Utilities.Polynomial.F\">F</a>()</html>"
        extends Modelica.Icons.Function;
        input Real x "Argument" annotation(Dialog(__Dymola_label = "<html><i>x</i></html>"));
        input Real[:] a "Coefficients" annotation(Dialog(__Dymola_label = "<html><i>a</i></html>"));
        input Integer n = 0 "Power associated with the first term (before integral)" annotation(Dialog(__Dymola_label = "<html><i>n</i></html>"));
        input Real dx "Derivative of argument" annotation(Dialog(__Dymola_label = "<html>d<i>x</i></html>"));
        input Real[size(a, 1)] da = zeros(size(a, 1)) "Derivatives of coefficients" annotation(Dialog(__Dymola_label = "<html>d<i>a</i></html>"));
        output Real dF "Derivative" annotation(Dialog(__Dymola_label = "<html>d<i>F</i></html>"));
      algorithm
        dF := f(x, a, n) * dx + f(x, da .* {if n + i == 0 then log(x) else 1 / (n + i) for i in 1:size(a, 1)}, n + 1);
        annotation(Inline = true);
      end dF;

      function f  "<html>Polynomial expressed in form: <i>f</i> = ((&hellip; + <i>a</i><sub>-1-<i>n</i></sub>)/<i>x</i> + <i>a</i><sub>-<i>n</i></sub>)/<i>x</i> + <i>a</i><sub>1-<i>n</i></sub> + <i>x</i>&middot;(<i>a</i><sub>2-<i>n</i></sub> + <i>x</i>&middot;(<i>a</i><sub>3-<i>n</i></sub> + &hellip;))</html>"
        extends Modelica.Icons.Function;
        input Real x "Argument" annotation(Dialog(__Dymola_label = "<html><i>x</i></html>"));
        input Real[:] a "Coefficients" annotation(Dialog(__Dymola_label = "<html><i>a</i></html>"));
        input Integer n = 0 "Power of the first term" annotation(Dialog(__Dymola_label = "<html><i>n</i></html>"));
        output Real f "Result" annotation(Dialog(__Dymola_label = "<html><i>f</i></html>"));

      protected
        function positivePoly  "<html>Polynomial expressed in form: y = x*(a + x*(a<sub>2</sub> + &hellip;))</html>"
          input Real x "Argument";
          input Real[:] a "Coefficients";
          output Real y "Result";
        algorithm
          y := if size(a, 1) > 0 then x * (a[1] + (if size(a, 1) > 1 then x * (a[2] + (if size(a, 1) > 2 then x * (a[3] + (if size(a, 1) > 3 then x * (a[4] + (if size(a, 1) > 4 then x * (a[5] + (if size(a, 1) > 5 then x * (a[6] + (if size(a, 1) > 6 then x * (a[7] + (if size(a, 1) > 7 then x * (a[8] + (if size(a, 1) > 8 then x * (a[9] + (if size(a, 1) > 9 then x * (a[10] + (if size(a, 1) > 10 then positivePoly(x, a[11:end]) else 0)) else 0)) else 0)) else 0)) else 0)) else 0)) else 0)) else 0)) else 0)) else 0)) else 0 annotation(Inline = true);
        end positivePoly;
      algorithm
        f := (if n < 0 then (if n + size(a, 1) < 0 then x ^ (n + size(a, 1)) else 1) * positivePoly(1 / x, a[min(size(a, 1), -n):(-1):1]) else 0) + (if n <= 0 and n > (-size(a, 1)) then a[1 - n] else 0) + (if n + size(a, 1) > 1 then (if n > 1 then x ^ (n - 1) else 1) * positivePoly(x, a[1 + max(0, 1 - n):size(a, 1)]) else 0);
        annotation(Inline = true, derivative = FCSys.Utilities.Polynomial.df, Documentation(info = "<html><p>For high-order polynomials, this
        is more computationally efficient than the form
        &Sigma;<i>a</i><sub><i>i</i></sub> <i>x</i><sup><i>n</i> + <i>i</i> - 1</sup>.</p>

        <p>Note that the order of the polynomial is
        <code>n + size(a, 1) - 1</code> (not <code>n</code>).</p>

        <p>The derivative of this function is
        <a href=\"modelica://FCSys.Utilities.Polynomial.df\">df</a>().</p></html>"));
      end f;

      function df  "<html>Derivative of <a href=\"modelica://FCSys.Utilities.Polynomial.f\">f</a>()</html>"
        extends Modelica.Icons.Function;
        input Real x "Argument" annotation(Dialog(__Dymola_label = "<html><i>x</i></html>"));
        input Real[:] a "Coefficients" annotation(Dialog(__Dymola_label = "<html><i>a</i></html>"));
        input Integer n = 0 "Power associated with the first term (before derivative)" annotation(Dialog(__Dymola_label = "<html><i>n</i></html>"));
        input Real dx "Derivative of argument" annotation(Dialog(__Dymola_label = "<html>d<i>x</i></html>"));
        input Real[size(a, 1)] da = zeros(size(a, 1)) "Derivatives of coefficients" annotation(Dialog(__Dymola_label = "<html>d<i>a</i></html>"));
        output Real df "Derivative" annotation(Dialog(__Dymola_label = "<html>d<i>f</i></html>"));
      algorithm
        df := f(x, a = {(n + i - 1) * a[i] for i in 1:size(a, 1)}, n = n - 1) * dx + f(x, da, n);
        annotation(Inline = true, derivative(order = 2) = FCSys.Utilities.Polynomial.d2f, Documentation(info = "<html>
      <p>The derivative of this function is
        <a href=\"modelica://FCSys.Utilities.Polynomial.d2f\">d2f</a>().</p></html>"));
      end df;

      function d2f  "<html>Derivative of <a href=\"modelica://FCSys.Utilities.Polynomial.df\">df</a>()</html>"
        extends Modelica.Icons.Function;
        input Real x "Argument" annotation(Dialog(__Dymola_label = "<html><i>x</i></html>"));
        input Real[:] a "Coefficients" annotation(Dialog(__Dymola_label = "<html><i>a</i></html>"));
        input Integer n = 0 "Power associated with the first term (before derivative)" annotation(Dialog(__Dymola_label = "<html><i>n</i></html>"));
        input Real dx "Derivative of argument" annotation(Dialog(__Dymola_label = "<html>d<i>x</i></html>"));
        input Real[size(a, 1)] da = zeros(size(a, 1)) "Derivatives of coefficients" annotation(Dialog(__Dymola_label = "<html>d<i>a</i></html>"));
        input Real d2x "Second derivative of argument" annotation(Dialog(__Dymola_label = "<html>d<sup>2</sup><i>x</i></html>"));
        input Real[size(a, 1)] d2a = zeros(size(a, 1)) "Second derivatives of coefficients" annotation(Dialog(__Dymola_label = "<html>d<sup>2</sup><i>a</i></html>"));
        output Real d2f "Second derivative" annotation(Dialog(__Dymola_label = "<html>d<sup>2</sup><i>f</i></html>"));
      algorithm
        d2f := sum(f(x, {a[i] * (n + i - 1) * (n + i - 2) * dx ^ 2, (n + i - 1) * (2 * da[i] * dx + a[i] * d2x), d2a[i]}, n + i - 3) for i in 1:size(a, 1));
        annotation(Inline = true);
      end d2f;
    end Polynomial;
    annotation(Documentation(info = "
  <html>
    <p><b>Licensed by the Hawaii Natural Energy Institute under the Modelica License 2</b><br>
  Copyright &copy; 2007&ndash;2014, <a href=\"http://www.hnei.hawaii.edu/\">Hawaii Natural Energy Institute</a> and <a href=\"http://www.gtrc.gatech.edu/\">Georgia Tech Research Corporation</a>.</p>

  <p><i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>;
  it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the
  disclaimer of warranty) see <a href=\"modelica://FCSys.UsersGuide.License\">
  FCSys.UsersGuide.License</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">
  http://www.modelica.org/licenses/ModelicaLicense2</a>.</i></p>
  </html>"));
  end Utilities;

  package Icons  "Icons to annotate and represent classes"
    extends Modelica.Icons.IconsPackage;

    package Names  "Icons labeled with the name of the class at various positions"
      extends Modelica.Icons.Package;

      partial class Top3   annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{-100, 60}, {100, 100}}, textString = "%name", lineColor = {0, 0, 0})})); end Top3;
    end Names;
    annotation(Documentation(info = "
  <html>
    <p><b>Licensed by the Hawaii Natural Energy Institute under the Modelica License 2</b><br>
  Copyright &copy; 2007&ndash;2014, <a href=\"http://www.hnei.hawaii.edu/\">Hawaii Natural Energy Institute</a> and <a href=\"http://www.gtrc.gatech.edu/\">Georgia Tech Research Corporation</a>.</p>

  <p><i>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>;
  it can be redistributed and/or modified under the terms of the Modelica License 2. For license conditions (including the
  disclaimer of warranty) see <a href=\"modelica://FCSys.UsersGuide.License\">
  FCSys.UsersGuide.License</a> or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">
  http://www.modelica.org/licenses/ModelicaLicense2</a>.</i></p>
  </html>"));
  end Icons;
  annotation(preferredView = "info", uses(Modelica(version = "3.2.1")), Commands(executeCall = FCSys.Units.setup()), Documentation(info = "<html>
    <p><a href=\"modelica://FCSys\">FCSys</a> is a free, open-source library of
    equation-based, object-oriented (EOO) models of proton exchange membrane
    fuel cells (PEMFCs) in the <a href = \"http://www.modelica.org/\">Modelica</a>
    language.  The models are:</p>

    <ul>
    <li><b>Dynamic</b></li>

    <li><b>Multi-domain</b>:
    Chemical, electrical, fluid, and thermal phenomena are included.</li>

    <li><b>Multi-phase</b>:
    Water is included and transported independently as vapor, liquid, and absorbed in the ionomer.
    Phase change is represented as a dynamic process.</li>

    <li><b>Multi-dimensional</b></li>

    <li><b>Highly reconfigurable</b>:
    There are options to adjust the assumptions, dimensionality (1D, 2D, or 3D), and spatial discretization
    (i.e., resolution).  Species may be independently enabled at instantiation, unlike
    the <a href=\"modelica://Modelica.Media\">Modelica media library</a>.  The framework is generic and can be extended
    to other fluidic or electrochemical devices like batteries.</li>

    <li><b>Highly modular and reusable</b>:
    Each layer of the cell is a separate model which is hierarchically constructed from graphical models of
    subregions, phases, and species.  At each level, EOO (i.e., effort/flow) connectors are used to combine
    the various components.</li>

    <li><b>Fully declarative</b>:
    There are no causal connectors besides those used to apply boundary conditions.  Functions are only
    used to simplify subexpressions of equations.</li>

    <li><b>Physics-based</b>:
    The equations are based on first principles, with explicit conservation of material, momentum, and energy
    in every control volume and across every interface.  A unique and physically appropriate method of
    upstream discretization is used to describe coupled advective and diffusive transfer.  All physical
    quantities are mapped to universal physical constants using a
    <a href=\"modelica://FCSys.Units\">novel, flexible implementation of natural units</a>.</li>

    <li><b>Computationally efficient</b>:
    There are minimal switching events and no nonlinear systems of equations after appropriate translation.
    A typical polarization curve can be simulated in less than two seconds.</li>

    </ul>

    <p><a href=\"#Fig1\">Figure 1</a> shows the seven primary layers of a typical PEMFC, which are also the components of the
    fuel cell model shown in <a href=\"#Fig2\">Figure 2</a>.
    Fluid enters and exits the cell through channels in the flow plates (FPs).  It spreads through
    the gas diffusion diffusion layers (GDLs) and reacts in the catalyst layers (CLs) according to the following electrochemical equations:</p>

          <table border=0 cellspacing=0 cellpadding=2 align=center style=\"margin-left: auto;
margin-right: auto;\" class=noBorder>
      <tr>
        <td align=right style=\"white-space:nowrap; text-align:right;\" class=noBorder>
          2(H<sub>2</sub>
        </td>
        <td align=center style=\"white-space:nowrap; text-align:center;\" class=noBorder>
          &rarr;
        </td>
        <td align=left style=\"white-space:nowrap;\" class=noBorder>
          2e<sup>-</sup> + 2H<sup>+</sup>)
        </td>
        <td class=noBorder>
          (anode)
        </td>
      </tr>
      <tr>
        <td align=right style=\"white-space:nowrap; text-align=right;\" class=noBorder>
          4e<sup>-</sup> + 4H<sup>+</sup> + O<sub>2</sub>
        </td>
        <td align=center style=\"white-space:nowrap; text-align:center;\" class=noBorder>
          &rarr;
        </td>
        <td align=left style=\"white-space:nowrap;\" class=noBorder>
          2H<sub>2</sub>O
        </td>
        <td class=noBorder>
          (cathode)
        </td>
      </tr>
      <tr>
        <td colspan=4 class=noBorder>
          <hr>
        </td>
      </tr>
      <tr>
        <td align=right style=\"white-space:nowrap; text-align=right;\" class=noBorder>
          2H<sub>2</sub> + O<sub>2</sub>
        </td>
        <td align=center style=\"white-space:nowrap; text-align:center;\" class=noBorder>
          &rarr;
        </td>
        <td align=left style=\"white-space:nowrap;\" class=noBorder>
          2H<sub>2</sub>O
        </td>
        <td class=noBorder>
          (net)
        </td>
      </tr>
    </table>
      <p>The
    proton exchange membrane (PEM) prevents electronic transport; therefore, electrons must
    pass through an external load to sustain the net reaction.</p>

    <p align=center id=\"Fig1\"><img src=\"modelica://FCSys/Resources/Documentation/CellFlows.png\">
<br>Figure 1: Layers and primary flows of a PEMFC.</p>

    <!--<p align=center id=\"Fig2\"><img src=\"modelica://FCSys/help/FCSys.Assemblies.Cells.CellD.png\" width=600>-->
    <p align=center id=\"Fig2\"><a href=\"modelica://FCSys.Assemblies.Cells.Cell\"><img src=\"modelica://FCSys/Resources/Documentation/FCSys.Assemblies.Cells.CellD.png\"></a>
<br>Figure 2: Diagram of the <a href=\"modelica://FCSys.Assemblies.Cells.Cell\">PEMFC model</a>.</p>

    <p>The fuel cell model can be exercised using the test stand shown in <a href=\"#Fig3\">Figure 3</a> or connected to the <a href=\"modelica://Modelica.Fluid\">Modelica fluid library</a>
    using <a href=\"modelica://FCSys.Conditions.Adapters.MSL\">available adapters</a>.
    Please see the <a href=\"modelica://FCSys.UsersGuide.SampleResults\">sample cell results</a> for examples and the
    <a href=\"modelica://FCSys.UsersGuide.GettingStarted\">getting started page</a> for information about using the library.</p>

    <!--<p align=center id=\"Fig3\"><img src=\"modelica://FCSys/help/FCSys.Assemblies.Cells.Examples.TestStandD.png\" width=500>-->
    <p align=center id=\"Fig3\"><a href=\"modelica://FCSys.Assemblies.Cells.Examples.TestStand\"><img src=\"modelica://FCSys/Resources/Documentation/FCSys.Assemblies.Cells.Examples.TestStandD.png\"></a>
<br>Figure 3: Diagram of the <a href=\"modelica://FCSys.Assemblies.Cells.Examples.TestStand\">test stand model</a>.</p>

    <p><b>Licensed by the Hawaii Natural Energy Institute under the Modelica License 2</b>
<br>Copyright &copy; 2007&ndash;2014, <a href=\"http://www.hnei.hawaii.edu/\">Hawaii Natural Energy Institute</a> and <a href=\"http://www.gtrc.gatech.edu/\">Georgia Tech Research Corporation</a>.</p>

    <p><i>This Modelica package is <u>free</u> software and the use is completely
    at <u>your own risk</u>; it can be redistributed and/or modified under the
    terms of the Modelica License 2. For license conditions (including the
    disclaimer of warranty) see
    <a href=\"modelica://FCSys.UsersGuide.License\">
    FCSys.UsersGuide.License</a>
    or visit <a href=\"http://www.modelica.org/licenses/ModelicaLicense2\">
    http://www.modelica.org/licenses/ModelicaLicense2</a>.</i></p></html>"), Icon(graphics = {Polygon(points = {{-4, 52}, {-14, 42}, {6, 42}, {16, 52}, {-4, 52}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-30, 52}, {-40, 42}, {-20, 42}, {-10, 52}, {-30, 52}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {0, 192, 0}), Polygon(points = {{-10, 52}, {-20, 42}, {-14, 42}, {-4, 52}, {-10, 52}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {0, 0, 0}), Rectangle(extent = {{6, 42}, {12, -52}}, fillPattern = FillPattern.Solid, fillColor = {0, 0, 0}, pattern = LinePattern.None), Polygon(points = {{16, 52}, {6, 42}, {12, 42}, {22, 52}, {16, 52}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {0, 0, 0}), Line(points = {{-40, 42}, {-40, -52}}, pattern = LinePattern.None, smooth = Smooth.None), Polygon(points = {{-46, 64}, {-66, 44}, {-46, 44}, {-26, 64}, {-46, 64}}, lineColor = {0, 0, 0}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-39.6277, 31.7996}, {-67.912, 17.6573}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, rotation = 45, fillColor = {255, 255, 255}, origin = {56.5067, 67.5353}), Rectangle(extent = {{-14, 42}, {6, -52}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.VerticalCylinder, fillColor = {255, 255, 255}), Line(points = {{-30, 52}, {32, 52}}, color = {0, 0, 0}), Rectangle(extent = {{-5.21738, -5.21961}, {-33.5017, -33.5041}}, lineColor = {0, 0, 170}, fillPattern = FillPattern.VerticalCylinder, rotation = 45, fillColor = {0, 0, 240}, origin = {31.9983, 69.3803}), Rectangle(extent = {{12, 42}, {52, -52}}, lineColor = {0, 0, 170}, fillPattern = FillPattern.VerticalCylinder, fillColor = {0, 0, 240}), Polygon(points = {{-26, 64}, {-46, 44}, {-46, -64}, {-26, -44}, {-26, 64}}, lineColor = {0, 0, 0}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-5.21774, -5.2196}, {-33.502, -33.5042}}, lineColor = {196, 11, 40}, fillPattern = FillPattern.HorizontalCylinder, rotation = 45, fillColor = {253, 52, 56}, origin = {-30.001, 79.3803}), Rectangle(extent = {{-60, 42}, {-20, -52}}, lineColor = {196, 11, 40}, fillPattern = FillPattern.VerticalCylinder, fillColor = {253, 52, 56}), Rectangle(extent = {{-60, 42}, {-40, -54}}, fillPattern = FillPattern.Solid, fillColor = {95, 95, 95}, pattern = LinePattern.None, lineColor = {0, 0, 0}), Rectangle(extent = {{-76.648, 66.211}, {-119.073, 52.0689}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.HorizontalCylinder, rotation = 45, fillColor = {135, 135, 135}, origin = {65.0166, 81.3801}), Rectangle(extent = {{-66, 44}, {-46, -64}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.VerticalCylinder, fillColor = {135, 135, 135}), Polygon(points = {{46, 64}, {34, 52}, {-26, 52}, {-26, 64}, {46, 64}}, smooth = Smooth.None, fillPattern = FillPattern.Solid, fillColor = {230, 230, 230}, pattern = LinePattern.None, lineColor = {0, 0, 0}), Rectangle(extent = {{-76.648, 66.211}, {-119.073, 52.0689}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.HorizontalCylinder, rotation = 45, fillColor = {135, 135, 135}, origin = {157.017, 81.3801}), Rectangle(extent = {{26, 44}, {46, -64}}, lineColor = {95, 95, 95}, fillPattern = FillPattern.VerticalCylinder, fillColor = {135, 135, 135}), Polygon(points = {{-26, 64}, {-26, 52}, {-30, 52}, {-30, 60}, {-26, 64}}, smooth = Smooth.None, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid, pattern = LinePattern.None, lineColor = {0, 0, 0}), Ellipse(extent = {{-44, 62}, {-36, 58}}, lineColor = {135, 135, 135}, fillColor = {253, 52, 56}, fillPattern = FillPattern.Sphere), Ellipse(extent = {{36, 50}, {44, 46}}, lineColor = {135, 135, 135}, fillColor = {0, 0, 240}, fillPattern = FillPattern.Sphere), Polygon(points = {{-26, 64}, {-26, 52}, {-30, 52}, {-40, 42}, {-46, 44}, {-26, 64}}, smooth = Smooth.None, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid, pattern = LinePattern.None, lineColor = {0, 0, 0}), Line(points = {{-30, 52}, {-40, 42}}, color = {0, 0, 0}, smooth = Smooth.None), Polygon(points = {{66, 64}, {46, 44}, {46, -64}, {66, -44}, {66, 64}}, lineColor = {0, 0, 0}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Rectangle(extent = {{26, 44}, {46, -64}}, lineColor = {0, 0, 0}), Rectangle(extent = {{-66, 44}, {-46, -64}}, lineColor = {0, 0, 0}), Line(points = {{-26, 64}, {-26, 52}}, color = {0, 0, 0}, smooth = Smooth.None), Line(points = {{-30, 52}, {34, 52}}, color = {0, 0, 0}), Rectangle(extent = {{-46, 74}, {66, 64}}, pattern = LinePattern.None, fillColor = {230, 230, 230}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 0}), Polygon(points = {{-46, 64}, {-26, 64}, {-46, 44}, {-66, 44}, {-46, 64}}, lineColor = {0, 0, 0}, smooth = Smooth.None), Polygon(points = {{46, 64}, {66, 64}, {46, 44}, {26, 44}, {46, 64}}, lineColor = {0, 0, 0}, smooth = Smooth.None), Rectangle(extent = {{-40, 42}, {26, -52}}, lineColor = {0, 0, 0}), Rectangle(extent = {{-20, 42}, {-14, -52}}, fillPattern = FillPattern.Solid, fillColor = {0, 0, 0}, pattern = LinePattern.None)}), version = "0.2.6", dateModified = "2014-01-25 16:41:20Z", revisionID = "SHA: 80c2494");
end FCSys;

model CellPotential_total  "<html>Evaluate the potential of an H<sub>2</sub>/O<sub>2</sub> cell as a function of temperature</html>"
  extends FCSys.Characteristics.Examples.CellPotential;
 annotation(experiment(StopTime = 10), Commands(file = "Resources/Scripts/Dymola/Characteristics.Examples.CellPotential.mos"));
end CellPotential_total;
