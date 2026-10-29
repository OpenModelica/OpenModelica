// name: ResizableNestedSplit
// keywords: resizable
// status: correct
// cflags: --newBackend --resizableArrays
//
// The binding of m.X_start is X[2:end, :] split by the elements of m, which
// keeps the split subscript inside the range subscript. Evaluating dom must
// only use the row of each element.
//

model ResizableNestedSplit
  model Medium
    parameter Integer dom = if X_start[1] > X_start[2] then 1 else 2;
    parameter Real X_start[2];
    constant Real MM[2] = {1, 2};
    parameter Real MM_start = MM[dom];
  end Medium;

  parameter Integer N = 3 annotation(__OpenModelica_resizable = true);
  parameter Real X[N + 1, 2] = {{1, 2}, {2, 1}, {1, 2}, {2, 1}};
  Medium m[N](X_start = X[2:end, :]);
end ResizableNestedSplit;
// Result:
// class ResizableNestedSplit
//   parameter Integer N = 3;
//   parameter Real[N + 1, 2] X = {{1.0, 2.0}, {2.0, 1.0}, {1.0, 2.0}, {2.0, 1.0}};
//   final parameter Integer[N] m.dom = {1, 2, 1};
//   parameter Real[N, 2] m.X_start = array(X[1 + $m1,:] for $m1 in 1:N);
//   constant Real[N, 2] m.MM = {{1.0, 2.0}, {1.0, 2.0}, {1.0, 2.0}};
//   parameter Real[N] m.MM_start = array({1.0, 2.0}[if m[$m1].X_start[1] > m[$m1].X_start[2] then 1 else 2] for $m1 in 1:N);
// end ResizableNestedSplit;
// endResult
