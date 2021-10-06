// name: FuncVectorization3
// keywords: vectorization function
// status: correct
// cflags: -d=newInst
//
//

model FuncVectorization3
  function f
    input Real x;
    output Real y = x;
  end f;

  Real x[3];
equation 
  x = f({1, 2, 3});
end FuncVectorization3;


// Result:
// class FuncVectorization3
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x[1] = 1.0;
//   x[2] = 2.0;
//   x[3] = 3.0;
// end FuncVectorization3;
// endResult
