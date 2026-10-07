// name:     Modification11
// keywords: modification
// status:   correct
//

class B
  Real x = 1.0;
end B;

class A
  B b1;
  B b2;
end A;

class Modification11
  A a(b2(x = 17.0));
end Modification11;

// Result:
// class Modification11
//   Real a.b1.x = 1.0;
//   Real a.b2.x = 17.0;
// end Modification11;
// [flattening/modelica/modification/Modification11.mo:7:3-7:15:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification11.mo:11:3-11:7:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification11.mo:12:3-12:7:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification11.mo:16:3-16:20:writable] Warning: Components are deprecated in class.
//
// endResult
