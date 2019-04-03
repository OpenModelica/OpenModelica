// name:     ArrayModif
// keywords: modification
// status:   correct
//
// Test that we don't give wrong errors about missing each


model ArrayModif

  package SI
    type MomentOfInertia = Real (final quantity="MomentOfInertia", final unit="kg.m2");
    type Inertia = MomentOfInertia;
    type TypeInteger
      extends Integer;
    end TypeInteger;
    type RotationSequence = TypeInteger[3](min = {1, 1, 1}, max = {3, 3, 3});
  end SI;

  model B
   type T = SI.Inertia[2];
   parameter T i = {1,2};
   type TM = SI.Inertia[3, 3];
   parameter TM x = {{1,2,3},{4,5,6},{6,7,8}};
   parameter SI.RotationSequence sequence(min = {1, 1, 1}, max = {3, 3, 3}) = {1, 2, 3};
   parameter SI.RotationSequence sequence_start = {1, 2, 3};
  end B;

  B b;

end ArrayModif;

// Result:
// class ArrayModif
//   parameter Real b.i[1](quantity = "MomentOfInertia", unit = "kg.m2") = 1.0;
//   parameter Real b.i[2](quantity = "MomentOfInertia", unit = "kg.m2") = 2.0;
//   parameter Real b.x[1,1](quantity = "MomentOfInertia", unit = "kg.m2") = 1.0;
//   parameter Real b.x[1,2](quantity = "MomentOfInertia", unit = "kg.m2") = 2.0;
//   parameter Real b.x[1,3](quantity = "MomentOfInertia", unit = "kg.m2") = 3.0;
//   parameter Real b.x[2,1](quantity = "MomentOfInertia", unit = "kg.m2") = 4.0;
//   parameter Real b.x[2,2](quantity = "MomentOfInertia", unit = "kg.m2") = 5.0;
//   parameter Real b.x[2,3](quantity = "MomentOfInertia", unit = "kg.m2") = 6.0;
//   parameter Real b.x[3,1](quantity = "MomentOfInertia", unit = "kg.m2") = 6.0;
//   parameter Real b.x[3,2](quantity = "MomentOfInertia", unit = "kg.m2") = 7.0;
//   parameter Real b.x[3,3](quantity = "MomentOfInertia", unit = "kg.m2") = 8.0;
//   parameter Integer b.sequence[1](min = 1, max = 3) = 1;
//   parameter Integer b.sequence[2](min = 1, max = 3) = 2;
//   parameter Integer b.sequence[3](min = 1, max = 3) = 3;
//   parameter Integer b.sequence_start[1](min = 1, max = 3) = 1;
//   parameter Integer b.sequence_start[2](min = 1, max = 3) = 2;
//   parameter Integer b.sequence_start[3](min = 1, max = 3) = 3;
// end ArrayModif;
// endResult
