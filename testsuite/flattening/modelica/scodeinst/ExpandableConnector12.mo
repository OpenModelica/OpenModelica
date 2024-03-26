// name: ExpandableConnector12
// keywords: expandable connector
// status: correct
// cflags: -d=newInst
//
// Checks that potentially present non-connector variables in an expandable
// connector doesn't generate warnings about unbalanced connectors.
//

expandable connector ExpandableConnector12
  Real x;
end ExpandableConnector12;

// Result:
// class ExpandableConnector12
// end ExpandableConnector12;
// endResult
