// name: UnusedInput
// status: correct

model UnusedInput

  function sinxx
    input Real x;
    output Real y;
  external "C" y=sin();
  end sinxx;

  function sinxy
    input Real x;
    output Real y;
  algorithm
    y := 1.0;
  end sinxy;

  Real x = sinxx(time);
  Real y = sinxy(time);

end UnusedInput;

// Result:
// function UnusedInput.sinxx
//   input Real x;
//   output Real y;
//
//   external "C" y = sin();
// end UnusedInput.sinxx;
//
// function UnusedInput.sinxy
//   input Real x;
//   output Real y;
// algorithm
//   y := 1.0;
// end UnusedInput.sinxy;
//
// class UnusedInput
//   Real x = UnusedInput.sinxx(time);
//   Real y = UnusedInput.sinxy(time);
// end UnusedInput;
// [flattening/modelica/algorithms-functions/UnusedInput.mo:7:5-7:17:writable] Warning: Unused input variable x in function .UnusedInput.sinxx.
//
// endResult
