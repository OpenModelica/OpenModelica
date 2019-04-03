within ThermoSysPro.MultiFluids.Boilers;
model FossilFuelBoiler "Fossil fuel boiler"
  parameter ThermoSysPro.Units.AbsoluteTemperature Tsf=400 "Flue gases temperature at the outlet";
  parameter ThermoSysPro.Units.PressureLossCoefficient Kf=0.05 "Flue gases pressure loss coefficient";
  parameter ThermoSysPro.Units.PressureLossCoefficient Ke=10000.0 "Water/steam pressure loss coefficient";
  parameter Real etacomb=1 "Combustion efficiency (between 0 and 1)";
  parameter Modelica.SIunits.Power Wloss=100000.0 "Thermal losses";
  parameter Integer mode=0 "IF97 region. 1:liquid - 2:steam - 4:saturation line - 0:automatic";
  Modelica.SIunits.MassFlowRate Qea(start=400) "Air mass flow rate at the inlet";
  ThermoSysPro.Units.AbsolutePressure Pea(start=100000.0) "Air pressure at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tea(start=400) "Air temperature at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hea(start=50000.0) "Air specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hrair(start=10000.0) "Air reference specific enthalpy";
  Real XeaCO2(start=0) "CO2 mass fraction at the inlet";
  Real XeaH2O(start=0.1) "H2O mass fraction at the inlet";
  Real XeaO2(start=0.2) "O2 mass fraction at the inlet";
  Real XeaSO2(start=0) "SO2 mass fraction at the inlet";
  Modelica.SIunits.MassFlowRate Qcomb(start=5) "Fuel mass flow rate";
  ThermoSysPro.Units.AbsoluteTemperature Tcomb(start=300) "Fuel temperature";
  ThermoSysPro.Units.SpecificEnthalpy Hcomb(start=10000.0) "Fuel specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrcomb(start=10000.0) "Fuel reference specific enthalpy";
  Real XCcomb(start=0.8) "Carbon mass fraction";
  Real XHcomb(start=0.2) "Hydrogen mass fraction";
  Real XOcomb(start=0) "Oxygen mass fraction";
  Real XScomb(start=0) "Sulfur mass fraction";
  Real PCIcomb(start=50000000.0) "Fuel PCI (J/kg)";
  Modelica.SIunits.SpecificHeatCapacity Cpcomb(start=2000) "Fuel specific heat capacity";
  Modelica.SIunits.MassFlowRate Qe(start=100) "Water/steam mass flow rate";
  ThermoSysPro.Units.AbsolutePressure Pee(start=5000000.0) "Water/steam pressure at the inlet";
  ThermoSysPro.Units.AbsolutePressure Pse(start=5000000.0) "Water/steam pressure at the outlet";
  ThermoSysPro.Units.DifferentialPressure deltaPe(start=100000.0) "Water/steam pressure losses";
  ThermoSysPro.Units.AbsoluteTemperature Tse(start=500) "Water/steam temperature at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hee(start=400000.0) "Water/steam specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hse(start=400000.0) "Water/steam specific enthalpy at the outlet";
  Modelica.SIunits.Density rhoe(start=998) "Average water/steam density";
  Modelica.SIunits.MassFlowRate Qsf(start=400) "Flue gases mass flow rate at the outlet";
  ThermoSysPro.Units.AbsolutePressure Psf(start=100000.0) "Flue gases pressure at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tf(start=1500) "Flue gases temperature after combustion";
  ThermoSysPro.Units.SpecificEnthalpy Hsf(start=50000.0) "Flue gases specific enthalpy at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hf(start=100000.0) "Flue gases specific enthalpy after combustion";
  ThermoSysPro.Units.SpecificEnthalpy Hrfum(start=10000.0) "Flue gases reference specific enthalpy";
  ThermoSysPro.Units.DifferentialPressure deltaPf(start=1000.0) "Pressure losses in the combusiton chamber";
  Modelica.SIunits.Density rhof(start=0.05) "Flue gases density";
  Real XsfCO2(start=0.2) "CO2 mass fraction at the outlet";
  Real XsfH2O(start=0.15) "H2O mass fraction at the outlet";
  Real XsfO2(start=0) "O2 mass fraction at the outlet";
  Real XsfSO2(start=0) "SO2 mass fraction at the outlet";
  Modelica.SIunits.Power Wfuel(start=500000000.0) "Fuel available power PCI";
  Modelica.SIunits.Power Wtot(start=500000000.0) "Total incoming power";
  Modelica.SIunits.Power Wboil(start=5000000000.0) "Power exchanged in the boiler";
  Real eta_boil(start=90) "Boiler efficiency (%) ";
  Real exc(start=1) "Air combustion ratio";
  Real exc_air(start=0.1) "Pertcentage of air in excess";
  ThermoSysPro.Combustion.Connectors.FuelInlet Cfuel annotation(Placement(transformation(x=0.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-80.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Cair annotation(Placement(transformation(x=-100.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Cfg annotation(Placement(transformation(x=100.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-62.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Cws1 annotation(Placement(transformation(x=-100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cws2 annotation(Placement(transformation(x=100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pros annotation(Placement(transformation(x=-90.0, y=94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prom annotation(Placement(transformation(x=90.0, y=94.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real amC=12.01115 "Carbon atomic mass";
  constant Real amH=1.00797 "Hydrogen atomic mass";
  constant Real amO=15.9994 "Oxygen atomic mass";
  constant Real amS=32.064 "Sulfur atomic mass";
  constant Real amCO2=amC + 2*amO "CO2 molecular mass";
  constant Real amH2O=2*amH + amO "H2O molecular mass";
  constant Real amSO2=amS + 2*amO "SO2 molecular mass";
  constant Real teps=1e-06 "Small number";
  parameter Real eps=1.0 "Small number for pressure loss equation";
  Real XeaO2c(start=0.2) "Intermediate variable for the computation of the O2 mass fraction";
equation
  Qea=Cair.Q;
  Pea=Cair.P;
  Tea=Cair.T;
  XeaCO2=Cair.Xco2;
  XeaH2O=Cair.Xh2o;
  XeaO2=Cair.Xo2;
  XeaSO2=Cair.Xso2;
  Qcomb=Cfuel.Q;
  Tcomb=Cfuel.T;
  XCcomb=Cfuel.Xc;
  XHcomb=Cfuel.Xh;
  XOcomb=Cfuel.Xo;
  XScomb=Cfuel.Xs;
  PCIcomb=Cfuel.LHV;
  Cpcomb=Cfuel.cp;
  Qsf=Cfg.Q;
  Psf=Cfg.P;
  Tsf=Cfg.T;
  XsfCO2=Cfg.Xco2;
  XsfH2O=Cfg.Xh2o;
  XsfO2=Cfg.Xo2;
  XsfSO2=Cfg.Xso2;
  Hee=Cws1.h;
  Pee=Cws1.P;
  Qe=Cws1.Q;
  Cws2.h=Hse;
  Cws2.P=Pse;
  Cws2.Q=Qe;
  0=if Qe > 0 then Cws1.h - Cws1.h_vol else Cws2.h - Cws2.h_vol;
  Qsf=Qea + Qcomb;
  XsfCO2*Qsf=Qea*XeaCO2 + Qcomb*XCcomb*amCO2/amC;
  XsfH2O*Qsf=Qea*XeaH2O + Qcomb*XHcomb*(amH2O/2)/amH;
  XsfO2*Qsf=Qea*XeaO2c - Qcomb*amO*(2*XCcomb/amC + 0.5*XHcomb/amH + 2*XScomb/amS) + Qcomb*XOcomb;
  XsfSO2*Qsf=Qea*XeaSO2 + Qcomb*XScomb*amSO2/amS;
  exc=Qea*(1 - XeaH2O)/(Qcomb*amO*(2*XCcomb/amC + 0.5*XHcomb/amH + 2*XScomb/amS - XOcomb/amO)/(XeaO2c/(1 - XeaH2O)));
  exc_air=(exc - 1)*100;
  Pea - Psf=deltaPf;
  deltaPf=Kf*ThermoSysPro.Functions.ThermoSquare(Qsf, eps)/rhof;
  Pee - Pse=deltaPe;
  deltaPe=Ke*ThermoSysPro.Functions.ThermoSquare(Qe, eps)/rhoe;
  Hcomb=Cpcomb*Tcomb;
  0=Qsf*(Hf - Hrfum) + Wloss - (Qcomb*(Hcomb - Hrcomb + PCIcomb*etacomb) + Qea*(Hea - Hrair));
  Wfuel=Qcomb*PCIcomb;
  Wtot=Qcomb*(Hcomb - Hrcomb + PCIcomb*etacomb) + Qea*(Hea - Hrair);
  Wboil=Wtot - Qsf*(Hsf - Hrfum) - Wloss;
  Hse=Wboil/Qe + Hee;
  eta_boil=100*Wboil/Wfuel;
  Hea=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pea, Tea, XeaCO2, XeaH2O, XeaO2c, XeaSO2);
  Hf=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pea, Tf, XsfCO2, XsfH2O, XsfO2, XsfSO2);
  Hsf=ThermoSysPro.Properties.FlueGases.FlueGases_h(Psf, Tsf, XsfCO2, XsfH2O, XsfO2, XsfSO2);
  rhof=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pea, (Tea + Tf)/2, XsfCO2, XsfH2O, XsfO2, XsfSO2);
  0=if XeaO2 > teps then XeaO2c - XeaO2 else XeaO2c - teps;
  Hrair=2501569.0*XeaH2O;
  Hrcomb=0;
  Hrfum=2501569.0*XsfH2O;
  prom=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph((Pee + Pse)/2, (Hee + Hse)/2, mode);
  rhoe=prom.d;
  pros=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pse, Hse, mode);
  Tse=pros.T;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,80},{100,-80}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Polygon(points={{0,-42},{12,-46},{22,-34},{26,-20},{24,-6},{22,2},{18,12},{14,22},{12,30},{10,36},{6,54},{2,44},{-2,36},{-6,24},{-6,20},{-8,16},{-10,24},{-12,26},{-14,22},{-18,14},{-20,8},{-24,0},{-26,-10},{-28,-20},{-28,-28},{-22,-36},{-18,-42},{-8,-48},{0,-42}}, lineColor={255,0,127}, fillColor={255,127,0}, fillPattern=FillPattern.Solid),Polygon(points={{-8,-22},{-6,-18},{-2,-16},{2,-16},{6,-18},{8,-20},{10,-26},{10,-30},{8,-28},{6,-24},{4,-20},{-2,-20},{-4,-22},{-8,-26},{-10,-28},{-10,-28},{-8,-22}}, lineColor={191,0,0}, fillColor={191,0,0}, fillPattern=FillPattern.Solid)}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-100,80},{100,-80}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Polygon(points={{-2,-42},{10,-46},{20,-34},{24,-20},{22,-6},{20,2},{16,12},{12,22},{10,30},{8,36},{4,54},{0,44},{-4,36},{-8,24},{-8,20},{-10,16},{-12,24},{-14,26},{-16,22},{-20,14},{-22,8},{-26,0},{-28,-10},{-30,-20},{-30,-28},{-24,-36},{-20,-42},{-10,-48},{-2,-42}}, lineColor={255,0,127}, fillColor={255,127,0}, fillPattern=FillPattern.Solid),Polygon(points={{-10,-24},{-8,-20},{-4,-18},{0,-18},{4,-20},{6,-22},{8,-28},{8,-32},{6,-30},{4,-26},{2,-22},{-4,-22},{-6,-24},{-10,-28},{-12,-30},{-12,-30},{-10,-24}}, lineColor={191,0,0}, fillColor={191,0,0}, fillPattern=FillPattern.Solid)}), Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Baligh El Hefni</li>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end FossilFuelBoiler;
