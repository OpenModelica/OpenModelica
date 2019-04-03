// name: FuncOverloadSimple
// keywords: overload
// status: correct
// cflags: -d=newInst
//
// Tests simple overloading.
//
model FuncOverloadSimple
  function F
    input Integer f1;
    output Integer f2;
  end F;  

  function G
    input Integer g1;
    input Integer g2;
    output Integer g3;
  end G;
  
  function OV = $overload(F,G);
  
  Integer x = OV(1);
  Integer y = OV(1,2);
end FuncOverloadSimple;

// Result:
// function FuncOverloadSimple.F
//   input Integer f1;
//   output Integer f2;
// end FuncOverloadSimple.F;
//
// function FuncOverloadSimple.G
//   input Integer g1;
//   input Integer g2;
//   output Integer g3;
// end FuncOverloadSimple.G;
//
// class FuncOverloadSimple
//   Integer x = FuncOverloadSimple.F(1);
//   Integer y = FuncOverloadSimple.G(1, 2);
// end FuncOverloadSimple;
// endResult
