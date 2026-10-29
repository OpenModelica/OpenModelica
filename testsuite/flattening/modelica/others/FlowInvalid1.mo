// name: FlowDeclRecord
// keywords: flow
// status: incorrect
//
// Tests the it's not valid to declare a structured component as flow if it
// contains flow variables, as per section 4.4.2.2 in the Modelica 3.2 spec.
//

record R
  Real x;
  flow Real y;
end R;

connector C
  flow R r;
end C;

model FlowInvalid1
  C c1, c2;
equation
  connect(c1, c2);
end FlowInvalid1;

// Result:
// Error processing file: FlowInvalid1.mo
// [flattening/modelica/others/FlowInvalid1.mo:11:3-11:14:writable] Error: Prefix 'flow' on component 'y' not allowed in class specialization 'record'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
