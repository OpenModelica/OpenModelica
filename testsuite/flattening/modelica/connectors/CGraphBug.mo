// name:     CGraphBug
// keywords: <insert keywords here>
// status:   correct
// cflags: -d=-newInst

model Test

  model SubModel1
    Modelica.Mechanics.MultiBody.Interfaces.Frame_a frame_a;
    outer Modelica.Mechanics.MultiBody.World world;
  equation
    connect(world.frame_b, frame_a);
  end SubModel1;


    SubModel1 subModel1;
    Modelica.Mechanics.MultiBody.Parts.Body mass(
      animation=false,
      m=1,
      I_11=1,
      I_22=1,
      I_33=1,
      r_CM={0,0,0},
      r_0(start={0,0,0}));
    inner Modelica.Mechanics.MultiBody.World world(enableAnimation=false);
  equation
    connect(subModel1.frame_a, mass.frame_a);

end Test;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// Result:
// function Modelica.Math.Vectors.length "Inline before index reduction" "Return length of a vectorReturn length of a vector (better as norm(), if further symbolic processing is performed)"
//   input Real[:] v "Vector";
//   output Real result "Length of vector v";
// algorithm
//   result := sqrt(v * v);
// end Modelica.Math.Vectors.length;
//
// function Modelica.Math.Vectors.normalize "Inline before index reduction" "Return normalized vector such that length = 1Return normalized vector such that length = 1 and prevent zero-division for zero vector"
//   input Real[:] v "Vector";
//   input Real eps = 1e-13 "if |v| < eps then result = v/eps";
//   output Real[size(v, 1)] result "Input vector v normalized to length=1";
// algorithm
//   result := if Modelica.Math.Vectors.length(v) >= eps then v / Modelica.Math.Vectors.length(v) else v / eps;
// end Modelica.Math.Vectors.normalize;
//
// function Modelica.Math.asin
//   input Real u;
//   output Real y(quantity = "Angle", unit = "rad", displayUnit = "deg");
//
//   external "C" y = asin(u);
// end Modelica.Math.asin;
//
// function Modelica.Math.atan2
//   input Real u1;
//   input Real u2;
//   output Real y(quantity = "Angle", unit = "rad", displayUnit = "deg");
//
//   external "C" y = atan2(u1, u2);
// end Modelica.Math.atan2;
//
// function Modelica.Math.cos
//   input Real u(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   output Real y;
//
//   external "C" y = cos(u);
// end Modelica.Math.cos;
//
// function Modelica.Math.sin
//   input Real u(quantity = "Angle", unit = "rad", displayUnit = "deg");
//   output Real y;
//
//   external "C" y = sin(u);
// end Modelica.Math.sin;
//
// function Modelica.Mechanics.MultiBody.Frames.Internal.resolve1_der "Inline before index reduction" "Derivative of function Frames.resolve1(..)"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v2 "Vector resolved in frame 2";
//   input Real[3] v2_der "= der(v2)";
//   output Real[3] v1_der "Derivative of vector v resolved in frame 1";
// algorithm
//   v1_der := Modelica.Mechanics.MultiBody.Frames.resolve1(R, {v2_der[1] + R.w[2] * v2[3] - R.w[3] * v2[2], v2_der[2] + R.w[3] * v2[1] - R.w[1] * v2[3], v2_der[3] + R.w[1] * v2[2] - R.w[2] * v2[1]});
// end Modelica.Mechanics.MultiBody.Frames.Internal.resolve1_der;
//
// function Modelica.Mechanics.MultiBody.Frames.Internal.resolve2_der "Inline before index reduction" "Derivative of function Frames.resolve2(..)"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v1 "Vector resolved in frame 1";
//   input Real[3] v1_der "= der(v1)";
//   output Real[3] v2_der "Derivative of vector v resolved in frame 2";
// algorithm
//   v2_der := Modelica.Mechanics.MultiBody.Frames.resolve2(R, {v1_der[1], v1_der[2], v1_der[3]}) - cross({R.w[1], R.w[2], R.w[3]}, Modelica.Mechanics.MultiBody.Frames.resolve2(R, {v1[1], v1[2], v1[3]}));
// end Modelica.Mechanics.MultiBody.Frames.Internal.resolve2_der;
//
// function Modelica.Mechanics.MultiBody.Frames.Orientation "Automatically generated record constructor for Modelica.Mechanics.MultiBody.Frames.Orientation"
//   input Real[3, 3] T;
//   input Real(quantity="AngularVelocity", unit="rad/s")[3] w;
//   output Orientation res;
// end Modelica.Mechanics.MultiBody.Frames.Orientation;
//
// function Modelica.Mechanics.MultiBody.Frames.Orientation.equalityConstraint "Inline before index reduction" "Return the constraint residues to express that two frames have the same orientation"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R1 "Orientation object to rotate frame 0 into frame 1";
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R2 "Orientation object to rotate frame 0 into frame 2";
//   output Real[3] residue "The rotation angles around x-, y-, and z-axis of frame 1 to rotate frame 1 into frame 2 for a small rotation (should be zero)";
// algorithm
//   residue := {atan2((R1.T[1,2] * R1.T[2,3] - R1.T[1,3] * R1.T[2,2]) * R2.T[2,1] + (R1.T[1,3] * R1.T[2,1] - R1.T[1,1] * R1.T[2,3]) * R2.T[2,2] + (R1.T[1,1] * R1.T[2,2] - R1.T[1,2] * R1.T[2,1]) * R2.T[2,3], R1.T[1,1] * R2.T[1,1] + R1.T[1,2] * R2.T[1,2] + R1.T[1,3] * R2.T[1,3]), atan2((R1.T[1,3] * R1.T[2,2] - R1.T[1,2] * R1.T[2,3]) * R2.T[1,1] + (R1.T[1,1] * R1.T[2,3] - R1.T[1,3] * R1.T[2,1]) * R2.T[1,2] + (R1.T[1,2] * R1.T[2,1] - R1.T[1,1] * R1.T[2,2]) * R2.T[1,3], R1.T[2,1] * R2.T[2,1] + R1.T[2,2] * R2.T[2,2] + R1.T[2,3] * R2.T[2,3]), atan2(R1.T[2,1] * R2.T[1,1] + R1.T[2,2] * R2.T[1,2] + R1.T[2,3] * R2.T[1,3], R1.T[3,1] * R2.T[3,1] + R1.T[3,2] * R2.T[3,2] + R1.T[3,3] * R2.T[3,3])};
// end Modelica.Mechanics.MultiBody.Frames.Orientation.equalityConstraint;
//
// function Modelica.Mechanics.MultiBody.Frames.Quaternions.angularVelocity2 "Inline before index reduction" "Compute angular velocity resolved in frame 2 from quaternions orientation object and its derivative"
//   input Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
//   input Real[4] der_Q(unit = "1/s") "Derivative of Q";
//   output Real[3] w(quantity = "AngularVelocity", unit = "rad/s") "Angular velocity of frame 2 with respect to frame 1 resolved in frame 2";
// algorithm
//   w := {(Q[4] * der_Q[1] + Q[3] * der_Q[2] + (-Q[2]) * der_Q[3] + (-Q[1]) * der_Q[4]) * 2.0, ((-Q[3]) * der_Q[1] + Q[4] * der_Q[2] + Q[1] * der_Q[3] + (-Q[2]) * der_Q[4]) * 2.0, (Q[2] * der_Q[1] + (-Q[1]) * der_Q[2] + Q[4] * der_Q[3] + (-Q[3]) * der_Q[4]) * 2.0};
// end Modelica.Mechanics.MultiBody.Frames.Quaternions.angularVelocity2;
//
// function Modelica.Mechanics.MultiBody.Frames.Quaternions.from_T "Return quaternions orientation object Q from transformation matrix T"
//   input Real[3, 3] T "Transformation matrix to transform vector from frame 1 to frame 2 (v2=T*v1)";
//   input Real[4] Q_guess = {0.0, 0.0, 0.0, 1.0} "Guess value for Q (there are 2 solutions; the one close to Q_guess is used";
//   output Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2 (Q and -Q have same transformation matrix)";
//   protected Real paux;
//   protected Real paux4;
//   protected Real c1;
//   protected Real c2;
//   protected Real c3;
//   protected Real c4;
//   protected constant Real p4limit = 0.1;
//   protected constant Real c4limit = 0.04;
// algorithm
//   c1 := 1.0 + T[1,1] + (-T[2,2]) - T[3,3];
//   c2 := 1.0 + T[2,2] + (-T[1,1]) - T[3,3];
//   c3 := 1.0 + T[3,3] + (-T[1,1]) - T[2,2];
//   c4 := 1.0 + T[1,1] + T[2,2] + T[3,3];
//   if c4 > 0.04 or c4 > c1 and c4 > c2 and c4 > c3 then
//     paux := sqrt(c4) / 2.0;
//     paux4 := 4.0 * paux;
//     Q := {(T[2,3] - T[3,2]) / paux4, (T[3,1] - T[1,3]) / paux4, (T[1,2] - T[2,1]) / paux4, paux};
//   elseif c1 > c2 and c1 > c3 and c1 > c4 then
//     paux := sqrt(c1) / 2.0;
//     paux4 := 4.0 * paux;
//     Q := {paux, (T[1,2] + T[2,1]) / paux4, (T[1,3] + T[3,1]) / paux4, (T[2,3] - T[3,2]) / paux4};
//   elseif c2 > c1 and c2 > c3 and c2 > c4 then
//     paux := sqrt(c2) / 2.0;
//     paux4 := 4.0 * paux;
//     Q := {(T[1,2] + T[2,1]) / paux4, paux, (T[2,3] + T[3,2]) / paux4, (T[3,1] - T[1,3]) / paux4};
//   else
//     paux := sqrt(c3) / 2.0;
//     paux4 := 4.0 * paux;
//     Q := {(T[1,3] + T[3,1]) / paux4, (T[2,3] + T[3,2]) / paux4, paux, (T[1,2] - T[2,1]) / paux4};
//   end if;
//   if Q[1] * Q_guess[1] + Q[2] * Q_guess[2] + Q[3] * Q_guess[3] + Q[4] * Q_guess[4] < 0.0 then
//     Q := -{Q[1], Q[2], Q[3], Q[4]};
//   end if;
// end Modelica.Mechanics.MultiBody.Frames.Quaternions.from_T;
//
// function Modelica.Mechanics.MultiBody.Frames.Quaternions.nullRotation "Inline before index reduction" "Return quaternions orientation object that does not rotate a frame"
//   output Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
// algorithm
//   Q := {0.0, 0.0, 0.0, 1.0};
// end Modelica.Mechanics.MultiBody.Frames.Quaternions.nullRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.Quaternions.orientationConstraint "Inline before index reduction" "Return residues of orientation constraints (shall be zero)"
//   input Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
//   output Real[1] residue "Residue constraint (shall be zero)";
// algorithm
//   residue := {Q[1] ^ 2.0 + Q[2] ^ 2.0 + Q[3] ^ 2.0 + Q[4] ^ 2.0 + -1.0};
// end Modelica.Mechanics.MultiBody.Frames.Quaternions.orientationConstraint;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation "Inline before index reduction" "Return rotation object to rotate around one frame axis"
//   input Integer axis(min = 1, max = 3) "Rotate around 'axis' of frame 1";
//   input Real angle(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angle to rotate frame 1 into frame 2 along 'axis' of frame 1";
//   output Real[3, 3] T "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   T := if axis == 1 then {{1.0, 0.0, 0.0}, {0.0, cos(angle), sin(angle)}, {0.0, -sin(angle), cos(angle)}} else if axis == 2 then {{cos(angle), 0.0, -sin(angle)}, {0.0, 1.0, 0.0}, {sin(angle), 0.0, cos(angle)}} else {{cos(angle), sin(angle), 0.0}, {-sin(angle), cos(angle), 0.0}, {0.0, 0.0, 1.0}};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.planarRotation "Inline before index reduction" "Return orientation object of a planar rotation"
//   input Real[3] e(unit = "1") "Normalized axis of rotation (must have length=1)";
//   input Real angle(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angle to rotate frame 1 into frame 2 along axis e";
//   output Real[3, 3] T "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   T := {{e[1] * e[1] + (1.0 - e[1] * e[1]) * cos(angle), e[1] * e[2] + (-e[1]) * e[2] * cos(angle) - (-e[3]) * sin(angle), e[1] * e[3] + (-e[1]) * e[3] * cos(angle) - e[2] * sin(angle)}, {e[2] * e[1] + (-e[2]) * e[1] * cos(angle) - e[3] * sin(angle), e[2] * e[2] + (1.0 - e[2] * e[2]) * cos(angle), e[2] * e[3] + (-e[2]) * e[3] * cos(angle) - (-e[1]) * sin(angle)}, {e[3] * e[1] + (-e[3]) * e[1] * cos(angle) - (-e[2]) * sin(angle), e[3] * e[2] + (-e[3]) * e[2] * cos(angle) - e[1] * sin(angle), e[3] * e[3] + (1.0 - e[3] * e[3]) * cos(angle)}};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.planarRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1 "Inline before index reduction" "Transform vector from frame 2 to frame 1"
//   input Real[3, 3] T "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v2 "Vector in frame 2";
//   output Real[3] v1 "Vector in frame 1";
// algorithm
//   v1 := {T[1,1] * v2[1] + T[2,1] * v2[2] + T[3,1] * v2[3], T[1,2] * v2[1] + T[2,2] * v2[2] + T[3,2] * v2[3], T[1,3] * v2[1] + T[2,3] * v2[2] + T[3,3] * v2[3]};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1;
//
// function Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2 "Inline before index reduction" "Transform vector from frame 1 to frame 2"
//   input Real[3, 3] T "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v1 "Vector in frame 1";
//   output Real[3] v2 "Vector in frame 2";
// algorithm
//   v2 := {T[1,1] * v1[1] + T[1,2] * v1[2] + T[1,3] * v1[3], T[2,1] * v1[1] + T[2,2] * v1[2] + T[2,3] * v1[3], T[3,1] * v1[1] + T[3,2] * v1[2] + T[3,3] * v1[3]};
// end Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2;
//
// function Modelica.Mechanics.MultiBody.Frames.angularVelocity2 "Inline before index reduction" "Return angular velocity resolved in frame 2 from orientation object"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   output Real[3] w(quantity = "AngularVelocity", unit = "rad/s") "Angular velocity of frame 2 with respect to frame 1 resolved in frame 2";
// algorithm
//   w := {R.w[1], R.w[2], R.w[3]};
// end Modelica.Mechanics.MultiBody.Frames.angularVelocity2;
//
// function Modelica.Mechanics.MultiBody.Frames.axesRotations "Inline before index reduction" "Return fixed rotation object to rotate in sequence around fixed angles along 3 axes"
//   input Integer[3] sequence = {1, 2, 3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
//   input Real[3] angles(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angles around the axes defined in 'sequence'";
//   input Real[3] der_angles(quantity = "AngularVelocity", unit = "rad/s") "= der(angles)";
//   output Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   R := Modelica.Mechanics.MultiBody.Frames.Orientation(Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[3], angles[3]) * Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[2], angles[2]) * Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[1], angles[1]), Modelica.Mechanics.MultiBody.Frames.axis(sequence[3]) * der_angles[3] + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2(Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[3], angles[3]), Modelica.Mechanics.MultiBody.Frames.axis(sequence[2]) * der_angles[2]) + Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2(Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[3], angles[3]) * Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.axisRotation(sequence[2], angles[2]), Modelica.Mechanics.MultiBody.Frames.axis(sequence[1]) * der_angles[1]));
// end Modelica.Mechanics.MultiBody.Frames.axesRotations;
//
// function Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles "Return the 3 angles to rotate in sequence around 3 axes to construct the given orientation object"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Integer[3] sequence = {1, 2, 3} "Sequence of rotations from frame 1 to frame 2 along axis sequence[i]";
//   input Real guessAngle1(quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Select angles[1] such that |angles[1] - guessAngle1| is a minimum";
//   output Real[3] angles(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angles around the axes defined in 'sequence' such that R=Frames.axesRotation(sequence,angles); -pi < angles[i] <= pi";
//   protected Real[3] e1_1(unit = "1") "First rotation axis, resolved in frame 1";
//   protected Real[3] e2_1a(unit = "1") "Second rotation axis, resolved in frame 1a";
//   protected Real[3] e3_1(unit = "1") "Third rotation axis, resolved in frame 1";
//   protected Real[3] e3_2(unit = "1") "Third rotation axis, resolved in frame 2";
//   protected Real A "Coefficient A in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
//   protected Real B "Coefficient B in the equation A*cos(angles[1])+B*sin(angles[1]) = 0";
//   protected Real angle_1a(quantity = "Angle", unit = "rad", displayUnit = "deg") "Solution 1 for angles[1]";
//   protected Real angle_1b(quantity = "Angle", unit = "rad", displayUnit = "deg") "Solution 2 for angles[1]";
//   protected Real[3, 3] T_1a "Orientation object to rotate frame 1 into frame 1a";
// algorithm
//   assert(sequence[1] <> sequence[2] and sequence[2] <> sequence[3], "input argument 'sequence[1:3]' is not valid");
//   e1_1 := if sequence[1] == 1 then {1.0, 0.0, 0.0} else if sequence[1] == 2 then {0.0, 1.0, 0.0} else {0.0, 0.0, 1.0};
//   e2_1a := if sequence[2] == 1 then {1.0, 0.0, 0.0} else if sequence[2] == 2 then {0.0, 1.0, 0.0} else {0.0, 0.0, 1.0};
//   e3_1 := {R.T[sequence[3],1], R.T[sequence[3],2], R.T[sequence[3],3]};
//   e3_2 := if sequence[3] == 1 then {1.0, 0.0, 0.0} else if sequence[3] == 2 then {0.0, 1.0, 0.0} else {0.0, 0.0, 1.0};
//   A := e2_1a[1] * e3_1[1] + e2_1a[2] * e3_1[2] + e2_1a[3] * e3_1[3];
//   B := (e1_1[2] * e2_1a[3] - e1_1[3] * e2_1a[2]) * e3_1[1] + (e1_1[3] * e2_1a[1] - e1_1[1] * e2_1a[3]) * e3_1[2] + (e1_1[1] * e2_1a[2] - e1_1[2] * e2_1a[1]) * e3_1[3];
//   if abs(A) <= 1e-12 and abs(B) <= 1e-12 then
//     angles[1] := guessAngle1;
//   else
//     angle_1a := atan2(A, -B);
//     angle_1b := atan2(-A, B);
//     angles[1] := if abs(angle_1a - guessAngle1) <= abs(angle_1b - guessAngle1) then angle_1a else angle_1b;
//   end if;
//   T_1a := Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.planarRotation({e1_1[1], e1_1[2], e1_1[3]}, angles[1]);
//   angles[2] := Modelica.Mechanics.MultiBody.Frames.planarRotationAngle({e2_1a[1], e2_1a[2], e2_1a[3]}, Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2({{T_1a[1,1], T_1a[1,2], T_1a[1,3]}, {T_1a[2,1], T_1a[2,2], T_1a[2,3]}, {T_1a[3,1], T_1a[3,2], T_1a[3,3]}}, {e3_1[1], e3_1[2], e3_1[3]}), {e3_2[1], e3_2[2], e3_2[3]});
//   angles[3] := Modelica.Mechanics.MultiBody.Frames.planarRotationAngle({e3_2[1], e3_2[2], e3_2[3]}, {e2_1a[1], e2_1a[2], e2_1a[3]}, Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve2({{R.T[1,1], R.T[1,2], R.T[1,3]}, {R.T[2,1], R.T[2,2], R.T[2,3]}, {R.T[3,1], R.T[3,2], R.T[3,3]}}, Modelica.Mechanics.MultiBody.Frames.TransformationMatrices.resolve1({{T_1a[1,1], T_1a[1,2], T_1a[1,3]}, {T_1a[2,1], T_1a[2,2], T_1a[2,3]}, {T_1a[3,1], T_1a[3,2], T_1a[3,3]}}, {e2_1a[1], e2_1a[2], e2_1a[3]})));
// end Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles;
//
// function Modelica.Mechanics.MultiBody.Frames.axis "Inline before index reduction" "Return unit vector for x-, y-, or z-axis"
//   input Integer axis(min = 1, max = 3) "Axis vector to be returned";
//   output Real[3] e(unit = "1") "Unit axis vector";
// algorithm
//   e := if axis == 1 then {1.0, 0.0, 0.0} else if axis == 2 then {0.0, 1.0, 0.0} else {0.0, 0.0, 1.0};
// end Modelica.Mechanics.MultiBody.Frames.axis;
//
// function Modelica.Mechanics.MultiBody.Frames.from_Q "Inline before index reduction" "Return orientation object R from quaternion orientation object Q"
//   input Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
//   input Real[3] w(quantity = "AngularVelocity", unit = "rad/s") "Angular velocity from frame 2 with respect to frame 1, resolved in frame 2";
//   output Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
// algorithm
//   R := Modelica.Mechanics.MultiBody.Frames.Orientation({{2.0 * (Q[1] ^ 2.0 + Q[4] ^ 2.0) + -1.0, 2.0 * (Q[1] * Q[2] + Q[3] * Q[4]), 2.0 * (Q[1] * Q[3] - Q[2] * Q[4])}, {2.0 * (Q[2] * Q[1] - Q[3] * Q[4]), 2.0 * (Q[2] ^ 2.0 + Q[4] ^ 2.0) + -1.0, 2.0 * (Q[2] * Q[3] + Q[1] * Q[4])}, {2.0 * (Q[3] * Q[1] + Q[2] * Q[4]), 2.0 * (Q[3] * Q[2] - Q[1] * Q[4]), 2.0 * (Q[3] ^ 2.0 + Q[4] ^ 2.0) + -1.0}}, {w[1], w[2], w[3]});
// end Modelica.Mechanics.MultiBody.Frames.from_Q;
//
// function Modelica.Mechanics.MultiBody.Frames.nullRotation "Inline before index reduction" "Return orientation object that does not rotate a frame"
//   output Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object such that frame 1 and frame 2 are identical";
// algorithm
//   R := Modelica.Mechanics.MultiBody.Frames.Orientation({{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}}, {0.0, 0.0, 0.0});
// end Modelica.Mechanics.MultiBody.Frames.nullRotation;
//
// function Modelica.Mechanics.MultiBody.Frames.planarRotationAngle "Inline before index reduction" "Return angle of a planar rotation, given the rotation axis and the representations of a vector in frame 1 and frame 2"
//   input Real[3] e(unit = "1") "Normalized axis of rotation to rotate frame 1 around e into frame 2 (must have length=1)";
//   input Real[3] v1 "A vector v resolved in frame 1 (shall not be parallel to e)";
//   input Real[3] v2 "Vector v resolved in frame 2, i.e., v2 = resolve2(planarRotation(e,angle),v1)";
//   output Real angle(quantity = "Angle", unit = "rad", displayUnit = "deg") "Rotation angle to rotate frame 1 into frame 2 along axis e in the range: -pi <= angle <= pi";
// algorithm
//   angle := atan2((e[3] * v1[2] - e[2] * v1[3]) * v2[1] + (e[1] * v1[3] - e[3] * v1[1]) * v2[2] + (e[2] * v1[1] - e[1] * v1[2]) * v2[3], v1[1] * v2[1] + v1[2] * v2[2] + v1[3] * v2[3] - (e[1] * v1[1] + e[2] * v1[2] + e[3] * v1[3]) * (e[1] * v2[1] + e[2] * v2[2] + e[3] * v2[3]));
// end Modelica.Mechanics.MultiBody.Frames.planarRotationAngle;
//
// function Modelica.Mechanics.MultiBody.Frames.resolve1 "Inline after index reduction" "Transform vector from frame 2 to frame 1"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v2 "Vector in frame 2";
//   output Real[3] v1 "Vector in frame 1";
// algorithm
//   v1 := {R.T[1,1] * v2[1] + R.T[2,1] * v2[2] + R.T[3,1] * v2[3], R.T[1,2] * v2[1] + R.T[2,2] * v2[2] + R.T[3,2] * v2[3], R.T[1,3] * v2[1] + R.T[2,3] * v2[2] + R.T[3,3] * v2[3]};
// end Modelica.Mechanics.MultiBody.Frames.resolve1;
//
// function Modelica.Mechanics.MultiBody.Frames.resolve2 "Inline after index reduction" "Transform vector from frame 1 to frame 2"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[3] v1 "Vector in frame 1";
//   output Real[3] v2 "Vector in frame 2";
// algorithm
//   v2 := {R.T[1,1] * v1[1] + R.T[1,2] * v1[2] + R.T[1,3] * v1[3], R.T[2,1] * v1[1] + R.T[2,2] * v1[2] + R.T[2,3] * v1[3], R.T[3,1] * v1[1] + R.T[3,2] * v1[2] + R.T[3,3] * v1[3]};
// end Modelica.Mechanics.MultiBody.Frames.resolve2;
//
// function Modelica.Mechanics.MultiBody.Frames.to_Q "Inline before index reduction" "Return quaternion orientation object Q from orientation object R"
//   input Modelica.Mechanics.MultiBody.Frames.Orientation R "Orientation object to rotate frame 1 into frame 2";
//   input Real[4] Q_guess = {0.0, 0.0, 0.0, 1.0} "Guess value for output Q (there are 2 solutions; the one closer to Q_guess is used";
//   output Real[4] Q "Quaternions orientation object to rotate frame 1 into frame 2";
// algorithm
//   Q := Modelica.Mechanics.MultiBody.Frames.Quaternions.from_T({{R.T[1,1], R.T[1,2], R.T[1,3]}, {R.T[2,1], R.T[2,2], R.T[2,3]}, {R.T[3,1], R.T[3,2], R.T[3,3]}}, {Q_guess[1], Q_guess[2], Q_guess[3], Q_guess[4]});
// end Modelica.Mechanics.MultiBody.Frames.to_Q;
//
// function Modelica.Mechanics.MultiBody.Parts.Body.world__gravityAcceleration "Gravity field acceleration depending on field type and position"
//   input Real[3] r(quantity = "Length", unit = "m") "Position vector from world frame to actual point, resolved in world frame";
//   input enumeration(NoGravity, UniformGravity, PointGravity) gravityType "Type of gravity field";
//   input Real[3] g(quantity = "Acceleration", unit = "m/s2") "Constant gravity acceleration, resolved in world frame, if gravityType=1";
//   input Real mue(unit = "m3/s2") "Field constant of point gravity field, if gravityType=2";
//   output Real[3] gravity(quantity = "Acceleration", unit = "m/s2") "Gravity acceleration at point r, resolved in world frame";
// algorithm
//   gravity := if gravityType == Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity then {g[1], g[2], g[3]} else if gravityType == Modelica.Mechanics.MultiBody.Types.GravityTypes.PointGravity then -{mue * r[1] / (Modelica.Math.Vectors.length({r[1], r[2], r[3]}) * (r[1] ^ 2.0 + r[2] ^ 2.0 + r[3] ^ 2.0)), mue * r[2] / (Modelica.Math.Vectors.length({r[1], r[2], r[3]}) * (r[1] ^ 2.0 + r[2] ^ 2.0 + r[3] ^ 2.0)), mue * r[3] / (Modelica.Math.Vectors.length({r[1], r[2], r[3]}) * (r[1] ^ 2.0 + r[2] ^ 2.0 + r[3] ^ 2.0))} else {0.0, 0.0, 0.0};
// end Modelica.Mechanics.MultiBody.Parts.Body.world__gravityAcceleration;
//
// class Test
//   Real world.frame_b.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real world.frame_b.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real world.frame_b.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real world.frame_b.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real world.frame_b.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real world.frame_b.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real world.frame_b.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real world.frame_b.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real world.frame_b.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real world.frame_b.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real world.frame_b.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real world.frame_b.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real world.frame_b.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real world.frame_b.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real world.frame_b.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real world.frame_b.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real world.frame_b.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real world.frame_b.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real world.frame_b.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real world.frame_b.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real world.frame_b.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   parameter Boolean world.enableAnimation = false "= true, if animation of all components is enabled";
//   parameter Boolean world.animateWorld = true "= true, if world coordinate system shall be visualized";
//   parameter Boolean world.animateGravity = true "= true, if gravity field shall be visualized (acceleration vector or field center)";
//   parameter String world.label1 = "x" "Label of horizontal axis in icon";
//   parameter String world.label2 = "y" "Label of vertical axis in icon";
//   parameter enumeration(NoGravity, UniformGravity, PointGravity) world.gravityType = Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity "Type of gravity field";
//   parameter Real world.g(quantity = "Acceleration", unit = "m/s2") = 9.81 "Constant gravity acceleration";
//   parameter Real world.n[1](unit = "1") = 0.0 "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
//   parameter Real world.n[2](unit = "1") = -1.0 "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
//   parameter Real world.n[3](unit = "1") = 0.0 "Direction of gravity resolved in world frame (gravity = g*n/length(n))";
//   parameter Real world.mue(unit = "m3/s2", min = 0.0) = 398600000000000.0 "Gravity field constant (default = field constant of earth)";
//   parameter Boolean world.driveTrainMechanics3D = true "= true, if 3-dim. mechanical effects of Parts.Mounting1D/Rotor1D/BevelGear1D shall be taken into account";
//   parameter Boolean world.axisShowLabels = true "= true, if labels shall be shown";
//   input Integer world.axisColor_x[1](min = 0, max = 255) "Color of x-arrow";
//   input Integer world.axisColor_x[2](min = 0, max = 255) "Color of x-arrow";
//   input Integer world.axisColor_x[3](min = 0, max = 255) "Color of x-arrow";
//   input Integer world.axisColor_y[1](min = 0, max = 255);
//   input Integer world.axisColor_y[2](min = 0, max = 255);
//   input Integer world.axisColor_y[3](min = 0, max = 255);
//   input Integer world.axisColor_z[1](min = 0, max = 255) "Color of z-arrow";
//   input Integer world.axisColor_z[2](min = 0, max = 255) "Color of z-arrow";
//   input Integer world.axisColor_z[3](min = 0, max = 255) "Color of z-arrow";
//   parameter Real world.gravityArrowTail[1](quantity = "Length", unit = "m") = 0.0 "Position vector from origin of world frame to arrow tail, resolved in world frame";
//   parameter Real world.gravityArrowTail[2](quantity = "Length", unit = "m") = 0.0 "Position vector from origin of world frame to arrow tail, resolved in world frame";
//   parameter Real world.gravityArrowTail[3](quantity = "Length", unit = "m") = 0.0 "Position vector from origin of world frame to arrow tail, resolved in world frame";
//   input Integer world.gravityArrowColor[1](min = 0, max = 255) "Color of gravity arrow";
//   input Integer world.gravityArrowColor[2](min = 0, max = 255) "Color of gravity arrow";
//   input Integer world.gravityArrowColor[3](min = 0, max = 255) "Color of gravity arrow";
//   parameter Real world.gravitySphereDiameter(quantity = "Length", unit = "m", min = 0.0) = 12742000.0 "Diameter of sphere representing gravity center (default = mean diameter of earth)";
//   input Integer world.gravitySphereColor[1](min = 0, max = 255) "Color of gravity sphere";
//   input Integer world.gravitySphereColor[2](min = 0, max = 255) "Color of gravity sphere";
//   input Integer world.gravitySphereColor[3](min = 0, max = 255) "Color of gravity sphere";
//   parameter Real world.nominalLength(quantity = "Length", unit = "m") = 1.0 "\"Nominal\" length of multi-body system";
//   parameter Real world.defaultWidthFraction = 20.0 "Default for shape width as a fraction of shape length (e.g., for Parts.FixedTranslation)";
//   parameter Real world.defaultFrameDiameterFraction = 40.0 "Default for arrow diameter of a coordinate system as a fraction of axis length";
//   parameter Real world.defaultSpecularCoefficient(min = 0.0) = 0.7 "Default reflection of ambient light (= 0: light is completely absorbed)";
//   parameter Real world.defaultN_to_m(unit = "N/m", min = 0.0) = 1000.0 "Default scaling of force arrows (length = force/defaultN_to_m)";
//   parameter Real world.defaultNm_to_m(unit = "N.m/m", min = 0.0) = 1000.0 "Default scaling of torque arrows (length = torque/defaultNm_to_m)";
//   protected parameter Integer world.ndim = if world.enableAnimation and world.animateWorld then 1 else 0;
//   protected parameter Integer world.ndim2 = if world.enableAnimation and world.animateWorld and world.axisShowLabels then 1 else 0;
//   protected parameter Integer world.ndim_pointGravity = if world.enableAnimation and world.animateGravity and world.gravityType == Modelica.Mechanics.MultiBody.Types.GravityTypes.UniformGravity then 1 else 0;
//   parameter Real world.axisLength(quantity = "Length", unit = "m", min = 0.0) = world.nominalLength / 2.0 "Length of world axes arrows";
//   parameter Real world.defaultAxisLength(quantity = "Length", unit = "m") = world.nominalLength / 5.0 "Default for length of a frame axis (but not world frame)";
//   parameter Real world.defaultJointLength(quantity = "Length", unit = "m") = world.nominalLength / 10.0 "Default for the fixed length of a shape representing a joint";
//   parameter Real world.defaultJointWidth(quantity = "Length", unit = "m") = world.nominalLength / 20.0 "Default for the fixed width of a shape representing a joint";
//   parameter Real world.defaultForceLength(quantity = "Length", unit = "m") = world.nominalLength / 10.0 "Default for the fixed length of a shape representing a force (e.g. damper)";
//   parameter Real world.defaultForceWidth(quantity = "Length", unit = "m") = world.nominalLength / 20.0 "Default for the fixed width of a shape represening a force (e.g. spring, bushing)";
//   parameter Real world.defaultBodyDiameter(quantity = "Length", unit = "m") = world.nominalLength / 9.0 "Default for diameter of sphere representing the center of mass of a body";
//   parameter Real world.defaultArrowDiameter(quantity = "Length", unit = "m") = world.nominalLength / 40.0 "Default for arrow diameter (e.g., of forces, torques, sensors)";
//   parameter Real world.axisDiameter(quantity = "Length", unit = "m", min = 0.0) = world.axisLength / world.defaultFrameDiameterFraction "Diameter of world axes arrows";
//   parameter Real world.gravityArrowLength(quantity = "Length", unit = "m") = world.axisLength / 2.0 "Length of gravity arrow";
//   protected parameter Real world.labelStart(quantity = "Length", unit = "m") = 1.05 * world.axisLength;
//   protected parameter Real world.headLength(quantity = "Length", unit = "m") = min(world.axisLength, 5.0 * world.axisDiameter);
//   protected parameter Real world.headWidth(quantity = "Length", unit = "m") = 3.0 * world.axisDiameter;
//   protected parameter Real world.lineWidth(quantity = "Length", unit = "m") = world.axisDiameter;
//   protected parameter Real world.scaledLabel(quantity = "Length", unit = "m") = 3.0 * world.axisDiameter;
//   parameter Real world.gravityArrowDiameter(quantity = "Length", unit = "m", min = 0.0) = world.gravityArrowLength / world.defaultWidthFraction "Diameter of gravity arrow";
//   protected parameter Real world.lineLength(quantity = "Length", unit = "m") = max(0.0, world.axisLength - world.headLength);
//   protected parameter Real world.gravityHeadLength(quantity = "Length", unit = "m") = min(world.gravityArrowLength, 4.0 * world.gravityArrowDiameter);
//   protected parameter Real world.gravityHeadWidth(quantity = "Length", unit = "m") = 3.0 * world.gravityArrowDiameter;
//   protected parameter Real world.gravityLineLength(quantity = "Length", unit = "m") = max(0.0, world.gravityArrowLength - world.gravityHeadLength);
//   Real subModel1.frame_a.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real subModel1.frame_a.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real subModel1.frame_a.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real subModel1.frame_a.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real subModel1.frame_a.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real subModel1.frame_a.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real subModel1.frame_a.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real subModel1.frame_a.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real subModel1.frame_a.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real subModel1.frame_a.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real subModel1.frame_a.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real subModel1.frame_a.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real subModel1.frame_a.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real subModel1.frame_a.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real subModel1.frame_a.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real subModel1.frame_a.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real subModel1.frame_a.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real subModel1.frame_a.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real subModel1.frame_a.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real subModel1.frame_a.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real subModel1.frame_a.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real mass.frame_a.r_0[1](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real mass.frame_a.r_0[2](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real mass.frame_a.r_0[3](quantity = "Length", unit = "m") "Position vector from world frame to the connector frame origin, resolved in world frame";
//   Real mass.frame_a.R.T[1,1] "Transformation matrix from world frame to local frame";
//   Real mass.frame_a.R.T[1,2] "Transformation matrix from world frame to local frame";
//   Real mass.frame_a.R.T[1,3] "Transformation matrix from world frame to local frame";
//   Real mass.frame_a.R.T[2,1] "Transformation matrix from world frame to local frame";
//   Real mass.frame_a.R.T[2,2] "Transformation matrix from world frame to local frame";
//   Real mass.frame_a.R.T[2,3] "Transformation matrix from world frame to local frame";
//   Real mass.frame_a.R.T[3,1] "Transformation matrix from world frame to local frame";
//   Real mass.frame_a.R.T[3,2] "Transformation matrix from world frame to local frame";
//   Real mass.frame_a.R.T[3,3] "Transformation matrix from world frame to local frame";
//   Real mass.frame_a.R.w[1](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real mass.frame_a.R.w[2](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real mass.frame_a.R.w[3](quantity = "AngularVelocity", unit = "rad/s") "Absolute angular velocity of local frame, resolved in local frame";
//   Real mass.frame_a.f[1](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real mass.frame_a.f[2](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real mass.frame_a.f[3](quantity = "Force", unit = "N") "Cut-force resolved in connector frame";
//   Real mass.frame_a.t[1](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real mass.frame_a.t[2](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   Real mass.frame_a.t[3](quantity = "Torque", unit = "N.m") "Cut-torque resolved in connector frame";
//   parameter Boolean mass.animation = false "= true, if animation shall be enabled (show cylinder and sphere)";
//   parameter Real mass.r_CM[1](quantity = "Length", unit = "m", start = 0.0) = 0.0 "Vector from frame_a to center of mass, resolved in frame_a";
//   parameter Real mass.r_CM[2](quantity = "Length", unit = "m", start = 0.0) = 0.0 "Vector from frame_a to center of mass, resolved in frame_a";
//   parameter Real mass.r_CM[3](quantity = "Length", unit = "m", start = 0.0) = 0.0 "Vector from frame_a to center of mass, resolved in frame_a";
//   parameter Real mass.m(quantity = "Mass", unit = "kg", min = 0.0, start = 1.0) = 1.0 "Mass of rigid body";
//   parameter Real mass.I_11(quantity = "MomentOfInertia", unit = "kg.m2", min = 0.0) = 1.0 " (1,1) element of inertia tensor";
//   parameter Real mass.I_22(quantity = "MomentOfInertia", unit = "kg.m2", min = 0.0) = 1.0 " (2,2) element of inertia tensor";
//   parameter Real mass.I_33(quantity = "MomentOfInertia", unit = "kg.m2", min = 0.0) = 1.0 " (3,3) element of inertia tensor";
//   parameter Real mass.I_21(quantity = "MomentOfInertia", unit = "kg.m2", min = -1e+60) = 0.0 " (2,1) element of inertia tensor";
//   parameter Real mass.I_31(quantity = "MomentOfInertia", unit = "kg.m2", min = -1e+60) = 0.0 " (3,1) element of inertia tensor";
//   parameter Real mass.I_32(quantity = "MomentOfInertia", unit = "kg.m2", min = -1e+60) = 0.0 " (3,2) element of inertia tensor";
//   Real mass.r_0[1](quantity = "Length", unit = "m", start = 0.0, StateSelect = StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
//   Real mass.r_0[2](quantity = "Length", unit = "m", start = 0.0, StateSelect = StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
//   Real mass.r_0[3](quantity = "Length", unit = "m", start = 0.0, StateSelect = StateSelect.avoid) "Position vector from origin of world frame to origin of frame_a";
//   Real mass.v_0[1](quantity = "Velocity", unit = "m/s", start = 0.0, StateSelect = StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
//   Real mass.v_0[2](quantity = "Velocity", unit = "m/s", start = 0.0, StateSelect = StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
//   Real mass.v_0[3](quantity = "Velocity", unit = "m/s", start = 0.0, StateSelect = StateSelect.avoid) "Absolute velocity of frame_a, resolved in world frame (= der(r_0))";
//   Real mass.a_0[1](quantity = "Acceleration", unit = "m/s2", start = 0.0) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
//   Real mass.a_0[2](quantity = "Acceleration", unit = "m/s2", start = 0.0) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
//   Real mass.a_0[3](quantity = "Acceleration", unit = "m/s2", start = 0.0) "Absolute acceleration of frame_a resolved in world frame (= der(v_0))";
//   parameter Boolean mass.angles_fixed = false "= true, if angles_start are used as initial values, else as guess values";
//   parameter Real mass.angles_start[1](quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
//   parameter Real mass.angles_start[2](quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
//   parameter Real mass.angles_start[3](quantity = "Angle", unit = "rad", displayUnit = "deg") = 0.0 "Initial values of angles to rotate frame_a around 'sequence_start' axes into frame_b";
//   parameter Integer mass.sequence_start[1](min = 1, max = 3) = 1 "Sequence of rotations to rotate frame_a into frame_b at initial time";
//   parameter Integer mass.sequence_start[2](min = 1, max = 3) = 2 "Sequence of rotations to rotate frame_a into frame_b at initial time";
//   parameter Integer mass.sequence_start[3](min = 1, max = 3) = 3 "Sequence of rotations to rotate frame_a into frame_b at initial time";
//   parameter Boolean mass.w_0_fixed = false "= true, if w_0_start are used as initial values, else as guess values";
//   parameter Real mass.w_0_start[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Initial or guess values of angular velocity of frame_a resolved in world frame";
//   parameter Real mass.w_0_start[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Initial or guess values of angular velocity of frame_a resolved in world frame";
//   parameter Real mass.w_0_start[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Initial or guess values of angular velocity of frame_a resolved in world frame";
//   parameter Boolean mass.z_0_fixed = false "= true, if z_0_start are used as initial values, else as guess values";
//   parameter Real mass.z_0_start[1](quantity = "AngularAcceleration", unit = "rad/s2") = 0.0 "Initial values of angular acceleration z_0 = der(w_0)";
//   parameter Real mass.z_0_start[2](quantity = "AngularAcceleration", unit = "rad/s2") = 0.0 "Initial values of angular acceleration z_0 = der(w_0)";
//   parameter Real mass.z_0_start[3](quantity = "AngularAcceleration", unit = "rad/s2") = 0.0 "Initial values of angular acceleration z_0 = der(w_0)";
//   input Integer mass.sphereColor[1](min = 0, max = 255) "Color of sphere";
//   input Integer mass.sphereColor[2](min = 0, max = 255) "Color of sphere";
//   input Integer mass.sphereColor[3](min = 0, max = 255) "Color of sphere";
//   input Integer mass.cylinderColor[1](min = 0, max = 255) "Color of cylinder";
//   input Integer mass.cylinderColor[2](min = 0, max = 255) "Color of cylinder";
//   input Integer mass.cylinderColor[3](min = 0, max = 255) "Color of cylinder";
//   input Real mass.specularCoefficient = world.defaultSpecularCoefficient "Reflection of ambient light (= 0: light is completely absorbed)";
//   parameter Boolean mass.enforceStates = false " = true, if absolute variables of body object shall be used as states (StateSelect.always)";
//   parameter Boolean mass.useQuaternions = true " = true, if quaternions shall be used as potential states otherwise use 3 angles as potential states";
//   parameter Integer mass.sequence_angleStates[1](min = 1, max = 3) = 1 " Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";
//   parameter Integer mass.sequence_angleStates[2](min = 1, max = 3) = 2 " Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";
//   parameter Integer mass.sequence_angleStates[3](min = 1, max = 3) = 3 " Sequence of rotations to rotate world frame into frame_a around the 3 angles used as potential states";
//   Real mass.w_a[1](quantity = "AngularVelocity", unit = "rad/s", start = Modelica.Mechanics.MultiBody.Frames.resolve2(mass.R_start, {mass.w_0_start[1], mass.w_0_start[2], mass.w_0_start[3]})[1], fixed = mass.w_0_fixed, StateSelect = StateSelect.avoid) "Absolute angular velocity of frame_a resolved in frame_a";
//   Real mass.w_a[2](quantity = "AngularVelocity", unit = "rad/s", start = Modelica.Mechanics.MultiBody.Frames.resolve2(mass.R_start, {mass.w_0_start[1], mass.w_0_start[2], mass.w_0_start[3]})[2], fixed = mass.w_0_fixed, StateSelect = StateSelect.avoid) "Absolute angular velocity of frame_a resolved in frame_a";
//   Real mass.w_a[3](quantity = "AngularVelocity", unit = "rad/s", start = Modelica.Mechanics.MultiBody.Frames.resolve2(mass.R_start, {mass.w_0_start[1], mass.w_0_start[2], mass.w_0_start[3]})[3], fixed = mass.w_0_fixed, StateSelect = StateSelect.avoid) "Absolute angular velocity of frame_a resolved in frame_a";
//   Real mass.g_0[1](quantity = "Acceleration", unit = "m/s2") "Gravity acceleration resolved in world frame";
//   Real mass.g_0[2](quantity = "Acceleration", unit = "m/s2") "Gravity acceleration resolved in world frame";
//   Real mass.g_0[3](quantity = "Acceleration", unit = "m/s2") "Gravity acceleration resolved in world frame";
//   protected Real mass.Q[1](start = mass.Q_start[1], StateSelect = StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
//   protected Real mass.Q[2](start = mass.Q_start[2], StateSelect = StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
//   protected Real mass.Q[3](start = mass.Q_start[3], StateSelect = StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
//   protected Real mass.Q[4](start = mass.Q_start[4], StateSelect = StateSelect.avoid) "Quaternion orientation object from world frame to frame_a (dummy value, if quaternions are not used as states)";
//   protected parameter Real mass.phi_start[1](quantity = "Angle", unit = "rad", displayUnit = "deg") = if mass.sequence_start[1] == mass.sequence_angleStates[1] and mass.sequence_start[2] == mass.sequence_angleStates[2] and mass.sequence_start[3] == mass.sequence_angleStates[3] then mass.angles_start[1] else Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles(mass.R_start, {mass.sequence_angleStates[1], mass.sequence_angleStates[2], mass.sequence_angleStates[3]}, 0)[1] "Potential angle states at initial time";
//   protected parameter Real mass.phi_start[2](quantity = "Angle", unit = "rad", displayUnit = "deg") = if mass.sequence_start[1] == mass.sequence_angleStates[1] and mass.sequence_start[2] == mass.sequence_angleStates[2] and mass.sequence_start[3] == mass.sequence_angleStates[3] then mass.angles_start[2] else Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles(mass.R_start, {mass.sequence_angleStates[1], mass.sequence_angleStates[2], mass.sequence_angleStates[3]}, 0)[2] "Potential angle states at initial time";
//   protected parameter Real mass.phi_start[3](quantity = "Angle", unit = "rad", displayUnit = "deg") = if mass.sequence_start[1] == mass.sequence_angleStates[1] and mass.sequence_start[2] == mass.sequence_angleStates[2] and mass.sequence_start[3] == mass.sequence_angleStates[3] then mass.angles_start[3] else Modelica.Mechanics.MultiBody.Frames.axesRotationsAngles(mass.R_start, {mass.sequence_angleStates[1], mass.sequence_angleStates[2], mass.sequence_angleStates[3]}, 0)[3] "Potential angle states at initial time";
//   protected Real mass.phi[1](quantity = "Angle", unit = "rad", displayUnit = "deg", start = mass.phi_start[1], StateSelect = StateSelect.avoid) "Dummy or 3 angles to rotate world frame into frame_a of body";
//   protected Real mass.phi[2](quantity = "Angle", unit = "rad", displayUnit = "deg", start = mass.phi_start[2], StateSelect = StateSelect.avoid) "Dummy or 3 angles to rotate world frame into frame_a of body";
//   protected Real mass.phi[3](quantity = "Angle", unit = "rad", displayUnit = "deg", start = mass.phi_start[3], StateSelect = StateSelect.avoid) "Dummy or 3 angles to rotate world frame into frame_a of body";
//   protected Real mass.phi_d[1](quantity = "AngularVelocity", unit = "rad/s", StateSelect = StateSelect.avoid) "= der(phi)";
//   protected Real mass.phi_d[2](quantity = "AngularVelocity", unit = "rad/s", StateSelect = StateSelect.avoid) "= der(phi)";
//   protected Real mass.phi_d[3](quantity = "AngularVelocity", unit = "rad/s", StateSelect = StateSelect.avoid) "= der(phi)";
//   protected Real mass.phi_dd[1](quantity = "AngularAcceleration", unit = "rad/s2") "= der(phi_d)";
//   protected Real mass.phi_dd[2](quantity = "AngularAcceleration", unit = "rad/s2") "= der(phi_d)";
//   protected Real mass.phi_dd[3](quantity = "AngularAcceleration", unit = "rad/s2") "= der(phi_d)";
//   final parameter Real mass.I[1,1](quantity = "MomentOfInertia", unit = "kg.m2") = mass.I_11 "inertia tensor";
//   final parameter Real mass.I[1,2](quantity = "MomentOfInertia", unit = "kg.m2") = mass.I_21 "inertia tensor";
//   final parameter Real mass.I[1,3](quantity = "MomentOfInertia", unit = "kg.m2") = mass.I_31 "inertia tensor";
//   final parameter Real mass.I[2,1](quantity = "MomentOfInertia", unit = "kg.m2") = mass.I_21 "inertia tensor";
//   final parameter Real mass.I[2,2](quantity = "MomentOfInertia", unit = "kg.m2") = mass.I_22 "inertia tensor";
//   final parameter Real mass.I[2,3](quantity = "MomentOfInertia", unit = "kg.m2") = mass.I_32 "inertia tensor";
//   final parameter Real mass.I[3,1](quantity = "MomentOfInertia", unit = "kg.m2") = mass.I_31 "inertia tensor";
//   final parameter Real mass.I[3,2](quantity = "MomentOfInertia", unit = "kg.m2") = mass.I_32 "inertia tensor";
//   final parameter Real mass.I[3,3](quantity = "MomentOfInertia", unit = "kg.m2") = mass.I_33 "inertia tensor";
//   final parameter Real mass.R_start.T[1,1] = 1.0 "Transformation matrix from world frame to local frame";
//   final parameter Real mass.R_start.T[1,2] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real mass.R_start.T[1,3] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real mass.R_start.T[2,1] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real mass.R_start.T[2,2] = 1.0 "Transformation matrix from world frame to local frame";
//   final parameter Real mass.R_start.T[2,3] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real mass.R_start.T[3,1] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real mass.R_start.T[3,2] = 0.0 "Transformation matrix from world frame to local frame";
//   final parameter Real mass.R_start.T[3,3] = 1.0 "Transformation matrix from world frame to local frame";
//   final parameter Real mass.R_start.w[1](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   final parameter Real mass.R_start.w[2](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   final parameter Real mass.R_start.w[3](quantity = "AngularVelocity", unit = "rad/s") = 0.0 "Absolute angular velocity of local frame, resolved in local frame";
//   parameter Real mass.sphereDiameter(quantity = "Length", unit = "m", min = 0.0) = world.defaultBodyDiameter "Diameter of sphere";
//   final parameter Real mass.z_a_start[1](quantity = "AngularAcceleration", unit = "rad/s2") = Modelica.Mechanics.MultiBody.Frames.resolve2(mass.R_start, {mass.z_0_start[1], mass.z_0_start[2], mass.z_0_start[3]})[1] "Initial values of angular acceleration z_a = der(w_a), i.e., time derivative of angular velocity resolved in frame_a";
//   final parameter Real mass.z_a_start[2](quantity = "AngularAcceleration", unit = "rad/s2") = Modelica.Mechanics.MultiBody.Frames.resolve2(mass.R_start, {mass.z_0_start[1], mass.z_0_start[2], mass.z_0_start[3]})[2] "Initial values of angular acceleration z_a = der(w_a), i.e., time derivative of angular velocity resolved in frame_a";
//   final parameter Real mass.z_a_start[3](quantity = "AngularAcceleration", unit = "rad/s2") = Modelica.Mechanics.MultiBody.Frames.resolve2(mass.R_start, {mass.z_0_start[1], mass.z_0_start[2], mass.z_0_start[3]})[3] "Initial values of angular acceleration z_a = der(w_a), i.e., time derivative of angular velocity resolved in frame_a";
//   Real mass.z_a[1](quantity = "AngularAcceleration", unit = "rad/s2", start = Modelica.Mechanics.MultiBody.Frames.resolve2(mass.R_start, {mass.z_0_start[1], mass.z_0_start[2], mass.z_0_start[3]})[1], fixed = mass.z_0_fixed) "Absolute angular acceleration of frame_a resolved in frame_a";
//   Real mass.z_a[2](quantity = "AngularAcceleration", unit = "rad/s2", start = Modelica.Mechanics.MultiBody.Frames.resolve2(mass.R_start, {mass.z_0_start[1], mass.z_0_start[2], mass.z_0_start[3]})[2], fixed = mass.z_0_fixed) "Absolute angular acceleration of frame_a resolved in frame_a";
//   Real mass.z_a[3](quantity = "AngularAcceleration", unit = "rad/s2", start = Modelica.Mechanics.MultiBody.Frames.resolve2(mass.R_start, {mass.z_0_start[1], mass.z_0_start[2], mass.z_0_start[3]})[3], fixed = mass.z_0_fixed) "Absolute angular acceleration of frame_a resolved in frame_a";
//   protected parameter Real mass.Q_start[1] = Modelica.Mechanics.MultiBody.Frames.to_Q(mass.R_start, {0.0, 0.0, 0.0, 1.0})[1] "Quaternion orientation object from world frame to frame_a at initial time";
//   protected parameter Real mass.Q_start[2] = Modelica.Mechanics.MultiBody.Frames.to_Q(mass.R_start, {0.0, 0.0, 0.0, 1.0})[2] "Quaternion orientation object from world frame to frame_a at initial time";
//   protected parameter Real mass.Q_start[3] = Modelica.Mechanics.MultiBody.Frames.to_Q(mass.R_start, {0.0, 0.0, 0.0, 1.0})[3] "Quaternion orientation object from world frame to frame_a at initial time";
//   protected parameter Real mass.Q_start[4] = Modelica.Mechanics.MultiBody.Frames.to_Q(mass.R_start, {0.0, 0.0, 0.0, 1.0})[4] "Quaternion orientation object from world frame to frame_a at initial time";
//   parameter Real mass.cylinderDiameter(quantity = "Length", unit = "m", min = 0.0) = mass.sphereDiameter / 3.0 "Diameter of cylinder";
// equation
//   world.axisColor_x = {0, 0, 0};
//   world.axisColor_y = {world.axisColor_x[1], world.axisColor_x[2], world.axisColor_x[3]};
//   world.axisColor_z = {world.axisColor_x[1], world.axisColor_x[2], world.axisColor_x[3]};
//   world.gravityArrowColor = {0, 230, 0};
//   world.gravitySphereColor = {0, 230, 0};
//   assert(Modelica.Math.Vectors.length({world.n[1], world.n[2], world.n[3]}) > 1e-10,"Parameter n of World object is wrong (lenght(n) > 0 required)");
//   world.frame_b.r_0[1] = 0.0;
//   world.frame_b.r_0[2] = 0.0;
//   world.frame_b.r_0[3] = 0.0;
//   world.frame_b.R.T[1,1] = 1.0;
//   world.frame_b.R.T[1,2] = 0.0;
//   world.frame_b.R.T[1,3] = 0.0;
//   world.frame_b.R.T[2,1] = 0.0;
//   world.frame_b.R.T[2,2] = 1.0;
//   world.frame_b.R.T[2,3] = 0.0;
//   world.frame_b.R.T[3,1] = 0.0;
//   world.frame_b.R.T[3,2] = 0.0;
//   world.frame_b.R.T[3,3] = 1.0;
//   world.frame_b.R.w[1] = 0.0;
//   world.frame_b.R.w[2] = 0.0;
//   world.frame_b.R.w[3] = 0.0;
//   mass.sphereColor = {0, 128, 255};
//   mass.cylinderColor = {mass.sphereColor[1], mass.sphereColor[2], mass.sphereColor[3]};
//   mass.r_0[1] = mass.frame_a.r_0[1];
//   mass.r_0[2] = mass.frame_a.r_0[2];
//   mass.r_0[3] = mass.frame_a.r_0[3];
//   if true then
//   mass.Q[1] = 0.0;
//   mass.Q[2] = 0.0;
//   mass.Q[3] = 0.0;
//   mass.Q[4] = 1.0;
//   mass.phi[1] = 0.0;
//   mass.phi[2] = 0.0;
//   mass.phi[3] = 0.0;
//   mass.phi_d[1] = 0.0;
//   mass.phi_d[2] = 0.0;
//   mass.phi_d[3] = 0.0;
//   mass.phi_dd[1] = 0.0;
//   mass.phi_dd[2] = 0.0;
//   mass.phi_dd[3] = 0.0;
//   elseif mass.useQuaternions then
//   mass.frame_a.R = Modelica.Mechanics.MultiBody.Frames.from_Q({mass.Q[1], mass.Q[2], mass.Q[3], mass.Q[4]}, Modelica.Mechanics.MultiBody.Frames.Quaternions.angularVelocity2({mass.Q[1], mass.Q[2], mass.Q[3], mass.Q[4]}, {der(mass.Q[1]), der(mass.Q[2]), der(mass.Q[3]), der(mass.Q[4])}));
//   {0.0} = Modelica.Mechanics.MultiBody.Frames.Quaternions.orientationConstraint({mass.Q[1], mass.Q[2], mass.Q[3], mass.Q[4]});
//   mass.phi[1] = 0.0;
//   mass.phi[2] = 0.0;
//   mass.phi[3] = 0.0;
//   mass.phi_d[1] = 0.0;
//   mass.phi_d[2] = 0.0;
//   mass.phi_d[3] = 0.0;
//   mass.phi_dd[1] = 0.0;
//   mass.phi_dd[2] = 0.0;
//   mass.phi_dd[3] = 0.0;
//   else
//   mass.phi_d[1] = der(mass.phi[1]);
//   mass.phi_d[2] = der(mass.phi[2]);
//   mass.phi_d[3] = der(mass.phi[3]);
//   mass.phi_dd[1] = der(mass.phi_d[1]);
//   mass.phi_dd[2] = der(mass.phi_d[2]);
//   mass.phi_dd[3] = der(mass.phi_d[3]);
//   mass.frame_a.R = Modelica.Mechanics.MultiBody.Frames.axesRotations({mass.sequence_angleStates[1], mass.sequence_angleStates[2], mass.sequence_angleStates[3]}, {mass.phi[1], mass.phi[2], mass.phi[3]}, {mass.phi_d[1], mass.phi_d[2], mass.phi_d[3]});
//   mass.Q[1] = 0.0;
//   mass.Q[2] = 0.0;
//   mass.Q[3] = 0.0;
//   mass.Q[4] = 1.0;
//   end if;
//   mass.g_0 = Modelica.Mechanics.MultiBody.Parts.Body.world__gravityAcceleration({mass.frame_a.r_0[1], mass.frame_a.r_0[2], mass.frame_a.r_0[3]} + Modelica.Mechanics.MultiBody.Frames.resolve1(mass.frame_a.R, {mass.r_CM[1], mass.r_CM[2], mass.r_CM[3]}), world.gravityType, Modelica.Math.Vectors.normalize({world.n[1], world.n[2], world.n[3]}, 1e-13) * world.g, world.mue);
//   mass.v_0[1] = der(mass.frame_a.r_0[1]);
//   mass.v_0[2] = der(mass.frame_a.r_0[2]);
//   mass.v_0[3] = der(mass.frame_a.r_0[3]);
//   mass.a_0[1] = der(mass.v_0[1]);
//   mass.a_0[2] = der(mass.v_0[2]);
//   mass.a_0[3] = der(mass.v_0[3]);
//   mass.w_a = Modelica.Mechanics.MultiBody.Frames.angularVelocity2(mass.frame_a.R);
//   mass.z_a[1] = der(mass.w_a[1]);
//   mass.z_a[2] = der(mass.w_a[2]);
//   mass.z_a[3] = der(mass.w_a[3]);
//   mass.frame_a.f = (Modelica.Mechanics.MultiBody.Frames.resolve2(mass.frame_a.R, {mass.a_0[1] - mass.g_0[1], mass.a_0[2] - mass.g_0[2], mass.a_0[3] - mass.g_0[3]}) + {mass.z_a[2] * mass.r_CM[3] - mass.z_a[3] * mass.r_CM[2], mass.z_a[3] * mass.r_CM[1] - mass.z_a[1] * mass.r_CM[3], mass.z_a[1] * mass.r_CM[2] - mass.z_a[2] * mass.r_CM[1]} + {mass.w_a[2] * (mass.w_a[1] * mass.r_CM[2] - mass.w_a[2] * mass.r_CM[1]) - mass.w_a[3] * (mass.w_a[3] * mass.r_CM[1] - mass.w_a[1] * mass.r_CM[3]), mass.w_a[3] * (mass.w_a[2] * mass.r_CM[3] - mass.w_a[3] * mass.r_CM[2]) - mass.w_a[1] * (mass.w_a[1] * mass.r_CM[2] - mass.w_a[2] * mass.r_CM[1]), mass.w_a[1] * (mass.w_a[3] * mass.r_CM[1] - mass.w_a[1] * mass.r_CM[3]) - mass.w_a[2] * (mass.w_a[2] * mass.r_CM[3] - mass.w_a[3] * mass.r_CM[2])}) * mass.m;
//   mass.frame_a.t[1] = mass.I[1,1] * mass.z_a[1] + mass.I[1,2] * mass.z_a[2] + mass.I[1,3] * mass.z_a[3] + mass.w_a[2] * (mass.I[3,1] * mass.w_a[1] + mass.I[3,2] * mass.w_a[2] + mass.I[3,3] * mass.w_a[3]) - mass.w_a[3] * (mass.I[2,1] * mass.w_a[1] + mass.I[2,2] * mass.w_a[2] + mass.I[2,3] * mass.w_a[3]) + mass.r_CM[2] * mass.frame_a.f[3] - mass.r_CM[3] * mass.frame_a.f[2];
//   mass.frame_a.t[2] = mass.I[2,1] * mass.z_a[1] + mass.I[2,2] * mass.z_a[2] + mass.I[2,3] * mass.z_a[3] + mass.w_a[3] * (mass.I[1,1] * mass.w_a[1] + mass.I[1,2] * mass.w_a[2] + mass.I[1,3] * mass.w_a[3]) - mass.w_a[1] * (mass.I[3,1] * mass.w_a[1] + mass.I[3,2] * mass.w_a[2] + mass.I[3,3] * mass.w_a[3]) + mass.r_CM[3] * mass.frame_a.f[1] - mass.r_CM[1] * mass.frame_a.f[3];
//   mass.frame_a.t[3] = mass.I[3,1] * mass.z_a[1] + mass.I[3,2] * mass.z_a[2] + mass.I[3,3] * mass.z_a[3] + mass.w_a[1] * (mass.I[2,1] * mass.w_a[1] + mass.I[2,2] * mass.w_a[2] + mass.I[2,3] * mass.w_a[3]) - mass.w_a[2] * (mass.I[1,1] * mass.w_a[1] + mass.I[1,2] * mass.w_a[2] + mass.I[1,3] * mass.w_a[3]) + mass.r_CM[1] * mass.frame_a.f[2] - mass.r_CM[2] * mass.frame_a.f[1];
//   world.frame_b.t[1] + (-subModel1.frame_a.t[1]) = 0.0;
//   world.frame_b.t[2] + (-subModel1.frame_a.t[2]) = 0.0;
//   world.frame_b.t[3] + (-subModel1.frame_a.t[3]) = 0.0;
//   world.frame_b.f[1] + (-subModel1.frame_a.f[1]) = 0.0;
//   world.frame_b.f[2] + (-subModel1.frame_a.f[2]) = 0.0;
//   world.frame_b.f[3] + (-subModel1.frame_a.f[3]) = 0.0;
//   subModel1.frame_a.t[1] + mass.frame_a.t[1] = 0.0;
//   subModel1.frame_a.t[2] + mass.frame_a.t[2] = 0.0;
//   subModel1.frame_a.t[3] + mass.frame_a.t[3] = 0.0;
//   subModel1.frame_a.f[1] + mass.frame_a.f[1] = 0.0;
//   subModel1.frame_a.f[2] + mass.frame_a.f[2] = 0.0;
//   subModel1.frame_a.f[3] + mass.frame_a.f[3] = 0.0;
//   mass.frame_a.r_0[1] = subModel1.frame_a.r_0[1];
//   mass.frame_a.r_0[2] = subModel1.frame_a.r_0[2];
//   mass.frame_a.r_0[3] = subModel1.frame_a.r_0[3];
//   mass.frame_a.R.T[1,1] = subModel1.frame_a.R.T[1,1];
//   mass.frame_a.R.T[2,1] = subModel1.frame_a.R.T[2,1];
//   mass.frame_a.R.T[3,1] = subModel1.frame_a.R.T[3,1];
//   mass.frame_a.R.T[1,2] = subModel1.frame_a.R.T[1,2];
//   mass.frame_a.R.T[2,2] = subModel1.frame_a.R.T[2,2];
//   mass.frame_a.R.T[3,2] = subModel1.frame_a.R.T[3,2];
//   mass.frame_a.R.T[1,3] = subModel1.frame_a.R.T[1,3];
//   mass.frame_a.R.T[2,3] = subModel1.frame_a.R.T[2,3];
//   mass.frame_a.R.T[3,3] = subModel1.frame_a.R.T[3,3];
//   mass.frame_a.R.w[1] = subModel1.frame_a.R.w[1];
//   mass.frame_a.R.w[2] = subModel1.frame_a.R.w[2];
//   mass.frame_a.R.w[3] = subModel1.frame_a.R.w[3];
//   subModel1.frame_a.r_0[1] = world.frame_b.r_0[1];
//   subModel1.frame_a.r_0[2] = world.frame_b.r_0[2];
//   subModel1.frame_a.r_0[3] = world.frame_b.r_0[3];
//   subModel1.frame_a.R.T[1,1] = world.frame_b.R.T[1,1];
//   subModel1.frame_a.R.T[2,1] = world.frame_b.R.T[2,1];
//   subModel1.frame_a.R.T[3,1] = world.frame_b.R.T[3,1];
//   subModel1.frame_a.R.T[1,2] = world.frame_b.R.T[1,2];
//   subModel1.frame_a.R.T[2,2] = world.frame_b.R.T[2,2];
//   subModel1.frame_a.R.T[3,2] = world.frame_b.R.T[3,2];
//   subModel1.frame_a.R.T[1,3] = world.frame_b.R.T[1,3];
//   subModel1.frame_a.R.T[2,3] = world.frame_b.R.T[2,3];
//   subModel1.frame_a.R.T[3,3] = world.frame_b.R.T[3,3];
//   subModel1.frame_a.R.w[1] = world.frame_b.R.w[1];
//   subModel1.frame_a.R.w[2] = world.frame_b.R.w[2];
//   subModel1.frame_a.R.w[3] = world.frame_b.R.w[3];
// end Test;
// endResult
