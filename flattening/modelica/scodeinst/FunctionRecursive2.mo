// name: FunctionRecursive2
// keywords:
// status: correct
// cflags: -d=newInst
//

function fac
  input Integer n;
  output Integer o = if n <= 1 then 1 else fac(n - 1);
end fac;

model FunctionRecursive2
  Integer x = fac(5);
end FunctionRecursive2;

// Result:
// function fac
//   input Integer n;
//   output Integer o = if n <= 1 then 1 else fac(n - 1);
// end fac;
//
// class FunctionRecursive2
//   Integer x = fac(5);
// end FunctionRecursive2;
// endResult
