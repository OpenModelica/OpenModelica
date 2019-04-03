// name: FuncOverloadExactPrefer
// keywords: overload, cast
// status: correct
// cflags: -d=newInst
//
// Tests proper selection of exact matches over converted matches.
// Compare with FuncOverloadAmbiguousDefault
//
model FuncOverloadExactPrefer
  function F
    input Integer f1;
    output Integer f2;
  end F;  

  function G
    input Real g1;
    input Integer g2 = 1;
    output Integer g3;
  end G;
  
  function OV = $overload(F,G);
  
  Integer x = OV(1);
  Integer y = OV(1.0);
end FuncOverloadExactPrefer;

// Result:
// function FuncOverloadExactPrefer.F
//   input Integer f1;
//   output Integer f2;
// end FuncOverloadExactPrefer.F;
//
// function FuncOverloadExactPrefer.G
//   input Real g1;
//   input Integer g2 = 1;
//   output Integer g3;
// end FuncOverloadExactPrefer.G;
//
// class FuncOverloadExactPrefer
//   Integer x = FuncOverloadExactPrefer.F(1);
//   Integer y = FuncOverloadExactPrefer.G(1.0, 1);
// end FuncOverloadExactPrefer;
// endResult
