// name: FuncVectorizationSizeCheck1
// keywords: vectorization function size
// status: correct
//
// A vectorized call moves the iterators into the operands of element-wise
// operations. When the sizes of the operands are not known to be equal, the
// range of the iterator checks them. A subscript fill(1, n)[i] is then removed.
// Operands with the same declared size are not checked.
//

model FuncVectorizationSizeCheck1
  function f
    input Real v[:, :];
    input Real fv[:];
    input Real a[:];
    input Real b[:];
    output Real Y[size(v, 1), size(fv, 1) - 1];
    output Real y[4];
  protected
    Integer n = size(fv, 1) - 1;
    Real w1[n] = fv[1:n];
    Real w2[n] = fv[2:n + 1];
  algorithm
    Y := abs(v[:, ones(n)] - v[:, 2:n + 1]);
    y[1] := max(abs(fv[ones(n)] - fv[2:n + 1]));
    y[2] := max(abs(a - b));
    y[3] := max(abs(w1 - w2));
    y[4] := max(abs(w1));
  end f;

  Real Y[2, 2], y[4];
equation
  (Y, y) = f({{time, 2, 3}, {4, 5, time}}, {time, 2, 3}, {1, time}, {time, 2});
end FuncVectorizationSizeCheck1;

// Result:
// function FuncVectorizationSizeCheck1.f
//   input Real[:, :] v;
//   input Real[:] fv;
//   input Real[:] a;
//   input Real[:] b;
//   output Real[size(v, 1), size(fv, 1) - 1] Y;
//   output Real[4] y;
//   protected Integer n = size(fv, 1) - 1;
//   protected Real[n] w1 = fv[1:n];
//   protected Real[n] w2 = fv[2:n + 1];
// algorithm
//   Y := array(array(abs(v[$i0,1] - v[$i0,$i1 + 1]) for $i1 in 1:OpenModelica.Internal.checkedSize(max(n + 1 - 2 + 1, 0), n, "[flattening/modelica/scodeinst/FuncVectorizationSizeCheck1.mo:24:5-24:44] Dimension 2 of abs(v[:, fill(1, n)] - v[:, 2:n + 1])")) for $i0 in 1:size(v, 1));
//   y[1] := max(abs(fv[1] - fv[$i2 + 1]) for $i2 in 1:OpenModelica.Internal.checkedSize(max(n + 1 - 2 + 1, 0), n, "[flattening/modelica/scodeinst/FuncVectorizationSizeCheck1.mo:25:5-25:48] Dimension 1 of abs(fv[fill(1, n)] - fv[2:n + 1])"));
//   y[2] := max(abs(a[$i3] - b[$i3]) for $i3 in 1:OpenModelica.Internal.checkedSize(size(a, 1), size(b, 1), "[flattening/modelica/scodeinst/FuncVectorizationSizeCheck1.mo:26:5-26:28] Dimension 1 of abs(a - b)"));
//   y[3] := max(abs(w1[$i4] - w2[$i4]) for $i4 in 1:n);
//   y[4] := max(abs(w1[$i5]) for $i5 in 1:n);
// end FuncVectorizationSizeCheck1.f;
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
// class FuncVectorizationSizeCheck1
//   Real Y[1,1];
//   Real Y[1,2];
//   Real Y[2,1];
//   Real Y[2,2];
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
// equation
//   (Y, y) = FuncVectorizationSizeCheck1.f({{time, 2.0, 3.0}, {4.0, 5.0, time}}, {time, 2.0, 3.0}, {1.0, time}, {time, 2.0});
// end FuncVectorizationSizeCheck1;
// endResult
