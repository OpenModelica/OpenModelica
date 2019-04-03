// name: OperatorOverloadConstructorDefault2
// keywords: operator overload constructor
// status: incorrect
// cflags: -d=newInst
//
// Checks that the default constructor is not used when an overloaded
// constructor is defined, even if it would be the only match.
//

operator record C
  Real r1;
  Real r2;

  encapsulated operator function 'constructor'
    import C;

    input Real r;
    output C o(r1 = r, r2 = 1.0);
  end 'constructor';
end C;

model OperatorOverloadConstructorDefault2
  C c;
equation
  c = C(1.0, 2.0);
end OperatorOverloadConstructorDefault2;


// Result:
// Error processing file: OperatorOverloadConstructorDefault2.mo
// [flattening/modelica/scodeinst/OperatorOverloadConstructorDefault2.mo:25:3-25:18:writable] Error: No matching function found for C(/*Real*/ 1.0, /*Real*/ 2.0).
// Candidates are:
//   C.'constructor'(Real r) => C
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
