// name: CevalFuncRecursive1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function fac
  input Integer n;
  output Integer res;
algorithm
  res := if n > 1 then n * fac(n - 1) else n;   
end fac;

model CevalFuncRecursive1
  constant Real x = fac(6);
end CevalFuncRecursive1;

// Result:
// class CevalFuncRecursive1
//   constant Real x = 720.0;
// end CevalFuncRecursive1;
// endResult
