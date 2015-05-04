within ThermoSysPro.Properties.C3H3F5;
function C3H3F5_Ps "11133-C3H3F5 physical properties as a function of P and s"
  input ThermoSysPro.Units.AbsolutePressure P "Pressure";
  input Modelica.SIunits.SpecificEntropy s "Specific entropy";
  output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ps props annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
  ThermoSysPro.Units.AbsolutePressure Psc "Critical pressure";
  ThermoSysPro.Units.AbsolutePressure Pcalc "Variable for the computation of the pressure";
  Modelica.SIunits.SpecificEntropy scalc "Variable for the computation of the specific entropy";
  ThermoSysPro.Units.SpecificEnthalpy hsatL "Boiling specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hsatV "Condensation specific enthalpy";
  Modelica.SIunits.SpecificEntropy ssatL "Boiling specific entropy";
  Modelica.SIunits.SpecificEntropy ssatV "Condensation specific entropy";
  Real x "Vapor mass fraction";
  Real A;
  Real B;
  Real C;
protected
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation(Placement(transformation(x=-50.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
algorithm
  Psc:=3640000;
  if P > Psc then
    Pcalc:=Psc/100000;
  elseif P <= 0 then
    Pcalc:=1/100000;
  else
    Pcalc:=P/100000;
  end if;
  if s > 2520 then
    scalc:=2.52;
  elseif s < 600 then
    scalc:=0.6;
  else
    scalc:=s/1000;
  end if;
  hsatV:=-2.74e-06*Pcalc^6 + 0.00032217*Pcalc^5 - 0.01489673*Pcalc^4 + 0.3425803*Pcalc^3 - 4.15381744*Pcalc^2 + 27.64876596*Pcalc + 385.22149853;
  hsatL:=-3.9275e-06*Pcalc^6 + 0.000478004*Pcalc^5 - 0.0227439765*Pcalc^4 + 0.5370471515*Pcalc^3 - 6.6496487588*Pcalc^2 + 46.8685173786*Pcalc + 166.7823742593;
  ssatV:=1.7e-09*Pcalc^6 - 2.159e-07*Pcalc^5 + 1.0223e-05*Pcalc^4 - 0.0002295813*Pcalc^3 + 0.0023692545*Pcalc^2 - 0.0062966866*Pcalc + 1.7667560947;
  ssatL:=-1.64e-08*Pcalc^6 + 1.9814e-06*Pcalc^5 - 9.34768e-05*Pcalc^4 + 0.002182751*Pcalc^3 - 0.0265228817*Pcalc^2 + 0.1740890297*Pcalc + 0.8685336198;
  if scalc >= ssatL and scalc <= ssatV then
    x:=(scalc - ssatL)/(ssatV - ssatL);
    h:=1000*(hsatL*(1 - x) + hsatV*x);
  elseif scalc < ssatL then
    h:=1000*(112.482*scalc^2 + 50.525*scalc + 39.292);
    if h > hsatL then
      h:=1000*hsatL;
    end if;
  else
    A:=-0.0396219*Pcalc^2 + 0.2873498*Pcalc + 185.5998054;
    B:=-0.1114991*Pcalc^2 + 12.841798*Pcalc - 415.1029137;
    C:=0.1219352*Pcalc^2 - 13.803117*Pcalc + 540.557801;
    h:=1000*(A*scalc^2 + B*scalc + C);
    if h < hsatV then
      h:=1000*hsatV;
    end if;
  end if;
  pro:=C3H3F5_Ph(P, h);
  props.T:=pro.T;
  props.d:=pro.d;
  props.u:=pro.u;
  props.h:=h;
  props.cp:=pro.cp;
  props.x:=x;
  annotation(smoothOrder=2, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end C3H3F5_Ps;
