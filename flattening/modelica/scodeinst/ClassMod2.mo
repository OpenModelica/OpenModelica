// name: ClassMod2
// status: correct
// cflags: -d=newInst

model A
  model B
    Real x = 1.0;
  end B;

  B b;
end A;

model ClassMod2
  extends A(B(x = 2.0));
  B b2;
end ClassMod2;

// Result:
// class ClassMod2
//   Real b.x = 2.0;
//   Real b2.x = 2.0;
// end ClassMod2;
// endResult
