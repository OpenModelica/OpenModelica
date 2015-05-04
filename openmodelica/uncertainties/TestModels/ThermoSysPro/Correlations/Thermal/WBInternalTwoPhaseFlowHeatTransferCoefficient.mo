within ThermoSysPro.Correlations.Thermal;
function WBInternalTwoPhaseFlowHeatTransferCoefficient "Internal two-phase water/steam flow heat transfer coefficient"
  input ThermoSysPro.Correlations.Misc.Pro_TwoPhaseWaterSteam hy annotation(Placement(transformation(x=-16.0, y=-64.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  input Real geomt[6] "Geometrical data vector";
  input Real Gm "Water mass velocity at the inlet (kg/m2s)";
  input Real Xmc "Steam average mass fraction";
  input Modelica.SIunits.Power flux "Heat flux";
  input ThermoSysPro.Units.AbsolutePressure Pmc "Water average pressure";
  input Modelica.SIunits.Area Si "Internal exchnage surface over dz";
  output Modelica.SIunits.CoefficientOfHeatTransfer hi "Internal heat transfer coefficient";
protected
  constant ThermoSysPro.Units.AbsolutePressure Pc=22120000.0 "Critical pressure";
  Modelica.SIunits.Density rhol "Density of the liquid phase";
  Modelica.SIunits.Density rhov "Density of the steam phase";
  Modelica.SIunits.DynamicViscosity mul "Dynamic viscosity of the liquid phase";
  Modelica.SIunits.DynamicViscosity muv "Dynamic viscosity of the vapor phase";
  Modelica.SIunits.ThermalConductivity kl "Thermal conductivity of the liquid phase";
  Modelica.SIunits.ThermalConductivity kv "Thermal conductivity of the vapor phase";
  Modelica.SIunits.SpecificHeatCapacity cpl "Specific heat capacity of the liquid phase";
  Modelica.SIunits.SpecificHeatCapacity cpv "Specific heat capacity of the vapor phase";
  Modelica.SIunits.SpecificEnergy lv "Phase transition change energy";
  Modelica.SIunits.Diameter dtin "Pipes internal diameter";
  Real Xmc0 "Steam average mass fraction";
  Real Frl "Froude number for the computation of hi";
  Real Frl0 "Froude number for the computation of hi";
  Real Xtt "Martinelli number";
  Real Rel "Reynolds number for the computation of hi";
  Real Prl "Prandtl number for the computation of hi";
  Modelica.SIunits.CoefficientOfHeatTransfer hc "Convective heat transfer coefficient for the compuation of hi";
  Real Bo "Boiling number";
  Real E "Variable for the compuation of hi";
  Real pred "Variable for the compuation of hi";
  Modelica.SIunits.CoefficientOfHeatTransfer heb "Boiling heat transfer coefficient";
  Real S "Corrective term for the removal of nucleation";
  Real Rev "Reynolds number for the computation of hi";
  Real Prv "Prandtl number for the computation of hi";
  Modelica.SIunits.CoefficientOfHeatTransfer hvi "Heat transfer coefficient for the drying of the wall";
algorithm
  rhol:=hy.rhol;
  rhov:=hy.rhov;
  lv:=hy.lv;
  cpl:=hy.cpl;
  cpv:=hy.cpv;
  mul:=hy.mul;
  muv:=hy.muv;
  kl:=hy.kl;
  kv:=hy.kv;
  dtin:=geomt[2];
  if Xmc > 0.85 then
    Xmc0:=0.85;
  else
    Xmc0:=Xmc;
  end if;
  Frl0:=Gm^2/(Modelica.Constants.g_n*dtin*rhol^2);
  if Frl0 <= 0.05 then
    Frl:=0.1;
  else
    Frl:=Frl0;
  end if;
  Xtt:=((1 - Xmc0)/Xmc0)^0.9*(rhov/rhol)^0.5*(mul/muv)^0.1;
  Rel:=Gm*dtin*(1 - Xmc0)/mul;
  Prl:=mul*cpl/kl;
  hc:=0.023*kl/dtin*Rel^0.8*Prl^0.4;
  Bo:=max(flux/Si/(lv*Gm), 0);
  E:=1 + 24000*Bo^1.16 + 1.37*(1/Xtt)^0.86;
  pred:=-Modelica.Math.log10(Pmc/Pc);
  heb:=55*((Pmc/Pc)^0.12*pred^(-0.55)*18.015^(-0.5)*max(flux/Si, 0)^0.67);
  S:=1/(1 + 1.15e-06*E^2*Rel^1.17);
  hi:=E*hc + S*heb;
  if Xmc > 0.85 then
    Rev:=Gm*dtin/muv;
    Prv:=muv*cpv/kv;
    hvi:=0.023*kv/dtin*Rev^0.8*Prv^0.4;
    hi:=hi*((1 - Xmc)/0.15) + hvi*((Xmc - 0.85)/0.15);
  end if;
  annotation(smoothOrder=2, Documentation(revisions="<html>
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
end WBInternalTwoPhaseFlowHeatTransferCoefficient;
