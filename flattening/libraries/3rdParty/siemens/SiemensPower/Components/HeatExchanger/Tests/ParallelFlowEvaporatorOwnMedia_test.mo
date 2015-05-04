within SiemensPower.Components.HeatExchanger.Tests;
model ParallelFlowEvaporatorOwnMedia_test
  "Evaporator of Liegender Benson with parallel gas and water flow, with analytical Jacobian"

   parameter Integer N=2 "Number of water/steam cells per tube layer";

  SiemensPower.Components.HeatExchanger.ParallelFlowEvaporatorOwnMedia EVA1(
    geoPipe(
         s=0.00264, Nt=130),
    propertiesMetal(
          lambda=40),
    geoFins(
      h=0.019,
      s=0.00125,
      n=300,
      material="St 35.8"),
    geoFGZ(
        pt=0.09, Lh=0.18),
    V=1,
    hasMixerVolume=
               false,
    hydrResistanceSplitterOut=
      7000,
    numberOfCellsPerLayer=
      N,
    numberOfWallLayers=
          1,
    numberOfTubeLayers=
       2)
    annotation (Placement(transformation(extent={{20,22},{40,42}}, rotation=0)));

  SiemensPower.Components.HeatExchanger.ParallelFlowEvaporatorOwnMedia EVA2(
    geoFins(
        material="13 CrMo 4.4"),
    propertiesMetal(
          lambda=38),
    V=1,
    hasMixerVolume=
               false,
    hydrResistanceSplitterOut=
      3000,
    numberOfCellsPerLayer=
      N,
    numberOfWallLayers=
          1,
    numberOfTubeLayers=
       2)
    annotation (Placement(transformation(extent={{-24,22},{-4,42}}, rotation=0)));

  SiemensPower.Components.Pipes.TubeOwnMedia downcomer(
    geoPipe(
      Nt=2,
      L=26,
      H=-21,
      d_out=0.1683,
      s=0.01427,
      zeta_add=0.5),
    hIn_start= 500e3,
    hOut_start= 500e3,
    considerDynamicPressure=
                 false,
    useDelayedPressure=
                  false,
    m_flow_start=
            20,
    numberOfNodes=
      N,
    useINTH2O=
           false,
    pIn_start= 13700000,
    pOut_start= 13900000)
         annotation (Placement(transformation(
        origin={5,14},
        extent={{-12,-9},{8,9}},
        rotation=270)));
  SiemensPower.Boundaries.WaterSink watersink_ph(use_p_in=true, use_h_in=true)
    annotation (Placement(transformation(extent={{-14,78},{6,98}}, rotation=0)));
  SiemensPower.Boundaries.WaterSourceMH watersource_mh(use_m_flow_in=true,
      use_h_in=true)
    annotation (Placement(transformation(extent={{82,-4},{60,-26}},  rotation=0)));
  SiemensPower.Blocks.Smoothing smoothing(timeDelay=
                                            0.01) annotation (Placement(
        transformation(extent={{-80,-18},{-60,2}},   rotation=0)));
  SiemensPower.Blocks.Smoothing smoothing1(timeDelay=
                                             0.01) annotation (Placement(
        transformation(extent={{-80,-4},{-60,16}},   rotation=0)));
  SiemensPower.Blocks.Smoothing smoothing2(timeDelay=
                                             0.01) annotation (Placement(
        transformation(extent={{-80,-38},{-60,-18}}, rotation=0)));
  Boundaries.GasSource        massflowSource_h(use_m_flow_set=true, use_T_set=
        true)
    annotation (Placement(transformation(extent={{-74,22},{-54,42}})));
  Boundaries.GasSinkP    boundary_ph(use_p_In=true, use_T_In=true)
    annotation (Placement(transformation(extent={{70,24},{54,40}})));
  SiemensPower.Boundaries.PrescribedHeatFlow prescribedHeatFlow(numberOfCells=
                                                                  N)
    annotation (Placement(transformation(extent={{-8,-8},{10,8}},
        rotation=90,
        origin={24,0})));
  Modelica.Blocks.Sources.RealExpression realExpression
    annotation (Placement(transformation(extent={{-2,-20},{10,-8}})));
  Fluid.MassFlowRate massFlowRate           annotation (Placement(
        transformation(
        extent={{-8,9},{9,-8}},
        rotation=90,
        origin={-14,59})));
  Fluid.Temperature temperature
    annotation (Placement(transformation(extent={{-44,64},{-28,84}})));
  Fluid.Pressure pressure
    annotation (Placement(transformation(extent={{50,-2},{70,16}})));
  Modelica.Blocks.Interfaces.RealOutput ausgang[3] "pin mout Tout"
    annotation (Placement(transformation(extent={{90,50},{110,70}})));
  inner Modelica.Fluid.System system
    annotation (Placement(transformation(extent={{-72,84},{-60,96}})));
  SiemensPower.Blocks.TimeTable h_in_gas(timeDelay=
                                              0.5, table=[0,121.894e3; 10,
        121.894e3; 900,537.432e3; 1000,537.432e3])
                     annotation (Placement(transformation(extent={{-128,28},{
            -108,48}},
                  rotation=0)));
  Modelica.Blocks.Sources.RealExpression p_out_gas(y=1.01325e5)
    annotation (Placement(transformation(extent={{-108,60},{-88,80}},rotation=0)));
  Modelica.Blocks.Sources.RealExpression hr_gas(y=122e3)
    annotation (Placement(transformation(extent={{-108,74},{-88,94}},rotation=0)));
  Modelica.Blocks.Sources.RealExpression m_in_gas(y=228.68)
    annotation (Placement(transformation(extent={{-108,46},{-88,66}},
                                                                    rotation=0)));
  SiemensPower.Blocks.TimeTable h_in_water(timeDelay=
                                                1, table=[0,500e3; 100,500e3;
        2000,1527e3; 3000,1527e3])
                     annotation (Placement(transformation(extent={{-108,-38},{
            -88,-18}},
                   rotation=0)));
  Modelica.Blocks.Sources.RealExpression hr_water(y=2800e3)
    annotation (Placement(transformation(extent={{-108,-4},{-88,16}},
                                                                    rotation=0)));
  Modelica.Blocks.Sources.RealExpression p_out_water(y=137.058e5)
    annotation (Placement(transformation(extent={{-108,-18},{-88,2}},rotation=0)));
  Modelica.Blocks.Sources.RealExpression m_in_water(y=20)
    annotation (Placement(transformation(extent={{-108,-58},{-88,-38}},
                                                                     rotation=0)));
  Blocks.TimeTable T_in_gas(timeDelay=0.5, table=[0,116.85 + 273.15; 10,116.85
         + 273.15; 900,491.7 + 273.15; 1000,491.7 + 273.15])
                     annotation (Placement(transformation(extent={{-104,22},{
            -84,42}},
                  rotation=0)));
  Modelica.Blocks.Sources.RealExpression T_gas(y=116.95 + 273.15)
    annotation (Placement(transformation(extent={{80,22},{100,42}},  rotation=0)));
equation

  connect(EVA2.portGasOut,EVA1.portGasIn)
    annotation (Line(points={{-4,32},{20,32}}, color={0,191,0}));
  connect(EVA1.portSteamOut,downcomer.portIn)   annotation (Line(points={{30,42},
          {30,50},{5,50},{5,26}},           color={0,127,255}));
  connect(downcomer.portOut,
                           EVA2.portWaterIn)   annotation (Line(points={{5,6},{5,
          0},{-14,0},{-14,22}},                 color={0,127,255}));
  connect(smoothing1.y,watersink_ph.hIn)       annotation (Line(points={{-65,6},
          {-48,6},{-48,102},{0,102},{0,96}},      color={0,0,127}));
  connect(smoothing2.y,watersource_mh.hIn)         annotation (Line(points={{-65,-28},
          {66,-28},{66,-21.6},{66.6,-21.6}},                   color={0,0,127}));
  connect(watersource_mh.port,EVA1.portWaterIn)     annotation (Line(points={{60,-15},
          {30,-15},{30,22}},                 color={0,127,255}));
  connect(downcomer.gasSide,prescribedHeatFlow.portsOut)
                                                      annotation (Line(
      points={{10.94,16},{24,16},{24,10}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(prescribedHeatFlow.Q_flow, realExpression.y) annotation (Line(
      points={{24,-8},{24,-14},{10.6,-14}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(watersink_ph.port, massFlowRate.port_b)       annotation (Line(
      points={{-14,88},{-14.5,88},{-14.5,68}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(massFlowRate.port_a,EVA2.portSteamOut)
                                               annotation (Line(
      points={{-14.5,51},{-14.5,42},{-14,42}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(temperature.port,EVA2.portSteamOut)
                                            annotation (Line(
      points={{-36,64},{-36,42},{-14,42}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(pressure.port, watersource_mh.port)       annotation (Line(
      points={{60,-2},{60,-15}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(hr_water.y, smoothing1.u) annotation (Line(
      points={{-87,6},{-79,6}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(p_out_water.y, smoothing.u) annotation (Line(
      points={{-87,-8},{-79,-8}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(h_in_water.y, smoothing2.u) annotation (Line(
      points={{-87,-28},{-79,-28}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(m_in_water.y,watersource_mh.m_flow_in)       annotation (Line(
      points={{-87,-48},{76,-48},{76,-21.6},{75.4,-21.6}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(smoothing.y,watersink_ph.pIn)       annotation (Line(
      points={{-65,-8},{-46,-8},{-46,100},{-8,100},{-8,96}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(pressure.p, ausgang[1]) annotation (Line(
      points={{71,7},{88,7},{88,53.3333},{100,53.3333}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(temperature.T, ausgang[3]) annotation (Line(
      points={{-30.4,74},{88,74},{88,66.6667},{100,66.6667}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(massFlowRate.m_flow, ausgang[2]) annotation (Line(
      points={{-5.15,59.5},{93.95,59.5},{93.95,60},{100,60}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(massflowSource_h.port, EVA2.portGasIn) annotation (Line(
      points={{-54,32},{-24,32}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(boundary_ph.portGas, EVA1.portGasOut) annotation (Line(
      points={{70,32},{70,46},{48,46},{48,32},{40,32}},
      color={0,191,0},
      smooth=Smooth.None));
  connect(p_out_gas.y, boundary_ph.p_In) annotation (Line(
      points={{-87,70},{-84,70},{-84,106},{66.8,106},{66.8,36.8}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(T_in_gas.y, massflowSource_h.T_set) annotation (Line(
      points={{-83,32},{-80,32},{-80,46},{-64,46},{-64,38}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(m_in_gas.y, massflowSource_h.m_flow_set) annotation (Line(
      points={{-87,56},{-70,56},{-70,38}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(T_gas.y, boundary_ph.T_In) annotation (Line(
      points={{101,32},{106,32},{106,48},{62,48},{62,39.2}},
      color={0,0,127},
      smooth=Smooth.None));
  annotation (uses(Modelica(version="2.2.1"), SiemensPower(version="0.9")),
      Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-110,-55},{
            110,110}}), graphics={Text(
          extent={{-10,46},{0,38}},
          lineColor={255,0,0},
          textString="EVA1"), Text(
          extent={{34,46},{44,38}},
          lineColor={255,0,0},
          textString="EVA2")}),
    Icon(coordinateSystem(preserveAspectRatio=true,  extent={{-110,-55},{110,
            110}}), graphics={
        Rectangle(extent={{-100,100},{100,-100}}, lineColor={0,0,0}),
        Ellipse(
          extent={{-34,-90},{26,-66}},
          lineColor={255,255,255},
          fillColor={0,128,255},
          fillPattern=FillPattern.Solid),
        Ellipse(
          extent={{-20,-72},{-16,-76}},
          lineColor={255,255,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Ellipse(
          extent={{4,-80},{8,-84}},
          lineColor={255,255,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid)}),
    Documentation(info="<HTML>
        <p>
           This is a test case for CouterCurrentHeatExchanger
        </p>
         <p>
           <table>
                <tr>
                              <td><b>Author:</b>  </td>
                              <td><a href=\"mailto:yongqi.sun@siemens.com\">Yongqi Sun</a> </td>
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
           </table>
                Copyright &copy  2008 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
     </HTML>"),
     experiment(StopTime=1,
     NumberOfIntervals=500));
end ParallelFlowEvaporatorOwnMedia_test;
