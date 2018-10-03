// name: ceval4.mo
// status: correct
// cflags: -d=newInst

model A
  function f
    input Integer i;
    output Integer j=i+1;
  end f;

  parameter Integer n = 1;
  parameter Integer m = f(n)+n;
  Real x[m] = {1.0, 1.0, 1.0}; //fill(1.0, m);
end A;

// Result:
// class A
//   parameter Integer n = 1;
//   parameter Integer m = 3;
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = {1.0, 1.0, 1.0};
// end A;
// endResult
