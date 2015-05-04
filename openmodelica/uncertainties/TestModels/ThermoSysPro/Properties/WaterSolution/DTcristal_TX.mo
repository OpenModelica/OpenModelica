within ThermoSysPro.Properties.WaterSolution;
function DTcristal_TX "Temperature difference with the cristallisation of the H2O/LiBr solution as a function of T et Xh2o"
  input ThermoSysPro.Units.AbsoluteTemperature T "Temperature";
  input Real X "Water mass fraction in the solution";
  output ThermoSysPro.Units.DifferentialTemperature DTc "Temperature difference with cristallisation : > 0 = no cristallisation ; < 0 = cristallisation";
protected
  Real Xi "LiBr mass fraction in the solution";
  ThermoSysPro.Units.AbsoluteTemperature Tc "Temperature in Celsius";
  ThermoSysPro.Units.AbsoluteTemperature Tcrist "Cristallisation temperature in Celsius";
algorithm
  Tc:=T - 273.15;
  Xi:=100*(1 - X);
  if Xi < 0 then
    Tcrist:=0;
  elseif Xi < 20 then
    Tcrist:=-0.1*Xi - 0.025*Xi*Xi;

  elseif Xi < 39.2 then
    Tcrist:=-24.804347826087 + 2.43369565217391*Xi - 0.0896739130434783*Xi*Xi;

  elseif Xi < 49.2 then
    Tcrist:=-434.48275862069 + 15.3685385878489*Xi - 0.15303776683087*Xi*Xi;

  elseif Xi < 57.37 then
    Tcrist:=-1286.15172413793 + 41.6625287356322*Xi - 0.335632183908046*Xi*Xi;

  elseif Xi < 65.16 then
    Tcrist:=-1336.1 + 39.043*Xi - 0.2748*Xi*Xi;

  elseif Xi <= 70 then
    Tcrist:=-6266.7 + 175.74*Xi - 1.2114*Xi*Xi;
  else
    Tcrist:=1000;
  end if;
  DTc:=Tc - Tcrist;
  annotation(smoothOrder=2, Documentation(info="<html>
<p><b>Copyright &copy; EDF 2002 - 2010</b></p>
</HTML>
<html>
<p><b>ThermoSysPro Version 2.0</b></p>
</HTML>
"));
end DTcristal_TX;
