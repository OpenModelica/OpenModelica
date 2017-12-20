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
//   constant Real x = 16.0;
//   constant Real z = 5.0;
//   constant Real y = 8.0;
// end A;
// endResult
