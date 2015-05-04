// name:     AlgorithmArrayEqn
// keywords: array
// status:   correct
//
// Tests array assignments in algorithm sections.
//

model AlgorithmArrayEqn
   Real p1[2,2]={{1,2},{3,4}};
   Real p2[2,2];
algorithm
  p2 := transpose(p1);
end AlgorithmArrayEqn;

// Result:
// class AlgorithmArrayEqn
//   Real p1[1,1] = 1.0;
//   Real p1[1,2] = 2.0;
//   Real p1[2,1] = 3.0;
//   Real p1[2,2] = 4.0;
//   Real p2[1,1];
//   Real p2[1,2];
//   Real p2[2,1];
//   Real p2[2,2];
// algorithm
//   p2 := {{p1[1,1],p1[2,1]},{p1[1,2],p1[2,2]}};
// end AlgorithmArrayEqn;
// endResult
