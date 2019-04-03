// name: FuncOverloadAmbiguousDefault
// keywords: overload
// status: incorrect
// cflags: -d=newInst
//
// Tests an ambigous overload due to default values.
//
model FuncOverloadAmbiguousDefault
  function F
    input Integer f1;
    output Integer f2;
  end F;  

  function G
    input Integer g1;
    input Integer g2 = 1;
    output Integer g3;
  end G;
  
  function OV = $overload(F,G);
  
  Integer x = OV(1);
end FuncOverloadAmbiguousDefault;

// Result:
// Error processing file: FuncOverloadAmbiguousDefault.mo
// [flattening/modelica/scodeinst/FuncOverloadAmbiguousDefault.mo:22:3-22:20:writable] Error: Ambiguous matching functions found for FuncOverloadAmbiguousDefault.OV(/*Integer*/ 1).
// Candidates are:
//   FuncOverloadAmbiguousDefault.G(Integer g1, Integer g2 = 1) => Integer
//   FuncOverloadAmbiguousDefault.F(Integer f1) => Integer
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
