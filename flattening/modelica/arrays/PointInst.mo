// name:     PointInst
// keywords: array
// status:   correct
//
// Drmodelica: 7.1 Type Checking (p. 209)
//
type Point = Real[3];


class PointInst
  Point[10]     p1 = fill(8, 10, 3);
  Real[10, 3]     p2 = fill(16, 10, 3);
  Real r[3] = p1[2, :];  // Equivalent to r[3] = p1[2]
  Real rsum = r[1]+r[3];
//equation
  //p2[5, :] = p1[2, :] + p1[4, :];  // Equivalent to p2[5] = p1[2] + p2[4]
end PointInst;

// model PointInst
// Real p1[10, 3] = fill(8, 10, 3);
// Real p2[10, 3] = fill(16, 10, 3);
// Real r[3] = p1[2, :];
// Real rsum = r[1]+r[3];
// end PointInst;