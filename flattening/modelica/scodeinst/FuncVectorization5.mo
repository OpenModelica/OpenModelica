// name: FuncVectorization5
// keywords: vectorization function
// status: correct
// cflags: -d=newInst
//
//

model FuncVectorization5
  function mySum
    input Real x;
    input Real y;
    output Real z = x + y;
  end mySum;

  function f
    input Real[:, :] x;
    input Real[:, :] y;
    output Real s = 0.0;
  algorithm
    s := sum(mySum(x, y));
  end f;

  Real x = f({{time, 2, 3}, {4, 5, 6}}, {{1, 2, 3}, {4, 5, 6}});
  Real y = f({{1, 2, 3}, {4, 5, 6}}, {{1, 2, 3}, {4, 5, 6}});
end FuncVectorization5;


// Result:
// function FuncVectorization5.f
//   input Real[:, :] x;
//   input Real[:, :] y;
//   output Real s = 0.0;
// algorithm
//   s := sum(array(FuncVectorization5.mySum(x[$i1,$i2], y[$i1,$i2]) for $i2 in 1:size(x, 2), $i1 in 1:size(x, 1)));
// end FuncVectorization5.f;
//
// function FuncVectorization5.mySum
//   input Real x;
//   input Real y;
//   output Real z = x + y;
// end FuncVectorization5.mySum;
//
// class FuncVectorization5
//   Real x = FuncVectorization5.f({{time, 2.0, 3.0}, {4.0, 5.0, 6.0}}, {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}});
//   Real y = 42.0;
// end FuncVectorization5;
// endResult
