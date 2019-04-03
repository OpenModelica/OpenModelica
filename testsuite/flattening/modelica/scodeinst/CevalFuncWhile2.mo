// name: CevalFuncWhile2
// keywords:
// status: incorrect
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
// Error processing file: CevalFuncWhile2.mo
// [flattening/modelica/scodeinst/CevalFuncWhile2.mo:12:3-14:12:writable] Error: The loop iteration limit (--evalLoopLimit=100000) was exceeded during evaluation.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
