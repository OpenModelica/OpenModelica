// status: correct
// ticket #3518

model Matrix3
 Boolean b = false;
 constant Integer n = 2;
 Boolean[:,:] vecB = [fill(true,n-1);b];
end Matrix3;

// Result:
// class Matrix3
//   Boolean b = false;
//   constant Integer n = 2;
//   Boolean vecB[1,1];
//   Boolean vecB[2,1];
// equation
//   vecB = {{true}, {b}};
// end Matrix3;
// endResult
