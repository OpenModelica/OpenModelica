// name: Return1
// keywords:
// status: correct
//

function f
  input Real x;
  output Real y = x;
algorithm
  if x > 3 then
    y := x + 1;
    return;
  end if;

  y := x - 1;
end f;

model Return1
  constant Real x1 = f(2);
  constant Real x2 = f(4);
end Return1;

// Result:
// class Return1
//   constant Real x1 = 1.0;
//   constant Real x2 = 5.0;
// end Return1;
// endResult
