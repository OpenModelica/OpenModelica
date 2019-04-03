// name: CevalFunc2
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
    res := res + i;
  end for;
end f;

model CevalFunc1
  constant Real x = f(10);
end CevalFunc1;

// Result:
// class CevalFunc1
//   constant Real x = 55.0;
// end CevalFunc1;
// endResult
