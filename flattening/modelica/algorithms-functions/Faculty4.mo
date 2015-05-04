// name:     Faculty4
// keywords: equation,array
// status:   correct
//
// Definition of faculty using equations. It is a matter of
// quality of implementation if the model can be treated with
// 'x' being a parameter. In the expected result given here 'x'
// is treated constant.
//

function multiply
  input Real x;
  input Real y;
  output Real z;
algorithm
  z:=x*y;
end multiply;

block Faculty4
  parameter Integer x(min = 0) = 4;
  output Integer y;
protected
  Integer work[x];
equation
  if x < 2 then
    y = 1;
  else
    y = work[x];
    work[x:-1:2] = multiply(work[x-1:-1:1],(ones(x-1) + work[x-1:-1:1]));
    work[1] = 1;
  end if;
end Faculty4;

// Result:
// endResult
