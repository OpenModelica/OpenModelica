// name: ClassExtendsBuiltin3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  type MyReal = Real;
end A;

model ClassExtendsBuiltin3
  extends A;

  redeclare model extends MyReal
  end MyReal;

  MyReal x;
end ClassExtendsBuiltin3;

// Result:
// class ClassExtendsBuiltin3
//   Real x;
// end ClassExtendsBuiltin3;
// endResult
