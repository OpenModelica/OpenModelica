within ThermoSysPro.Combustion.CombustionChambers;
model GTCombustionChamber "Gas turbine combustion chamber"
  parameter Real kcham=1 "Pressure loss coefficient in the combustion chamber";
  parameter Modelica.SIunits.Area Acham=1 "Average corss-sectional area of the combusiton chamber";
  parameter Real eta_comb=1 "Combustion efficiency";
  parameter Modelica.SIunits.Power Wpth=1000000.0 "Thermal loss fraction in the body of the combustion chamber";
  parameter Boolean air_atomisation=false "true: computation with air atomisation - false: computation without air atomisation";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tecpat=293 "Temperature at the inlet of the atomisation compressor";
  parameter Real kat=0 "Atomisation pressure loss coefficient";
  parameter Real XQat=0 "Atomisation air mass flow rate coefficient";
  parameter Real Xspat=0 "Atomisation over-pressure coefficient";
  parameter Real eta_is=1 "Atomisation compressor isentropic efficiency";
  Modelica.SIunits.MassFlowRate Qea(start=400) "Air mass flow rate";
  ThermoSysPro.Units.AbsolutePressure Pea(start=100000.0) "Air pressure at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tea(start=600) "Air temperature at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hea(start=50000.0) "Air specific enthalpy at the inlet";
  Real XeaCO2(start=0) "CO2 mass fraction at the air inlet";
  Real XeaH2O(start=0.1) "H2O mass fraction at the air inlet";
  Real XeaO2(start=0.2) "O2 mass fraction at the air inlet";
  Real XeaSO2(start=0) "SO2 mass fraction at the air inlet";
  Modelica.SIunits.MassFlowRate Qfuel(start=5) "Fuel mass flow rate";
  ThermoSysPro.Units.AbsoluteTemperature Tfuel(start=300) "Fuel temperature";
  ThermoSysPro.Units.SpecificEnthalpy Hfuel(start=10000.0) "Fuel specific enthalpy";
  Real XCfuel(start=0.8) "C mass fraction in the fuel";
  Real XHfuel(start=0.2) "H mass fraction in the fuel";
  Real XOfuel(start=0) "O mass fraction in the fuel";
  Real XSfuel(start=0) "S mass fraction in the fuel";
  Modelica.SIunits.SpecificEnergy LHVfuel(start=50000000.0) "Fuel lower heating value";
  Modelica.SIunits.SpecificHeatCapacity Cpfuel(start=1000) "Fuel specific heat capacity";
  Modelica.SIunits.MassFlowRate Qews(start=1) "Water/steam mass flow rate";
  ThermoSysPro.Units.SpecificEnthalpy Hews(start=10000.0) "Water/steam specific enthalpy at the inlet";
  Modelica.SIunits.MassFlowRate Qsf(start=400) "Flue gases mass flow rate";
  ThermoSysPro.Units.AbsolutePressure Psf(start=1200000.0) "Flue gases pressure at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsf(start=1500) "Flue gases temperature at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hsf(start=500000.0) "Flue gases specific enthalpy at the outlet";
  Real XsfCO2(start=0.5) "CO2 mass fraction in the flue gases";
  Real XsfH2O(start=0.1) "H2O mass fraction in the flue gases";
  Real XsfO2(start=0) "O2 mass fraction in the flue gases";
  Real XsfSO2(start=0) "SO2 mass fraction in the flue gases";
  Modelica.SIunits.Power Wfuel(start=500000000.0) "LHV power available in the fuel";
  Real exc(start=1) "Combustion air ratio";
  ThermoSysPro.Units.DifferentialPressure deltaPccb(start=1000.0) "Pressure loss in the combusiton chamber";
  ThermoSysPro.Units.SpecificEnthalpy Hrair(start=10000.0) "Air reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrws(start=100000.0) "Water/steam reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrfuel(start=10000.0) "Fuel reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrfg(start=10000.0) "Flue gases reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hecpat(start=10000.0) "Air specific enthalpy at the inlet of the atomisaiton compressor";
  ThermoSysPro.Units.SpecificEnthalpy Hiscpat(start=10000.0) "Air specific enthalpy after isentropic expansion at the outlet of the atomisaiotn compressor";
  ThermoSysPro.Units.AbsolutePressure Pecpat(start=100000.0) "Pressure at the inlet of the atomisation compressor";
  ThermoSysPro.Units.AbsolutePressure Pscpat(start=100000.0) "Pressure at the inlet of the atomisation compressor";
  Modelica.SIunits.SpecificEntropy Secpat(start=1000.0) "Entropy at the inlet of the atomisation compressor";
  Modelica.SIunits.MassFlowRate Qm(start=400) "Average mlass flow rate in the combustion chamber";
  Real Vea(start=0.001) "Air volume mass (m3/kg)";
  Real Vsf(start=0.001) "Flue gases volume mass (m3/kg)";
  Modelica.SIunits.Density rhoea(start=0.001) "Air density at the inlet";
  Modelica.SIunits.Density rhosf(start=0.001) "Flue gases density at the outlet";
  Real Vccbm(start=0.001) "Average volume mass in the combustion chamber";
  Modelica.SIunits.Velocity v(start=100) "Flue gases reference velocity in the combusiton chamber";
  Modelica.SIunits.Power Wcpat(start=1000.0) "Power of the atomisation compressor";
  Modelica.SIunits.Power Wrfat(start=1000.0) "Thermal power extracted by the atomisaiton refrigerant";
  ThermoSysPro.Combustion.Connectors.FuelInlet Cfuel "Fuel inlet" annotation(Placement(transformation(x=0.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Ca "Air inlet" annotation(Placement(transformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Cfg "Flue gases outlet" annotation(Placement(transformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Cws "Water/steam inlet" annotation(Placement(transformation(x=-60.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-60.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real amC=12.01115 "Carbon atomic mass";
  constant Real amH=1.00797 "Hydrogen atomic mass";
  constant Real amO=15.9994 "Oxygen atomic mass";
  constant Real amS=32.064 "Sulfur atomic mass";
  constant Real eps_a=1e-06 "Zero criterion for a-dimensional numbers";
  constant Real eps_s=1e-06 "Zero criterion for surface numbers";
  Real amCO2 "CO2 molecular mass";
  Real amH2O "H2O molecular mass";
  Real amSO2 "SO2 molecular mass";
  Real eta_isc(start=1) "Intermediate variable for the computation of the isentropic efficiency of the atomisaiton compressor";
  Modelica.SIunits.Area Achamc(start=1) "Intermediate variable for the computation of the average corss-section aera of the combusion chamber";
  Real XeaO2c(start=0.2) "Intermediate variable for the computation of the O2 mass fraction";
equation
  Qea=Ca.Q;
  Pea=Ca.P;
  Tea=Ca.T;
  XeaCO2=Ca.Xco2;
  XeaH2O=Ca.Xh2o;
  XeaO2=Ca.Xo2;
  XeaSO2=Ca.Xso2;
  Qfuel=Cfuel.Q;
  Tfuel=Cfuel.T;
  XCfuel=Cfuel.Xc;
  XHfuel=Cfuel.Xh;
  XOfuel=Cfuel.Xo;
  XSfuel=Cfuel.Xs;
  LHVfuel=Cfuel.LHV;
  Cpfuel=Cfuel.cp;
  Qews=Cws.Q;
  Hews=Cws.h;
  Cws.h=Cws.h_vol;
  Qsf=Cfg.Q;
  Psf=Cfg.P;
  Tsf=Cfg.T;
  XsfCO2=Cfg.Xco2;
  XsfH2O=Cfg.Xh2o;
  XsfO2=Cfg.Xo2;
  XsfSO2=Cfg.Xso2;
  if air_atomisation then
    Hecpat=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pecpat, Tecpat, XeaCO2, XeaH2O, XeaO2c, XeaSO2);
    Secpat=ThermoSysPro.Properties.FlueGases.FlueGases_s(Pecpat, Tecpat, XeaCO2, XeaH2O, XeaO2c, XeaSO2);
    Hiscpat=ThermoSysPro.Properties.FlueGases.FlueGases_h_Ps(Pscpat, Secpat, XeaCO2, XeaH2O, XeaO2c, XeaSO2);
  else
    Hecpat=60000;
    Secpat=-2000;
    Hiscpat=60000;
  end if;
  Hea=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pea, Tea, XeaCO2, XeaH2O, XeaO2c, XeaSO2);
  Hsf=ThermoSysPro.Properties.FlueGases.FlueGases_h(Psf, Tsf, XsfCO2, XsfH2O, XsfO2, XsfSO2);
  rhoea=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pea, Tea, XeaCO2, XeaH2O, XeaO2c, XeaSO2);
  Vea=if rhoea > 0.001 then 1/rhoea else 1/1.1;
  rhosf=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Psf, Tsf, XsfCO2, XsfH2O, XsfO2, XsfSO2);
  Vsf=if rhosf > 0.001 then 1/rhosf else 1/0.1;
  0=if eta_is > eps_a then eta_isc - eta_is else eta_isc - eps_a;
  0=if Acham > eps_s then Achamc - Acham else Achamc - eps_s;
  0=if XeaO2 > eps_a then XeaO2c - XeaO2 else XeaO2c - eps_a;
  amCO2=amC + 2*amO;
  amH2O=2*amH + amO;
  amSO2=amS + 2*amO;
  Qsf=Qea + Qews + Qfuel;
  XsfCO2*(Qea + Qews + Qfuel)=Qea*XeaCO2 + Qfuel*XCfuel*amCO2/amC;
  XsfH2O*(Qea + Qews + Qfuel)=Qews + (Qea*XeaH2O + Qfuel*XHfuel*amH2O/2/amH);
  XsfO2*(Qea + Qews + Qfuel)=Qea*XeaO2c - Qfuel*amO*(2*XCfuel/amC + 0.5*XHfuel/amH + 2*XSfuel/amS) + Qfuel*XOfuel;
  XsfSO2*(Qea + Qews + Qfuel)=Qea*XeaSO2 + Qfuel*XSfuel*amSO2/amS;
  Wfuel=Qfuel*LHVfuel;
  exc=Qea*(1 - XeaH2O)/(Qfuel*amO*(2*XCfuel/amC + 0.5*XHfuel/amH + 2*XSfuel/amS - XOfuel/amO)/(XeaO2c/(1 - XeaH2O)));
  Pea - Psf=deltaPccb;
  Qm=Qea + (Qfuel + Qews)/2;
  Vccbm=(Vea + Vsf)/2;
  v=Qm*Vccbm/Achamc;
  deltaPccb=kcham*v^2/(2*Vccbm);
  Hfuel=Cpfuel*Tfuel;
  if air_atomisation then
    (Qea + Qews + Qfuel)*(Hsf - Hrfg) + Wrfat + Wpth - (Qfuel*(Hfuel - Hrfuel + LHVfuel*eta_comb) + Qea*(Hea - Hrair) + Qews*(Hews - Hrws) + Wcpat)=0;
    Pecpat=Pea*(1 - kat);
    Pscpat=(1 + Xspat)*Pea;
    Wcpat=Qea*XQat*(Hiscpat - Hecpat)/eta_isc;
    Wrfat=Qea*XQat*(Hea - Hecpat);
  else
    (Qea + Qews + Qfuel)*(Hsf - Hrfg) + Wpth - (Qfuel*(Hfuel - Hrfuel + LHVfuel*eta_comb) + Qea*(Hea - Hrair) + Qews*(Hews - Hrws))=0;
    Pecpat=Pea;
    Pscpat=Pea;
    Wcpat=0;
    Wrfat=0;
  end if;
  Hrair=2501569.0*XeaH2O;
  Hrfuel=0;
  Hrws=2501569.0;
  Hrfg=2501569.0*XsfH2O;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,80},{80,-80}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,191,0}),Line(points={{-20,80},{-20,-80}}, color={0,0,255}),Polygon(points={{-20,62},{46,46},{2,30},{58,18},{6,0},{48,-16},{2,-32},{54,-44},{-20,-60},{-20,62}}, lineColor={0,0,0}, fillColor={255,0,0}, fillPattern=FillPattern.CrossDiag)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,80},{80,-80}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={0,191,0}),Line(points={{-20,80},{-20,-80}}, color={0,0,255}),Polygon(points={{-20,62},{46,46},{2,30},{58,18},{6,0},{48,-16},{2,-32},{54,-44},{-20,-60},{-20,62}}, lineColor={0,0,0}, fillColor={255,0,0}, fillPattern=FillPattern.CrossDiag)}), Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</ul>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end GTCombustionChamber;
