// name: RedeclareMod7
// keywords:
// status: correct
//

model A
  replaceable Real x;
end A;

model B
  extends A(x = 2.0);
end B;

model RedeclareMod7
  B b(redeclare Real x = 3.0);
end RedeclareMod7;


// Result:
// class RedeclareMod7
//   Real b.x = 3.0;
// end RedeclareMod7;
// endResult
