// name: FuncVectorization5
// keywords: vectorization function
// status: correct
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
//   s := sum(sum(FuncVectorization5.mySum(x[$i0,$i1], y[$i0,$i1]) for $i1 in 1:OpenModelica.Internal.checkedSize(size(x, 2), size(y, 2), "[flattening/modelica/scodeinst/FuncVectorization5.mo:19:5-19:26] Dimension 2 of FuncVectorization5.mySum(x, y)")) for $i0 in 1:OpenModelica.Internal.checkedSize(size(x, 1), size(y, 1), "[flattening/modelica/scodeinst/FuncVectorization5.mo:19:5-19:26] Dimension 1 of FuncVectorization5.mySum(x, y)"));
// end FuncVectorization5.f;
//
// function FuncVectorization5.mySum
//   input Real x;
//   input Real y;
//   output Real z = x + y;
// end FuncVectorization5.mySum;
//
// function OpenModelica.Internal.checkedSize "Returns n, and stops with an error if n and m are different"
//   input Integer n;
//   input Integer m;
//   input String description;
//   output Integer s = n;
// algorithm
//   assert(n == m, description + " has different sizes: " + String(n, 0, true) + " and " + String(m, 0, true) + ".");
// end OpenModelica.Internal.checkedSize;
//
// class FuncVectorization5
//   Real x = FuncVectorization5.f({{time, 2.0, 3.0}, {4.0, 5.0, 6.0}}, {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}});
//   Real y = 42.0;
// end FuncVectorization5;
// endResult
