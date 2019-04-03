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
// function FuncVectorization3.f
//   input Real x;
//   output Real y = x;
// end FuncVectorization3.f;
//
// class FuncVectorization3
//   Real x[1];
//   Real x[2];
//   Real x[3];
// equation
//   x = array(FuncVectorization3.f({1.0, 2.0, 3.0}[$i1]) for $i1 in 1:3);
// end FuncVectorization3;
// endResult
