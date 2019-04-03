// name:     FunctionEval12
// keywords: function, ceval, bug1522
// status:   correct
// cflags: +d=nogen
//
// Checks that size of an input parameter in a function is considered
// non-constant, i.e. it should not be constant evaluated since the arrays size
// might depend on the input arguments.
//

model FunctionEval12
  function myFun
    input Real[1, :] x = [0,1];
    output Real y;
  protected
    Real[1, size(x,2)] locX;
    Integer index;
  algorithm
    index :=1;
    while (index <= size(x,2)) loop
      locX[1,index] := x[1,index];
      index := index + 1;
    end while;

    y := locX[1,size(x,2)];

  end myFun;

  Real res1;
  Real res2;
equation
  res1 = myFun( {{1,2,3}});
  res2 = myFun( {{1,2,3,4,5}});
end FunctionEval12;

// Result:
// function FunctionEval12.myFun
//   input Real[1, :] x = {{0.0, 1.0}};
//   output Real y;
//   protected Integer index;
//   protected Real[1, size(x, 2)] locX;
// algorithm
//   index := 1;
//   while index <= size(x, 2) loop
//     locX[1,index] := x[1,index];
//     index := 1 + index;
//   end while;
//   y := locX[1,size(x, 2)];
// end FunctionEval12.myFun;
//
// class FunctionEval12
//   Real res1;
//   Real res2;
// equation
//   res1 = 3.0;
//   res2 = 5.0;
// end FunctionEval12;
// endResult
