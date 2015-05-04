// name:     FunctionDefaultArgs
// keywords: functions, default arguments, unknown size
// status:   correct
//
// Tests default arguments to function, particularly default arguments of
// unknown size.
//
// Tests fix for bug #1190: http://openmodelica.ida.liu.se:8080/cb/issue/1190?navigation=true
//

model FunctionDefaultArgs
  constant Integer[:] reference_X = {1,2,3};

  function set
    input Integer X[:] = reference_X;
    output Integer x1;
  algorithm
    x1 := X[1];
  end set;

  Integer res1, res2, res3;
equation
  res1 = set({4,5,6,7});
  res2 = set({4,3,2});
  res3 = set();
end FunctionDefaultArgs;

// Result:
// function FunctionDefaultArgs.set
//   input Integer[:] X = {1, 2, 3};
//   output Integer x1;
// algorithm
//   x1 := X[1];
// end FunctionDefaultArgs.set;
//
// class FunctionDefaultArgs
//   constant Integer reference_X[1] = 1;
//   constant Integer reference_X[2] = 2;
//   constant Integer reference_X[3] = 3;
//   Integer res1;
//   Integer res2;
//   Integer res3;
// equation
//   res1 = 4;
//   res2 = 4;
//   res3 = 1;
// end FunctionDefaultArgs;
// endResult
