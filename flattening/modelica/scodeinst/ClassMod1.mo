// name: ClassMod1
// status: correct
// cflags: -d=newInst

model A
  model B
    Real x = 1.0;
  end B;

  B b;
end A;
  
model ClassMod1
  A a(B(x = 2.0));
end ClassMod1;

// Result:
// class ClassMod1
//   Real a.b.x = 2.0;
// end ClassMod1;
// endResult
