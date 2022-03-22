within ;
model EventSubClock "See Modelica 3.5 spec, section 16.5.2 Sub-clock conversion operators"
  Clock c = Clock(time > 0.5);
  Clock c1 = superSample(c, 2);
  Integer n(start=1, fixed=true);
equation
  when c1 then
    n = previous(n) + 1;
  end when;
end EventSubClock;
