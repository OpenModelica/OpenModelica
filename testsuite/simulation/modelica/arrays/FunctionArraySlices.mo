model FunctionArraySlices
  function three
    input Integer n;
    output Real a[n] = fill(1, n);
    output Real b[n] = fill(2, n);
    output Integer info = 0;
  end three;

  function columns "Tuple outputs assigned to slices"
    input Integer n;
    output Real e[n, 2];
  protected
    Integer info;
  algorithm
    (e[:, 1], e[:, 2], info) := three(n);
  end columns;

  function emptySlices "Zero-size slices on both sides"
    input Integer n;
    output Real s;
    output Integer rows;
    output Integer cols;
  protected
    Real a[n] = ones(n);
    Real A[n - 1, n];
    Real V[n, n] = identity(n);
    Real Z[n, :];
  algorithm
    for j in 1:n loop
      A[:, j] := a[2:n];
    end for;
    a[1:1] := cat(1, {a[1] + 1}, a[2:1] + a[1:0]);
    Z := V[:, n + 1:n];
    s := sum(a);
    rows := size(Z, 1);
    cols := size(Z, 2);
  end emptySlices;

  function vectorMatrix
    input Real v[:];
    input Real M[size(v, 1), :];
    output Real y[size(M, 2)];
  algorithm
    y := v*M;
  end vectorMatrix;

  function rowOf
    input Real x;
    input Real m[:, 3];
    output Real row[3];
  algorithm
    row := m[1 + integer(x), :];
    annotation(Inline = true);
  end rowOf;

  Real e[3, 2] = columns(3);
  Real s;
  Integer rows, cols;
  Real y[3] = vectorMatrix({1, 2}, [1, 2, 3; 4, 5, 6]);
  Real row[3] = rowOf(1.5*time, {{1, 2, 3}, {4, 5, 6}});
equation
  (s, rows, cols) = emptySlices(1);
end FunctionArraySlices;
