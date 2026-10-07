// name:     FunctionBreak
// keywords: function break
// status:   correct
//
// break statement in function

function f
  input Real y;
  output Real a;
protected
  Integer i;
algorithm
  i := 0;
  a := y-1.0;
  while ((i/10) < y) loop
    a := a + 0.5;
    if a>y then break; end if;
    i := i + 1;
  end while;
end f;

model FunctionBreak
  Real x, y;
equation
  x = f(y);
  y = f(x);
end FunctionBreak;


// Result:
// function f
//   input Real y;
//   output Real a;
//   protected Integer i;
// algorithm
//   i := 0;
//   a := y - 1.0;
//   while /*Real*/(i) / 10.0 < y loop
//     a := a + 0.5;
//     if a > y then
//       break;
//     end if;
//     i := i + 1;
//   end while;
// end f;
//
// class FunctionBreak
//   Real x;
//   Real y;
// equation
//   x = f(y);
//   y = f(x);
// end FunctionBreak;
// endResult
