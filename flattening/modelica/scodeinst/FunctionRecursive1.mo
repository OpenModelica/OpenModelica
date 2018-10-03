// name: FunctionRecursive1
// keywords:
// status: correct
// cflags: -d=newInst
//

function fac
  input Integer n;
  output Integer o;
algorithm
  if n <= 1 then
    o := 1;
  else
    o := n * fac(n - 1);
  end if;
end fac;

model FunctionRecursive1
  Integer x = fac(5);
end FunctionRecursive1;

// Result:
// class FunctionRecursive1
//   Integer x = 120;
// end FunctionRecursive1;
// endResult
