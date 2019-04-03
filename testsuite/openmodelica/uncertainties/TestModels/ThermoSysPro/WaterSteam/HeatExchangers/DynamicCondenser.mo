within ThermoSysPro.WaterSteam.HeatExchangers;
model DynamicCondenser "Dynamic condenser"
  parameter Modelica.SIunits.Volume Vc=4510 "Condenser total volume";
  parameter Real Vf0=0.066 "Fraction of initial liquid volume in the condenser (0 < Vf0 < 1)";
  parameter ThermoSysPro.Units.AbsolutePressure P0c=9326 "Initial pressure in the condenser";
  parameter Modelica.SIunits.Area Ac=200 "Condenser cross-sectional area";
  parameter Modelica.SIunits.Length Lc=13.5 "Length of the cooling pipes";
  parameter Modelica.SIunits.Diameter Dc=0.018 "Internal diameter of the cooling pipes";
  parameter Modelica.SIunits.Thickness ec=0.002 "Thickness of the cooling pipes";
  parameter Integer ntubesc=72044 "Number of cooling pipes in parallel";
  parameter Modelica.SIunits.SpecificHeatCapacity cp=460 "Specific heat capacity of the metal of the cooling pipes";
  parameter Modelica.SIunits.Density rho=7900 "Density of the metal of the cooling pipes";
  parameter Modelica.SIunits.CoefficientOfHeatTransfer hc=25000 "Heat transfer coefficient between the vapor and the cooling pipes";
  ThermoSysPro.WaterSteam.Volumes.TwoPhaseVolume condenser(V=Vc, Vf0=Vf0, A=Ac, P0=P0c, Vv(start=2000), Tv(start=320), P(start=9326, fixed=false), hl(start=200000.0), hv(fixed=false, start=1500000.0), steady_state=false) annotation(Placement(transformation(x=0.0, y=20.0, scale=0.2, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  annotation(Diagram, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Rectangle(extent={{100,20},{80,-60}}, lineColor={0,0,255}, fillColor={223,159,159}, fillPattern=FillPattern.Solid),Rectangle(extent={{-100,20},{-80,-60}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,191,255}),Rectangle(extent={{-20,6},{-80,0}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,191,255}),Rectangle(extent={{-20,-18},{-80,-24}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,191,255}),Rectangle(extent={{-20,-40},{-80,-46}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={127,191,255}),Rectangle(extent={{80,6},{20,0}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159}),Rectangle(extent={{80,-40},{20,-46}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159}),Rectangle(extent={{80,-18},{20,-24}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={223,159,159}),Rectangle(extent={{30,-18},{-30,-24}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={159,159,223}),Rectangle(extent={{30,-40},{-30,-46}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={159,159,223}),Rectangle(extent={{30,6},{-30,0}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, fillColor={159,159,223}),Line(points={{-20,100},{20,100},{100,20},{100,-100},{-100,-100},{-100,20},{-20,100}}, color={0,0,255}, thickness=0.5),Rectangle(extent={{-100,-72},{100,-100}}, fillPattern=FillPattern.Solid, lineColor={0,0,255}, lineThickness=0.5, fillColor={127,191,255})}), Documentation(revisions="<html>
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
  ThermoSysPro.WaterSteam.HeatExchangers.DynamicOnePhaseFlowPipe pipe(L=Lc, ntubes=ntubesc, option_temperature=2, advection=true, h0=fill(119720.0, 1), mode=0, continuous_flow_reversal=true, D=Dc, Ns=1) annotation(Placement(transformation(x=-40.0, y=-20.0, scale=0.2, aspectRatio=0.7, flipHorizontal=false, flipVertical=false, rotation=-0.0)));
  Connectors.FluidInletI C1vap "Vapor inlet" annotation(Placement(transformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutletI C2ex "Condensed water extraction outlet" annotation(Placement(transformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=0.0, y=-100.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInletI Ce1 "Cooling water inlet" annotation(Placement(transformation(x=-100.0, y=-20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=-20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidOutletI Ce2 "Cooling water outlet" annotation(Placement(transformation(x=100.0, y=-20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=100.0, y=-20.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.InstrumentationAndControl.Connectors.OutputReal sortieReelle annotation(Placement(transformation(x=110.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=110.0, y=-70.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  Connectors.FluidInletI C1 "Extra water inlet" annotation(Placement(transformation(x=-100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false), iconTransformation(x=-100.0, y=60.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
equation
  if cardinality(C1) == 1 then
    C1.Q=0;
    C1.h=100000.0;
    C1.b=true;
  end if;
  connect(Ce1,pipe.C1) annotation(Line(points={{-100,-20},{-60,-20}}));
  connect(pipe.C2,Ce2) annotation(Line(points={{-20,-20},{-2,-20},{-2,-18},{2,-18},{2,-20},{58,-20},{58,-18},{62,-18},{62,-20},{100,-20}}, color={0,0,255}));
  connect(C1vap,condenser.Cv) annotation(Line(points={{0,100},{0,40}}));
  connect(condenser.Cl,C2ex) annotation(Line(points={{0,0},{0,-100}}, color={0,0,255}));
  connect(C1,condenser.Ce) annotation(Line(points={{-100,60},{-60,60},{-60,20},{-20,20}}));
  connect(condenser.Cth,pipe.CTh[1]) annotation(Line(points={{0,24},{-40,24},{-40,-15.8}}, color={191,95,0}));
  connect(condenser.yLevel,sortieReelle) annotation(Line(points={{22,20},{60,20},{60,-70},{110,-70}}));
end DynamicCondenser;
