// name: ConnectInNonParamIf
// keywords: connect, if, equation
// status: incorrect
//
// Checks that connect equations are not allowed in if equations with
// non-parameter conditions.
//

model ConnectInNonParamIf
  connector C
    Real e = 1.0;
    flow Real f;
  end C;

  C c1, c2, c3;
equation
  if time > 0.5 then
    connect(c1, c2);
    connect(c1, c3);
  else
    connect(c1, c2);
    connect(c2, c3);
  end if;
end ConnectInNonParamIf;

// Result:
// Error processing file: ConnectInNonParamIf.mo
// [flattening/modelica/equations/ConnectInNonParamIf.mo:18:5-18:20:writable] Error: connect may not be used inside if-equations with non-parametric conditions (found connect(c1, c2)).
// Error: Error occurred while flattening model ConnectInNonParamIf
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
