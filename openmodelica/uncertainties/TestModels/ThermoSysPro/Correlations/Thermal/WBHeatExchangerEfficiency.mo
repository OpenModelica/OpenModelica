within ThermoSysPro.Correlations.Thermal;
function WBHeatExchangerEfficiency "Heat exchanger efficiency"
  input Modelica.SIunits.MassFlowRate QevC "Steam mass flow rate at the inlet";
  input Modelica.SIunits.MassFlowRate QeeF "Water mass flow rate at the inlet";
  input Modelica.SIunits.SpecificHeatCapacity Cc "Hot fluid specific heat capacity";
  input Modelica.SIunits.SpecificHeatCapacity Cf "Cold fluid specific heat capacity";
  input Modelica.SIunits.CoefficientOfHeatTransfer KEG0 "Global heat transfer coefficient";
  input Modelica.SIunits.Area S0 "External exchange surface";
  input Real Phase " = 0 ou 1 one-phase flow - otherwise two-phase flow";
  output Real EC0 "Heat exchanger efficiency";
protected
  Real NUT "Number of transfer units";
  Real CpMIN "Minimum heat capacity for the two fluids";
  Real CpMAX "Maximum heat capacity for the two fluids";
  Integer TYP2 "0 = co-current, 1 = counter-current";
  Modelica.SIunits.CoefficientOfHeatTransfer KEG "Global heat exchange coefficient";
  Modelica.SIunits.Area S "External exchange surface";
  Real EC "Exchnager efficiency";
algorithm
  TYP2:=1;
  KEG:=if KEG0 > 0.0 then KEG0 else 50;
  S:=if S0 > 0.0 then S0 else 5;
  if QevC*Cc < QeeF*Cf then
    CpMIN:=noEvent(abs(QevC*Cc));
    CpMAX:=noEvent(abs(QeeF*Cf));
  else
    CpMIN:=noEvent(abs(QeeF*Cf));
    CpMAX:=noEvent(abs(QevC*Cc));
  end if;
  if Phase > 0 and Phase < 1 then
    NUT:=KEG*S/noEvent(abs(QeeF*Cf));
    EC:=1 - Modelica.Math.exp(-NUT);
  else
    NUT:=KEG*S/CpMIN;
    if abs(QevC*Cc) < abs(QeeF*Cf) then
      EC:=1.0 - Modelica.Math.exp(-abs(QeeF*Cf)/abs(QevC*Cc)*(1.0 - Modelica.Math.exp(-NUT*abs(QevC*Cc)/abs(QeeF*Cf))));
    else
      EC:=abs(QevC*Cc)/abs(QeeF*Cf)*(1.0 - Modelica.Math.exp(-abs(QeeF*Cf)/abs(QevC*Cc)*(1 - Modelica.Math.exp(-NUT))));
    end if;
  end if;
  EC0:=if EC > 0.0 then EC else 0.01;
  annotation(smoothOrder=2, Icon(coordinateSystem(extent={{-100,-100},{100,100}}), graphics={Ellipse(extent={{-100,52},{100,-88}}, fillPattern=FillPattern.Solid, lineColor={255,127,0}, fillColor={255,255,255}),Text(lineColor={0,0,255}, extent={{-82,8},{86,-40}}, textString="function", fillColor={255,127,0})}), Documentation(revisions="<html>
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
end WBHeatExchangerEfficiency;
