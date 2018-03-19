// name: RedeclareMod3
// keywords:
// status: correct
// cflags: -d=newInst
//

model A
  replaceable Real x(start = 1.0);
end A;

model B
  extends A(redeclare replaceable Real x(nominal = 2.0));
end B;

model RedeclareMod4
  extends B(redeclare Real x(min = 3.0));
end RedeclareMod4;

// Result:
// class RedeclareMod4
//   Real x(min = 3.0, start = 1.0);
// end RedeclareMod4;
// endResult
