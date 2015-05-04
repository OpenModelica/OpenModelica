within ThermoSysPro.Combustion.CombustionChambers;
model GenericCombustion "Generic combustion chamber"
  parameter ThermoSysPro.Units.PressureLossCoefficient kcham=1 "Pressure loss coefficient in the combustion chamber";
  parameter Modelica.SIunits.Area Acham=1 "Average corss-sectional area of the combusiton chamber";
  parameter Real Xpth=0.01 "Thermal loss fraction in the body of the combustion chamber (0-1 over Q.HHV)";
  parameter Real ImbCV=0 "Unburnt particles ratio in the volatile ashes (0-1)";
  parameter Real ImbBF=0 "Unburnt particle ratio in the low furnace ashes (0-1)";
  parameter Modelica.SIunits.SpecificHeatCapacity Cpcd=500 "Ashes specific heat capacity";
  parameter ThermoSysPro.Units.AbsoluteTemperature Tbf=500 "Ashes temperature at the outlet of the low furnace";
  parameter Real Xbf=0.1 "Ashes ration in the low furnace (0-1)";
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
  Real Xwfuel(start=0) "H2O mass fraction in the fuel";
  Real XCDfuel(start=0) "Ashes mass fraction in the fuel";
  Modelica.SIunits.SpecificEnergy LHVfuel(start=50000000.0) "Fuel lower heating value";
  Modelica.SIunits.SpecificHeatCapacity Cpfuel(start=1000) "Fuel specific heat capacity";
  Modelica.SIunits.SpecificEnergy HHVfuel "Fuel higher heating value";
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
  Modelica.SIunits.Power Wpth(start=1000000.0) "Thermal losses power";
  Real exc(start=1) "Combustion air ratio";
  Modelica.SIunits.MassFlowRate Qcv(start=1) "Volatile ashes mass flow rate";
  Modelica.SIunits.MassFlowRate Qbf(start=1) "Low furnace ashes mass flow rate";
  ThermoSysPro.Units.SpecificEnthalpy Hcv(start=10000.0) "Volatile ashes specific enthalpy at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hbf(start=10000.0) "Low furnace ashes specific enthalpy at the outlet";
  ThermoSysPro.Units.DifferentialPressure deltaPccb(start=1000.0) "Pressure loss in the combustion chamber";
  ThermoSysPro.Units.SpecificEnthalpy Hrair(start=10000.0) "Air reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrws(start=100000.0) "Water/steam reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrfuel(start=10000.0) "Fuel reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrcd(start=10000.0) "Ashes reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrfg(start=10000.0) "Flue gases reference specific enthalpy";
  Real Vea(start=0.001) "Air volume mass (m3/kg)";
  Real Vsf(start=0.001) "Flue gases volume mass (m3/kg)";
  Modelica.SIunits.Density rhoea(start=0.001) "Air density at the inlet";
  Modelica.SIunits.Density rhosf(start=0.001) "Flue gases density at the outlet";
  Modelica.SIunits.MassFlowRate Qm(start=400) "Average mlass flow rate in the combusiton chamber";
  Real Vccbm(start=0.001) "Average volume mass in the combustion chamber";
  Modelica.SIunits.Velocity v(start=100) "Flue gases reference velocity in the combusiton chamber";
  ThermoSysPro.Combustion.Connectors.FuelInlet Cfuel "Fuel inlet" annotation(Placement(transformation(x=30.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=30.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Ca "Air inlet" annotation(Placement(transformation(x=-30.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-30.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Cfg "Flue gases outlet" annotation(Placement(transformation(x=-30.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-30.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Cws "Water/steam inlet" annotation(Placement(transformation(x=-90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant Real amC=12.01115 "Carbon atomic mass";
  constant Real amH=1.00797 "Hydrogen atomic mass";
  constant Real amO=15.9994 "Oxygen atomic mass";
  constant Real amS=32.064 "Sulfur atomic mass";
  constant Modelica.SIunits.SpecificEnergy HHVcarbone=32800000.0 "Unburnt carbon higher heating value";
  Real amCO2 "CO2 molecular mass";
  Real amH2O "H2O molecular mass";
  Real amSO2 "SO2 molecular mass";
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
  Xwfuel=Cfuel.hum;
  XCDfuel=Cfuel.Xashes;
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
  Hea=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pea, Tea, XeaCO2, XeaH2O, XeaO2, XeaSO2);
  Hsf=ThermoSysPro.Properties.FlueGases.FlueGases_h(Psf, Tsf, XsfCO2, XsfH2O, XsfO2, XsfSO2);
  rhoea=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pea, Tea, XeaCO2, XeaH2O, XeaO2, XeaSO2);
  Vea=if rhoea > 0.001 then 1/rhoea else 1/1.1;
  rhosf=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Psf, Tsf, XsfCO2, XsfH2O, XsfO2, XsfSO2);
  Vsf=if rhosf > 0.001 then 1/rhosf else 1/0.1;
  amCO2=amC + 2*amO;
  amH2O=2*amH + amO;
  amSO2=amS + 2*amO;
  Qsf=Qea + Qews + Qfuel*(1 - XCDfuel) - Qcv*ImbCV - Qbf*ImbBF;
  Qcv=Qfuel*XCDfuel*(1 - Xbf)/(1 - ImbCV);
  Qbf=Qfuel*XCDfuel*Xbf/(1 - ImbBF);
  XsfCO2*Qsf=Qea*XeaCO2 + (Qfuel*XCfuel - Qcv*ImbCV - Qbf*ImbBF)*amCO2/amC;
  XsfH2O*Qsf=Qews + (Qea*XeaH2O + Qfuel*XHfuel*amH2O/2/amH);
  XsfO2*Qsf=Qea*XeaO2 - Qfuel*amO*(2*XCfuel/amC + 0.5*XHfuel/amH + 2*XSfuel/amS) + Qfuel*XOfuel;
  XsfSO2*Qsf=Qea*XeaSO2 + Qfuel*XSfuel*amSO2/amS;
  HHVfuel=LHVfuel + 22430000.0*XHfuel + 2510000.0*Xwfuel;
  Wfuel=Qfuel*HHVfuel;
  Wpth=Qfuel*LHVfuel*Xpth;
  exc=Qea*(1 - XeaH2O)/((Qfuel*amO*(2*XCfuel/amC + 0.5*XHfuel/amH + 2*XSfuel/amS - XOfuel/amO) - Qfuel*amO*2*(Qcv*ImbCV + Qbf*ImbBF)/amC)/(XeaO2/(1 - XeaH2O)));
  Pea - Psf=deltaPccb;
  Qm=Qea + (Qfuel + Qews)/2;
  Vccbm=(Vea + Vsf)/2;
  v=Qm*Vccbm/Acham;
  deltaPccb=kcham*v^2/(2*Vccbm);
  (Qea + Qews + Qfuel*(1 - XCDfuel))*(Hsf - Hrfg) + Wpth + Qcv*(Hcv - Hrcd) + Qbf*(Hbf - Hrcd) + (Qcv*ImbCV + Qbf*ImbBF)*HHVcarbone - (Qfuel*(Hfuel - Hrfuel + LHVfuel) + Qea*(Hea - Hrair) + Qews*(Hews - Hrws))=0;
  Hfuel=Cpfuel*Tfuel;
  Hcv=Cpcd*Tsf;
  Hbf=Cpcd*Tbf;
  Hrair=2501569.0*XeaH2O;
  Hrfuel=0;
  Hrws=2501569.0;
  Hrfg=2501569.0*XsfH2O;
  Hrcd=0;
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,80},{80,-80}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Polygon(points={{-50,-36},{-44,30},{-34,-2},{-10,66},{10,-4},{44,54},{66,-44},{38,-80},{-34,-80},{-50,-36}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,127,0}),Polygon(points={{-32,-36},{-18,-44},{-26,-16},{-16,6},{4,-44},{8,-28},{36,-72},{16,-80},{-16,-80},{-32,-36}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,0,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,80},{80,-80}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={255,255,0}),Polygon(points={{-50,-36},{-44,30},{-34,-2},{-10,66},{10,-4},{44,54},{66,-44},{38,-80},{-34,-80},{-50,-36}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,127,0}),Polygon(points={{-32,-36},{-18,-44},{-26,-16},{-16,6},{4,-44},{8,-28},{36,-72},{16,-80},{-16,-80},{-32,-36}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,0,0})}), Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Benoît Bride</li>
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
end GenericCombustion;
