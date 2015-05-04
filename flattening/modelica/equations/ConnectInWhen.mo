// name: ConnectInWhen
// keywords: connect, when, equation
// status: incorrect
//
// Checks that connect equations are not allowed in when equations.
//

model ConnectInWhen
  connector C
    Real e = 1.0;
    flow Real f;
  end C;

  C c1, c2;
equation
  when time > 0.5 then
    connect(c1, c2);
  end when;
end ConnectInWhen;

// Result:
// Error processing file: ConnectInWhen.mo
// [flattening/modelica/equations/ConnectInWhen.mo:17:5-17:20:writable] Error: connect may not be used inside when-equations (found connect(c1, c2)).
// Error: Error occurred while flattening model ConnectInWhen
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
