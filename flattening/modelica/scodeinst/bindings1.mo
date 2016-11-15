// name: bindings1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//


model A
  constant Real x = 2 * y;
  constant Real z = 5;
  constant Real y = 3 + z;
end A;

// Result:
// class A
//   constant Real x = 2.0 * y;
//   constant Real z = 5;
//   constant Real y = 3.0 + z;
// end A;
// endResult
