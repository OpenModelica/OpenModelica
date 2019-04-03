// name: OperatorOverloadConstructorInvalidOutput1
// keywords: operator overload constructor
// status: incorrect
// cflags: -d=newInst
//
//

operator record C
  Real r1;
  Real r2;

  encapsulated operator function 'constructor'
    input Real r;
    output Real x = r;
  end 'constructor';
end C;

model OperatorOverloadConstructorInvalidOutput1
  C c;
equation
  c = C(1.0);
end OperatorOverloadConstructorInvalidOutput1;


// Result:
// Error processing file: OperatorOverloadConstructorInvalidOutput1.mo
// [flattening/modelica/scodeinst/OperatorOverloadConstructorInvalidOutput1.mo:8:1-16:6:writable] Error: Output ‘x‘ in operator C.'constructor' must be of type C, got type Real.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
