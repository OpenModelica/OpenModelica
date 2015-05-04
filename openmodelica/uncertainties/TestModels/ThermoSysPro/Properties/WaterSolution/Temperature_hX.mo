within ThermoSysPro.Properties.WaterSolution;
function Temperature_hX "Temperature of the H2O/LiBr solution as a function of h et Xh2o"
  input ThermoSysPro.Units.SpecificEnthalpy h "Specific enthazlpy of the solution";
  input Real X "Water mass fraction in the solution";
  output ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
protected
  Real A0;
  Real A1;
  Real A2;
algorithm
  A0:=7073.041837*X*X*X*X*X - 26597.06323*X*X*X*X + 39689.57688*X*X*X - 29426.61413*X*X + 10845.50019*X - 1311.645958;
  A1:=-0.05155160151*X*X*X*X*X + 0.1831371685*X*X*X*X - 0.2547248076*X*X*X + 0.1733914006*X*X - 0.05828427688*X + 0.008271482051;
  A2:=-2.81645083e-07*X*X*X*X*X*X + 1.181863048e-06*X*X*X*X*X - 2.027614981e-06*X*X*X*X + 1.81835959e-06*X*X*X - 8.983047414e-07*X*X + 2.318831106e-07*X - 2.454384671e-08;
  T:=A2*h*h + A1*h + A0;
  annotation(smoothOrder=2, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end Temperature_hX;
