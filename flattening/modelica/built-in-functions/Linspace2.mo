// status: correct

model Linespace2
  Real points[5,2];
  parameter Integer pointNum = 5;
  parameter Real size[2] = {100,100};
equation
  points[:,1]=linspace(0,size[1],pointNum);
  points[:,2] = fill(size[2], pointNum);
end Linespace2;

// Result:
// class Linespace2
//   Real points[1,1];
//   Real points[1,2];
//   Real points[2,1];
//   Real points[2,2];
//   Real points[3,1];
//   Real points[3,2];
//   Real points[4,1];
//   Real points[4,2];
//   Real points[5,1];
//   Real points[5,2];
//   parameter Integer pointNum = 5;
//   parameter Real size[1] = 100.0;
//   parameter Real size[2] = 100.0;
// equation
//   points[1,1] = 0.0;
//   points[2,1] = size[1] * 0.25;
//   points[3,1] = size[1] * 0.5;
//   points[4,1] = size[1] * 0.75;
//   points[5,1] = size[1];
//   points[1,2] = size[2];
//   points[2,2] = size[2];
//   points[3,2] = size[2];
//   points[4,2] = size[2];
//   points[5,2] = size[2];
// end Linespace2;
// endResult
