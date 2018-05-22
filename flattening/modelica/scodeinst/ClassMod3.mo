// name: ClassMod3
// status: correct
// cflags: -d=newInst

package P
  type T = Real;
end P;

model ClassMod3
  package MyP = P(T(start = 1.0));
  MyP.T t[3];
end ClassMod3;

// Result:
// class ClassMod3
//   Real t[1](start = 1.0);
//   Real t[2](start = 1.0);
//   Real t[3](start = 1.0);
// end ClassMod3;
// endResult
