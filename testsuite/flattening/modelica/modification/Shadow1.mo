// name:     Shadow1
// keywords: modification,shadow
// status:   correct
//
// Modifications override declarations but not equations.

class A
  Real y=3.0;
  Real x;
equation
  x = 1;
end A;

model Shadow1
  Real z;
  A a(x = z, y=2.0);
end Shadow1;


// Result:
// class Shadow1
//   Real z;
//   Real a.y = 2.0;
//   Real a.x = z;
// equation
//   a.x = 1.0;
// end Shadow1;
// [flattening/modelica/modification/Shadow1.mo:8:3-8:13:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Shadow1.mo:9:3-9:9:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Shadow1.mo:11:3-11:8:writable] Warning: Equation sections are deprecated in class.
//
// endResult
