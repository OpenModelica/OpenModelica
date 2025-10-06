// name: VectorizeBindings6
// keywords:
// status: correct
//

model VectorizeBindings6
  model A
    Real x;
    Real y;
  equation
    x = 1;
  algorithm
    y := 1;
  end A;

  model B
    A[2] a;
  end B;

  B[2] b;
  annotation(__OpenModelica_commandLineOptions="--newBackend");
end VectorizeBindings6;

// Result:
// class VectorizeBindings6
//   Real[2, 2] b.a.x;
//   Real[2, 2] b.a.y;
// equation
//   for $i2 in 1:2 loop
//     for $i0 in 1:2 loop
//       b[$i2].a[$i0].x = 1.0;
//     end for;
//   end for;
// algorithm
//   for $i3 in 1:2 loop
//     for $i1 in 1:2 loop
//       b[$i3].a[$i1].y := 1.0;
//     end for;
//   end for;
// end VectorizeBindings6;
// endResult
