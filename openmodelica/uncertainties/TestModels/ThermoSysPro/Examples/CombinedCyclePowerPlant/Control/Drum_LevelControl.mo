within ThermoSysPro.Examples.CombinedCyclePowerPlant.Control;
model Drum_LevelControl "Drum level control"
  parameter Real k=1 "Gain";
  parameter Real Ti=1 "Time constant (s)";
  parameter Real minval=0.01 "Minimum output value";
  annotation(Diagram(coordinateSystem(scale=0.1, extent={{-100,-100},{100,100}}), graphics={Text(lineColor={0,0,255}, extent={{-97,99},{-59,91}}, fillColor={191,0,0}, textString="Niveau ballon"),Text(lineColor={0,0,255}, extent={{-101,-59},{-55,-91}}, fillColor={191,0,0}, textString="Consigne Niveau"),Text(lineColor={0,0,255}, extent={{64,-92},{102,-100}}, fillColor={191,0,0}, textString="Ouv Vanne")}), Icon(coordinateSystem(scale=0.1, extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,100},{100,-100}}),Rectangle(extent={{-80,81},{80,-80}}, lineColor={0,0,255}, fillColor={191,95,0}, fillPattern=FillPattern.Solid),Text(lineColor={0,0,255}, extent={{-88,65},{74,-26}}, fillColor={0,0,255}, textString="Régulation Niveau "),Text(lineColor={0,0,255}, extent={{-41,-9},{38,-58}}, fillColor={0,0,255}, textString="Bache"),Text(lineColor={0,0,255}, extent={{-98,93},{-60,85}}, fillColor={191,0,0}, textString="Niveau ballon"),Text(lineColor={0,0,255}, extent={{-101,-31},{-52,-64}}, fillColor={191,0,0}, textString="Consigne Niveau"),Text(lineColor={0,0,255}, extent={{64,-86},{102,-94}}, fillColor={191,0,0}, textString="Ouv Vanne")}));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal MesureNiveauEau annotation(Placement(transformation(x=-105.0, y=90.0, scale=0.05, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-105.0, y=90.0, scale=0.05, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal ConsigneNiveauEau annotation(Placement(transformation(x=-105.0, y=-60.0, scale=0.05, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-105.0, y=-60.0, scale=0.05, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal SortieReelle1 annotation(Placement(transformation(x=105.0, y=-90.0, scale=0.05, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=105.0, y=-90.0, scale=0.05, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Continu.PIsat pIsat(permanent=true, ureset0=0.8, k=k, Ti=Ti, minval=minval) annotation(Placement(transformation(x=-10.0, y=-56.5, scale=0.29, aspectRatio=0.810344827586207, flipHorizontal=false, flipVertical=false, rotation=-270.0)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Continu.PT1 pT1_1(permanent=true, U0=1.1, Ti=10) annotation(Placement(transformation(x=2.5, y=84.0, scale=0.155, aspectRatio=0.967741935483871, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Math.Add add(k1=-1, k2=+1) annotation(Placement(transformation(x=65.5, y=72.5, scale=0.175, aspectRatio=1.11428571428571, flipHorizontal=false, flipVertical=false)));
equation
  connect(pIsat.y,SortieReelle1) annotation(Line(points={{-10,-82.35},{-10,-90},{105,-90}}, color={255,0,0}));
  connect(MesureNiveauEau,pT1_1.u) annotation(Line(points={{-105,90},{-38,90},{-38,84},{-14.55,84}}, color={191,0,0}));
  connect(ConsigneNiveauEau,add.u2) annotation(Line(points={{-105,-60},{-68,-60},{-68,42},{35,42},{35,60.8},{46.25,60.8}}));
  connect(pT1_1.y,add.u1) annotation(Line(points={{19.55,84},{32.9,84},{32.9,84.2},{46.25,84.2}}));
  connect(add.y,pIsat.u) annotation(Line(points={{84.75,72.5},{96,72.5},{96,-30.65},{-10,-30.65}}));
end Drum_LevelControl;
