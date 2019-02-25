// name: ExpandableConnectorPresent1
// keywords: expandable connector
// status: correct
// cflags: -d=newInst
//
//

expandable connector EC
  Real x;
  Real y;
end EC;

connector RealInput = input Real;

model ExpandableConnectorPresent1
  EC ec;
  RealInput ri;
equation
  connect(ec.x, ri);
end ExpandableConnectorPresent1;

// Result:
// class ExpandableConnectorPresent1
//   Real ec.x;
//   input Real ri;
// equation
//   ec.x = ri;
// end ExpandableConnectorPresent1;
// endResult
