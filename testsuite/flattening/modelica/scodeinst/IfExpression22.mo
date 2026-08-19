// name: IfExpression22
// keywords:
// status: correct
//

function specificEnthalpy_pTxi
  input BaseGas gasType;
  output Real h = 0;
end specificEnthalpy_pTxi;

record BaseGas
  constant Boolean fixedMixingRatio;
  final constant Integer nc = if fixedMixingRatio then 1 else 3;
  final parameter Real defaultMixingRatio[nc] = if fixedMixingRatio then {1} else ones(nc);
end BaseGas;

record FlueGasTILMedia
  extends BaseGas(final fixedMixingRatio = false);
end FlueGasTILMedia;

model IfExpression22
  parameter FlueGasTILMedia flueGasModel;
  inner parameter BaseGas medium = flueGasModel;
  final parameter Real h_start = specificEnthalpy_pTxi(medium);
end IfExpression22;

// Result:
// function BaseGas "Automatically generated record constructor for BaseGas"
//   input Boolean fixedMixingRatio;
//   protected Integer nc = if fixedMixingRatio then 1 else 3;
//   protected Real[nc] defaultMixingRatio = if fixedMixingRatio then {1.0} else fill(1.0, nc);
//   output BaseGas res;
// end BaseGas;
//
// function specificEnthalpy_pTxi
//   input BaseGas gasType;
//   output Real h = 0.0;
// end specificEnthalpy_pTxi;
//
// class IfExpression22
//   final constant Boolean flueGasModel.fixedMixingRatio = false;
//   final constant Integer flueGasModel.nc = 3;
//   final parameter Real flueGasModel.defaultMixingRatio[1] = /*Integer*/(1.0);
//   final parameter Real flueGasModel.defaultMixingRatio[2] = /*Integer*/(1.0);
//   final parameter Real flueGasModel.defaultMixingRatio[3] = /*Integer*/(1.0);
//   constant Boolean medium.fixedMixingRatio = false;
//   final constant Integer medium.nc = 3;
//   final parameter Real medium.defaultMixingRatio[1] = flueGasModel.defaultMixingRatio[1];
//   final parameter Real medium.defaultMixingRatio[2] = flueGasModel.defaultMixingRatio[2];
//   final parameter Real medium.defaultMixingRatio[3] = flueGasModel.defaultMixingRatio[3];
//   final parameter Real h_start = specificEnthalpy_pTxi(medium);
// end IfExpression22;
// endResult
