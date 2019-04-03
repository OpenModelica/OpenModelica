within ;
model boolSubClocks
// Rational interval clock 1
Clock u = Clock(3, 10); // ticks: 0, 3/10, 6/10
Clock y1 = shiftSample(u,3); // ticks: 9/10, 12/10,
Clock y2 = backSample(y1,2); // ticks: 3/10, 6/10,
//Clock y3 = backSample(y1,4); // error (ticks before u)
Clock y4 = shiftSample(u,2,3); // ticks: 2/10, 5/10,
Clock y5 = backSample(y4,1,3); // ticks: 1/10, 4/10,
// Boolean clock
Clock v = Clock(sin(2*Modelica.Constants.pi*time) > 0, 0); // ticks: 0, 1.0, 2.0, 3.0,
Clock z1 = shiftSample(v,3); // ticks: 3.0, 4.0,
Clock z2 = backSample(z1,2); // ticks: 1.0, 2.0,

Real x1,x2,x3,x4,x5,x6;
Real a1,a2,a3;
Real b1,b2;
equation
  when sample(1.3, 0.5) then
    b1 = time;
  end when;
  when u then
    x1 = sample(time);
  end when;
  when y1 then
    x2 = sample(time);
  end when;
  when y2 then
    x3 = sample(time);
  end when;
  when y4 then
    x4 = sample(time);
  end when;
  when y5 then
    x5 = sample(time);
  end when;
  when u then
    x6 = sample(time);
  end when;

    when v then
    a1 = sample(time);
  end when;
  when z1 then
    a2 = sample(time);
  end when;
  when z2 then
    a3 = sample(time);
  end when;
  when sample(0.8, 1.5) then
    b2 = 1.5*time;
  end when;
  annotation (experiment(StopTime=5));
end boolSubClocks;
