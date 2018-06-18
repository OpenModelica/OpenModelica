// name: CevalFuncArray4
// keywords:
// status: correct
// cflags: -d=newInst
//
// Checks that the function evaluation can handle outputs whose type depends on
// the input.
//

function f
  input Integer n;
  output Real[n] x;
protected
  Real delta;
algorithm
  if n >= 1 then
    x[1] := 0;
  end if;

  if n >= 2 then
    x[n] := 1;
  end if;

  if n == 3 then
    x[2] := 0.5;
  elseif n > 3 then
    delta := 1 / (n - 2);

    for i in 2:n - 1 loop
      x[i] := (i - 1.5) * delta;
    end for;
  end if;
end f;

model CevalFuncArray4
  constant Real[:] x = f(12);
end CevalFuncArray4;

// Result:
// class CevalFuncArray4
//   constant Real x[1] = 0.0;
//   constant Real x[2] = 0.05;
//   constant Real x[3] = 0.15;
//   constant Real x[4] = 0.25;
//   constant Real x[5] = 0.35;
//   constant Real x[6] = 0.45;
//   constant Real x[7] = 0.55;
//   constant Real x[8] = 0.65;
//   constant Real x[9] = 0.75;
//   constant Real x[10] = 0.8500000000000001;
//   constant Real x[11] = 0.9500000000000001;
//   constant Real x[12] = 1.0;
// end CevalFuncArray4;
// endResult
