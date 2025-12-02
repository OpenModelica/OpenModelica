// name: FuncOverloadNoMatch
// keywords: overload
// status: incorrect
//
// Tests that proper error messages are printed for no overload match
//
model FuncOverloadNoMatch
  function F
    input Integer f1;
    output Integer f2;
  algorithm
    f2 := f1;
  end F;  

  function G
    input Real g1;
    output Integer g3;
  algorithm
    g3 := integer(g1);
  end G;
  
  function OV = $overload(F,G);
  
  Integer x = OV(true);
end FuncOverloadNoMatch;

// Result:
// Error processing file: FuncOverloadNoMatch.mo
// [flattening/modelica/scodeinst/FuncOverloadNoMatch.mo:24:3-24:23:writable] Error: No matching function found for FuncOverloadNoMatch.OV(/*Boolean*/ true).
// Candidates are:
//   FuncOverloadNoMatch.F(Integer f1) => Integer
//   FuncOverloadNoMatch.G(Real g1) => Integer
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
