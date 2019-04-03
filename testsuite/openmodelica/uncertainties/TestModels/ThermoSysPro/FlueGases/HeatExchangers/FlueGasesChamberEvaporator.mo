within ThermoSysPro.FlueGases.HeatExchangers;
model FlueGasesChamberEvaporator "Flue gases chamber  for water evaporation"
  parameter Modelica.SIunits.Area Se=400 "Heat exchange surface on the flue gases side";
  parameter Modelica.SIunits.Length rugosi=1e-05 "Pipe roughness";
  parameter Real rencrf=0.1 "Fouling resistance on the flue gases side (m².K/m)";
  parameter Real rencrc=0.1 "Fouling resistance on the coolant side (m².K/m)";
  parameter Real FVN=0 "Ashes volume fraction";
  parameter Modelica.SIunits.Height haut=15 "Flux wall height";
  parameter Real alpha=1 "Chamber width/depth ratio";
  parameter Modelica.SIunits.Diameter dtex=0.06 "Pipe external diameter";
  parameter Modelica.SIunits.Diameter dtin=0.05 "Pipe internal diameter";
  parameter Modelica.SIunits.Length lailet=0.05 "Membrane length";
  parameter Modelica.SIunits.Length eailet=0.001 "Membrane thickness";
  parameter Modelica.SIunits.Length ebeton=0.01 "Concrete thickness";
  parameter Modelica.SIunits.ThermalConductivity condt=10 "Pipes thermal conductivity";
  parameter Modelica.SIunits.ThermalConductivity condm=10 "Membrane thermal conductivity";
  parameter Modelica.SIunits.ThermalConductivity condb=10 "Concret thermal conductivity";
  parameter Real emimur=0.1 "Walls emissitivity";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer hi=10000 "Coolant heat exchange coefficient";
  ThermoSysPro.Units.AbsoluteTemperature Tef(start=800) "Flue gases temperature at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsf(start=800) "Flue gases temperature at the outlet";
  ThermoSysPro.Units.AbsolutePressure Pef(start=100000.0) "Flue gases pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Psf(start=100000.0) "Flue gases pressure at the outlet";
  Modelica.SIunits.MassFlowRate Qf(start=10) "Flue gases mass flow rate";
  Real XfCO2(start=0.1) "CO2 mass fraction";
  Real XfH2O(start=0.1) "H2O mass fraction";
  Real XfO2(start=0.1) "O2 mass fraction";
  Real XfN2(start=0.1) "N2 mass fraction";
  Real XfSO2(start=0.6) "SO2 mass fraction";
  Modelica.SIunits.Power Wer(start=1000000.0) "Radiation power received";
  Modelica.SIunits.Power Wech(start=1000000.0) "Power exchanged";
  ThermoSysPro.Units.AbsoluteTemperature Ts(start=600) "Average surface temperature on the flue gases side";
  ThermoSysPro.Units.AbsoluteTemperature Tpet(start=600) "Average external fin wall temperature";
  ThermoSysPro.Units.AbsolutePressure Pec0(start=100000.0) "Coolant pressure";
  ThermoSysPro.Units.AbsolutePressure Pec(start=100000.0) "Coolant pressure";
  Modelica.SIunits.Angle anglb(start=1.5) "Angle of the junction between the pipe and the membrane";
  Modelica.SIunits.Angle angla(start=1.5) "Angle of the pipe exposed to the flue gases";
  Real rtube(start=100) "Number of coressponding pipes";
  Modelica.SIunits.Length long(start=100) "Chamber length";
  Modelica.SIunits.Length prof(start=10) "Chamber depth";
  ThermoSysPro.Units.AbsoluteTemperature Tc(start=800) "Coolant saturation temperature";
  ThermoSysPro.Units.AbsolutePressure Pmf(start=100000.0) "Flue gases average pressure";
  ThermoSysPro.Units.AbsoluteTemperature Tmf(start=800) "Flue gases average temperature";
  Real Xcor(start=0.1) "Corrective coefficient for the flue gases mass fractions";
  Real XfH2O0(start=0.1) "H2O corrected mass fraction";
  Real XfCO20(start=0.1) "CO2 corrected mass fraction";
  Real XfO20(start=0.1) "O2 corrected mass fraction";
  Real XfSO20(start=0.1) "SO2 corrected mass fraction";
  Real XfN20(start=0.1) "N2 corrected mass fraction";
  constant ThermoSysPro.Units.AbsolutePressure Pnorm=101325.0 "Normal pressure";
  constant ThermoSysPro.Units.AbsoluteTemperature Tnorm=273.15 "Normal temperature";
  Modelica.SIunits.Density rhonorm(start=100) "Flue gases density at (Pnorm,Tnorm)";
  Modelica.SIunits.ThermalConductivity condf(start=100) "Flue gases thermal conductivity";
  Modelica.SIunits.SpecificHeatCapacity cpf(start=1000) "Flue gases specific heat capacity";
  Modelica.SIunits.DynamicViscosity muf(start=1e-05) "Flue gases dynamic viscosity";
  Modelica.SIunits.Density rhof(start=100) "Flue gases density";
  Real fvd(start=0.5) "Ashes volume fraction";
  Modelica.SIunits.Area Surf(start=50) "Flue gases cross-sectional area";
  Modelica.SIunits.Length Perim(start=50) "Chamber perimeter";
  Modelica.SIunits.Diameter Dh(start=50) "Chamber hydraulic diameter";
  Real Ref(start=10000) "Reynolds number";
  Real Prf(start=1) "Prandtl number";
  Modelica.SIunits.CoefficientOfHeatTransfer hc(start=1) "Convection heat exchange coefficient";
  Modelica.SIunits.CoefficientOfHeatTransfer hr(start=50) "Radiation heat exchange coefficient";
  Modelica.SIunits.CoefficientOfHeatTransfer hf(start=50) "Global heat exchange coefficient";
  Modelica.SIunits.Volume volumg(start=500) "Gas volume";
  Modelica.SIunits.Area senveng(start=500) "Gas envelope surface";
  Modelica.SIunits.Length rop(start=5) "Average optical radius between the pipes";
  Real Masmol(start=0.1) "Mixture molar mass";
  ThermoSysPro.Units.AbsolutePressure PCO2R(start=50000.0) "CO2 partial pressure";
  ThermoSysPro.Units.AbsolutePressure PH2OR(start=50000.0) "H2O partial pressure";
  Real EG(start=0.5);
  Real ES(start=0.5);
  Real emigaz(start=0.5) "Gases emissivity";
  Real emigaz0(start=0.5) "Gases emissivity";
  Real rugos(start=1e-06) "Pipe roughness on the flue gases side";
  Real kfrot(start=0.05) "Pressure losses friction coefficient";
  ThermoSysPro.Units.DifferentialPressure dpd(start=1000) "Dynamical pressure losses";
  ThermoSysPro.Units.DifferentialPressure dps(start=1000) "Static pressure losses";
  ThermoSysPro.Units.DifferentialPressure Pdf(start=1000) "Total pressure losses";
  Real R1(start=0.1) "Thermal resistance";
  Real R2(start=0.1) "Thermal resistance";
  Real R3(start=0.1) "Thermal resistance";
  Real R4(start=0.1) "Thermal resistance";
  Real R5(start=0.1) "Thermal resistance";
  Real R6(start=0.1) "Thermal resistance";
  Real R7(start=0.1) "Thermal resistance";
  Real R8(start=0.1) "Thermal resistance";
  Real R9(start=0.1) "Thermal resistance";
  Real R10(start=0.1) "Thermal resistance";
  Real R789(start=0.1) "Thermal resistance";
  Real R01(start=0.1) "Fouling resistance";
  Real R02(start=0.1) "Fouling resistance";
  Real R03(start=0.1) "Fouling resistance";
  Real R04(start=0.1) "Fouling resistance";
  Real R05(start=0.1) "Fouling resistancet";
  Real Rb1(start=0.1) "Concrete surface thermal resistance";
  Real Rb2(start=0.1) "Concrete surface thermal resistance";
  Real Rt(start=0.1) "Total surface thermal resistance (K/W)";
  Real U(start=50) "Global heat exchange coefficient per external surface unit (W/m²/K)";
  Modelica.SIunits.Area Set(start=500) "Total external surface";
  Modelica.SIunits.Velocity vit(start=1) "Gases veolicity";
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet C1 annotation(Placement(transformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet C2 annotation(Placement(transformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.InputReal IPressure "Water/steam pressure" annotation(Placement(transformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0), iconTransformation(x=0.0, y=110.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false, rotation=90.0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort CTh annotation(Placement(transformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  Modelica.SIunits.ThermalConductivity c1(start=0.1) "Variable for the computation of the flue gases thermal conductivity";
  Modelica.SIunits.ThermalConductivity c2(start=0.1) "Variable for the computation of the flue gases thermal conductivity";
  Real bb(start=1e-06) "Variable for the computation of the friction coefficient";
equation
  Qf=C1.Q;
  Pef=C1.P;
  Tef=C1.T;
  XfCO2=C1.Xco2;
  XfH2O=C1.Xh2o;
  XfO2=C1.Xo2;
  XfN2=1 - XfCO2 - XfH2O - XfO2 - XfSO2;
  XfSO2=C1.Xso2;
  Qf=C2.Q;
  Psf=C2.P;
  Tsf=C2.T;
  XfCO2=C2.Xco2;
  XfH2O=C2.Xh2o;
  XfO2=C2.Xo2;
  XfSO2=C2.Xso2;
  Wer=CTh.W;
  CTh.T=Tsf;
  Pec0=IPressure.signal;
  0=if Pec0 >= 0 then Pec - Pec0 else Pec - 1000000.0;
  anglb=2*Modelica.Math.asin(eailet/dtex);
  angla=(Modelica.Constants.pi - anglb)/2;
  rtube=Se/haut/(angla*dtex + lailet);
  long=alpha/(1 + alpha)*rtube*(dtex + lailet)/2;
  prof=1/(1 + alpha)*rtube*(dtex + lailet)/2;
  Tc=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(Pec);
  Pmf=0.5*(Pef + Psf);
  Tmf=0.5*(Tef + Tsf);
  Xcor=1/(1 - XfH2O);
  XfH2O0=0;
  XfCO20=XfCO2*Xcor;
  XfO20=XfO2*Xcor;
  XfSO20=XfSO2*Xcor;
  XfN20=1 - (XfCO20 + XfO20 + XfSO20);
  rhonorm=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pnorm, Tnorm, XfCO20, XfH2O0, XfO20, XfSO20);
  if Tmf > 973.15 then
    c1=ThermoSysPro.Properties.FlueGases.FlueGases_k(Pmf, 923.15, XfCO2, XfH2O, XfO2, XfSO2);
    c2=ThermoSysPro.Properties.FlueGases.FlueGases_k(Pmf, 973.15, XfCO2, XfH2O, XfO2, XfSO2);
    condf=(Tmf - 973.15)*(c2 - c1)/50 + c2;
  else
    c1=0;
    c2=0;
    condf=ThermoSysPro.Properties.FlueGases.FlueGases_k(Pmf, Tmf, XfCO2, XfH2O, XfO2, XfSO2);
  end if;
  cpf=ThermoSysPro.Properties.FlueGases.FlueGases_cp(Pmf, Tmf, XfCO2, XfH2O, XfO2, XfSO2);
  muf=ThermoSysPro.Properties.FlueGases.FlueGases_mu(Pmf, Tmf, XfCO2, XfH2O, XfO2, XfSO2);
  rhof=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pmf, Tmf, XfCO2, XfH2O, XfO2, XfSO2);
  fvd=FVN*rhof/rhonorm;
  Surf=prof*long;
  Perim=2*(long + prof);
  Dh=4*Surf/Perim;
  Ref=Qf/Surf*Dh/muf;
  Prf=muf*cpf/condf;
  hc=0.023*Ref^0.8*Prf^0.4*condf/Dh;
  volumg=Dh*long*prof;
  senveng=2*Dh*long + 2*Dh*prof + 2*long*prof;
  rop=3.6*volumg/senveng;
  Masmol=XfCO2/44 + XfO2/32 + XfSO2/64 + XfH2O/18 + XfN2/28;
  PCO2R=XfCO2/44/Masmol*Pef;
  PH2OR=XfH2O/18/Masmol*Pef;
  (EG,ES,emigaz0)=ThermoSysPro.Properties.FlueGases.FlueGases_Absorb(PCO2R, PH2OR, fvd, rop, Tmf);
  if emigaz0 < 0.0001 then
    emigaz=0.0001;
  elseif emigaz0 > 1 then
    emigaz=0.99;
  else
    emigaz=emigaz0;
  end if;
  hr=5.68e-08/(1/emigaz + (1 - emimur)/emimur)*(Tmf^2 + Ts^2)*(Tmf + Ts);
  hf=hc + hr;
  rugos=0.00015;
  if Ref < 2000 then
    bb=0;
    kfrot=64/Ref;
  else
    bb=13/Ref + rugos/3.7/Dh;
    kfrot=0.25*Modelica.Math.log10(bb)^(-2);
  end if;
  dpd=kfrot*haut*Qf^2/(2*Surf^2*Dh*rhof);
  dps=rhof*Modelica.Constants.g_n*haut;
  Pdf=dpd + dps;
  if hf <= 0 then
    R1=0;
    R4=0;
    Rb1=0;
  else
    R1=1/(hf*angla*dtex/2*haut);
    R4=1/(hf*lailet/2*haut);
    Rb1=1/(hf*(lailet + dtex)/2*haut);
  end if;
  R3=1/(hi*angla*dtin/2*haut);
  R8=1/(hi*anglb*dtin/2*haut);
  R9=R3;
  R2=Modelica.Math.log(dtex/dtin)/(condt*angla*haut);
  R5=lailet/4/(eailet*condm*haut);
  R6=Modelica.Math.log(dtex/(dtin + (dtex - dtin)/2))/(condt*anglb*haut);
  R7=Modelica.Math.log((dtin + (dtex - dtin)/2)/dtin)/(condt*anglb*haut);
  R10=angla/4*(dtin + dtex)/(dtex - dtin)/(condt*haut);
  Rb2=ebeton/(condb*(lailet + dtex)/2*haut);
  R01=rencrc/(angla*dtin/2*haut);
  R02=rencrc/(anglb*dtin/2*haut);
  R03=rencrf/(angla*dtex/2*haut);
  R04=rencrf/(lailet/2*haut);
  R05=rencrf/((angla*dtex/2 + lailet/2)*haut);
  R789=1/(1/(R7 + R8 + R02) + 1/(R9 + R10 + R01));
  if ebeton <= 0 then
    Rt=1/(1/(R1 + R03 + R2 + R3 + R01) + 1/(R4 + R04 + R5 + R6 + R789));
    U=1/((angla*dtex/2 + lailet/2)*haut*Rt);
    Se=rtube*(angla*dtex + lailet)*haut;
  else
    Rt=1/(1/(R3 + R2 + R01) + 1/(R5 + R6 + R789)) + Rb1 + Rb2 + R05;
    U=1/((lailet + dtex)/2*haut*Rt);
    Set=rtube*(dtex + lailet)*haut;
  end if;
  vit=Qf/(long*prof*rhof);
  Tsf=Tef - (Wech - Wer)/(Qf*cpf);
  U*Set*(Tsf - Tef)/Modelica.Math.log((Tsf - Tc)/(Tef - Tc))=Wech - Wer;
  Ts=Tmf - (Wech - Wer)/hf/Set;
  Tpet=Ts - (Wech - Wer)*rencrf/Set;
  Psf + Pdf=Pef;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,100},{80,-100}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Rectangle(extent={{-80,100},{-74,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255}),Rectangle(extent={{-44,100},{-36,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255}),Rectangle(extent={{36,100},{44,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255}),Rectangle(extent={{-4,100},{4,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255}),Rectangle(extent={{74,100},{80,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,100},{80,-100}}, lineColor={0,0,255}, fillColor={255,255,0}, fillPattern=FillPattern.Backward),Rectangle(extent={{-80,100},{-74,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255}),Rectangle(extent={{-44,100},{-36,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255}),Rectangle(extent={{36,100},{44,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255}),Rectangle(extent={{-4,100},{4,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255}),Rectangle(extent={{74,100},{80,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,255,255}),Text(lineColor={0,0,255}, extent={{-2,118},{34,94}}, fillColor={0,0,255}, textString="P")}), Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
<li>
    Benoît Bride</li></ul>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end FlueGasesChamberEvaporator;
