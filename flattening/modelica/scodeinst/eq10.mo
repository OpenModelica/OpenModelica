// name: eq10.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

model A
  model B
    Integer ba;
  end B;

  B aa;
equation
  aa.ba = 1;
end A;

// Result:
// class A
//   Integer aa.ba;
// equation
//   aa.ba = 1;
// end A;
// endResult
