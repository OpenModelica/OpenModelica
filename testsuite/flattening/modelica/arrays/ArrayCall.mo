// name: ArrayCall
// status: correct
// Tests that there are no ASUB expressions in the function

class ArrayCall
  function fn
    input Real r;
    output Real array[10];
    annotation(__OpenModelica_EarlyInline = true);
  algorithm
    array := cos(r*(1.0:10.0));
  end fn;
  Real x[10] = fn(time);
end ArrayCall;

// Result:
// class ArrayCall
//   Real x[1];
//   Real x[2];
//   Real x[3];
//   Real x[4];
//   Real x[5];
//   Real x[6];
//   Real x[7];
//   Real x[8];
//   Real x[9];
//   Real x[10];
// equation
//   x = array(cos(time * (1.0:10.0)[$i0]) for $i0 in 1:10);
// end ArrayCall;
// [flattening/modelica/arrays/ArrayCall.mo:13:3-13:24:writable] Warning: Components are deprecated in class.
//
// endResult
