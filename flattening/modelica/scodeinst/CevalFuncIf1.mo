// name: CevalFuncIf1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
algorithm
  if x > 4 then
    y := 3.0;
  elseif x > 2 then
    y := 5.0;
  else
    y := 7.0;
  end if;
end f;

model CevalFuncIf1
  constant Real x = f(1.0);
  constant Real y = f(3.0);
  constant Real z = f(5.0);
end CevalFuncIf1;

// Result:
// class CevalFuncIf1
//   constant Real x = 7.0;
//   constant Real y = 5.0;
//   constant Real z = 3.0;
// end CevalFuncIf1;
// endResult
