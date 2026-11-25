// name: ExpandableConnector4
// keywords: expandable
// status: correct
//
//

expandable connector EC
end EC;

connector C
  Real e;
  flow Real f;
end C;

model ExpandableConnector4
  EC ec;
  C c;
equation
  connect(ec.c, c);
end ExpandableConnector4;

// Result:
// class ExpandableConnector4
//   Real ec.c.f "variable added to expandable connector";
//   Real ec.c.e "variable added to expandable connector";
//   Real c.e;
//   Real c.f;
// equation
//   ec.c.e = c.e;
//   ec.c.f = 0.0;
//   -(ec.c.f + c.f) = 0.0;
//   c.f = 0.0;
// end ExpandableConnector4;
// endResult
