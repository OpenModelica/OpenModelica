// name: EqualityConstraint1
// keywords:
// status: correct
// cflags: -d=newInst
//

type Real3 = Real[3];

type OC
  extends Real3;

  function equalityConstraint
    input OC oc1;
    input OC oc2;
    output Real residue[0];
  end equalityConstraint;
end OC;

model EqualityConstraint1
  OC oc1, oc2;
equation
  OC.equalityConstraint(oc1, oc2);
end EqualityConstraint1;


// Result:
// function OC.equalityConstraint
//   input Real[3] oc1;
//   input Real[3] oc2;
//   output Real[0] residue;
// end OC.equalityConstraint;
//
// class EqualityConstraint1
//   Real oc1[1];
//   Real oc1[2];
//   Real oc1[3];
//   Real oc2[1];
//   Real oc2[2];
//   Real oc2[3];
// equation
//   OC.equalityConstraint(oc1, oc2);
// end EqualityConstraint1;
// endResult
