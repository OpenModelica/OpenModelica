within SiemensPower.Components.FlueGasZones.Tests;
model FlueGasZoneSingleTube_testsimple "Test case for the basic flue gas zone"
  extends Modelica.Icons.Example;
  FlueGasZoneSingleTubeOwnMedia flueGasZoneSingleCompGas(
    geoFGZ(
      pt=0.085,
      Lw=7.3,
      Ld=13.5,
      Lh=0.4,
      Nr=4,
      pl=0.100),
    geoPipe(
      L=20,
      Nt=84,
      d_out=0.036,
      zeta_add=2),
    geoFins(
      serrated=false,
      h=0.019,
      s=0.0012,
      n=200,
      material="15 Mo 3"),
    numberOfTubeNodes=
      20,
    m_flow_start=
            18,
    hIn_start=
       1300e3,
    hOut_start=
       1700e3,
    m_flowGas_start=
               200,
    heatloss=0.5,
    numberOfWallLayers=
          3,
    pIn_start=8200000,
    pOut_start=8200000,
    TGasIn_start=673,
    TGasOut_start=760,
    redeclare SiemensPower.Utilities.HeatTransfer.HeatTransfer_constAlpha
      heatTransfer)
                 annotation (Placement(transformation(extent={{-2,36},{18,56}},
          rotation=0)));

  Boundaries.GasSinkP gasSinkP(T_start(displayUnit="K")=300,use_T_In = false)
                                       annotation (Placement(transformation(
          extent={{50,36},{70,56}}, rotation=0)));
  Boundaries.GasSource gasSourceW(
    m_flow_start=
            200,
    use_m_flow_set=false,
    T_start(displayUnit="K") = 673.15,
    use_T_set=true)
                 annotation (Placement(transformation(extent={{-54,40},{-34,60}},
          rotation=0)));
  SiemensPower.Boundaries.WaterSink watersink_ph(p_start=8200000)
    annotation (Placement(transformation(extent={{30,76},{50,96}}, rotation=0)));
  SiemensPower.Boundaries.WaterSourceMH watersource_mh(
                                           m_flow_start=
                                                   18.41, h_start=
                                                             1300e3)
    annotation (Placement(transformation(extent={{-34,-4},{-14,16}},   rotation=
           0)));
  SiemensPower.Blocks.TimeTable timeTable(timeDelay=1, table=[0,673.15; 10,
        673.15])     annotation (Placement(transformation(extent={{-94,60},{-74,
            80}}, rotation=0)));
  SiemensPower.Blocks.TimeTable timeTable1(
                                          timeDelay=1, table=[0,673.15; 10,673.15; 100,773.15;
        200,773.15]) annotation (Placement(transformation(extent={{-72,82},{-52,
            102}},rotation=0)));
equation
  connect(gasSourceW.port,flueGasZoneSingleCompGas.portGasIn)
                                                            annotation (Line(
      points={{-34,50},{-16.7,50},{-16.7,46},{-2,46}},
      color={0,191,0},
      smooth=Smooth.None));
  connect(flueGasZoneSingleCompGas.portGasOut, gasSinkP.portGas)
                                                          annotation (Line(
      points={{18,46},{50,46}},
      color={0,191,0},
      smooth=Smooth.None));
  connect(watersource_mh.port,flueGasZoneSingleCompGas.portIn)
                                                             annotation (Line(
      points={{-14,6},{8,6},{8,38}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(watersink_ph.port,flueGasZoneSingleCompGas.portOut)
                                                           annotation (Line(
      points={{30,86},{8,86},{8,54}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(timeTable.y,gasSourceW.T_set) annotation (Line(points={{-73,70},{-44,
          70},{-44,56}}, color={0,0,127}));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-100,
            -100},{100,100}}),
                      graphics),
Documentation(
     info="<HTML>
        <p>
           This is a test case for the basic flue gas zone with a single tube in a cross flow flue gas zone.
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
     </html>"),
    experiment(StopTime=200,
    NumberOfIntervals=500),
    Commands(file="Scripts/tests/FlueGasZoneSingleTube_test.mos"
        "FlueGasZoneSingleTube_test"));
end FlueGasZoneSingleTube_testsimple;
