within SiemensPower.Components.Pipes.Tests;
model tube_ownMedia_test "Test of tube"
    extends Modelica.Icons.Example;
  SiemensPower.Boundaries.WaterSourceMH watersource_mh(
                                           m_flow_start=
                                                   50, h_start=
                                                          500e3)
    annotation (Placement(transformation(extent={{-100,20},{-80,40}},rotation=0)));
  Boundaries.WaterSink watersink_ph(            h_start=
                                                   1000e3,
    use_p_in=true,
    p_start=3000000)
    annotation (Placement(transformation(extent={{80,20},{100,40}},rotation=0)));
  SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow(numberOfCells=
                                                     20)
    annotation (Placement(transformation(extent={{-32,74},{-12,94}}, rotation=0)));
  SiemensPower.Components.Pipes.TubeOwnMedia EVA(
    numberOfNodes=
      20,
    alphaOffset=5000,
    geoPipe(L=40, Nt=100),
    considerMassAccelaration=
                false,
    considerDynamicPressure=
                 true,
    m_flow_start=
            50,
    hIn_start= 1000e3,
    hOut_start= 1000e3,
    useINTH2O=
           false,
    metal(
      cp=540,
      lambda=44,
      rho=7850),
    pIn_start=3100000,
    pOut_start=3000000,
    considerDynamicMomentum=false)
          annotation (Placement(transformation(extent={{0,20},{20,40}},
          rotation=0)));
  SiemensPower.Blocks.TimeTable timeTable(table=[0,0; 1000,100e6; 2000,100e6])
    annotation (Placement(transformation(extent={{-80,74},{-60,94}}, rotation=0)));
  SiemensPower.Components.Pipes.TubeOwnMedia ECO(
    numberOfNodes=
      10,
    geoPipe(L=10, Nt=100),
    considerMassAccelaration=
                false,
    considerDynamicPressure=
                 true,
    delayInnerHeatTransfer=
                true,
    m_flow_start=
            50,
    hIn_start= 500e3,
    hOut_start= 1000e3,
    useINTH2O=
           false,
    pIn_start=3100000,
    pOut_start=3000000,
    metal(
      cp=540,
      lambda=44,
      rho=7850))
          annotation (Placement(transformation(extent={{-60,40},{-38,20}},
          rotation=0)));
  SiemensPower.Blocks.TimeTable timeTable1(table=[0,30e5; 1100,30e5; 1400,31e5; 2000,31e5])
    annotation (Placement(transformation(extent={{44,70},{64,90}}, rotation=0)));
  Modelica.Blocks.Sources.RealExpression realExpression(y=25e6)
    annotation (Placement(transformation(extent={{-102,-12},{-82,8}}, rotation=
            0)));
  SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow1(numberOfCells=
                                                      10)
    annotation (Placement(transformation(extent={{-60,-20},{-40,0}}, rotation=0)));
  SiemensPower.Components.Pipes.TubeOwnMedia SH(
    numberOfNodes=
      10,
    geoPipe(L=10, Nt=100),
    considerMassAccelaration=
                false,
    considerDynamicPressure=
                 true,
    initializeInletPressure=
           false,
    m_flow_start=
            50,
    hOut_start= 2000e3,
    delayInnerHeatTransfer=
                true,
    hIn_start= 2000e3,
    pIn_start=3200000,
    pOut_start=3000000,
    metal(
      cp=540,
      lambda=44,
      rho=7850))
          annotation (Placement(transformation(extent={{40,-20},{62,-40}},
          rotation=0)));
  SiemensPower.Boundaries.WaterSink watersink_ph1(
                                                h_start=
                                                   2000e3, p_start=
                                                              3000000)
    annotation (Placement(transformation(extent={{80,-40},{100,-20}},  rotation=
           0)));
  Modelica.Blocks.Sources.RealExpression realExpression1(y=0)
    annotation (Placement(transformation(extent={{-14,-68},{6,-48}}, rotation=0)));
  SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow2(numberOfCells=
                                                      10)
    annotation (Placement(transformation(extent={{16,-70},{36,-50}}, rotation=0)));
  SiemensPower.Boundaries.WaterSourceWithSetPressure watersource_ph(
                                           h0=2000e3,
    p0=3200000,
    use_pIn=true)
    annotation (Placement(transformation(extent={{0,-40},{20,-20}},  rotation=0)));
  SiemensPower.Blocks.TimeTable timeTable2(table=[0,32e5; 200,32e5; 800,35e5; 2000,35e5])
    annotation (Placement(transformation(extent={{-20,-20},{0,0}},  rotation=0)));
equation

  connect(prescribedHeatFlow.portsOut,
                                  EVA. gasSide)            annotation (Line(
        points={{-12,84},{10,84},{10,36.6}}, color={191,0,0}));

  connect(timeTable.y,prescribedHeatFlow. Q_flow)
    annotation (Line(points={{-59,84},{-32,84}}, color={0,0,127}));
  connect(watersource_mh.port,ECO.portIn)  annotation (Line(points={{-80,30},{
          -60,30}},                                  color={0,127,255}));
  connect(ECO.portOut,EVA.portIn) annotation (Line(points={{-38,30},{-29.125,30},
          {-29.125,29.9},{-24.25,29.9},{-24.25,30},{0,30}},
                  color={0,127,255}));
  connect(prescribedHeatFlow1.portsOut,
                                   ECO. gasSide) annotation (Line(points={{-40,-10},
          {-49,-10},{-49,23.4}},    color={191,0,0}));
  connect(EVA.portOut,
                     watersink_ph. port) annotation (Line(points={{20,30},{20,
          30},{80,30}},                    color={0,127,255}));
  connect(realExpression.y,prescribedHeatFlow1. Q_flow)
    annotation (Line(points={{-81,-2},{-76,-2},{-76,-10},{-60,-10}},
                                                 color={0,0,127}));
  connect(watersink_ph1.port,SH.portOut) annotation (Line(points={{80,-30},{72,
          -30},{62,-30}},                            color={0,127,255}));
  connect(realExpression1.y,prescribedHeatFlow2. Q_flow)
    annotation (Line(points={{7,-58},{16,-58},{16,-60}},
                                                color={0,0,127}));
  connect(prescribedHeatFlow2.portsOut,
                                   SH. gasSide) annotation (Line(points={{36,-60},
          {52,-60},{52,-36.6},{51,-36.6}},      color={191,0,0}));
  connect(watersource_ph.port,SH.portIn)  annotation (Line(points={{20,-30},{30,
          -30},{40,-30}},                            color={0,127,255}));
  connect(timeTable2.y,watersource_ph.pIn)   annotation (Line(points={{1,-10},{
          6,-10},{6,-22}},
                       color={0,0,127}));
  connect(timeTable1.y, watersink_ph.pIn) annotation (Line(
      points={{65,80},{86,80},{86,38}},
      color={0,0,127},
      smooth=Smooth.None));
  annotation (Documentation(info="<HTML>
       <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                             <td><a href=\"mailto:haiko.steuer@siemens.com\">Haiko Steuer</a> </td>
                        <td><a href=\"https://scd.siemens.com/db4/v3/lookUp.d4w?tcgid=Z001K4SN\">SCD</a> </td>
                       </tr>
                <tr>
                           <td><b>Checked by:</b>   </td>
                           <td>            </td>
                </tr>
                <tr>
                           <td><b>Protection class:</b>    </td>
                           <td> </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td> </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
      revisions="<html>
<ul>
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>"),
    Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,-100},{
            100,100}}),
            graphics),
    experiment(
      StopTime=2000,
      NumberOfIntervals=2000,
      Tolerance=1e-005),
    Commands(file="Scripts/tests/tube_ownMedia_test.mos" "tube_ownMedia_test"));
end tube_ownMedia_test;
