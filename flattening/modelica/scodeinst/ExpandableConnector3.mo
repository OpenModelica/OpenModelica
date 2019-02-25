// name: ExpandableConnector3
// keywords: expandable connector
// status: correct
// cflags: -d=newInst
//
//

expandable connector EC
end EC;

connector RealInput = input Real;

model ExpandableConnector3
  EC ec;
  RealInput ri;
equation
  connect(ec.x, ri);
end ExpandableConnector3;

// Result:
// class ExpandableConnector3
//   Real ec.x "virtual variable in expandable connector";
//   input Real ri;
// equation
//   ec.x = ri;
// end ExpandableConnector3;
// endResult
