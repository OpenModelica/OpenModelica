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
// Ambiguous call: OV(1)
// Candidates:
//   OV(Integer g1, Integer g2 = 1) => Integer
//   OV(Integer f1) => Integer
// Error processing file: FuncOverloadAmbiguousDefault.mo
// Error: Internal error Instantiation of FuncOverloadAmbiguousDefault failed with no error message.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
