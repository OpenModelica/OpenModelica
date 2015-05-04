model M1
  Boolean b[1] = {time>0.5};
  Real r;
  Real i;
equation
  der(r) = 1;
algorithm
  when b then
    i := time;
  end when;
end M1;

model M2
  Boolean b[2] = {time>0.5,time>0.75};
  Real r;
  Real i;
equation
  der(r) = 1;
algorithm
  when b then
    i := time;
  end when;
end M2;

model M3
  Boolean b[2];
  Boolean b1[2] = {time>0.5,time>0.75};
  Boolean b2[2] = {time>1.5,time>1.75};
  Real r;
  Real i;
equation
  der(r) = 1;
algorithm
  b := if r<1 then b1 else b2;
  when b then
    i := time;
  end when;
end M3;

