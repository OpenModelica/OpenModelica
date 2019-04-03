package Chattering "Models with chattering behaviour"
    model ChatteringEvents1
      "Exhibits chattering after t = 0.5, with generated events"
      Real x(start=1, fixed=true);
      Real y;
      Real z;
    equation
      z = if x > 0 then -1 else 1;
      y = 2*z;
      der(x) = y;
      annotation (Documentation(info="<html>
<p>After t = 0.5, chattering takes place, due to the discontinuity in the right hand side of the first equation.</p>
<p>Chattering can be detected because lots of tightly spaced events are generated. The feedback to the user should allow to identify the equation from which the zero crossing function that generates the events originates.</p>
</html>"), experiment(StopTime=1));
    end ChatteringEvents1;

    model ChatteringEvents2
      "Exhibits chattering after t = 0.422, with generated events"
      Real x(start=1, fixed=true);
      Real w(start=0, fixed=true);
      Real y;
      Real z;
    equation
      der(w) = -w + 1;
      z = if x > 0 then -1 else 1;
      y = 2*(z - w);
      der(x) = y;
      annotation (Documentation(info="<html>
<p>After t = 0.5, chattering takes place, due to the discontinuity in the right hand side of the second equation.</p>
<p>Chattering can be detected because lots of tightly spaced events are generated. The feedback to the user should allow to identify the equation from which the zero crossing function that generates the events originates.</p>
</html>"), experiment(StopTime=1));
    end ChatteringEvents2;

    model ChatteringNoEvents1
      "Exhibits chattering after t = 0.5, without generated events"
      Real x(start=1, fixed=true);
      Real y;
      Real z;
    equation
      z = noEvent(if x > 0 then -1 else 1);
      y = 2*z;
      der(x) = y;
      annotation (Documentation(info="<html>
<p>After t = 0.5, chattering takes place, due to the discontinuity in the right hand side of the first equation. The discontinuity does not generate state events, thanks to the noEvent operator.</p>
<p>If a variable-step-size integration algorithm with error control is used, the time step will be reduced to very small values once the discontinuity is hit, and this can be detected by monitoring the value of time at each time step.</p>
<p>Variable step size solvers usually allow to identify which state variable(s) give the biggest contribution to the error estimate, thus causing the step size reduction. The corresponding derivative shows very high frequency oscillations between two values. The end user can then use the BLT navigation functionality of the debugger to investigate which variable/equation is introducing the discontinuity.</p>
</html>"), experiment(StopTime=1));
    end ChatteringNoEvents1;

    model ChatteringNoEvents2
      "Exhibits chattering after t = 0.422, without generated events"
      Real x(start=1, fixed=true);
      Real w(start=0, fixed=true);
      Real y;
      Real z;
    equation
      der(w) = -w + 1;
      z = noEvent(if x > 0 then -1 else 1);
      y = 2*(z - w);
      der(x) = y;
      annotation (Documentation(info="<html>
<p>After t = 0.422, chattering takes place, due to the discontinuity in the right hand side of the second equation. The discontinuity does not generate state events, thanks to the noEvent operator.</p>
<p>If a variable-step-size integration algorithm with error control is used, the time step will be reduced to very small values once the discontinuity is hit, and this can be detected by monitoring the value of time at each time step.</p>
<p>Variable step size solvers usually allow to identify which state variable(s) give the biggest contribution to the error estimate (x, in this case), thus causing the step size reduction. The corresponding derivative shows very high frequency oscillations between two values. The end user can then use the BLT navigation functionality of the debugger to investigate which variable/equation is introducing the discontinuity.</p>
</html>"), experiment(StopTime=1));
    end ChatteringNoEvents2;

    model ChatteringFunction1
      "Exhibits chattering after t = 0.4, without generated events"
      Real x(start=1, fixed=true);
      Real y;
      Real z;
    equation
      z = Functions.f_sign(x);
      y = 2*z;
      der(x) = y;
      annotation (Documentation(info="<html>
<p>After t = 0.5, chattering takes place, due to the discontinuity in the right hand side of the first equation. The discontinuity is caused by a discontinuous function, which does not generate events.</p>
<p>If a variable-step-size integration algorithm with error control is used, the time step will be reduced to very small values once the discontinuity is hit, and this can be detected by monitoring the value of time at each time step.</p>
<p>Variable step size solvers usually allow to identify which state variable(s) give the biggest contribution to the error estimate, thus causing the step size reduction. The corresponding derivative shows very high frequency oscillations between two values. The end user can then use the BLT navigation functionality of the debugger to investigate which variable/equation is introducing the discontinuity.</p>
</html>"), experiment(StopTime=1));
    end ChatteringFunction1;

    model ChatteringFunction2
      "Exhibits chattering after t = 0.422, without generated events"
      Real x(start=1, fixed=true);
      Real w(start=0, fixed=true);
      Real y;
      Real z;
    equation
      der(w) = -w + 1;
      z = Functions.f_sign(x);
      y = 2*(z - w);
      der(x) = y;
      annotation (Documentation(info="<html>
<p>After t = 0.422, chattering takes place, due to the discontinuity in the right hand side of the second equation. The discontinuity is caused by a discontinuous function, which does not generate events.</p>
<p>If a variable-step-size integration algorithm with error control is used, the time step will be reduced to very small values once the discontinuity is hit, and this can be detected by monitoring the value of time at each time step.</p>
<p>Variable step size solvers usually allow to identify which state variable(s) give the biggest contribution to the error estimate (x, in this case), thus causing the step size reduction. The corresponding derivative shows very high frequency oscillations between two values. The end user can then use the BLT navigation functionality of the debugger to investigate which variable/equation is introducing the discontinuity.</p>
</html>"), experiment(StopTime=1));
    end ChatteringFunction2;

  package Functions
    function f_sign "Computes the signum function"
      input Real x;
      output Real y;
    algorithm
      if x > 0 then
        y := 1;
      elseif x < 0 then
        y := -1;
      else
        y := 0;
      end if;
      annotation (Inline=false);
    end f_sign;
  end Functions;
end Chattering;

