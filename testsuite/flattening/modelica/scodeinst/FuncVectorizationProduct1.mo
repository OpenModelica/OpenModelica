// name: FuncVectorizationProduct1
// keywords: vectorization function matrix product
// status: correct
//
// The iterators of a vectorized call are moved into the operands of a matrix
// product, so that each element calculates only one scalar product. The size
// check of A - C follows the iterator into the product.
//

model FuncVectorizationProduct1
  function f
    input Real A[:, :];
    input Real B[:, :];
    input Real C[:, :];
    input Real x[:];
    output Real Y[size(A, 1), size(B, 2)];
    output Real y[3];
  algorithm
    Y := abs(A*B);
    y[1] := max(abs(A*x));
    y[2] := max(abs(x*B));
    y[3] := max(abs((A - C)*x));
  end f;

  Real Y[2, 2], y[3];
equation
  (Y, y) = f({{time, 2}, {3, 4}}, {{1, time}, {3, -4}}, {{time, 1}, {0, 1}}, {time, -1});
end FuncVectorizationProduct1;

// Result:
// function FuncVectorizationProduct1.f
//   input Real[:, :] A;
//   input Real[:, :] B;
//   input Real[:, :] C;
//   input Real[:] x;
//   output Real[size(A, 1), size(B, 2)] Y;
//   output Real[3] y;
// algorithm
//   Y := array(array(abs(A[$i0,:] * B[:,$i1]) for $i1 in 1:size(B, 2)) for $i0 in 1:size(A, 1));
//   y[1] := max(abs(A[$i2,:] * x) for $i2 in 1:size(A, 1));
//   y[2] := max(abs(x * B[:,$i3]) for $i3 in 1:size(B, 2));
//   y[3] := max(abs((A[$i4,:] - C[$i4,:]) * x) for $i4 in 1:OpenModelica.Internal.checkedSize(size(A, 1), size(C, 1), "[flattening/modelica/scodeinst/FuncVectorizationProduct1.mo:22:5-22:32] Dimension 1 of abs((A - C)*x)"));
// end FuncVectorizationProduct1.f;
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
// class FuncVectorizationProduct1
//   Real Y[1,1];
//   Real Y[1,2];
//   Real Y[2,1];
//   Real Y[2,2];
//   Real y[1];
//   Real y[2];
//   Real y[3];
// equation
//   (Y, y) = FuncVectorizationProduct1.f({{time, 2.0}, {3.0, 4.0}}, {{1.0, time}, {3.0, -4.0}}, {{time, 1.0}, {0.0, 1.0}}, {time, -1.0});
// end FuncVectorizationProduct1;
// endResult
