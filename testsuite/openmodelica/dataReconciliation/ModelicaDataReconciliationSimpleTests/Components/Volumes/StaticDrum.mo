within ModelicaDataReconciliationSimpleTests.Components.Volumes;
model StaticDrum "Staic drum"
  parameter Real x=1 "Vapor separation efficiency at the outlet";
  parameter Integer fluid=1 "1: water/steam - 2: C3H3F5 - 3: Simple";

  constant Real c0=-1.499284498173245e8;
  constant Real c1=2.704822454027627e6;
  constant Real c2=-2.055993982138471e4;
  constant Real c3=8.527291155079814e1;
  constant Real c4=-2.08121050121206e-1;
  constant Real c5=2.984399245658974e-4;
  constant Real c6=-2.327974895639335e-7;
  constant Real c7=7.677448367806697e-11;

  constant Real v00=1.778741e6;
  constant Real v10=-6.9977339e-2;
  constant Real v01=2.423675e3;
  constant Real v20=1.958603e-10;
  constant Real v11=8.100784e-5;
  constant Real v02=-3.747139e-1;
  constant Real v30=-1.016123e-19;
  constant Real v21=-1.234548e-13;
  constant Real v12=-2.324528e-8;
  constant Real v03=1.891004e-4;

  constant Real l00=-1.210342e7;
  constant Real l10=3.9322901e-2;
  constant Real l01=1.3110565e5;
  constant Real l20=-3.425284e-10;
  constant Real l11=-2.572281e-4;
  constant Real l02=-5.801243e2;
  constant Real l30=1.974339e-19;
  constant Real l21=2.427381e-12;
  constant Real l12=4.966543e-7;
  constant Real l03=1.314839e0;
  constant Real l40=-4.256626e-27;
  constant Real l31=1.512868e-21;
  constant Real l22=-6.054694e-15;
  constant Real l13=-8.389491e-11;
  constant Real l04=-1.484055e-3;
  constant Real l50=1.597043e-35;
  constant Real l41=1.356624e-31;
  constant Real l32=-2.492294e-24;
  constant Real l23=5.082575e-18;
  constant Real l14=-3.822957e-13;
  constant Real l05=6.712484e-7;

public
  Modelica.Units.SI.Temperature T "Fluid temperature";
  Modelica.Units.SI.AbsolutePressure P(start=10.e5) "Fluid pressure";
  Modelica.Units.SI.SpecificEnthalpy hl(start=100000) "Liquid phase specific enthalpy";
  Modelica.Units.SI.SpecificEnthalpy hv(start=2800000) "Gas phase specific enthalpy";
public
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce_eva annotation (Placement(transformation(extent={{-104,-44},{-84,-24}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce_eco annotation (Placement(transformation(extent={{-50,-104},{-30,-84}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs_sup annotation (Placement(transformation(extent={{84,24},{104,44}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs_eva annotation (Placement(transformation(extent={{30,-104},{50,-84}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs_sur annotation (Placement(transformation(extent={{28,84},{48,104}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidOutlet Cs_purg annotation (Placement(transformation(extent={{84,-44},{104,-24}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce_steam annotation (Placement(transformation(extent={{-48,84},{-28,104}}, rotation=0)));
  ThermoSysPro.WaterSteam.Connectors.FluidInlet Ce_sup annotation (Placement(transformation(extent={{-104,26},{-84,46}}, rotation=0)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsat annotation (Placement(transformation(extent={{-104,66},{-78,98}}, rotation=0)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsat annotation (Placement(transformation(extent={{72,68},{100,100}}, rotation=0)));
  ThermoSysPro.Thermal.Connectors.ThermalPort Cth annotation (Placement(transformation(extent={{-10,-10},{10,10}}, rotation=0)));
equation
  /* Unconnected connectors */

  /* Steam input */
  if (cardinality(Ce_steam) == 0) then
    Ce_steam.Q = 0;
    Ce_steam.h = 1.e5;
    Ce_steam.b = true;
  end if;

  /* Extra input */
  if (cardinality(Ce_sup) == 0) then
    Ce_sup.Q = 0;
    Ce_sup.h = 1.e5;
    Ce_sup.b = true;
  end if;

  /* Input from evaporator */
  if (cardinality(Ce_eva) == 0) then
    Ce_eva.Q = 0;
    Ce_eva.h = 1.e5;
    Ce_eva.b = true;
  end if;

  /* Input from the economizer */
  if (cardinality(Ce_eco) == 0) then
    Ce_eco.Q = 0;
    Ce_eco.h = 1.e5;
    Ce_eco.b = true;
  end if;

  /* Output to the evaporator */
  if (cardinality(Cs_eva) == 0) then
    Cs_eva.Q = 0;
    Cs_eva.h = 1.e5;
    Cs_eva.a = true;
  end if;

  /* Extra output */
  if (cardinality(Cs_purg) == 0) then
    Cs_purg.Q = 0;
    Cs_purg.h = 1.e5;
    Cs_purg.a = true;
  end if;

  /* Extra output  */
  if (cardinality(Cs_sup) == 0) then
    Cs_sup.Q = 0;
    Cs_sup.h = 1.e5;
    Cs_sup.a = true;
  end if;

  /* Output to reheater */
  if (cardinality(Cs_sur) == 0) then
    Cs_sur.Q = 0;
    Cs_sur.h = 1.e5;
    Cs_sur.a = true;
  end if;

  /* Fluid pressure */
  P = Ce_steam.P;
  P = Ce_sup.P;
  P = Ce_eva.P;
  P = Ce_eco.P;
  P = Cs_eva.P;
  P = Cs_purg.P;
  P = Cs_sup.P;
  P = Cs_sur.P;

  /* Fluid specific enthalpies at the inlets and outlets */
  Ce_sup.h_vol = hl;
  Ce_eva.h_vol = hl;
  Ce_eco.h_vol = hl;
  Ce_steam.h_vol = hv;

  Cs_purg.h_vol = hl;
  Cs_sup.h_vol = hl;
  Cs_eva.h_vol = hl;
  Cs_sur.h_vol = (1 - x)*hl + x*hv;

  /* Mass balance equation */
  Ce_eco.Q + Ce_steam.Q + Ce_sup.Q + Ce_eva.Q - Cs_eva.Q - Cs_sur.Q - Cs_purg.Q - Cs_sup.Q = 0;

  /* Energy balance equation */
  Ce_eco.Q*Ce_eco.h + Ce_steam.Q*Ce_steam.h + Ce_sup.Q*Ce_sup.h + Ce_eva.Q*Ce_eva.h - Cs_eva.Q*Cs_eva.h - Cs_sur.Q*Cs_sur.h - Cs_purg.Q*Cs_purg.h - Cs_sup.Q*Cs_sup.h + Cth.W = 0;

  /* Fluid thermodynamic properties */
  if (fluid == 3) then
    P = c0 + c1*T + c2*T^2 + c3*T^3 + c4*T^4 + c5*T^5 + c6*T^6 + c7*T^7;
    hv = v00 + v10*P + v01*T + v20*P^2 + v11*P*T + v02*T^2 + v30*P^3 + v21*P^2*T + v12*P*T^2 + v03*T^3;
    hl = l00 + l10*P + l01*T + l20*P^2 + l11*P*T + l02*T^2 + l30*P^3 + l21*P^2*T + l12*P*T^2 + l03*T^3 + l40*P^4 + l31*P^3*T + l22*P^2*T^2 + l13*P*T^3 + l04*T^4 + l50*P^5 + l41*P^4*T + l32*P^3*T^2 + l23*P^2*T^3 + l14*P*T^4 + l05*T^5;
    (lsat,vsat) = ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(1.e5);
  else
    (lsat,vsat) = ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(P);

    hl = lsat.h;
    hv = vsat.h;
    T = ThermoSysPro.Properties.Fluid.T_sat(P, fluid);
  end if;

  Cth.T = T;

  annotation (
    Diagram(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Line(points={{0,90},{0,-100}}),Ellipse(
          extent={{-98,96},{98,-96}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),Line(
          points={{-86,-44},{86,-44}},
          color={0,0,255},
          pattern=LinePattern.Dash),Line(
          points={{-44,-86},{44,-86}},
          color={0,0,255},
          pattern=LinePattern.Dash),Line(
          points={{-64,-72},{64,-72}},
          color={0,0,255},
          pattern=LinePattern.Dash),Line(
          points={{-78,-58},{76,-58}},
          color={0,0,255},
          pattern=LinePattern.Dash),Text(extent={{-56,94},{-56,92}}, textString="Esteam")}),
    Icon(coordinateSystem(
        preserveAspectRatio=false,
        extent={{-100,-100},{100,100}},
        grid={2,2}), graphics={Line(points={{0,90},{0,-100}}),Ellipse(
          extent={{-98,96},{98,-96}},
          lineColor={0,0,255},
          fillColor={255,255,0},
          fillPattern=FillPattern.Solid),Line(
          points={{-86,-44},{86,-44}},
          color={0,0,255},
          pattern=LinePattern.Dash),Line(
          points={{-44,-86},{44,-86}},
          color={0,0,255},
          pattern=LinePattern.Dash),Line(
          points={{-64,-72},{64,-72}},
          color={0,0,255},
          pattern=LinePattern.Dash),Line(
          points={{-78,-58},{76,-58}},
          color={0,0,255},
          pattern=LinePattern.Dash)}),
    Window(
      x=0.33,
      y=0.08,
      width=0.66,
      height=0.69),
    Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2012</b> </p>
<p><b>ThermoSysPro Version 3.0</h4>
<p>This component model is documented in Sect. 14.6 of the <a href=\"https://www.springer.com/us/book/9783030051044\">ThermoSysPro book</a>. </h4>
</html>", revisions="<html>
<p><u><b>Authors</b></u> </p>
<ul>
<li>Baligh El Hefni</li>
<li>Daniel Bouskela </li>
</ul>
</html>"));
end StaticDrum;
