// name:     ModifyFunction1
// keywords: modification function
// status:   correct
//
// Tests modification of functions by introducing a default binding for an input
// parameter.
//

function quadraticFlow
  input Real V_flow;
  output Real head;
  input Real V_flow_nominal;
end quadraticFlow;

model Inverse
  function flowCharacteristic = quadraticFlow(V_flow_nominal = V_flow_op);
  parameter Real V_flow_op = 1;
  Real head;
equation
  head = flowCharacteristic(1);
end Inverse;

// Result:
// function Inverse.flowCharacteristic
//   input Real V_flow;
//   output Real head;
//   input Real V_flow_nominal = V_flow_op;
// end Inverse.flowCharacteristic;
//
// class Inverse
//   parameter Real V_flow_op = 1.0;
//   Real head;
// equation
//   head = 0.0;
// end Inverse;
// endResult
