within ThermoSysPro.WaterSteam.HeatExchangers;
model DynamicTwoPhaseFlowPipe "Dynamic two-phase flow pipe"
  parameter Modelica.SIunits.Length L=10.0 "Pipe length";
  parameter Modelica.SIunits.Diameter D=0.2 "Internal pipe diameter";
  parameter Modelica.SIunits.Length rugosrel=0.0007 "Pipe relative roughness";
  parameter Integer ntubes=1 "Number of pipes in parallel";
  parameter Modelica.SIunits.Position z1=0 "Pipe inlet altitude";
  parameter Modelica.SIunits.Position z2=0 "Pipe outlet altitude";
  parameter Real rgliss=1 "Phase slip coefficient";
  parameter Integer a=4200 "Phase pressure loss coefficient";
  parameter Integer Ns=10 "Number of segments";
  parameter ThermoSysPro.Units.AbsoluteTemperature T0[Ns]=fill(300, Ns) "Initial fluid temperature (active if steady_state = false and option_temperature = 1)" annotation(Evaluate=false);
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
  ThermoSysPro.Units.AbsolutePressure Pb[N + 1](start=fill(100000.0, N + 1), nominal=fill(100000.0, N + 1)) "Bounded fluid pressure in node i";
  Modelica.SIunits.Density rho1[N - 1](start=fill(998, N - 1), nominal=fill(1, N - 1)) "Fluid density in thermal node i";
  Modelica.SIunits.Density rho2[N](start=fill(998, N), nominal=fill(1, N)) "Fluid density in hydraulic node i";
  Modelica.SIunits.Density rhoc[N + 1](start=fill(998, N + 1), nominal=fill(1, N + 1)) "Fluid density at the boudary of node i";
  Modelica.SIunits.Power dW1[N - 1](start=fill(300000.0, N - 1), nominal=fill(300000.0, N - 1)) "Thermal power exchanged on the liquid side for node i";
  Modelica.SIunits.Power W1t "Total power exchanged on the liquid side";
  ThermoSysPro.Units.AbsoluteTemperature Tp1[N - 1](each start=500.0) "Wall temperature in node i";
  Modelica.SIunits.CoefficientOfHeatTransfer hi[N - 1](start=fill(2000, N - 1), nominal=fill(20000.0, N - 1)) "Fluid heat exchange coefficient in node i";
  Modelica.SIunits.CoefficientOfHeatTransfer hcl[N - 1](start=fill(2000, N - 1), nominal=fill(200, N - 1)) "Fluid heat exchange coefficient in node i for the liquid fraction";
  Modelica.SIunits.CoefficientOfHeatTransfer hcv[N - 1](start=fill(0, N - 1), nominal=fill(200, N - 1)) "Fluid heat exchange coefficient in node i for the vapor fraction";
  Real S[N - 1] "Corrective terme correctif for nucleation removal";
  Real E[N - 1] "Corrective term for hcl";
  Modelica.SIunits.CoefficientOfHeatTransfer heb[N - 1](start=fill(0, N - 1), nominal=fill(500000.0, N - 1)) "Fluid heat exchange coefficient for vaporization in thermal node i";
  Modelica.SIunits.ReynoldsNumber Rel1[N - 1](start=fill(60000.0, N - 1), nominal=fill(5000.0, N - 1)) "Reynolds number in thermal node i for the liquid";
  Modelica.SIunits.ReynoldsNumber Rel2[N](start=fill(60000.0, N), nominal=fill(5000.0, N)) "Reynolds number in hydraulic node i for the liquid";
  Modelica.SIunits.ReynoldsNumber Rev1[N - 1](start=fill(1000.0, N - 1), nominal=fill(500000.0, N - 1)) "Reynolds number in thermal node i for the vapor";
  Modelica.SIunits.ReynoldsNumber Rev2[N](start=fill(1000.0, N), nominal=fill(500000.0, N)) "Reynolds number in hydraulic node i for the vapor";
  Real Prl[N - 1](start=fill(4, N - 1), nominal=fill(1, N - 1)) "Fluid Prandtl number in node i for the liquid";
  Real Prv[N - 1](start=fill(1, N - 1), nominal=fill(1, N - 1)) "Fluid Prandtl number in node i for the vapor";
  Modelica.SIunits.ThermalConductivity kl[N - 1](start=fill(0.6, N - 1), nominal=fill(0.6, N - 1)) "Thermal conductivity in node i for the liquid";
  Modelica.SIunits.ThermalConductivity kv[N - 1](start=fill(0.03, N - 1), nominal=fill(0.03, N - 1)) "Thermal conductivity in node i for the vapor";
  Real xv1[N - 1] "Vapor mass fraction in thermal node i";
  Real xv2[N] "Vapor mass fraction in hydraulic node i";
  Real xbs[N - 1] "Bounded upper value for the vapor mass fraction";
  Real xbi[N - 1] "Bounded lower value for the vapor mass fraction";
  Modelica.SIunits.DynamicViscosity mul1[N - 1](start=fill(0.0002, N - 1), nominal=fill(0.0002, N - 1)) "Dynamic viscosity in thermal node i for the liquid";
  Modelica.SIunits.DynamicViscosity mul2[N](start=fill(0.0002, N), nominal=fill(0.0002, N)) "Dynamic viscosity in hydraulic node i for the liquid";
  Modelica.SIunits.DynamicViscosity muv1[N - 1](start=fill(1e-05, N - 1), nominal=fill(0.0001, N - 1)) "Dynamic viscosity in thermal node i for the vapor";
  Modelica.SIunits.DynamicViscosity muv2[N](start=fill(1e-05, N), nominal=fill(0.0001, N)) "Dynamic viscosity in hydraulic node i for the vapor";
  Modelica.SIunits.SpecificHeatCapacity cpl[N - 1](start=fill(4000, N - 1), nominal=fill(4000, N - 1)) "Specific heat capacity for the liquid";
  Modelica.SIunits.SpecificHeatCapacity cpv[N - 1](start=fill(2000, N - 1), nominal=fill(2000, N - 1)) "Specific heat capacity for the vapor";
  Real Bo[N - 1](start=fill(0, N - 1), nominal=fill(0.0004, N - 1)) "Boiling number";
  Real Xtt[N - 1](start=fill(1, N - 1), nominal=fill(1, N - 1)) "Martinelli number";
  ThermoSysPro.Units.SpecificEnthalpy lv[N - 1](start=fill(2000000.0, N - 1), nominal=fill(2000000.0, N - 1)) "Specific enthalpy for vaporisation";
  Modelica.SIunits.Density rhol1[N - 1](start=fill(998, N - 1), nominal=fill(998, N - 1)) "Fluid density in thermal node i for the liquid";
  Modelica.SIunits.Density rhol2[N](start=fill(998, N), nominal=fill(998, N)) "Fluid density in hydraulic node i for the liquid";
  Modelica.SIunits.Density rhov1[N - 1](start=fill(1, N - 1), nominal=fill(1, N - 1)) "Fluid density in thermal node i for the vapor";
  Modelica.SIunits.Density rhov2[N](start=fill(1, N), nominal=fill(1, N)) "Fluid density in hydraulic node i for the vapor";
  ThermoSysPro.Units.AbsoluteTemperature T1[N - 1] "Fluid temperature in thermal node i";
  ThermoSysPro.Units.AbsoluteTemperature T2[N] "Fluid temperature in hydraulic node i";
  ThermoSysPro.Units.DifferentialPressure dpa[N] "Advection term for the mass balance equation in node i";
  ThermoSysPro.Units.DifferentialPressure dpf[N] "Friction pressure loss in node i";
  ThermoSysPro.Units.DifferentialPressure dpg[N] "Gravity pressure loss in node i";
  Real khi[N] "Hydraulic pressure loss coefficient in node i";
  Real lambdal[N](start=fill(0.03, N), nominal=fill(0.03, N)) "Friction pressure loss coefficient in node i for the liquid";
  Real lambdav[N](start=fill(0.03, N), nominal=fill(0.03, N)) "Friction pressure loss coefficient in node i for the vapor)";
  Real filo[N] "Pressure loss coefficient for two-phase flow";
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro1[N - 1] annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph proc[2] annotation(Placement(transformation(x=-10.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro2[N] annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat2[N] annotation(Placement(transformation(x=90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat2[N] annotation(Placement(transformation(x=50.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat1[N - 1] annotation(Placement(transformation(x=-50.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat1[N - 1] annotation(Placement(transformation(x=-90.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInlet C1 annotation(Placement(transformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Thermal.Connectors.ThermalPort CTh[Ns] annotation(Placement(transformation(x=0.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=30.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutlet C2 annotation(Placement(transformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
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
  parameter Real Mmol=18.015 "Water molar mass";
  parameter ThermoSysPro.Units.AbsolutePressure pcrit=ThermoSysPro.Properties.WaterSteam.BaseIF97.data.PCRIT "Critical pressure";
  parameter ThermoSysPro.Units.AbsolutePressure ptriple=ThermoSysPro.Properties.WaterSteam.BaseIF97.triple.ptriple "Triple point pressure";
  parameter Real xb1=0.0002 "Min value for vapor mass fraction";
  parameter Real xb2=0.85 "Max value for vapor mass fraction";
initial equation
  if steady_state then
    for i in 2:N loop
      der(h[i])=0;
    end for;
  else
    if option_temperature == 1 then
      for i in 2:N loop
        h[i]=ThermoSysPro.Properties.WaterSteam.IF97.SpecificEnthalpy_PT(Pb[i], T0[i - 1], mode);
      end for;
    elseif option_temperature == 2 then
      for i in 2:N loop
        h[i]=h0[i - 1];
      end for;
    else
      assert(false, "DynamicTwoPhaseFlowPipe: incorrect option");
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
  Tp1=CTh.T;
  CTh.W=dW1;
  P[1]=C1.P;
  P[N + 1]=C2.P;
  Q[1]=C1.Q;
  Q[N]=C2.Q;
  hb[1]=C1.h;
  hb[N]=C2.h;
  h[1]=C1.h_vol;
  h[N + 1]=C2.h_vol;
  Pb[1]=max(min(P[1], pcrit - 1), ptriple);
  Pb[N + 1]=max(min(P[N + 1], pcrit - 1), ptriple);
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
    dW1[i]=hi[i]*dSi*(Tp1[i] - T1[i]);
    if xv1[i] < xb1 then
      hi[i]=(1 - xv1[i]/xb1)*hcl[i] + xv1[i]/xb1*(E[i]*hcl[i] + S[i]*heb[i]);
      Xtt[i]=((1 - xb1)/xb1)^0.9*(rhov1[i]/rhol1[i])^0.5*(mul1[i]/muv1[i])^0.1;
    elseif xv1[i] > xb2 then
      hi[i]=(xv1[i] - xb2)/(1 - xb2)*hcv[i] + (1 - xv1[i])/(1 - xb2)*(E[i]*hcl[i] + S[i]*heb[i]);
      Xtt[i]=((1 - xb2)/xb2)^0.9*(rhov1[i]/rhol1[i])^0.5*(mul1[i]/muv1[i])^0.1;
    else
      hi[i]=E[i]*hcl[i] + S[i]*heb[i];
      Xtt[i]=((1 - xv1[i])/xv1[i])^0.9*(rhov1[i]/rhol1[i])^0.5*(mul1[i]/muv1[i])^0.1;
    end if;
    E[i]=1 + 24000*Bo[i]^1.16 + 1.37*Xtt[i]^(-0.86);
    Bo[i]=noEvent(if abs((Q[i] + Q[i + 1])/2) > 0.001 then abs(dW1[i]*D/(4*(Q[i] + Q[i + 1])/2*lv[i]*dx1)) else 1e-05);
    S[i]=noEvent(if Rel1[i] > 1e-06 then 1/(1 + 1.15e-06*E[i]^2*Rel1[i]^1.17) else 0);
    heb[i]=noEvent(if Pb[i] > 1 then 55*(abs(Pb[i])/pcrit)^0.12*(-Modelica.Math.log10(abs(Pb[i])/pcrit))^(-0.55)*Mmol^(-0.5)*(abs(dW1[i])/dSi)^0.67 else 100);
    hcl[i]=noEvent(if Rel1[i] > 1e-06 and Prl[i] > 1e-06 then 0.023*kl[i]/D*Rel1[i]^0.8*Prl[i]^0.4 else 0);
    hcv[i]=noEvent(if Rev1[i] > 1e-06 and Prv[i] > 1e-06 then 0.023*kv[i]/D*Rev1[i]^0.8*Prv[i]^0.4 else 0);
    Prl[i]=mul1[i]*cpl[i]/kl[i];
    Prv[i]=muv1[i]*cpv[i]/kv[i];
    Rel1[i]=noEvent(abs(4*(Q[i] + Q[i + 1])/2*(1 - xbs[i])/(pi*Di*mul1[i])));
    Rev1[i]=noEvent(abs(4*(Q[i] + Q[i + 1])/2*xbi[i]/(pi*Di*muv1[i])));
    pro1[i]=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P[i + 1], h[i + 1]);
    rho1[i]=pro1[i].d;
    T1[i]=pro1[i].T;
    xv1[i]=pro1[i].x;
    xbs[i]=min(pro1[i].x, 0.9);
    xbi[i]=max(pro1[i].x, 0.1);
    (lsat1[i],vsat1[i])=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P[i + 1]);
    rhol1[i]=max(pro1[i].d, lsat1[i].rho);
    rhov1[i]=min(pro1[i].d, vsat1[i].rho);
    cpl[i]=if noEvent(xv1[i] <= 0.0) then pro1[i].cp else lsat1[i].cp;
    cpv[i]=if noEvent(xv1[i] >= 1.0) then pro1[i].cp else vsat1[i].cp;
    mul1[i]=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rhol1[i], T1[i]);
    muv1[i]=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rhov1[i], T1[i]);
    kl[i]=ThermoSysPro.Properties.WaterSteam.IF97.ThermalConductivity_rhoT(rhol1[i], T1[i], P[i + 1]);
    kv[i]=ThermoSysPro.Properties.WaterSteam.IF97.ThermalConductivity_rhoT(rhov1[i], T1[i], P[i + 1]);
    lv[i]=vsat1[i].h - lsat1[i].h;
    Pb[i + 1]=max(min(P[i + 1], pcrit - 1), ptriple);
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
    dpf[i]=noEvent(khi[i]*Q[i]*abs(Q[i])/(2*A^2*rhol2[i]));
    khi[i]=filo[i]*lambdal[i]*dx2/D;
    lambdal[i]=if noEvent(Rel2[i] > 1) then 0.25*Modelica.Math.log10(13/Rel2[i] + rugosrel/3.7/D)^(-2) else 0.01;
    lambdav[i]=if noEvent(Rev2[i] > 1) then 0.25*Modelica.Math.log10(13/Rev2[i] + rugosrel/3.7/D)^(-2) else 0.01;
    Rel2[i]=noEvent(abs(4*Q[i]/(pi*Di*mul2[i])));
    Rev2[i]=noEvent(abs(4*Q[i]/(pi*Di*muv2[i])));
    if noEvent(xv2[i] < 0.8) then
      filo[i]=1 + a*xv2[i]*rgliss/(19 + Pb[i]*1e-05)/exp(Pb[i]*1e-05/84);
    else
      filo[i]=(1 - xv2[i]*rgliss)/0.2*(1 + a*xv2[i]*rgliss/(19 + Pb[i]*1e-05)/exp(Pb[i]*1e-05/84)) + (xv2[i]*rgliss - 0.8)/0.2*rhol2[i]/rhov2[i]*lambdav[i]/lambdal[i];
    end if;
    pro2[i]=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((P[i] + P[i + 1])/2, hb[i]);
    rho2[i]=pro2[i].d;
    xv2[i]=pro2[i].x;
    T2[i]=pro2[i].T;
    (lsat2[i],vsat2[i])=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P((P[i] + P[i + 1])/2);
    rhol2[i]=max(pro2[i].d, lsat2[i].rho);
    rhov2[i]=min(pro2[i].d, vsat2[i].rho);
    mul2[i]=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rhol2[i], T2[i]);
    muv2[i]=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rhov2[i], T2[i]);
  end for;
  for i in 2:N loop
    rhoc[i]=rho1[i - 1];
  end for;
  proc[1]=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P[1], h[1]);
  proc[2]=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(P[N + 1], h[N + 1]);
  rhoc[1]=proc[1].d;
  rhoc[N + 1]=proc[2].d;
  W1t=sum(dW1);
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,0},{100,-20}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Rectangle(lineColor={0,0,255}, extent={{-100,20},{100,0}}, fillPattern=FillPattern.Solid, fillColor={159,223,223}),Line(color={0,0,255}, points={{-60,20},{-60,-20}}),Line(color={0,0,255}, points={{-20,20},{-20,-20}}),Line(color={0,0,255}, points={{20,20},{20,-20}}),Line(color={0,0,255}, points={{60,20},{60,-20}})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(lineColor={0,0,255}, extent={{-100,20},{100,0}}, fillPattern=FillPattern.Solid, fillColor={159,223,223}),Rectangle(lineColor={0,0,255}, extent={{-100,0},{100,-20}}, fillPattern=FillPattern.Solid, fillColor={127,191,255}),Line(color={0,0,255}, points={{-60,20},{-60,-20}}),Line(color={0,0,255}, points={{-20,20},{-20,-20}}),Line(color={0,0,255}, points={{20,20},{20,-20}}),Line(color={0,0,255}, points={{60,20},{60,-20}})}), Documentation(info="<html>
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
<li>
    Baligh El Hefni</li>
<li>
    Guillaume Larrignon</li>
</ul>
</html>
"));
end DynamicTwoPhaseFlowPipe;
