// name: CevalFuncAssert2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Integer n;
  output Integer res;
algorithm
  assert(n <= 2, "f got n larger than 2", AssertionLevel.error);
  res := n;
end f;

model CevalFuncAssert2
  constant Real x = f(10);
end CevalFuncAssert2;

// Result:
// function f
//   input Integer n;
//   output Integer res;
// algorithm
//   assert(n <= 2, "f got n larger than 2");
//   res := n;
// end f;
//
// class CevalFuncAssert2
//   constant Real x = /*Real*/(f(10));
// end CevalFuncAssert2;
// [flattening/modelica/scodeinst/CevalFuncAssert2.mo:12:3-12:64:writable] Error: assert triggered: f got n larger than 2
//
// endResult
