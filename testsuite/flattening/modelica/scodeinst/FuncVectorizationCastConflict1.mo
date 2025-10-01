// name: FuncVectorizationCastConflict1
// keywords: vectorization function
// status: correct
//
// Checks that a vectorized function that matches both exactly and via casting
// chooses the exact match.
//

model FuncVectorizationCastConflict1
  Integer x[3];
equation
  x = mod(x, 3);
end FuncVectorizationCastConflict1;


// Result:
// class FuncVectorizationCastConflict1
//   Integer x[1];
//   Integer x[2];
//   Integer x[3];
// equation
//   x = array(mod(x[$i0], 3) for $i0 in 1:3);
// end FuncVectorizationCastConflict1;
// endResult
