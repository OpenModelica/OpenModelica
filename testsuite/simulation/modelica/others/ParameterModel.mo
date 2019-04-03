model M2
  parameter Real a = 1;
  parameter Real b = 2*a;
end M2;

model M1
  M2 m2;
  parameter Real a = 1;
  M2 m2_2;
end M1;


