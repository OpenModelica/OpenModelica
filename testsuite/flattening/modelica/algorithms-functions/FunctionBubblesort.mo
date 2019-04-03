// name:     FunctionBubblesort
// keywords: function,code generation,constant propagation
// status:   correct
//
// Constant evaluation of function calls. Result of a function call with
// constant arguments is inserted into flat modelica.
//

function bubblesort
  input Real[:] x;
  output Real[size(x,1)] y;
protected
  Real t;
algorithm
  y := x;
  for i in 1:size(x,1) loop
    for j in 1:size(x,1) loop
      if y[i] > y[j] then
  t := y[i];
  y[i] := y[j];
  y[j] := t;
      end if;
    end for;
  end for;
end bubblesort;

model FunctionBubblesort
  constant Real a[8] = { 0,9,3,5,7,6,8,0 };
  Real b[8];
equation
  b=bubblesort(a);
end FunctionBubblesort;


// Result:
// function bubblesort
//   input Real[:] x;
//   output Real[size(x, 1)] y;
//   protected Real t;
// algorithm
//   y := x;
//   for i in 1:size(x, 1) loop
//     for j in 1:size(x, 1) loop
//       if y[i] > y[j] then
//         t := y[i];
//         y[i] := y[j];
//         y[j] := t;
//       end if;
//     end for;
//   end for;
// end bubblesort;
//
// class FunctionBubblesort
//   constant Real a[1] = 0.0;
//   constant Real a[2] = 9.0;
//   constant Real a[3] = 3.0;
//   constant Real a[4] = 5.0;
//   constant Real a[5] = 7.0;
//   constant Real a[6] = 6.0;
//   constant Real a[7] = 8.0;
//   constant Real a[8] = 0.0;
//   Real b[1];
//   Real b[2];
//   Real b[3];
//   Real b[4];
//   Real b[5];
//   Real b[6];
//   Real b[7];
//   Real b[8];
// equation
//   b[1] = 9.0;
//   b[2] = 8.0;
//   b[3] = 7.0;
//   b[4] = 6.0;
//   b[5] = 5.0;
//   b[6] = 3.0;
//   b[7] = 0.0;
//   b[8] = 0.0;
// end FunctionBubblesort;
// endResult
