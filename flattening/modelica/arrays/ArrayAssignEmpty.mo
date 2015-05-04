// name: ArrayAssignEmpty.mo [BUG: #1907, #2300]
// keywords: Empty arrays used in algorithm
// status:   correct
// #1907

model ArrayAssignEmpty
  function f
    input Real r;
    output Real o[0];
  end f;
  Real r[0];
algorithm
  r := f(time);
end ArrayAssignEmpty;

// Result:
// function ArrayAssignEmpty.f
//   input Real r;
//   output Real[0] o;
// end ArrayAssignEmpty.f;
//
// class ArrayAssignEmpty
// algorithm
// end ArrayAssignEmpty;
// endResult
