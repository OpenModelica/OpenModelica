within SiemensPower.Components.Pipes.Tests;
model tube_test "Test of tube"
    extends Modelica.Icons.Example;
  Modelica.Fluid.Sources.MassFlowSource_h
                                        watersource_mh(
    m_flow=50,
    h=500e3,
    nPorts=1,
    redeclare package Medium = Modelica.Media.Water.WaterIF97_ph)
    annotation (Placement(transformation(extent={{-92,18},{-72,38}}, rotation=0)));
  SiemensPower.Boundaries.WaterSink watersink_ph(
                                       p_start=
                                          30e5, h_start=
                                                   1000e3)
    annotation (Placement(transformation(extent={{78,18},{98,38}}, rotation=0)));
  Tube                               EVA(
    geoPipe(
        L=40, Nt=100),
     numberOfNodes=
      20,
    m_flow_start=
            50,
    hIn_start= 1000e3,
    hOut_start= 1000e3,
    redeclare model Friction = SiemensPower.Utilities.PressureLoss.OverallFlow,
    pIn_start=3100000,
    pOut_start=3000000,
    redeclare model heattransfer =
        SiemensPower.Utilities.HeatTransfer.InnerHeatTransfer.SinglePhaseOverall)
          annotation (Placement(transformation(extent={{-8,20},{12,40}},
          rotation=0)));

  Tube                               ECO(
    geoPipe(
        L=10, Nt=100),
    numberOfNodes=
      10,
    m_flow_start=
            50,
    hIn_start= 1000e3,
    hOut_start= 1000e3,
    redeclare model Friction = SiemensPower.Utilities.PressureLoss.OverallFlow,
    redeclare model heattransfer =
        SiemensPower.Utilities.HeatTransfer.InnerHeatTransfer.SinglePhaseOverall,

    pIn_start=3100000,
    pOut_start=3000000,
    metal(
      cp=540,
      lambda=44,
      rho=7850,
      Rm=600,
      Rp02=440))
          annotation (Placement(transformation(extent={{-52,40},{-30,20}},
          rotation=0)));

  SiemensPower.Blocks.TimeTable timeTable1(table=[0,30e5; 1100,30e5; 1400,31e5; 2000,31e5])
    annotation (Placement(transformation(extent={{48,64},{68,84}}, rotation=0)));
  Modelica.Blocks.Sources.RealExpression realExpression(y=25e6)
    annotation (Placement(transformation(extent={{-98,-18},{-78,2}}, rotation=0)));
  SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow1(numberOfCells=
                                                      10)
    annotation (Placement(transformation(extent={{-66,-18},{-46,2}}, rotation=0)));
  SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow(numberOfCells=
                                                     20)
    annotation (Placement(transformation(extent={{-24,70},{-4,90}},rotation=0)));
  SiemensPower.Blocks.TimeTable timeTable(table=[0,0; 101,0; 1000,100e6; 2000,100e6])
    annotation (Placement(transformation(extent={{-78,70},{-58,90}}, rotation=0)));
equation

  connect(ECO.portOut,EVA.portIn) annotation (Line(points={{-30,30},{-20,28},{-8,
          30}},   color={0,127,255}));
  connect(EVA.portOut,
                     watersink_ph. port) annotation (Line(points={{12,30},{12,28},
          {78,28}},                        color={0,127,255}));
  connect(realExpression.y, prescribedHeatFlow1.Q_flow)
    annotation (Line(points={{-77,-8},{-66,-8}}, color={0,0,127}));
  connect(timeTable.y, prescribedHeatFlow.Q_flow)
    annotation (Line(points={{-57,80},{-32,80},{-24,80}},
                                                 color={0,0,127}));
  connect(timeTable1.y,watersink_ph.p_set) annotation (Line(points={{69,74},{88,
          74},{88,36},{84,36}}, color={0,0,127}));
  connect(prescribedHeatFlow1.portsOut, ECO.heatPort) annotation (Line(
      points={{-46,-8},{-42,-8},{-42,-6},{-41,-6},{-41,23.4}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(prescribedHeatFlow.portsOut, EVA.heatPort) annotation (Line(
      points={{-4,80},{2,80},{2,36.6}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(watersource_mh.ports[1], ECO.portIn) annotation (Line(
      points={{-72,28},{-64,28},{-64,30},{-52,30}},
      color={0,127,255},
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
                           <td>internal </td>
                </tr>
           </table>
               <p><b><font style=\"font-size: 10pt; \">License, Copyright and Disclaimer</font></b> </p>
<p>
<blockquote><br/>Licensed by Siemens AG under the Siemens Modelica License 2</blockquote>
<blockquote><br/>Copyright  2007-2012 Siemens AG. All rights reserved.</blockquote>
<blockquote><br/>This Modelica package is <u>free</u> software and the use is completely at <u>your own risk</u>; it can be redistributed and/or modified under the terms of the Siemens Modelica License 2. For license conditions (including the disclaimer of warranty) see <a href=\"../Documents/SiemensModelicaLicense2.html\">Siemens Modelica License 2 </a>.</blockquote>
        </p>
</HTML>",
      revisions="<html>
<ul>
<li> January 2007, added by Haiko Steuer
</ul>
</HTML>"),
    Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
            100}}),
            graphics),
    experiment(
      StopTime=2000,
      NumberOfIntervals=100,
      Tolerance=1e-005),
    Commands(file="Scripts/tests/tube_test.mos" "tube_test"));
end tube_test;
