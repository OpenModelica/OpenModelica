// name:     ElementWiseMultiplication.mo
// keywords: function, array, algorithm
// status:   correct
//
// Drmodelica:
//

function ewm
  input Real[3] positionvector;
  output Real[3] result;
algorithm
  result := positionvector * 2;
end ewm;

model ElementWiseMultiplication
  Real inVector[3] = {3,6,1};
  Real result[3];
equation
  result = ewm(inVector);
end ElementWiseMultiplication;

// Result:
// function ewm
//   input Real[3] positionvector;
//   output Real[3] result;
// algorithm
//   result := {positionvector[1] * 2.0, positionvector[2] * 2.0, positionvector[3] * 2.0};
// end ewm;
//
// class ElementWiseMultiplication
//   Real inVector[1];
//   Real inVector[2];
//   Real inVector[3];
//   Real result[1];
//   Real result[2];
//   Real result[3];
// equation
//   inVector = {3.0, 6.0, 1.0};
//   result = ewm({inVector[1], inVector[2], inVector[3]});
// end ElementWiseMultiplication;
// endResult
