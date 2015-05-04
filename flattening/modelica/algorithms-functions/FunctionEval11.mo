// name:     FunctionEval11
// keywords: function, ceval, bug1436
// status:   correct
// cflags: +d=nogen
//
// Tests constant evaluation of reductions where the iterator shadows a function
// variable. See bug #1436: http://openmodelica.ida.liu.se:8080/cb/issue/1436.
//

function f
  input Integer i1;
  output Integer i = max(i for i in {1,2,3,i1});
end f;

model FunctionEval11
  constant Integer i = f(4);
end FunctionEval11;

// Result:
// function f
//   input Integer i1;
//   output Integer i = max(3, i1);
// end f;
//
// class FunctionEval11
//   constant Integer i = 4;
// end FunctionEval11;
// endResult
