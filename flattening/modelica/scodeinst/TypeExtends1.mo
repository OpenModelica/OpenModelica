// name: TypeExtends1
// keywords:
// status: correct
// cflags: -d=newInst
//

type MyReal
  extends Real(min = 1.0);
end MyReal;

model TypeExtends1
  MyReal x(start = 1.0);
end TypeExtends1;

// Result:
// class TypeExtends1
//   Real x(min = 1.0, start = 1.0);
// end TypeExtends1;
// endResult
