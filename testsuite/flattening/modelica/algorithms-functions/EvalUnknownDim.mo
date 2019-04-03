// cflags: +d=-gen
// status: correct

model EvalUnknownDim
  function mySize
    input Real r[:];
    output Integer s;
  protected
    Real tmp[:];
  algorithm
    tmp := r;
    s := size(tmp,1);
  end mySize;
  constant Integer s = mySize({1,2,3});
end EvalUnknownDim;
// Result:
// function EvalUnknownDim.mySize
//   input Real[:] r;
//   output Integer s;
//   protected Real[:] tmp;
// algorithm
//   tmp := r;
//   s := size(tmp, 1);
// end EvalUnknownDim.mySize;
//
// class EvalUnknownDim
//   constant Integer s = 3;
// end EvalUnknownDim;
// endResult
