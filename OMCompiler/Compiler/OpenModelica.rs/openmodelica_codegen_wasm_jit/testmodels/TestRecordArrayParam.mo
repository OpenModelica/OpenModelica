// Whole-array reference to a matrix field of a record inside an array
// (`part[1].R.T`), as MultiBody's `bodybox[1].body.R_start.T`.
model TestRecordArrayParam
  record Orientation
    Real T[3, 3];
  end Orientation;

  function traceT
    input Real T[3, 3];
    output Real s;
  algorithm
    s := T[1, 1] + T[2, 2] + T[3, 3];
  end traceT;

  model Part
    parameter Real d = 1.0;
    parameter Orientation R = Orientation(d * identity(3));
    Real y;
  equation
    y = traceT(R.T);
  end Part;

  Part part[2](d = {2.0, 5.0});
  Real x(start = 0.0, fixed = true);
equation
  der(x) = part[1].y + part[2].y; // expect der(x) = 3*2 + 3*5 = 21
end TestRecordArrayParam;
