// name: FuncOverloadSimple
// keywords: overload
// status: correct
//
// Tests simple overloading.
//
model FuncOverloadSimple
  function F
    input Integer f1;
    output Integer f2;
  algorithm
    f2 := f1;
  end F;  

  function G
    input Integer g1;
    input Integer g2;
    output Integer g3;
  algorithm
    g3 := g1 + g2;
  end G;
  
  function OV = $overload(F,G);
  
  Integer x = OV(1);
  Integer y = OV(1,2);
end FuncOverloadSimple;

// Result:
// class FuncOverloadSimple
//   Integer x = 1;
//   Integer y = 3;
// end FuncOverloadSimple;
// endResult
