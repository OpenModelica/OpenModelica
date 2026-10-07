// name:     Modification16 [bug #1238]
// keywords: modification
// status:   correct
//


model Modification16

  model Inertia
    parameter Real J;
    Real phi;
    Real w;
  equation
    phi = 1;
    w = 1;
  end Inertia;

  Inertia inertia1(w.start = 1, w.stateSelect=StateSelect.always, J=1, phi.start=0, phi.stateSelect=StateSelect.always);
end Modification16;

// Result:
// class Modification16
//   parameter Real inertia1.J = 1.0;
//   Real inertia1.phi(start = 0.0, stateSelect = StateSelect.always);
//   Real inertia1.w(start = 1.0, stateSelect = StateSelect.always);
// equation
//   inertia1.phi = 1.0;
//   inertia1.w = 1.0;
// end Modification16;
// endResult
