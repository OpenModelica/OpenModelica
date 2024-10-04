// name: Subscript7
// status: correct
//
//

model Subscript7
  parameter Real[3, :] x = {{1.0, 0, 0}, {0, 1.0, 0}, {0, 0, 1.0}} annotation(Evaluate=true);
  parameter Real[:, :] y = {x[:, i + 1] - x[:, i] for i in 1:2};
end Subscript7;

// Result:
// class Subscript7
//   final parameter Real x[1,1] = 1.0;
//   final parameter Real x[1,2] = 0.0;
//   final parameter Real x[1,3] = 0.0;
//   final parameter Real x[2,1] = 0.0;
//   final parameter Real x[2,2] = 1.0;
//   final parameter Real x[2,3] = 0.0;
//   final parameter Real x[3,1] = 0.0;
//   final parameter Real x[3,2] = 0.0;
//   final parameter Real x[3,3] = 1.0;
//   parameter Real y[1,1] = -1.0;
//   parameter Real y[1,2] = 1.0;
//   parameter Real y[1,3] = 0.0;
//   parameter Real y[2,1] = 0.0;
//   parameter Real y[2,2] = -1.0;
//   parameter Real y[2,3] = 1.0;
// end Subscript7;
// endResult
