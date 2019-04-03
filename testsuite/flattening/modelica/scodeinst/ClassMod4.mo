// name: ClassMod4
// status: correct
// cflags: -d=newInst

model A
  type T = Real;
  T t[3];
end A;

model ClassMod4
  A a(T(start = 1.0));
end ClassMod4; 

// Result:
// class ClassMod4
//   Real a.t[1](start = 1.0);
//   Real a.t[2](start = 1.0);
//   Real a.t[3](start = 1.0);
// end ClassMod4;
// endResult
