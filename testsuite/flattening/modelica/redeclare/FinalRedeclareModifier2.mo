// name:     FinalRedeclareModifier2
// keywords: redeclare, modification, final
// status:   correct
//
// Checks that it's allowed to redeclare a component as final.
//

model M1
  replaceable package P end P;
end M1;

model M2
  extends M1;
end M2;

model FinalRedeclareModifier2
  package P2 end P2;

  M2 m(redeclare final package P = P2);
end FinalRedeclareModifier2;

// Result:
// class FinalRedeclareModifier2
// end FinalRedeclareModifier2;
// endResult
