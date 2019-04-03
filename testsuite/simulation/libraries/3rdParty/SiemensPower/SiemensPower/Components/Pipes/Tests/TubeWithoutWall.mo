within SiemensPower.Components.Pipes.Tests;
model TubeWithoutWall "Test of unheated tube"
  import SiemensPower;
    extends Modelica.Icons.Example;
  SiemensPower.Components.Pipes.TubeWithoutWall tube2(
    numberOfNodes=
      10,
    geoPipe(L=10),
    m_flow_start=
            1,
    pIn_start= 3100000,
    pOut_start= 3000000,
    hIn_start= 3000e3,
    hOut_start= 3000e3)
               annotation (Placement(transformation(extent={{4,6},{24,26}},
          rotation=0)));
  SiemensPower.Boundaries.WaterSourceMH watersource_mh(
                                           h_start=
                                              3000e3)
    annotation (Placement(transformation(extent={{-72,6},{-52,26}}, rotation=0)));
  SiemensPower.Boundaries.WaterSink watersink_ph(
                                       p_start=
                                          30e5, h_start=
                                                   1000e3)
    annotation (Placement(transformation(extent={{44,6},{64,26}}, rotation=0)));
  SiemensPower.Blocks.TimeTable InletMassFlowRate(table=[0,1; 1,1; 2,2; 3,2])
    annotation (Placement(transformation(extent={{-96,32},{-76,52}}, rotation=0)));
  SiemensPower.Blocks.TimeTable OutletPressure(table=[0,30e5; 60,30e5; 120,31e5; 150,31e5])
    annotation (Placement(transformation(extent={{6,44},{26,64}}, rotation=0)));
  SiemensPower.Blocks.TimeTable InletEnthalpy(table=[0,3000e3; 20,3000e3; 50,1000e3; 60,
        1000e3]) annotation (Placement(transformation(extent={{-94,68},{-74,88}},
          rotation=0)));
  SiemensPower.Components.Pipes.TubeWithoutWall tube1(
    numberOfNodes=
      10,
    geoPipe(L=10),
    initializeInletPressure=
           false,
    m_flow_start=
            0.4,
    pIn_start= 3100000,
    pOut_start= 3000000,
    hIn_start= 3000e3,
    hOut_start= 3000e3)
            annotation (Placement(transformation(extent={{-42,6},{-22,26}},
          rotation=0)));
  SiemensPower.Boundaries.WaterSourceMH watersource_add(
                                           h_start=
                                              3000e3)
    annotation (Placement(transformation(extent={{-56,-18},{-36,2}},rotation=0)));
equation
  connect(tube2.portOut,watersink_ph.port) annotation (Line(points={{24,16},{
          26.35,16},{44,16}},               color={0,127,255}));

  connect(InletMassFlowRate.y,watersource_mh.m_flowIn) annotation (Line(points=
          {{-75,42},{-66,42},{-66,22}}, color={0,0,127}));

  connect(InletEnthalpy.y,watersource_mh.hIn)   annotation (Line(points={{-73,
          78},{-58,78},{-58,22}}, color={0,0,127}));
  connect(OutletPressure.y,watersink_ph.p_set) annotation (Line(points={{27,54},
          {38,54},{38,52},{50,52},{50,24}}, color={0,0,127}));
  connect(watersource_mh.port,tube1.portIn)  annotation (Line(
      points={{-52,16},{-42,16}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(tube1.portOut,tube2.portIn) annotation (Line(
      points={{-22,16},{4,16}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(watersource_add.port,tube2.portIn)  annotation (Line(
      points={{-36,-8},{-16,-8},{-16,16},{4,16}},
      color={0,127,255},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
            -100},{100,100}}),
                      graphics),
                       experiment(StopTime=150, Tolerance=1e-005),
    Commands(file="Scripts/tests/tube_unheated_test.mos" "tube_unheated_test"),
              Documentation(info="<HTML>
       <p>  This is a simple test of the tube_unheated aggregate including reverse flow and pp tube.
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
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>"));
end TubeWithoutWall;
