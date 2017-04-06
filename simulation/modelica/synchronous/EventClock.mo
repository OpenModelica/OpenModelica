within ;
model EventClock "See Modelica 3.3 spec, section 16.3 Clock Constructors"
  Integer nextInterval(start = 1);
  Real nextTick(start = 0);
equation
  when Clock(time > hold(nextTick) / 210) then
    nextInterval = previous(nextInterval) + 1;
    nextTick = previous(nextTick) + nextInterval;
  end when;
  annotation (uses(Modelica(version="3.2.2")));
end EventClock;
