within ThermoSysPro.MultiFluids.Machines;
model AlternatingEngine "Internal combustion engine with electrical output"
  parameter Integer mechanical_efficiency_type=1 "1: fixed nominal efficiency - 2: Linear efficiency using Coef_Rm_a, Coef_Rm_b and Coef_Rm_c - 3: Beau de Rochas cycle efficiency";
  parameter Real Rmeca_nom=0.4 "Fixed nominal mechanical efficiency (active if mechanical_efficiency_type=1)";
  parameter Real Coef_Rm_a=-5.727e-09 "Coefficient a for the linear mechanical efficiency (active if mechanical_efficiency_type=2)";
  parameter Real Coef_Rm_b=4.5267e-05 "Coefficient b for the linear mechanical efficiency (active if mechanical_efficiency_type=2)";
  parameter Real Coef_Rm_c=0.312412946 "Coefficient c for the linear mechanical efficiency (active if mechanical_efficiency_type=2)";
  parameter Real Relec=0.97 "Engine electrical efficiency";
  parameter Real Relec_red=0.967 "Engein electrical efficiency at half load";
  parameter Modelica.SIunits.Power Pnom=500000000.0 "Engein nominal power";
  parameter Real Cosphi=1 "Cos(phi) of the eletrical grid";
  parameter Real Xpth=0.03 "Thermal loss fraction - cooling (0-1 sur Q.PCI)";
  parameter Real Xref=0.2 "Cooling power fraction (0-1 sur Q.PCI)";
  parameter Real MMg=30 "Gas average molar mass (g/mol)";
  parameter Real DPe=0 "Water pressure loss as percent of the pressure at the inlet";
  parameter ThermoSysPro.Units.DifferentialPressure DPaf=0 "Pressure difference between the air pressure at the inlet and the flue gases pressure at the outlet";
  parameter Real RV=6 "Engine volume ratio (> 1)";
  parameter Real Kc=1.2 "Compression polytropic coefficient";
  parameter Real Kd=1.4 "Expansion polytropic coefficient";
  Modelica.SIunits.MassFlowRate Qsf(start=400) "Flue gases mass flow rate at the outlet";
  ThermoSysPro.Units.AbsolutePressure Psf(start=1200000.0) "Flue gases pressure at the outlet";
  ThermoSysPro.Units.AbsoluteTemperature Tsf(start=1500) "Flue gases temperature at the outlet";
  Real XsfCO2(start=0.5) "Flue gases CO2 mass fraction at the outlet";
  Real XsfH2O(start=0.1) "Flue gases H2O mass fraction at the outlet";
  Real XsfO2(start=0) "Flue gases O2 mass fraction at the outlet";
  Real XsfSO2(start=0) "Flue gases SO2 mass fraction at the outlet";
  Real Rmeca(start=0.3) "Engine mechanical efficiency";
  Modelica.SIunits.Power Wmeca(start=500000000.0) "Engine mechanical power";
  Modelica.SIunits.Power Welec(start=500000000.0) "Engine lectrical power";
  Modelica.SIunits.Power Wcomb(start=500000000.0) "Fuel power available (Q.PCS)";
  Modelica.SIunits.Power Wpth_ref(start=1000000.0) "Power of thermal losses + cooling";
  Real exc(start=1) "Combustion air ratio";
  Real PCScomb "Pouvoir Calorifique Supérieur du combustible sur brut(en J/kg)";
  ThermoSysPro.Units.AbsoluteTemperature Tm(start=500) "Air-gas mixture temperature";
  ThermoSysPro.Units.AbsoluteTemperature Tfcp(start=500) "Temperature at the end of the compression phase";
  ThermoSysPro.Units.AbsolutePressure Pfcp(start=1200000.0) "Pressure at the end of the compression phase";
  ThermoSysPro.Units.AbsoluteTemperature Tfcb(start=500) "Temperature at the end of the combustion phase";
  ThermoSysPro.Units.AbsolutePressure Pfcb(start=1200000.0) "Pressure at the end of the combustion phase";
  ThermoSysPro.Units.AbsoluteTemperature Tfd(start=500) "Temperature at the end of the expansion phase";
  ThermoSysPro.Units.AbsolutePressure Pfd(start=1200000.0) "Pressure at the end of the expansion phase";
  ThermoSysPro.Units.AbsoluteTemperature Tfe(start=500) "Temperature at the exhaust";
  ThermoSysPro.Units.SpecificEnthalpy Hea(start=50000.0) "Air specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hsf(start=500000.0) "Flue gases specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hcomb(start=10000.0) "Fuel specific enthalpy at the inlet";
  ThermoSysPro.Units.SpecificEnthalpy Hrfum(start=10000.0) "Flue gases reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrair(start=10000.0) "Air reference specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy Hrcomb(start=10000.0) "Fuel reference specific enthalpy";
  Modelica.SIunits.MassFlowRate Qea(start=400) "Air mass flow rate at the inlet";
  ThermoSysPro.Units.AbsolutePressure Pea(start=100000.0) "Air pressure at the inlet";
  ThermoSysPro.Units.AbsoluteTemperature Tea(start=600) "Air temperature at the inlet";
  Real XeaCO2(start=0) "Air CO2 mass fraction at the inlet";
  Real XeaH2O(start=0.1) "Air H2O mass fraction at the inlet";
  Real XeaO2(start=0.2) "Air O2 mass fraction at the inlet";
  Real XeaSO2(start=0) "Air SO2 mass fraction at the inlet";
  Modelica.SIunits.SpecificHeatCapacity Cpair(start=1000) "Air specific heat capacity";
  Modelica.SIunits.MassFlowRate Qcomb(start=5) "Fuel mass flow rate";
  ThermoSysPro.Units.AbsoluteTemperature Tcomb(start=300) "Fuel temperature";
  Real XCcomb(start=0.8) "Fuel carbon fraction";
  Real XHcomb(start=0.2) "Fuel hydrogen fraction";
  Real XOcomb(start=0) "Fuel oxygen fraction";
  Real XScomb(start=0) "Fuel sulfur fraction";
  Real XEAUcomb(start=0) "Fuel H2O fraction";
  Real XCDcomb(start=0) "Fuel ashes fraction";
  Real PCIcomb(start=50000000.0) "Fuel PCI (J/kg)";
  Modelica.SIunits.SpecificHeatCapacity Cpcomb(start=1000) "Fuel specific heat capacity";
  Modelica.SIunits.MassFlowRate Qe(start=1) "Water mass flow rate";
  ThermoSysPro.Units.SpecificEnthalpy Hev(start=10000.0) "Water specific enthalpy at the inlet";
  Modelica.SIunits.Density rhoea(start=0.001) "Air density at the inlet";
  Modelica.SIunits.Density rhosf(start=0.001) "Flue gases density at the outlet";
  ThermoSysPro.Units.SpecificEnthalpy Hsv(start=10000.0) "Water specific enthalpy at the outlet";
  Real MMairgaz(start=30) "Air/gas mixture molecular mass (g/mol)";
  Real MMfumees(start=30) "Flue gases molecular mass (g/mol)";
  ThermoSysPro.Combustion.Connectors.FuelInlet Cfuel annotation(Placement(transformation(x=-40.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-40.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesInlet Cair annotation(Placement(transformation(x=40.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=40.0, y=-90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.FlueGases.Connectors.FlueGasesOutlet Cfg annotation(Placement(transformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Cws1 annotation(Placement(transformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cws2 annotation(Placement(transformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=90.0, y=0.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,80},{80,-80}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,223,159}),Polygon(points={{-10,-64},{4,-46},{0,-56},{18,-54},{2,-60},{22,-66},{6,-64},{-10,-76},{-2,-66},{-10,-64}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,0,0}),Polygon(points={{-46,-42},{-46,0},{-6,0},{-6,58},{0,50},{6,58},{6,0},{48,0},{48,-42},{-46,-42}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={159,223,159}),Polygon(lineColor={0,0,255}, points={{-80,30},{-34,30},{-34,54},{38,54},{38,30},{80,30},{80,38},{46,38},{46,62},{-42,62},{-42,38},{-80,38},{-80,30}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, fillColor={0,0,0})}), Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{-80,80},{80,-80}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,223,159}),Polygon(points={{-10,-64},{4,-46},{0,-56},{18,-54},{2,-60},{22,-66},{6,-64},{-10,-76},{-2,-66},{-10,-64}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={255,0,0}),Polygon(points={{-46,-42},{-46,0},{-6,0},{-6,58},{0,50},{6,58},{6,0},{48,0},{48,-42},{-46,-42}}, fillPattern=FillPattern.Solid, lineColor={0,0,0}, fillColor={159,223,159}),Polygon(lineColor={0,0,255}, points={{-80,30},{-34,30},{-34,54},{38,54},{38,30},{80,30},{80,38},{46,38},{46,62},{-42,62},{-42,38},{-80,38},{-80,30}}, fillPattern=FillPattern.Solid, pattern=LinePattern.None, fillColor={0,0,0})}), Documentation(revisions="<html>
<u><p><b>Authors</u> : </p></b>
<ul style='margin-top:0cm' type=disc>
<li>
    Benoît Bride</li>
</html>
", info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
protected
  constant Real amC=12.01115 "Carbon atomic mass";
  constant Real amH=1.00797 "Hydrogen atomic mass";
  constant Real amO=15.9994 "Oxygen atomic mass";
  constant Real amS=32.064 "Sulfur atomic mass";
  constant Real Gamma=1.3333 "Flue gases gamma = Cp/Cv";
  constant Real amCO2=amC + 2*amO "CO2 molecular mass";
  constant Real amH2O=2*amH + amO "H2O molecular mass";
  constant Real amSO2=amS + 2*amO "SO2 molecular mass";
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
  XEAUcomb=Cfuel.hum;
  XCDcomb=Cfuel.Xashes;
  PCIcomb=Cfuel.LHV;
  Cpcomb=Cfuel.cp;
  Qe=Cws1.Q;
  Hev=Cws1.h;
  Cws2.Q=Cws1.Q;
  Hsv=Cws2.h;
  Qsf=Cfg.Q;
  Psf=Cfg.P;
  Tsf=Cfg.T;
  XsfCO2=Cfg.Xco2;
  XsfH2O=Cfg.Xh2o;
  XsfO2=Cfg.Xo2;
  XsfSO2=Cfg.Xso2;
  0=if Qe > 0 then Cws1.h - Cws1.h_vol else Cws2.h - Cws2.h_vol;
  Qsf=Qea + Qcomb;
  XsfCO2*Qsf=Qea*XeaCO2 + Qcomb*XCcomb*amCO2/amC;
  XsfH2O*Qsf=Qea*XeaH2O + Qcomb*XHcomb*(amH2O/2)/amH;
  XsfO2*Qsf=Qea*XeaO2 - Qcomb*amO*(2*XCcomb/amC + 0.5*XHcomb/amH + 2*XScomb/amS) + Qcomb*XOcomb;
  XsfSO2*Qsf=Qea*XeaSO2 + Qcomb*XScomb*amSO2/amS;
  PCScomb=PCIcomb + 22430000.0*XHcomb + 2510000.0*XEAUcomb;
  Wcomb=Qcomb*PCIcomb;
  Wpth_ref=Qcomb*PCIcomb*(Xpth + Xref);
  Qe*(Hsv - Hev)=Qcomb*PCIcomb*Xref;
  Hea=ThermoSysPro.Properties.FlueGases.FlueGases_h(Pea, Tea, XeaCO2, XeaH2O, XeaO2, XeaSO2);
  Cpair=ThermoSysPro.Properties.FlueGases.FlueGases_cp(Pea, Tea, XeaCO2, XeaH2O, XeaO2, XeaSO2);
  rhoea=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Pea, Tea, XeaCO2, XeaH2O, XeaO2, XeaSO2);
  Hsf=ThermoSysPro.Properties.FlueGases.FlueGases_h(Psf, Tsf, XsfCO2, XsfH2O, XsfO2, XsfSO2);
  rhosf=ThermoSysPro.Properties.FlueGases.FlueGases_rho(Psf, Tsf, XsfCO2, XsfH2O, XsfO2, XsfSO2);
  Tm=(Qcomb*Cpcomb*Tcomb + Qea*Cpair*Tea)/(Qcomb*Cpcomb + Qea*Cpair);
  Tfcp=Tm*RV^(Kc - 1);
  Pfcp=Pea*RV^Kc;
  MMairgaz=(Qea*28.9 + Qcomb*MMg)/(Qea + Qcomb);
  MMfumees=(1 - XsfCO2 - XsfH2O - XsfO2 - XsfSO2)*28 + XsfCO2*44 + XsfH2O*18 + XsfO2*32 + XsfSO2*64;
  Tfcb=(Wcomb - Wpth_ref)/ThermoSysPro.Properties.FlueGases.FlueGases_cp(Pfcp, (Tfcp + Tfcb)/2, XsfCO2, XsfH2O, XsfO2, XsfSO2)/0.75/Qsf + Tfcp;
  Pfcb=Pfcp*Tfcb/Tfcp*MMairgaz/MMfumees;
  Tfd=Tfcb*(1/RV)^(Kd - 1);
  Pfd=Pfcb*(1/RV)^Kd;
  Tfe=Tfd*(Psf/Pfd)^((Gamma - 1)/Gamma);
  if mechanical_efficiency_type == 1 then
    Rmeca=Rmeca_nom;
  elseif mechanical_efficiency_type == 2 then
    Rmeca=Coef_Rm_a*Wcomb/1000*Wcomb/1000 + Coef_Rm_b*Wcomb/1000 + Coef_Rm_c;
  else
    Rmeca=(Qcomb*(Hcomb - Hrcomb + PCIcomb) + Qea*(Hea - Hrair) - (Qsf*(ThermoSysPro.Properties.FlueGases.FlueGases_h(Psf, Tfe, XsfCO2, XsfH2O, XsfO2, XsfSO2) - Hrfum) + Wpth_ref))/Wcomb;
  end if;
  Wmeca=Rmeca*Wcomb;
  exc=Qea*(1 - XeaH2O)/(Qcomb*amO*(2*XCcomb/amC + 0.5*XHcomb/amH + 2*XScomb/amS - XOcomb/amO)/(XeaO2/(1 - XeaH2O)));
  Pea - Psf=DPaf;
  Cws2.P=if Qe > 0 then Cws1.P - DPe*Cws1.P/100 else Cws1.P + DPe*Cws1.P/100;
  Qsf*(Hsf - Hrfum) + Wpth_ref + Wmeca - (Qcomb*(Hcomb - Hrcomb + PCIcomb) + Qea*(Hea - Hrair))=0;
  Hcomb=Cpcomb*(Tcomb - 273.15);
  if Wmeca > Pnom*0.5 then
    Welec=Wmeca*Relec*(0.0479*Cosphi + 0.952);
  else
    Welec=Wmeca*Relec_red*(0.0479*Cosphi + 0.952);
  end if;
  Hrair=2501569.0*XeaH2O;
  Hrcomb=0;
  Hrfum=2501569.0*XsfH2O;
end AlternatingEngine;
