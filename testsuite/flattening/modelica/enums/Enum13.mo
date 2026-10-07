// name:     Enum13
// keywords: enumeration enum mod bug1621
// status:   correct
//
// Checks that it's possible to have a modifier on a component that contains an
// enumeration, and still use the enumeration inside the model.
//

model modelInner
    parameter typeA param1 = typeA.e1;
    type typeA = enumeration(e1, e2 , e3);
end modelInner;

model topModel
  modelInner m(param1 = modelInner.typeA.e2);
end topModel;

// Result:
// class topModel
//   parameter enumeration(e1, e2, e3) m.param1 = modelInner.typeA.e2;
// end topModel;
// endResult
