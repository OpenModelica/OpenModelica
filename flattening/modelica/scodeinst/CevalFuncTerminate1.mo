// name: CevalFuncTerminate1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  output Integer n = 2;
algorithm
  terminate("terminating");
end f;

model CevalFuncTerminate1
  constant Real x = f();
end CevalFuncTerminate1;

// Result:
// function f
//   output Integer n = 2;
// algorithm
//   terminate("terminating");
// end f;
//
// class CevalFuncTerminate1
//   constant Real x = /*Real*/(f());
// end CevalFuncTerminate1;
// [flattening/modelica/scodeinst/CevalFuncTerminate1.mo:11:3-11:27:writable] Error: terminate triggered: terminating
//
// endResult
