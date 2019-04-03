within ThermoSysPro.Correlations.Thermal;
function WBFlueGasesHeatTransferCoefficient "Flue gases heat transfer coefficient"
  input Real propf[4] "Flue gases properties vector";
  input Modelica.SIunits.MassFlowRate Qef "Flue gases mass flow rate at the inlet";
  input ThermoSysPro.Units.AbsolutePressure Pmf "Flue gases average pressure";
  input ThermoSysPro.Units.AbsoluteTemperature Tmf "Flue gases average temperature";
  input Real XefCO2 "CO2 mass fraction at the inlet";
  input Real XefH2O "H2O mass fraction at the inlet";
  input Modelica.SIunits.PathLength dz "Step in the z direction";
  input Modelica.SIunits.Length long "Wall zone length";
  input Modelica.SIunits.Length prof "Wall zone width";
  input ThermoSysPro.Units.AbsoluteTemperature Tpext "External wall temperature";
  input Real fvd=0 "Particles volume fraction";
  input Real emimur=0.1 "Wall emissivity";
  output Modelica.SIunits.CoefficientOfHeatTransfer hf "Global heat transfer coefficient";
protected
  Modelica.SIunits.ThermalConductivity condf "Flue gases thermal conductivity";
  Modelica.SIunits.SpecificHeatCapacity cpf "Flue gases specific heat capacity";
  Modelica.SIunits.DynamicViscosity muf "Flue gases dynamic viscosity";
  Real Ref "Flue gases Reynolds number";
  Real Prf "Flue gases Prandtl number";
  Modelica.SIunits.CoefficientOfHeatTransfer hc "Flue gases convective heat transfer coefficient";
  Modelica.SIunits.Volume volumg "Gas volume";
  Modelica.SIunits.Area senveng "Gas total envelope surface";
  Modelica.SIunits.Radius rop "Average optical radius between pipes";
  Real EG " ";
  Real ES " ";
  Real emigaz "Gas emissivity";
  Real emigaz0 "Gas emissivity";
  Modelica.SIunits.CoefficientOfHeatTransfer hr "Radiation heat transfer coefficient";
algorithm
  condf:=propf[1];
  cpf:=propf[2];
  muf:=propf[3];
  Ref:=Qef*dz/(muf*prof*long);
  Prf:=muf*cpf/condf;
  if Ref <= 300000.0 then
    hc:=0.66*Ref^0.5*Prf^0.333*condf/dz;
  else
    hc:=0.036*Ref^0.8*Prf^0.333*condf/dz;
  end if;
  volumg:=dz*long*prof;
  senveng:=2*dz*long + 2*dz*prof + 2*long*prof;
  rop:=3.6*volumg/senveng;
  (EG,ES,emigaz0):=ThermoSysPro.Properties.FlueGases.FlueGases_Absorb(XefCO2*Pmf, XefH2O*Pmf, fvd, rop, Tmf);
  if emigaz0 < 0.0001 then
    emigaz:=0.0001;
  elseif emigaz0 > 1 then
    emigaz:=0.99;
  else
    emigaz:=emigaz0;
  end if;
  hr:=5.68e-08/(1/emigaz + (1 - emimur)/emimur)*(Tmf^2 + Tpext^2)*(Tmf + Tpext);
  hf:=hc + hr;
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
end WBFlueGasesHeatTransferCoefficient;
