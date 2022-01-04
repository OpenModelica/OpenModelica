package Synchronous

  package Constructors

    // Inferred clock with nothing to infer from
    model inferredClock1
      Integer y(start=0);
    equation
      when Clock() then
        // periodic clock that ticks at 0.0, 1.0, 2.0, ...
        y = previous(y) + 1;
      end when;
    end inferredClock1;

    // Inferred clock from real interval clock
    model inferredClock2
      Integer tempVar(start=0);
      Integer y(start=0);
    equation
      when Clock(0.25) then
        // periodic clock that ticks at 0.0, 0.25, 0.5, ...
        tempVar = 1;
      end when;
      when Clock() then
        // ticks together with above clock
        y = previous(y) + tempVar;
      end when;
    end inferredClock2;

    // Rationla clock with constant interval
    model rationalClock1
      Integer y(start = 0);
    equation
      when Clock(2, 10) then
        // periodic clock that ticks at 0, 2/10, 4/10, ...
        y = previous(y) + 1;
      end when;
    end rationalClock1;

    // Rational clock with changing intervalCounter
    model rationalClock2
      Integer nextInterval(start = 2);
      Real y(start = 0);
    equation
      when Clock(nextInterval, 10) then
        // interval clock that ticks at 0, 3/10, 7/10, ...
        nextInterval = previous(nextInterval) + 1;
        y = previous(y) + 1;
      end when;
    end rationalClock2;

    model eventClock
      Real x;
      Integer y1(start=0), y2(start=0);
      parameter Real startInterval = 0.5;
    equation
      x = sin(10*Modelica.Constants.pi*time);
      when Clock(x < 0) then
        y1 = previous(y1) + 1;  // ticks: 0.1, 0.3, 0.5, 0.7, 0.9
      end when;
      when Clock(x > 0, startInterval) then
        y2 = previous(y2) + 1;  // ticks: 0.0, 0.2, 0.4, 0.6, 0.8, 1.0
      end when;
      annotation(uses(Modelica(version="4.0.0")));
    end eventClock;

    // TODO: Add solver clock
  end Constructors;

  package SubClocks

    model subSampleTest
      Clock u = Clock(1, 10);         // ticks: 0, 1/10, 2/10, 3/10, ...
      Clock s1 = subSample(u, 4);     // ticks: 0, 4/10, 8/10, ...
      Integer y(start=0);
    equation
      when s1 then
        y = previous(y) + 1;
      end when;
    end subSampleTest;

    model subSuperSample1
      Clock u = Clock(1/10);          // ticks: 0, 1/10, 2/10, 3/10, ...
      Clock s1 = subSample(u, 4);     // ticks: 0, 4/10, 8/10, ...
      Clock s2 = superSample(s1, 2);  // ticks: 0, 2/10, 4/10, 6/10, 8/10, ...
      Integer y1(start=0), y2(start=0);
    equation
      when s1 then
        y1 = previous(y1) + 1;
      end when;
      when s2 then
        y2 = previous(y2) + 1;
      end when;
    end subSuperSample1;

    // Sub and super sample of event clock
    model subSuperSample2
      Real x;
      Clock u = Clock(x > 0);         // ticks: 0.0, 0.1, 0.2, ...
      Clock s1 = subSample(u, 4);     // ticks: 0.0, 0.4, 0.8, ...
      Clock s2 = superSample(s1, 2);  // ticks: 0.0, 0.2, 0.4, ...
      Integer y1(start=0), y2(start=0);
    equation
      x = sin(Modelica.Constants.pi*20*time);
      when s1 then
        y1 = previous(y1) + 1;
      end when;
      when s2 then
        y2 = previous(y2) + 1;
      end when;
      annotation(uses(Modelica(version="4.0.0")));
    end subSuperSample2;

    // Shift sample of rational clock
    model shiftSample1
      Clock u  = Clock(3, 10);            // ticks: 0, 3/10, 6/10, 9/10, 12/10, ...
      Clock s1 = shiftSample(u, 1, 3);    // ticks: 1/10, 4/10, 7/10, 1, ...
      Clock s2 = shiftSample(s1, 2);      // ticks: 7/10, 1, ...
      Integer y1(start=0), y2(start=0);
    equation
      when s1 then
        y1 = previous(y1) + 1;
      end when;

      when s2 then
        y2 = previous(y2) + 1;
      end when;
    end shiftSample1;

    // Shift sample of event clock
    model shiftSample2
      Clock u  = Clock(sin(20*Modelica.Constants.pi*time) > 0, 10); // ticks: 0.0, 0.1, 0.2, ... 
      Clock s1 = shiftSample(u, 2);    // ticks: 0.2, 0.3, 0.4, ...
      Integer y1(start=0);
    equation
      when s1 then
        y1 = previous(y1) + 1;
      end when;
      annotation(uses(Modelica(version="4.0.0")));
    end shiftSample2;

    // Back sample of rational clock
    model backSample1
      Clock u  = Clock(3, 10);          // ticks: 0, 3/10, 6/10, 
      Clock s1 = shiftSample(u, 3);     // ticks: 9/10, 12/10, 
      Clock b1 = backSample(s1, 2);     // ticks: 3/10, 6/10, 
      Clock s2 = shiftSample(u, 2, 3);  // ticks: 2/10, 5/10, 
      Clock b2 = backSample(s2, 1, 3);  // ticks: 1/10, 4/10, 
      Integer y1(start=0), y2(start=0);
    equation
      when b1 then
        y1 = previous(y1) + 1;
      end when;
      when b2 then
        y2 = previous(y2) + 1;
      end when;
    end backSample1;

    // Back sample of event clock
    model backSample2
      Clock u = Clock(sin(2*Modelica.Constants.pi*time) > 0, 0.5);   // ticks: 0, 1.0, 2.0, 3.0, ...
      Clock s1 = shiftSample(u, 3);               // ticks: 3.0, 4.0, ...
      Clock b1 = backSample(s1, 2);               // ticks: 1.0, 2.0, ...
      Integer y1(start=0);
    equation
      when b1 then
        y1 = previous(y1) + 1;
      end when;
      annotation(uses(Modelica(version="4.0.0")));
    end backSample2;

    // noClock() and it's difference to sample(hold())
    model noClock1
      Clock clk1 = Clock(0.2);          // ticks: 0, 0.2, 0.4, 0.6, ...
      Clock clk2 = subSample(clk1, 2);  // ticks: 0, 0.4, 0.8, 1.2 ...
      Real y1(start = 0), y2(start = 0);
      Real z(start=0);
    equation
      when clk1 then
        y1 = previous(y1) + 1;  // 1, 2, 3, 4, ...
      end when;
      when clk2 then
        y2 = noClock(y1);       // 1, 3, 5, ...
        z = sample(hold(y1));   // 0, 2, 4, ...
      end when;
    end noClock1;
  end SubClocks;

  package Conversion

    // sample variable
    model sampleVar
      Clock clk = Clock(3/10);  // ticks: 0, 3/10, 6/10, 9/10, ...
      Real x(start=1);
      Real xc;
    initial equation
      der(x) = 0;
    equation
      der(x) + x = 2;
      xc = sample(x, clk);    // yc at the first clock tick is 2, not start value 1
    end sampleVar;

    // inferred sample variable
    model inferredSampleVar
      Clock clk = Clock(0.3);  // ticks: 0, 0.3, 0.6, 0.9, ...
      Real x(start=1, fixed=true);
      Real xc;
    equation 
      der(x) = 2*x;
      when clk then
        xc = sample(x);
      end when;
    end inferredSampleVar;

    // Hold clocked variable
    model holdVar
      Clock clk1 = Clock(0.3);  // ticks: 0, 0.3, 0.6, 0.9, ...
      Real xc(start = 0), x;
    equation
      when clk1 then
        xc = previous(xc) + 1;
      end when;
      x = hold(xc);
    end holdVar;

    model firstTickBool
      Clock clk1 = Clock(0.5);    // ticks: 0, 0.5, 1.0, ...
      Clock clk2 = Clock(hold(clk1_firstTick)); // ticks: 0
      Boolean clk1_firstTick(start=false);
      Integer y(start=0);
    equation
      clk1_firstTick = firstTick(clk1);
      when clk2 then
        y = previous(y) + 1;
      end when;
    end firstTickBool;

    model intervalBaseClock
      constant Real startInterval = 0.5;
      Clock clk1 = Clock(x>0, startInterval); // ticks: 0, 0.1, 0.2, ...
      Clock clk2 = Clock(nextInterval, 10);   // ticks: 0, 3/10, 7/10, ...
      Integer nextInterval(start = 2);
      Real intv1 = interval(clk1);
      Real intv2 = interval(clk2);
      Real intv3(start=0);
      Real x = sin(Modelica.Constants.pi*20*time);
    equation
      when clk2 then
        nextInterval = previous(nextInterval) + 1;
      end when;
      when Clock(0.25) then
        intv3 = interval();
      end when;
      annotation(uses(Modelica(version="4.0.0")));
    end intervalBaseClock;

    model intervalSubClock

    end intervalSubClock;






    model manualEuler
      input Real u;
      parameter Real x_start = 1;
      Real x(start = x_start); // previous(x) = x_start at first clock tick
      Real der_x(start = 0);   // previous(der_x) = 0 at first clock tick
    protected
      Boolean first(start = true);
    equation
      when Clock() then
        first = false;
        if previous(first) then
          // first clock tick (initialize system)
          x = previous (x);
        else
          // second and further clock tick
          x = previous(x) + interval() * previous(der_x);
        end if;
        der_x = -x + u;
      end when;
    end manualEuler;

    block MixedController
      parameter Real T "Time constant of continuous PI controller";
      parameter Real k "Gain of continuous PI controller";
      input Real y_ref, y_meas;
      Real y;
      output Real yc;
      Real z(start = 0);
      Real xc(start = 1, fixed = true);
      Clock c = Clock(Clock(0.1), solverMethod="ImplicitEuler");
    protected
      Real uc;
      Real Ts = interval(uc);
    equation
      /* Continuous-time, inverse model */
      uc = sample(y_ref, c);
      der(xc) = uc;
      /* PI controller */
      z = if  firstTick() then 0 else
      previous(z) + Ts / T * (uc - y_meas);
      y = xc + k * (xc + uc);
      yc = hold (y);
    end MixedController;
  end Conversion;

end Synchronous;