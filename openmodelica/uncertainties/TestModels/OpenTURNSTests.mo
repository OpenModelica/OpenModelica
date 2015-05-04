package OpenTURNSTests
  annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-100.0,-100.0},{80.0,50.0}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{-100.0,50.0},{-80.0,70.0},{100.0,70.0},{80.0,50.0},{-100.0,50.0}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{100.0,70.0},{100.0,-80.0},{80.0,-100.0},{80.0,50.0},{100.0,70.0}}),Bitmap(visible=true, origin={-50.0,0.0}, fileName="logoOpenturns.png", imageSource="", extent={{-75.0,-42.4646},{75.0,42.4646}}),Bitmap(visible=true, origin={23.1899,-65.9119}, fileName="logoModelica.png", imageSource="", extent={{-53.1899,-18.4552},{53.1899,18.4552}})}), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  model ArticleExpleThermoSysPro
    annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP1 annotation(Placement(visible=true, transformation(origin={-140.0,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP1 annotation(Placement(visible=true, transformation(origin={136.0591,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss1(K=0.0001) annotation(Placement(visible=true, transformation(origin={-80.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-44.0534,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={43.7284,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss2(K=0.0001) annotation(Placement(visible=true, transformation(origin={10.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss3(K=0.0001) annotation(Placement(visible=true, transformation(origin={10.0,-20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss4(K=0.0001) annotation(Placement(visible=true, transformation(origin={110.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    parameter Distribution distributionQ2=Distribution("Normal", {2.5,0.5}, {"mu","sigma"});
    parameter Distribution distributionQ3=Distribution("Normal", {2.6,0.1}, {"mu","sigma"});
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1 annotation(Placement(visible=true, transformation(origin={-20.0,28.3184}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q.distribution=distributionQ2, Q.uncertain=Uncertainty.given) annotation(Placement(visible=true, transformation(origin={-20.0,-12.4274}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3(Q.distribution=distributionQ3, Q.uncertain=Uncertainty.given) annotation(Placement(visible=true, transformation(origin={-110.0,7.6168}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4(Q.uncertain=Uncertainty.sought) annotation(Placement(visible=true, transformation(origin={80.0,7.6168}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(pipePressureLoss4.C2,sinkP1.C) annotation(Line(visible=true, origin={124.024,-0.1018}, points={{-2.9658,0.1696},{0.6553,0.1696},{0.6553,-0.1696},{1.6553,-0.1696}}, color={0,0,255}));
    connect(sensorQ4.C2,pipePressureLoss4.C1) annotation(Line(visible=true, origin={95.4854,-0.1703}, points={{-4.9798,-0.306},{0.6599,-0.306},{0.6599,0.306},{3.6599,0.306}}, color={0,0,255}));
    connect(mixer21.Cs,sensorQ4.C1) annotation(Line(visible=true, origin={64.3305,-0.2621}, points={{-10.4258,0.0586},{2.4753,0.0586},{2.4753,-0.0586},{5.4753,-0.0586}}, color={0,0,255}));
    connect(sensorQ2.C2,pipePressureLoss3.C1) annotation(Line(visible=true, origin={-4.5146,-20.1924}, points={{-4.9798,-0.3281},{0.6599,-0.3281},{0.6599,0.3281},{3.6599,0.3281}}, color={0,0,255}));
    connect(sensorQ1.C2,pipePressureLoss2.C1) annotation(Line(visible=true, origin={-4.5146,20.1805}, points={{-4.9798,0.0448},{0.6599,0.0448},{0.6599,-0.0448},{3.6599,-0.0448}}, color={0,0,255}));
    connect(splitter21.Cs2,sensorQ2.C1) annotation(Line(visible=true, origin={-36.7652,-16.9235}, points={{-3.2855,6.8829},{-3.2855,-3.4414},{6.571,-3.4414}}, color={0,0,255}));
    connect(splitter21.Cs1,sensorQ1.C1) annotation(Line(visible=true, origin={-36.7652,16.8889}, points={{-3.2855,-6.984},{-3.2855,3.492},{6.571,3.492}}, color={0,0,255}));
    connect(sensorQ3.C2,pipePressureLoss1.C1) annotation(Line(visible=true, origin={-94.5146,-0.1703}, points={{-4.9798,-0.306},{0.6599,-0.306},{0.6599,0.306},{3.6599,0.306}}, color={0,0,255}));
    connect(sourceP1.C,sensorQ3.C1) annotation(Line(visible=true, origin={-123.9998,-0.3639}, points={{-5.4168,-0.0432},{0.8056,-0.0432},{0.8056,0.0432},{3.8056,0.0432}}, color={0,0,255}));
    connect(pipePressureLoss1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-59.2678,-0.0}, points={{-9.674,0.0678},{2.1144,0.0678},{2.1144,-0.0678},{5.4452,-0.0678}}, color={0,0,255}));
    connect(pipePressureLoss3.C2,mixer21.Ce2) annotation(Line(visible=true, origin={33.5937,-16.7254}, points={{-12.5355,-3.2067},{6.2677,-3.2067},{6.2677,6.4135}}, color={0,0,255}));
    connect(pipePressureLoss2.C2,mixer21.Ce1) annotation(Line(visible=true, origin={33.5485,16.5671}, points={{-12.4902,3.5007},{6.2451,3.5007},{6.2451,-7.0014}}, color={0,0,255}));
  end ArticleExpleThermoSysPro;

  model CantileverBeam "Model from here: http://doc.openturns.org/openturns-latest/html/ExamplesGuide/cid1.xhtml#cid1"
    parameter Distribution distributionE=Distribution("Beta", {0.93,3.2,28000000.0,48000000.0}, {"r","t","a","b"});
    parameter Distribution distributionF=Distribution("LogNormal", {30000,9000,15000}, {"mu","sigma","gamma"});
    parameter Distribution distributionL=Distribution("Uniform", {250,260}, {"a","b"});
    parameter Distribution distributionI=Distribution("Beta", {2.5,4.0,310.0,450.0}, {"r","t","a","b"});
    Real y(uncertain=Uncertainty.sought);
    parameter Real F(distribution=distributionF, uncertain=Uncertainty.given)=300;
    parameter Real E(distribution=distributionE, uncertain=Uncertainty.given)=3000000000.0;
    parameter Real L(distribution=distributionL, uncertain=Uncertainty.given)=250;
    parameter Real I(distribution=distributionI, uncertain=Uncertainty.given)=4e-06 annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-10.0,0.0}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-70.0,-10.0},{70.0,10.0}}),Line(visible=true, origin={-80.0,0.0}, points={{0.0,50.0},{0.0,-50.0}}, thickness=3),Line(visible=true, origin={50.0,30.0634}, points={{0.0,18.937},{0.0,-18.937}}, color={255,0,0}, thickness=1, arrow={Arrow.None,Arrow.Open}, arrowSize=6),Text(visible=true, origin={62.1431,44.7413}, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-5.4548,-6.2587},{5.4548,6.2587}}, textString="F", fontName="Arial"),Line(visible=true, origin={-45.0,20.0}, points={{15.0,10.0},{-15.0,-10.0}}, arrow={Arrow.None,Arrow.Open}, arrowSize=6),Text(visible=true, origin={-20.0781,34.0169}, fillPattern=FillPattern.Solid, extent={{-9.9219,-4.0169},{9.9219,4.0169}}, textString="E", fontName="Arial"),Line(visible=true, origin={-9.3707,-20.0}, points={{-67.248,0.0},{67.248,0.0}}, arrow={Arrow.Open,Arrow.Open}, arrowSize=6),Text(visible=true, origin={-13.0781,-26.9831}, fillPattern=FillPattern.Solid, extent={{-9.9219,-4.0169},{9.9219,4.0169}}, textString="L", fontName="Arial")}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, origin={-10.0,0.0}, fillColor={192,192,192}, fillPattern=FillPattern.Solid, extent={{-70.0,-10.0},{70.0,10.0}}),Line(visible=true, origin={-80.0,0.0}, points={{0.0,50.0},{0.0,-50.0}}, thickness=3),Line(visible=true, origin={50.0,30.0634}, points={{0.0,18.937},{0.0,-18.937}}, color={255,0,0}, thickness=1, arrow={Arrow.None,Arrow.Open}, arrowSize=6),Text(visible=true, origin={62.1431,44.7413}, fillColor={255,0,0}, fillPattern=FillPattern.Solid, extent={{-5.4548,-6.2587},{5.4548,6.2587}}, textString="F", fontName="Arial"),Line(visible=true, origin={-45.0,20.0}, points={{15.0,10.0},{-15.0,-10.0}}, arrow={Arrow.None,Arrow.Open}, arrowSize=6),Text(visible=true, origin={-20.0781,34.0169}, fillPattern=FillPattern.Solid, extent={{-9.9219,-4.0169},{9.9219,4.0169}}, textString="E", fontName="Arial"),Line(visible=true, origin={-9.3707,-20.0}, points={{-67.248,0.0},{67.248,0.0}}, arrow={Arrow.Open,Arrow.Open}, arrowSize=6),Text(visible=true, origin={-13.0781,-26.9831}, fillPattern=FillPattern.Solid, extent={{-9.9219,-4.0169},{9.9219,4.0169}}, textString="L", fontName="Arial")}));
    Correlation correlation[1];
  algorithm
    correlation:={Correlation(L, I, -0.2)};
  equation
    y=(F*L*L*L)/(3.0*E*I);
  end CantileverBeam;

  model TankPI
    parameter Distribution distributionqOut=Distribution("Normal", {0.02,0.005}, {"mu","sigma"});
    IntroductoryExamples.Hierarchical.Components.LiquidSource source(flowLevel=0.02, qOut.uncertain=Uncertainty.given, qOut.distribution=distributionqOut) annotation(Placement(visible=true, transformation(origin={-17.5,22.5}, extent={{-7.5,-7.5},{7.5,7.5}}, rotation=0)));
    IntroductoryExamples.Hierarchical.Components.PIcontinuousController piContinuous(ref=0.25) annotation(Placement(visible=true, transformation(origin={12.5,-22.5}, extent={{-7.5,-7.5},{7.5,7.5}}, rotation=0)));
    IntroductoryExamples.Hierarchical.Components.Tank tank(area=1, h.uncertain=Uncertainty.sought) annotation(Placement(visible=true, transformation(origin={12.5,5}, extent={{-7.5,-7.5},{7.5,7.5}}, rotation=0)));
  equation
    connect(tank.tSensor,piContinuous.cIn) annotation(Line(visible=true, origin={2.35175,-11.003}, points={{1.89225,11.497},{-1.89525,11.497},{-1.89525,-11.497},{1.89825,-11.497}}));
    connect(source.qOut,tank.qIn) annotation(Line(visible=true, origin={-10.248,11.0793}, points={{-7.252,3.17067},{-7.252,-1.58533},{14.504,-1.58533}}));
    connect(piContinuous.cOut,tank.tActuator) annotation(Line(visible=true, origin={22.6345,-6.611}, points={{-1.88449,-15.889},{1.88899,-15.889},{1.88899,15.889},{-1.89349,15.889}}));
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={5,5}), graphics={Line(visible=true, points={{0,-75},{-90,-75},{-90,70},{-70,70}}),Line(visible=true, points={{50,20},{70,20},{70,-50}}),Text(visible=true, fillPattern=FillPattern.Solid, extent={{-100,-150},{100,-110}}, textString="%name", fontName="Arial"),Rectangle(visible=true, origin={-11.9933,60}, lineColor={232,232,232}, fillColor={255,255,255}, fillPattern=FillPattern.VerticalCylinder, extent={{-63.0067,-25},{66.9933,25}}),Rectangle(visible=true, fillPattern=FillPattern.Solid, extent={{0,-100},{100,-50}}),Text(visible=true, origin={-24.78,7.38}, fillColor={255,255,255}, fillPattern=FillPattern.Solid, extent={{24.78,-107.38},{124.78,-57.38}}, textString="PI", fontName="Arial"),Ellipse(visible=true, origin={-10,85}, lineColor={216,216,216}, fillColor={255,255,255}, fillPattern=FillPattern.VerticalCylinder, extent={{-65,15},{65,-15}}),Ellipse(visible=true, origin={-10,-15}, lineColor={0,0,128}, fillColor={0,0,255}, fillPattern=FillPattern.VerticalCylinder, extent={{-65,15},{65,-15}}),Rectangle(visible=true, origin={3,2.55}, lineColor={0,0,127}, fillColor={0,0,255}, pattern=LinePattern.None, fillPattern=FillPattern.VerticalCylinder, extent={{-78,-17.55},{52,32.45}}),Ellipse(visible=true, origin={-10,35}, lineColor={216,216,216}, fillColor={0,0,255}, fillPattern=FillPattern.VerticalCylinder, extent={{-65,15},{65,-15}})}), Diagram(coordinateSystem(extent={{-40,40},{40,-40}}, preserveAspectRatio=true, initialScale=0.1, grid={5,5})), experiment(StartTime=0.0, StopTime=250), Documentation(info="<h1>MathModelica&reg;</h1>
<h2><em>Hierarchical modeling - component based tank system</em></h2>
<h4>&copy; 2010 MathCore Engineering AB</h4>
<hr />
<p>&nbsp;</p>
<table bgcolor=\"lightgrey\">
<tbody>
<tr>
<td>
<p>The <a href=\"Modelica://IntroductoryExamples\">IntroductoryExamples</a> library contains a few examples that are will help you to get started with <em>MathModelica</em>. In the <a href=\"../../docs/introductory_examples.pdf\">Introductory Examples document</a> you can find  detailed step by step descriptions of how to build and simulate respective model, as well as some exercises that will help you learn <em>MathModelica</em>.</p>
</td>
</tr>
</tbody>
</table>
<p>&nbsp;</p>
<hr />
<p>This is a component based model of the following one-tank system with a PI controller:</p>
<p><img src=\"Hierarchical/image001.png\" alt=\"\" /></p>
<p>The water level, <em>h</em>, in the tank is a function of the flow in and out from the tank, and the tank area:</p>
<p><sub><img src=\"Hierarchical/image002.png\" alt=\"\" /></sub></p>
<p>The input flow is given by the <a href=\"Modelica://IntroductoryExamples.Hierarchical.Components.LiquidSource\">LiquidSource</a> component and is constant the first 150 seconds and then triples after this. By controlling the output flow of the <a href=\"Modelica://IntroductoryExamples.Hierarchical.Components.Tank\">tank</a> with a <a href=\"Modelica://IntroductoryExamples.Hierarchical.Components.PIcontinuousController\">PI controller</a> the liquid level is held at a desired reference value.</p>
<p>By simulating the model for 250 seconds we can see that the tank level starts to increase reaching and passing the desired reference level. When the desired level is passed the outflow is opened and after 150 seconds the level has stabilized. However at this moment the input flow is suddenly increased and the water level is therefore increased before the controller manages to stabilize it again. This is illustrated in the figure below:</p>
<p><img src=\"Hierarchical/image012.png\" alt=\"\" /></p>
<p>The <a href=\"Modelica://IntroductoryExamples.Hierarchical.FlatTank\">FlatTank</a> model is a model of the same system, but implemented without the use of components.</p>
<p>The <a href=\"Modelica://IntroductoryExamples.Hierarchical.TankPID\">TankPID</a> model is a model of the same system, but with a PID controller.</p>", revisions=""));
  end TankPI;

end OpenTURNSTests;
