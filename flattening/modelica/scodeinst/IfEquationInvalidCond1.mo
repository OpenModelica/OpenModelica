// name: IfEquationInvalidCond1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model IfEquationInvalidCond1
  Real x;
  String s;
equation
  if s then
    x = 1.0;
  end if;
end IfEquationInvalidCond1;

// Result:
// Error processing file: IfEquationInvalidCond1.mo
// [flattening/modelica/scodeinst/IfEquationInvalidCond1.mo:11:3-13:9:writable] Error: Type error in conditional 's'. Expected Boolean, got String.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
