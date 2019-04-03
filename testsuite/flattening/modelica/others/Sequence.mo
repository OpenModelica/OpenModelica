// name:     Sequence
// keywords: testing that array given as modifications for input paramters in function work fine
// status:   correct
//
// testing that array given as modifications for input paramters in function work fine
//

type AngularVelocity = Real;
type Angle = Real;

record Orientation "Orientation object defining rotation from a frame 1 into a frame 2"
  Real T[3,3] "Transformation matrix from world frame to local frame" ;
  AngularVelocity w[3] "Absolute angular velocity of local frame, resolved in local frame" ;
  encapsulated function equalityConstraint "Return the constraint residues to express that two frames have the same orientation"
    import Orientation;
    input Orientation R1 "Orientation object to rotate frame 0 into frame 1" ;
    input Orientation R2 "Orientation object to rotate frame 0 into frame 2" ;
    output Real residue[3] "The rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (should be zero)" ;
    annotation(Inline = true);
  algorithm
    residue := 1.2;
  end equalityConstraint ;
end Orientation;


function axesRotations "Return fixed rotation object to rotate in sequence around fixed angles along 3 axes"
  input Integer sequence[3](min = {1,1,1}, max = {3,3,3}) = {1,2,3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]" ;
  input Angle angles[3] "Rotation angles around the axes defined in 'sequence'" ;
  input AngularVelocity der_angles[3] "= der(angles)";
  output Orientation R "Orientation object to rotate frame 1 into frame 2" ;
  annotation(Inline = true);
algorithm
  R := Orientation(T = identity(3), w = angles);
end axesRotations ;

function axesRot
  input Integer sequence[3](min = {1,1,1}, max = {3,3,3}) = {1,2,3};
  input Angle angles[3] = {4,5,6};
  output Real r;
algorithm
  r := sequence[1]*angles[3] + sequence[2]*angles[2] + sequence[3]*angles[1]; // 6+10+12=28
end axesRot;

model Sequence
 Orientation r = axesRotations(angles={4,5,6}, der_angles={7,8,9});
 Orientation rOther = axesRotations({10,11,12}, {4,5,6}, {7,8,9});
 Real x = axesRot(); // 28
end Sequence;


// Result:
// function Orientation "Automatically generated record constructor for Orientation"
//   input Real[3, 3] T;
//   input Real[3] w;
//   output Orientation res;
// end Orientation;
//
// function axesRot
//   input Integer[3] sequence = {1, 2, 3};
//   input Real[3] angles = {4.0, 5.0, 6.0};
//   output Real r;
// algorithm
//   r := /*Real*/(sequence[1]) * angles[3] + /*Real*/(sequence[2]) * angles[2] + /*Real*/(sequence[3]) * angles[1];
// end axesRot;
//
// function axesRotations "Inline before index reduction" "Return fixed rotation object to rotate in sequence around fixed angles along 3 axes"
//   input Integer[3] sequence = {1, 2, 3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
//   input Real[3] angles "Rotation angles around the axes defined in 'sequence'";
//   input Real[3] der_angles "= der(angles)";
//   output Orientation R "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   R := Orientation({{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}}, {angles[1], angles[2], angles[3]});
// end axesRotations;
//
// class Sequence
//   Real r.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   Real r.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   Real r.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   Real r.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   Real r.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   Real r.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   Real r.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   Real r.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   Real r.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   Real r.w[1] = 4.0 "Absolute angular velocity of local frame, resolved in local frame";
//   Real r.w[2] = 5.0 "Absolute angular velocity of local frame, resolved in local frame";
//   Real r.w[3] = 6.0 "Absolute angular velocity of local frame, resolved in local frame";
//   Real rOther.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   Real rOther.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   Real rOther.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   Real rOther.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   Real rOther.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   Real rOther.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   Real rOther.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   Real rOther.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   Real rOther.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   Real rOther.w[1] = 4.0 "Absolute angular velocity of local frame, resolved in local frame";
//   Real rOther.w[2] = 5.0 "Absolute angular velocity of local frame, resolved in local frame";
//   Real rOther.w[3] = 6.0 "Absolute angular velocity of local frame, resolved in local frame";
//   Real x = 28.0;
// end Sequence;
// endResult
