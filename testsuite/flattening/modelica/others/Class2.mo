// name:     Class2
// keywords:
// status:   correct
//
// This is a really simple tests.
//

class Class2
  Real x = 17.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Class2;

// Result:
// class Class2
//   Real x = 17.0;
// end Class2;
// endResult
