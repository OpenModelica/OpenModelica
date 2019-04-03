// name: CevalFuncWhile1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Integer n;
  output Integer res;
protected
  Integer i;
algorithm
  i := n;
  res := 0;

  while i > 0 loop
    res := res + i;
    i := i - 1;  
  end while;
end f;

model CevalFuncWhile1
  constant Real x = f(10);
end CevalFuncWhile1;

// Result:
// class CevalFuncWhile1
//   constant Real x = 55.0;
// end CevalFuncWhile1;
// endResult
