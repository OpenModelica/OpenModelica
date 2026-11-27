// name: FuncFillLet1
// keywords: fill function let
// status: correct
//
// fill in a function binds a value that is not a literal or a reference, so
// that the expanded array and an operation on it do not copy the value.
//

model FuncFillLet1
  function f
    input Real x[5];
    output Real y[4];
  algorithm
    y := fill(sum(x), 4);
  end f;

  function f2
    input Real x[:];
    output Real y[size(x, 1)];
  algorithm
    y := fill(sum(x), size(x, 1));
  end f2;

  function f3
    input Real x[3];
    output Real y[3];
  algorithm
    y := fill(x[1] * x[2], 3) + x;
  end f3;

  function f4
    input Real x[3];
    output Real y[2, 2];
  algorithm
    y := fill(x[1], 2, 2);
  end f4;

  Real x[5] = {time, 2*time, 3, 4, 5};
  Real y1[4] = f(x);
  Real y2[5] = f2(x);
  Real y3[3] = f3(x[1:3]);
  Real y4[2, 2] = f4(x[1:3]);
end FuncFillLet1;

// Result:
// function FuncFillLet1.f
//   input Real[5] x;
//   output Real[4] y;
// algorithm
//   y := let $let0 = x[1] + x[2] + x[3] + x[4] + x[5] in {$let0, $let0, $let0, $let0};
// end FuncFillLet1.f;
//
// function FuncFillLet1.f2
//   input Real[:] x;
//   output Real[size(x, 1)] y;
// algorithm
//   y := fill(sum(x), size(x, 1));
// end FuncFillLet1.f2;
//
// function FuncFillLet1.f3
//   input Real[3] x;
//   output Real[3] y;
// algorithm
//   y := let $let2 = x[1] * x[2] in {$let2 + x[1], $let2 + x[2], $let2 + x[3]};
// end FuncFillLet1.f3;
//
// function FuncFillLet1.f4
//   input Real[3] x;
//   output Real[2, 2] y;
// algorithm
//   y := {{x[1], x[1]}, {x[1], x[1]}};
// end FuncFillLet1.f4;
//
// class FuncFillLet1
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real y1[1];
//   Real y1[2];
//   Real y1[3];
//   Real y1[4];
//   Real y2[1];
//   Real y2[2];
//   Real y2[3];
//   Real y2[4];
//   Real y2[5];
//   Real y3[1];
//   Real y3[2];
//   Real y3[3];
//   Real y4[1,1];
//   Real y4[1,2];
//   Real y4[2,1];
//   Real y4[2,2];
// equation
//   x = {time, 2.0 * time, 3.0, 4.0, 5.0};
//   y1 = FuncFillLet1.f(x);
//   y2 = FuncFillLet1.f2(x);
//   y3 = FuncFillLet1.f3(x[1:3]);
//   y4 = FuncFillLet1.f4(x[1:3]);
// end FuncFillLet1;
// endResult
