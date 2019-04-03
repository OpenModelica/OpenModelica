// name:     ConnectorInheritance1.mo
// keywords: connector, record, inheritance
// status:   correct
//
// Connectors may inherit from records.
//

record A
  Real x;
end A;

connector ConnectorInheritance1 = A;

// Result:
// class ConnectorInheritance1
//   Real x;
// end ConnectorInheritance1;
// endResult
