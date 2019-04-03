model SimpleTriggeredTrapezoid "C2M2L_OM Range Pack Internals includes a triggered trapezoid.  This requires when equations and initial equations"
    Modelica.Blocks.Logical.TriggeredTrapezoid tt(amplitude = 1, rising = 0.5, falling = 0.5, offset = 1);
    // The PARC one doesn't work.
    //TT tt(amplitude = 1, rising = 0.5, falling = 0.5, offset = 1);
    Boolean b;
  equation
    b = if time > 5 then if time < 9 then true else false else false;
    connect(b,tt.u);
    annotation(experiment(StartTime = 0.0, StopTime = 10.0, Tolerance = 0.000001));
end SimpleTriggeredTrapezoid;
