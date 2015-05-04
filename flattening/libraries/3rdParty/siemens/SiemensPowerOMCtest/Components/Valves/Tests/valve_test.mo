within SiemensPowerOMCtest.Components.Valves.Tests;
model valve_test "Test of valve aggregate"
    extends Modelica.Icons.Example;
  SiemensPowerOMCtest.Boundaries.WaterSink watersink_ph(   h_start=
                                                       500e3, p_start=
                                                                 200000)
    annotation (Placement(transformation(extent={{42,44},{62,64}}, rotation=0)));
  SiemensPowerOMCtest.Components.Valves.Valve waterValve(
    valveType =   "water valve",
    useExplicitGeometry=
                      false,
    hasNoReverseFlow=
               false,
    hIn_start= 300e3,
    pIn_start= 300000,
    pOut_start= 200000)
                     annotation (Placement(transformation(extent={{-8,44},{12,64}},
          rotation=0)));
  SiemensPowerOMCtest.Boundaries.WaterSourceWithSetPressure watersource_ph(
                                                                h0=300e3, p0=
        200000)
    annotation (Placement(transformation(extent={{-62,44},{-42,64}}, rotation=0)));
  SiemensPowerOMCtest.Blocks.TimeTable timeTable(table=[0,3e5; 1,3e5; 9,1e5; 10,1e5])
    annotation (Placement(transformation(extent={{-92,76},{-72,96}}, rotation=0)));
  SiemensPowerOMCtest.Boundaries.WaterSink watersink_ph1(   h_start=
                                                        3500e3, p_start=
                                                                   200000)
    annotation (Placement(transformation(extent={{42,-22},{62,-2}}, rotation=0)));
  SiemensPowerOMCtest.Components.Valves.Valve steamValve(
    useExplicitGeometry=
                      false,
    valveType =   "steam valve",
    hIn_start= 2000e3,
    hasNoReverseFlow=
               false,
    m_flow_start=
            1,
    pIn_start= 1100000,
    pOut_start= 1000000)
                   annotation (Placement(transformation(extent={{-8,-22},{12,-2}},
          rotation=0)));
  SiemensPowerOMCtest.Blocks.TimeTable timeTable1(table=[0,10e5; 1,10e5; 9,1e5; 10,1e5])
    annotation (Placement(transformation(extent={{-88,14},{-68,34}},rotation=0)));
  SiemensPowerOMCtest.Boundaries.WaterSourceMH watersource_mh(
                                           m_flow_start=
                                                   1, h_start=
                                                         2000e3)
    annotation (Placement(transformation(extent={{-58,-22},{-38,-2}}, rotation=
            0)));
  SiemensPowerOMCtest.Boundaries.GasSourceP gasSourceP(p_start=
                                      200000, T_start=
                                                 293.15)
    annotation (Placement(transformation(extent={{-68,-72},{-48,-52}})));
  SiemensPowerOMCtest.Boundaries.GasSinkP gasSinkP(p_start=
                                  100000, T_start=
                                             298.15)
    annotation (Placement(transformation(extent={{44,-72},{64,-52}})));
  SiemensPowerOMCtest.Components.Valves.Valve GasValve(
    redeclare package Medium = Modelica.Media.Air.SimpleAir,
    useTemperatureStartValue=
                true,
    useExplicitGeometry=
                      false,
    pIn_start= 200000,
    pOut_start= 100000,
    TIn_start= 293.15,
    TOut_start= 298.15)
    annotation (Placement(transformation(extent={{-10,-72},{10,-52}})));
equation
  connect(watersource_ph.port,waterValve.portIn)
                                             annotation (Line(points={{-42,54},
          {-26,54},{-26,54},{-8,54}},       color={0,127,255}));
  connect(waterValve.portOut,watersink_ph.port)
                                           annotation (Line(points={{12,54},{
          28.725,54},{28.725,54},{42,54}},            color={0,127,255}));
  connect(timeTable.y,watersource_ph.pIn)   annotation (Line(points={{-71,86},{
          -56,86},{-56,62}}, color={0,0,127}));
  connect(steamValve.portOut,watersink_ph1.port)
                                           annotation (Line(points={{12,-12},{
          28.725,-12},{28.725,-12},{42,-12}},             color={0,127,255}));

  connect(watersource_mh.port,steamValve.portIn)
                                              annotation (Line(points={{-38,-12},
          {-26,-12},{-26,-12},{-8,-12}},       color={0,127,255}));

  connect(timeTable1.y,watersink_ph1.p_set) annotation (Line(
      points={{-67,24},{48,24},{48,-4}},
      color={0,0,127},
      smooth=Smooth.None));

  connect(gasSourceP.portGas,GasValve.portIn)
                                          annotation (Line(
      points={{-48,-62},{-10,-62}},
      color={0,191,0},
      smooth=Smooth.None));
  connect(gasSinkP.portGas,GasValve.portOut)
                                        annotation (Line(
      points={{44,-62},{10,-62}},
      color={0,191,0},
      smooth=Smooth.None));
  annotation (Documentation(info="<HTML>
<p>This is a simple test of the valve aggregate including reverse flow.
<p>
</HTML>
<HTML>
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
           For details see <a href=\"./Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
</HTML>",
      revisions="<html>
<ul>
<li> December 2006, added by Haiko Steuer
</ul>
</HTML>"), Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-100,
            -100},{100,100}}),
                   graphics),
    Commands(file="Scripts/tests/valve_test.mos" "valve_test"),
    experiment(StopTime=10));
end valve_test;
