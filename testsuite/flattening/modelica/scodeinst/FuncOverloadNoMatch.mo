// name: FuncOverloadNoMatch
// keywords: overload
// status: incorrect
// cflags: -d=newInst
//
// Tests that proper error messages are printed for no overload match
//
model FuncOverloadNoMatch
  function F
    input Integer f1;
    output Integer f2;
  end F;  

  function G
    input Real g1;
    output Integer g3;
  end G;
  
  function OV = $overload(F,G);
  
  Integer x = OV(true);
end FuncOverloadNoMatch;

// Result:
// Error processing file: FuncOverloadNoMatch.mo
// [flattening/modelica/scodeinst/FuncOverloadNoMatch.mo:21:3-21:23:writable] Error: No matching function found for FuncOverloadNoMatch.OV(/*Boolean*/ true).
// Candidates are:
//   FuncOverloadNoMatch.F(Integer f1) => Integer
//   FuncOverloadNoMatch.G(Real g1) => Integer
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
