// name: OperatorNonEncapsulated1
// keywords: operator
// status: incorrect
// cflags: -d=newInst
//
// Checks that non-encapsulated operators aren't allowed.
//

operator record C
  Real r;

  operator function 'constructor'
    input Real r;
    output C c(r = r);
  end 'constructor';
end C;

model OperatorNonEncapsulated1
  C c = C(1.0);
end OperatorNonEncapsulated1;

// Result:
// Error processing file: OperatorNonEncapsulated1.mo
// [flattening/modelica/scodeinst/OperatorNonEncapsulated1.mo:12:3-15:20:writable] Error: Operator C.'constructor' is not encapsulated.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
