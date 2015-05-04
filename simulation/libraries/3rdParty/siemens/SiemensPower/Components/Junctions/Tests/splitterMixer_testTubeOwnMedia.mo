within SiemensPower.Components.Junctions.Tests;
model splitterMixer_testTubeOwnMedia "Test case for SplitterMixer"
//  extends Modelica.Icons.Example;

SiemensPower.Components.Junctions.SplitterMixer splitter(
    hasPressureDrop = true,
    resistanceHydraulic=
      100,
    h_start=1000e3,
    numberOfPortsSplit=
      2,
    m_flow_start=
            20,
    p_start=3000000)
                annotation (Placement(transformation(extent={{-34,-52},{-14,-32}},
          rotation=0)));
  Boundaries.WaterSourceMH watersource_mh( h_start=
                                              1000e3, m_flow_start=
                                                              20,
    use_m_flow_in=false,
    use_h_in=false)
    annotation (Placement(transformation(extent={{-44,-86},{-24,-66}}, rotation=
           0)));
  SiemensPower.Boundaries.WaterSink watersink_ph(  h_start=
                                                      1500e3, p_start=
                                                                 3000000)
    annotation (Placement(transformation(extent={{12,70},{32,90}},   rotation=0)));
  SiemensPower.Components.Junctions.SplitterMixer mixer(
    numberOfPortsSplit=
      3,
    h_start=1000e3,
    m_flow_start=
            -30,
    useTemperatureStartValue=
                true,
    hasVolume= true,
    V=0.05,
    initializeSteadyEnthalpyBalance=
                          false,
    p_start=3000000)
                 annotation (Placement(transformation(extent={{-24,64},{-6,42}},
          rotation=0)));

  Pipes.TubeOwnMedia pipe1( geoPipe(zeta_add=1),
    m_flow_start=
            10,
    pIn_start= 3100000,
    pOut_start= 3000000,
    hIn_start= 1000e3,
    hOut_start= 1000e3)
    annotation (Placement(transformation(
        origin={-34,8},
        extent={{-10,-10},{10,10}},
        rotation=90)));
  Pipes.TubeOwnMedia pipe2( geoPipe(zeta_add=2),
   m_flow_start=
           10,
    pIn_start= 3100000,
    pOut_start= 3000000,
    hIn_start= 1000e3,
    hOut_start= 1000e3)
    annotation (Placement(transformation(
        origin={-14,8},
        extent={{-10,-10},{10,10}},
        rotation=90)));
  Pipes.TubeOwnMedia pipe3(
   m_flow_start=
           10,
    pIn_start= 3100000,
    pOut_start= 3000000,
    hIn_start= 2000e3,
    hOut_start= 2000e3)
               annotation (Placement(transformation(
        origin={8,8},
        extent={{-10,-10},{10,10}},
        rotation=90)));
  Boundaries.WaterSourceMH watersource_mh1( h_start=
                                               2000e3, m_flow_start=
                                                               10,
    use_h_in=false,
    use_m_flow_in=true)
    annotation (Placement(transformation(extent={{44,-40},{26,-22}},   rotation=
           0)));
  SiemensPower.Blocks.TimeTable timeTable(table=[0,5; 1,5; 2,0; 3,0; 4,-10; 5,-10])
    annotation (Placement(transformation(extent={{86,8},{70,24}})));
equation
  connect(watersource_mh.port,splitter.portMix) annotation (Line(
      points={{-24,-76},{-24,-51}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(mixer.portMix,watersink_ph.port) annotation (Line(
      points={{-15,62.9},{-15,80},{12,80}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(splitter.portsSplit[1],pipe1.portIn)
                                            annotation (Line(
      points={{-24,-35},{-24,-32},{-34,-32},{-34,-2}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(splitter.portsSplit[2],pipe2.portIn)
                                            annotation (Line(
      points={{-24,-31},{-24,-32},{-14,-32},{-14,-2}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(pipe1.portOut,
                       mixer.portsSplit[1])
                                         annotation (Line(
      points={{-34,18},{-34,40},{-18,40},{-18,46.0333},{-15,46.0333}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(pipe2.portOut,
                       mixer.portsSplit[2])
                                         annotation (Line(
      points={{-14,18},{-14,30.35},{-15,30.35},{-15,43.1}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(pipe3.portOut,
                       mixer.portsSplit[3])
                                         annotation (Line(
      points={{8,18},{8,40.1667},{-15,40.1667}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(watersource_mh1.port,pipe3.portIn)  annotation (Line(
      points={{26,-31},{8,-31},{8,-2}},
      color={0,127,255},
      smooth=Smooth.None));

  connect(timeTable.y, watersource_mh1.m_flow_in) annotation (Line(
      points={{69.2,16},{38.6,16},{38.6,-25.6}},
      color={0,0,127},
      smooth=Smooth.None));
annotation (Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
            -100},{100,100}}), graphics),
    experiment(StopTime=12,
    NumberOfIntervals=500),
    Commands(file="Scripts/tests/splitterMixer_test.mos" "splitterMixer_test"),
  Documentation(
     info="<HTML>
        <p>
           This is a test case for the SplitterMixer component <br>
           The model restrictions are:
                <ul>
                        <li> none
                </ul>
        </p>
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
                           <td>free </td>
                </tr>
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>6.1 </td>
                  </tr>
           </table>
                Copyright &copy  2007 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
     </HTML>",
     revisions="<html>
        <ul>
            <li> November 2007 by Haiko Steuer
        </ul>
     </html>"));
end splitterMixer_testTubeOwnMedia;
