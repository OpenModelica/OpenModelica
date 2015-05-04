within SiemensPower.Components.HeatExchanger.Tests;
model ParallelFlowEvaporatorOwnMedia_testsimple
  "Evaporator of Liegender Benson with parallel gas and water flow, with analytical Jacobian"

   parameter Integer N=2 "Number of water/steam cells per tube layer";

 //   redeclare package GasMedium =
 //       SiemensPower.Media.ExhaustGasSingleComponent,

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
    numberOfTubeLayers=1)
    annotation (Placement(transformation(extent={{-24,22},{-4,42}}, rotation=0)));
 //   redeclare package GasMedium =
 //       SiemensPower.Media.ExhaustGasSingleComponent,

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
  Boundaries.GasSource                     massflowSource_h(use_T_set=true,
      use_m_flow_set=true)
    annotation (Placement(transformation(extent={{-74,22},{-54,42}})));
 //   redeclare package Medium =
 //       SiemensPower.Media.ExhaustGasSingleComponent,
  Boundaries.GasSinkP                 boundary_ph(use_p_In=true, use_T_In=true)
    annotation (Placement(transformation(extent={{70,24},{54,40}})));
 //   redeclare package Medium =
 //       SiemensPower.Media.ExhaustGasSingleComponent,
  /*
  Modelica.Fluid.Sensors.MassFlowRate massFlowRate(redeclare package Medium =
        Modelica.Media.Water.StandardWater) annotation (Placement(
        transformation(
        extent={{-8,9},{9,-8}},
        rotation=90,
        origin={-14,59})));
  Modelica.Fluid.Sensors.Temperature temperature(redeclare package Medium =
        Modelica.Media.Water.StandardWater)
    annotation (Placement(transformation(extent={{-44,64},{-28,84}})));
  Modelica.Fluid.Sensors.Pressure pressure(redeclare package Medium =
        Modelica.Media.Water.StandardWater)
    annotation (Placement(transformation(extent={{50,-2},{70,16}})));
  */

  SiemensPower.Blocks.TimeTable h_in_gas(timeDelay=
                                              0.5, table=[0,121.894e3; 10,
        121.894e3; 900,537.432e3; 1000,537.432e3])
                     annotation (Placement(transformation(extent={{-130,32},{
            -110,52}},
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
  Modelica.Blocks.Sources.RealExpression T_gas(y=116.95 + 273.15)
    annotation (Placement(transformation(extent={{80,32},{100,52}},  rotation=0)));
  Blocks.TimeTable T_in_gas(timeDelay=0.5, table=[0,116.85 + 273.15; 10,116.85
         + 273.15; 900,491.7 + 273.15; 1000,491.7 + 273.15])
                     annotation (Placement(transformation(extent={{-106,20},{
            -86,40}},
                  rotation=0)));
equation

//  connect(smoothing1.y,watersink_ph.h_set);

/*  connect(smoothing2.y,watersource_mh.port)         annotation (Line(points={{-65,-28},
          {66,-28},{66,-15},{60,-15}},                         color={0,0,127}));
    connect(smoothing2.y,watersource_mh.hIn);
*/
  connect(smoothing1.y, watersink_ph.hIn) annotation (Line(
      points={{-65,6},{-32,6},{-32,96},{0,96}},
      color={0,0,127},
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
/*  connect(m_in_water.y,watersource_mh.port)       annotation (Line(
      points={{-87,-48},{76,-48},{76,-15},{60,-15}},
      color={0,0,127},
      smooth=Smooth.None));
    connect(m_in_water.y,watersource_mh.m_flowIn)
    connect(smoothing.y,watersink_ph.p_set);
*/
  connect(smoothing1.y, watersink_ph.hIn) annotation (Line(
      points={{-65,6},{-32,6},{-32,96},{0,96}},
      color={0,0,127},
      smooth=Smooth.None));

  connect(EVA2.portWaterIn, watersource_mh.port) annotation (Line(
      points={{-14,22},{24,22},{24,-15},{60,-15}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(EVA2.portSteamOut, watersink_ph.port) annotation (Line(
      points={{-14,42},{-14,88}},
      color={0,127,255},
      smooth=Smooth.None));

  connect(smoothing1.y, watersink_ph.hIn) annotation (Line(
      points={{-65,6},{-32,6},{-32,96},{0,96}},
      color={0,0,127},
      smooth=Smooth.None));

  connect(smoothing.y, watersink_ph.pIn) annotation (Line(
      points={{-65,-8},{-36,-8},{-36,96},{-8,96}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(smoothing2.y, watersource_mh.hIn) annotation (Line(
      points={{-65,-28},{-66,-28},{-66,-34},{66,-34},{66,-22},{66.6,-21.6}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(m_in_water.y, watersource_mh.m_flow_in) annotation (Line(
      points={{-87,-48},{-8,-48},{-8,-46},{75.4,-46},{75.4,-21.6}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(massflowSource_h.port, EVA2.portGasIn) annotation (Line(
      points={{-54,32},{-24,32}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(boundary_ph.portGas, EVA2.portGasOut) annotation (Line(
      points={{70,32},{74,32},{74,48},{30,48},{30,32},{-4,32}},
      color={0,191,0},
      smooth=Smooth.None));
  connect(p_out_gas.y, boundary_ph.p_In) annotation (Line(
      points={{-87,70},{-76,70},{-76,68},{-64,68},{-64,100},{66.8,100},{66.8,
          36.8}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(T_gas.y, boundary_ph.T_In) annotation (Line(
      points={{101,42},{102,42},{102,58},{60,58},{60,39.2},{62,39.2}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(T_in_gas.y, massflowSource_h.T_set) annotation (Line(
      points={{-85,30},{-82,30},{-82,32},{-80,32},{-80,46},{-64,46},{-64,38}},
      color={0,0,127},
      smooth=Smooth.None));
  connect(m_in_gas.y, massflowSource_h.m_flow_set) annotation (Line(
      points={{-87,56},{-70,56},{-70,38}},
      color={0,0,127},
      smooth=Smooth.None));
  annotation (uses(Modelica(version="2.2.1"), SiemensPower(version="0.9")),
      Diagram(coordinateSystem(preserveAspectRatio=true,  extent={{-110,-55},{
            110,110}}), graphics={Text(
          extent={{-2,54},{8,46}},
          lineColor={255,0,0},
          textString="EVA1")}),
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
                <tr>
                           <td><b>Used Dymola version:</b>    </td>
                           <td>6.1 </td>
                  </tr>
           </table>
                Copyright &copy  2008 Siemens AG, PG EIP12. All rights reserved.<br> <br>
               This model is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
           For details see <a href=\"../Documents/Disclaimer.html\">disclaimer</a> <br>
        </p>
     </HTML>"),
     experiment(StopTime=1,
     NumberOfIntervals=500));
end ParallelFlowEvaporatorOwnMedia_testsimple;
