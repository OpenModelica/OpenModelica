package DataReconciliationTests
  model ThermoSysProSimpleExple

    parameter Real rho=1000;
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP1 annotation(Placement(visible=true, transformation(origin={-140.0,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP1 annotation(Placement(visible=true, transformation(origin={136.0591,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss1(K=0.0001, p_rho=
          rho)                                                                          annotation(Placement(visible=true, transformation(origin={-80.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-44.0534,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={43.7284,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss2(K=0.0001, p_rho=
          rho)                                                                          annotation(Placement(visible=true, transformation(origin={10.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss3(K=0.0001, p_rho=
          rho)                                                                          annotation(Placement(visible=true, transformation(origin={10.0,-20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.PipePressureLoss pipePressureLoss4(K=0.0001, p_rho=
          rho)                                                                          annotation(Placement(visible=true, transformation(origin={110.0,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q(uncertain=Uncertainty.refine))
                                                                                     annotation(Placement(visible=true, transformation(origin={-20,
              27.8184},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3(Q(
                                                     uncertain = Uncertainty.refine))
                                                                                     annotation(Placement(visible=true, transformation(origin={-20,
              -11.9274},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(
                                                     uncertain = Uncertainty.refine))
                                                                                     annotation(Placement(visible=true, transformation(origin={-110,
              8.1168},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4(Q(
                                                     uncertain = Uncertainty.refine))
                                                                                     annotation(Placement(visible=true, transformation(origin={80,
              8.1168},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(sensorQ4.C2,pipePressureLoss4.C1) annotation(Line(visible=true, origin={95.4854,-0.1703}, points={{-5.2854,
            0.2871},{0.6599,0.2871},{0.6599,0.1703},{4.5146,0.1703}},                                                                                                    color={0,0,255}));
    connect(mixer21.Cs,sensorQ4.C1) annotation(Line(visible=true, origin={64.3305,-0.2621}, points={{
            -10.6021,0.2621},{2.4753,0.2621},{2.4753,0.3789},{5.6695,0.3789}},                                                                                            color={0,0,255}));
    connect(sensorQ3.C2,pipePressureLoss3.C1) annotation(Line(visible=true, origin={-4.5146,-20.1924}, points={{-5.2854,
            0.265},{0.6599,0.265},{0.6599,0.1924},{4.5146,0.1924}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2, pipePressureLoss2.C1)
                                              annotation(Line(visible=true, origin={-4.5146,20.1805}, points={{-5.2854,
            -0.3621},{0.6599,-0.3621},{0.6599,-0.1805},{4.5146,-0.1805}},                                                                                                  color={0,0,255}));
    connect(splitter21.Cs2,sensorQ3.C1) annotation(Line(visible=true, origin={-36.7652,-16.9235}, points={{-3.2882,
            6.9235},{-3.2882,-3.0039},{6.7652,-3.0039}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1, sensorQ2.C1)
                                        annotation(Line(visible=true, origin={-36.7652,16.8889}, points={{-3.2882,
            -6.8889},{-3.2882,2.9295},{6.7652,2.9295}},                                                                                                   color={0,0,255}));
    connect(sensorQ1.C2,pipePressureLoss1.C1) annotation(Line(visible=true, origin={-94.5146,-0.1703}, points={{-5.2854,
            0.2871},{0.6599,0.2871},{0.6599,0.1703},{4.5146,0.1703}},                                                                                                    color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-123.9998,-0.3639}, points={{-6.0002,
            0.3639},{0.8056,0.3639},{0.8056,0.4807},{3.9998,0.4807}},                                                                                                    color={0,0,255}));
    connect(pipePressureLoss1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-59.2678,-0.0}, points={{
            -10.7322,0},{2.1144,0},{5.2144,0}},                                                                                                    color={0,0,255}));
    connect(pipePressureLoss3.C2,mixer21.Ce2) annotation(Line(visible=true, origin={33.5937,-16.7254}, points={{
            -13.5937,-3.2746},{6.1347,-3.2746},{6.1347,6.7254}},                                                                                                    color={0,0,255}));
    connect(pipePressureLoss2.C2,mixer21.Ce1) annotation(Line(visible=true, origin={33.5485,16.5671}, points={{
            -13.5485,3.4329},{6.1799,3.4329},{6.1799,-6.5671}},                                                                                                    color={0,0,255}));
    connect(pipePressureLoss4.C2,sinkP1.C) annotation(Line(visible=true, origin={124.024,-0.1018}, points={{-4.024,
            0.1018},{0.6553,0.1018},{2.0351,0.1018}},                                                                                                    color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-148.5,-105},{148.5,105}},     preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics),
        DymolaStoredErrors);
  end ThermoSysProSimpleExple;

  model FlatSimpleExple
    Real q1(uncertain=Uncertainty.refine)=1;
    Real q2(uncertain=Uncertainty.refine)=2;
    Real q3(uncertain=Uncertainty.refine);
    Real q4(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    q1=q2 + q3;
    q4=q2 + q3;
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724},
              fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
              =                                                                                                    "Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625},
              fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
              =                                                                                                    "Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146},
              fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
              =                                                                                                    "Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854},
              fillPattern =                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString
              =                                                                                                    "Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Line(visible=true, origin={-50.0,0.0}, points={{-20.0,0.0},{20.0,0.0}}),Line(visible=true, origin={60.0,0.0}, points={{-30.0,0.0},{30.0,0.0}}),Rectangle(visible=true, fillColor={255,255,255}, extent={{-30.0,-20.0},{30.0,20.0}}),Text(visible=true, origin={-51.9844,11.724},
              fillPattern=                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString=
                                                                                                    "Q1", fontName="Arial"),Text(visible=true, origin={0.0,32.0625},
              fillPattern=                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString=
                                                                                                    "Q2", fontName="Arial"),Text(visible=true, origin={0.0,-7.6146},
              fillPattern=                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString=
                                                                                                    "Q3", fontName="Arial"),Text(visible=true, origin={46.3542,11.3854},
              fillPattern=                                                                                                    FillPattern.Solid, extent={{-4.9609,-4.9609},{4.9609,4.9609}}, textString=
                                                                                                    "Q4", fontName="Arial"),Line(visible=true, origin={-53.4427,2.3151}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-53.4427,-2.6849}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,22.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,17.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={-3.4427,-17.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={-3.4427,-22.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}}),Line(visible=true, origin={46.5573,2.5}, points={{3.4427,-2.3151},{-3.4427,2.3151}}),Line(visible=true, origin={46.5573,-2.5}, points={{3.4427,2.3151},{-3.4427,-2.3151}})}));
  end FlatSimpleExple;

  model VDI2048Exple
    Real mFDKEL(uncertain=Uncertainty.refine)=46.241;
    Real mFDKELL(uncertain=Uncertainty.refine)=45.668;
    Real mSPL(uncertain=Uncertainty.refine)=44.575;
    Real mSPLL(uncertain=Uncertainty.refine)=44.319;
    Real mV(uncertain=Uncertainty.refine);
    Real mHK(uncertain=Uncertainty.refine)=69.978;
    Real mA7(uncertain=Uncertainty.refine)=10.364;
    Real mA6(uncertain=Uncertainty.refine)=3.744;
    Real mA5(uncertain=Uncertainty.refine);
    Real mHDNK(uncertain=Uncertainty.refine);
    Real mD(uncertain=Uncertainty.refine)=2.092 annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}})}), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={5.278,-0.8412}, fileName="../../VDI2048.png", imageSource="", extent={{-124.722,-80.8412},{124.722,80.8412}}),Bitmap(visible=true, origin={182.075,17.4625}, fileName="", imageSource="iVBORw0KGgoAAAANSUhEUgAAAA8AAAAOCAIAAAB/6NG4AAAACXBIWXMAAA7EAAAOxAGVKw4b
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
  equation
    mFDKEL + mFDKELL - mSPL - mSPLL + 0.4*mV=0;
    mSPL + mSPLL - mV - mHK - mA7 - mA6 - mA5=0;
    mA7 + mA6 + mA5 - mHDNK=0;
    annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={4.7313,-6.275}, fileName="logoVDI2048.png",
              imageSource =                                                                                                    "", extent={{-142.7312,-86.275},{142.7312,86.275}})}), Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Bitmap(visible=true, origin={4.7313,-6.275}, fileName="logoVDI2048.png",
              imageSource=                                                                                                    "", extent={{-142.7312,-86.275},{142.7312,86.275}})}));
  end VDI2048Exple;


  model DistillationTower
    Real F(uncertain=Uncertainty.refine)=1;
    Real B(uncertain=Uncertainty.refine)=1;
    Real T(uncertain=Uncertainty.refine);
    Real xF1(uncertain=Uncertainty.refine);
    Real xF2(uncertain=Uncertainty.refine);
    Real xB1(uncertain=Uncertainty.refine)=1;
    Real xB2(uncertain=Uncertainty.refine);
    Real xT1(uncertain=Uncertainty.refine)=1;
    Real xT2(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    F*xF1 - B*xB1 - T*xT1=0;
    F*xF2 - B*xB2 - T*xT2=0;
    xF1 + xF2=100;
    xB1 + xB2=100;
    xT1 + xT2=100;
  end DistillationTower;

  model RedundancyTestCase1
    Real x1(uncertain=Uncertainty.refine)=1;
    Real x2(uncertain=Uncertainty.refine)=2;
    Real x3;
    Real x4;
    Real x5(uncertain=Uncertainty.refine);
    Real x6(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1-x2-x3 = 0;
    x2-x4 = 0;
    x3-x5 = 0;
    x4+x5-x6 = 0;
  end RedundancyTestCase1;

  model RedundancyTestCase2
    Real x1(uncertain=Uncertainty.refine)=1;
    Real x2(uncertain=Uncertainty.refine)=2;
    Real x3;
    Real x4;
    Real x5;
    Real x6                               annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1-x2-x3 = 0;
    x2-x4 = 0;
    x3-x5 = 0;
    x4+x5-x6 = 0;
  end RedundancyTestCase2;

  model RedundancyTestCase3
    Real x1(uncertain=Uncertainty.refine)=1;
    Real x2=2;
    Real x3;
    Real x4;
    Real x5;
    Real x6(uncertain=Uncertainty.refine) annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1-x2-x3 = 0;
    x2-x4 = 0;
    x3-x5 = 0;
    x4+x5-x6 = 0;
  end RedundancyTestCase3;

  model ExtractionSetSTest
    Real x1(uncertain=Uncertainty.refine);
    Real x2(uncertain=Uncertainty.refine);
    Real x3(uncertain=Uncertainty.refine);
    Real y1;
    Real y2;
    Real y3                               annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1+x2 = 0;
    x1-x2 = 0;
    y1 = x2+2*x3;
    x3-y1+y2=x2;
    y2+y3=0;
    y2-2*y3=3;
  end ExtractionSetSTest;

  model ExtractionSetS_NL_Test
    Real x1(uncertain=Uncertainty.refine);
    Real x2(uncertain=Uncertainty.refine);
    Real x3(uncertain=Uncertainty.refine);
    Real y1;
    Real y2;
    Real y3                               annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1+x2 = 0;
    x1-x2 = 0;
    y1 = x2+2*x3;
    x3-y1+y2=x2;
    y2+y3=0;
    y2*y3=3;
  end ExtractionSetS_NL_Test;

  // NEW TEST CASES
  model TwoFlows
    Real Q1(uncertain=Uncertainty.refine);
	Real Q2(uncertain=Uncertainty.refine);
	Real Q3(uncertain=Uncertainty.refine);
    Real Q4(uncertain=Uncertainty.refine);
    Real y1, a;
  equation
	  y1 = 2;       // Eq1
	  a = 0.5;      // Eq2
	  Q1 = y1;      // Eq3
	  Q2 = a*y1 annotation(__OpenModelica_ApproximatedEquation=true); // Eq4 uncertain
	  Q1 = Q2 + Q3; // Eq5
	  Q4 = Q1 + Q2; // Eq6
  end TwoFlows;

  model Splitter
	 Real Q(uncertain=Uncertainty.refine);
	 Real Q1(uncertain=Uncertainty.refine);
	 Real Q2(uncertain=Uncertainty.refine);
	 Real y, y1, y2, a;
	 Real A, Y;
  equation
     Y = 2;       // Eq1
     y = Y;       // Eq2
     A = 0.5;     // Eq3
     a = A;       // Eq4
     y1 = a*y;    // Eq5
     y = y1 + y2; // Eq6
     Q = y;       // Eq7
     Q1 = y1;     // Eq8
     Q2 = y2;     // Eq9
  end Splitter;


  model Splitter1
	  Real Q1(uncertain=Uncertainty.refine);
      Real Q2(uncertain=Uncertainty.refine);
      Real Q3(uncertain=Uncertainty.refine);
	  Real P01,P02,P03,T1_P1,T2_P2,T3_P2,T1_P2,T2_P1;
	  Real T3_P1,V_Q1,V_Q2,V_Q3,T1_Q2,T2_Q1,T3_Q1,V_P1,P,V_P2,V_P3,T1_Q1,T2_Q2,T3_Q2;
  equation
	  P01 = 3;			// Eq1
	  P02 = 1;			// Eq2
	  P03 = 1;			// Eq3
	  T1_P1 = P01;		// Eq4
	  T2_P2 = P02;		// Eq5
	  T3_P2 = P03;		// Eq6
	  T1_P1 - T1_P2 = Q1^2 annotation(__OpenModelica_ApproximatedEquation=true); // Eq7
	  T2_P1 - T2_P2 = Q2^2 annotation(__OpenModelica_ApproximatedEquation=true);// Eq8
	  T3_P1 - T3_P2 = Q3^2 annotation(__OpenModelica_ApproximatedEquation=true); // Eq9
	  V_Q1 = V_Q2 + V_Q3; // Eq10
	  V_Q1 = T1_Q2;	 	// Eq11
	  T1_Q2 = Q1;		// Eq12
	  V_Q2 = T2_Q1;	 	// Eq13
	  T2_Q1 = Q2;		// Eq14
	  V_Q3 = T3_Q1;	 	// Eq15
	  T3_Q1 = Q3;		// Eq16
	  T1_P2 = V_P1;	 	// Eq17
	  V_P1 = P;			// Eq18
	  T2_P1 = V_P2 ;	// Eq19
	  V_P2 = P; 		// Eq20
	  T3_P1 = V_P3;	 	// Eq21
	  V_P3 = P;			// Eq22
	  T1_Q1 = Q1;		// Eq23
	  T2_Q2 = Q2;  		// Eq24
	  T3_Q2 = Q3;  		// Eq25
  end Splitter1;

  model Pipe1
    Real p;
    Real Q1(uncertain=Uncertainty.refine);
	Real Q2(uncertain=Uncertainty.refine);
  equation
    p=2;
    Q1 = Q2;
    Q1 = p;
  end Pipe1;

  model Pipe2
    Real p;
    Real Q1(uncertain=Uncertainty.refine);
	Real Q2(uncertain=Uncertainty.refine);
    Real y1, y2;
  equation
    p=2;
    Q1 = y1;
    Q2 = Q1; // Eq2
    y1 = y2; // Eq3
    Q1 = p;  // Eq4
  end Pipe2;

  model Pipe3
    Real p=2;
    Real Q1(uncertain=Uncertainty.refine);
	Real Q2(uncertain=Uncertainty.refine);
    Real y1, y2;
  equation
    Q1 = y1; // Eq1
    Q2 = y2; // Eq2
    y1 = y2; // Eq3
    Q1 = p;  // Eq4
  end Pipe3;

  model Pipe4
    Real p;
    Real q;
    Real Q1(uncertain=Uncertainty.refine);
    Real Q2(uncertain=Uncertainty.refine);
    Real y1, y2;
  equation
    p=2;
    q=1;
    Q1 = y1;   // Eq1
    Q2 = q*y2; // Eq2
    y1 = y2;   // Eq3
    Q1 = q*p;  // Eq4
  end Pipe4;

  model Pipe5
    Real p;
    Real q;
    Real Q1(uncertain=Uncertainty.refine);
    Real Q2(uncertain=Uncertainty.refine);
    Real y1, y2;
  equation
    p=2;
    q=1;
    Q1 = y1;   // Eq1
    Q2 = q*y2; // Eq2
    y1 = q*y2; // Eq3
    Q1 = p;    // Eq4
  end Pipe5;

  model ExtractionSetSTest2
    Real x1(uncertain=Uncertainty.refine);
    Real x2(uncertain=Uncertainty.refine);
    Real x3(uncertain=Uncertainty.refine);
    Real y1;
    Real y2;
    Real y3;
    Real z1;
    Real z2;
    Real z3;
    Real z4;
    Real z5 annotation(Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  equation
    x1 + x2 = 0;
    x1 - x2 = 0;
    y1 = x2 + 2*x3;
    x3 - y1 + y2 = x2;
    y2 + y3 = 0;
    y2 - 2*y3 = 3;
    z1 + z2 + z3 + y3 = 2;
    z2 + 2*z3 = x1 - x2;
    z3 = 2*x3;
    y1 + y2 + z4 = x2 + 3*x3 annotation(__OpenModelica_ApproximatedEquation=true);
    z4 - z5 = x1 - x3;
  end ExtractionSetSTest2;


  model ThermoSysProRedundancyTest1

    ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceP1(P0=300000, Q0=500)
                                                                annotation(Placement(visible=true, transformation(origin={-133.8792,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.Sink  sinkP1 annotation(Placement(visible=true, transformation(origin={134.408,
              0},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss
                                                       switchValve1 annotation(Placement(visible=true, transformation(origin={0,
              -39.9708},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-100,
              7.9125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-40,
              48.125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4                                 annotation(Placement(visible=true, transformation(origin={40.0,47.8833}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3                                 annotation(Placement(visible=true, transformation(origin={-40.0,-32.0083}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ5(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={40,
              -32.1458},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ6(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={102.658,
              8.275},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-63.5,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={64.0292,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser
      simpleStaticCondenser1                                                            annotation(Placement(visible=true, transformation(origin={-0.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP2 annotation(Placement(visible=true, transformation(origin={30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2(T0=400)
                                                                annotation(Placement(visible=true, transformation(origin={-30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(simpleStaticCondenser1.Ec,sourceP2.C) annotation(Line(visible=true, origin={-10.6823,23.2887}, points={{4.6823,
            6.7113},{4.6823,-3.2887},{-9.3177,-3.2887}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sc,sinkP2.C) annotation(Line(visible=true, origin={10.6989,23.3552}, points={{-4.6989,
            6.6448},{-4.6989,-3.3552},{9.3011,-3.3552}},                                                                                                    color={0,0,255}));
    connect(sensorQ3.C1,splitter21.Cs2) annotation(Line(visible=true, origin={-56.532,-30.0086}, points={{6.532,
            -9.9997},{-2.968,-9.9997},{-2.968,20.0086}},                                                                                                    color={0,0,255}));
    connect(switchValve1.C1,sensorQ3.C2) annotation(Line(visible=true, origin={-23.375,-40.0784}, points={{13.375,
            0.1076},{-3.325,0.1076},{-3.325,0.0701},{-6.425,0.0701}},                                                                                                    color={0,0,255}));
    connect(sensorQ5.C1,switchValve1.C2) annotation(Line(visible=true, origin={16.4252,-40.3223}, points={{13.5748,
            0.1765},{-3.3252,0.1765},{-3.3252,0.3515},{-6.4252,0.3515}},                                                                                                    color={0,0,255}));
    connect(mixer21.Ce2,sensorQ5.C2) annotation(Line(visible=true, origin={56.7017,-30.3337}, points={{3.3275,
            20.3337},{3.3275,-9.8121},{-6.5017,-9.8121}},                                                                                                    color={0,0,255}));
    connect(sensorQ6.C2,sinkP1.C) annotation(Line(visible=true, origin={119.9833,-0.0563}, points={{-7.1253,
            0.3313},{1.425,0.3313},{1.425,0.0563},{4.4247,0.0563}},                                                                                                   color={0,0,255}));
    connect(mixer21.Cs,sensorQ6.C1) annotation(Line(visible=true, origin={86.1095,-0.1561}, points={{
            -12.0803,0.1561},{3.0653,0.1561},{3.0653,0.4311},{6.5485,0.4311}},                                                                                            color={0,0,255}));
    connect(sensorQ4.C2, mixer21.Ce1)
                                     annotation(Line(visible=true, origin={56.7017,29.9254}, points={{-6.5017,
            9.9579},{3.3275,9.9579},{3.3275,-19.9254}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sf, sensorQ4.C1)
                                                   annotation(Line(visible=true, origin={23.1335,40.0228}, points={{
            -13.1335,-0.1228},{3.3831,-0.1228},{3.3831,-0.1395},{6.8665,-0.1395}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2,simpleStaticCondenser1.Ef) annotation(Line(visible=true, origin={-16.4438,39.9436}, points={{
            -13.3562,0.1814},{3.4313,0.1814},{3.4313,0.0564},{6.4438,0.0564}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1,sensorQ2.C1) annotation(Line(visible=true, origin={-56.532,29.7531}, points={{-2.968,
            -19.7531},{-2.968,10.3719},{6.532,10.3719}},                                                                                                  color={0,0,255}));
    connect(sensorQ1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-79.1376,0.2625}, points={{
            -10.6624,-0.35},{2.5376,-0.35},{2.5376,-0.2625},{5.6376,-0.2625}},                                                                                               color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-115.3239,0.1876}, points={{-8.5553,
            -0.1876},{1.8404,-0.1876},{1.8404,-0.2751},{5.3239,-0.2751}},                                                                                                 color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-150,-105},{150,105}},         preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics));
  end ThermoSysProRedundancyTest1;

  model ThermoSysProRedundancyTest2

    ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceP1(P0=300000, Q0=500)
                                                                annotation(Placement(visible=true, transformation(origin={-133.8792,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.Sink  sinkP1 annotation(Placement(visible=true, transformation(origin={134.408,
              0},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss
                                                       switchValve1 annotation(Placement(visible=true, transformation(origin={0,
              -39.9708},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-100,
              7.9125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-40,
              48.125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4                                 annotation(Placement(visible=true, transformation(origin={40.0,47.8833}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3                                 annotation(Placement(visible=true, transformation(origin={-40.0,-32.0083}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ5                                 annotation(Placement(visible=true, transformation(origin={40,
              -32.1458},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ6                                 annotation(Placement(visible=true, transformation(origin={102.658,
              8.275},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-63.5,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={64.0292,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser
      simpleStaticCondenser1                                                            annotation(Placement(visible=true, transformation(origin={-0.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP2 annotation(Placement(visible=true, transformation(origin={30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2(T0=400)
                                                                annotation(Placement(visible=true, transformation(origin={-30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(simpleStaticCondenser1.Ec,sourceP2.C) annotation(Line(visible=true, origin={-10.6823,23.2887}, points={{4.6823,
            6.7113},{4.6823,-3.2887},{-9.3177,-3.2887}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sc,sinkP2.C) annotation(Line(visible=true, origin={10.6989,23.3552}, points={{-4.6989,
            6.6448},{-4.6989,-3.3552},{9.3011,-3.3552}},                                                                                                    color={0,0,255}));
    connect(sensorQ3.C1,splitter21.Cs2) annotation(Line(visible=true, origin={-56.532,-30.0086}, points={{6.532,
            -9.9997},{-2.968,-9.9997},{-2.968,20.0086}},                                                                                                    color={0,0,255}));
    connect(switchValve1.C1,sensorQ3.C2) annotation(Line(visible=true, origin={-23.375,-40.0784}, points={{13.375,
            0.1076},{-3.325,0.1076},{-3.325,0.0701},{-6.425,0.0701}},                                                                                                    color={0,0,255}));
    connect(sensorQ5.C1,switchValve1.C2) annotation(Line(visible=true, origin={16.4252,-40.3223}, points={{13.5748,
            0.1765},{-3.3252,0.1765},{-3.3252,0.3515},{-6.4252,0.3515}},                                                                                                    color={0,0,255}));
    connect(mixer21.Ce2,sensorQ5.C2) annotation(Line(visible=true, origin={56.7017,-30.3337}, points={{3.3275,
            20.3337},{3.3275,-9.8121},{-6.5017,-9.8121}},                                                                                                    color={0,0,255}));
    connect(sensorQ6.C2,sinkP1.C) annotation(Line(visible=true, origin={119.9833,-0.0563}, points={{-7.1253,
            0.3313},{1.425,0.3313},{1.425,0.0563},{4.4247,0.0563}},                                                                                                   color={0,0,255}));
    connect(mixer21.Cs,sensorQ6.C1) annotation(Line(visible=true, origin={86.1095,-0.1561}, points={{
            -12.0803,0.1561},{3.0653,0.1561},{3.0653,0.4311},{6.5485,0.4311}},                                                                                            color={0,0,255}));
    connect(sensorQ4.C2, mixer21.Ce1)
                                     annotation(Line(visible=true, origin={56.7017,29.9254}, points={{-6.5017,
            9.9579},{3.3275,9.9579},{3.3275,-19.9254}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sf, sensorQ4.C1)
                                                   annotation(Line(visible=true, origin={23.1335,40.0228}, points={{
            -13.1335,-0.1228},{3.3831,-0.1228},{3.3831,-0.1395},{6.8665,-0.1395}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2,simpleStaticCondenser1.Ef) annotation(Line(visible=true, origin={-16.4438,39.9436}, points={{
            -13.3562,0.1814},{3.4313,0.1814},{3.4313,0.0564},{6.4438,0.0564}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1,sensorQ2.C1) annotation(Line(visible=true, origin={-56.532,29.7531}, points={{-2.968,
            -19.7531},{-2.968,10.3719},{6.532,10.3719}},                                                                                                  color={0,0,255}));
    connect(sensorQ1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-79.1376,0.2625}, points={{
            -10.6624,-0.35},{2.5376,-0.35},{2.5376,-0.2625},{5.6376,-0.2625}},                                                                                               color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-115.3239,0.1876}, points={{-8.5553,
            -0.1876},{1.8404,-0.1876},{1.8404,-0.2751},{5.3239,-0.2751}},                                                                                                 color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-150,-105},{150,105}},         preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics));
  end ThermoSysProRedundancyTest2;

  model ThermoSysProRedundancyTest3

    ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceP1(P0=300000, Q0=500)
                                                                annotation(Placement(visible=true, transformation(origin={-133.8792,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.Sink  sinkP1 annotation(Placement(visible=true, transformation(origin={134.408,
              0},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss
                                                       switchValve1 annotation(Placement(visible=true, transformation(origin={0,
              -39.9708},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-100,
              7.9125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2                                 annotation(Placement(visible=true, transformation(origin={-40,
              48.125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4                                 annotation(Placement(visible=true, transformation(origin={40.0,47.8833}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3                                 annotation(Placement(visible=true, transformation(origin={-40.0,-32.0083}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ5                                 annotation(Placement(visible=true, transformation(origin={40,
              -32.1458},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ6(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={102.658,
              8.275},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-63.5,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={64.0292,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser
      simpleStaticCondenser1                                                            annotation(Placement(visible=true, transformation(origin={-0.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP2 annotation(Placement(visible=true, transformation(origin={30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2(T0=400)
                                                                annotation(Placement(visible=true, transformation(origin={-30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(simpleStaticCondenser1.Ec,sourceP2.C) annotation(Line(visible=true, origin={-10.6823,23.2887}, points={{4.6823,
            6.7113},{4.6823,-3.2887},{-9.3177,-3.2887}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sc,sinkP2.C) annotation(Line(visible=true, origin={10.6989,23.3552}, points={{-4.6989,
            6.6448},{-4.6989,-3.3552},{9.3011,-3.3552}},                                                                                                    color={0,0,255}));
    connect(sensorQ3.C1,splitter21.Cs2) annotation(Line(visible=true, origin={-56.532,-30.0086}, points={{6.532,
            -9.9997},{-2.968,-9.9997},{-2.968,20.0086}},                                                                                                    color={0,0,255}));
    connect(switchValve1.C1,sensorQ3.C2) annotation(Line(visible=true, origin={-23.375,-40.0784}, points={{13.375,
            0.1076},{-3.325,0.1076},{-3.325,0.0701},{-6.425,0.0701}},                                                                                                    color={0,0,255}));
    connect(sensorQ5.C1,switchValve1.C2) annotation(Line(visible=true, origin={16.4252,-40.3223}, points={{13.5748,
            0.1765},{-3.3252,0.1765},{-3.3252,0.3515},{-6.4252,0.3515}},                                                                                                    color={0,0,255}));
    connect(mixer21.Ce2,sensorQ5.C2) annotation(Line(visible=true, origin={56.7017,-30.3337}, points={{3.3275,
            20.3337},{3.3275,-9.8121},{-6.5017,-9.8121}},                                                                                                    color={0,0,255}));
    connect(sensorQ6.C2,sinkP1.C) annotation(Line(visible=true, origin={119.9833,-0.0563}, points={{-7.1253,
            0.3313},{1.425,0.3313},{1.425,0.0563},{4.4247,0.0563}},                                                                                                   color={0,0,255}));
    connect(mixer21.Cs,sensorQ6.C1) annotation(Line(visible=true, origin={86.1095,-0.1561}, points={{
            -12.0803,0.1561},{3.0653,0.1561},{3.0653,0.4311},{6.5485,0.4311}},                                                                                            color={0,0,255}));
    connect(sensorQ4.C2, mixer21.Ce1)
                                     annotation(Line(visible=true, origin={56.7017,29.9254}, points={{-6.5017,
            9.9579},{3.3275,9.9579},{3.3275,-19.9254}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sf, sensorQ4.C1)
                                                   annotation(Line(visible=true, origin={23.1335,40.0228}, points={{
            -13.1335,-0.1228},{3.3831,-0.1228},{3.3831,-0.1395},{6.8665,-0.1395}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2,simpleStaticCondenser1.Ef) annotation(Line(visible=true, origin={-16.4438,39.9436}, points={{
            -13.3562,0.1814},{3.4313,0.1814},{3.4313,0.0564},{6.4438,0.0564}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1,sensorQ2.C1) annotation(Line(visible=true, origin={-56.532,29.7531}, points={{-2.968,
            -19.7531},{-2.968,10.3719},{6.532,10.3719}},                                                                                                  color={0,0,255}));
    connect(sensorQ1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-79.1376,0.2625}, points={{
            -10.6624,-0.35},{2.5376,-0.35},{2.5376,-0.2625},{5.6376,-0.2625}},                                                                                               color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-115.3239,0.1876}, points={{-8.5553,
            -0.1876},{1.8404,-0.1876},{1.8404,-0.2751},{5.3239,-0.2751}},                                                                                                 color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-150,-105},{150,105}},         preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics));
  end ThermoSysProRedundancyTest3;

  model ThermoSysProRedundancyTest4

    ThermoSysPro.WaterSteam.BoundaryConditions.SourcePQ sourceP1(P0=300000, Q0=500)
                                                                annotation(Placement(visible=true, transformation(origin={-133.8792,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.Sink  sinkP1 annotation(Placement(visible=true, transformation(origin={134.408,
              0},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.PressureLosses.SingularPressureLoss
                                                       switchValve1 annotation(Placement(visible=true, transformation(origin={0,
              -39.9708},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ1(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={-100,
              7.9125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ2(Q(uncertain = Uncertainty.refine))                                 annotation(Placement(visible=true, transformation(origin={-40,
              48.125},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ4(Q(uncertain = Uncertainty.refine))                                 annotation(Placement(visible=true, transformation(origin={40.0,47.8833}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ3(Q(uncertain = Uncertainty.refine))                                 annotation(Placement(visible=true, transformation(origin={-40.0,-32.0083}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ5(Q(uncertain = Uncertainty.refine))                                 annotation(Placement(visible=true, transformation(origin={40,
              -32.1458},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Sensors.SensorQ sensorQ6(Q(uncertain = Uncertainty.refine)) annotation(Placement(visible=true, transformation(origin={102.658,
              8.275},                                                                                                    extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Splitter2 splitter21 annotation(Placement(visible=true, transformation(origin={-63.5,-0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.Junctions.Mixer2 mixer21 annotation(Placement(visible=true, transformation(origin={64.0292,0.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.HeatExchangers.SimpleStaticCondenser
      simpleStaticCondenser1                                                            annotation(Placement(visible=true, transformation(origin={-0.0,40.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SinkP sinkP2 annotation(Placement(visible=true, transformation(origin={30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
    ThermoSysPro.WaterSteam.BoundaryConditions.SourceP sourceP2(T0=400)
                                                                annotation(Placement(visible=true, transformation(origin={-30.0,20.0}, extent={{-10.0,-10.0},{10.0,10.0}}, rotation=0)));
  equation
    connect(simpleStaticCondenser1.Ec,sourceP2.C) annotation(Line(visible=true, origin={-10.6823,23.2887}, points={{4.6823,
            6.7113},{4.6823,-3.2887},{-9.3177,-3.2887}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sc,sinkP2.C) annotation(Line(visible=true, origin={10.6989,23.3552}, points={{-4.6989,
            6.6448},{-4.6989,-3.3552},{9.3011,-3.3552}},                                                                                                    color={0,0,255}));
    connect(sensorQ3.C1,splitter21.Cs2) annotation(Line(visible=true, origin={-56.532,-30.0086}, points={{6.532,
            -9.9997},{-2.968,-9.9997},{-2.968,20.0086}},                                                                                                    color={0,0,255}));
    connect(switchValve1.C1,sensorQ3.C2) annotation(Line(visible=true, origin={-23.375,-40.0784}, points={{13.375,
            0.1076},{-3.325,0.1076},{-3.325,0.0701},{-6.425,0.0701}},                                                                                                    color={0,0,255}));
    connect(sensorQ5.C1,switchValve1.C2) annotation(Line(visible=true, origin={16.4252,-40.3223}, points={{13.5748,
            0.1765},{-3.3252,0.1765},{-3.3252,0.3515},{-6.4252,0.3515}},                                                                                                    color={0,0,255}));
    connect(mixer21.Ce2,sensorQ5.C2) annotation(Line(visible=true, origin={56.7017,-30.3337}, points={{3.3275,
            20.3337},{3.3275,-9.8121},{-6.5017,-9.8121}},                                                                                                    color={0,0,255}));
    connect(sensorQ6.C2,sinkP1.C) annotation(Line(visible=true, origin={119.9833,-0.0563}, points={{-7.1253,
            0.3313},{1.425,0.3313},{1.425,0.0563},{4.4247,0.0563}},                                                                                                   color={0,0,255}));
    connect(mixer21.Cs,sensorQ6.C1) annotation(Line(visible=true, origin={86.1095,-0.1561}, points={{
            -12.0803,0.1561},{3.0653,0.1561},{3.0653,0.4311},{6.5485,0.4311}},                                                                                            color={0,0,255}));
    connect(sensorQ4.C2, mixer21.Ce1)
                                     annotation(Line(visible=true, origin={56.7017,29.9254}, points={{-6.5017,
            9.9579},{3.3275,9.9579},{3.3275,-19.9254}},                                                                                                    color={0,0,255}));
    connect(simpleStaticCondenser1.Sf, sensorQ4.C1)
                                                   annotation(Line(visible=true, origin={23.1335,40.0228}, points={{
            -13.1335,-0.1228},{3.3831,-0.1228},{3.3831,-0.1395},{6.8665,-0.1395}},                                                                                                    color={0,0,255}));
    connect(sensorQ2.C2,simpleStaticCondenser1.Ef) annotation(Line(visible=true, origin={-16.4438,39.9436}, points={{
            -13.3562,0.1814},{3.4313,0.1814},{3.4313,0.0564},{6.4438,0.0564}},                                                                                                    color={0,0,255}));
    connect(splitter21.Cs1,sensorQ2.C1) annotation(Line(visible=true, origin={-56.532,29.7531}, points={{-2.968,
            -19.7531},{-2.968,10.3719},{6.532,10.3719}},                                                                                                  color={0,0,255}));
    connect(sensorQ1.C2,splitter21.Ce) annotation(Line(visible=true, origin={-79.1376,0.2625}, points={{
            -10.6624,-0.35},{2.5376,-0.35},{2.5376,-0.2625},{5.6376,-0.2625}},                                                                                               color={0,0,255}));
    connect(sourceP1.C,sensorQ1.C1) annotation(Line(visible=true, origin={-115.3239,0.1876}, points={{-8.5553,
            -0.1876},{1.8404,-0.1876},{1.8404,-0.2751},{5.3239,-0.2751}},                                                                                                 color={0,0,255}));
    annotation(Diagram(coordinateSystem(extent={{-150,-105},{150,105}},         preserveAspectRatio=true, initialScale=0.1, grid={1,1}),
          graphics));
  end ThermoSysProRedundancyTest4;
  annotation(Icon(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10}), graphics={Rectangle(visible=true, lineColor={0,0,255}, fillColor={235,235,235},
            fillPattern =                                                                                                    FillPattern.Solid, extent={{-100.0,-100.0},{80.0,50.0}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={235,235,235},
            fillPattern =                                                                                                    FillPattern.Solid, points={{-100.0,50.0},{-80.0,70.0},{100.0,70.0},{80.0,50.0},{-100.0,50.0}}),Polygon(visible=true, lineColor={0,0,255}, fillColor={235,235,235},
            fillPattern =                                                                                                    FillPattern.Solid, points={{100.0,70.0},{100.0,-80.0},{80.0,-100.0},{80.0,50.0},{100.0,70.0}}),Text(visible=true, origin={-42.0755,7.2622},
            fillPattern =                                                                                                    FillPattern.Solid, extent={{-39.4379,-29.2276},{39.4379,29.2276}}, textString
            =                                                                                                    "Data reconciliation", fontName="Arial"),Bitmap(visible=true, origin={23.1899,-65.9119}, fileName="logoModelica.png",
            imageSource =                                                                                                    "", extent={{-53.1899,-18.4552},{53.1899,18.4552}})}), Diagram(coordinateSystem(extent={{-148.5,-105.0},{148.5,105.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})),
    uses(Modelica(version="4.1.0"), ThermoSysPro(version="4.2")));
end DataReconciliationTests;
