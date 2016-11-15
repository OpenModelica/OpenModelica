// name: for2.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Expansion of for equations not implemented yet.
//

model A
  Real x[3,3];
equation
  for i in 1:2 loop
    for i in 1:3 loop
      x[i, i] = i;
    end for;
  end for;
end A;
