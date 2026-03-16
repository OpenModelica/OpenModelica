// name: FunctionRecordArg7
// keywords:
// status: correct
//

record flowParametersInternal
  parameter Integer n annotation(Evaluate = true);
  parameter Real V_flow[n];
end flowParametersInternal;

function power
  input flowParametersInternal pressure;
  output Real power[11];
algorithm
  power := {pressure.V_flow[end]*i for i in 0:10};
end power;

model FunctionRecordArg7
  parameter flowParametersInternal pCur1(n = 3, V_flow = ones(3));
  parameter Real powEu_internal[:] = power(pressure = pCur1);
  annotation(__OpenModelica_commandLineOptions="-d=evaluateAllParameters");
end FunctionRecordArg7;

// Result:
// class FunctionRecordArg7
//   final parameter Integer pCur1.n = 3;
//   final parameter Real pCur1.V_flow[1] = 1.0;
//   final parameter Real pCur1.V_flow[2] = 1.0;
//   final parameter Real pCur1.V_flow[3] = 1.0;
//   final parameter Real powEu_internal[1] = 0.0;
//   final parameter Real powEu_internal[2] = 1.0;
//   final parameter Real powEu_internal[3] = 2.0;
//   final parameter Real powEu_internal[4] = 3.0;
//   final parameter Real powEu_internal[5] = 4.0;
//   final parameter Real powEu_internal[6] = 5.0;
//   final parameter Real powEu_internal[7] = 6.0;
//   final parameter Real powEu_internal[8] = 7.0;
//   final parameter Real powEu_internal[9] = 8.0;
//   final parameter Real powEu_internal[10] = 9.0;
//   final parameter Real powEu_internal[11] = 10.0;
// end FunctionRecordArg7;
// endResult
