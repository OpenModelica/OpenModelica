function cross_ab
  input Real V1[:];
  input Real V2[:];
  output Real V[size(V1, 1)];
algorithm
  V[1]:=V1[2]*V2[3] - V1[3]*V2[2];
  V[2]:=V1[3]*V2[1] - V1[1]*V2[3];
  V[3]:=V1[1]*V2[2] - V1[2]*V2[1];
end cross_ab;


model FuncCrossTest
  Real r_1[3]={1,2,3};
  Real r_2[3]={3,4,5};
  Real r_3[3]={1,1,1};
  Real r[3];
equation
  r = r_3 + cross_ab(r_1,r_2);
end FuncCrossTest;

