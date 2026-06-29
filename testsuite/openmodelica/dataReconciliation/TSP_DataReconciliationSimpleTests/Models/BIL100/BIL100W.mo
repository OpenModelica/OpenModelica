within TSP_DataReconciliationSimpleTests.Models.BIL100;
model BIL100W
  Components.Sensors.SensorW sensorW_GV1
    annotation (Placement(transformation(extent={{-60,38},{-40,58}},rotation=0)));
  Components.Sensors.SensorW sensorW_GV2
    annotation (Placement(transformation(extent={{-60,-2},{-40,18}},rotation=0)));
  Components.Sensors.SensorW sensorW_GV3
    annotation (Placement(transformation(extent={{-60,-42},{-40,-22}},rotation=0)));
  Components.Sensors.SensorW sensorW_GV4
    annotation (Placement(transformation(extent={{-60,-82},{-40,-62}},rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Ce4
    annotation (Placement(transformation(extent={{-110,-90},{-90,-70}},rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Ce3
    annotation (Placement(transformation(extent={{-110,-50},{-90,-30}},rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Ce2
    annotation (Placement(transformation(extent={{-110,-10},{-90,10}},rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Ce1
    annotation (Placement(transformation(extent={{-110,30},{-90,50}},rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cs1
    annotation (Placement(transformation(extent={{90,30},{110,50}},rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cs2
    annotation (Placement(transformation(extent={{90,-10},{110,10}},rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cs3
    annotation (Placement(transformation(extent={{90,-50},{110,-30}},rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cs4
    annotation (Placement(transformation(extent={{90,-90},{110,-70}},rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Math.Add add
    annotation (Placement(transformation(extent={{-20,50},{0,70}},rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Math.Add add1
    annotation (Placement(transformation(extent={{-20,-30},{0,-10}},rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Blocks.Math.Add add2
    annotation (Placement(transformation(extent={{20,10},{40,30}},rotation=0)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal W_BIL100
    annotation (Placement(transformation(origin={0,104},extent={{-10,-10},{10,10}},rotation=90)));
equation
  connect(Cs2,Cs2)
    annotation (Line(points={{100,0},{100,0}},color={191,95,0}));
  connect(Ce1,sensorW_GV1.C1)
    annotation (Line(points={{-100,40},{-60,40}},color={191,95,0}));
  connect(sensorW_GV1.C2,Cs1)
    annotation (Line(points={{-40,40},{100,40}},color={191,95,0}));
  connect(Cs2,sensorW_GV2.C2)
    annotation (Line(points={{100,0},{-40,0}},color={191,95,0}));
  connect(sensorW_GV2.C1,Ce2)
    annotation (Line(points={{-60,0},{-100,0}},color={191,95,0}));
  connect(Ce3,sensorW_GV3.C1)
    annotation (Line(points={{-100,-40},{-60,-40}},color={191,95,0}));
  connect(sensorW_GV3.C2,Cs3)
    annotation (Line(points={{-40,-40},{100,-40}},color={191,95,0}));
  connect(Cs4,sensorW_GV4.C2)
    annotation (Line(points={{100,-80},{-40,-80}},color={191,95,0}));
  connect(sensorW_GV4.C1,Ce4)
    annotation (Line(points={{-60,-80},{-100,-80}},color={191,95,0}));
  connect(sensorW_GV1.Measure,add.u1)
    annotation (Line(points={{-50,58.2},{-50,66},{-21,66}}));
  connect(sensorW_GV2.Measure,add.u2)
    annotation (Line(points={{-50,18.2},{-50,26},{-28,26},{-28,54},{-21,54}}));
  connect(sensorW_GV3.Measure,add1.u1)
    annotation (Line(points={{-50,-21.8},{-50,-14},{-21,-14}}));
  connect(sensorW_GV4.Measure,add1.u2)
    annotation (Line(points={{-50,-61.8},{-50,-54},{-28,-54},{-28,-26},{-21,-26}}));
  connect(add.y,add2.u1)
    annotation (Line(points={{1,60},{10,60},{10,26},{19,26}}));
  connect(add1.y,add2.u2)
    annotation (Line(points={{1,-20},{10,-20},{10,14},{19,14}}));
  connect(add2.y,W_BIL100)
    annotation (Line(points={{41,20},{60,20},{60,80},{0,80},{0,104}}));
  annotation (
    Diagram(
      graphics),
    Icon);
end BIL100W;
