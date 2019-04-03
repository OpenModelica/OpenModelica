package SynchronousFeatures "Fundamentals of Synchronous Control in Modelica,  Hilding Elmqvist, Martin Otter and Sven-Erik Mattsson"
  // BTH: For efficiency reasons copy-pasted this units from the MSL to avoid loading the whole MSL in tests
  type Mass = Real (
    quantity="Mass",
    final unit="kg",
    min=0);
  type Length = Real (final quantity="Length", final unit="m");
  type Position = Length;
  type Velocity = Real (final quantity="Velocity", final unit="m/s");
  type Force = Real (final quantity="Force", final unit="N");

  package BaseClasses
    type TranslationalSpringConstant = Real (final unit="N/m");
    type TranslationalDampingConstant = Real (final unit="N.s/m");

    model MassWithSpringDamper
      parameter SynchronousFeatures.Mass m=1;
      parameter TranslationalSpringConstant k=1;
      parameter TranslationalDampingConstant d=0.1;
      SynchronousFeatures.Position x(start=1,fixed=true) "Position";
      SynchronousFeatures.Velocity v(start=0,fixed=true) "Velocity";
      SynchronousFeatures.Force f "Force";
    equation
      der(x) = v;
      m*der(v) = f - k*x - d*v;
    end MassWithSpringDamper;
  end BaseClasses;

  model SpeedControl "Plant and Controller Partitioning"
    extends BaseClasses.MassWithSpringDamper;
    parameter Real K=20 "Gain of speed P controller";
    parameter SynchronousFeatures.Velocity vref=100 "Speed ref.";
    discrete Real vd;
    discrete Real u(start=0);
  equation
    // speed sensor
    vd = sample(v, Clock(0.01));
    // P controller for speed
    u = K*(vref - vd);
    // force actuator
    f = hold(u);
  end SpeedControl;

  model ControlledMassBasic "Discrete-time State Variables"
    extends BaseClasses.MassWithSpringDamper;
    parameter Real KOuter = 10 "Gain of position PI controller";
    parameter Real KInner = 20 "Gain of speed P controller";
    parameter Real Ti = 10 "Integral time for pos. PI controller";
    parameter Real xref = 10 "Position reference";
    discrete Real xd;
    discrete Real eOuter;
    discrete Real intE(start=0);
    discrete Real uOuter;
    discrete Real vd;
    discrete Real vref;
    discrete Real uInner(start=0);
  equation
    // position sensor
    xd = sample(x, Clock(0.01));
    // outer PI controller for position
    eOuter = xref-xd;
    intE = previous(intE) + eOuter;
    uOuter = KOuter*(eOuter + intE/Ti);
    // speed sensor
    vd = sample(v);
    // inner P controller for speed
    vref = uOuter;
    uInner = KInner*(vref-vd);
    // force actuator
    f = hold(uInner);
  end ControlledMassBasic;

  model ControlledMass "Phase of Clock"
    extends BaseClasses.MassWithSpringDamper;
    parameter Real KOuter = 10 "Gain of position PI controller";
    parameter Real KInner = 20 "Gain of speed P controller";
    parameter Real Ti = 10 "Integral time for pos. PI controller";
    parameter Real xref = 10 "Position reference";
    discrete Real xd;
    discrete Real eOuter;
    discrete Real intE(start=0);
    discrete Real uOuter(start=0);
    discrete Real xdFast;
    discrete Real vd;
    discrete Real vref;
    discrete Real uInner(start=0);
    Clock cControl = Clock(0.01);
    Clock cOuter = subSample(shiftSample(cControl, 2, 3), 5);
    Clock cFast = superSample(cControl, 2);
  equation
    // position sensor
    xd = sample(x, cOuter);
    // outer PI controller for position
    eOuter = xref-xd;
    intE = previous(intE) + eOuter;
    uOuter = KOuter*(eOuter + intE/Ti);
    // speed estimation
    xdFast = sample(x, cFast);
    vd = subSample((xdFast-previous(xdFast))/interval(), 2);
    // inner P controller for speed
    vref = backSample(superSample(uOuter, 5), 2, 3);
    uInner = KInner*(vref-vd);
    // force actuator
    f = hold(uInner);
  end ControlledMass;

  model VaryingClock "Varying Interval Clocks"
    Integer nextInterval(start=1);
    Clock c = Clock(nextInterval, 100);
    Real v(start=0.2);
    Real d = interval(v);
    Real d0 = previous(nextInterval)/100.0;
  equation
    when c then
      nextInterval = previous(nextInterval) + 1;
      v = previous(v) + 1;
    end when;
  end VaryingClock;
end SynchronousFeatures;
