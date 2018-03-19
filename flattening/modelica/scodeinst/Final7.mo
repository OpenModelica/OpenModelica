// name: Final7
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable Real x(start = 1.0);
end A;

model Final7
  extends A(redeclare final Real x = 1.0);
end Final7;

// Result:
// class Final7
//   final Real x(start = 1.0) = 1.0;
// end Final7;
// endResult
