// name: SumArray
// keywords: sum array #4028
// status: correct
//
// Tests that sum of a multidimensional array is constant evaluated correctly.
//

model SumArray
  function f
    input Integer [:,:,:] x;
    output Integer y = sum(x);
  end f;

  constant Integer s = f({{{1, 2}}, {{3, 4}}});
end SumArray;

// Result:
// function SumArray.f
//   input Integer[:, :, :] x;
//   output Integer y = sum(x);
// end SumArray.f;
//
// class SumArray
//   constant Integer s = 10;
// end SumArray;
// endResult
