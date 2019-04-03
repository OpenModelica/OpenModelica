// name: OperatorOverloadArrayOp3
// keywords: operator overload complex
// status: incorrect
// cflags: -d=newInst
//
//

operator record Complex
  Real re;
  Real im;
end Complex;

model OperatorOverloadArrayOp3
  Complex c1[0], c2[0], c3[0];
equation
  c1 = c2 - c3; 
end OperatorOverloadArrayOp3;

// Result:
// Error processing file: OperatorOverloadArrayOp3.mo
// [flattening/modelica/scodeinst/OperatorOverloadArrayOp3.mo:16:3-16:15:writable] Error: Cannot resolve type of expression c2 - c3. The operands have types Complex[0], Complex[0] in component <NO_COMPONENT>.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
