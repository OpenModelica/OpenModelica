within ;
model EventClockAndClassic
  Real f = cos(5*time*Modelica.Constants.pi);
  Boolean condition = f > 0;
  Integer count1(start = 0);
  Integer count1Shift(start = 0);
  Clock c = Clock(condition);
  Clock cShift = shiftSample(c, 1);
  Integer count2;
initial equation
  count2 = 0;
equation
  when c then
    count1 = previous(count1) + 1;
  end when;
  when cShift then
    count1Shift = previous(count1Shift) + 1;
  end when;
  when condition then
    count2 = pre(count2) + 1;
  end when;
  annotation (experiment(StopTime=1));
end EventClockAndClassic;
