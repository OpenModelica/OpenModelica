within ThermoSysPro.WaterSteam.HeatExchangers;
model DynamicOnePhaseFlowPipe "Dynamic one-phase flow pipe"
  parameter Modelica.SIunits.Length L=10.0 "Pipe length";
  parameter Modelica.SIunits.Diameter D=0.2 "Internal pipe diameter";
  parameter Real rugosrel=0.0007 "Pipe relative roughness";
  parameter Integer ntubes=1 "Number of pipes in parallel";
  parameter Modelica.SIunits.Position z1=0 "Pipe inlet altitude";
  parameter Modelica.SIunits.Position z2=0 "Pipe outlet altitude";
  parameter Integer Ns=10 "Number of segments";
  parameter ThermoSysPro.Units.AbsoluteTemperature T0[Ns]=fill(290, Ns) "Initial fluid temperature (active if steady_state = false and option_temperature = 1)";
  parameter ThermoSysPro.Units.SpecificEnthalpy h0[Ns]=fill(100000.0, Ns) "Initial fluid specific enthalpy (active if steady_state = false and option_temperature = 2)";
  parameter Boolean inertia=true "true: momentum balance equation with inertia - false: without inertia";
  parameter Boolean advection=false "true: momentum balance equation with advection terme - false: without advection terme";
  parameter Boolean dynamic_mass_balance=true "true: dynamic mass balance equation - false: static mass balance equation";
  parameter Boolean dynamic_energy_balance=true "true: dynamic energy balance equation - false: static energy balance equation";
  parameter Boolean simplified_dynamic_energy_balance=true "true: simplified dynamic energy balance equation - false: full dynamic energy balance equation (active if dynamic_energy_balance=true)";
  parameter Boolean steady_state=true "true: start from steady state - false: start from T0 (if option_temperature=1) or h0 (if option_temperature=2)";
  parameter Integer option_temperature=1 "1:initial temperature is fixed - 2:initial specific enthalpy is fixed (active if steady_state = false)";
  parameter Boolean continuous_flow_reversal=true "true: continuous flow reversal - false: discontinuous flow reversal";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  ThermoSysPro.Units.AbsolutePressure P[N + 1](start=fill(100000.0, N + 1), nominal=fill(100000.0, N + 1)) "Fluid pressure in node i";
  Modelica.SIunits.MassFlowRate Q[N](start=fill(10, N), nominal=fill(10, N)) "Mass flow rate in node i";
  ThermoSysPro.Units.SpecificEnthalpy h[N + 1](start=fill(100000.0, N + 1), nominal=fill(1000000.0, N + 1)) "Fluid specific enthalpy in node i";
  ThermoSysPro.Units.SpecificEnthalpy hb[N] "Fluid specific enthalpy at the boundary of node i";
  Modelica.SIunits.Density rho1[N - 1](start=fill(998, N - 1), nominal=fill(1, N - 1)) "Fluid density in thermal node i";
  Modelica.SIunits.Density rho2[N](start=fill(998, N), nominal=fill(1, N)) "Fluid density in hydraulic node i";
  Modelica.SIunits.Density rhoc[N + 1](start=fill(998, N + 1), nominal=fill(1, N + 1)) "Fluid density at the boudary of node i";
  Modelica.SIunits.Power dW1[N - 1](start=fill(300000.0, N - 1), nominal=fill(300000.0, N - 1)) "Thermal power exchanged on the water side for node i";
  Modelica.SIunits.Power W1t "Total power exchanged on the water side";
  ThermoSysPro.Units.AbsoluteTemperature Tp[N - 1](start=T0) "Wall temperature in node i";
  Modelica.SIunits.CoefficientOfHeatTransfer hc[N - 1](start=fill(2000, N - 1), nominal=fill(200, N - 1)) "Fluid heat exchange coefficient in node i";
  Modelica.SIunits.ReynoldsNumber Re1[N - 1](start=fill(60000.0, N - 1), nominal=fill(5000.0, N - 1)) "Fluid Reynolds number in thermal node i";
  Modelica.SIunits.ReynoldsNumber Re2[N](start=fill(60000.0, N), nominal=fill(5000.0, N)) "Fluid Reynolds number in hydraulic node i";
  Real Pr[N - 1](start=fill(4, N - 1), nominal=fill(1, N - 1)) "Fluid Prandtl number in node i";
  Modelica.SIunits.ThermalConductivity k[N - 1](start=fill(0.6, N - 1), nominal=fill(0.6, N - 1)) "Fluid thermal conductivity in node i";
  Modelica.SIunits.DynamicViscosity mu1[N - 1](start=fill(0.0002, N - 1), nominal=fill(0.0002, N - 1)) "Fluid dynamic viscosity in thermal node i";
  Modelica.SIunits.DynamicViscosity mu2[N](start=fill(0.0002, N), nominal=fill(0.0002, N)) "Fluid dynamic viscosity in hydraulic node i";
  Modelica.SIunits.SpecificHeatCapacity cp[N - 1](start=fill(4000, N - 1), nominal=fill(4000, N - 1)) "Fluid specific heat capacity";
  ThermoSysPro.Units.AbsoluteTemperature T1[N - 1] "Fluid temperature in thermal node i";
  ThermoSysPro.Units.AbsoluteTemperature T2[N] "Fluid temperature in hydraulic node i";
  ThermoSysPro.Units.DifferentialPressure dpa[N] "Advection term for the mass balance equation in node i";
  ThermoSysPro.Units.DifferentialPressure dpf[N] "Friction pressure loss in node i";
  ThermoSysPro.Units.DifferentialPressure dpg[N] "Gravity pressure loss in node i";
  Real khi[N] "Hydraulic pressure loss coefficient in node i";
  Real lambda[N](start=fill(0.03, N), nominal=fill(0.03, N)) "Friction pressure loss coefficient in node i";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro1[N - 1] annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proc[2] annotation(Placement(transformation(x=70.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro2[N] annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat[N - 1] annotation(Placement(transformation(x=-10.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat[N - 1] annotation(Placement(transformation(x=30.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Line(color={0,0,255}, points={{-60,20},{-60,-20}}),Line(color={0,0,255}, points={{-20,20},{-20,-20}}),Line(color={0,0,255}, points={{20,20},{20,-20}}),Line(color={0,0,255}, points={{60,20},{60,-20}}),Line(color={0,0,255}, points={{-60,20},{-60,-20}}),Line(color={0,0,255}, points={{-20,20},{-20,-20}}),Line(color={0,0,255}, points={{20,20},{20,-20}}),Line(color={0,0,255}, points={{60,20},{60,-20}}),Rectangle(lineColor={0,0,255}, extent={{-100,20},{100,-20}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Line(color={0,0,255}, points={{60,20},{60,-20}}),Line(color={0,0,255}, points={{20,20},{20,-20}}),Line(color={0,0,255}, points={{-20,20},{-20,-20}}),Line(color={0,0,255}, points={{-60,20},{-60,-20}})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,20},{100,-20}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Line(color={0,0,255}, points={{-60,20},{-60,-20}}),Line(color={0,0,255}, points={{-20,20},{-20,-20}}),Line(color={0,0,255}, points={{20,20},{20,-20}}),Line(color={0,0,255}, points={{60,20},{60,-20}})}), Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
", revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Daniel Bouskela</li>
</ul>
</html>
"));
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort CTh[Ns] annotation(Placement(transformation(x=0.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Modelica.SIunits.Acceleration g=Modelica.Constants.g_n "Gravity constant";
  constant Real pi=Modelica.Constants.pi "pi";
  parameter Real eps=1.0 "Small number for pressure loss equation";
  parameter Modelica.SIunits.MassFlowRate Qeps=0.001 "Small mass flow rate for continuous flow reversal";
  parameter Integer N=Ns + 1 "Number of hydraulic nodes (= number of thermal nodes + 1)";
  parameter Modelica.SIunits.Area A=ntubes*pi*D^2/4 "Internal cross sectional pipe area";
  parameter Modelica.SIunits.Diameter Di=ntubes*D "Internal pipe diameter";
  parameter Modelica.SIunits.PathLength dx1=L/(N - 1) "Length of a thermal node";
  parameter Modelica.SIunits.PathLength dx2=L/N "Length of a hydraulic node";
  parameter Modelica.SIunits.Area dSi=pi*Di*dx1 "Internal heat exchange area for a node";
initial equation
  if steady_state then
    for i in 2:N loop
      der(h[i])=0;
    end for;
  else
    Tp=T0;
    if option_temperature == 1 then
      for i in 2:N loop
        h[i]=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(P[i], T0[i - 1], mode);
      end for;
    elseif option_temperature == 2 then
      for i in 2:N loop
        h[i]=h0[i - 1];
      end for;
    else
      assert(false, "DynamicOnePhaseFlowPipe: incorrect option");
    end if;
  end if;
  if dynamic_mass_balance then
    for i in 2:N loop
      der(P[i])=0;
    end for;
  end if;
  if inertia then
    if dynamic_mass_balance then
      for i in 1:N loop
        der(Q[i])=0;
      end for;
    else
      der(Q[1])=0;
    end if;
  end if;
equation
  Tp=CTh.T;
  CTh.W=dW1;
  P[1]=C1.P;
  P[N + 1]=C2.P;
  Q[1]=C1.Q;
  Q[N]=C2.Q;
  hb[1]=C1.h;
  hb[N]=C2.h;
  h[1]=C1.h_vol;
  h[N + 1]=C2.h_vol;
  for i in 1:N - 1 loop
    if dynamic_mass_balance then
      A*(pro1[i].ddph*der(P[i + 1]) + pro1[i].ddhp*der(h[i + 1]))*dx1=Q[i] - Q[i + 1];
    else
      0=Q[i] - Q[i + 1];
    end if;
    if dynamic_energy_balance then
      if simplified_dynamic_energy_balance then
        A*(-der(P[i + 1]) + rho1[i]*der(h[i + 1]))*dx1=hb[i]*Q[i] - hb[i + 1]*Q[i + 1] + dW1[i];
      else
        A*((h[i + 1]*pro1[i].ddph - 1)*der(P[i + 1]) + (h[i + 1]*pro1[i].ddhp + rho1[i])*der(h[i + 1]))*dx1=hb[i]*Q[i] - hb[i + 1]*Q[i + 1] + dW1[i];
      end if;
    else
      A*rho1[i]*der(h[i + 1])*dx1=hb[i]*Q[i] - hb[i + 1]*Q[i + 1] + dW1[i];
    end if;
    dW1[i]=hc[i]*dSi*(Tp[i] - T1[i]);
    pro1[i]=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P[i + 1], h[i + 1], mode);
    rho1[i]=pro1[i].d;
    T1[i]=pro1[i].T;
    (lsat[i],vsat[i])=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P[i + 1]);
    cp[i]=pro1[i].cp;
    mu1[i]=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rho1[i], T1[i]);
    k[i]=noEvent(ThermoSysPro.Properties.WaterSteam.IF97.ThermalConductivity_rhoT(rho1[i], T1[i], P[i + 1]));
    hc[i]=noEvent(if Re1[i] > 1e-06 and Pr[i] > 1e-06 then 0.023*k[i]/D*Re1[i]^0.8*Pr[i]^0.4 else 0);
    Pr[i]=mu1[i]*cp[i]/k[i];
    Re1[i]=noEvent(abs(4*(Q[i] + Q[i + 1])/2/(pi*Di*mu1[i])));
  end for;
  for i in 1:N loop
    if continuous_flow_reversal then
      0=noEvent(if Q[i] > Qeps then hb[i] - h[i] else if Q[i] < -Qeps then hb[i] - h[i + 1] else hb[i] - 0.5*((h[i] - h[i + 1])*Modelica.Math.sin(pi*Q[i]/2/Qeps) + h[i + 1] + h[i]));
    else
      0=if Q[i] > 0 then hb[i] - h[i] else hb[i] - h[i + 1];
    end if;
    if inertia then
      1/A*der(Q[i])*dx2=P[i] - P[i + 1] - dpf[i] - dpg[i] - dpa[i];
    else
      P[i] - P[i + 1] - dpf[i] - dpg[i] - dpa[i]=0;
    end if;
    if advection then
      dpa[i]=noEvent(Q[i]*abs(Q[i])*(1/rhoc[i + 1] - 1/rhoc[i])/A^2);
    else
      dpa[i]=0;
    end if;
    dpg[i]=rho2[i]*g*(z2 - z1)*dx2/L;
    dpf[i]=noEvent(khi[i]*Q[i]*abs(Q[i])/(2*A^2*rho2[i]));
    khi[i]=lambda[i]*dx2/D;
    lambda[i]=if noEvent(Re2[i] > 1) then 0.25*Modelica.Math.log10(13/Re2[i] + rugosrel/3.7/D)^(-2) else 0.01;
    Re2[i]=noEvent(abs(4*Q[i]/(pi*Di*mu2[i])));
    pro2[i]=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((P[i] + P[i + 1])/2, hb[i], mode);
    rho2[i]=pro2[i].d;
    T2[i]=pro2[i].T;
    mu2[i]=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rho2[i], T2[i]);
  end for;
  for i in 2:N loop
    rhoc[i]=rho1[i - 1];
  end for;
  proc[1]=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P[1], h[1], mode);
  proc[2]=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P[N + 1], h[N + 1], mode);
  rhoc[1]=proc[1].d;
  rhoc[N + 1]=proc[2].d;
  W1t=sum(dW1);
end DynamicOnePhaseFlowPipe;
