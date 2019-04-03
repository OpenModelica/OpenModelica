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
// function RedeclareBaseClass1.R "Automatically generated record constructor for RedeclareBaseClass1.R"
//   input Real x;
//   output R res;
// end RedeclareBaseClass1.R;
//
// class RedeclareBaseClass1
//   constant Real r.x = 4.0;
//   Real x = 4.0;
// end RedeclareBaseClass1;
// endResult
