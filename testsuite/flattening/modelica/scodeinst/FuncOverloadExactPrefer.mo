// name: FuncOverloadExactPrefer
// keywords: overload, cast
// status: correct
//
// Tests proper selection of exact matches over converted matches.
// Compare with FuncOverloadAmbiguousDefault
//
model FuncOverloadExactPrefer
  function F
    input Integer f1;
    output Integer f2;
  algorithm
    f2 := f1;
  end F;  

  function G
    input Real g1;
    input Integer g2 = 1;
    output Integer g3;
  algorithm
    g3 := g2;
  end G;
  
  function OV = $overload(F,G);
  
  Integer x = OV(1);
  Integer y = OV(1.0);
end FuncOverloadExactPrefer;

// Result:
// class FuncOverloadExactPrefer
//   Integer x = 1;
//   Integer y = 1;
// end FuncOverloadExactPrefer;
// endResult
