// name:     Epidemics1
// keywords: der terminate
// status:   correct
//
//
//

model Epidemics1
Real Indv(start=0.005);
Real S(start=0.995);
Real R(start=0);
parameter Real tau=0.8;
parameter Real k=4.0 "recovery coefficient (from 4people infected one is recoved)" ;
equation
  der(Indv) = tau * Indv * S - Indv / k;
  der(S) = -tau * Indv * S;
  der(R) = Indv/k;
  when (Indv < 10e-5) then
    terminate("Simulation terminated");
  end when;
  when (S < 10e-5) then
    terminate("Simulation terminated");
  end when;
end Epidemics1;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// Result:
// class Epidemics1
//   Real Indv(start = 0.005);
//   Real S(start = 0.995);
//   Real R(start = 0.0);
//   parameter Real tau = 0.8;
//   parameter Real k = 4.0 "recovery coefficient (from 4people infected one is recoved)";
// equation
//   der(Indv) = tau * Indv * S - Indv / k;
//   der(S) = (-tau) * Indv * S;
//   der(R) = Indv / k;
//   when Indv < 0.0001 then
//   terminate("Simulation terminated");
//   end when;
//   when S < 0.0001 then
//   terminate("Simulation terminated");
//   end when;
// end Epidemics1;
// endResult
