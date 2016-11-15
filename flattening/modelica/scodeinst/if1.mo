// name: if1.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Expansion of if-equations not implemented.
//

model A
  Real x;
equation
  if true then
    x = 2;
  elseif "hej" then
    x = 3;
  end if;
end A;
