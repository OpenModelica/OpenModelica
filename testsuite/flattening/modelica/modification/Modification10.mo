// name:     Modification10
// keywords: modification
// status:   correct
//
//

class B
  Real x = 1.0;
end B;

class C
  B b;
end C;

class A
  replaceable class B2=B;
  C c;
  B2 b;
end A;

class Modification10
  A a(redeclare class B2=B(x = 17.0));
end Modification10;









// Result:
// class Modification10
//   Real a.c.b.x = 1.0;
//   Real a.b.x = 17.0;
// end Modification10;
// [flattening/modelica/modification/Modification10.mo:8:3-8:15:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification10.mo:12:3-12:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification10.mo:8:3-8:15:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification10.mo:17:3-17:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification10.mo:18:3-18:7:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification10.mo:22:3-22:38:writable] Warning: Components are deprecated in class.
//
// endResult
