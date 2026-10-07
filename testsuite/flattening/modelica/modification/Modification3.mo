// name:     Modification3
// keywords: modification
// status:   correct

class A
  class AA
    parameter Real p=1.0;
  end AA;
end A;

class B
  replaceable class A=.A.AA;
  A a;
  A a2;
end B;

class Modification3
  B b(redeclare class A=A.AA(p=2),a2(p=4));
end Modification3;

// Result:
// class Modification3
//   parameter Real b.a.p = 2.0;
//   parameter Real b.a2.p = 4.0;
// end Modification3;
// [flattening/modelica/modification/Modification3.mo:7:5-7:25:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification3.mo:13:3-13:6:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification3.mo:14:3-14:7:writable] Warning: Components are deprecated in class.
// [flattening/modelica/modification/Modification3.mo:18:3-18:43:writable] Warning: Components are deprecated in class.
//
// endResult
