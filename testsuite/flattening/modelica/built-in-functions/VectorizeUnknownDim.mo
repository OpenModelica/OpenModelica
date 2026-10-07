// name: VectorizeUnknownDim
// status: correct

model VectorizeUnknownDim
  function Foo
    input Integer x[:];
    output Integer y[size(x,1)];
  algorithm
    y := abs(x);
  end Foo;

  Integer a[2] = {1, -1};
  Integer b[2];
algorithm
  b := Foo(a);
end VectorizeUnknownDim;

// Result:
// function VectorizeUnknownDim.Foo
//   input Integer[:] x;
//   output Integer[size(x, 1)] y;
// algorithm
//   y := array(abs(x[$i0]) for $i0 in 1:size(x, 1));
// end VectorizeUnknownDim.Foo;
//
// class VectorizeUnknownDim
//   Integer a[1];
//   Integer a[2];
//   Integer b[1];
//   Integer b[2];
// equation
//   a = {1, -1};
// algorithm
//   b := VectorizeUnknownDim.Foo(a);
// end VectorizeUnknownDim;
// endResult
