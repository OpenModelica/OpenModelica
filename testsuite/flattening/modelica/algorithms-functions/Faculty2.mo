// name:     Faculty2
// keywords: algorithm
// status:   correct
//
// Definition of faculty using a for loop. The for loop can not be
// unrolled.
//

function Faculty2
  input Integer x;
  output Integer y;
algorithm
  y := 1;
  for i in 2:x loop
    y := i * y;
  end for;
end Faculty2;

model Faculty2Model
  Integer x;
  Integer y;
equation
  y = Faculty2(x);
end Faculty2Model;

// Result:
// function Faculty2
//   input Integer x;
//   output Integer y;
// algorithm
//   y := 1;
//   for i in 2:x loop
//     y := i * y;
//   end for;
// end Faculty2;
//
// class Faculty2Model
//   Integer x;
//   Integer y;
// equation
//   y = Faculty2(x);
// end Faculty2Model;
// endResult
