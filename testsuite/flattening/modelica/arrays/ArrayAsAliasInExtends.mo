// name:     ArrayAsAliasInExtends
// keywords: testing that array as alias used in extends works properly
// status:   correct
//
// Array as alias used in extends checks, enumeration used as array size, enumeration indexing, etc.

type NowLetsSee = enumeration(one, two, three);

type Alias = Real[NowLetsSee](each unit="fish/s");

type Orientation
  extends Alias annotation(dummyAnn = true);
  // have an annotation here too to test that
  // keeping the annotation in SCode doesn't
  // interfere with normal operation!
  annotation(dumyAnn = false);

  // have the equalityConstraint function here too
  function equalityConstraint
    input Orientation x;
    output Real y;
  algorithm
    y := x[NowLetsSee.one]+x[NowLetsSee.two]+x[NowLetsSee.three];
  end equalityConstraint;
end Orientation;

package Mine

  constant Orientation R={1,2,3};

  model Theirs
    parameter Orientation R1 = R;
    Real x = Orientation.equalityConstraint(R);
  end Theirs;

end Mine;


model ArrayAsAliasInExtends
  extends Mine.Theirs;
end ArrayAsAliasInExtends;


// Result:
// function Orientation.equalityConstraint
//   input Real[NowLetsSee] x(unit = "fish/s");
//   output Real y;
// algorithm
//   y := x[NowLetsSee.one] + x[NowLetsSee.two] + x[NowLetsSee.three];
// end Orientation.equalityConstraint;
//
// class ArrayAsAliasInExtends
//   parameter Real R1[NowLetsSee.one](unit = "fish/s") = 1.0;
//   parameter Real R1[NowLetsSee.two](unit = "fish/s") = 2.0;
//   parameter Real R1[NowLetsSee.three](unit = "fish/s") = 3.0;
//   Real x = 6.0;
// end ArrayAsAliasInExtends;
// endResult
