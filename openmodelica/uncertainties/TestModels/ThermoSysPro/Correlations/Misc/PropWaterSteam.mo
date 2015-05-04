within ThermoSysPro.Correlations.Misc;
function PropWaterSteam "Computation of the water/steam properties"
  input ThermoSysPro.Units.AbsolutePressure Pmc "Water/steam average pressure";
  input ThermoSysPro.Units.SpecificEnthalpy Hmc "Water/steam average specific enthalpy";
  input Real Xmc "Steam average mass fraction";
  output ThermoSysPro.Correlations.Misc.Pro_TwoPhaseWaterSteam hy annotation(Placement(transformation(x=10.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
protected
  constant ThermoSysPro.Units.AbsolutePressure Pc=22120000.0 "Critical pressure";
  ThermoSysPro.Units.AbsoluteTemperature Tsat1 "Saturation temperature at Pmc";
  ThermoSysPro.Units.AbsoluteTemperature T "Water/steam mixture temperature";
  ThermoSysPro.Units.SpecificEnthalpy hlv "Water/steam mixture specific enthalpy";
  Modelica.SIunits.Density rholv "Water/steam mixture density";
  Modelica.SIunits.Density rhol "Water density";
  Modelica.SIunits.Density rhov "Steam density";
  ThermoSysPro.Units.SpecificEnthalpy hl "Water specific enthalpy";
  ThermoSysPro.Units.SpecificEnthalpy hv "Steam specific enthalpy";
  Modelica.SIunits.SpecificEnergy lv "Phase transition energy";
  Modelica.SIunits.SpecificHeatCapacity cpl "Water specific heat capacity";
  Modelica.SIunits.SpecificHeatCapacity cpv "Steam specific heat capacity";
  Modelica.SIunits.DynamicViscosity mul "Water dynamic viscosity";
  Modelica.SIunits.DynamicViscosity muv "Steam dynamic viscosity";
  Modelica.SIunits.ThermalConductivity kl "Water thermal conductivity";
  Modelica.SIunits.ThermalConductivity kv "Steam thermal conductivity";
  Modelica.SIunits.SurfaceTension tsl "Water surface tensiton";
protected
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat vsatm annotation(Placement(transformation(x=-30.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.PropThermoSat lsatm annotation(Placement(transformation(x=10.0, y=50.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
  ThermoSysPro.Properties.WaterSteam.Common.ThermoProperties_ph prol annotation(Placement(transformation(x=-30.0, y=10.0, scale=0.1, aspectRatio=1.0, flipHorizontal=false, flipVertical=false)));
algorithm
  Tsat1:=ThermoSysPro.Properties.WaterSteam.BaseIF97.Basic.tsat(Pmc);
  (lsatm,vsatm):=ThermoSysPro.Properties.WaterSteam.IF97.Water_sat_P(Pmc);
  prol:=ThermoSysPro.Properties.WaterSteam.IF97.Water_Ph(Pmc, Hmc, 0);
  if 0 < Xmc and Xmc < 1 and Pmc < Pc then
    T:=Tsat1;
    hlv:=Hmc;
    rholv:=prol.d;
    rhol:=lsatm.rho;
    rhov:=vsatm.rho;
    hl:=lsatm.h;
    hv:=vsatm.h;
    cpl:=lsatm.cp;
    cpv:=vsatm.cp;
  else
    T:=prol.T;
    rhol:=prol.d;
    rhov:=rhol;
    hl:=Hmc;
    hv:=hl;
    cpl:=prol.cp;
    cpv:=cpl;
  end if;
  lv:=hv - hl;
  mul:=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rhol, T);
  muv:=ThermoSysPro.Properties.WaterSteam.IF97.DynamicViscosity_rhoT(rhov, T);
  kl:=ThermoSysPro.Properties.WaterSteam.IF97.ThermalConductivity_rhoT(rhol, T, Pmc, 0);
  kv:=ThermoSysPro.Properties.WaterSteam.IF97.ThermalConductivity_rhoT(rhov, T, Pmc, 0);
  if Pmc > 22000000.0 then
    tsl:=6e-06;
  elseif abs(Pmc) < 1e-06 then
    tsl:=0.05;
  else
    tsl:=ThermoSysPro.Properties.WaterSteam.IF97.SurfaceTension_T(Tsat1);
  end if;
  hy.rhol:=rhol;
  hy.rhov:=rhov;
  hy.hl:=hl;
  hy.hl:=hv;
  hy.lv:=lv;
  hy.cpl:=cpl;
  hy.cpv:=cpv;
  hy.mul:=mul;
  hy.muv:=muv;
  hy.kl:=kl;
  hy.kv:=kv;
  hy.tsl:=tsl;
  hy.rholv:=rholv;
  hy.hlv:=hlv;
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
end PropWaterSteam;
