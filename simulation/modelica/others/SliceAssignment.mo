// name:     SliceAssignment
// keywords: slice assignment bug1249
// status:   correct
//
// Checks that correct code is generated for slice assignments.
//

model SliceAssignment
  parameter Real data[:, 3] = {{0.0, 1.0, 2.0}, {3.0, 4.0, 5.0}, {6.0, 7.0, 8.0}};
  parameter Real x[:] = data[:, 1];
  parameter Real y[:] = data[:, 2];
  parameter Real z[:] = data[:, 3];
end SliceAssignment;

// Result:
// class SliceAssignment
//   parameter Real data[1,1] = 0.0;
//   parameter Real data[1,2] = 1.0;
//   parameter Real data[1,3] = 2.0;
//   parameter Real data[2,1] = 3.0;
//   parameter Real data[2,2] = 4.0;
//   parameter Real data[2,3] = 5.0;
//   parameter Real data[3,1] = 6.0;
//   parameter Real data[3,2] = 7.0;
//   parameter Real data[3,3] = 8.0;
//   parameter Real x[1] = data[1,1];
//   parameter Real x[2] = data[2,1];
//   parameter Real x[3] = data[3,1];
//   parameter Real y[1] = data[1,2];
//   parameter Real y[2] = data[2,2];
//   parameter Real y[3] = data[3,2];
//   parameter Real z[1] = data[1,3];
//   parameter Real z[2] = data[2,3];
//   parameter Real z[3] = data[3,3];
// end SliceAssignment;
// endResult
