// name:     Modification2
// keywords: modification
// status:   correct
//
// Modifying a parameter in a local class is allowed.


class B
  class A
    parameter Real p=1.0;
  end A;
  A a;
end B;

class Modification2
  B b(A(p=2.0));
end Modification2;

// Result:
// class Modification2
//   parameter Real b.a.p = 2.0;
// end Modification2;
// endResult
