within ;
model functionEvaluation

function collisionDetection
  input Integer maxContacts;
  input Real r_a[3];
  input Modelica.Mechanics.MultiBody.Frames.Quaternions.Orientation Q_a;
  input String id_a;
  input Real r_b[3];
  input Modelica.Mechanics.MultiBody.Frames.Quaternions.Orientation Q_b;
  input String id_b;
  output Real numberOfContactPoints;
  output Real cp_a[maxContacts, 3];
  output Real cp_b[maxContacts, 3];
  output Real depth_a[maxContacts];
  output Real depth_b[maxContacts];
  output Real normals_a[maxContacts, 3];
  output Real normals_b[maxContacts, 3];
algorithm
  if r_a[3] > 5 then
    numberOfContactPoints := 0;
    cp_a[1, :] := zeros(3);
    cp_b[1, :] := zeros(3);
  else
    numberOfContactPoints := 1;
    cp_a[1, :] := Modelica.Mechanics.MultiBody.Frames.resolve2(Modelica.Mechanics.MultiBody.Frames.from_Q(Q_a, {0, 0, 0}), {r_a[1], r_a[2], 0});
    cp_b[1, :] := Modelica.Mechanics.MultiBody.Frames.resolve2(Modelica.Mechanics.MultiBody.Frames.from_Q(Q_b, {0, 0, 0}), {r_a[1], r_a[2], 0});
  end if;
  depth_a := {5 - r_a[3]};
  depth_b := {0.0};
  normals_a := {{0,  0, 1}};
  normals_b := {{0, 0, 1}};
  annotation(Inline = false);
end collisionDetection;

  inner Modelica.Mechanics.MultiBody.World world    annotation (Placement(transformation(extent={{-60,20},{-40,40}})));
  parameter Integer maxContacts = 1;
  parameter Real r_a[3] = {0,0,1};
  parameter Modelica.Mechanics.MultiBody.Frames.Quaternions.Orientation Q_a = Modelica.Mechanics.MultiBody.Frames.Quaternions.nullRotation();
  parameter String id_a = "s1";
  parameter Real r_b[3] = {0,0,1};
  parameter Modelica.Mechanics.MultiBody.Frames.Quaternions.Orientation Q_b = Modelica.Mechanics.MultiBody.Frames.Quaternions.nullRotation();
  parameter String id_b = "s2";
  Real numberOfContactPoints;
  Real cp_a[maxContacts, 3];
  Real cp_b[maxContacts, 3];
  Real depth_a[maxContacts];
  Real depth_b[maxContacts];
  Real normals_a[maxContacts, 3];
  Real normals_b[maxContacts, 3];
equation
  (numberOfContactPoints,cp_a,cp_b,depth_a,depth_b,normals_a,normals_b) = collisionDetection(maxContacts,r_a,Q_a,id_a,r_b,Q_b,id_b);
  annotation (uses(Modelica(version="3.2.1")));
end functionEvaluation;
