// name: CevalFuncFor2
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Integer n;
  output Integer res;
algorithm
  res := 0;

  for i in 1:n loop
    for i in 1:i loop
      res := res + i;
    end for;
  end for;
end f;

model CevalFuncFor2
  constant Real x = f(10);
end CevalFuncFor2;

// Result:
// class CevalFuncFor2
//   constant Real x = 220.0;
// end CevalFuncFor2;
// endResult
