// name: for1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Expansion of for equations not implemented yet.
//

model A
  Real x[5];
equation
  for i in 1:5 loop
    x[i] = i;
  end for;
end A;
