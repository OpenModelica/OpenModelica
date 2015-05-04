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
// endResult
