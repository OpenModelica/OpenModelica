// name: CevalIf1
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model CevalIf1
  constant Real x = if true then 1.0 else 2.0;
  constant Real y = if false then 1.0 else 2.0;
end CevalIf1;

// Result:
// class CevalIf1
//   constant Real x = 1.0;
//   constant Real y = 2.0;
// end CevalIf1;
// endResult
