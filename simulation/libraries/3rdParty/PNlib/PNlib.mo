within ;
package PNlib
  model Contact
    //extends Modelica.Icons.Contact;
    annotation(Documentation(info = "<html>
       <p>This package is developed and maintained by the following contributors:</p>
       <table border=1 cellspacing=0 cellpadding=2>
         <tr>
           <th></th>
           <th>Name</th>
           <th>Affiliation</th>
         </tr>
         <tr>
           <td valign=top>Library officer</td>
           <td valign=top>
           <a>Lennart Ochel</a><br>
           <a href=\"mailto:lennart.ochel@fh-bielefeld.de\">lennart.ochel@fh-bielefeld.de</a>
           <td valign=top>University of Applied Sciences Bielefeld<br>
             Department of engineering and mathematics<br>
             33609 Bielefeld<br>
             Germany<br>
             <a href=\"http://www.fh-bielefeld.de/ammo\">http://www.fh-bielefeld.de/ammo<a>
           </td>
         </tr>
         <tr>
           <td valign=top>Library officer</td>
           <td valign=top>
           <a>S. Proß</a><br>
           <a href=\"mailto:sabrina.pross@fh-bielefeld.de\">sabrina.pross@fh-bielefeld.de</a><br>
           <td valign=top>University of Applied Sciences Bielefeld<br>
             <a>Department of engineering and mathematics</a><br>
             33609 Bielefeld<br>
             Germany<br>
             <a href=\"http://www.fh-bielefeld.de/ammo\">http://www.fh-bielefeld.de/ammo<a>
           </td>
         </tr>
         <tr>
           <td valign=top>Contributor</td>
           <td valign=top>
           <a>B. Bachmann</a><br>
           <a href=\"mailto:bernhard.bachmann@fh-bielefeld.de\">bernhard.bachmann@fh-bielefeld.de</a><br>
           <td valign=top>University of Applied Sciences Bielefeld<br>
             <a>Department of engineering and mathematics</a><br>
             33609 Bielefeld<br>
             Germany<br>
             <a href=\"http://www.fh-bielefeld.de/ammo\">http://www.fh-bielefeld.de/ammo<a>
           </td>
         </tr>
       </table>
     </html>"));
  end Contact;

  model RevisionHistory
    //extends Modelica.Icons.ReleaseNotes;
    annotation(Documentation(revisions = "<html>
      <table border=\"1\" cellspacing=\"0\" cellpadding=\"2\">
        <tr>
          <th>Version</th>
          <th>Revision</th>
          <th>Date</th>
          <th>Author</th>
          <th>Comment</th>
        </tr>
        <tr>
          <td valign=\"top\">1.0.0</td>
          <td valign=\"top\">1</td>
          <td valign=\"top\">2012-05-15</td>
          <td valign=\"top\">S. Proß</td>
          <td valign=\"top\">Dymola specific version <br>- source: https://www.modelica.org/events/modelica2012/proceedings/Modelica2012-USB-Stick.zip</td>
        </tr>
        <tr>
          <td valign=\"top\">1.1.0</td>
          <td valign=\"top\">195</td>
          <td valign=\"top\">2014-01-06</td>
          <td valign=\"top\">Lennart Ochel</td>
          <td valign=\"top\">Shrunk version with only continuous Petri net support (only continuous places and transitions) <br>- no longer Dymola specific</td>
        </tr>
        <tr>
          <td valign=\"top\">1.1.0</td>
          <td valign=\"top\">217</td>
          <td valign=\"top\">2014-01-14</td>
          <td valign=\"top\">Lennart Ochel</td>
          <td valign=\"top\">- add inhibitor arc</td>
        </tr>
        <tr>
          <td valign=\"top\">1.1.0</td>
          <td valign=\"top\">350</td>
          <td valign=\"top\">2014-05-05</td>
          <td valign=\"top\">Lennart Ochel</td>
          <td valign=\"top\">- add/fix animation for PC and TC <br>- new variables for debugging (actualSpeed, tSum, ...) <br>- minor fixes</td>
        </tr>
      </table>
    </html>"));
  end RevisionHistory;

  model PC "Continuous Place"
    Real t = if t_ < minMarks then minMarks else t_ "marking";
    Real tSumIn(fixed = true, start = 0.0);
    Real tSumIn_[nIn](each fixed = true, each start = 0.0);
    Real tSumOut(fixed = true, start = 0.0);
    Real tSumOut_[nOut](each fixed = true, each start = 0.0);
    parameter Integer nIn = 0 "number of input transitions" annotation(Dialog(connectorSizing = true));
    parameter Integer nOut = 0 "number of output transitions" annotation(Dialog(connectorSizing = true));
    // *** MODIFIABLE PARAMETERS AND VARIABLES BEGIN ***
    parameter Real startMarks = 0 "start marks" annotation(Dialog(enable = true, group = "Marks"));
    parameter Real minMarks(min=0) = 0 "minimum capacity" annotation(Dialog(enable = true, group = "Marks"));
    parameter Real maxMarks(min=minMarks) = PNlib.Constants.inf
      "maximum capacity"                                                           annotation(Dialog(enable = true, group = "Marks"));
    // *** MODIFIABLE PARAMETERS AND VARIABLES END ***
  protected
    Real t_(start = startMarks, fixed = true) "marking";
    Real arcWeightIn[nIn] "weights of input arcs";
    Real arcWeightOut[nOut] "weights of output arcs";
    Real instSpeedIn[nIn] "instantaneous speed of input transitions";
    Real instSpeedOut[nOut] "instantaneous speed of output transitions";
    Real maxSpeedIn[nIn] "maximum speed of input transitions";
    Real maxSpeedOut[nOut] "maximum speed of output transitions";
    Real prelimSpeedIn[nIn] "preliminary speed of input transitions";
    Real prelimSpeedOut[nOut] "preliminary speed of output transitions";
    Boolean fireIn[nIn](each start = false, each fixed = true)
      "Does any input transition fire?";
    Boolean fireOut[nOut](each start = false, each fixed = true)
      "Does any output transition fire?";
    Boolean activeIn[nIn] "Are the input transitions active?";
    Boolean activeOut[nOut] "Are the output transitions active?";
    Boolean enabledByInPlaces[nIn]
      "Are the input transitions enabled by all their input places?";
    // *** BLOCKS BEGIN ***
    // since no events are generated within functions!!!
    Boolean feeding = Functions.anyTrue(pre(fireIn))
      "Is the place fed by input transitions?";
    Boolean emptying = Functions.anyTrue(vec=  pre(fireOut))
      "Is the place emptied by output transitions?";
    Real firingSumIn = Functions.firingSumCon(fire=pre(fireIn), arcWeight=arcWeightIn, instSpeed=instSpeedIn)
      "firing sum calculation";
    Real firingSumOut = Functions.firingSumCon(fire=  pre(fireOut), arcWeight=  arcWeightOut, instSpeed=  instSpeedOut)
      "firing sum calculation";
    //decreasing factor calculation
    Real decFactorIn[nIn]= Functions.decreasingFactorIn(
      nIn=nIn,
      t=t_,
      maxMarks=maxMarks,
      speedOut=firingSumOut,
      maxSpeedIn=maxSpeedIn,
      prelimSpeedIn=prelimSpeedIn,
      arcWeightIn=arcWeightIn,
      firingIn=fireIn,
      firingOut=fireOut) "decreasing factors for input transitions";
    Real decFactorOut[nOut]= Functions.decreasingFactorOut(
      nOut=nOut,
      t=t_,
      minMarks=minMarks,
      speedIn=firingSumIn,
      maxSpeedOut=maxSpeedOut,
      prelimSpeedOut=prelimSpeedOut,
      arcWeightOut=arcWeightOut,
      firingIn=fireIn,
      firingOut=fireOut) "decreasing factors for output transitions";
    // *** BLOCKS END ***
  public
    Interfaces.PlaceIn inTransition[nIn](each t = t_, each maxTokens = maxMarks, enable = activeIn, each emptied = emptying, decreasingFactor = decFactorIn, each speedSum = firingSumOut, fire = fireIn, active = activeIn, arcWeight = arcWeightIn, instSpeed = instSpeedIn, maxSpeed = maxSpeedIn, prelimSpeed = prelimSpeedIn, enabledByInPlaces = enabledByInPlaces)
      "connector for input transitions"                                                                                                     annotation(Placement(transformation(origin = {-93, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-93, 0}, extent = {{-10, -10}, {10, 10}})));
    Interfaces.PlaceOut outTransition[nOut](each t = t_, each minTokens = minMarks, enable = activeOut, each arcType = PNlib.Types.ArcType.normal_arc, each testValue = -1.0, each fed = feeding, decreasingFactor=decFactorOut, each speedSum = firingSumIn, fire = fireOut, active = activeOut, arcWeight = arcWeightOut, instSpeed = instSpeedOut, maxSpeed = maxSpeedOut, prelimSpeed = prelimSpeedOut)
      "connector for output transitions"                                                                                                     annotation(Placement(transformation(origin = {93, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {93, 0}, extent = {{-10, -10}, {10, 10}})));
    //initial equation
    //  fireIn = pre(fireIn);
    //  fireOut = pre(fireOut);
  equation
    // *** MAIN BEGIN ***
    der(tSumIn) = firingSumIn;
    // der(tSumIn_) = arcWeightIn .* instSpeedIn;
    for i in 1:nIn loop
      der(tSumIn_[i]) = if pre(fireIn[i]) then arcWeightIn[i] * instSpeedIn[i] else 0.0;
    end for;
    der(tSumOut) = firingSumOut;
    // der(tSumOut_) = arcWeightOut .* instSpeedOut;
    for i in 1:nOut loop
      der(tSumOut_[i]) = if pre(fireOut[i]) then arcWeightOut[i] * instSpeedOut[i] else 0.0;
    end for;
    der(t_) = firingSumIn - firingSumOut
      "calculation of continuous mark change";
    // *** MAIN END ***
    // *** ERROR MESSENGES BEGIN ***
    assert(startMarks >= minMarks and startMarks <= maxMarks, "minMarks <= startMarks <= maxMarks");
    // *** ERROR MESSENGES END ***
    annotation(defaultComponentName = "P1", Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false), graphics), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2}), graphics={  Ellipse(fillColor = {255, 255, 255},
              fillPattern =                                                                                                    FillPattern.Solid, extent = {{-86, 86}, {86, -86}}, endAngle = 360), Ellipse(fillColor = {255, 255, 255},
              fillPattern =                                                                                                    FillPattern.Solid, extent = {{-79, 79}, {79, -79}}, endAngle = 360), Text(origin = {0.5, -0.5}, extent = {{-1.5, 25.5}, {-1.5, -21.5}}, textString = DynamicSelect("%startMarks", if t > 0 then realString(t, 1, 2) else "0.0")), Text(extent = {{-74, -103}, {-74, -128}}, textString = "%name")}));
  end PC;

  model TC "Continuous Transition"
    parameter Integer nIn = 0 "number of input places" annotation(Dialog(connectorSizing = true));
    parameter Integer nOut = 0 "number of output places" annotation(Dialog(connectorSizing = true));
    // *** MODIFIABLE PARAMETERS AND VARIABLES BEGIN ***
    Real maximumSpeed = 1 "maximum speed" annotation(Dialog(enable = true, group = "Maximum Speed"));
    Real arcWeightIn[nIn] = fill(1, nIn) "arc weights of input places" annotation(Dialog(enable = true, group = "Arc Weights"));
    Real arcWeightOut[nOut] = fill(1, nOut) "arc weights of output places" annotation(Dialog(enable = true, group = "Arc Weights"));
    // *** MODIFIABLE PARAMETERS AND VARIABLES END ***
    Boolean fire "Does the transition fire?";
    Real instantaneousSpeed "instantaneous speed";
    Real actualSpeed = if fire then instantaneousSpeed else 0.0;
    Interfaces.TransitionOut[nOut] outPlaces(each active = activation.active, each fire = fire, each enabledByInPlaces = true, arcWeight = arcWeightOut, each instSpeed = instantaneousSpeed, each prelimSpeed = preliminarySpeed.prelimSpeed, each maxSpeed = maximumSpeed, t = tOut, maxTokens = maxTokens, decreasingFactor=decreasingFactorOut, emptied = emptied, speedSum = speedSumOut)
      "connector for output places"                                                                                                     annotation(Placement(transformation(origin = {47, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {47, 0}, extent = {{-10, -10}, {10, 10}})));
    Interfaces.TransitionIn[nIn] inPlaces(each active = activation.active, each fire = fire, arcWeight = arcWeightIn, each instSpeed = instantaneousSpeed, each prelimSpeed = preliminarySpeed.prelimSpeed, each maxSpeed = maximumSpeed, t = tIn, minTokens = minTokens, fed = fed, enable = enableIn, decreasingFactor=decreasingFactorIn, speedSum = speedSumIn)
      "connector for input places"                                                                                                     annotation(Placement(visible = true, transformation(origin = {-47, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-47, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  protected
    Real tIn[nIn] "tokens of input places";
    Real tOut[nOut] "tokens of output places";
    Real minTokens[nIn] "minimum tokens of input places";
    Real maxTokens[nOut] "maximum tokens of output places";
    Real speedSumIn[nIn] "Input speeds of continuous input places";
    Real speedSumOut[nOut] "Output speeds of continuous output places";
    Real decreasingFactorIn[nIn] "decreasing factors of input places";
    Real decreasingFactorOut[nOut] "decreasing factors of output places";
    Boolean fed[nIn] "Are the input places fed by their input transitions?";
    Boolean emptied[nOut]
      "Are the output places emptied by their output transitions?";
    Boolean enableIn[nIn]
      "Is the transition enabled by all its discrete input transitions?";
    // *** BLOCKS BEGIN ***
    // since no events are generated within functions!!!
    Blocks.activationCon activation(nIn = nIn, nOut = nOut, tIn = tIn, tOut = tOut, arcWeightIn = arcWeightIn, arcWeightOut = arcWeightOut, minTokens = minTokens, maxTokens = maxTokens, fed = fed, emptied = emptied, testValue = inPlaces.testValue, arcType = inPlaces.arcType)
      "activation process";
    Blocks.preliminarySpeed preliminarySpeed(nIn = nIn, nOut = nOut, arcWeightIn = arcWeightIn, arcWeightOut = arcWeightOut, speedSumIn = speedSumIn, speedSumOut = speedSumOut, maximumSpeed = maximumSpeed, active = activation.active, weaklyInputActiveVec = activation.weaklyInputActiveVec, weaklyOutputActiveVec = activation.weaklyOutputActiveVec)
      "preliminary speed calculation";
    // *** BLOCKS END ***
  equation
    // *** MAIN BEGIN ***
    fire = activation.active and not maximumSpeed <= 0 "firing process";
      instantaneousSpeed = max(min(min(min(decreasingFactorIn),min(decreasingFactorOut))*maximumSpeed, preliminarySpeed.prelimSpeed), 0.0)
      "instantaneous speed calculation";
    // *** MAIN END ***
    annotation(defaultComponentName = "T1", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics={  Rectangle(extent = {{-40, 100}, {40, -100}}, lineColor = {0, 0, 0}, fillColor = DynamicSelect({255, 255, 255}, if fire then {255, 255, 0} else {255, 255, 255}),
              fillPattern =                                                                                                    FillPattern.Solid), Text(extent = {{-2, -116}, {-2, -144}}, lineColor = {0, 0, 0}, textString = DynamicSelect(" ", if animateSpeed == 1 and fire > 0.5 then if instantaneousSpeed > 0 then realString(instantaneousSpeed, 1, 2) else "0.0" else " ")), Text(extent = {{-4, 139}, {-4, 114}}, lineColor = {0, 0, 0}, textString = "%name")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics));
  end TC;

  model IA "Inhibitor Arc"
    // *** MODIFIABLE PARAMETERS AND VARIABLES BEGIN ***
    parameter Real testValue = 0.0
      "marking that has to be deceeded to enable firing"                              annotation(Dialog(enable = true, group = "Inhibitor Arc"));
    // *** MODIFIABLE PARAMETERS AND VARIABLES END ***
    Interfaces.TransitionIn inPlace(active = outTransition.active, fire = outTransition.fire, arcWeight = 0, instSpeed = 0, prelimSpeed = 0, maxSpeed = 0)
      "connector for place"                                                                                                     annotation(Placement(visible = true, transformation(origin = {-67, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-67, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Interfaces.PlaceOut outTransition(t = inPlace.t, minTokens = inPlace.minTokens, enable = inPlace.enable, decreasingFactor=inPlace.decreasingFactor, fed = inPlace.fed, arcType = PNlib.Types.ArcType.inhibitor_arc, testValue = testValue, speedSum = inPlace.speedSum)
      "connector for transition"                                                                                                     annotation(Placement(visible = true, transformation(origin = {67, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {67, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  equation
    // *** ERROR MESSENGES BEGIN ***
    assert(testValue >= 0.0, "Test values must be greater or equal than zero.");
    // *** ERROR MESSENGES END ***
    annotation(defaultComponentName = "IA1", Icon(coordinateSystem(extent = {{-74, -20}, {74, 20}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics={  Rectangle(fillColor = {255, 255, 255},
              fillPattern =                                                                                                    FillPattern.Solid, extent = {{-60, -20}, {60, 20}}), Line(points = {{-55, 0}, {55, 0}}), Ellipse(origin = {49, 0}, fillColor = {255, 255, 255},
              fillPattern =                                                                                                    FillPattern.Solid, extent = {{-6, -6}, {6, 6}}, endAngle = 360), Text(
              lineThickness =                                                                                                    0.5, extent = {{-38, -4}, {-38, -16}}, textString = " ")}), Diagram(coordinateSystem(extent = {{-74, -20}, {74, 20}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})));
  end IA;

  package Interfaces
    "contains the connectors for the Petri net component models"
    connector PlaceIn
      "part of place model to connect places to input transitions"
      output Real t "Marking of the place" annotation(HideResult = true);
      output Real maxTokens "Maximum capacity of the place" annotation(HideResult = true);
      output Boolean enable
        "Which of the input transitions are enabled by the place?"                     annotation(HideResult = true);
      output Real decreasingFactor
        "Factor for decreasing the speed of continuous input transitions"                            annotation(HideResult = true);
      output Boolean emptied
        "Is the continuous place emptied by output transitions?"                      annotation(HideResult = true);
      output Real speedSum "Output speed of a continuous place" annotation(HideResult = true);
      input Boolean active "Are the input transitions active?" annotation(HideResult = true);
      input Boolean fire "Do the input transitions fire?" annotation(HideResult = true);
      input Real arcWeight "Arc weights of input transitions" annotation(HideResult = true);
      input Boolean enabledByInPlaces
        "Are the input transitions enabled by all theier input places?"                               annotation(HideResult = true);
      input Real instSpeed
        "Instantaneous speeds of continuous input transitions"                    annotation(HideResult = true);
      input Real prelimSpeed
        "Preliminary speeds of continuous input transitions"                      annotation(HideResult = true);
      input Real maxSpeed "Maximum speeds of continuous input transitions" annotation(HideResult = true);
      annotation(Diagram(graphics={  Polygon(fillColor = {95, 95, 95},
                fillPattern =                                                        FillPattern.Solid, points = {{-70, 100}, {70, 0}, {-70, -100}, {-70, 100}}, lineColor = {0, 0, 0})}), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics={  Polygon(
                fillPattern =                                                                                                    FillPattern.Solid, points = {{-70, 100}, {70, 0}, {-70, -100}, {-70, 100}})}));
    end PlaceIn;

    connector PlaceOut
      "part of place model to connect places to output transitions"
      output Real t "Marking of the place" annotation(HideResult = true);
      output Real minTokens "Minimum capacity of the place" annotation(HideResult = true);
      output Boolean enable
        "Which of the output transitions are enabled by the place?"                     annotation(HideResult = true);
      output Real decreasingFactor
        "Factor for decreasing the speed of continuous input transitions"                            annotation(HideResult = true);
      output PNlib.Types.ArcType arcType
        "Type of output arcs ([1]normal, [2]test, [3]inhibition, or [4]read)"                                  annotation(HideResult = true);
      output Real testValue "Test value of a test or inhibitor arc" annotation(HideResult = true);
      output Boolean fed "Is the continuous place fed by input transitions?" annotation(HideResult = true);
      output Real speedSum "Input speed of a continuous place" annotation(HideResult = true);
      input Boolean active "Are the output transitions active?" annotation(HideResult = true);
      input Boolean fire "Do the output transitions fire?" annotation(HideResult = true);
      input Real arcWeight "Arc weights of output transitions" annotation(HideResult = true);
      input Real instSpeed
        "Instantaneous speeds of continuous output transitions"                    annotation(HideResult = true);
      input Real prelimSpeed
        "Preliminary speeds of continuous output transitions"                      annotation(HideResult = true);
      input Real maxSpeed "Maximum speeds of continuous output transitions" annotation(HideResult = true);
      annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics={  Polygon(fillColor = {255, 255, 255},
                fillPattern =                                                                                                    FillPattern.Solid, points = {{-70, 100}, {70, 0}, {-70, -100}, {-70, 100}})}), Diagram(graphics={  Polygon(fillColor = {215, 215, 215},
                fillPattern =                                                                                                    FillPattern.Solid, points = {{-72, 100}, {68, 0}, {-72, -100}, {-72, 100}}, lineColor = {0, 0, 0})}));
    end PlaceOut;

    connector TransitionIn
      "part of transition model to connect transitions to input places"
      input Real t "Markings of input places" annotation(HideResult = true);
      input Real minTokens "Minimum capacites of input places" annotation(HideResult = true);
      input Boolean enable "Is the transition enabled by input places?" annotation(HideResult = true);
      input Real decreasingFactor
        "Factor of continuous input places for decreasing the speed"                           annotation(HideResult = true);
      input PNlib.Types.ArcType arcType
        "Type of output arcs ([1]normal, [2]test, [3]inhibition, or [4]read)"                                 annotation(HideResult = true);
      input Real testValue "Test value of a test or inhibitor arc" annotation(HideResult = true);
      input Boolean fed "Are the continuous input places fed?" annotation(HideResult = true);
      input Real speedSum "Input speeds of continuous input places" annotation(HideResult = true);
      output Boolean active "Is the transition active?" annotation(HideResult = true);
      output Boolean fire "Does the transition fire?" annotation(HideResult = true);
      output Real arcWeight "Input arc weights of the transition" annotation(HideResult = true);
      output Real instSpeed "Instantaneous speed of a continuous transition" annotation(HideResult = true);
      output Real prelimSpeed "Preliminary speed of a continuous transition" annotation(HideResult = true);
      output Real maxSpeed "Maximum speed of a continuous transition" annotation(HideResult = true);
      annotation(Diagram(graphics={  Polygon(fillColor = {95, 95, 95},
                fillPattern =                                                        FillPattern.Solid, points = {{-70, 100}, {70, 0}, {-70, -100}, {-70, 100}}, lineColor = {0, 0, 0})}), Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics={  Polygon(
                fillPattern =                                                                                                    FillPattern.Solid, points = {{-70, 100}, {70, 0}, {-70, -100}, {-70, 100}})}));
    end TransitionIn;

    connector TransitionOut
      "part of transition model to connect transitions to output places"
      input Real t "Markings of output places" annotation(HideResult = true);
      input Real maxTokens "Maximum capacities of output places" annotation(HideResult = true);
      input Boolean enable "Is the transition enabled by output places?" annotation(HideResult = true);
      input Real decreasingFactor
        "Factor of continuous output places for decreasing the speed"                           annotation(HideResult = true);
      input Boolean emptied "Are the continuous output places emptied?" annotation(HideResult = true);
      input Real speedSum "Output speeds of continuous output places" annotation(HideResult = true);
      output Boolean active "Is the transition active?" annotation(HideResult = true);
      output Boolean fire "Does the transition fire?" annotation(HideResult = true);
      output Real arcWeight "Output arc weights of the transition" annotation(HideResult = true);
      output Boolean enabledByInPlaces
        "Is the transition enabled by all input places?"                                annotation(HideResult = true);
      output Real instSpeed "Instantaneous speed of a continuous transition" annotation(HideResult = true);
      output Real prelimSpeed "Preliminary speed of a continuous transition" annotation(HideResult = true);
      output Real maxSpeed "Maximum speed of a continuous transition" annotation(HideResult = true);
      annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2}), graphics={  Polygon(fillColor = {255, 255, 255},
                fillPattern =                                                                                                    FillPattern.Solid, points = {{-70, 100}, {70, 0}, {-70, -100}, {-70, 100}})}), Diagram(graphics={  Polygon(fillColor = {215, 215, 215},
                fillPattern =                                                                                                    FillPattern.Solid, points = {{-70, 100}, {70, 0}, {-70, -100}, {-70, 100}}, lineColor = {0, 0, 0})}));
    end TransitionOut;
  end Interfaces;

  package Blocks
    "contains blocks with specific procedures that are used in the Petri net component models"
    block activationCon "activation process of continuous transitions"
      parameter input Integer nIn "number of input places";
      parameter input Integer nOut "number of output places";
      input Real tIn[:] "marking of input places";
      input Real tOut[:] "marking of output places";
      input Real arcWeightIn[:] "arc weights of input places";
      input Real arcWeightOut[:] "arc weights of output places";
      input Real minTokens[:] "minimum capacities of input places";
      input Real maxTokens[:] "maximum capacities of output places";
      input Boolean fed[:] "input places are fed?";
      input Boolean emptied[:] "output places are emptied?";
      input PNlib.Types.ArcType arcType[:] "arc type of input places";
      input Real testValue[:] "test values of test and inhibitor arcs";
      output Boolean active "activation of transition";
      output Boolean weaklyInputActiveVec[nIn]
        "places that causes weakly input activation";
      output Boolean weaklyOutputActiveVec[nOut]
        "places that causes weakly output activation";
    algorithm
      active := true;
      weaklyInputActiveVec := fill(false, nIn);
      weaklyOutputActiveVec := fill(false, nOut);

      //check input places
      for i in 1:nIn loop
        // normal arc
        if arcType[i] == PNlib.Types.ArcType.normal_arc then
          if tIn[i] <= minTokens[i] then
             if fed[i] then
               weaklyInputActiveVec[i] := true;
             else
               active := false;
             end if;
          end if;
        // inhibitor arc
        elseif arcType[i] == PNlib.Types.ArcType.inhibitor_arc then
          if not tIn[i] < testValue[i] then
            active := false;
          end if;
        end if;
      end for;

      //output places
      for i in 1:nOut loop
        if tOut[i] >= maxTokens[i] and not emptied[i] then
          active := false;
        elseif tOut[i] >= maxTokens[i] and emptied[i] then
          weaklyOutputActiveVec[i] := true;
        end if;
      end for;
    end activationCon;

    block preliminarySpeed
      "calculates the preliminary speed of a continuous transition"
      input Integer nIn "number of input places";
      input Integer nOut "number of output places";
      input Real arcWeightIn[:] "input arc weights";
      input Real arcWeightOut[:] "output arc weights";
      input Real speedSumIn[:] "input speed";
      input Real speedSumOut[:] "output speed";
      input Real maximumSpeed "maximum speed";
      input Boolean active "activation";
      input Boolean weaklyInputActiveVec[:]
        "places that causes weakly input activation";
      input Boolean weaklyOutputActiveVec[:]
        "places that causes weakly output activation";
      output Real prelimSpeed "preliminary speed";
    algorithm
      prelimSpeed := maximumSpeed;
      for i in 1:nIn loop
        if weaklyInputActiveVec[i] and speedSumIn[i] / arcWeightIn[i] < prelimSpeed then
          prelimSpeed := speedSumIn[i] / arcWeightIn[i];
        end if;
      end for;
      for i in 1:nOut loop
        if weaklyOutputActiveVec[i] and speedSumOut[i] / arcWeightOut[i] < prelimSpeed then
          prelimSpeed := speedSumOut[i] / arcWeightOut[i];
        end if;
      end for;
    end preliminarySpeed;

  end Blocks;

  package Functions
    function anyTrue "Is any entry of a Boolean vector true?"
      input Boolean vec[:];
      output Boolean anytrue;
    algorithm
      anytrue := false;
      for i in 1:size(vec, 1) loop
        if vec[i] then
          anytrue := true;
        end if;
      end for;
    end anyTrue;

    function firingSumCon "calculates the firing sum of continuous places"
      input Boolean fire[:] "firability of transitions";
      input Real arcWeight[:] "arc weights";
      input Real instSpeed[:] "istantaneous speed of transitions";
      output Real conFiringSum "continuous firing sum";
    algorithm
      conFiringSum := 0.0;
      for i in 1:size(fire, 1) loop
        if fire[i] then
          conFiringSum := conFiringSum + arcWeight[i] * instSpeed[i];
        end if;
      end for;
    end firingSumCon;

    function numTrue "Is any entry of a Boolean vector true?"
      input Boolean vec[:];
      output Integer numtrue;
    algorithm
      numtrue := 0;
      for i in 1:size(vec, 1) loop
        if vec[i] then
          numtrue := numtrue+1;
        end if;
      end for;
    end numTrue;

    function conditionalSum
      "calculates the conditional sum of real vector entries"
      input Real vec[:];
      input Boolean con[:];
      output Real conSum;
    algorithm
      conSum:=0;
      for i in 1:size(vec,1) loop
        if con[i] then
           conSum:=conSum + vec[i];
        end if;
      end for;
    end conditionalSum;

    function decreasingFactorIn "calculation of decreasing factors"
      parameter input Integer nIn "number of input transitions";
      input Real t "marking";
      input Real maxMarks "maximum capacity";
      input Real speedOut "output speed";
      input Real maxSpeedIn[:] "maximum speeds of input transitions";
      input Real prelimSpeedIn[:] "preliminary speeds of input transitions";
      input Real arcWeightIn[:] "arc weights of input transitions";
      input Boolean firingIn[:] "firability of input transitions";
      input Boolean firingOut[:] "firability of input transitions";
      output Real decFactorIn[nIn] "decreasing factors for input transitions";
    protected
      Real maxSpeedSumIn;
      Real prelimSpeedSumIn;
      Real prelimDecFactorIn;
      Real modSpeedOut;
      Boolean anyFireIn = Functions.anyTrue(firingIn);
      Integer numFireIn = Functions.numTrue(firingIn);
      Integer numFireOut = Functions.numTrue(firingOut);
      Boolean stop;
    algorithm
      decFactorIn:=fill(-1, nIn);
      modSpeedOut:=speedOut;
      stop:=false;
      maxSpeedSumIn:=0;
      prelimSpeedSumIn:=0;
      prelimDecFactorIn:=0;
      //-----------------------------------------------------------------------------------------------------------//
      //decreasing factor of input transitions
    if numFireOut>0 and numFireIn>1 then
        prelimSpeedSumIn:=Functions.conditionalSum(arcWeightIn.*prelimSpeedIn, firingIn);
        maxSpeedSumIn:=Functions.conditionalSum(arcWeightIn.*maxSpeedIn, firingIn);
        if maxSpeedSumIn>0 then
        if not (t<maxMarks) and  speedOut<prelimSpeedSumIn then   // arcWeights can be zero and then is maxSpeedSumIn zero!!! and not maxSpeedSumIn<=0
          prelimDecFactorIn:=speedOut/maxSpeedSumIn;
          while not stop loop
            stop:=true;
            for i in 1:nIn loop
              if firingIn[i] and prelimDecFactorIn*maxSpeedIn[i]>prelimSpeedIn[i] and decFactorIn[i]<0 and prelimDecFactorIn<1 then
                 decFactorIn[i]:=prelimSpeedIn[i]/maxSpeedIn[i];
                 modSpeedOut:=modSpeedOut - arcWeightIn[i]*prelimSpeedIn[i];
                 maxSpeedSumIn:=maxSpeedSumIn - arcWeightIn[i]*maxSpeedIn[i];
                 stop:=false;
              end if;
            end for;
             if  maxSpeedSumIn>0 then
               prelimDecFactorIn:=modSpeedOut/maxSpeedSumIn;
             else
               prelimDecFactorIn:=1;
            end if;
     //       prelimDecFactorIn:=if not maxSpeedSumIn<=0 then modSpeedOut/maxSpeedSumIn else 1;  // arcWeights can be zero and then is maxSpeedSumIn zero!!!
          end while;
          for i in 1:nIn loop
            if decFactorIn[i]<0 then
              decFactorIn[i]:=prelimDecFactorIn;
            end if;
          end for;
        else
          decFactorIn:=fill(1, nIn);
        end if;
      else
          decFactorIn:=fill(1, nIn);
        end if;
         else
          decFactorIn:=fill(1, nIn);
    end if;
    end decreasingFactorIn;

    function decreasingFactorOut "calculation of decreasing factors"
      parameter input Integer nOut "number of output transitions";
      input Real t "marking";
      input Real minMarks "minimum capacity";
      input Real speedIn "input speed";
      input Real maxSpeedOut[:] "maximum speeds of output transitions";
      input Real prelimSpeedOut[:] "preliminary speeds of output transitions";
      input Real arcWeightOut[:] "arc weights of output transitions";
      input Boolean firingIn[:] "firability of input transitions";
      input Boolean firingOut[:] "firability of output transitions";
      output Real decFactorOut[nOut]
        "decreasing factors for output transitions";
    protected
      Real maxSpeedSumOut;
      Real prelimSpeedSumOut;
      Real prelimDecFactorOut;
      Real modSpeedIn;
      Boolean anyFireIn = Functions.anyTrue(firingIn);
      Integer numFireOut = Functions.numTrue(firingOut);
      Integer numFireIn = Functions.numTrue(firingIn);
      Boolean stop;
    algorithm
      decFactorOut:=fill(-1, nOut);
      modSpeedIn:=speedIn;
      stop:=false;
      maxSpeedSumOut:=0;
      prelimSpeedSumOut:=0;
      prelimDecFactorOut:=0;
      //-----------------------------------------------------------------------------------------------------------//
      //decreasing factor of output transitions
      stop:=false;
       if numFireOut>1 and numFireIn>0 then
        prelimSpeedSumOut:=Functions.conditionalSum(arcWeightOut.*prelimSpeedOut, firingOut);
        maxSpeedSumOut:=Functions.conditionalSum(arcWeightOut .*maxSpeedOut, firingOut);
        if maxSpeedSumOut>0 then
        if not t>minMarks and speedIn<prelimSpeedSumOut then

          prelimDecFactorOut:=speedIn/maxSpeedSumOut;
          while not stop loop
            stop:=true;
            for i in 1:nOut loop
              if firingOut[i] and prelimDecFactorOut*maxSpeedOut[i]>prelimSpeedOut[i] and decFactorOut[i]<0 and prelimDecFactorOut<1 then
                 decFactorOut[i]:=prelimSpeedOut[i]/maxSpeedOut[i];
                 modSpeedIn:=modSpeedIn - arcWeightOut[i]*prelimSpeedOut[i];
                 maxSpeedSumOut:=maxSpeedSumOut - arcWeightOut[i]*maxSpeedOut[i];
                 stop:=false;
              end if;
            end for;
          if maxSpeedSumOut>0 then
              prelimDecFactorOut:=modSpeedIn/maxSpeedSumOut;
          end if;
          end while;
          for i in 1:nOut loop
            if decFactorOut[i]<0 then
              decFactorOut[i]:=prelimDecFactorOut;
            end if;
          end for;
        else
          decFactorOut:=fill(1, nOut);
        end if;
        else
           decFactorOut:=fill(1, nOut);
       end if;
       else
           decFactorOut:=fill(1, nOut);
       end if;
    end decreasingFactorOut;
  end Functions;

  package Constants
    "contains constants which are used in the Petri net component models"
    constant Real inf = 9.999999999999999e+059
      "Biggest Real number such that inf and -inf are representable on the machine";
  end Constants;

  package Types
    type ArcType = enumeration(
        normal_arc,
        inhibitor_arc);
  end Types;

  package Examples
    model Test1a
      PNlib.PC P1 annotation(Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      annotation(experiment(StartTime = 0, StopTime = 2, Tolerance = 1e-006), Diagram(coordinateSystem(extent = {{0, -20}, {40, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{0, -20}, {40, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})));
    end Test1a;

    model Test1b
      PNlib.TC T1 annotation(Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      annotation(experiment(StartTime = 0, StopTime = 2, Tolerance = 1e-006), Diagram(coordinateSystem(extent = {{-40, -20}, {0, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{-40, -20}, {0, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})));
    end Test1b;

    model Test2
      PNlib.TC T1(nIn = 1, nOut = 0, maximumSpeed = 2 * P1.t) annotation(Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P1(nOut = 1, startMarks = 1) annotation(Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(P1.outTransition[1], T1.inPlaces[1]) annotation(Line(points = {{-10.7, 0}, {-10.7, 0}, {15.3, 0}}));
      annotation(experiment(StartTime = 0, StopTime = 2, Tolerance = 1e-006), Diagram(coordinateSystem(extent = {{-40, -20}, {40, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{-40, -20}, {40, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})));
    end Test2;

    model Test3
      PNlib.TC T1(nIn = 0, nOut = 1) annotation(Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P1(nIn = 1) annotation(Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(T1.outPlaces[1], P1.inTransition[1]) annotation(Line(points = {{-15.3, 0}, {10.7, 0}}));
      annotation(experiment(StartTime = 0, StopTime = 2, Tolerance = 1e-006), Diagram(coordinateSystem(extent = {{-40, -20}, {40, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{-40, -20}, {40, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})));
    end Test3;

    model Test4
      PNlib.PC P1(nOut = 1, startMarks = 0.5) annotation(Placement(visible = true, transformation(origin = {-60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.TC T1(nOut = 1, nIn = 1) annotation(Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P2(nOut = 1, nIn = 1) annotation(Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.TC T2(nIn = 1) annotation(Placement(visible = true, transformation(origin = {60, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(P1.outTransition[1], T1.inPlaces[1]) annotation(Line(points = {{-50.7, 0}, {-24.7, 0}}));
      connect(P2.inTransition[1], T1.outPlaces[1]) annotation(Line(points = {{10.7, 0}, {-15.3, 0}}));
      connect(P2.outTransition[1], T2.inPlaces[1]) annotation(Line(points = {{29.3, 0}, {55.3, 0}}));
      annotation(experiment(StartTime = 0, StopTime = 2, Tolerance = 1e-006), Diagram(coordinateSystem(extent = {{-80, -20}, {80, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{-80, -20}, {80, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})));
    end Test4;

    model Test5
      PNlib.PC P1(nOut = 1, startMarks = 1) annotation(Placement(visible = true, transformation(origin = {-30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P2(nIn = 1) annotation(Placement(visible = true, transformation(origin = {30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.TC T1(nIn = 1, nOut = 1, maximumSpeed = time) annotation(Placement(visible = true, transformation(origin = {0, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(T1.outPlaces[1], P2.inTransition[1]) annotation(Line(points = {{4.7, 10}, {4.7, 10}, {20.7, 10}}));
      connect(P1.outTransition[1], T1.inPlaces[1]) annotation(Line(points = {{-20.7, 10}, {-20.7, 10}, {-4.7, 10}}));
      annotation(Diagram(coordinateSystem(extent = {{-60, -20}, {60, 40}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2}), graphics), Icon(coordinateSystem(extent = {{-60, -20}, {60, 40}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), experiment(StartTime = 0, StopTime = 2, Tolerance = 1e-006));
    end Test5;

    model Test6
      PNlib.PC P1(nOut = 1, startMarks = 1) annotation(Placement(visible = true, transformation(origin = {-30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P2(nIn = 1, maxMarks = 0.4) annotation(Placement(visible = true, transformation(origin = {30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.TC T1(nIn = 1, nOut = 1) annotation(Placement(visible = true, transformation(origin = {0, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(T1.outPlaces[1], P2.inTransition[1]) annotation(Line(points = {{4.7, 10}, {4.7, 10}, {20.7, 10}}));
      connect(P1.outTransition[1], T1.inPlaces[1]) annotation(Line(points = {{-20.7, 10}, {-20.7, 10}, {-4.7, 10}}));
      annotation(Diagram(coordinateSystem(extent = {{-60, -20}, {60, 40}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{-60, -20}, {60, 40}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-006));
    end Test6;

    model Test7
      PNlib.PC P1(nOut = 1, startMarks = 1, minMarks = 0.5) annotation(Placement(visible = true, transformation(origin = {-30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P2(nIn = 1) annotation(Placement(visible = true, transformation(origin = {30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.TC T1(nIn = 1, nOut = 1) annotation(Placement(visible = true, transformation(origin = {0, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(T1.outPlaces[1], P2.inTransition[1]) annotation(Line(points = {{4.7, 10}, {4.7, 10}, {20.7, 10}}));
      connect(P1.outTransition[1], T1.inPlaces[1]) annotation(Line(points = {{-20.7, 10}, {-20.7, 10}, {-4.7, 10}}));
      annotation(Diagram(coordinateSystem(extent = {{-60, -20}, {60, 40}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{-60, -20}, {60, 40}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-006));
    end Test7;

    model Test8
      PNlib.PC P1(nOut = 2, startMarks = 1) annotation(Placement(visible = true, transformation(origin = {-30, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P2(nIn = 1) annotation(Placement(visible = true, transformation(origin = {30, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.TC T1(nIn = 1, nOut = 1) annotation(Placement(visible = true, transformation(origin = {0, 10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      TC T2(nIn = 1, nOut = 1) annotation(Placement(transformation(extent = {{-10, -40}, {10, -20}})));
      PC P3(nIn = 1, startMarks = 0.1) annotation(Placement(transformation(extent = {{20, -40}, {40, -20}})));
    equation
      connect(T1.outPlaces[1], P2.inTransition[1]) annotation(Line(points = {{4.7, 10}, {20.7, 10}}));
      connect(T2.outPlaces[1], P3.inTransition[1]) annotation(Line(points = {{4.7, -30}, {4.7, -30}, {20.7, -30}}));
      connect(P1.outTransition[1], T1.inPlaces[1]) annotation(Line(points = {{-20.7, -10.5}, {-12.354, -10.5}, {-12.354, 10}, {-4.7, 10}}));
      connect(P1.outTransition[2], T2.inPlaces[1]) annotation(Line(points = {{-20.7, -9.5}, {-12, -9.5}, {-12, -30}, {-4.7, -30}}, color = {0, 0, 0}, smooth = Smooth.None));
      annotation(Diagram(coordinateSystem(extent = {{-60, -60}, {60, 40}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2}), graphics), Icon(coordinateSystem(extent = {{-40, -60}, {30, 40}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-006));
    end Test8;

    model Test9
      PNlib.PC P1(nOut = 1, startMarks = 1) annotation(Placement(visible = true, transformation(origin = {-40, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.TC T1(nIn = 1, nOut = 1, maximumSpeed = 0.5) annotation(Placement(visible = true, transformation(origin = {-20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P2(nIn = 1, nOut = 1) annotation(Placement(visible = true, transformation(origin = {0, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.TC T2(nIn = 1, nOut = 1, maximumSpeed = 1.0) annotation(Placement(visible = true, transformation(origin = {20, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P3(nIn = 1, startMarks = 0) annotation(Placement(visible = true, transformation(origin = {40, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(T2.outPlaces[1], P3.inTransition[1]) annotation(Line(points={{24.7,0},
              {30.7783,0},{30.7783,0},{30.7,0}}));
      connect(P2.outTransition[1], T2.inPlaces[1]) annotation(Line(points={{9.3,0},
              {15.566,0},{15.566,0},{15.3,0}}));
      connect(T1.outPlaces[1], P2.inTransition[1]) annotation(Line(points={{-15.3,0},
              {-9.19811,0},{-9.19811,0},{-9.3,0}}));
      connect(P1.outTransition[1], T1.inPlaces[1]) annotation(Line(points={{-30.7,0},
              {-24.7642,0},{-24.7642,0},{-24.7,0}}));
      annotation(experiment(StartTime = 0, StopTime = 3, Tolerance = 1e-006), Diagram(coordinateSystem(extent = {{-60, -20}, {60, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{-60, -20}, {60, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})));
    end Test9;

    model Test10
      PNlib.PC P1(nOut = 1, startMarks = 1) annotation(Placement(visible = true, transformation(origin = {-60, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P2(nOut = 2, startMarks = 1.5) annotation(Placement(visible = true, transformation(origin = {-60, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.IA IA1(testValue = 0) annotation(Placement(transformation(extent = {{-8, -2}, {8, 2}}, rotation = 90, origin = {-30, 0})));
      PNlib.TC T1(nIn = 2, nOut = 1) annotation(Placement(visible = true, transformation(origin = {0, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.TC T2(nIn = 1, nOut = 1) annotation(Placement(visible = true, transformation(origin = {0, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P3(nIn = 1) annotation(Placement(visible = true, transformation(origin = {60, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      PNlib.PC P4(nIn = 1) annotation(Placement(visible = true, transformation(origin = {60, -40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(IA1.inPlace, P2.outTransition[2]) annotation(Line(points={{-30,
              -7.24324},{-30,-7.24324},{-30,-39.5},{-50.7,-39.5}}));
      connect(IA1.outTransition, T1.inPlaces[2]) annotation(Line(points={{-30,
              7.24324},{-30,7.24324},{-30,40.5},{-4.7,40.5}}));
      connect(P2.outTransition[1], T2.inPlaces[1]) annotation(Line(points = {{-50.7, -40.5}, {-4.24528, -40.5}, {-4.24528, -40}, {-4.7, -40}}));
      connect(T2.outPlaces[1], P4.inTransition[1]) annotation(Line(points = {{4.7, -40}, {50.9434, -40}, {50.9434, -40}, {50.7, -40}}));
      connect(T1.outPlaces[1], P3.inTransition[1]) annotation(Line(points = {{4.7, 40}, {50.4717, 40}, {50.4717, 40}, {50.7, 40}}));
      connect(P1.outTransition[1], T1.inPlaces[1]) annotation(Line(points = {{-50.7, 40}, {-4.71698, 40}, {-4.71698, 39.5}, {-4.7, 39.5}}));
      annotation(experiment(StartTime = 0, StopTime = 3, Tolerance = 1e-006), Diagram(coordinateSystem(extent = {{-80, -60}, {80, 60}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Icon(coordinateSystem(extent = {{-80, -60}, {80, 60}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})));
    end Test10;

    model Test11
      PNlib.PC 'P1'(nOut=1, startMarks=1.5) annotation (Placement(visible=true,
            transformation(
            origin={-60,0},
            extent={{-10,-10},{10,10}},
            rotation=0)));
      PNlib.TC 'T1'(nOut=1, nIn=1) annotation (Placement(visible=true,
            transformation(
            origin={-30,0},
            extent={{-10,-10},{10,10}},
            rotation=0)));
      PNlib.PC 'P2'(nOut=1, nIn=1) annotation (Placement(visible=true,
            transformation(
            origin={0,0},
            extent={{-10,-10},{10,10}},
            rotation=0)));
      PNlib.TC 'T2'(
        nIn=1,
        nOut=1,
        maximumSpeed=0.5 + time) annotation (Placement(visible=true,
            transformation(
            origin={30,0},
            extent={{-10,-10},{10,10}},
            rotation=0)));
      PC 'P3'(nIn=1)
        annotation (Placement(transformation(extent={{50,-10},{70,10}})));
    equation
      connect('P1'.outTransition[1], 'T1'.inPlaces[1])
        annotation (Line(points={{-50.7,0},{-42,0},{-34.7,0}}));
      connect('P2'.inTransition[1], 'T1'.outPlaces[1])
        annotation (Line(points={{-9.3,0},{-9.3,0},{-25.3,0}}));
      connect('P2'.outTransition[1], 'T2'.inPlaces[1])
        annotation (Line(points={{9.3,0},{25.3,0}}));
      connect('T2'.outPlaces[1], 'P3'.inTransition[1]) annotation (Line(
          points={{34.7,0},{50.7,0}},
          color={0,0,0},
          smooth=Smooth.None));
      annotation(experiment(StartTime = 0, StopTime = 2, Tolerance = 1e-006), Diagram(coordinateSystem(extent={{-80,-20},
                {80,20}},                                                                                                    preserveAspectRatio=false,   initialScale = 0.1, grid = {2, 2}),
            graphics),                                                                                                    Icon(coordinateSystem(extent = {{-80, -20}, {80, 20}}, preserveAspectRatio = false, initialScale = 0.1, grid = {2, 2})));
    end Test11;

    model Test12 "conflict"

      PNlib.TC T1(nOut=1)
        annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
      PNlib.TC T2(nIn=1, nOut=1)
        annotation (Placement(transformation(extent={{20,10},{40,30}})));
      PNlib.TC T3(nIn=1, nOut=1)
        annotation (Placement(transformation(extent={{20,-30},{40,-10}})));
      PNlib.PC P1(nIn=1, nOut=2)
        annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
      PNlib.PC P2(nIn=1)
        annotation (Placement(transformation(extent={{50,10},{70,30}})));
      PNlib.PC P3(nIn=1)
        annotation (Placement(transformation(extent={{50,-30},{70,-10}})));
    equation
      connect(T1.outPlaces[1], P1.inTransition[1]) annotation (Line(
          points={{-25.3,0},{-9.3,0}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(P1.outTransition[1], T2.inPlaces[1]) annotation (Line(
          points={{9.3,-0.5},{20,-0.5},{20,20},{25.3,20}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(P1.outTransition[2], T3.inPlaces[1]) annotation (Line(
          points={{9.3,0.5},{20,0.5},{20,-20},{25.3,-20}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(T3.outPlaces[1], P3.inTransition[1]) annotation (Line(
          points={{34.7,-20},{50.7,-20}},
          color={0,0,0},
          smooth=Smooth.None));
      connect(T2.outPlaces[1], P2.inTransition[1]) annotation (Line(
          points={{34.7,20},{50.7,20}},
          color={0,0,0},
          smooth=Smooth.None));
      annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-80,-40},
                {80,40}}),         graphics), Icon(coordinateSystem(extent={{
                -80,-40},{80,40}})));
    end Test12;
    annotation(Icon(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})), Diagram(coordinateSystem(extent = {{-100, -100}, {100, 100}}, preserveAspectRatio = true, initialScale = 0.1, grid = {2, 2})));
  end Examples;
end PNlib;
