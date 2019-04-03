// name: OperatorOverloadConstructorInvalidOutput2
// keywords: operator overload constructor
// status: incorrect
// cflags: -d=newInst
//
//

operator record C
  Real r1;
  Real r2;

  encapsulated operator function 'constructor'
    import C;
    input Real r;
    output C c(r1 = r, r2 = 1.0);
    output Real x = r;
  end 'constructor';
end C;

model OperatorOverloadConstructorInvalidOutput2
  C c;
equation
  c = C(1.0);
end OperatorOverloadConstructorInvalidOutput2;


// Result:
// Error processing file: OperatorOverloadConstructorInvalidOutput2.mo
// [flattening/modelica/scodeinst/OperatorOverloadConstructorInvalidOutput2.mo:8:1-18:6:writable] Error: Operator C.'constructor' must have exactly one output.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
