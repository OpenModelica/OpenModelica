package Modelica "Modelica Standard Library - Version 3.2.1 (Build 2)"
  extends Modelica.Icons.Package;

  package Blocks "Library of basic input/output control blocks (continuous, discrete, logical, table blocks)"
    import SI = Modelica.SIunits;
    extends Modelica.Icons.Package;

    package Interfaces "Library of connectors and partial models for input/output blocks"
      import Modelica.SIunits;
      extends Modelica.Icons.InterfacesPackage;
      connector RealInput = input Real "'input Real' as connector" annotation(defaultComponentName = "u", Icon(graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid, points = {{-100.0, 100.0}, {100.0, 0.0}, {-100.0, -100.0}})}, coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}, preserveAspectRatio = true, initialScale = 0.2)), Diagram(coordinateSystem(preserveAspectRatio = true, initialScale = 0.2, extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid, points = {{0.0, 50.0}, {100.0, 0.0}, {0.0, -50.0}, {0.0, 50.0}}), Text(lineColor = {0, 0, 127}, extent = {{-10.0, 60.0}, {-10.0, 85.0}}, textString = "%name")}), Documentation(info = "<html>

         <p>

         Connector with one input signal of type Real.

         </p>

         </html>"));
      connector RealOutput = output Real "'output Real' as connector" annotation(defaultComponentName = "y", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 100.0}, {100.0, 0.0}, {-100.0, -100.0}})}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100.0, -100.0}, {100.0, 100.0}}, initialScale = 0.1), graphics = {Polygon(lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-100.0, 50.0}, {0.0, 0.0}, {-100.0, -50.0}}), Text(lineColor = {0, 0, 127}, extent = {{30.0, 60.0}, {30.0, 110.0}}, textString = "%name")}), Documentation(info = "<html>

         <p>

         Connector with one output signal of type Real.

         </p>

         </html>"));

      partial block SO "Single Output continuous control block"
        extends Modelica.Blocks.Icons.Block;
        RealOutput y "Connector of Real output signal" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}}, rotation = 0)));
        annotation(Documentation(info = "<html>

 <p>

 Block has one continuous Real output signal.

 </p>

 </html>"));
      end SO;

      package Adaptors "Obsolete package with components to send signals to a bus or receive signals from a bus (only for backward compatibility)"
        extends Modelica.Icons.Package;
        // extends Modelica.Icons.ObsoleteModel;

        block SendReal "Obsolete block to send Real signal to bus"
          // extends Modelica.Icons.ObsoleteModel;
          RealOutput toBus "Output signal to be connected to bus" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}}, rotation = 0)));
          RealInput u "Input signal to be send to bus" annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}}, rotation = 0)));
        equation
          toBus = u;
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 40}, {100, -40}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-144, 96}, {144, 46}}, lineColor = {0, 0, 0}, textString = "%name"), Text(extent = {{-100, 30}, {100, -30}}, lineColor = {0, 0, 127}, textString = "send")}), Documentation(info = "<html>

 <p>

 Obsolete block that was previously used to connect a Real signal

 to a signal in a connector. This block is only provided for

 backward compatibility.

 </p>



 <p>

 It is much more convenient and more powerful to use \"expandable connectors\"

 for signal buses, see example

 <a href=\"modelica://Modelica.Blocks.Examples.BusUsage\">BusUsage</a>.

 </p>

 </html>"));
        end SendReal;

        block ReceiveReal "Obsolete block to receive Real signal from bus"
          // extends Modelica.Icons.ObsoleteModel;
          RealInput fromBus "To be connected with signal on bus" annotation(Placement(transformation(extent = {{-120, -10}, {-100, 10}}, rotation = 0)));
          RealOutput y "Output signal to be received from bus" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}}, rotation = 0)));
        equation
          y = fromBus;
          annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 40}, {100, -40}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-100, 30}, {100, -30}}, lineColor = {0, 0, 127}, textString = "receive"), Text(extent = {{-144, 96}, {144, 46}}, lineColor = {0, 0, 0}, textString = "%name")}), Documentation(info = "<html>

 <p>

 Obsolete block that was previously used to connect a Real signal

 in a connector to an input of a block. This block is only provided for

 backward compatibility.

 </p>



 <p>

 It is much more convenient and more powerful to use \"expandable connectors\"

 for signal buses, see example

 <a href=\"modelica://Modelica.Blocks.Examples.BusUsage\">BusUsage</a>.

 </p>

 </html>"));
        end ReceiveReal;
        annotation(Documentation(info = "<html>

 <p>

 The components of this package should no longer be used.

 They are only provided for backward compatibility.

 It is much more convenient and more powerful to use \"expandable connectors\"

 for signal buses, see example

 <a href=\"modelica://Modelica.Blocks.Examples.BusUsage\">BusUsage</a>.

 </p>

 </html>"));
      end Adaptors;
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

    package Sources "Library of signal source blocks generating Real and Boolean signals"
      import Modelica.Blocks.Interfaces;
      import Modelica.SIunits;
      extends Modelica.Icons.SourcesPackage;

      block Constant "Generate constant signal of type Real"
        parameter Real k(start = 1) "Constant output value";
        extends Interfaces.SO;
      equation
        y = k;
        annotation(defaultComponentName = "const", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 68}, {-80, -80}}, color = {192, 192, 192}), Polygon(points = {{-80, 90}, {-88, 68}, {-72, 68}, {-80, 90}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-90, -70}, {82, -70}}, color = {192, 192, 192}), Polygon(points = {{90, -70}, {68, -62}, {68, -78}, {90, -70}}, lineColor = {192, 192, 192}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid), Line(points = {{-80, 0}, {80, 0}}, color = {0, 0, 0}), Text(extent = {{-150, -150}, {150, -110}}, lineColor = {0, 0, 0}, textString = "k=%k")}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{-80, 90}, {-86, 68}, {-74, 68}, {-80, 90}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Line(points = {{-80, 68}, {-80, -80}}, color = {95, 95, 95}), Line(points = {{-80, 0}, {80, 0}}, color = {0, 0, 255}, thickness = 0.5), Line(points = {{-90, -70}, {82, -70}}, color = {95, 95, 95}), Polygon(points = {{90, -70}, {68, -64}, {68, -76}, {90, -70}}, lineColor = {95, 95, 95}, fillColor = {95, 95, 95}, fillPattern = FillPattern.Solid), Text(extent = {{-83, 92}, {-30, 74}}, lineColor = {0, 0, 0}, textString = "y"), Text(extent = {{70, -80}, {94, -100}}, lineColor = {0, 0, 0}, textString = "time"), Text(extent = {{-101, 8}, {-81, -12}}, lineColor = {0, 0, 0}, textString = "k")}), Documentation(info = "<html>

 <p>

 The Real output y is a constant signal:

 </p>



 <p>

 <img src=\"modelica://Modelica/Resources/Images/Blocks/Sources/Constant.png\"

      alt=\"Constant.png\">

 </p>

 </html>"));
      end Constant;
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

    package Icons "Icons for Blocks"
      extends Modelica.Icons.IconsPackage;

      partial block Block "Basic graphical layout of input/output block"
        annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, -100}, {100, 100}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255})}), Documentation(info = "<html>

 <p>

 Block that has only the basic icon for an input/output

 block (no declarations, no equations). Most blocks

 of package Modelica.Blocks inherit directly or indirectly

 from this block.

 </p>

 </html>"));
      end Block;
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

 Copyright &copy; 1998-2013, Modelica Association and DLR.

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

  package Icons "Library of icons"
    extends Icons.Package;

    partial model Example "Icon for runnable examples"
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(lineColor = {75, 138, 73}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, extent = {{-100, -100}, {100, 100}}), Polygon(lineColor = {0, 0, 255}, fillColor = {75, 138, 73}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-36, 60}, {64, 0}, {-36, -60}, {-36, 60}})}), Documentation(info = "<html>

 <p>This icon indicates an example. The play button suggests that the example can be executed.</p>

 </html>"));
    end Example;

    partial package Package "Icon for standard packages"
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(lineColor = {200, 200, 200}, fillColor = {248, 248, 248}, fillPattern = FillPattern.HorizontalCylinder, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0), Rectangle(lineColor = {128, 128, 128}, fillPattern = FillPattern.None, extent = {{-100.0, -100.0}, {100.0, 100.0}}, radius = 25.0)}), Documentation(info = "<html>

 <p>Standard package icon.</p>

 </html>"));
    end Package;

    partial package InterfacesPackage "Icon for packages containing interfaces"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {20.0, 0.0}, lineColor = {64, 64, 64}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-10.0, 70.0}, {10.0, 70.0}, {40.0, 20.0}, {80.0, 20.0}, {80.0, -20.0}, {40.0, -20.0}, {10.0, -70.0}, {-10.0, -70.0}}), Polygon(fillColor = {102, 102, 102}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-100.0, 20.0}, {-60.0, 20.0}, {-30.0, 70.0}, {-10.0, 70.0}, {-10.0, -70.0}, {-30.0, -70.0}, {-60.0, -20.0}, {-100.0, -20.0}})}), Documentation(info = "<html>

 <p>This icon indicates packages containing interfaces.</p>

 </html>"));
    end InterfacesPackage;

    partial package SourcesPackage "Icon for packages containing sources"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {23.3333, 0.0}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-23.333, 30.0}, {46.667, 0.0}, {-23.333, -30.0}}), Rectangle(fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-70, -4.5}, {0, 4.5}})}), Documentation(info = "<html>

 <p>This icon indicates a package which contains sources.</p>

 </html>"));
    end SourcesPackage;

    partial package IconsPackage "Icon for packages containing icons"
      extends Modelica.Icons.Package;
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {-8.167, -17}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.833, 20.0}, {-15.833, 30.0}, {14.167, 40.0}, {24.167, 20.0}, {4.167, -30.0}, {14.167, -30.0}, {24.167, -30.0}, {24.167, -40.0}, {-5.833, -50.0}, {-15.833, -30.0}, {4.167, 20.0}, {-5.833, 20.0}}, smooth = Smooth.Bezier, lineColor = {0, 0, 0}), Ellipse(origin = {-0.5, 56.5}, fillColor = {128, 128, 128}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-12.5, -12.5}, {12.5, 12.5}}, lineColor = {0, 0, 0})}));
    end IconsPackage;

    expandable connector SignalBus "Icon for signal bus"
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Rectangle(lineColor = {255, 204, 51}, lineThickness = 0.5, extent = {{-20.0, -2.0}, {20.0, 2.0}}), Polygon(fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, points = {{-80.0, 50.0}, {80.0, 50.0}, {100.0, 30.0}, {80.0, -40.0}, {60.0, -50.0}, {-60.0, -50.0}, {-80.0, -40.0}, {-100.0, 30.0}}, smooth = Smooth.Bezier), Ellipse(fillPattern = FillPattern.Solid, extent = {{-65.0, 15.0}, {-55.0, 25.0}}), Ellipse(fillPattern = FillPattern.Solid, extent = {{-5.0, 15.0}, {5.0, 25.0}}), Ellipse(fillPattern = FillPattern.Solid, extent = {{55.0, 15.0}, {65.0, 25.0}}), Ellipse(fillPattern = FillPattern.Solid, extent = {{-35.0, -25.0}, {-25.0, -15.0}}), Ellipse(fillPattern = FillPattern.Solid, extent = {{25.0, -25.0}, {35.0, -15.0}})}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, initialScale = 0.2), graphics = {Polygon(points = {{-40, 25}, {40, 25}, {50, 15}, {40, -20}, {30, -25}, {-30, -25}, {-40, -20}, {-50, 15}}, lineColor = {0, 0, 0}, fillColor = {255, 204, 51}, fillPattern = FillPattern.Solid, smooth = Smooth.Bezier), Ellipse(extent = {{-32.5, 7.5}, {-27.5, 12.5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-2.5, 12.5}, {2.5, 7.5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Ellipse(extent = {{27.5, 12.5}, {32.5, 7.5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-17.5, -7.5}, {-12.5, -12.5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Ellipse(extent = {{12.5, -7.5}, {17.5, -12.5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 70}, {150, 40}}, lineColor = {0, 0, 0}, textString = "%name")}), Documentation(info = "<html>

 This icon is designed for a <b>signal bus</b> connector.

 </html>"));
    end SignalBus;

    expandable connector SignalSubBus "Icon for signal sub-bus"
      annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, initialScale = 0.1), graphics = {Line(points = {{-16.0, 2.0}, {16.0, 2.0}}, color = {255, 204, 51}, thickness = 0.5), Rectangle(lineColor = {255, 204, 51}, lineThickness = 0.5, extent = {{-10.0, 0.0}, {8.0, 8.0}}), Polygon(fillColor = {255, 215, 136}, fillPattern = FillPattern.Solid, points = {{-80.0, 50.0}, {80.0, 50.0}, {100.0, 30.0}, {80.0, -40.0}, {60.0, -50.0}, {-60.0, -50.0}, {-80.0, -40.0}, {-100.0, 30.0}}, smooth = Smooth.Bezier), Ellipse(fillPattern = FillPattern.Solid, extent = {{-55.0, 15.0}, {-45.0, 25.0}}), Ellipse(fillPattern = FillPattern.Solid, extent = {{45.0, 15.0}, {55.0, 25.0}}), Ellipse(fillPattern = FillPattern.Solid, extent = {{-5.0, -25.0}, {5.0, -15.0}}), Rectangle(lineColor = {255, 215, 136}, lineThickness = 0.5, extent = {{-20.0, 0.0}, {20.0, 4.0}})}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}, initialScale = 0.1), graphics = {Polygon(points = {{-40, 25}, {40, 25}, {50, 15}, {40, -20}, {30, -25}, {-30, -25}, {-40, -20}, {-50, 15}}, lineColor = {0, 0, 0}, fillColor = {255, 204, 51}, fillPattern = FillPattern.Solid, smooth = Smooth.Bezier), Ellipse(extent = {{-22.5, 7.5}, {-17.5, 12.5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Ellipse(extent = {{17.5, 12.5}, {22.5, 7.5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-2.5, -7.5}, {2.5, -12.5}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 70}, {150, 40}}, lineColor = {0, 0, 0}, textString = "%name")}), Documentation(info = "<html>

 <p>

 This icon is designed for a <b>sub-bus</b> in a signal connector.

 </p>

 </html>"));
    end SignalSubBus;
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

     <dd><a href=\"http://www.ait.ac.at/\">Austrian Institute of Technology, AIT</a></dd>

     <dd>Mobility Department</dd><dd>Giefinggasse 2</dd>

     <dd>1210 Vienna, Austria</dd>

     <dd>email: <a href=\"mailto:dr.christian.kral@gmail.com\">dr.christian.kral@gmail.com</a></dd>

 <dt>Johan Andreasson</dt>

     <dd><a href=\"http://www.modelon.se/\">Modelon AB</a></dd>

     <dd>Ideon Science Park</dd>

     <dd>22370 Lund, Sweden</dd>

     <dd>email: <a href=\"mailto:johan.andreasson@modelon.se\">johan.andreasson@modelon.se</a></dd>

 </dl>



 <p>Copyright &copy; 1998-2013, Modelica Association, DLR, AIT, and Modelon AB. </p>

 <p><i>This Modelica package is <b>free</b> software; it can be redistributed and/or modified under the terms of the <b>Modelica license</b>, see the license conditions and the accompanying <b>disclaimer</b> in <a href=\"modelica://Modelica.UsersGuide.ModelicaLicense2\">Modelica.UsersGuide.ModelicaLicense2</a>.</i> </p>

 </html>"));
  end Icons;

  package SIunits "Library of type and unit definitions based on SI units according to ISO 31-1992"
    extends Modelica.Icons.Package;
    // Space and Time (chapter 1 of ISO 31-1992)
    // Periodic and related phenomens (chapter 2 of ISO 31-1992)
    // For compatibility reasons only
    // added to ISO-chapter
    // Mechanics (chapter 3 of ISO 31-1992)
    // added to ISO-chapter 3
    // Heat (chapter 4 of ISO 31-1992)
    // added to ISO-chapter 4
    // Electricity and Magnetism (chapter 5 of ISO 31-1992)
    // added to ISO-chapter 5
    // Light and Related Electromagnetic Radiations (chapter 6 of ISO 31-1992)"
    // Acoustics (chapter 7 of ISO 31-1992)
    // Physical chemistry and molecular physics (chapter 8 of ISO 31-1992)
    // Atomic and Nuclear Physics (chapter 9 of ISO 31-1992)
    // Nuclear Reactions and Ionizing Radiations (chapter 10 of ISO 31-1992)
    // chapter 11 is not defined in ISO 31-1992
    // Characteristic Numbers (chapter 12 of ISO 31-1992)
    // The Biot number (Bi) is used when
    // the Nusselt number is reserved
    // for convective transport of heat.
    // Solid State Physics (chapter 13 of ISO 31-1992)
    // Other types not defined in ISO 31-1992
    // Complex types for electrical systems (not defined in ISO 31-1992)
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

 Copyright &copy; 1998-2013, Modelica Association and DLR.

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
  annotation(__Wolfram(totalModelPart = true, totalModelId = "{cbefb7cf-3381-4147-b9f1-e599d11e1678}"), preferredView = "info", version = "3.2.1", versionBuild = 2, versionDate = "2013-08-14", dateModified = "2013-08-14 08:44:41Z", revisionId = "$Id:: package.mo 6931 2013-08-14 11:38:51Z #$", uses(Complex(version = "3.2.1"), ModelicaServices(version = "3.2.1")), conversion(noneFromVersion = "3.2", noneFromVersion = "3.1", noneFromVersion = "3.0.1", noneFromVersion = "3.0", from(version = "2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.1", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos"), from(version = "2.2.2", script = "modelica://Modelica/Resources/Scripts/Dymola/ConvertModelica_from_2.2.2_to_3.0.mos")), Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {-6.9888, 20.048}, fillColor = {0, 0, 0}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-93.0112, 10.3188}, {-93.0112, 10.3188}, {-73.011, 24.6}, {-63.011, 31.221}, {-51.219, 36.777}, {-39.842, 38.629}, {-31.376, 36.248}, {-25.819, 29.369}, {-24.232, 22.49}, {-23.703, 17.463}, {-15.501, 25.135}, {-6.24, 32.015}, {3.02, 36.777}, {15.191, 39.423}, {27.097, 37.306}, {32.653, 29.633}, {35.035, 20.108}, {43.501, 28.046}, {54.085, 35.19}, {65.991, 39.952}, {77.89700000000001, 39.688}, {87.422, 33.338}, {91.12600000000001, 21.696}, {90.068, 9.525}, {86.099, -1.058}, {79.749, -10.054}, {71.283, -21.431}, {62.816, -33.337}, {60.964, -32.808}, {70.489, -16.14}, {77.368, -2.381}, {81.072, 10.054}, {79.749, 19.05}, {72.605, 24.342}, {61.758, 23.019}, {49.587, 14.817}, {39.003, 4.763}, {29.214, -6.085}, {21.012, -16.669}, {13.339, -26.458}, {5.401, -36.777}, {-1.213, -46.037}, {-6.24, -53.446}, {-8.092000000000001, -52.387}, {-0.6840000000000001, -40.746}, {5.401, -30.692}, {12.81, -17.198}, {19.424, -3.969}, {23.658, 7.938}, {22.335, 18.785}, {16.514, 23.283}, {8.047000000000001, 23.019}, {-1.478, 19.05}, {-11.267, 11.113}, {-19.734, 2.381}, {-29.259, -8.202}, {-38.519, -19.579}, {-48.044, -31.221}, {-56.511, -43.392}, {-64.449, -55.298}, {-72.386, -66.93899999999999}, {-77.678, -74.612}, {-79.53, -74.083}, {-71.857, -61.383}, {-62.861, -46.037}, {-52.278, -28.046}, {-44.869, -15.346}, {-38.784, -2.117}, {-35.344, 8.731}, {-36.403, 19.844}, {-42.488, 23.813}, {-52.013, 22.49}, {-60.744, 16.933}, {-68.947, 10.054}, {-76.884, 2.646}, {-93.0112, -12.1707}, {-93.0112, -12.1707}}, smooth = Smooth.Bezier), Ellipse(origin = {40.8208, -37.7602}, fillColor = {161, 0, 4}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, extent = {{-17.8562, -17.8563}, {17.8563, 17.8562}})}), Documentation(info = "<HTML>

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

 Copyright &copy; 1998-2013, ABB, AIT, T.&nbsp;B&ouml;drich, DLR, Dassault Syst&egrave;mes AB, Fraunhofer, A.Haumer, ITI, Modelon,

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

package TestPackage
  model TestModel
    extends Modelica.Icons.Example;
    TestPackage.OutputFromBus OutputFromBus annotation(Placement(transformation(extent = {{-20, 70}, {0, 90}}, rotation = 0, origin = {30, -70}), visible = true));
    TestPackage.InputToBus inputToBus annotation(Placement(visible = true, transformation(origin = {-50, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  protected
  equation
    connect(OutputFromBus.controlBus, inputToBus.controlBus) annotation(Line(visible = true, origin = {-15, -1.513}, points = {{35, 1.513}, {35, -1.513}, {-35, -1.513}, {-35, 1.512}}, color = {85, 85, 255}));
    annotation(Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {10, 10})), experiment(StopTime = 200, NumberOfIntervals = 2000), experimentSetupOutput);
  end TestModel;

  expandable connector MyBus
    extends Modelica.Icons.SignalBus;
    annotation(Diagram(coordinateSystem(extent = {{-148.5, -105}, {148.5, 105}}, preserveAspectRatio = true, initialScale = 0.1, grid = {5, 5})));
  end MyBus;

  model InputToBus
    MyBus controlBus annotation(Placement(transformation(extent = {{-20, -80}, {20, -120}}, rotation = 0)));
    RealToBus velocityIn annotation(Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Sources.Constant const(k = 30) annotation(Placement(visible = true, transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  protected
    MySubBus chassisBus annotation(Placement(visible = true, transformation(origin = {0, 0}, extent = {{-40, -100}, {-20, -80}}, rotation = 0)));
  equation
    connect(velocityIn.subBus, chassisBus) annotation(Line(visible = true, origin = {-23, -61}, points = {{7, 61}, {7, -16}, {-7, -16}, {-7, -29}}, color = {85, 85, 255}));
    connect(chassisBus, controlBus.chassis) annotation(Line(visible = true, origin = {-20, -96.667}, points = {{-10, 6.667}, {-10, -3.333}, {20, -3.333}}, color = {85, 85, 255}));
    connect(const.y, velocityIn.u) annotation(Line(visible = true, origin = {-36.5, 0}, points = {{-12.5, -0}, {12.5, 0}}, color = {0, 0, 127}));
    annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {10, 10}), graphics = {Rectangle(visible = true, fillColor = {255, 255, 255}, lineThickness = 0.5, extent = {{-100, -100}, {100, 100}}), Text(visible = true, extent = {{-100, -100}, {100, 100}}, textString = "Input")}));
  end InputToBus;

  model OutputFromBus
    MyBus controlBus annotation(Placement(transformation(extent = {{-20, -80}, {20, -120}}, rotation = 0)));
    RealFromBus vehicleVelocity annotation(Placement(transformation(extent = {{-90, 50}, {-70, 70}}, rotation = 0)));
  protected
    MySubBus chassisBus annotation(Placement(visible = true, transformation(origin = {0, 0}, extent = {{-40, -100}, {-20, -80}}, rotation = 0)));
  equation
    connect(chassisBus, controlBus.chassis) annotation(Line(visible = true, points = {{-30, -90}, {-30, -100}, {0, -100}}, color = {255, 204, 51}, thickness = 0.5));
    connect(vehicleVelocity.subBus, chassisBus) annotation(Line(visible = true, points = {{-84, 60}, {-100, 60}, {-100, -100}, {-30, -100}, {-30, -90}}, color = {255, 204, 51}, thickness = 0.5));
    annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {10, 10}), graphics = {Rectangle(visible = true, fillColor = {255, 255, 255}, lineThickness = 0.5, extent = {{-100, -100}, {100, 100}}), Text(visible = true, origin = {-0.349, -0}, extent = {{-100.349, -100}, {100.349, 100}}, textString = "Output")}), Diagram(graphics));
  end OutputFromBus;

  expandable connector MySubBus
    extends Modelica.Icons.SignalSubBus;
    annotation(Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {10, 10})));
  end MySubBus;

  model RealToBus
    Modelica.Blocks.Interfaces.RealInput u annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {-40, 0}), iconTransformation(extent = {{-50, -10}, {-30, 10}})));
    MySubBus subBus annotation(Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = 270, origin = {40, 0}), iconTransformation(extent = {{-20, -20}, {20, 20}}, rotation = 270, origin = {40, 0})));
    Modelica.Blocks.Interfaces.Adaptors.SendReal velocity(toBus(unit = "m/s")) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}})));
  equation
    connect(u, velocity.u) annotation(Line(points = {{-40, 0}, {-12, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(velocity.toBus, subBus.velocity) annotation(Line(points = {{11, 0}, {40, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
    annotation(Diagram(graphics), Icon(graphics = {Text(visible = true, textColor = {0, 0, 127}, extent = {{-0, 60}, {0, 100}}, textString = "%name"), Polygon(visible = true, origin = {-0.459, 0}, lineColor = {0, 0, 128}, fillColor = {255, 255, 255}, lineThickness = 2, points = {{-29.541, 50}, {-29.541, -50}, {30.459, 0}})}, coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {10, 10})));
  end RealToBus;

  model RealFromBus
    Modelica.Blocks.Interfaces.RealOutput y annotation(Placement(transformation(extent = {{30, -10}, {50, 10}}, rotation = 0), iconTransformation(extent = {{30, -10}, {50, 10}})));
    MySubBus subBus annotation(Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = 90, origin = {-40, 0}), iconTransformation(extent = {{-20, -20}, {20, 20}}, rotation = 90, origin = {-40, 0})));
    Modelica.Blocks.Interfaces.Adaptors.ReceiveReal velocity(y(unit = "m/s")) annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}})));
  equation
    connect(velocity.y, y) annotation(Line(points = {{11, 0}, {40, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
    connect(velocity.fromBus, subBus.velocity) annotation(Line(points = {{-11, 0}, {-40, 0}}, color = {0, 0, 127}, smooth = Smooth.None));
    annotation(Diagram(graphics), Icon(graphics = {Text(visible = true, textColor = {0, 0, 127}, extent = {{-0, 60}, {0, 100}}, textString = "%name"), Polygon(visible = true, origin = {-10, 0}, lineColor = {0, 0, 128}, fillColor = {0, 0, 128}, fillPattern = FillPattern.Solid, points = {{-20, 50}, {-20, -50}, {40, 0}})}, coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {10, 10})));
  end RealFromBus;
  annotation(__Wolfram(totalModelPart = true, totalModelId = "{cbefb7cf-3381-4147-b9f1-e599d11e1678}"), Diagram(coordinateSystem(extent = {{-148.5, -105}, {148.5, 105}}, preserveAspectRatio = true, initialScale = 0.1, grid = {5, 5})));
end TestPackage;

model TestPackage_TestModel
  extends TestPackage.TestModel;
  annotation(__Wolfram(totalModelMain = true, totalModelId = "{cbefb7cf-3381-4147-b9f1-e599d11e1678}"));
end TestPackage_TestModel;