package AcausalComponent "acausal components exported with --fmuAcausalComponent"
  connector Pin
    Real v;
    flow Real i;
  end Pin;

  model RC "a resistor in series with a capacitor to ground"
    parameter Real R = 1, C = 1;
    Pin p;
    Real vc(start = 0, fixed = true);
  equation
    p.v - vc = R*p.i;
    C*der(vc) = p.i;
  end RC;

  model Source "an ideal voltage source between two pins: no states"
    parameter Real V = 1;
    Pin p, n;
  equation
    p.v - n.v = V;
    p.i + n.i = 0;
  end Source;
end AcausalComponent;
