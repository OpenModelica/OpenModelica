// name:     CatFunc
// keywords: cat concatenation function #2681
// status:   correct
//
// Tests the use of cat in a function where the dimensions
// are not known.
//


function func
  input Integer x1;
  input Integer x2;
  output Real[x1 + x2] result;
protected
  parameter Real vec1[x1] = {i for i in 1:x1};
  parameter Real vec2[x2] = {i for i in 1:x2};
algorithm
  result := cat(1, vec1, vec2);
end func;

model CatFunc
  Real x[:] = func(3, 5);
end CatFunc;

// Result:
// function func
//   input Integer x1;
//   input Integer x2;
//   output Real[x1 + x2] result;
//   protected parameter Real[x1] vec1 = /*Real[:]*/(array(i for i in 1:x1));
//   protected parameter Real[x2] vec2 = /*Real[:]*/(array(i for i in 1:x2));
// algorithm
//   result := cat(1, vec1, vec2);
// end func;
//
// class CatFunc
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real x[6];
//   Real x[7];
//   Real x[8];
// equation
//   x = {1.0, 2.0, 3.0, 1.0, 2.0, 3.0, 4.0, 5.0};
// end CatFunc;
// endResult
