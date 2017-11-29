// name:     IgnoreReplaceable
// keywords: 
// status:   correct
// cflags: --ignoreReplaceable
//
// Tests the --ignoreReplaceable flag.
//

model A
  Real x;

  model B
    Real y;
  end B;

  B b;
end A;

model IgnoreReplaceable
  model C
    Real y;
    Real z;
  end C;

  type MyReal = Real(start = 1.0);

  A a(redeclare MyReal x, redeclare model B = C);
end IgnoreReplaceable;

// Result:
// class IgnoreReplaceable
//   Real a.x(start = 1.0);
//   Real a.b.y;
//   Real a.b.z;
// end IgnoreReplaceable;
// endResult
