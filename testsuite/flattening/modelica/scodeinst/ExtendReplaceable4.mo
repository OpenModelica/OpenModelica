// name: ExtendReplaceable4
// keywords:
// status: correct
//

model ExtendReplaceable4
  replaceable class A
    Real x;
  end A;

  class B = A;
  extends B;
end ExtendReplaceable4;

// Result:
// class ExtendReplaceable4
//   Real x;
// end ExtendReplaceable4;
// endResult
