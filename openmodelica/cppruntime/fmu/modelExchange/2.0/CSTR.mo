model CSTR
  "Continuous stirred reactor with parallel and subsequent reaction.
   See: Engell, Klatt: Nonlinear control of a nonminimum phase CSTR.
   In Americal Control Conference, Los Angeles, 1993."
  import SI = Modelica.SIunits;
  parameter SI.MolarEnergy[:] H = {4.2e3, -11.0e3, -41.85e3};
  parameter SI.Density rho = 0.9342e3;
  parameter SI.SpecificHeatCapacity Cp = 3.01e3;
  parameter SI.CoefficientOfHeatTransfer kw = 1.12e3;
  parameter SI.Area AR = 0.215 "reactor surface area";
  parameter SI.Volume VR = 0.01 "reactor volume";
  parameter SI.Mass mK = 5.0 "coolant mass";
  parameter SI.SpecificHeatCapacity CpK = 2.0e3 "coolant heat capacity";
  parameter Real cAF(unit="mol/l") = 5.10 "Concentration of substance A in feed";
  Modelica.Blocks.Interfaces.RealInput VF_flow(unit="1/h", start=14.19)
    "Feed flow rate" annotation (Placement(transformation(extent={{-140,-20},{-100,
            20}}, rotation=0), iconTransformation(extent={{-140,-20},{-100,20}})));
  Modelica.Blocks.Interfaces.RealInput TF(unit="degC", start=104.9)
    "Feed temperature" annotation (Placement(transformation(extent={{-140,40},{-100,
            80}}, rotation=0), iconTransformation(extent={{-140,40},{-100,80}})));
  Modelica.Blocks.Interfaces.RealInput QK_flow(unit="kJ/h", nominal=1000,
    start=-1113.5) "Heat flow rate" annotation (Placement(transformation(extent={{-140,-80},{-100,
            -40}}, rotation=0), iconTransformation(extent={{-140,-80},{-100,-40}})));
  Modelica.Blocks.Interfaces.RealOutput cA(unit="mol/l",
    start = 2.14, fixed = true, stateSelect=StateSelect.always)
    "Concentration"
    annotation (Placement(transformation(extent={{100,40},{140,80}},
          rotation=0), iconTransformation(extent={{100,40},{140,80}})));
  Modelica.Blocks.Interfaces.RealOutput cB(unit="mol/l",
    start = 1.09, fixed = fixedInitial) "Concentration"
    annotation (Placement(transformation(extent={{100,-20},{140,20}},
          rotation=0), iconTransformation(extent={{100,-20},{140,20}})));
  Modelica.Blocks.Interfaces.RealOutput TK(unit="degC", nominal=100,
    start = 112.9, fixed = fixedInitial) "Coolant temperature"
    annotation (Placement(transformation(extent={{100,-80},{140,-40}},
          rotation=0), iconTransformation(extent={{100,-80},{140,-40}})));
  SI.Temp_C T(nominal=100, start=114.2, fixed=fixedInitial);
  parameter Real[:] k0 = {1.287e12, 1.287e12, 9.043e9}/3600;
  parameter Real[:] E = {-9758.3, -9758.3, -8560};
  Real[size(k0, 1)] k;
  parameter Boolean fixedInitial = true "=false to free reactor states"
    annotation(Evaluate=true);
  parameter SI.Time samplePeriod = 20 "Period of clock"
    annotation(Evaluate=true);
  parameter ModelicaServices.Types.SolverMethod solverMethod = "ImplicitEuler";
  Clock clock = Clock(Clock(samplePeriod), solverMethod=solverMethod);
  Real QK_flow_sampled = sample(QK_flow, clock);
equation
  k = k0 .* exp(E./(T + 273.15));
  der(cA) = VF_flow/3600*(cAF - cA) - k[1]*cA - k[3]*cA^2;
  der(cB) = -VF_flow/3600*cB + k[1]*cA - k[2]*cB;
  der(T) = VF_flow/3600*(TF - T)
    - 1000/rho/Cp*(k[1]*cA*H[1] + k[2]*cB*H[2] + k[3]*cA^2*H[3])
    + kw*AR/rho/Cp/VR*(TK - T);
  der(TK) = 1/mK/CpK * (QK_flow_sampled*1000/3600 + kw*AR*(T - TK));
  annotation (uses(Modelica(version="3.2.2")), experiment(StopTime=1500),
      Diagram(coordinateSystem(preserveAspectRatio=false, extent={{
            -100,-100},{100,100}})),
      Icon(coordinateSystem(preserveAspectRatio=false,
          extent={{-100,-100},{100,100}}), graphics={
        Rectangle(
          extent={{-100,40},{100,-100}},
          lineColor={255,255,255},
          fillColor={0,255,255},
          fillPattern=FillPattern.Solid),
        Line(points={{-100,100},{-100,-100},{100,-100},{100,100}}, color={0,
              0,0}),
        Text(
          extent={{-144,148},{148,100}},
          lineColor={0,0,255},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid,
          textString="%name"),
        Text(
          extent={{120,-30},{162,-50}},
          lineColor={0,0,0},
          textString="TK"),
        Text(
          extent={{120,90},{162,70}},
          lineColor={0,0,0},
          textString="cA"),
        Text(
          extent={{-240,30},{-140,10}},
          lineColor={0,0,0},
          textString="VF_flow"),
        Line(points={{0,-50},{0,-100}}, color={0,0,0}),
        Ellipse(
          extent={{-42,-38},{0,-66}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Ellipse(
          extent={{0,-38},{42,-66}},
          lineColor={0,0,0},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Text(
          extent={{-240,-30},{-140,-50}},
          lineColor={0,0,0},
          textString="QK_flow"),
        Text(
          extent={{120,30},{162,10}},
          lineColor={0,0,0},
          textString="cB"),
        Text(
          extent={{-220,90},{-120,70}},
          lineColor={0,0,0},
          textString="TF")}));
end CSTR;
