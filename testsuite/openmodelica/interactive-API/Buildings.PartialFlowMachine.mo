package Buildings  "Library with models for building energy and control systems"
extends Modelica.Icons.Package;

package Fluid  "Package with models for fluid flow systems"
extends Modelica.Icons.Package;

package Delays  "Package with delay models"
extends Modelica.Icons.VariantsPackage;

model DelayFirstOrder  "Delay element, approximated by a first order differential equation"
extends Buildings.Fluid.MixingVolumes.MixingVolume(final V = V_nominal, final mSenFac = 1);
parameter Modelica.SIunits.Time tau = 60 "Time constant at nominal flow" annotation(Dialog(tab = "Dynamics", group = "Nominal condition"));
protected
parameter Modelica.SIunits.Volume V_nominal = m_flow_nominal * tau / rho_default "Volume of delay element";
annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-100, 98}, {100, -102}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Sphere, fillColor = {170, 213, 255}), Text(extent = {{-72, 22}, {68, -18}}, lineColor = {0, 0, 0}, textString = "tau=%tau")}), defaultComponentName = "del");
end DelayFirstOrder;
annotation(preferredView = "info");
end Delays;

package MixingVolumes  "Package with mixing volumes"
extends Modelica.Icons.VariantsPackage;

model MixingVolume  "Mixing volume with inlet and outlet ports (flow reversal is allowed)"
extends Buildings.Fluid.MixingVolumes.BaseClasses.PartialMixingVolume;
equation
connect(QSen_flow.y, steBal.Q_flow) annotation(Line(points = {{-19, 88}, {0, 88}, {0, 18}, {8, 18}}, color = {0, 0, 127}));
connect(QSen_flow.y, dynBal.Q_flow) annotation(Line(points = {{-19, 88}, {54, 88}, {54, 16}, {58, 16}}, color = {0, 0, 127}));
annotation(defaultComponentName = "vol", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-100, 98}, {100, -102}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Sphere, fillColor = {170, 213, 255}), Text(extent = {{-58, 14}, {58, -18}}, lineColor = {0, 0, 0}, textString = "V=%V"), Text(extent = {{-152, 100}, {148, 140}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})));
end MixingVolume;

package BaseClasses  "Package with base classes for Buildings.Fluid.MixingVolumes"
extends Modelica.Icons.BasesPackage;

partial model PartialMixingVolume  "Partial mixing volume with inlet and outlet ports (flow reversal is allowed)"
extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations;
constant Boolean initialize_p = not Medium.singleState "= true to set up initial equations for pressure" annotation(HideResult = true);
constant Boolean prescribedHeatFlowRate = false "Set to true if the model has a prescribed heat flow at its heatPort. If the heat flow rate at the heatPort is only based on temperature difference, then set to false";
constant Boolean simplify_mWat_flow = true "Set to true to cause port_a.m_flow + port_b.m_flow = 0 even if mWat_flow is non-zero";
parameter Boolean use_C_flow = false "Set to true to enable input connector for trace substance" annotation(Evaluate = true, Dialog(tab = "Advanced"));
parameter Modelica.SIunits.MassFlowRate m_flow_nominal(min = 0) "Nominal mass flow rate" annotation(Dialog(group = "Nominal condition"));
parameter Integer nPorts = 0 "Number of ports" annotation(Evaluate = true, Dialog(connectorSizing = true, tab = "General", group = "Ports"));
parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * abs(m_flow_nominal) "Small mass flow rate for regularization of zero flow" annotation(Dialog(tab = "Advanced"));
parameter Boolean allowFlowReversal = true "= false to simplify equations, assuming, but not enforcing, no flow reversal. Used only if model has two ports." annotation(Dialog(tab = "Assumptions"), Evaluate = true);
parameter Modelica.SIunits.Volume V "Volume";
Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b[nPorts] ports(redeclare each package Medium = Medium) "Fluid inlets and outlets" annotation(Placement(transformation(extent = {{-40, -10}, {40, 10}}, origin = {0, -100})));
Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort(T(start = T_start)) "Heat port for sensible heat input" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
Medium.Temperature T = Medium.temperature_phX(p = p, h = hOut_internal, X = cat(1, Xi, {1 - sum(Xi)})) "Temperature of the fluid";
Modelica.Blocks.Interfaces.RealOutput U(unit = "J") "Internal energy of the component";
Modelica.SIunits.Pressure p = if nPorts > 0 then ports[1].p else p_start "Pressure of the fluid";
Modelica.Blocks.Interfaces.RealOutput m(unit = "kg") "Mass of the component";
Modelica.SIunits.MassFraction[Medium.nXi] Xi = XiOut_internal "Species concentration of the fluid";
Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] mXi(each unit = "kg") "Species mass of the component";
Medium.ExtraProperty[Medium.nC] C(nominal = C_nominal) = COut_internal "Trace substance mixture content";
Modelica.Blocks.Interfaces.RealOutput[Medium.nC] mC(each unit = "kg") "Trace substance mass of the component";
Modelica.Blocks.Interfaces.RealInput[Medium.nC] C_flow if use_C_flow "Trace substance mass flow rate added to the medium" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
protected
Buildings.Fluid.Interfaces.StaticTwoPortConservationEquation steBal(final simplify_mWat_flow = simplify_mWat_flow, final use_C_flow = use_C_flow, redeclare final package Medium = Medium, final m_flow_nominal = m_flow_nominal, final allowFlowReversal = allowFlowReversal, final m_flow_small = m_flow_small, final prescribedHeatFlowRate = prescribedHeatFlowRate) if useSteadyStateTwoPort "Model for steady-state balance if nPorts=2" annotation(Placement(transformation(extent = {{10, 0}, {30, 20}})));
Buildings.Fluid.Interfaces.ConservationEquation dynBal(final simplify_mWat_flow = simplify_mWat_flow, final use_C_flow = use_C_flow, redeclare final package Medium = Medium, final energyDynamics = energyDynamics, final massDynamics = massDynamics, final p_start = p_start, final T_start = T_start, final X_start = X_start, final C_start = C_start, final C_nominal = C_nominal, final fluidVolume = V, final initialize_p = initialize_p, m(start = V * rho_start), nPorts = nPorts, final mSenFac = mSenFac) if not useSteadyStateTwoPort "Model for dynamic energy balance" annotation(Placement(transformation(extent = {{60, 0}, {80, 20}})));
parameter Modelica.SIunits.Density rho_start = Medium.density(state = state_start) "Density, used to compute start and guess values";
final parameter Medium.ThermodynamicState state_default = Medium.setState_pTX(T = Medium.T_default, p = Medium.p_default, X = Medium.X_default[1:Medium.nXi]) "Medium state at default values";
final parameter Modelica.SIunits.Density rho_default = Medium.density(state = state_default) "Density, used to compute fluid mass";
final parameter Medium.ThermodynamicState state_start = Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi]) "Medium state at start values";
final parameter Boolean useSteadyStateTwoPort = nPorts == 2 and (prescribedHeatFlowRate or not allowFlowReversal) and energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState and traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState "Flag, true if the model has two ports only and uses a steady state balance" annotation(Evaluate = true);
Modelica.Blocks.Interfaces.RealOutput hOut_internal(unit = "J/kg") "Internal connector for leaving temperature of the component";
Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] XiOut_internal(each unit = "1") "Internal connector for leaving species concentration of the component";
Modelica.Blocks.Interfaces.RealOutput[Medium.nC] COut_internal(each unit = "1") "Internal connector for leaving trace substances of the component";
Modelica.Blocks.Sources.RealExpression QSen_flow(y = heatPort.Q_flow) "Block to set sensible heat input into volume" annotation(Placement(transformation(extent = {{-40, 78}, {-20, 98}})));
Buildings.HeatTransfer.Sources.PrescribedTemperature preTem "Port temperature" annotation(Placement(transformation(extent = {{-68, 10}, {-88, 30}})));
Modelica.Blocks.Sources.RealExpression portT(y = T) "Port temperature" annotation(Placement(transformation(extent = {{-40, 10}, {-60, 30}})));
equation
if not allowFlowReversal then
assert(ports[1].m_flow > (-m_flow_small), "Model has flow reversal, but the parameter allowFlowReversal is set to false.
m_flow_small    = " + String(m_flow_small) + "
ports[1].m_flow = " + String(ports[1].m_flow) + "
");
end if;
if useSteadyStateTwoPort then
connect(steBal.port_a, ports[1]) annotation(Line(points = {{10, 10}, {0, 10}, {0, -60}, {0, -100}}, color = {0, 127, 255}));
connect(steBal.port_b, ports[2]) annotation(Line(points = {{30, 10}, {40, 10}, {40, -20}, {0, -20}, {0, -100}}, color = {0, 127, 255}));
U = 0;
mXi = zeros(Medium.nXi);
m = 0;
mC = zeros(Medium.nC);
connect(hOut_internal, steBal.hOut);
connect(XiOut_internal, steBal.XiOut);
connect(COut_internal, steBal.COut);
else
connect(dynBal.ports, ports) annotation(Line(points = {{70, 0}, {70, -20}, {2.22045e-15, -20}, {2.22045e-15, -100}}, color = {0, 127, 255}));
connect(U, dynBal.UOut);
connect(mXi, dynBal.mXiOut);
connect(m, dynBal.mOut);
connect(mC, dynBal.mCOut);
connect(hOut_internal, dynBal.hOut);
connect(XiOut_internal, dynBal.XiOut);
connect(COut_internal, dynBal.COut);
end if;
connect(steBal.C_flow, C_flow) annotation(Line(points = {{8, 6}, {-80, 6}, {-80, -60}, {-120, -60}}, color = {0, 0, 127}));
connect(dynBal.C_flow, C_flow) annotation(Line(points = {{58, 6}, {50, 6}, {50, -60}, {-120, -60}}, color = {0, 0, 127}));
connect(portT.y, preTem.T) annotation(Line(points = {{-61, 20}, {-66, 20}}, color = {0, 0, 127}));
connect(preTem.port, heatPort) annotation(Line(points = {{-88, 20}, {-92, 20}, {-92, 0}, {-100, 0}}, color = {191, 0, 0}));
annotation(defaultComponentName = "vol", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Ellipse(extent = {{-100, 98}, {100, -102}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Sphere, fillColor = {170, 213, 255}), Text(extent = {{-58, 14}, {58, -18}}, lineColor = {0, 0, 0}, textString = "V=%V"), Text(extent = {{-152, 100}, {148, 140}}, textString = "%name", lineColor = {0, 0, 255})}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})));
end PartialMixingVolume;
end BaseClasses;
end MixingVolumes;

package Movers  "Package with fan and pump models"
extends Modelica.Icons.Package;

package Data  "Package containing data for real pumps/fans"
extends Modelica.Icons.MaterialPropertiesPackage;

record Generic  "Generic data record for movers"
extends Modelica.Icons.Record;
parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParameters pressure(V_flow = {0, 0}, dp = {0, 0}) "Volume flow rate vs. total pressure rise" annotation(Evaluate = true, Dialog(group = "Pressure curve"));
parameter Boolean use_powerCharacteristic = false "Use power data instead of motor efficiency" annotation(Dialog(group = "Power computation"));
parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters hydraulicEfficiency(V_flow = {0}, eta = {0.7}) "Hydraulic efficiency (used if use_powerCharacteristic=false)" annotation(Dialog(group = "Power computation", enable = not use_powerCharacteristic));
parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters motorEfficiency(V_flow = {0}, eta = {0.7}) "Electric motor efficiency (used if use_powerCharacteristic=false)" annotation(Dialog(group = "Power computation", enable = not use_powerCharacteristic));
parameter BaseClasses.Characteristics.powerParameters power(V_flow = {0}, P = {0}) "Volume flow rate vs. electrical power consumption (used if use_powerCharacteristic=true)" annotation(Dialog(group = "Power computation", enable = use_powerCharacteristic));
parameter Boolean motorCooledByFluid = true "If true, then motor heat is added to fluid stream" annotation(Dialog(group = "Motor heat rejection"));
parameter Real speed_nominal(final min = 0, final unit = "1") = 1 "Nominal rotational speed for flow characteristic" annotation(Dialog(group = "Normalized speeds (used in model, default values assigned from speeds in rpm"));
parameter Real constantSpeed(final min = 0, final unit = "1") = constantSpeed_rpm / speed_rpm_nominal "Normalized speed set point, used if inputType = Buildings.Fluid.Types.InputType.Constant" annotation(Dialog(group = "Normalized speeds (used in model, default values assigned from speeds in rpm"));
parameter Real[:] speeds(each final min = 0, each final unit = "1") = speeds_rpm / speed_rpm_nominal "Vector of normalized speed set points, used if inputType = Buildings.Fluid.Types.InputType.Stages" annotation(Dialog(group = "Normalized speeds (used in model, default values assigned from speeds in rpm"));
parameter Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm speed_rpm_nominal = 1500 "Nominal rotational speed for flow characteristic" annotation(Dialog(group = "Speeds in RPM"));
parameter Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm constantSpeed_rpm = speed_rpm_nominal "Speed set point, used if inputType = Buildings.Fluid.Types.InputType.Constant" annotation(Dialog(group = "Speeds in RPM"));
parameter Modelica.SIunits.Conversions.NonSIunits.AngularVelocity_rpm[:] speeds_rpm = {speed_rpm_nominal} "Vector of speed set points, used if inputType = Buildings.Fluid.Types.InputType.Stages" annotation(Dialog(group = "Speeds in RPM"));
final parameter Boolean havePressureCurve = sum(pressure.V_flow) > Modelica.Constants.eps and sum(pressure.dp) > Modelica.Constants.eps "= true, if default record values are being used";
annotation(defaultComponentPrefixes = "parameter", defaultComponentName = "per", Documentation(revisions = "<html>
<ul>
<li>
February 19, 2016, by Filip Jorissen:<br/>
Refactored model such that <code>SpeedControlled_Nrpm</code>,
<code>SpeedControlled_y</code> and <code>FlowControlled</code>
are integrated into one record.
This is for
<a href=\"https://github.com/iea-annex60/modelica-annex60/issues/417\">#417</a>.
</li>
<li>
February 17, 2016, by Michael Wetter:<br/>
Changed parameter <code>N_nominal</code> to
<code>speed_rpm_nominal</code> as it is the same quantity as <code>speeds_rmp</code>.
This is for
<a href=\"https://github.com/iea-annex60/modelica-annex60/issues/396\">#396</a>.
</li>
<li>
January 19, 2016, by Filip Jorissen:<br/>
Added parameter <code>speeds_rpm</code>.
This is for
<a href=\"https://github.com/iea-annex60/modelica-annex60/issues/396\">#396</a>.
</li>
<li>
February 13, 2015, by Michael Wetter:<br/>
Updated documentation.
</li>
<li>
January 6, 2015, by Michael Wetter:<br/>
Revised record for OpenModelica.
</li>
<li>
November 22, 2014 by Michael Wetter:<br/>
First implementation.
</li>
</ul>
</html>", info = "<html>
<p>
Record containing parameters for pumps or fans.
</p>
<h4>Typical use</h4>
<p>
This record may be used to assign for example fan performance data using
declaration such as
</p>
<pre>
Buildings.Fluid.Movers.SpeedControlled_y fan(
redeclare package Medium = Medium,
per(pressure(V_flow={0,m_flow_nominal,2*m_flow_nominal}/1.2,
dp={2*dp_nominal,dp_nominal,0}))) \"Fan\";
</pre>
<p>
This data record can be used with
<a href=\"modelica://Buildings.Fluid.Movers.SpeedControlled_Nrpm\">
Buildings.Fluid.Movers.SpeedControlled_Nrpm</a>,
<a href=\"modelica://Buildings.Fluid.Movers.SpeedControlled_y\">
Buildings.Fluid.Movers.SpeedControlled_y</a>,
<a href=\"modelica://Buildings.Fluid.Movers.FlowControlled_dp\">
Buildings.Fluid.Movers.FlowControlled_dp</a>,
<a href=\"modelica://Buildings.Fluid.Movers.FlowControlled_m_flow\">
Buildings.Fluid.Movers.FlowControlled_m_flow</a>.
</p>
<p>
An example that uses manufacturer data can be found in
<a href=\"modelica://Buildings.Fluid.Movers.Validation.Pump_Nrpm_stratos\">
Buildings.Fluid.Movers.Validation.Pump_Nrpm_stratos</a>.
</p>
<h4>Parameters in RPM</h4>
<p>
The parameters <code>speed_rpm_nominal</code>,
<code>constantSpeed_rpm</code> and
<code>speeds_rpm</code> are used to assign the non-dimensional speeds
</p>
<pre>
parameter Real constantSpeed(final min=0, final unit=\"1\") = constantSpeed_rpm/speed_rpm_nominal;
parameter Real[:] speeds(each final min = 0, each final unit=\"1\") = speeds_rpm/speed_rpm_nominal;
</pre>
<p>
In addition, <code>speed_rpm_nominal</code> is used in
<a href=\"modelica://Buildings.Fluid.Movers.SpeedControlled_Nrpm\">
Buildings.Fluid.Movers.SpeedControlled_Nrpm</a>
to normalize the control input signal.
Otherwise, these speed parameters in RPM are not used in the models.
</p>
</html>"));
end Generic;
end Data;

package BaseClasses  "Package with base classes for Buildings.Fluid.Movers"
extends Modelica.Icons.BasesPackage;

model FlowMachineInterface  "Partial model with performance curves for fans or pumps"
extends Modelica.Blocks.Interfaces.BlockIcon;
parameter Buildings.Fluid.Movers.Data.Generic per "Record with performance data" annotation(choicesAllMatching = true, Placement(transformation(extent = {{60, -80}, {80, -60}})));
parameter Buildings.Fluid.Movers.BaseClasses.Types.PrescribedVariable preVar = Types.PrescribedVariable.Speed "Type of prescribed variable";
parameter Boolean computePowerUsingSimilarityLaws "= true, compute power exactly, using similarity laws. Otherwise approximate.";
final parameter Modelica.SIunits.VolumeFlowRate V_flow_nominal = per.pressure.V_flow[nOri] "Nominal volume flow rate, used for homotopy";
parameter Modelica.SIunits.Density rho_default "Fluid density at medium default state";
parameter Boolean haveVMax "Flag, true if user specified data that contain V_flow_max";
parameter Modelica.SIunits.VolumeFlowRate V_flow_max "Maximum volume flow rate, used for smoothing";
parameter Integer nOri(min = 1) "Number of data points for pressure curve" annotation(Evaluate = true);
parameter Boolean homotopyInitialization = true "= true, use homotopy method" annotation(Evaluate = true, Dialog(tab = "Advanced"));
Modelica.Blocks.Interfaces.RealInput y_in(final unit = "1") if preSpe "Prescribed mover speed" annotation(Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = 270, origin = {-40, 120})));
Modelica.Blocks.Interfaces.RealOutput y_out(final unit = "1") "Mover speed (prescribed or computed)" annotation(Placement(transformation(extent = {{100, 90}, {120, 110}})));
Modelica.Blocks.Interfaces.RealInput m_flow(final quantity = "MassFlowRate", final unit = "kg/s") "Mass flow rate" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
Modelica.Blocks.Interfaces.RealInput rho(final quantity = "Density", final unit = "kg/m3", min = 0.0) "Medium density" annotation(Placement(transformation(extent = {{-140, -80}, {-100, -40}})));
Modelica.Blocks.Interfaces.RealOutput V_flow(quantity = "VolumeFlowRate", final unit = "m3/s") "Volume flow rate" annotation(Placement(transformation(extent = {{100, 38}, {120, 58}}), iconTransformation(extent = {{100, 38}, {120, 58}})));
Modelica.Blocks.Interfaces.RealInput dp_in(quantity = "PressureDifference", final unit = "Pa") if prePre "Prescribed pressure increase" annotation(Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = 270, origin = {40, 120})));
Modelica.Blocks.Interfaces.RealOutput dp(quantity = "Pressure", final unit = "Pa") if not prePre "Pressure increase (computed or prescribed)" annotation(Placement(transformation(extent = {{100, 70}, {120, 90}})));
Modelica.Blocks.Interfaces.RealOutput WFlo(quantity = "Power", final unit = "W") "Flow work" annotation(Placement(transformation(extent = {{100, 10}, {120, 30}})));
Modelica.Blocks.Interfaces.RealOutput PEle(quantity = "Power", final unit = "W") "Electrical power consumed" annotation(Placement(transformation(extent = {{100, -20}, {120, 0}}), iconTransformation(extent = {{100, -20}, {120, 0}})));
Modelica.Blocks.Interfaces.RealOutput eta(final quantity = "Efficiency", final unit = "1") "Overall efficiency" annotation(Placement(transformation(extent = {{100, -50}, {120, -30}}), iconTransformation(extent = {{100, -50}, {120, -30}})));
Modelica.Blocks.Interfaces.RealOutput etaHyd(final quantity = "Efficiency", final unit = "1") "Hydraulic efficiency" annotation(Placement(transformation(extent = {{100, -80}, {120, -60}}), iconTransformation(extent = {{100, -80}, {120, -60}})));
Modelica.Blocks.Interfaces.RealOutput etaMot(final quantity = "Efficiency", final unit = "1") "Motor efficiency" annotation(Placement(transformation(extent = {{100, -110}, {120, -90}}), iconTransformation(extent = {{100, -110}, {120, -90}})));
Modelica.Blocks.Interfaces.RealOutput r_N(unit = "1") "Ratio N_actual/N_nominal";
Real r_V(start = 1, unit = "1") "Ratio V_flow/V_flow_max";
protected
final parameter Boolean preSpe = preVar == Types.PrescribedVariable.Speed "True if speed is a prescribed variable of this block";
final parameter Boolean prePre = preVar == Types.PrescribedVariable.PressureDifference or preVar == Types.PrescribedVariable.FlowRate "True if pressure head is a prescribed variable of this block";
final parameter Real[size(per.motorEfficiency.V_flow, 1)] motDer(each fixed = false) "Coefficients for polynomial of motor efficiency vs. volume flow rate";
final parameter Real[size(per.hydraulicEfficiency.V_flow, 1)] hydDer(each fixed = false) "Coefficients for polynomial of hydraulic efficiency vs. volume flow rate";
parameter Modelica.SIunits.PressureDifference dpMax(displayUnit = "Pa") = if haveDPMax then per.pressure.dp[1] else per.pressure.dp[1] - (per.pressure.dp[2] - per.pressure.dp[1]) / (per.pressure.V_flow[2] - per.pressure.V_flow[1]) * per.pressure.V_flow[1] "Maximum head";
parameter Real delta = 0.05 "Small value used to for regularization and to approximate an internal flow resistance of the fan";
parameter Real kRes(min = 0, unit = "kg/(s.m4)") = dpMax / V_flow_max * delta ^ 2 / 10 "Coefficient for internal pressure drop of fan or pump";
parameter Integer curve = if haveVMax and haveDPMax or nOri == 2 then 1 elseif haveVMax or haveDPMax then 2 else 3 "Flag, used to pick the right representatio of the fan or pump pressure curve";
final parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal pCur1(final n = nOri, final V_flow = if haveVMax and haveDPMax or nOri == 2 then {per.pressure.V_flow[i] for i in 1:nOri} else zeros(nOri), final dp = if haveVMax and haveDPMax or nOri == 2 then {per.pressure.dp[i] + per.pressure.V_flow[i] * kRes for i in 1:nOri} else zeros(nOri)) "Volume flow rate vs. total pressure rise with correction for pump resistance added";
parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal pCur2(final n = nOri + 1, V_flow = if haveVMax and haveDPMax or nOri == 2 then zeros(nOri + 1) elseif haveVMax then cat(1, {0}, {per.pressure.V_flow[i] for i in 1:nOri})
elseif haveDPMax then cat(1, {per.pressure.V_flow[i] for i in 1:nOri}, {V_flow_max}) else zeros(nOri + 1), dp = if haveVMax and haveDPMax or nOri == 2 then zeros(nOri + 1) elseif haveVMax then cat(1, {dpMax}, {per.pressure.dp[i] + per.pressure.V_flow[i] * kRes for i in 1:nOri})
elseif haveDPMax then cat(1, {per.pressure.dp[i] + per.pressure.V_flow[i] * kRes for i in 1:nOri}, {0}) else zeros(nOri + 1)) "Volume flow rate vs. total pressure rise with correction for pump resistance added";
parameter Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal pCur3(final n = nOri + 2, V_flow = if haveVMax and haveDPMax or nOri == 2 then zeros(nOri + 2) elseif haveVMax or haveDPMax then zeros(nOri + 2) else cat(1, {0}, {per.pressure.V_flow[i] for i in 1:nOri}, {V_flow_max}), dp = if haveVMax and haveDPMax or nOri == 2 then zeros(nOri + 2) elseif haveVMax or haveDPMax then zeros(nOri + 2) else cat(1, {dpMax}, {per.pressure.dp[i] + per.pressure.V_flow[i] * kRes for i in 1:nOri}, {0})) "Volume flow rate vs. total pressure rise with correction for pump resistance added";
parameter Real[nOri] preDer1(each fixed = false) "Derivatives of flow rate vs. pressure at the support points";
parameter Real[nOri + 1] preDer2(each fixed = false) "Derivatives of flow rate vs. pressure at the support points";
parameter Real[nOri + 2] preDer3(each fixed = false) "Derivatives of flow rate vs. pressure at the support points";
parameter Real[size(per.power.V_flow, 1)] powDer = if per.use_powerCharacteristic then Buildings.Utilities.Math.Functions.splineDerivatives(x = per.power.V_flow, y = per.power.P, ensureMonotonicity = Buildings.Utilities.Math.Functions.isMonotonic(x = per.power.P, strict = false)) else zeros(size(per.power.V_flow, 1)) "Coefficients for polynomial of power vs. flow rate";
parameter Boolean haveMinimumDecrease = Modelica.Math.BooleanVectors.allTrue({(per.pressure.dp[i + 1] - per.pressure.dp[i]) / (per.pressure.V_flow[i + 1] - per.pressure.V_flow[i]) < (-kRes) for i in 1:nOri - 1}) "Flag used for reporting";
parameter Boolean haveDPMax = abs(per.pressure.V_flow[1]) < Modelica.Constants.eps "Flag, true if user specified data that contain dpMax";
Modelica.Blocks.Interfaces.RealOutput dp_internal "If dp is prescribed, use dp_in and solve for r_N, otherwise compute dp using r_N";

function getArrayAsString
input Real[:] array "Array to be printed";
input String varName "Variable name";
input Integer minimumLength = 6 "Minimum width of result";
input Integer significantDigits = 6 "Number of significant digits";
output String str "String representation";
algorithm
str := "";
for i in 1:size(array, 1) loop
str := str + "  " + varName + "[" + String(i) + "]=" + String(array[i], minimumLength = minimumLength, significantDigits = significantDigits) + "\n";
end for;
end getArrayAsString;
initial equation
assert(nOri > 1, "Must have at least two data points for pressure.V_flow.");
assert(Buildings.Utilities.Math.Functions.isMonotonic(x = per.pressure.V_flow, strict = true) and per.pressure.V_flow[1] > (-Modelica.Constants.eps), "The fan pressure rise must be a strictly decreasing sequence with respect to the volume flow rate,
with the first element for the fan pressure raise being non-zero.
The following performance data have been entered:
" + getArrayAsString(per.pressure.V_flow, "pressure.V_flow"));
if not haveVMax then
assert((per.pressure.V_flow[nOri] - per.pressure.V_flow[nOri - 1]) / (per.pressure.dp[nOri] - per.pressure.dp[nOri - 1]) < 0, "The last two pressure points for the fan or pump performance curve must be decreasing.
You need to set more reasonable parameters.
Received
" + getArrayAsString(per.pressure.dp, "dp"));
end if;
if not haveMinimumDecrease then
Modelica.Utilities.Streams.print("
Warning:
========
It is recommended that the volume flow rate versus pressure relation
of the fan or pump satisfies the minimum decrease condition

(per.pressure.dp[i+1]-per.pressure.dp[i])
d[i] = ------------------------------------------------- < " + String(-kRes) + "
(per.pressure.V_flow[i+1]-per.pressure.V_flow[i])

is
" + getArrayAsString({(per.pressure.dp[i + 1] - per.pressure.dp[i]) / (per.pressure.V_flow[i + 1] - per.pressure.V_flow[i]) for i in 1:nOri - 1}, "d") + "
Otherwise, a solution to the equations may not exist if the fan or pump speed is reduced.
In this situation, the solver will fail due to non-convergence and
the simulation stops.");
end if;
if haveVMax and haveDPMax or nOri == 2 then
preDer1 = Buildings.Utilities.Math.Functions.splineDerivatives(x = pCur1.V_flow, y = pCur1.dp);
preDer2 = zeros(nOri + 1);
preDer3 = zeros(nOri + 2);
elseif haveVMax or haveDPMax then
preDer1 = zeros(nOri);
preDer2 = Buildings.Utilities.Math.Functions.splineDerivatives(x = pCur2.V_flow, y = pCur2.dp);
preDer3 = zeros(nOri + 2);
else
preDer1 = zeros(nOri);
preDer2 = zeros(nOri + 1);
preDer3 = Buildings.Utilities.Math.Functions.splineDerivatives(x = pCur3.V_flow, y = pCur3.dp);
end if;
motDer = if per.use_powerCharacteristic then zeros(size(per.motorEfficiency.V_flow, 1)) elseif size(per.motorEfficiency.V_flow, 1) == 1 then {0} else Buildings.Utilities.Math.Functions.splineDerivatives(x = per.motorEfficiency.V_flow, y = per.motorEfficiency.eta, ensureMonotonicity = Buildings.Utilities.Math.Functions.isMonotonic(x = per.motorEfficiency.eta, strict = false));
hydDer = if per.use_powerCharacteristic then zeros(size(per.hydraulicEfficiency.V_flow, 1)) elseif size(per.hydraulicEfficiency.V_flow, 1) == 1 then {0} else Buildings.Utilities.Math.Functions.splineDerivatives(x = per.hydraulicEfficiency.V_flow, y = per.hydraulicEfficiency.eta);
equation
connect(dp_internal, dp);
connect(dp_internal, dp_in);
connect(r_N, y_in);
y_out = r_N;
V_flow = m_flow / rho;
r_V = V_flow / V_flow_max;
if computePowerUsingSimilarityLaws == false and preVar <> Types.PrescribedVariable.Speed then
r_N = 1;
else
if curve == 1 then
if homotopyInitialization then
V_flow * kRes + dp_internal = homotopy(actual = Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1), simplified = r_N * (Characteristics.pressure(V_flow = V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1) + (V_flow - V_flow_nominal) * (Characteristics.pressure(V_flow = (1 + delta) * V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1) - Characteristics.pressure(V_flow = (1 - delta) * V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1)) / (2 * delta * V_flow_nominal)));
else
V_flow * kRes + dp_internal = Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer1, per = pCur1);
end if;
elseif curve == 2 then
if homotopyInitialization then
V_flow * kRes + dp_internal = homotopy(actual = Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2), simplified = r_N * (Characteristics.pressure(V_flow = V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2) + (V_flow - V_flow_nominal) * (Characteristics.pressure(V_flow = (1 + delta) * V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2) - Characteristics.pressure(V_flow = (1 - delta) * V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2)) / (2 * delta * V_flow_nominal)));
else
V_flow * kRes + dp_internal = Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer2, per = pCur2);
end if;
else
if homotopyInitialization then
V_flow * kRes + dp_internal = homotopy(actual = Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3), simplified = r_N * (Characteristics.pressure(V_flow = V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3) + (V_flow - V_flow_nominal) * (Characteristics.pressure(V_flow = (1 + delta) * V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3) - Characteristics.pressure(V_flow = (1 - delta) * V_flow_nominal, r_N = 1, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3)) / (2 * delta * V_flow_nominal)));
else
V_flow * kRes + dp_internal = Characteristics.pressure(V_flow = V_flow, r_N = r_N, dpMax = dpMax, V_flow_max = V_flow_max, d = preDer3, per = pCur3);
end if;
end if;
end if;
WFlo = dp_internal * V_flow;
if per.use_powerCharacteristic then
if homotopyInitialization then
PEle = homotopy(actual = Characteristics.power(per = per.power, V_flow = V_flow, r_N = r_N, d = powDer, delta = delta), simplified = V_flow / V_flow_nominal * Characteristics.power(per = per.power, V_flow = V_flow_nominal, r_N = 1, d = powDer, delta = delta));
else
PEle = rho / rho_default * Characteristics.power(per = per.power, V_flow = V_flow, r_N = r_N, d = powDer, delta = delta);
end if;
eta = WFlo / Buildings.Utilities.Math.Functions.smoothMax(x1 = PEle, x2 = 1E-5, deltaX = 1E-6);
etaHyd = 1;
etaMot = eta;
else
if homotopyInitialization then
etaHyd = homotopy(actual = Characteristics.efficiency(per = per.hydraulicEfficiency, V_flow = V_flow, d = hydDer, r_N = r_N, delta = delta), simplified = Characteristics.efficiency(per = per.hydraulicEfficiency, V_flow = V_flow_max, d = hydDer, r_N = r_N, delta = delta));
etaMot = homotopy(actual = Characteristics.efficiency(per = per.motorEfficiency, V_flow = V_flow, d = motDer, r_N = r_N, delta = delta), simplified = Characteristics.efficiency(per = per.motorEfficiency, V_flow = V_flow_max, d = motDer, r_N = r_N, delta = delta));
else
etaHyd = Characteristics.efficiency(per = per.hydraulicEfficiency, V_flow = V_flow, d = hydDer, r_N = r_N, delta = delta);
etaMot = Characteristics.efficiency(per = per.motorEfficiency, V_flow = V_flow, d = motDer, r_N = r_N, delta = delta);
end if;
PEle = WFlo / Buildings.Utilities.Math.Functions.smoothMax(x1 = eta, x2 = 1E-5, deltaX = 1E-6);
eta = etaHyd * etaMot;
end if;
annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Text(extent = {{56, 66}, {106, 52}}, lineColor = {0, 0, 127}, textString = "dp"), Text(extent = {{56, 8}, {106, -6}}, lineColor = {0, 0, 127}, textString = "PEle"), Text(extent = {{52, -22}, {102, -36}}, lineColor = {0, 0, 127}, textString = "eta"), Text(extent = {{50, -52}, {100, -66}}, lineColor = {0, 0, 127}, textString = "etaHyd"), Text(extent = {{50, -72}, {100, -86}}, lineColor = {0, 0, 127}, textString = "etaMot"), Ellipse(extent = {{-78, 34}, {44, -88}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-62, 18}, {28, -72}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Ellipse(extent = {{-26, -18}, {-8, -36}}, lineColor = {0, 0, 0}, fillColor = {100, 100, 100}, fillPattern = FillPattern.Solid), Polygon(points = {{-26, -22}, {-32, -8}, {-30, 10}, {-8, 20}, {-6, 14}, {-24, 6}, {-24, -8}, {-18, -20}, {-26, -22}}, lineColor = {0, 0, 0}, fillColor = {100, 100, 100}, fillPattern = FillPattern.Solid, smooth = Smooth.Bezier), Polygon(points = {{-8, -32}, {-2, -46}, {-4, -64}, {-26, -74}, {-28, -68}, {-10, -60}, {-10, -46}, {-16, -34}, {-8, -32}}, lineColor = {0, 0, 0}, fillColor = {100, 100, 100}, fillPattern = FillPattern.Solid, smooth = Smooth.Bezier), Polygon(points = {{7, 21}, {13, 7}, {11, -11}, {-11, -21}, {-13, -15}, {5, -7}, {5, 7}, {-1, 19}, {7, 21}}, lineColor = {0, 0, 0}, fillColor = {100, 100, 100}, fillPattern = FillPattern.Solid, smooth = Smooth.Bezier, origin = {9, -23}, rotation = 90), Polygon(points = {{-7, -21}, {-13, -7}, {-11, 11}, {11, 21}, {13, 15}, {-5, 7}, {-5, -7}, {1, -19}, {-7, -21}}, lineColor = {0, 0, 0}, fillColor = {100, 100, 100}, fillPattern = FillPattern.Solid, smooth = Smooth.Bezier, origin = {-43, -31}, rotation = 90), Text(extent = {{56, 36}, {106, 22}}, lineColor = {0, 0, 127}, textString = "WFlo"), Text(extent = {{56, 94}, {106, 80}}, lineColor = {0, 0, 127}, textString = "V_flow"), Line(points = {{-74, 92}, {-74, 40}}, color = {0, 0, 0}, smooth = Smooth.Bezier), Line(points = {{-74, 40}, {46, 40}}, color = {0, 0, 0}, smooth = Smooth.Bezier), Line(points = {{-70, 86}, {-40, 84}, {8, 68}, {36, 42}}, color = {0, 0, 0}, smooth = Smooth.Bezier)}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})));
end FlowMachineInterface;

model IdealSource  "Base class for pressure and mass flow source with optional power input"
extends Buildings.Fluid.Interfaces.PartialTwoPortTransport(show_T = false);
parameter Boolean control_m_flow "= false to control dp instead of m_flow" annotation(Evaluate = true);
Modelica.Blocks.Interfaces.RealInput m_flow_in(unit = "kg/s") if control_m_flow "Prescribed mass flow rate" annotation(Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = -90, origin = {-50, 82}), iconTransformation(extent = {{-20, -20}, {20, 20}}, rotation = -90, origin = {-60, 80})));
Modelica.Blocks.Interfaces.RealInput dp_in(unit = "Pa") if not control_m_flow "Prescribed pressure difference port_a.p-port_b.p" annotation(Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = -90, origin = {50, 82}), iconTransformation(extent = {{-20, -20}, {20, 20}}, rotation = -90, origin = {60, 80})));
protected
Modelica.Blocks.Interfaces.RealInput m_flow_internal(unit = "kg/s") "Needed to connect to conditional connector";
Modelica.Blocks.Interfaces.RealInput dp_internal(unit = "Pa") "Needed to connect to conditional connector";
equation
if control_m_flow then
m_flow = m_flow_internal;
dp_internal = 0;
else
dp = dp_internal;
m_flow_internal = 0;
end if;
connect(dp_internal, dp_in);
connect(m_flow_internal, m_flow_in);
port_a.h_outflow = inStream(port_b.h_outflow);
port_b.h_outflow = inStream(port_a.h_outflow);
annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 60}, {100, -60}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {192, 192, 192}), Rectangle(extent = {{-100, 50}, {100, -48}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.HorizontalCylinder, fillColor = {0, 127, 255}), Text(visible = not control_m_flow, extent = {{24, 44}, {80, 24}}, lineColor = {255, 255, 255}, textString = "dp"), Text(visible = control_m_flow, extent = {{-80, 44}, {-24, 24}}, lineColor = {255, 255, 255}, textString = "m")}));
end IdealSource;

partial model PartialFlowMachine  "Partial model to interface fan or pump models with the medium"
extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations(final mSenFac = 1);
extends Buildings.Fluid.Interfaces.PartialTwoPortInterface(show_T = false, port_a(h_outflow(start = h_outflow_start)), port_b(h_outflow(start = h_outflow_start), p(start = p_start), final m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0)));
replaceable parameter Buildings.Fluid.Movers.Data.Generic per constrainedby Buildings.Fluid.Movers.Data.Generic;
parameter Buildings.Fluid.Types.InputType inputType = Buildings.Fluid.Types.InputType.Continuous "Control input type" annotation(Dialog(group = "Control"));
parameter Real constInput = 0 "Constant input set point" annotation(Dialog(group = "Control", enable = inputType == Buildings.Fluid.Types.InputType.Constant));
parameter Real[:] stageInputs "Vector of input set points corresponding to stages" annotation(Dialog(group = "Control", enable = inputType == Buildings.Fluid.Types.InputType.Stages));
parameter Boolean computePowerUsingSimilarityLaws "= true, compute power exactly, using similarity laws. Otherwise approximate.";
parameter Boolean addPowerToMedium = true "Set to false to avoid any power (=heat and flow work) being added to medium (may give simpler equations)";
parameter Boolean nominalValuesDefineDefaultPressureCurve = false "Set to true to avoid warning if m_flow_nominal and dp_nominal are used to construct the default pressure curve";
parameter Modelica.SIunits.Time tau = 1 "Time constant of fluid volume for nominal flow, used if energy or mass balance is dynamic" annotation(Dialog(tab = "Dynamics", group = "Nominal condition", enable = energyDynamics <> Modelica.Fluid.Types.Dynamics.SteadyState or massDynamics <> Modelica.Fluid.Types.Dynamics.SteadyState));
parameter Boolean filteredSpeed = true "= true, if speed is filtered with a 2nd order CriticalDamping filter" annotation(Dialog(tab = "Dynamics", group = "Filtered speed"));
parameter Modelica.SIunits.Time riseTime = 30 "Rise time of the filter (time to reach 99.6 % of the speed)" annotation(Dialog(tab = "Dynamics", group = "Filtered speed", enable = filteredSpeed));
parameter Modelica.Blocks.Types.Init init = Modelica.Blocks.Types.Init.InitialOutput "Type of initialization (no init/steady state/initial state/initial output)" annotation(Dialog(tab = "Dynamics", group = "Filtered speed", enable = filteredSpeed));
parameter Real y_start(min = 0, max = 1, unit = "1") = 0 "Initial value of speed" annotation(Dialog(tab = "Dynamics", group = "Filtered speed", enable = filteredSpeed));
Modelica.Blocks.Interfaces.IntegerInput stage if inputType == Buildings.Fluid.Types.InputType.Stages "Stage input signal for the pressure head" annotation(Placement(transformation(extent = {{-20, -20}, {20, 20}}, rotation = 270, origin = {0, 120})));
Modelica.Blocks.Interfaces.RealOutput y_actual(final unit = "1") "Actual normalised pump speed that is used for computations" annotation(Placement(transformation(extent = {{100, 40}, {120, 60}}), iconTransformation(extent = {{100, 40}, {120, 60}})));
Modelica.Blocks.Interfaces.RealOutput P(quantity = "Power", final unit = "W") "Electrical power consumed" annotation(Placement(transformation(extent = {{100, 70}, {120, 90}})));
Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort "Heat dissipation to environment" annotation(Placement(transformation(extent = {{-70, -110}, {-50, -90}}), iconTransformation(extent = {{-10, -78}, {10, -58}})));
Modelica.SIunits.VolumeFlowRate VMachine_flow(start = _VMachine_flow) = eff.V_flow "Volume flow rate";
Modelica.SIunits.PressureDifference dpMachine(displayUnit = "Pa") = -preSou.dp "Pressure difference";
Real eta(unit = "1", final quantity = "Efficiency") = eff.eta "Global efficiency";
Real etaHyd(unit = "1", final quantity = "Efficiency") = eff.etaHyd "Hydraulic efficiency";
Real etaMot(unit = "1", final quantity = "Efficiency") = eff.etaMot "Motor efficiency";
protected
final parameter Modelica.SIunits.VolumeFlowRate _VMachine_flow = 0 "Start value for VMachine_flow, used to avoid a warning if not specified";
parameter Types.PrescribedVariable preVar "Type of prescribed variable";
final parameter Boolean speedIsInput = preVar == Types.PrescribedVariable.Speed "Parameter that is true if speed is the controlled variables";
final parameter Integer nOri = size(per.pressure.V_flow, 1) "Number of data points for pressure curve" annotation(Evaluate = true);
final parameter Boolean haveVMax = abs(per.pressure.dp[nOri]) < Modelica.Constants.eps "Flag, true if user specified data that contain V_flow_max";
final parameter Modelica.SIunits.VolumeFlowRate V_flow_max = if per.havePressureCurve then if haveVMax then per.pressure.V_flow[nOri] else per.pressure.V_flow[nOri] - (per.pressure.V_flow[nOri] - per.pressure.V_flow[nOri - 1]) / (per.pressure.dp[nOri] - per.pressure.dp[nOri - 1]) * per.pressure.dp[nOri] else m_flow_nominal / rho_default "Maximum volume flow rate, used for smoothing";
final parameter Modelica.SIunits.Density rho_default = Medium.density_pTX(p = Medium.p_default, T = Medium.T_default, X = Medium.X_default) "Default medium density";
final parameter Medium.ThermodynamicState sta_start = Medium.setState_pTX(T = T_start, p = p_start, X = X_start) "Medium state at start values";
final parameter Modelica.SIunits.SpecificEnthalpy h_outflow_start = Medium.specificEnthalpy(sta_start) "Start value for outflowing enthalpy";
Modelica.Blocks.Sources.Constant[size(stageInputs, 1)] stageValues(final k = stageInputs) if inputType == Buildings.Fluid.Types.InputType.Stages "Stage input values" annotation(Placement(transformation(extent = {{-80, 40}, {-60, 60}})));
Modelica.Blocks.Sources.Constant setConst(final k = constInput) if inputType == Buildings.Fluid.Types.InputType.Constant "Constant input set point" annotation(Placement(transformation(extent = {{-80, 70}, {-60, 90}})));
Extractor extractor(final nin = size(stageInputs, 1)) if inputType == Buildings.Fluid.Types.InputType.Stages "Stage input extractor" annotation(Placement(transformation(extent = {{-50, 60}, {-30, 40}})));
Modelica.Blocks.Routing.RealPassThrough inputSwitch "Dummy connection for easy connection of input options" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {-10, 50})));
Buildings.Fluid.Delays.DelayFirstOrder vol(redeclare final package Medium = Medium, final tau = tau, final energyDynamics = energyDynamics, final massDynamics = massDynamics, final T_start = T_start, final X_start = X_start, final C_start = C_start, final m_flow_nominal = m_flow_nominal, final m_flow_small = m_flow_small, final p_start = p_start, final prescribedHeatFlowRate = true, final allowFlowReversal = allowFlowReversal, nPorts = 2) "Fluid volume for dynamic model" annotation(Placement(transformation(extent = {{-70, 0}, {-90, 20}})));
Modelica.Blocks.Continuous.Filter filter(order = 2, f_cut = 5 / (2 * Modelica.Constants.pi * riseTime), final init = init, x(each stateSelect = StateSelect.always), final analogFilter = Modelica.Blocks.Types.AnalogFilter.CriticalDamping, final filterType = Modelica.Blocks.Types.FilterType.LowPass) if filteredSpeed "Second order filter to approximate valve opening time, and to improve numerics" annotation(Placement(transformation(extent = {{20, 81}, {34, 95}})));
Modelica.Blocks.Math.Gain gaiSpe(y(final unit = "1")) if inputType == Buildings.Fluid.Types.InputType.Continuous and speedIsInput "Gain to normalized speed using speed_nominal or speed_rpm_nominal" annotation(Placement(transformation(extent = {{-4, 74}, {-16, 86}})));
Buildings.Fluid.Movers.BaseClasses.IdealSource preSou(redeclare final package Medium = Medium, final m_flow_small = m_flow_small, final allowFlowReversal = allowFlowReversal, final control_m_flow = preVar == Types.PrescribedVariable.FlowRate) "Pressure source" annotation(Placement(transformation(extent = {{40, -10}, {60, 10}})));
Buildings.Fluid.Movers.BaseClasses.PowerInterface heaDis(final motorCooledByFluid = per.motorCooledByFluid, final delta_V_flow = 1E-3 * V_flow_max) if addPowerToMedium "Heat dissipation into medium" annotation(Placement(transformation(extent = {{20, -80}, {40, -60}})));
Modelica.Blocks.Math.Add PToMed(final k1 = 1, final k2 = 1) if addPowerToMedium "Heat and work input into medium" annotation(Placement(transformation(extent = {{50, -90}, {70, -70}})));
Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow prePow(final alpha = 0) if addPowerToMedium "Prescribed power (=heat and flow work) flow for dynamic model" annotation(Placement(transformation(extent = {{-14, -104}, {-34, -84}})));
Modelica.Blocks.Sources.RealExpression rho_inlet(y = Medium.density(Medium.setState_phX(port_a.p, inStream(port_a.h_outflow), inStream(port_a.Xi_outflow)))) "Density of the inflowing fluid" annotation(Placement(transformation(extent = {{-90, -74}, {-70, -54}})));
Buildings.Fluid.Sensors.MassFlowRate senMasFlo(redeclare final package Medium = Medium) "Mass flow rate sensor" annotation(Placement(transformation(extent = {{-50, 10}, {-30, -10}})));
Sensors.RelativePressure senRelPre(redeclare final package Medium = Medium) "Head of mover" annotation(Placement(transformation(extent = {{58, -27}, {43, -14}})));
FlowMachineInterface eff(per(final hydraulicEfficiency = per.hydraulicEfficiency, final motorEfficiency = per.motorEfficiency, final motorCooledByFluid = per.motorCooledByFluid, final speed_nominal = 0, final constantSpeed = 0, final speeds = {0}, final power = per.power), final nOri = nOri, final rho_default = rho_default, final computePowerUsingSimilarityLaws = computePowerUsingSimilarityLaws, final haveVMax = haveVMax, final V_flow_max = V_flow_max, r_N(start = y_start), r_V(start = m_flow_nominal / rho_default), final preVar = preVar) "Flow machine" annotation(Placement(transformation(extent = {{-32, -68}, {-12, -48}})));

block Extractor  "Extract scalar signal out of signal vector dependent on IntegerRealInput index"
extends Modelica.Blocks.Interfaces.MISO;
Modelica.Blocks.Interfaces.IntegerInput index "Integer input for control input" annotation(Placement(transformation(origin = {0, -120}, extent = {{-20, -20}, {20, 20}}, rotation = 90)));
equation
y = sum({if index == i then u[i] else 0 for i in 1:nin});
annotation(Icon(graphics = {Rectangle(extent = {{-80, 50}, {-40, -50}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-84.4104, 1.9079}, {-84.4104, -2.09208}, {-80.4104, -0.09208}, {-84.4104, 1.9079}}, lineColor = {0, 0, 127}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid), Line(points = {{-62, 2}, {-50.1395, 12.907}, {-39.1395, 12.907}}, color = {0, 0, 127}), Line(points = {{-63, 4}, {-49, 40}, {-39, 40}}, color = {0, 0, 127}), Line(points = {{-102, 0}, {-65.0373, -0.01802}}, color = {0, 0, 127}), Ellipse(extent = {{-70.0437, 4.5925}, {-60.0437, -4.90745}}, lineColor = {0, 0, 127}, fillColor = {0, 0, 127}, fillPattern = FillPattern.Solid), Line(points = {{-63, -5}, {-50, -40}, {-39, -40}}, color = {0, 0, 127}), Line(points = {{-62, -2}, {-50.0698, -12.907}, {-39.0698, -12.907}}, color = {0, 0, 127}), Polygon(points = {{-38.8808, -11}, {-38.8808, -15}, {-34.8808, -13}, {-38.8808, -11}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-39, 42}, {-39, 38}, {-35, 40}, {-39, 42}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-38.8728, -38.0295}, {-38.8728, -42.0295}, {-34.8728, -40.0295}, {-38.8728, -38.0295}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{-38.9983, 14.8801}, {-38.9983, 10.8801}, {-34.9983, 12.8801}, {-38.9983, 14.8801}}, lineColor = {0, 0, 127}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Rectangle(extent = {{-30, 50}, {30, -50}}, fillColor = {235, 235, 235}, fillPattern = FillPattern.Solid, lineColor = {0, 0, 127}), Line(points = {{100, 0}, {0, 0}}, color = {0, 0, 127}), Line(points = {{0, 2}, {0, -104}}, color = {255, 128, 0}), Line(points = {{-35, 40}, {-20, 40}}, color = {0, 0, 127}), Line(points = {{-35, 13}, {-20, 13}}, color = {0, 0, 127}), Line(points = {{-35, -13}, {-20, -13}}, color = {0, 0, 127}), Line(points = {{-35, -40}, {-20, -40}}, color = {0, 0, 127}), Polygon(points = {{0, 0}, {-20, 13}, {-20, 13}, {0, 0}, {0, 0}}, lineColor = {0, 0, 127}), Ellipse(extent = {{-6, 6}, {6, -6}}, lineColor = {255, 128, 0}, fillColor = {255, 128, 0}, fillPattern = FillPattern.Solid)}));
end Extractor;
initial equation
assert(nominalValuesDefineDefaultPressureCurve or per.havePressureCurve or preVar == Types.PrescribedVariable.Speed, "*** Warning: You are using a flow or pressure controlled mover with the
default pressure curve.
This leads to approximate calculations of the electrical power
consumption. Add the correct pressure curve in the record per
to obtain an accurate computation.
Setting nominalValuesDefineDefaultPressureCurve=true will suppress this warning.", AssertionLevel.warning);
assert(nominalValuesDefineDefaultPressureCurve or per.havePressureCurve or preVar == Types.PrescribedVariable.Speed or per.use_powerCharacteristic == false, "*** Warning: You are using a flow or pressure controlled mover with the
default pressure curve and you set use_powerCharacteristic = true.
Since this can cause wrong power consumption, the model will overwrite
this setting and use instead use_powerCharacteristic = false.
Since this causes the efficiency curve to be used,
make sure that the efficiency curves in the performance record per
are correct or add the pressure curve of the mover.
Setting nominalValuesDefineDefaultPressureCurve=true will suppress this warning.", AssertionLevel.warning);
equation
connect(prePow.port, vol.heatPort) annotation(Line(points = {{-34, -94}, {-60, -94}, {-60, 10}, {-70, 10}}, color = {191, 0, 0}));
connect(vol.heatPort, heatPort) annotation(Line(points = {{-70, 10}, {-70, 10}, {-60, 10}, {-60, -100}}, color = {191, 0, 0}));
connect(preSou.port_b, port_b) annotation(Line(points = {{60, 0}, {100, 0}}, color = {0, 127, 255}, smooth = Smooth.None));
connect(stageValues.y, extractor.u) annotation(Line(points = {{-59, 50}, {-52, 50}}, color = {0, 0, 127}, smooth = Smooth.None));
connect(extractor.y, inputSwitch.u) annotation(Line(points = {{-29, 50}, {-22, 50}}, color = {0, 0, 127}, smooth = Smooth.None));
connect(setConst.y, inputSwitch.u) annotation(Line(points = {{-59, 80}, {-26, 80}, {-26, 50}, {-22, 50}}, color = {0, 0, 127}, smooth = Smooth.None));
connect(extractor.index, stage) annotation(Line(points = {{-40, 62}, {-40, 90}, {0, 90}, {0, 120}}, color = {255, 127, 0}, smooth = Smooth.None));
connect(PToMed.y, prePow.Q_flow) annotation(Line(points = {{71, -80}, {80, -80}, {80, -94}, {-14, -94}}, color = {0, 0, 127}));
connect(PToMed.u1, heaDis.Q_flow) annotation(Line(points = {{48, -74}, {44, -74}, {44, -72}, {44, -70}, {41, -70}}, color = {0, 0, 127}));
connect(senRelPre.port_b, preSou.port_a) annotation(Line(points = {{43, -20.5}, {20, -20.5}, {20, 0}, {40, 0}}, color = {0, 127, 255}));
connect(senRelPre.port_a, preSou.port_b) annotation(Line(points = {{58, -20.5}, {80, -20.5}, {80, 0}, {60, 0}}, color = {0, 127, 255}));
connect(heaDis.etaHyd, eff.etaHyd) annotation(Line(points = {{18, -60}, {10, -60}, {10, -65}, {-11, -65}}, color = {0, 0, 127}));
connect(heaDis.V_flow, eff.V_flow) annotation(Line(points = {{18, -66}, {14, -66}, {14, -53.2}, {-6, -53.2}, {-11, -53.2}}, color = {0, 0, 127}));
connect(eff.PEle, heaDis.PEle) annotation(Line(points = {{-11, -59}, {0, -59}, {0, -80}, {18, -80}}, color = {0, 0, 127}));
connect(eff.WFlo, heaDis.WFlo) annotation(Line(points = {{-11, -56}, {-8, -56}, {-8, -74}, {18, -74}}, color = {0, 0, 127}));
connect(rho_inlet.y, eff.rho) annotation(Line(points = {{-69, -64}, {-69, -64}, {-34, -64}}, color = {0, 0, 127}));
connect(eff.m_flow, senMasFlo.m_flow) annotation(Line(points = {{-34, -54}, {-34, -54}, {-40, -54}, {-40, -11}}, color = {0, 0, 127}));
connect(eff.PEle, P) annotation(Line(points = {{-11, -59}, {0, -59}, {0, -50}, {90, -50}, {90, 80}, {110, 80}}, color = {0, 0, 127}));
connect(eff.WFlo, PToMed.u2) annotation(Line(points = {{-11, -56}, {-8, -56}, {-8, -86}, {48, -86}}, color = {0, 0, 127}));
connect(inputSwitch.y, filter.u) annotation(Line(points = {{1, 50}, {16, 50}, {16, 88}, {18.6, 88}}, color = {0, 0, 127}));
connect(senRelPre.p_rel, eff.dp_in) annotation(Line(points = {{50.5, -26.35}, {50.5, -38}, {-18, -38}, {-18, -46}}, color = {0, 0, 127}));
connect(eff.y_out, y_actual) annotation(Line(points = {{-11, -48}, {92, -48}, {92, 50}, {110, 50}}, color = {0, 0, 127}));
connect(port_a, vol.ports[1]) annotation(Line(points = {{-100, 0}, {-78, 0}, {-78, 0}}, color = {0, 127, 255}));
connect(vol.ports[2], senMasFlo.port_a) annotation(Line(points = {{-82, 0}, {-82, 0}, {-50, 0}}, color = {0, 127, 255}));
connect(senMasFlo.port_b, preSou.port_a) annotation(Line(points = {{-30, 0}, {40, 0}, {40, 0}}, color = {0, 127, 255}));
annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{0, 50}, {100, 50}}, color = {0, 0, 0}, smooth = Smooth.None), Line(points = {{0, 80}, {100, 80}}, color = {0, 0, 0}, smooth = Smooth.None), Line(visible = not filteredSpeed, points = {{0, 100}, {0, 40}}), Rectangle(extent = {{-100, 16}, {100, -14}}, lineColor = {0, 0, 0}, fillColor = {0, 127, 255}, fillPattern = FillPattern.HorizontalCylinder), Ellipse(extent = {{-58, 50}, {54, -58}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Sphere, fillColor = {0, 100, 199}), Polygon(points = {{0, 50}, {0, -56}, {54, 2}, {0, 50}}, lineColor = {0, 0, 0}, pattern = LinePattern.None, fillPattern = FillPattern.HorizontalCylinder, fillColor = {255, 255, 255}), Ellipse(extent = {{4, 14}, {34, -16}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Sphere, visible = energyDynamics <> Modelica.Fluid.Types.Dynamics.SteadyState, fillColor = {0, 100, 199}), Rectangle(visible = filteredSpeed, extent = {{-34, 40}, {32, 100}}, lineColor = {0, 0, 0}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid), Ellipse(visible = filteredSpeed, extent = {{-34, 100}, {32, 40}}, lineColor = {0, 0, 0}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid), Text(visible = filteredSpeed, extent = {{-22, 92}, {20, 46}}, lineColor = {0, 0, 0}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid, textString = "M", textStyle = {TextStyle.Bold}), Text(extent = {{64, 98}, {114, 84}}, lineColor = {0, 0, 127}, textString = "P")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})));
end PartialFlowMachine;

model PowerInterface  "Partial model to compute power draw and heat dissipation of fans and pumps"
extends Modelica.Blocks.Interfaces.BlockIcon;
parameter Boolean homotopyInitialization = true "= true, use homotopy method" annotation(Evaluate = true, Dialog(tab = "Advanced"));
parameter Boolean motorCooledByFluid "Flag, true if the motor is cooled by the fluid stream";
parameter Modelica.SIunits.VolumeFlowRate delta_V_flow "Factor used for setting heat input into medium to zero at very small flows";
Modelica.Blocks.Interfaces.RealInput etaHyd(final quantity = "Efficiency", final unit = "1") "Hydraulic efficiency" annotation(Placement(transformation(extent = {{-140, 80}, {-100, 120}}), iconTransformation(extent = {{-140, 80}, {-100, 120}})));
Modelica.Blocks.Interfaces.RealInput V_flow(final quantity = "VolumeFlowRate", final unit = "m3/s") "Volume flow rate" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}}), iconTransformation(extent = {{-140, 20}, {-100, 60}})));
Modelica.Blocks.Interfaces.RealInput WFlo(final quantity = "Power", final unit = "W") "Flow work" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}}), iconTransformation(extent = {{-140, -60}, {-100, -20}})));
Modelica.Blocks.Interfaces.RealInput PEle(final quantity = "Power", final unit = "W") "Electrical power consumed" annotation(Placement(transformation(extent = {{-140, -120}, {-100, -80}})));
Modelica.Blocks.Interfaces.RealOutput Q_flow(quantity = "Power", final unit = "W") "Heat input from fan or pump to medium" annotation(Placement(transformation(extent = {{100, -10}, {120, 10}})));
Modelica.SIunits.Power WHyd "Hydraulic power input (converted to flow work and heat)";
protected
Modelica.SIunits.HeatFlowRate QThe_flow "Heat input from fan or pump to medium";
equation
etaHyd * WHyd = WFlo;
QThe_flow + WFlo = if motorCooledByFluid then PEle else WHyd;
Q_flow = if homotopyInitialization then homotopy(actual = Buildings.Utilities.Math.Functions.regStep(y1 = QThe_flow, y2 = 0, x = noEvent(abs(V_flow)) - 2 * delta_V_flow, x_small = delta_V_flow), simplified = 0) else Buildings.Utilities.Math.Functions.regStep(y1 = QThe_flow, y2 = 0, x = noEvent(abs(V_flow)) - 2 * delta_V_flow, x_small = delta_V_flow);
annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(origin = {-49.5, 7.6667}, points = {{-2.5, -91.6667}, {17.5, -71.6667}, {-22.5, -51.6667}, {17.5, -31.6667}, {-22.5, -11.667}, {17.5, 8.3333}, {-2.5, 28.3333}, {-2.5, 48.3333}}, smooth = Smooth.Bezier, color = {255, 0, 0}), Line(origin = {0.5, 7.6667}, points = {{-2.5, -91.6667}, {17.5, -71.6667}, {-22.5, -51.6667}, {17.5, -31.6667}, {-22.5, -11.667}, {17.5, 8.3333}, {-2.5, 28.3333}, {-2.5, 48.3333}}, smooth = Smooth.Bezier, color = {255, 0, 0}), Line(origin = {50.5, 7.6667}, points = {{-2.5, -91.6667}, {17.5, -71.6667}, {-22.5, -51.6667}, {17.5, -31.6667}, {-22.5, -11.667}, {17.5, 8.3333}, {-2.5, 28.3333}, {-2.5, 48.3333}}, smooth = Smooth.Bezier, color = {255, 0, 0}), Polygon(origin = {48, 64.333}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{0.0, 21.667}, {-10.0, -8.333}, {10.0, -8.333}}, lineColor = {0, 0, 0}, fillColor = {255, 0, 0}), Polygon(origin = {-2, 64.333}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{0.0, 21.667}, {-10.0, -8.333}, {10.0, -8.333}}, lineColor = {0, 0, 0}, fillColor = {255, 0, 0}), Polygon(origin = {-52, 64.333}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{0.0, 21.667}, {-10.0, -8.333}, {10.0, -8.333}}, lineColor = {0, 0, 0}, fillColor = {255, 0, 0})}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})));
end PowerInterface;

package Characteristics  "Functions for fan or pump characteristics"
function efficiency  "Flow vs. efficiency characteristics for fan or pump"
extends Modelica.Icons.Function;
input Buildings.Fluid.Movers.BaseClasses.Characteristics.efficiencyParameters per "Efficiency performance data";
input Modelica.SIunits.VolumeFlowRate V_flow "Volumetric flow rate";
input Real[:] d "Derivatives at support points for spline interpolation";
input Real r_N(unit = "1") "Relative revolution, r_N=N/N_nominal";
input Real delta "Small value for switching implementation around zero rpm";
output Real eta(unit = "1", final quantity = "Efficiency") "Efficiency";
protected
Integer n = size(per.V_flow, 1) "Number of data points";
Real rat "Ratio of V_flow/r_N";
Integer i "Integer to select data interval";
algorithm
if n == 1 then
eta := per.eta[1];
else
rat := V_flow / Buildings.Utilities.Math.Functions.smoothMax(x1 = r_N, x2 = 0.1, deltaX = delta);
i := 1;
for j in 1:n - 1 loop
if rat > per.V_flow[j] then
i := j;
else
end if;
end for;
eta := Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = rat, x1 = per.V_flow[i], x2 = per.V_flow[i + 1], y1 = per.eta[i], y2 = per.eta[i + 1], y1d = d[i], y2d = d[i + 1]);
end if;
annotation(smoothOrder = 1);
end efficiency;

function power  "Flow vs. electrical power characteristics for fan or pump"
extends Modelica.Icons.Function;
input Buildings.Fluid.Movers.BaseClasses.Characteristics.powerParameters per "Pressure performance data";
input Modelica.SIunits.VolumeFlowRate V_flow "Volumetric flow rate";
input Real r_N(unit = "1") "Relative revolution, r_N=N/N_nominal";
input Real[:] d "Derivatives at support points for spline interpolation";
input Real delta "Small value for switching implementation around zero rpm";
output Modelica.SIunits.Power P "Power consumption";
protected
Integer n = size(per.V_flow, 1) "Dimension of data vector";
Modelica.SIunits.VolumeFlowRate rat "Ratio of V_flow/r_N";
Integer i "Integer to select data interval";
algorithm
if n == 1 then
P := r_N ^ 3 * per.P[1];
else
i := 1;
rat := V_flow / Buildings.Utilities.Math.Functions.smoothMax(x1 = r_N, x2 = 0.1, deltaX = delta);
for j in 1:n - 1 loop
if rat > per.V_flow[j] then
i := j;
else
end if;
end for;
P := r_N ^ 3 * Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = rat, x1 = per.V_flow[i], x2 = per.V_flow[i + 1], y1 = per.P[i], y2 = per.P[i + 1], y1d = d[i], y2d = d[i + 1]);
end if;
annotation(smoothOrder = 1);
end power;

function pressure  "Pump or fan head away from the origin without correction for mover flow resistance"
extends Modelica.Icons.Function;
input Modelica.SIunits.VolumeFlowRate V_flow "Volumetric flow rate";
input Real r_N(unit = "1") "Relative revolution, r_N=N/N_nominal";
input Real[:] d "Derivatives of flow rate vs. pressure at the support points";
input Modelica.SIunits.PressureDifference dpMax(displayUnit = "Pa") "Maximum pressure drop at nominal speed, for regularisation";
input Modelica.SIunits.VolumeFlowRate V_flow_max "Maximum flow rate at nominal speed, for regularisation";
input Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParametersInternal per "Pressure performance data";
output Modelica.SIunits.PressureDifference dp(displayUnit = "Pa") "Pressure raise";
protected
constant Real delta = 0.05 "Small number for r_N below which we don't care about the affinity laws";
constant Real delta2 = delta / 2 "= delta/2";
Real r_R(unit = "1") "Relative revolution, bounded below by delta";
Integer i "Integer to select data interval";
Modelica.SIunits.VolumeFlowRate rat "Ratio of V_flow/r_R";
algorithm
if r_N > delta then
r_R := r_N;
elseif r_N < 0 then
r_R := delta2;
else
r_R := Modelica.Fluid.Utilities.cubicHermite(x = r_N, x1 = 0, x2 = delta, y1 = delta2, y2 = delta, y1d = 0, y2d = 1);
end if;
i := 1;
rat := V_flow / r_R;
for j in 1:size(d, 1) - 1 loop
if rat > per.V_flow[j] then
i := j;
else
end if;
end for;
if r_N >= 0 then
dp := r_N ^ 2 * Buildings.Utilities.Math.Functions.cubicHermiteLinearExtrapolation(x = rat, x1 = per.V_flow[i], x2 = per.V_flow[i + 1], y1 = per.dp[i], y2 = per.dp[i + 1], y1d = d[i], y2d = d[i + 1]);
else
dp := -r_N ^ 2 * (dpMax - dpMax / V_flow_max * V_flow);
end if;
annotation(smoothOrder = 1);
end pressure;

record efficiencyParameters  "Record for efficiency parameters"
extends Modelica.Icons.Record;
parameter Modelica.SIunits.VolumeFlowRate[:] V_flow(each min = 0) "Volumetric flow rate at user-selected operating points";
parameter Modelica.SIunits.Efficiency[size(V_flow, 1)] eta(each max = 1) "Fan or pump efficiency at these flow rates";
end efficiencyParameters;

record flowParameters  "Record for flow parameters"
extends Modelica.Icons.Record;
parameter Modelica.SIunits.VolumeFlowRate[:] V_flow(each min = 0) "Volume flow rate at user-selected operating points";
parameter Modelica.SIunits.PressureDifference[size(V_flow, 1)] dp(each min = 0, each displayUnit = "Pa") "Fan or pump total pressure at these flow rates";
end flowParameters;

record flowParametersInternal  "Record for flow parameters with prescribed size"
extends Modelica.Icons.Record;
parameter Integer n "Number of elements in each array" annotation(Evaluate = true);
parameter Modelica.SIunits.VolumeFlowRate[n] V_flow(each min = 0) "Volume flow rate at user-selected operating points";
parameter Modelica.SIunits.PressureDifference[n] dp(each min = 0, each displayUnit = "Pa") "Fan or pump total pressure at these flow rates";
end flowParametersInternal;

record powerParameters  "Record for electrical power parameters"
extends Modelica.Icons.Record;
parameter Modelica.SIunits.VolumeFlowRate[:] V_flow(each min = 0) "Volume flow rate at user-selected operating points";
parameter Modelica.SIunits.Power[size(V_flow, 1)] P(each min = 0) "Fan or pump electrical power at these flow rates";
end powerParameters;
end Characteristics;

package Types  "Package with type definitions"
extends Modelica.Icons.TypesPackage;
type PrescribedVariable = enumeration(Speed "Speed is prescribed", FlowRate "Flow rate is prescribed", PressureDifference "Pressure difference is prescribed") "Enumeration to choose what variable is prescribed";
end Types;
end BaseClasses;
annotation(Icon(graphics = {Ellipse(extent = {{-66, 66}, {68, -68}}, lineColor = {0, 0, 0}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{0, 66}, {0, -68}, {68, 0}, {0, 66}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid)}));
end Movers;

package Sensors  "Package with sensor models"
extends Modelica.Icons.SensorsPackage;

model MassFlowRate  "Ideal sensor for mass flow rate"
extends Buildings.Fluid.Sensors.BaseClasses.PartialFlowSensor(final m_flow_nominal = 0, final m_flow_small = 0);
extends Modelica.Icons.RotationalSensor;
Modelica.Blocks.Interfaces.RealOutput m_flow(quantity = "MassFlowRate", final unit = "kg/s") "Mass flow rate from port_a to port_b" annotation(Placement(transformation(origin = {0, 110}, extent = {{10, -10}, {-10, 10}}, rotation = 270)));
equation
m_flow = port_a.m_flow;
annotation(defaultComponentName = "senMasFlo", Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{70, 0}, {100, 0}}, color = {0, 128, 255}), Text(extent = {{162, 120}, {2, 90}}, lineColor = {0, 0, 0}, textString = "m_flow"), Line(points = {{0, 100}, {0, 70}}, color = {0, 0, 127}), Line(points = {{-100, 0}, {-70, 0}}, color = {0, 128, 255})}));
end MassFlowRate;

model RelativePressure  "Ideal relative pressure sensor"
extends Modelica.Icons.TranslationalSensor;
replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the sensor" annotation(choicesAllMatching = true);
Modelica.Fluid.Interfaces.FluidPort_a port_a(m_flow(min = 0), p(start = Medium.p_default), redeclare package Medium = Medium) "Fluid connector of stream a" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
Modelica.Fluid.Interfaces.FluidPort_b port_b(m_flow(min = 0), p(start = Medium.p_default), redeclare package Medium = Medium) "Fluid connector of stream b" annotation(Placement(transformation(extent = {{110, -12}, {90, 8}}), iconTransformation(extent = {{110, -10}, {90, 10}})));
Modelica.Blocks.Interfaces.RealOutput p_rel(final quantity = "PressureDifference", final unit = "Pa", displayUnit = "Pa") "Relative pressure of port_a minus port_b" annotation(Placement(transformation(origin = {0, -90}, extent = {{10, -10}, {-10, 10}}, rotation = 90)));
equation
port_a.m_flow = 0;
port_b.m_flow = 0;
port_a.h_outflow = 0;
port_b.h_outflow = 0;
port_a.Xi_outflow = zeros(Medium.nXi);
port_b.Xi_outflow = zeros(Medium.nXi);
port_a.C_outflow = zeros(Medium.nC);
port_b.C_outflow = zeros(Medium.nC);
p_rel = port_a.p - port_b.p;
annotation(defaultComponentName = "senRelPre", Icon(graphics = {Line(points = {{-100, 0}, {-70, 0}}, color = {0, 127, 255}), Line(points = {{70, 0}, {100, 0}}, color = {0, 127, 255}), Line(points = {{0, -30}, {0, -80}}, color = {0, 0, 127}), Text(extent = {{-150, 40}, {150, 80}}, textString = "%name", lineColor = {0, 0, 255}), Text(extent = {{130, -70}, {4, -100}}, lineColor = {0, 0, 0}, textString = "p_rel"), Line(points = {{32, 3}, {-58, 3}}, color = {0, 128, 255}), Polygon(points = {{22, 18}, {62, 3}, {22, -12}, {22, 18}}, lineColor = {0, 128, 255}, fillColor = {0, 128, 255}, fillPattern = FillPattern.Solid)}));
end RelativePressure;

package BaseClasses  "Package with base classes for Buildings.Fluid.Sensors"
extends Modelica.Icons.BasesPackage;

partial model PartialFlowSensor  "Partial component to model sensors that measure flow properties"
extends Buildings.Fluid.Interfaces.PartialTwoPort;
parameter Modelica.SIunits.MassFlowRate m_flow_nominal(min = 0) "Nominal mass flow rate, used for regularization near zero flow" annotation(Dialog(group = "Nominal condition"));
parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * m_flow_nominal "For bi-directional flow, temperature is regularized in the region |m_flow| < m_flow_small (m_flow_small > 0 required)" annotation(Dialog(tab = "Advanced"));
equation
port_b.m_flow = -port_a.m_flow;
port_a.p = port_b.p;
port_a.h_outflow = if allowFlowReversal then inStream(port_b.h_outflow) else Medium.h_default;
port_b.h_outflow = inStream(port_a.h_outflow);
port_a.Xi_outflow = if allowFlowReversal then inStream(port_b.Xi_outflow) else Medium.X_default[1:Medium.nXi];
port_b.Xi_outflow = inStream(port_a.Xi_outflow);
port_a.C_outflow = if allowFlowReversal then inStream(port_b.C_outflow) else zeros(Medium.nC);
port_b.C_outflow = inStream(port_a.C_outflow);
end PartialFlowSensor;
end BaseClasses;
end Sensors;

package Types  "Package with type definitions"
extends Modelica.Icons.TypesPackage;
type InputType = enumeration(Constant "Use parameter to set stage", Stages "Use integer input to select stage", Continuous "Use continuous, real input") "Input options for movers";
end Types;

package Interfaces  "Package with interfaces for fluid models"
extends Modelica.Icons.InterfacesPackage;

model ConservationEquation  "Lumped volume with mass and energy balance"
extends Buildings.Fluid.Interfaces.LumpedVolumeDeclarations;
constant Boolean initialize_p = not Medium.singleState "= true to set up initial equations for pressure" annotation(HideResult = true);
constant Boolean simplify_mWat_flow = true "Set to true to cause port_a.m_flow + port_b.m_flow = 0 even if mWat_flow is non-zero";
parameter Integer nPorts = 0 "Number of ports" annotation(Evaluate = true, Dialog(connectorSizing = true, tab = "General", group = "Ports"));
parameter Boolean use_mWat_flow = false "Set to true to enable input connector for moisture mass flow rate" annotation(Evaluate = true, Dialog(tab = "Advanced"));
parameter Boolean use_C_flow = false "Set to true to enable input connector for trace substance" annotation(Evaluate = true, Dialog(tab = "Advanced"));
Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W") "Sensible plus latent heat flow rate transferred into the medium" annotation(Placement(transformation(extent = {{-140, 40}, {-100, 80}})));
Modelica.Blocks.Interfaces.RealInput mWat_flow(final quantity = "MassFlowRate", unit = "kg/s") if use_mWat_flow "Moisture mass flow rate added to the medium" annotation(Placement(transformation(extent = {{-140, 0}, {-100, 40}})));
Modelica.Blocks.Interfaces.RealInput[Medium.nC] C_flow if use_C_flow "Trace substance mass flow rate added to the medium" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
Modelica.Blocks.Interfaces.RealOutput hOut(unit = "J/kg", start = hStart) "Leaving specific enthalpy of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {-50, 110})));
Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] XiOut(each unit = "1", each min = 0, each max = 1) "Leaving species concentration of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {0, 110})));
Modelica.Blocks.Interfaces.RealOutput[Medium.nC] COut(each min = 0) "Leaving trace substances of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {50, 110})));
Modelica.Blocks.Interfaces.RealOutput UOut(unit = "J") "Internal energy of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {110, 20})));
Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] mXiOut(each min = 0, each unit = "kg") "Species mass of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {110, -20})));
Modelica.Blocks.Interfaces.RealOutput mOut(min = 0, unit = "kg") "Mass of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {110, 60})));
Modelica.Blocks.Interfaces.RealOutput[Medium.nC] mCOut(each min = 0, each unit = "kg") "Trace substance mass of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 0, origin = {110, -60})));
Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b[nPorts] ports(redeclare each final package Medium = Medium) "Fluid inlets and outlets" annotation(Placement(transformation(extent = {{-40, -10}, {40, 10}}, origin = {0, -100})));
Medium.BaseProperties medium(p(start = p_start), h(start = hStart), T(start = T_start), Xi(start = X_start[1:Medium.nXi]), X(start = X_start), d(start = rho_start)) "Medium properties";
Modelica.SIunits.Energy U(start = fluidVolume * rho_start * Medium.specificInternalEnergy(Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi])) + (T_start - Medium.reference_T) * CSen, nominal = 1E5) "Internal energy of fluid";
Modelica.SIunits.Mass m(stateSelect = if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then StateSelect.default else StateSelect.prefer) "Mass of fluid";
Modelica.SIunits.Mass[Medium.nXi] mXi "Masses of independent components in the fluid";
Modelica.SIunits.Mass[Medium.nC] mC "Masses of trace substances in the fluid";
Medium.ExtraProperty[Medium.nC] C(nominal = C_nominal) "Trace substance mixture content";
Modelica.SIunits.MassFlowRate mb_flow "Mass flows across boundaries";
Modelica.SIunits.MassFlowRate[Medium.nXi] mbXi_flow "Substance mass flows across boundaries";
Medium.ExtraPropertyFlowRate[Medium.nC] mbC_flow "Trace substance mass flows across boundaries";
Modelica.SIunits.EnthalpyFlowRate Hb_flow "Enthalpy flow across boundaries or energy source/sink";
parameter Modelica.SIunits.Volume fluidVolume "Volume";
final parameter Modelica.SIunits.HeatCapacity CSen = (mSenFac - 1) * rho_default * cp_default * fluidVolume "Aditional heat capacity for implementing mFactor";
protected
Medium.EnthalpyFlowRate[nPorts] ports_H_flow;
Modelica.SIunits.MassFlowRate[nPorts, Medium.nXi] ports_mXi_flow;
Medium.ExtraPropertyFlowRate[nPorts, Medium.nC] ports_mC_flow;
parameter Modelica.SIunits.SpecificHeatCapacity cp_default = Medium.specificHeatCapacityCp(state = state_default) "Heat capacity, to compute additional dry mass";
parameter Modelica.SIunits.Density rho_start = Medium.density(Medium.setState_pTX(T = T_start, p = p_start, X = X_start[1:Medium.nXi])) "Density, used to compute fluid mass";
final parameter Boolean computeCSen = CSen > Modelica.Constants.eps annotation(Evaluate = true);
final parameter Medium.ThermodynamicState state_default = Medium.setState_pTX(T = Medium.T_default, p = Medium.p_default, X = Medium.X_default[1:Medium.nXi]) "Medium state at default values";
final parameter Modelica.SIunits.Density rho_default = Medium.density(state = state_default) "Density, used to compute fluid mass";
final parameter Real[Medium.nXi] s = {if Modelica.Utilities.Strings.isEqual(string1 = Medium.substanceNames[i], string2 = "Water", caseSensitive = false) then 1 else 0 for i in 1:Medium.nXi} "Vector with zero everywhere except where species is";
parameter Modelica.SIunits.SpecificEnthalpy hStart = Medium.specificEnthalpy_pTX(p_start, T_start, X_start) "Start value for specific enthalpy";
Modelica.Blocks.Interfaces.RealInput mWat_flow_internal(unit = "kg/s") "Needed to connect to conditional connector";
Modelica.Blocks.Interfaces.RealInput[Medium.nC] C_flow_internal "Needed to connect to conditional connector";
initial equation
assert(Medium.nXi == 0 or abs(sum(s) - 1) < 1e-5, "If Medium.nXi > 1, then substance 'water' must be present for one component.'" + Medium.mediumName + "'.\n" + "Check medium model.");
if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
assert(massDynamics == energyDynamics, "
If 'massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState', then it is
required that 'energyDynamics==Modelica.Fluid.Types.Dynamics.SteadyState'.
Otherwise, the system of equations may not be consistent.
You need to select other parameter values.");
end if;
if energyDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
medium.T = T_start;
else
if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
der(medium.T) = 0;
end if;
end if;
if massDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
if initialize_p then
medium.p = p_start;
end if;
else
if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
if initialize_p then
der(medium.p) = 0;
end if;
end if;
end if;
if substanceDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
medium.Xi = X_start[1:Medium.nXi];
else
if substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
der(medium.Xi) = zeros(Medium.nXi);
end if;
end if;
if traceDynamics == Modelica.Fluid.Types.Dynamics.FixedInitial then
C = C_start[1:Medium.nC];
else
if traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyStateInitial then
der(C) = zeros(Medium.nC);
end if;
end if;
equation
connect(mWat_flow, mWat_flow_internal);
if not use_mWat_flow then
mWat_flow_internal = 0;
end if;
connect(C_flow, C_flow_internal);
if not use_C_flow then
C_flow_internal = zeros(Medium.nC);
end if;
if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
m = fluidVolume * rho_start;
else
if simplify_mWat_flow then
m = fluidVolume * Medium.density(Medium.setState_phX(p = medium.p, h = hOut, X = Medium.X_default));
else
m = fluidVolume * medium.d;
end if;
end if;
mXi = m * medium.Xi;
if computeCSen then
U = m * medium.u + CSen * (medium.T - Medium.reference_T);
else
U = m * medium.u;
end if;
mC = m * C;
hOut = medium.h;
XiOut = medium.Xi;
COut = C;
for i in 1:nPorts loop
ports_H_flow[i] = semiLinear(ports[i].m_flow, inStream(ports[i].h_outflow), ports[i].h_outflow) "Enthalpy flow";
for j in 1:Medium.nXi loop
ports_mXi_flow[i, j] = semiLinear(ports[i].m_flow, inStream(ports[i].Xi_outflow[j]), ports[i].Xi_outflow[j]) "Component mass flow";
end for;
for j in 1:Medium.nC loop
ports_mC_flow[i, j] = semiLinear(ports[i].m_flow, inStream(ports[i].C_outflow[j]), ports[i].C_outflow[j]) "Trace substance mass flow";
end for;
end for;
for i in 1:Medium.nXi loop
mbXi_flow[i] = sum(ports_mXi_flow[:, i]);
end for;
for i in 1:Medium.nC loop
mbC_flow[i] = sum(ports_mC_flow[:, i]);
end for;
mb_flow = sum(ports.m_flow);
Hb_flow = sum(ports_H_flow);
if energyDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
0 = Hb_flow + Q_flow;
else
der(U) = Hb_flow + Q_flow;
end if;
if massDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
0 = mb_flow + (if simplify_mWat_flow then 0 else mWat_flow_internal);
else
der(m) = mb_flow + (if simplify_mWat_flow then 0 else mWat_flow_internal);
end if;
if substanceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
zeros(Medium.nXi) = mbXi_flow + mWat_flow_internal * s;
else
der(mXi) = mbXi_flow + mWat_flow_internal * s;
end if;
if traceDynamics == Modelica.Fluid.Types.Dynamics.SteadyState then
zeros(Medium.nC) = mbC_flow + C_flow_internal;
else
der(mC) = mbC_flow + C_flow_internal;
end if;
for i in 1:nPorts loop
ports[i].p = medium.p;
ports[i].h_outflow = medium.h;
ports[i].Xi_outflow = medium.Xi;
ports[i].C_outflow = C;
end for;
UOut = U;
mXiOut = mXi;
mOut = m;
mCOut = mC;
annotation(Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid, pattern = LinePattern.None), Text(extent = {{-89, 17}, {-54, 34}}, lineColor = {0, 0, 127}, textString = "mWat_flow"), Text(extent = {{-89, 52}, {-54, 69}}, lineColor = {0, 0, 127}, textString = "Q_flow"), Line(points = {{-56, -73}, {81, -73}}, color = {255, 255, 255}), Line(points = {{-42, 55}, {-42, -84}}, color = {255, 255, 255}), Polygon(points = {{-42, 67}, {-50, 45}, {-34, 45}, {-42, 67}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{87, -73}, {65, -65}, {65, -81}, {87, -73}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-42, -28}, {-6, -28}, {18, 4}, {40, 12}, {66, 14}}, color = {255, 255, 255}, smooth = Smooth.Bezier), Text(extent = {{-155, -120}, {145, -160}}, lineColor = {0, 0, 255}, textString = "%name")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})));
end ConservationEquation;

partial model PartialTwoPort  "Partial component with two ports"
replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the component" annotation(choicesAllMatching = true);
parameter Boolean allowFlowReversal = true "= false to simplify equations, assuming, but not enforcing, no flow reversal" annotation(Dialog(tab = "Assumptions"), Evaluate = true);
Modelica.Fluid.Interfaces.FluidPort_a port_a(redeclare final package Medium = Medium, m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0), h_outflow(start = Medium.h_default)) "Fluid connector a (positive design flow direction is from port_a to port_b)" annotation(Placement(transformation(extent = {{-110, -10}, {-90, 10}})));
Modelica.Fluid.Interfaces.FluidPort_b port_b(redeclare final package Medium = Medium, m_flow(max = if allowFlowReversal then +Modelica.Constants.inf else 0), h_outflow(start = Medium.h_default)) "Fluid connector b (positive design flow direction is from port_a to port_b)" annotation(Placement(transformation(extent = {{110, -10}, {90, 10}})));
annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(points = {{20, -70}, {60, -85}, {20, -100}, {20, -70}}, lineColor = {0, 128, 255}, fillColor = {0, 128, 255}, fillPattern = FillPattern.Solid, visible = not allowFlowReversal), Line(points = {{55, -85}, {-60, -85}}, color = {0, 128, 255}, visible = not allowFlowReversal), Text(extent = {{-149, -114}, {151, -154}}, lineColor = {0, 0, 255}, textString = "%name")}));
end PartialTwoPort;

partial model PartialTwoPortInterface  "Partial model transporting fluid between two ports without storing mass or energy"
extends Buildings.Fluid.Interfaces.PartialTwoPort(port_a(p(start = Medium.p_default)), port_b(p(start = Medium.p_default)));
parameter Modelica.SIunits.MassFlowRate m_flow_nominal "Nominal mass flow rate" annotation(Dialog(group = "Nominal condition"));
parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1E-4 * abs(m_flow_nominal) "Small mass flow rate for regularization of zero flow" annotation(Dialog(tab = "Advanced"));
parameter Boolean show_T = false "= true, if actual temperature at port is computed" annotation(Dialog(tab = "Advanced", group = "Diagnostics"));
Modelica.SIunits.MassFlowRate m_flow(start = _m_flow_start) = port_a.m_flow "Mass flow rate from port_a to port_b (m_flow > 0 is design flow direction)";
Modelica.SIunits.PressureDifference dp(start = _dp_start, displayUnit = "Pa") = port_a.p - port_b.p "Pressure difference between port_a and port_b";
Medium.ThermodynamicState sta_a = Medium.setState_phX(port_a.p, noEvent(actualStream(port_a.h_outflow)), noEvent(actualStream(port_a.Xi_outflow))) if show_T "Medium properties in port_a";
Medium.ThermodynamicState sta_b = Medium.setState_phX(port_b.p, noEvent(actualStream(port_b.h_outflow)), noEvent(actualStream(port_b.Xi_outflow))) if show_T "Medium properties in port_b";
protected
final parameter Modelica.SIunits.MassFlowRate _m_flow_start = 0 "Start value for m_flow, used to avoid a warning if not set in m_flow, and to avoid m_flow.start in parameter window";
final parameter Modelica.SIunits.PressureDifference _dp_start(displayUnit = "Pa") = 0 "Start value for dp, used to avoid a warning if not set in dp, and to avoid dp.start in parameter window";
end PartialTwoPortInterface;

partial model PartialTwoPortTransport  "Partial element transporting fluid between two ports without storage of mass or energy"
extends Buildings.Fluid.Interfaces.PartialTwoPort;
parameter Modelica.SIunits.PressureDifference dp_start(displayUnit = "Pa") = 0 "Guess value of dp = port_a.p - port_b.p" annotation(Dialog(tab = "Advanced"));
parameter Medium.MassFlowRate m_flow_start = 0 "Guess value of m_flow = port_a.m_flow" annotation(Dialog(tab = "Advanced"));
parameter Medium.MassFlowRate m_flow_small "Small mass flow rate for regularization of zero flow" annotation(Dialog(tab = "Advanced"));
parameter Boolean show_T = true "= true, if temperatures at port_a and port_b are computed" annotation(Dialog(tab = "Advanced", group = "Diagnostics"));
parameter Boolean show_V_flow = true "= true, if volume flow rate at inflowing port is computed" annotation(Dialog(tab = "Advanced", group = "Diagnostics"));
Medium.MassFlowRate m_flow(min = if allowFlowReversal then -Modelica.Constants.inf else 0, start = m_flow_start) "Mass flow rate in design flow direction";
Modelica.SIunits.PressureDifference dp(start = dp_start, displayUnit = "Pa") "Pressure difference between port_a and port_b (= port_a.p - port_b.p)";
Modelica.SIunits.VolumeFlowRate V_flow = m_flow / Modelica.Fluid.Utilities.regStep(m_flow, Medium.density(Medium.setState_phX(p = port_a.p, h = inStream(port_a.h_outflow), X = inStream(port_a.Xi_outflow))), Medium.density(Medium.setState_phX(p = port_b.p, h = inStream(port_b.h_outflow), X = inStream(port_b.Xi_outflow))), m_flow_small) if show_V_flow "Volume flow rate at inflowing port (positive when flow from port_a to port_b)";
Medium.Temperature port_a_T = Modelica.Fluid.Utilities.regStep(port_a.m_flow, Medium.temperature(Medium.setState_phX(p = port_a.p, h = inStream(port_a.h_outflow), X = inStream(port_a.Xi_outflow))), Medium.temperature(Medium.setState_phX(port_a.p, port_a.h_outflow, port_a.Xi_outflow)), m_flow_small) if show_T "Temperature close to port_a, if show_T = true";
Medium.Temperature port_b_T = Modelica.Fluid.Utilities.regStep(port_b.m_flow, Medium.temperature(Medium.setState_phX(p = port_b.p, h = inStream(port_b.h_outflow), X = inStream(port_b.Xi_outflow))), Medium.temperature(Medium.setState_phX(port_b.p, port_b.h_outflow, port_b.Xi_outflow)), m_flow_small) if show_T "Temperature close to port_b, if show_T = true";
equation
dp = port_a.p - port_b.p;
m_flow = port_a.m_flow;
assert(m_flow > (-m_flow_small) or allowFlowReversal, "Reverting flow occurs even though allowFlowReversal is false");
port_a.m_flow + port_b.m_flow = 0;
port_a.Xi_outflow = if allowFlowReversal then inStream(port_b.Xi_outflow) else Medium.X_default[1:Medium.nXi];
port_b.Xi_outflow = inStream(port_a.Xi_outflow);
port_a.C_outflow = if allowFlowReversal then inStream(port_b.C_outflow) else zeros(Medium.nC);
port_b.C_outflow = inStream(port_a.C_outflow);
end PartialTwoPortTransport;

model StaticTwoPortConservationEquation  "Partial model for static energy and mass conservation equations"
extends Buildings.Fluid.Interfaces.PartialTwoPortInterface;
constant Boolean simplify_mWat_flow = true "Set to true to cause port_a.m_flow + port_b.m_flow = 0 even if mWat_flow is non-zero";
constant Boolean prescribedHeatFlowRate = false "Set to true if the heat flow rate is not a function of a temperature difference to the fluid temperature";
parameter Boolean use_mWat_flow = false "Set to true to enable input connector for moisture mass flow rate" annotation(Evaluate = true, Dialog(tab = "Advanced"));
parameter Boolean use_C_flow = false "Set to true to enable input connector for trace substance" annotation(Evaluate = true, Dialog(tab = "Advanced"));
Modelica.Blocks.Interfaces.RealInput Q_flow(unit = "W") "Sensible plus latent heat flow rate transferred into the medium" annotation(Placement(transformation(extent = {{-140, 60}, {-100, 100}})));
Modelica.Blocks.Interfaces.RealInput mWat_flow(final quantity = "MassFlowRate", unit = "kg/s") if use_mWat_flow "Moisture mass flow rate added to the medium" annotation(Placement(transformation(extent = {{-140, 20}, {-100, 60}})));
Modelica.Blocks.Interfaces.RealInput[Medium.nC] C_flow if use_C_flow "Trace substance mass flow rate added to the medium" annotation(Placement(transformation(extent = {{-140, -60}, {-100, -20}})));
Modelica.Blocks.Interfaces.RealOutput hOut(unit = "J/kg", start = Medium.specificEnthalpy_pTX(p = Medium.p_default, T = Medium.T_default, X = Medium.X_default)) "Leaving specific enthalpy of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {-50, 110}), iconTransformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {-50, 110})));
Modelica.Blocks.Interfaces.RealOutput[Medium.nXi] XiOut(each unit = "1", each min = 0, each max = 1) "Leaving species concentration of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {0, 110})));
Modelica.Blocks.Interfaces.RealOutput[Medium.nC] COut(each min = 0) "Leaving trace substances of the component" annotation(Placement(transformation(extent = {{-10, -10}, {10, 10}}, rotation = 90, origin = {50, 110})));
protected
final parameter Boolean use_m_flowInv = prescribedHeatFlowRate or use_mWat_flow or use_C_flow "Flag, true if m_flowInv is used in the model" annotation(Evaluate = true);
final parameter Real[Medium.nXi] s = {if Modelica.Utilities.Strings.isEqual(string1 = Medium.substanceNames[i], string2 = "Water", caseSensitive = false) then 1 else 0 for i in 1:Medium.nXi} "Vector with zero everywhere except where species is";
Real m_flowInv(unit = "s/kg") "Regularization of 1/m_flow of port_a";
Modelica.SIunits.MassFlowRate[Medium.nXi] mXi_flow "Mass flow rates of independent substances added to the medium";
final parameter Real deltaReg = m_flow_small / 1E3 "Smoothing region for inverseXRegularized";
final parameter Real deltaInvReg = 1 / deltaReg "Inverse value of delta for inverseXRegularized";
final parameter Real aReg = -15 * deltaInvReg "Polynomial coefficient for inverseXRegularized";
final parameter Real bReg = 119 * deltaInvReg ^ 2 "Polynomial coefficient for inverseXRegularized";
final parameter Real cReg = -361 * deltaInvReg ^ 3 "Polynomial coefficient for inverseXRegularized";
final parameter Real dReg = 534 * deltaInvReg ^ 4 "Polynomial coefficient for inverseXRegularized";
final parameter Real eReg = -380 * deltaInvReg ^ 5 "Polynomial coefficient for inverseXRegularized";
final parameter Real fReg = 104 * deltaInvReg ^ 6 "Polynomial coefficient for inverseXRegularized";
final parameter Medium.ThermodynamicState state_default = Medium.setState_pTX(T = Medium.T_default, p = Medium.p_default, X = Medium.X_default[1:Medium.nXi]) "Medium state at default values";
final parameter Modelica.SIunits.SpecificHeatCapacity cp_default = Medium.specificHeatCapacityCp(state = state_default) "Specific heat capacity, used to verify energy conservation";
Modelica.Blocks.Interfaces.RealInput mWat_flow_internal(unit = "kg/s") "Needed to connect to conditional connector";
Modelica.Blocks.Interfaces.RealInput[Medium.nC] C_flow_internal "Needed to connect to conditional connector";
initial equation
assert(Medium.nXi == 0 or abs(sum(s) - 1) < 1e-5, "If Medium.nXi > 1, then substance 'water' must be present for one component.'" + Medium.mediumName + "'.\n" + "Check medium model.");
equation
connect(mWat_flow, mWat_flow_internal);
if not use_mWat_flow then
mWat_flow_internal = 0;
end if;
connect(C_flow, C_flow_internal);
if not use_C_flow then
C_flow_internal = zeros(Medium.nC);
end if;
mXi_flow = mWat_flow_internal * s;
if use_m_flowInv then
m_flowInv = Buildings.Utilities.Math.Functions.inverseXRegularized(x = port_a.m_flow, delta = deltaReg, deltaInv = deltaInvReg, a = aReg, b = bReg, c = cReg, d = dReg, e = eReg, f = fReg);
else
m_flowInv = 0;
end if;
if prescribedHeatFlowRate then
assert(noEvent(if abs(m_flow) < Modelica.Constants.small then abs(Q_flow) < 1E-10 else abs(Q_flow / cp_default / m_flow) < 200), "Energy may not be conserved for small mass flow rates. This model may require prescribedHeatFlowRate = false.");
end if;
if allowFlowReversal then
hOut = Buildings.Utilities.Math.Functions.regStep(y1 = port_b.h_outflow, y2 = port_a.h_outflow, x = port_a.m_flow, x_small = m_flow_small / 1E3);
XiOut = Buildings.Utilities.Math.Functions.regStep(y1 = port_b.Xi_outflow, y2 = port_a.Xi_outflow, x = port_a.m_flow, x_small = m_flow_small / 1E3);
COut = Buildings.Utilities.Math.Functions.regStep(y1 = port_b.C_outflow, y2 = port_a.C_outflow, x = port_a.m_flow, x_small = m_flow_small / 1E3);
else
hOut = port_b.h_outflow;
XiOut = port_b.Xi_outflow;
COut = port_b.C_outflow;
end if;
port_a.m_flow + port_b.m_flow = if simplify_mWat_flow then 0 else -mWat_flow_internal;
if use_m_flowInv then
port_b.Xi_outflow = inStream(port_a.Xi_outflow) + mXi_flow * m_flowInv;
else
assert(use_mWat_flow == false, "Wrong implementation for forward flow.");
port_b.Xi_outflow = inStream(port_a.Xi_outflow);
end if;
if allowFlowReversal then
if use_m_flowInv then
port_a.Xi_outflow = inStream(port_b.Xi_outflow) - mXi_flow * m_flowInv;
else
assert(use_mWat_flow == false, "Wrong implementation for reverse flow.");
port_a.Xi_outflow = inStream(port_b.Xi_outflow);
end if;
else
port_a.Xi_outflow = Medium.X_default[1:Medium.nXi];
end if;
if prescribedHeatFlowRate then
port_b.h_outflow = inStream(port_a.h_outflow) + Q_flow * m_flowInv;
if allowFlowReversal then
port_a.h_outflow = inStream(port_b.h_outflow) - Q_flow * m_flowInv;
else
port_a.h_outflow = Medium.h_default;
end if;
else
port_a.m_flow * (inStream(port_a.h_outflow) - port_b.h_outflow) = -Q_flow;
if allowFlowReversal then
port_a.m_flow * (inStream(port_b.h_outflow) - port_a.h_outflow) = +Q_flow;
else
port_a.h_outflow = Medium.h_default;
end if;
end if;
if use_m_flowInv and use_C_flow then
port_b.C_outflow = inStream(port_a.C_outflow) + C_flow_internal * m_flowInv;
else
assert(not use_C_flow, "Wrong implementation of trace substance balance for forward flow.");
port_b.C_outflow = inStream(port_a.C_outflow);
end if;
if allowFlowReversal then
if use_C_flow then
port_a.C_outflow = inStream(port_b.C_outflow) - C_flow_internal * m_flowInv;
else
port_a.C_outflow = inStream(port_b.C_outflow);
end if;
else
port_a.C_outflow = zeros(Medium.nC);
end if;
port_a.p = port_b.p;
annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}, grid = {1, 1}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid, pattern = LinePattern.None), Text(extent = {{-93, 72}, {-58, 89}}, lineColor = {0, 0, 127}, textString = "Q_flow"), Text(extent = {{-93, 37}, {-58, 54}}, lineColor = {0, 0, 127}, textString = "mWat_flow"), Text(extent = {{-41, 103}, {-10, 117}}, lineColor = {0, 0, 127}, textString = "hOut"), Text(extent = {{10, 103}, {41, 117}}, lineColor = {0, 0, 127}, textString = "XiOut"), Text(extent = {{61, 103}, {92, 117}}, lineColor = {0, 0, 127}, textString = "COut"), Line(points = {{-42, 55}, {-42, -84}}, color = {255, 255, 255}), Polygon(points = {{-42, 67}, {-50, 45}, {-34, 45}, {-42, 67}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Polygon(points = {{87, -73}, {65, -65}, {65, -81}, {87, -73}}, lineColor = {255, 255, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Line(points = {{-56, -73}, {81, -73}}, color = {255, 255, 255}), Line(points = {{6, 14}, {6, -37}}, color = {255, 255, 255}), Line(points = {{54, 14}, {6, 14}}, color = {255, 255, 255}), Line(points = {{6, -37}, {-42, -37}}, color = {255, 255, 255})}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})));
end StaticTwoPortConservationEquation;

record LumpedVolumeDeclarations  "Declarations for lumped volumes"
replaceable package Medium = Modelica.Media.Interfaces.PartialMedium "Medium in the component" annotation(choicesAllMatching = true);
parameter Modelica.Fluid.Types.Dynamics energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial "Type of energy balance: dynamic (3 initialization options) or steady state" annotation(Evaluate = true, Dialog(tab = "Dynamics", group = "Equations"));
parameter Modelica.Fluid.Types.Dynamics massDynamics = energyDynamics "Type of mass balance: dynamic (3 initialization options) or steady state" annotation(Evaluate = true, Dialog(tab = "Dynamics", group = "Equations"));
final parameter Modelica.Fluid.Types.Dynamics substanceDynamics = energyDynamics "Type of independent mass fraction balance: dynamic (3 initialization options) or steady state" annotation(Evaluate = true, Dialog(tab = "Dynamics", group = "Equations"));
final parameter Modelica.Fluid.Types.Dynamics traceDynamics = energyDynamics "Type of trace substance balance: dynamic (3 initialization options) or steady state" annotation(Evaluate = true, Dialog(tab = "Dynamics", group = "Equations"));
parameter Medium.AbsolutePressure p_start = Medium.p_default "Start value of pressure" annotation(Dialog(tab = "Initialization"));
parameter Medium.Temperature T_start = Medium.T_default "Start value of temperature" annotation(Dialog(tab = "Initialization"));
parameter Medium.MassFraction[Medium.nX] X_start(quantity = Medium.substanceNames) = Medium.X_default "Start value of mass fractions m_i/m" annotation(Dialog(tab = "Initialization", enable = Medium.nXi > 0));
parameter Medium.ExtraProperty[Medium.nC] C_start(quantity = Medium.extraPropertiesNames) = fill(0, Medium.nC) "Start value of trace substances" annotation(Dialog(tab = "Initialization", enable = Medium.nC > 0));
parameter Medium.ExtraProperty[Medium.nC] C_nominal(quantity = Medium.extraPropertiesNames) = fill(1E-2, Medium.nC) "Nominal value of trace substances. (Set to typical order of magnitude.)" annotation(Dialog(tab = "Initialization", enable = Medium.nC > 0));
parameter Real mSenFac(min = 1) = 1 "Factor for scaling the sensible thermal mass of the volume" annotation(Dialog(tab = "Dynamics"));
end LumpedVolumeDeclarations;
end Interfaces;
annotation(preferredView = "info", Icon(graphics = {Polygon(points = {{-70, 26}, {68, -44}, {68, 26}, {2, -10}, {-70, -42}, {-70, 26}}, lineColor = {0, 0, 0}), Line(points = {{2, 42}, {2, -10}}, color = {0, 0, 0}), Rectangle(extent = {{-18, 50}, {22, 42}}, lineColor = {0, 0, 0}, fillColor = {0, 0, 0}, fillPattern = FillPattern.Solid)}));
end Fluid;

package HeatTransfer
extends Modelica.Icons.Package;

package Sources
extends Modelica.Icons.SourcesPackage;

model PrescribedTemperature
Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_b port annotation(Placement(transformation(extent = {{90, -10}, {110, 10}})));
Modelica.Blocks.Interfaces.RealInput T annotation(Placement(transformation(extent = {{-140, -20}, {-100, 20}})));
equation
port.T = T;
annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, pattern = LinePattern.None, fillColor = {159, 159, 223}, fillPattern = FillPattern.Backward), Line(points = {{-102, 0}, {64, 0}}, color = {191, 0, 0}, thickness = 0.5), Text(extent = {{0, 0}, {-100, -100}}, lineColor = {0, 0, 0}, textString = "K"), Text(extent = {{-150, 150}, {150, 110}}, textString = "%name", lineColor = {0, 0, 255}), Polygon(points = {{50, -20}, {50, 20}, {90, 0}, {50, -20}}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid)}), Diagram(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 0}, pattern = LinePattern.None, fillColor = {159, 159, 223}, fillPattern = FillPattern.Backward), Text(extent = {{0, 0}, {-100, -100}}, lineColor = {0, 0, 0}, textString = "K"), Line(points = {{-102, 0}, {64, 0}}, color = {191, 0, 0}, thickness = 0.5), Polygon(points = {{52, -20}, {52, 20}, {90, 0}, {52, -20}}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid)}));
end PrescribedTemperature;
end Sources;
annotation(preferredView = "info", Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Polygon(origin = {13.758, 27.517}, lineColor = {128, 128, 128}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{-54, -6}, {-61, -7}, {-75, -15}, {-79, -24}, {-80, -34}, {-78, -42}, {-73, -49}, {-64, -51}, {-57, -51}, {-47, -50}, {-41, -43}, {-38, -35}, {-40, -27}, {-40, -20}, {-42, -13}, {-47, -7}, {-54, -5}, {-54, -6}}), Polygon(origin = {13.758, 27.517}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{-75, -15}, {-79, -25}, {-80, -34}, {-78, -42}, {-72, -49}, {-64, -51}, {-57, -51}, {-47, -50}, {-57, -47}, {-65, -45}, {-71, -40}, {-74, -33}, {-76, -23}, {-75, -15}, {-75, -15}}), Polygon(origin = {13.758, 27.517}, lineColor = {160, 160, 164}, fillColor = {192, 192, 192}, fillPattern = FillPattern.Solid, points = {{39, -6}, {32, -7}, {18, -15}, {14, -24}, {13, -34}, {15, -42}, {20, -49}, {29, -51}, {36, -51}, {46, -50}, {52, -43}, {55, -35}, {53, -27}, {53, -20}, {51, -13}, {46, -7}, {39, -5}, {39, -6}}), Polygon(origin = {13.758, 27.517}, fillColor = {160, 160, 164}, fillPattern = FillPattern.Solid, points = {{18, -15}, {14, -25}, {13, -34}, {15, -42}, {21, -49}, {29, -51}, {36, -51}, {46, -50}, {36, -47}, {28, -45}, {22, -40}, {19, -33}, {17, -23}, {18, -15}, {18, -15}}), Polygon(origin = {13.758, 27.517}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid, points = {{-9, -23}, {-9, -10}, {18, -17}, {-9, -23}}), Line(origin = {13.758, 27.517}, points = {{-41, -17}, {-9, -17}}, color = {191, 0, 0}, thickness = 0.5), Line(origin = {13.758, 27.517}, points = {{-17, -40}, {15, -40}}, color = {191, 0, 0}, thickness = 0.5), Polygon(origin = {13.758, 27.517}, lineColor = {191, 0, 0}, fillColor = {191, 0, 0}, fillPattern = FillPattern.Solid, points = {{-17, -46}, {-17, -34}, {-40, -40}, {-17, -46}})}));
end HeatTransfer;

package Utilities
extends Modelica.Icons.Package;

package Math
extends Modelica.Icons.Package;

package Functions
extends Modelica.Icons.VariantsPackage;

function cubicHermiteLinearExtrapolation
input Real x "Abscissa value";
input Real x1 "Lower abscissa value";
input Real x2 "Upper abscissa value";
input Real y1 "Lower ordinate value";
input Real y2 "Upper ordinate value";
input Real y1d "Lower gradient";
input Real y2d "Upper gradient";
output Real y "Interpolated ordinate value";
algorithm
if x > x1 and x < x2 then
y := Modelica.Fluid.Utilities.cubicHermite(x = x, x1 = x1, x2 = x2, y1 = y1, y2 = y2, y1d = y1d, y2d = y2d);
elseif x <= x1 then
y := y1 + (x - x1) * y1d;
else
y := y2 + (x - x2) * y2d;
end if;
end cubicHermiteLinearExtrapolation;

function inverseXRegularized  "Function that approximates 1/x by a twice continuously differentiable function"
input Real x "Abscissa value";
input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
input Real deltaInv = 1 / delta "Inverse value of delta";
input Real a = -15 * deltaInv "Polynomial coefficient";
input Real b = 119 * deltaInv ^ 2 "Polynomial coefficient";
input Real c = -361 * deltaInv ^ 3 "Polynomial coefficient";
input Real d = 534 * deltaInv ^ 4 "Polynomial coefficient";
input Real e = -380 * deltaInv ^ 5 "Polynomial coefficient";
input Real f = 104 * deltaInv ^ 6 "Polynomial coefficient";
output Real y "Function value";
algorithm
y := if x > delta or x < (-delta) then 1 / x elseif x < delta / 2 and x > (-delta / 2) then x / (delta * delta) else BaseClasses.smoothTransition(x = x, delta = delta, deltaInv = deltaInv, a = a, b = b, c = c, d = d, e = e, f = f);
end inverseXRegularized;

function isMonotonic  "Returns true if the argument is a monotonic sequence"
input Real[:] x "Sequence to be tested";
input Boolean strict = false "Set to true to test for strict monotonicity";
output Boolean monotonic "True if x is monotonic increasing or decreasing";
protected
Integer n = size(x, 1) "Number of data points";
algorithm
if n == 1 then
monotonic := true;
else
monotonic := true;
if strict then
if x[1] >= x[n] then
for i in 1:n - 1 loop
if not x[i] > x[i + 1] then
monotonic := false;
else
end if;
end for;
else
for i in 1:n - 1 loop
if not x[i] < x[i + 1] then
monotonic := false;
else
end if;
end for;
end if;
else
if x[1] >= x[n] then
for i in 1:n - 1 loop
if not x[i] >= x[i + 1] then
monotonic := false;
else
end if;
end for;
else
for i in 1:n - 1 loop
if not x[i] <= x[i + 1] then
monotonic := false;
else
end if;
end for;
end if;
end if;
end if;
end isMonotonic;

function regStep  "Approximation of a general step, such that the approximation is continuous and differentiable"
extends Modelica.Icons.Function;
input Real x "Abscissa value";
input Real y1 "Ordinate value for x > 0";
input Real y2 "Ordinate value for x < 0";
input Real x_small(min = 0) = 1e-5 "Approximation of step for -x_small <= x <= x_small; x_small >= 0 required";
output Real y "Ordinate value to approximate y = if x > 0 then y1 else y2";
algorithm
y := smooth(1, if x > x_small then y1 else if x < (-x_small) then y2 else if x_small > 0 then x / x_small * ((x / x_small) ^ 2 - 3) * (y2 - y1) / 4 + (y1 + y2) / 2 else (y1 + y2) / 2);
end regStep;

function smoothMax  "Once continuously differentiable approximation to the maximum function"
input Real x1 "First argument";
input Real x2 "Second argument";
input Real deltaX "Width of transition interval";
output Real y "Result";
algorithm
y := Buildings.Utilities.Math.Functions.regStep(y1 = x1, y2 = x2, x = x1 - x2, x_small = deltaX);
end smoothMax;

function splineDerivatives  "Function to compute the derivatives for cubic hermite spline interpolation"
input Real[:] x "Support point, strict monotone increasing";
input Real[size(x, 1)] y "Function values at x";
input Boolean ensureMonotonicity = isMonotonic(y, strict = false) "Set to true to ensure monotonicity of the cubic hermite";
output Real[size(x, 1)] d "Derivative at the support points";
protected
Integer n = size(x, 1) "Number of data points";
Real[n - 1] delta "Slope of secant line between data points";
Real alpha "Coefficient to ensure monotonicity";
Real beta "Coefficient to ensure monotonicity";
Real tau "Coefficient to ensure monotonicity";
algorithm
if n > 1 then
assert(x[1] < x[n], "x must be strictly increasing.
Received x[1] = " + String(x[1]) + "
x[" + String(n) + "] = " + String(x[n]));
assert(isMonotonic(x, strict = true), "x-values must be strictly monontone increasing or decreasing.");
if ensureMonotonicity then
assert(isMonotonic(y, strict = false), "If ensureMonotonicity=true, y-values must be monontone increasing or decreasing.");
else
end if;
else
end if;
if n == 1 then
d[1] := 0;
elseif n == 2 then
d[1] := (y[2] - y[1]) / (x[2] - x[1]);
d[2] := d[1];
else
for i in 1:n - 1 loop
delta[i] := (y[i + 1] - y[i]) / (x[i + 1] - x[i]);
end for;
d[1] := delta[1];
d[n] := delta[n - 1];
for i in 2:n - 1 loop
d[i] := (delta[i - 1] + delta[i]) / 2;
end for;
end if;
if n > 2 and ensureMonotonicity then
for i in 1:n - 1 loop
if abs(delta[i]) < Modelica.Constants.small then
d[i] := 0;
d[i + 1] := 0;
else
alpha := d[i] / delta[i];
beta := d[i + 1] / delta[i];
if alpha ^ 2 + beta ^ 2 > 9 then
tau := 3 / (alpha ^ 2 + beta ^ 2) ^ (1 / 2);
d[i] := delta[i] * alpha * tau;
d[i + 1] := delta[i] * beta * tau;
else
end if;
end if;
end for;
else
end if;
end splineDerivatives;

package BaseClasses  "Package with base classes for Buildings.Utilities.Math.Functions"
extends Modelica.Icons.BasesPackage;

function der_2_smoothTransition  "Second order derivative of smoothTransition with respect to x"
input Real x "Abscissa value";
input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
input Real deltaInv "Inverse value of delta";
input Real a "Polynomial coefficient";
input Real b "Polynomial coefficient";
input Real c "Polynomial coefficient";
input Real d "Polynomial coefficient";
input Real e "Polynomial coefficient";
input Real f "Polynomial coefficient";
input Real x_der "Derivative of x";
input Real x_der2 "Second order derivative of x";
output Real y_der2 "Second order derivative of function value";
protected
Real aX "Absolute value of x";
Real ex "Intermediate expression";
algorithm
aX := abs(x);
ex := 2 * c + aX * (6 * d + aX * (12 * e + aX * 20 * f));
y_der2 := (b + aX * (2 * c + aX * (3 * d + aX * (4 * e + aX * 5 * f)))) * x_der2 + x_der * x_der * (if x > 0 then ex else -ex);
end der_2_smoothTransition;

function der_inverseXRegularized  "Derivative of inverseXRegularised function"
input Real x "Abscissa value";
input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
input Real deltaInv = 1 / delta "Inverse value of delta";
input Real a = -15 * deltaInv "Polynomial coefficient";
input Real b = 119 * deltaInv ^ 2 "Polynomial coefficient";
input Real c = -361 * deltaInv ^ 3 "Polynomial coefficient";
input Real d = 534 * deltaInv ^ 4 "Polynomial coefficient";
input Real e = -380 * deltaInv ^ 5 "Polynomial coefficient";
input Real f = 104 * deltaInv ^ 6 "Polynomial coefficient";
input Real x_der "Abscissa value";
output Real y_der "Function value";
algorithm
y_der := if x > delta or x < (-delta) then -x_der / x / x elseif x < delta / 2 and x > (-delta / 2) then x_der / (delta * delta) else Buildings.Utilities.Math.Functions.BaseClasses.der_smoothTransition(x = x, x_der = x_der, delta = delta, deltaInv = deltaInv, a = a, b = b, c = c, d = d, e = e, f = f);
end der_inverseXRegularized;

function der_smoothTransition  "First order derivative of smoothTransition with respect to x"
input Real x "Abscissa value";
input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
input Real deltaInv "Inverse value of delta";
input Real a "Polynomial coefficient";
input Real b "Polynomial coefficient";
input Real c "Polynomial coefficient";
input Real d "Polynomial coefficient";
input Real e "Polynomial coefficient";
input Real f "Polynomial coefficient";
input Real x_der "Derivative of x";
output Real y_der "Derivative of function value";
protected
Real aX "Absolute value of x";
algorithm
aX := abs(x);
y_der := (b + aX * (2 * c + aX * (3 * d + aX * (4 * e + aX * 5 * f)))) * x_der;
end der_smoothTransition;

function smoothTransition  "Twice continuously differentiable transition between the regions"
input Real x "Abscissa value";
input Real delta(min = Modelica.Constants.eps) "Abscissa value below which approximation occurs";
input Real deltaInv = 1 / delta "Inverse value of delta";
input Real a = -15 * deltaInv "Polynomial coefficient";
input Real b = 119 * deltaInv ^ 2 "Polynomial coefficient";
input Real c = -361 * deltaInv ^ 3 "Polynomial coefficient";
input Real d = 534 * deltaInv ^ 4 "Polynomial coefficient";
input Real e = -380 * deltaInv ^ 5 "Polynomial coefficient";
input Real f = 104 * deltaInv ^ 6 "Polynomial coefficient";
output Real y "Function value";
protected
Real aX "Absolute value of x";
algorithm
aX := abs(x);
y := a + aX * (b + aX * (c + aX * (d + aX * (e + aX * f))));
if x < 0 then
y := -y;
else
end if;
end smoothTransition;
end BaseClasses;
end Functions;
annotation(Icon(coordinateSystem(preserveAspectRatio = true, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{-80, 0}, {-68.7, 34.2}, {-61.5, 53.1}, {-55.1, 66.4}, {-49.4, 74.6}, {-43.8, 79.1}, {-38.2, 79.8}, {-32.6, 76.6}, {-26.9, 69.7}, {-21.3, 59.4}, {-14.9, 44.1}, {-6.83, 21.2}, {10.1, -30.8}, {17.3, -50.2}, {23.7, -64.2}, {29.3, -73.1}, {35, -78.4}, {40.6, -80}, {46.2, -77.6}, {51.9, -71.5}, {57.5, -61.9}, {63.9, -47.2}, {72, -24.8}, {80, 0}}, color = {0, 0, 0}, smooth = Smooth.Bezier)}));
end Math;
annotation(Icon(coordinateSystem(extent = {{-100.0, -100.0}, {100.0, 100.0}}), graphics = {Polygon(origin = {1.3835, -4.1418}, rotation = 45.0, fillColor = {64, 64, 64}, pattern = LinePattern.None, fillPattern = FillPattern.Solid, points = {{-15.0, 93.333}, {-15.0, 68.333}, {0.0, 58.333}, {15.0, 68.333}, {15.0, 93.333}, {20.0, 93.333}, {25.0, 83.333}, {25.0, 58.333}, {10.0, 43.333}, {10.0, -41.667}, {25.0, -56.667}, {25.0, -76.667}, {10.0, -91.667}, {0.0, -91.667}, {0.0, -81.667}, {5.0, -81.667}, {15.0, -71.667}, {15.0, -61.667}, {5.0, -51.667}, {-5.0, -51.667}, {-15.0, -61.667}, {-15.0, -71.667}, {-5.0, -81.667}, {0.0, -81.667}, {0.0, -91.667}, {-10.0, -91.667}, {-25.0, -76.667}, {-25.0, -56.667}, {-10.0, -41.667}, {-10.0, 43.333}, {-25.0, 58.333}, {-25.0, 83.333}, {-20.0, 93.333}}), Polygon(origin = {10.1018, 5.218}, rotation = -45.0, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid, points = {{-15.0, 87.273}, {15.0, 87.273}, {20.0, 82.273}, {20.0, 27.273}, {10.0, 17.273}, {10.0, 7.273}, {20.0, 2.273}, {20.0, -2.727}, {5.0, -2.727}, {5.0, -77.727}, {10.0, -87.727}, {5.0, -112.727}, {-5.0, -112.727}, {-10.0, -87.727}, {-5.0, -77.727}, {-5.0, -2.727}, {-20.0, -2.727}, {-20.0, 2.273}, {-10.0, 7.273}, {-10.0, 17.273}, {-20.0, 27.273}, {-20.0, 82.273}})}));
end Utilities;
end Buildings;

model PartialFlowMachine_total  "Partial model to interface fan or pump models with the medium"
extends Buildings.Fluid.Movers.BaseClasses.PartialFlowMachine;
annotation(Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Line(points = {{0, 50}, {100, 50}}, color = {0, 0, 0}, smooth = Smooth.None), Line(points = {{0, 80}, {100, 80}}, color = {0, 0, 0}, smooth = Smooth.None), Line(visible = not filteredSpeed, points = {{0, 100}, {0, 40}}), Rectangle(extent = {{-100, 16}, {100, -14}}, lineColor = {0, 0, 0}, fillColor = {0, 127, 255}, fillPattern = FillPattern.HorizontalCylinder), Ellipse(extent = {{-58, 50}, {54, -58}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Sphere, fillColor = {0, 100, 199}), Polygon(points = {{0, 50}, {0, -56}, {54, 2}, {0, 50}}, lineColor = {0, 0, 0}, pattern = LinePattern.None, fillPattern = FillPattern.HorizontalCylinder, fillColor = {255, 255, 255}), Ellipse(extent = {{4, 14}, {34, -16}}, lineColor = {0, 0, 0}, fillPattern = FillPattern.Sphere, visible = energyDynamics <> Modelica.Fluid.Types.Dynamics.SteadyState, fillColor = {0, 100, 199}), Rectangle(visible = filteredSpeed, extent = {{-34, 40}, {32, 100}}, lineColor = {0, 0, 0}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid), Ellipse(visible = filteredSpeed, extent = {{-34, 100}, {32, 40}}, lineColor = {0, 0, 0}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid), Text(visible = filteredSpeed, extent = {{-22, 92}, {20, 46}}, lineColor = {0, 0, 0}, fillColor = {135, 135, 135}, fillPattern = FillPattern.Solid, textString = "M", textStyle = {TextStyle.Bold}), Text(extent = {{64, 98}, {114, 84}}, lineColor = {0, 0, 127}, textString = "P")}), Diagram(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}})));
end PartialFlowMachine_total;
