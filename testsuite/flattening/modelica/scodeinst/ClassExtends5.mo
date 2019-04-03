// name: ClassExtends5
// keywords:
// status: correct
// cflags: -d=newInst
//

partial package PartialMedium
  replaceable record ThermodynamicState
  end ThermodynamicState;

  replaceable partial model BaseProperties
    Real p;
  end BaseProperties;
end PartialMedium;

partial package PartialMixtureMedium
  extends PartialMedium;

  redeclare replaceable record extends ThermodynamicState 
    Real p;
    Real T;
    Real[nX] X;
  end ThermodynamicState;
end PartialMixtureMedium;

package Air
  package MoistAir 
    extends PartialMixtureMedium;

    redeclare replaceable model extends BaseProperties
      Real x_water;
    end BaseProperties;
  end MoistAir;
end Air;

model ClassExtends5
  package Medium = Air.MoistAir;
  Medium.BaseProperties medium;
end ClassExtends5;

// Result:
// class ClassExtends5
//   Real medium.p;
//   Real medium.x_water;
// end ClassExtends5;
// endResult
