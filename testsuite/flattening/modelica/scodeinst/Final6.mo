// name: Final6
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable Real x;
end A;

model Final6
  extends A(redeclare final Real x = 1.0);
end Final6;

// Result:
// class Final6
//   final Real x = 1.0;
// end Final6;
// endResult
