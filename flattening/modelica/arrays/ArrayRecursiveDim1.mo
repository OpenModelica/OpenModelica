// name:     ArrayRecursiveDim
// keywords: array, recursive, dimension, bug #2057
// status:   correct
//
// Checks that the compiler can handle modificaations that reference the
// modified arrays dimensions.
//

model ArrayRecursiveDim
  parameter Integer N = 4,nX = 3;
  parameter Real Xstart[nX] = {0.1,0.8,0.1};
  Real Xtilde[N,nX](start = ones(size(Xtilde, 1), size(Xtilde, 2)));
equation
  for i in 1:N loop
    for j in 1:nX loop
      der(Xtilde[i,j]) = 1;
    end for;
  end for;
end ArrayRecursiveDim;

// Result:
// class ArrayRecursiveDim
//   parameter Integer N = 4;
//   parameter Integer nX = 3;
//   parameter Real Xstart[1] = 0.1;
//   parameter Real Xstart[2] = 0.8;
//   parameter Real Xstart[3] = 0.1;
//   Real Xtilde[1,1](start = 1.0);
//   Real Xtilde[1,2](start = 1.0);
//   Real Xtilde[1,3](start = 1.0);
//   Real Xtilde[2,1](start = 1.0);
//   Real Xtilde[2,2](start = 1.0);
//   Real Xtilde[2,3](start = 1.0);
//   Real Xtilde[3,1](start = 1.0);
//   Real Xtilde[3,2](start = 1.0);
//   Real Xtilde[3,3](start = 1.0);
//   Real Xtilde[4,1](start = 1.0);
//   Real Xtilde[4,2](start = 1.0);
//   Real Xtilde[4,3](start = 1.0);
// equation
//   der(Xtilde[1,1]) = 1.0;
//   der(Xtilde[1,2]) = 1.0;
//   der(Xtilde[1,3]) = 1.0;
//   der(Xtilde[2,1]) = 1.0;
//   der(Xtilde[2,2]) = 1.0;
//   der(Xtilde[2,3]) = 1.0;
//   der(Xtilde[3,1]) = 1.0;
//   der(Xtilde[3,2]) = 1.0;
//   der(Xtilde[3,3]) = 1.0;
//   der(Xtilde[4,1]) = 1.0;
//   der(Xtilde[4,2]) = 1.0;
//   der(Xtilde[4,3]) = 1.0;
// end ArrayRecursiveDim;
// endResult
