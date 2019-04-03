within ThermoSysPro.Properties.WaterSolution;
function Pressure_eq_TX "Equilibrium pressure of the H2O/LiBr solution as a funciton of T and Xh2o"
  input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
  input Real X "Water mass fraction in the solution";
  output ThermoSysPro.Units.AbsolutePressure Pe "Equilibrium pressure of the solution";
protected
  Real a "Coefficient directeur de la loi ln P = a (-1/T) + b";
  Real b "Ordonnée à l'origine de la loi ln P = a (-1/T) + b";
  Real A1 "Coefficient directeur borne inférieure";
  Real B1 "Ordonnée à l'origine borne inférieure";
  Real A2 "Coefficient directeur borne supérieure";
  Real B2 "Ordonnée à l'origine borne supérieure";
algorithm
  if X > 0.6 then
    A1:=5467.383523;
    A2:=5379.103071;
    B1:=26.36790788;
    B2:=25.44182656;
    a:=A1 + (A2 - A1)/(0.6 - 1)*(X - 1);
    b:=B1 + (B2 - B1)/(0.6 - 1)*(X - 1);
  elseif X > 0.55 then
    A1:=5379.103071;
    A2:=5304.170432;
    B1:=25.44182656;
    B2:=24.93793936;
    a:=A1 + (A2 - A1)/(0.55 - 0.6)*(X - 0.6);
    b:=B1 + (B2 - B1)/(0.55 - 0.6)*(X - 0.6);

  elseif X > 0.5 then
    A1:=5304.170432;
    A2:=5438.215285;
    B1:=24.93793936;
    B2:=24.96552904;
    a:=A1 + (A2 - A1)/(0.5 - 0.55)*(X - 0.55);
    b:=B1 + (B2 - B1)/(0.5 - 0.55)*(X - 0.55);

  elseif X > 0.45 then
    A1:=5438.215285;
    A2:=5624.954368;
    B1:=24.96552904;
    B2:=25.04073086;
    a:=A1 + (A2 - A1)/(0.45 - 0.5)*(X - 0.5);
    b:=B1 + (B2 - B1)/(0.45 - 0.5)*(X - 0.5);

  elseif X > 0.4 then
    A1:=5624.954368;
    A2:=5862.125101;
    B1:=25.04073086;
    B2:=25.2166991;
    a:=A1 + (A2 - A1)/(0.4 - 0.45)*(X - 0.45);
    b:=B1 + (B2 - B1)/(0.4 - 0.45)*(X - 0.45);

  elseif X > 0.35 then
    A1:=5862.125101;
    A2:=6036.317803;
    B1:=25.2166991;
    B2:=25.22194134;
    a:=A1 + (A2 - A1)/(0.35 - 0.4)*(X - 0.4);
    b:=B1 + (B2 - B1)/(0.35 - 0.4)*(X - 0.4);
  else
    A1:=6036.317803;
    A2:=5904.887091;
    B1:=25.22194134;
    B2:=24.38414762;
    a:=A1 + (A2 - A1)/(0.3 - 0.35)*(X - 0.35);
    b:=B1 + (B2 - B1)/(0.3 - 0.35)*(X - 0.35);
  end if;
  Pe:=exp(a*(-1/T) + b);
  annotation(smoothOrder=2, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end Pressure_eq_TX;
