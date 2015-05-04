package DataReconciliationTests
  annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, extent={{-100.0,-100.0},{80.0,50.0}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{-100.0,50.0},{-80.0,70.0},{100.0,70.0},{80.0,50.0},{-100.0,50.0}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={235,235,235}, fillPattern=FillPattern.Solid, points={{100.0,70.0},{100.0,-80.0},{80.0,-100.0},{80.0,50.0},{100.0,70.0}}),Text(visible=true, origin={-42.0755,7.2622}, fillPattern=FillPattern.Solid, extent={{-39.4379,-29.2276},{39.4379,29.2276}}, textString="Data reconciliation", fontName="Arial"),Bitmap(visible=true, origin={23.1899,-65.9119}, fileName="logoModelica.png", imageSource="", extent={{-53.1899,-18.4552},{53.1899,18.4552}})}), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
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
    parameter Distribution distributionQ1=Distribution("Normal", {5.0,1.0}, {"mu","sigma"});
    parameter Distribution distributionQ2=Distribution("Normal", {2.5,0.5}, {"mu","sigma"});
    parameter Distribution distributionQ3=Distribution("Normal", {2.6,0.1}, {"mu","sigma"});
    parameter Distribution distributionQ4=Distribution("Normal", {5.5,0.5}, {"mu","sigma"});
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q.distribution=distributionQ1, Q.uncertain=Uncertainty.refine) annotation(Placement(visible=true, transformation(origin={-20.0,28.3184}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q.distribution=distributionQ2, Q.uncertain=Uncertainty.refine) annotation(Placement(visible=true, transformation(origin={-20.0,-12.4274}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3(Q.distribution=distributionQ3, Q.uncertain=Uncertainty.refine) annotation(Placement(visible=true, transformation(origin={-110.0,7.6168}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4(Q.distribution=distributionQ4, Q.uncertain=Uncertainty.refine) annotation(Placement(visible=true, transformation(origin={80.0,7.6168}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
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
    connect(pipePressureLoss4.C2,sinkP1.C) annotation(Line(visible=true, origin={124.024,-0.1018}, points={{-2.9658,0.1696},{0.6553,0.1696},{0.6553,-0.1696},{1.6553,-0.1696}}, color={0,0,255}));
  end ArticleExpleThermoSysPro;

  model SimpleExple
    parameter Distribution distributionQ1=Distribution("Normal", {5.0,1.0}, {"mu","sigma"});
    parameter Distribution distributionQ2=Distribution("Normal", {2.5,0.5}, {"mu","sigma"});
    parameter Distribution distributionQ3=Distribution("Normal", {2.6,0.1}, {"mu","sigma"});
    parameter Distribution distributionQ2=Distribution("Normal", {5.5,0.5}, {"mu","sigma"});
    Real q1(uncertain=Uncertainty.refine, distribution=distributionQ1)=1;
    Real q2(uncertain=Uncertainty.refine, distribution=distributionQ2)=2;
    Real q3(uncertain=Uncertainty.refine, distribution=distributionQ3);
    Real q4(uncertain=Uncertainty.refine, distribution=distributionQ4) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854}, fillPattern=FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString="Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}));
  equation
    q1=q2 + q3;
    q4=q2 + q3;
  end SimpleExple;

  model VDI2048Exple
    parameter Distribution distributionmFDKEL=Distribution("Normal", {46.241,0.8}, {"mu","sigma"});
    parameter Distribution distributionmFDKELL=Distribution("Normal", {45.668,0.79}, {"mu","sigma"});
    parameter Distribution distributionmSPL=Distribution("Normal", {44.575,0.535}, {"mu","sigma"});
    parameter Distribution distributionmSPLL=Distribution("Normal", {44.319,0.532}, {"mu","sigma"});
    parameter Distribution distributionmV=Distribution("Normal", {0.525,0.105}, {"mu","sigma"});
    parameter Distribution distributionmHK=Distribution("Normal", {69.978,0.854}, {"mu","sigma"});
    parameter Distribution distributionmA7=Distribution("Normal", {10.364,0.168}, {"mu","sigma"});
    parameter Distribution distributionmA6=Distribution("Normal", {3.744,0.058}, {"mu","sigma"});
    parameter Distribution distributionmA5=Distribution("Normal", {4.391,0.058}, {"mu","sigma"});
    parameter Distribution distributionmHDNK=Distribution("Normal", {18.498,0.205}, {"mu","sigma"});
    parameter Distribution distributionmD=Distribution("Normal", {2.092,0.272}, {"mu","sigma"});
    Real mFDKEL(uncertain=Uncertainty.refine, distribution=distributionmFDKEL)=46.241;
    Real mFDKELL(uncertain=Uncertainty.refine, distribution=distributionmFDKELL)=45.668;
    Real mSPL(uncertain=Uncertainty.refine, distribution=distributionmSPL)=44.575;
    Real mSPLL(uncertain=Uncertainty.refine, distribution=distributionmSPLL)=44.319;
    Real mV(uncertain=Uncertainty.refine, distribution=distributionmV);
    Real mHK(uncertain=Uncertainty.refine, distribution=distributionmHK)=69.978;
    Real mA7(uncertain=Uncertainty.refine, distribution=distributionmA7)=10.364;
    Real mA6(uncertain=Uncertainty.refine, distribution=distributionmA6)=3.744;
    Real mA5(uncertain=Uncertainty.refine, distribution=distributionmA5);
    Real mHDNK(uncertain=Uncertainty.refine, distribution=distributionmHDNK);
    Real mD(uncertain=Uncertainty.refine, distribution=distributionmD)=2.092 annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}})}), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}}),Bitmap(visible=true, origin={182.075,17.4625}, fileName="", imageSource="iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAACXBIWXMAAA7EAAAOxAGVKw4b
AAACj0lEQVQoFQGEAnv9AU1NTQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAABNTU3//03//////03//////03//////03//////03//////03//////01NTU0C
AAAAAACyAABOAACyAABOAACyAABOAACyAABOp6dZTk5OTk4Ap6enAACyAAAAAgAAAAAATgAA
sgAATgAAsgAATgAAsgAATgAAsqenp1lZAFlZAKenpwAATgAAAAIAAAAAALIAAE4AALIAAE4A
ALIAAE4AALIAAE4AAAAAAAAAAAAAAAAAALIAAAAEAAAAAABOAACyAABOAACyAABOAACyAABO
AACyWVmnp6enAAAAWVlZAABOAAAAAE1NTf//////Tf//////Tf//////Tf//////Tf//////
Tf//////Tf///01NTQIAAAAAAE4AALIAAE4AALJOTk5OTgAAAE4AALIAAE4AALIAAE4AALIA
AE4AAAACAAAAAACyAABOAACyTk5OWVlZWVlZTk4AAABOTk4ATk5OAACyAABOAACyAAAABAAA
AAAATgAAsk5OTllZWQAAAKenp1lZWU5Op4aGhgAAAE5OTrKysgAATgAAAAIAAAAAALJOTk5Z
WVkAAAAAAABZWVkAAABZWVl6enoAAACGhoZOTk4AALIAAAACAAAATk5OWVlZAAAAp6enAAAA
AAAAp6enAAAAWVlZenp6AAAAhoaGTk5OAAAAAgAAAFlZWQAAAAAAAFlZWaenpwAAAFlZWaen
pwAAAFlZWXp6egAAAIaGhgAAAAFNTU0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAB4KaX50xp77gAAAABJRU5ErkJggg==
", extent={{-2.075,0.0},{2.075,0.0}})}));
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={4.7313,-6.275}, fileName="logoVDI2048.png", imageSource="", extent={{-142.7312,-86.275},{142.7312,86.275}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={4.7313,-6.275}, fileName="logoVDI2048.png", imageSource="", extent={{-142.7312,-86.275},{142.7312,86.275}})}));
  equation
    mFDKEL + mFDKELL - mSPL - mSPLL + 0.4*mV=0;
    mSPL + mSPLL - mV - mHK - mA7 - mA6 - mA5=0;
    mA7 + mA6 + mA5 - mHDNK=0;
  end VDI2048Exple;

  model ObservabilityTest
    annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP1 annotation(Placement(visible=true, transformation(origin={-133.8792,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP1 annotation(Placement(visible=true, transformation(origin={134.4083,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.SwitchValve switchValve1 annotation(Placement(visible=true, transformation(origin={0.0,-33.9708}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    parameter Distribution distributionQ1=Distribution("Normal", {101.91,2.0}, {"mu","sigma"});
    parameter Distribution distributionQ2=Distribution("Normal", {64.45,2.0}, {"mu","sigma"});
    parameter Distribution distributionQ3=Distribution("Normal", {34.65,2.0}, {"mu","sigma"});
    parameter Distribution distributionQ4=Distribution("Normal", {64.2,2.0}, {"mu","sigma"});
    parameter Distribution distributionQ5=Distribution("Normal", {36.44,2.0}, {"mu","sigma"});
    parameter Distribution distributionQ6=Distribution("Normal", {98.88,2.0}, {"mu","sigma"});
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(uncertain=Uncertainty.refine, distribution=distributionQ1) annotation(Placement(visible=true, transformation(origin={-100.0,8.4125}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(uncertain=Uncertainty.refine, distribution=distributionQ2) annotation(Placement(visible=true, transformation(origin={-40.0,47.625}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3(uncertain=Uncertainty.refine, distribution=distributionQ3) annotation(Placement(visible=true, transformation(origin={40.0,47.8833}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4(uncertain=Uncertainty.refine, distribution=distributionQ4) annotation(Placement(visible=true, transformation(origin={-40.0,-32.0083}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ5(uncertain=Uncertainty.refine, distribution=distributionQ5) annotation(Placement(visible=true, transformation(origin={40.0,-32.6458}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ6(uncertain=Uncertainty.refine, distribution=distributionQ6) annotation(Placement(visible=true, transformation(origin={102.6583,7.775}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-63.5,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={64.0292,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser simpleStaticCondenser1 annotation(Placement(visible=true, transformation(origin={-0.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP2 annotation(Placement(visible=true, transformation(origin={30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2 annotation(Placement(visible=true, transformation(origin={-30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(simpleStaticCondenser1.Ec,sourceP2.C) annotation(Line(visible=true, origin={-10.6823,23.2887}, points={{4.6418,6.6771},{4.6418,-3.3386},{-9.2835,-3.3386}}, color={0,0,255}));
    connect(simpleStaticCondenser1.Sc,sinkP2.C) annotation(Line(visible=true, origin={10.6989,23.3552}, points={{-4.6584,6.7104},{-4.6584,-3.3552},{9.3168,-3.3552}}, color={0,0,255}));
    connect(sensorQ4.C1,splitter21.Cs2) annotation(Line(visible=true, origin={-56.532,-30.0086}, points={{6.0485,-9.9872},{-3.0242,-9.9872},{-3.0242,19.9744}}, color={0,0,255}));
    connect(switchValve1.C1,sensorQ4.C2) annotation(Line(visible=true, origin={-23.375,-40.0784}, points={{13.2409,-0.1825},{-3.325,-0.1825},{-3.325,0.1825},{-6.5908,0.1825}}, color={0,0,255}));
    connect(sensorQ5.C1,switchValve1.C2) annotation(Line(visible=true, origin={16.4252,-40.3223}, points={{13.0913,-0.311},{-3.3252,-0.311},{-3.3252,0.311},{-6.4409,0.311}}, color={0,0,255}));
    connect(mixer21.Ce2,sensorQ5.C2) annotation(Line(visible=true, origin={56.7017,-30.3337}, points={{3.3338,20.3994},{3.3338,-10.1997},{-6.6675,-10.1997}}, color={0,0,255}));
    connect(sensorQ6.C2,sinkP1.C) annotation(Line(visible=true, origin={119.9833,-0.0563}, points={{-7.2908,-0.0563},{1.425,-0.0563},{1.425,0.0563},{4.4407,0.0563}}, color={0,0,255}));
    connect(mixer21.Cs,sensorQ6.C1) annotation(Line(visible=true, origin={86.1095,-0.1561}, points={{-12.1959,0.0563},{3.0653,0.0563},{3.0653,-0.0563},{6.0653,-0.0563}}, color={0,0,255}));
    connect(sensorQ3.C2,mixer21.Ce1) annotation(Line(visible=true, origin={56.7017,29.9254}, points={{-6.6675,10.0704},{3.3338,10.0704},{3.3338,-20.1408}}, color={0,0,255}));
    connect(simpleStaticCondenser1.Sf,sensorQ3.C1) annotation(Line(visible=true, origin={23.1335,40.0228}, points={{-13.1492,0.1269},{3.3831,0.1269},{3.3831,-0.1269},{6.3831,-0.1269}}, color={0,0,255}));
    connect(sensorQ2.C2,simpleStaticCondenser1.Ef) annotation(Line(visible=true, origin={-16.4438,39.9436}, points={{-13.522,-0.2062},{3.4313,-0.2062},{3.4313,0.2062},{6.6593,0.2062}}, color={0,0,255}));
    connect(splitter21.Cs1,sensorQ2.C1) annotation(Line(visible=true, origin={-56.532,29.7531}, points={{-3.0242,-19.7689},{-3.0242,9.8844},{6.0485,9.8844}}, color={0,0,255}));
    connect(sensorQ1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-79.1376,0.2625}, points={{-10.8282,0.2625},{2.5376,0.2625},{2.5376,-0.2625},{5.7531,-0.2625}}, color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-115.3239,0.1876}, points={{-8.5211,-0.2375},{1.8404,-0.2375},{1.8404,0.2375},{4.8404,0.2375}}, color={0,0,255}));
  end ObservabilityTest;

  model DistillationTower
    parameter Distribution distributionF=Distribution("Normal", {1095.47,160}, {"mu","sigma"});
    parameter Distribution distributionB=Distribution("Normal", {488.23,30}, {"mu","sigma"});
    parameter Distribution distributionD1=Distribution("Normal", {478.4,30}, {"mu","sigma"});
    parameter Distribution distributionxF1=Distribution("Normal", {0.4822,0.05}, {"mu","sigma"});
    parameter Distribution distributionxF2=Distribution("Normal", {0.517,0.05}, {"mu","sigma"});
    parameter Distribution distributionxB1=Distribution("Normal", {0.0197,0.05}, {"mu","sigma"});
    parameter Distribution distributionxB2=Distribution("Normal", {0.9748,0.05}, {"mu","sigma"});
    parameter Distribution distributionxD1=Distribution("Normal", {0.941,0.05}, {"mu","sigma"});
    parameter Distribution distributionxD2=Distribution("Normal", {0.0501,0.05}, {"mu","sigma"});
    Real F(uncertain=Uncertainty.refine, distribution=distributionF)=1;
    Real B(uncertain=Uncertainty.refine, distribution=distributionB)=1;
    Real D1(uncertain=Uncertainty.refine, distribution=distributionD1);
    Real xF1(uncertain=Uncertainty.refine, distribution=distributionxF1);
    Real xF2(uncertain=Uncertainty.refine, distribution=distributionxF2);
    Real xB1(uncertain=Uncertainty.refine, distribution=distributionxB1)=1;
    Real xB2(uncertain=Uncertainty.refine, distribution=distributionxB2);
    Real xD1(uncertain=Uncertainty.refine, distribution=distributionxD1)=1;
    Real xD2(uncertain=Uncertainty.refine, distribution=distributionxD2) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    F*xF1 - B*xB1 - D1*xD1=0;
    F*xF2 - B*xB2 - D1*xD2=0;
    xF1 + xF2=1;
    xB1 + xB2=1;
    xD1 + xD2=1;
  end DistillationTower;

end DataReconciliationTests;
