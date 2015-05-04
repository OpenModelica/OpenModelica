within SiemensPowerOMCtest.Components.HeatExchanger.Tests;
model paralleFlowEVA_test "Test case for Benson parallelFlowEvaporator"
  extends Modelica.Icons.Example;
  SiemensPowerOMCtest.Components.HeatExchanger.ParallelFlowEvaporator EVA1(
    geoPipe(s=0.00264, Nt=78),
    propertiesMetal(lambda=40),
    geoFins(
      h=0.019,
      s=0.00125,
      n=300,
      material="St 35.8"),
    geoFGZ(pt=0.09, Lh=0.18),
    m_flow_start=25.87,
    numberOfWallLayers=1,
    V=1,
    hasMixerVolume=false,
    numberOfTubeLayers=5,
    numberOfCellsPerLayer=5,
    hydraulicResistanceSplitterOut=7000,
    redeclare package GasMedium = SiemensPowerOMCtest.Media.ExhaustGas)
    annotation (Placement(transformation(extent={{28,16},{48,36}}, rotation=0)));
  SiemensPowerOMCtest.Components.HeatExchanger.ParallelFlowEvaporator EVA2(
    geoPipe(Nt=80),
    geoFins(material="13 CrMo 4.4"),
    propertiesMetal(lambda=38),
    m_flow_start=25.87,
    numberOfWallLayers=1,
    numberOfCellsPerLayer=5,
    V=1,
    hydraulicResistanceSplitterOut=3000,
    redeclare package GasMedium = SiemensPowerOMCtest.Media.ExhaustGas,
    numberOfTubeLayers=2)
    annotation (Placement(transformation(extent={{-28,16},{-8,36}}, rotation=0)));
  SiemensPowerOMCtest.Components.Pipes.TubeWithoutWall downcomer(
    geoPipe(
      Nt=2,
      L=26,
      H=-21,
      d_out=0.1683,
      s=0.01427,
      zeta_add=0.5),
    hIn_start= 500e3,
    hOut_start= 500e3,
    m_flow_start=
            25.87,
    numberOfNodes=
      5,
    considerDynamicPressure=
                 false,
    useDelayedPressure=
                  false,
    pIn_start= 13700000,
    pOut_start= 13900000)
         annotation (Placement(transformation(
        origin={9,10},
        extent={{-8,-9},{8,9}},
        rotation=270)));
  SiemensPowerOMCtest.Boundaries.GasSource gasSourceW(
    m_flow_start=
            228.68,
    T_start=
       390,
    redeclare package Medium = SiemensPowerOMCtest.Media.ExhaustGas)
                                   annotation (Placement(transformation(extent=
            {{-74,16},{-54,36}}, rotation=0)));
  SiemensPowerOMCtest.Boundaries.GasSinkP gasSinkP(redeclare package Medium =
        SiemensPowerOMCtest.Media.ExhaustGas)
                               annotation (Placement(transformation(extent={{72,
            16},{92,36}}, rotation=0)));
  SiemensPowerOMCtest.Boundaries.WaterSink watersink_ph(
                                       p_start=
                                          137.093e5)
                                       annotation (Placement(transformation(
          extent={{-10,66},{10,86}}, rotation=0)));
  SiemensPowerOMCtest.Boundaries.WaterSourceMH watersource_mh(
                                           h_start=
                                              500e3, m_flow_start=
                                                             25.87)
                                           annotation (Placement(transformation(
          extent={{12,-80},{32,-60}}, rotation=0)));
  SiemensPowerOMCtest.Blocks.TimeTable timeTable(timeDelay=
                                  1, table=[0,390; 10,390; 900,711.15; 1000,711.15])
    annotation (Placement(transformation(extent={{-100,60},{-80,80}}, rotation=
            0)));
  SiemensPowerOMCtest.Blocks.TimeTable timeTable1(timeDelay=
                                   2, table=[0,500e3; 100,500e3; 2000,2338e3; 3000,
        2338e3]) annotation (Placement(transformation(extent={{-20,-40},{0,-20}},
          rotation=0)));
equation
  connect(timeTable1.y,watersource_mh.hIn)   annotation (Line(points={{1,-30},{
          26,-30},{26,-64}}, color={0,0,127}));
  connect(timeTable.y,gasSourceW.T_set) annotation (Line(points={{-79,70},{-64,
          70},{-64,32}}, color={0,0,127}));
  connect(gasSourceW.port,EVA2.portGasIn)  annotation (Line(
      points={{-54,26},{-28,26}},
      color={0,191,0},
      smooth=Smooth.None));
  connect(EVA2.portGasOut,EVA1.portGasIn) annotation (Line(
      points={{-8,26},{28,26}},
      color={0,191,0},
      smooth=Smooth.None));
  connect(EVA1.portGasOut,
                         gasSinkP.portGas)
                                         annotation (Line(
      points={{48,26},{72,26}},
      color={0,191,0},
      smooth=Smooth.None));
  connect(watersource_mh.port,EVA1.portWaterIn)
                                              annotation (Line(
      points={{32,-70},{38,-70},{38,16}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(EVA1.portSteamOut,downcomer.portIn)
                                            annotation (Line(
      points={{38,36},{38,50},{9,50},{9,18}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(downcomer.portOut,
                           EVA2.portWaterIn)
                                           annotation (Line(
      points={{9,2},{9,-4},{-18,-4},{-18,16}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(EVA2.portSteamOut,
                          watersink_ph.port) annotation (Line(
      points={{-18,36},{-18,76},{-10,76}},
      color={0,127,255},
      smooth=Smooth.None));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=false, extent={{-100,
            -100},{100,100}}), graphics),
Documentation(
     info="<HTML>
        <p>
           This is a test case for Benson parallelFlowEvaporator (according to Cottam design)
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
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
     </HTML>",
     revisions="<html>
        <ul>
            <li> November 2007 by Haiko Steuer
        </ul>
     </html>"),
    experiment(StopTime=3000),
    Commands(file="Scripts/tests/parallelFlowEVA_test.mos"
        "parallelFlowEVA_test"));
end paralleFlowEVA_test;
