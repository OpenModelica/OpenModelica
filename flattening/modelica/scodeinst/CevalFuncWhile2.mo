// name: CevalFuncWhile2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  output Integer res;
algorithm
  res := 0;
  while true loop
    res := res + 1;
  end while;
end f;

model CevalFuncWhile2
  constant Real x = f();
end CevalFuncWhile2;

// Result:
// function f
//   output Integer res;
// algorithm
//   res := 0;
//   while true loop
//     res := res + 1;
//   end while;
// end f;
//
// class CevalFuncWhile2
//   constant Real x = /*Real*/(f());
// end CevalFuncWhile2;
// [flattening/modelica/scodeinst/CevalFuncWhile2.mo:12:3-14:12:writable] Error: The loop iteration limit (--evalLoopLimit=100000) was exceeded during evaluation.
//
// endResult
