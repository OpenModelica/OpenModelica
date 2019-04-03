// status: correct
// Bug #2695

package Modelica
  extends Modelica.Icons.Package;

  package Icons
    extends Icons.Package;

    partial package Package  end Package;
  end Icons;

  package SIunits
    extends Modelica.Icons.Package;
    type Pressure = Real(final quantity = "Pressure", final unit = "Pa", displayUnit = "bar");
    type AbsolutePressure = Pressure(min = 0.0, nominal = 1e5);
    type ThermodynamicTemperature = Real(final quantity = "ThermodynamicTemperature", final unit = "K", min = 0.0, start = 288.15, nominal = 300, displayUnit = "degC");
    type Temperature = ThermodynamicTemperature;
    type MassFraction = Real(final quantity = "MassFraction", final unit = "1", min = 0, max = 1);
  end SIunits;
end Modelica;

package TestTILMediaOSMC
  record BaseGas
    constant Boolean fixedMixingRatio annotation(HideResult = true);
    constant Integer nc_propertyCalculation(min = 1) annotation(HideResult = true);
    final constant Integer nc = if fixedMixingRatio then 1 else nc_propertyCalculation annotation(Evaluate = true, HideResult = true);
    constant String[nc_propertyCalculation] gasNames;
    constant Real[nc_propertyCalculation] mixingRatio_propertyCalculation annotation(HideResult = true);
    constant Real[nc] defaultMixingRatio = if fixedMixingRatio then {1} else mixingRatio_propertyCalculation annotation(HideResult = true);
    constant Real[nc - 1] xi_default = defaultMixingRatio[1:end - 1] / sum(defaultMixingRatio) annotation(HideResult = true);
    constant Integer condensingIndex annotation(HideResult = true);
    constant Integer ID = 0 annotation(HideResult = true);
  end BaseGas;

  record DryAir
    extends TestTILMediaOSMC.BaseGas(final fixedMixingRatio = false, final nc_propertyCalculation = 1, final gasNames = {""}, final mixingRatio_propertyCalculation = {1}, final condensingIndex = 0);
  end DryAir;

  record MoistAir_nc2
    extends TestTILMediaOSMC.BaseGas(final fixedMixingRatio = false, final nc_propertyCalculation = 2, final gasNames = {"VDIWA.Water", "VDIWA.DryAir"}, final condensingIndex = 1, final mixingRatio_propertyCalculation = {0.001, 1});
  end MoistAir_nc2;

  model gas_pT
    replaceable parameter TestTILMediaOSMC.BaseGas gasType constrainedby TestTILMediaOSMC.BaseGas;
    input Modelica.SIunits.AbsolutePressure p;
    input Modelica.SIunits.Temperature T;
    input Modelica.SIunits.MassFraction[gasType.nc - 1] xi = gasType.xi_default;
  end gas_pT;

  model TestGas_error
    Modelica.SIunits.MassFraction[gas_pT1.gasType.nc - 1] xi1;
    Modelica.SIunits.MassFraction[gas_pT2.gasType.nc - 1] xi2;
    gas_pT gas_pT1(p = 10, T = 10, xi = xi1, redeclare TestTILMediaOSMC.MoistAir_nc2 gasType);
    gas_pT gas_pT2(p = 10, T = 10, xi = xi2, redeclare TestTILMediaOSMC.DryAir gasType);
  equation
    xi1 = gas_pT1.gasType.xi_default;
    xi2 = gas_pT2.gasType.xi_default;
  end TestGas_error;
end TestTILMediaOSMC;

model TestGas_error
  extends TestTILMediaOSMC.TestGas_error;
end TestGas_error;

// Result:
// function TestTILMediaOSMC.DryAir "Automatically generated record constructor for TestTILMediaOSMC.DryAir"
//   protected Boolean fixedMixingRatio = false;
//   protected Integer nc_propertyCalculation(min = 1) = 1;
//   protected Integer nc = 1;
//   protected String[1] gasNames = {""};
//   protected Real[1] mixingRatio_propertyCalculation = {1.0};
//   protected Real[1] defaultMixingRatio = {1.0};
//   protected Real[0] xi_default = {};
//   protected Integer condensingIndex = 0;
//   protected Integer ID = 0;
//   output DryAir res;
// end TestTILMediaOSMC.DryAir;
//
// function TestTILMediaOSMC.MoistAir_nc2 "Automatically generated record constructor for TestTILMediaOSMC.MoistAir_nc2"
//   protected Boolean fixedMixingRatio = false;
//   protected Integer nc_propertyCalculation(min = 1) = 2;
//   protected Integer nc = 2;
//   protected String[2] gasNames = {"VDIWA.Water", "VDIWA.DryAir"};
//   protected Real[2] mixingRatio_propertyCalculation = {0.001, 1.0};
//   protected Real[2] defaultMixingRatio = {0.001, 1.0};
//   protected Real[1] xi_default = {0.0009990009990009992};
//   protected Integer condensingIndex = 1;
//   protected Integer ID = 0;
//   output MoistAir_nc2 res;
// end TestTILMediaOSMC.MoistAir_nc2;
//
// class TestGas_error
//   Real xi1[1](quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   constant Boolean gas_pT1.gasType.fixedMixingRatio = false;
//   constant Integer gas_pT1.gasType.nc_propertyCalculation(min = 1) = 2;
//   final constant Integer gas_pT1.gasType.nc = 2;
//   constant String gas_pT1.gasType.gasNames[1] = "VDIWA.Water";
//   constant String gas_pT1.gasType.gasNames[2] = "VDIWA.DryAir";
//   constant Real gas_pT1.gasType.mixingRatio_propertyCalculation[1] = 0.001;
//   constant Real gas_pT1.gasType.mixingRatio_propertyCalculation[2] = 1.0;
//   constant Real gas_pT1.gasType.defaultMixingRatio[1] = 0.001;
//   constant Real gas_pT1.gasType.defaultMixingRatio[2] = 1.0;
//   constant Real gas_pT1.gasType.xi_default[1] = 0.0009990009990009992;
//   constant Integer gas_pT1.gasType.condensingIndex = 1;
//   constant Integer gas_pT1.gasType.ID = 0;
//   Real gas_pT1.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 10.0;
//   Real gas_pT1.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 10.0;
//   Real gas_pT1.xi[1](quantity = "MassFraction", unit = "1", min = 0.0, max = 1.0);
//   constant Boolean gas_pT2.gasType.fixedMixingRatio = false;
//   constant Integer gas_pT2.gasType.nc_propertyCalculation(min = 1) = 1;
//   final constant Integer gas_pT2.gasType.nc = 1;
//   constant String gas_pT2.gasType.gasNames[1] = "";
//   constant Real gas_pT2.gasType.mixingRatio_propertyCalculation[1] = 1.0;
//   constant Real gas_pT2.gasType.defaultMixingRatio[1] = 1.0;
//   constant Integer gas_pT2.gasType.condensingIndex = 0;
//   constant Integer gas_pT2.gasType.ID = 0;
//   Real gas_pT2.p(quantity = "Pressure", unit = "Pa", displayUnit = "bar", min = 0.0, nominal = 100000.0) = 10.0;
//   Real gas_pT2.T(quantity = "ThermodynamicTemperature", unit = "K", displayUnit = "degC", min = 0.0, start = 288.15, nominal = 300.0) = 10.0;
// equation
//   gas_pT1.xi = {xi1[1]};
//   xi1[1] = 0.0009990009990009992;
// end TestGas_error;
// endResult
