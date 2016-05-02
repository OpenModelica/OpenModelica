within ;
model ClockInterval

    //see Modelica Specification 3.3. p 194
    Real y(start=0);
    Integer nextInterval(start=2);// first interval = 2/100
    Clock c = Clock(nextInterval,100);
equation

when c then
    // interval clock that ticks at 0, 0.02, 0.05, 0.09, ...
    nextInterval = previous(nextInterval) + 1;
    y = previous(y) + 1;
end when;
  annotation (uses(Modelica(version="3.2.1")));
end ClockInterval;
