// name: BuiltinAttribute28
// keywords:
// status: correct
//
// each attributes of array variables in arrays of components.

model BuiltinAttribute28
  model P
    Real x[3](each min = 0);
  end P;

  model C
    P p;
    Real y[3](each min = 0, each nominal = 10);
  end C;

  C c[4];
  P p2[2];
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end BuiltinAttribute28;

// Result:
// class BuiltinAttribute28
//   Real[4, 3] c.p.x(min = array(array(0.0 for $f1 in 1:3) for $f2 in 1:4));
//   Real[4, 3] c.y(min = array(array(0.0 for $f3 in 1:3) for $f4 in 1:4), nominal = array(array(10.0 for $f1 in 1:3) for $f2 in 1:4));
//   Real[2, 3] p2.x(min = array(array(0.0 for $f1 in 1:3) for $f2 in 1:2));
// end BuiltinAttribute28;
// endResult
