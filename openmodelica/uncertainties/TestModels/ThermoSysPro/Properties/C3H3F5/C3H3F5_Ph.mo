within ThermoSysPro.Properties.C3H3F5;
function C3H3F5_Ph "11133-C3H3F5 physical properties as a function of P and h"
  input ThermoSysPro.Units.AbsolutePressure P "Pressure";
  input ThermoSysPro.Units.SpecificEnthalpy h "Specific enthalpy";
  output ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph pro annotation(Placement(transformation(x=-90.0, y=90.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  ThermoSysPro.Units.AbsoluteTemperature Tsat "Saturation temperature";
  ThermoSysPro.Units.AbsolutePressure Psc "Critical pressure";
  ThermoSysPro.Units.AbsolutePressure Pcalc "Variable for the computation of the pressure";
  ThermoSysPro.Units.SpecificEnthalpy hcalc "Variable for the computation of the specific  enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hsatL "Boiling specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hsatV "Condensation specific enthalpy";
  Modelica.SIunits.SpecificEntropy ssatL "Boiling specific entropy";
  Modelica.SIunits.SpecificEntropy ssatV "Condensation specific entropy";
  Modelica.SIunits.Density rhoSatL "Boiling density";
  Modelica.SIunits.Density rhoSatV "Condensation density";
  Real A1;
  Real B1;
  Real C1;
  Real A2;
  Real B2;
  Real C2;
  Real D2;
  Real A3;
  Real B3;
  Real C3;
algorithm
  Psc:=3640000;
  if P > Psc then
    Pcalc:=Psc/100000;
  elseif P <= 0 then
    Pcalc:=1/100000;
  else
    Pcalc:=P/100000;
  end if;
  if h > 640000 then
    hcalc:=640;
  elseif h < 100000 then
    hcalc:=100;
  else
    hcalc:=h/1000;
  end if;
  hsatV:=-2.74e-06*Pcalc^6 + 0.00032217*Pcalc^5 - 0.01489673*Pcalc^4 + 0.3425803*Pcalc^3 - 4.15381744*Pcalc^2 + 27.64876596*Pcalc + 385.22149853;
  hsatL:=-3.9275e-06*Pcalc^6 + 0.000478004*Pcalc^5 - 0.0227439765*Pcalc^4 + 0.5370471515*Pcalc^3 - 6.6496487588*Pcalc^2 + 46.8685173786*Pcalc + 166.7823742593;
  ssatV:=1000*(1.7e-09*Pcalc^6 - 2.159e-07*Pcalc^5 + 1.0223e-05*Pcalc^4 - 0.0002295813*Pcalc^3 + 0.0023692545*Pcalc^2 - 0.0062966866*Pcalc + 1.7667560947);
  ssatL:=1000*(-1.64e-08*Pcalc^6 + 1.9814e-06*Pcalc^5 - 9.34768e-05*Pcalc^4 + 0.002182751*Pcalc^3 - 0.0265228817*Pcalc^2 + 0.1740890297*Pcalc + 0.8685336198);
  rhoSatL:=5.7803e-06*Pcalc^6 - 0.0007528646*Pcalc^5 + 0.03773738*Pcalc^4 - 0.9314090824*Pcalc^3 + 11.9184348938*Pcalc^2 - 89.9582798898*Pcalc + 1467.5902188299;
  rhoSatV:=2.07e-06*Pcalc^6 - 0.00019163*Pcalc^5 + 0.00675913*Pcalc^4 - 0.10924667*Pcalc^3 + 0.84661954*Pcalc^2 + 2.83415571*Pcalc + 2.12959146;
  Tsat:=-3.3655e-06*Pcalc^6 + 0.0004044854*Pcalc^5 - 0.0190328128*Pcalc^4 + 0.4443722095*Pcalc^3 - 5.4337547883*Pcalc^2 + 36.7572359309*Pcalc + 246.4280421048;
  if hcalc >= hsatL and hcalc <= hsatV then
    pro.T:=Tsat;
    pro.x:=(hcalc - hsatL)/(hsatV - hsatL);
    pro.d:=rhoSatL*(1 - pro.x) + rhoSatV*pro.x;
    pro.s:=ssatL*(1 - pro.x) + ssatV*pro.x;
  elseif hcalc < hsatL then
    pro.T:=-0.0005311*hcalc^2 + 0.9990391*hcalc + 93.9602333;
    if pro.T > Tsat then
      pro.T:=Tsat;
    end if;
    pro.x:=0;
    pro.d:=-1.54e-05*hcalc^3 + 0.0095634*hcalc^2 - 3.8184877*hcalc + 1916.6958695;
    if pro.d < rhoSatL then
      pro.d:=rhoSatL;
    end if;
    pro.s:=1000*(-3.7e-06*hcalc^2 + 0.00516*hcalc + 0.1002293);
    if pro.s > ssatL then
      pro.s:=ssatL;
    end if;
  else
    A1:=6.98e-05*Pcalc - 0.0008618;
    B1:=-0.0858201*Pcalc + 1.8849272;
    C1:=27.0570743*Pcalc - 353.7594967;
    pro.T:=A1*hcalc^2 + B1*hcalc + C1;
    if pro.T < Tsat then
      pro.T:=Tsat;
    end if;
    pro.x:=1;
    A2:=-9.58e-08*Pcalc^2 + 6.742e-07*Pcalc - 2.691e-07;
    B2:=0.0001689*Pcalc^2 - 0.0011644*Pcalc + 0.000469;
    C2:=-0.0995131*Pcalc^2 + 0.6639841*Pcalc - 0.2724718;
    D2:=19.6224804*Pcalc^2 - 121.4944333*Pcalc + 52.8361115;
    pro.d:=A2*hcalc^3 + B2*hcalc^2 + C2*hcalc + D2;
    if pro.d > rhoSatV then
      pro.d:=rhoSatV;
    end if;
    A3:=-3.2e-09*Pcalc^2 + 1.779e-07*Pcalc - 3.7134e-06;
    B3:=3.4e-06*Pcalc^2 - 0.0001957*Pcalc + 0.0064718;
    C3:=-0.0001958*Pcalc^2 + 0.0194928*Pcalc - 0.1696592;
    pro.s:=1000*(A3*hcalc^2 + B3*hcalc + C3);
    if pro.s < ssatV then
      pro.s:=ssatV;
    end if;
  end if;
  annotation(smoothOrder=2, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end C3H3F5_Ph;
