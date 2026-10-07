// name:     RedeclareBaseClass1
// keywords: class extends, redeclare
// status:   correct
//
// This test checks that it's possible to redeclare the base class in a class
// extends. It doesn't really check that it's done correctly, but that the
// compiler doesn't end up in a loop (since A.R is replaced with C.R which
// extends from A.R).
//

class A
  replaceable record R
    Real x;
  end R;
end A;

class B
  extends A;
end B;

class C
  extends A;

  redeclare record extends R end R;
end C;

class RedeclareBaseClass1
  extends B(redeclare record R = C.R);

  constant R r = R(4.0);
  Real x = r.x;
end RedeclareBaseClass1;

// Result:
// class RedeclareBaseClass1
//   constant Real r.x = 4.0;
//   Real x = 4.0;
// end RedeclareBaseClass1;
// [flattening/modelica/redeclare/RedeclareBaseClass1.mo:30:3-30:24:writable] Warning: Components are deprecated in class.
// [flattening/modelica/redeclare/RedeclareBaseClass1.mo:31:3-31:15:writable] Warning: Components are deprecated in class.
//
// endResult
