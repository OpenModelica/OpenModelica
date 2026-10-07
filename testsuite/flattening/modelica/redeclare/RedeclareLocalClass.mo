// name:     RedeclareLocalClass
// keywords: redeclare,type
// status:   correct
//
// Checks that the compiler correctly handles redeclarations of local classes.
//

package OnePhase = PartialPhaseSystem(n = 2);

package PartialPhaseSystem 
  constant Integer n;
end PartialPhaseSystem;

model PartialBaseTwoPort
  connector BaseTerminal end BaseTerminal;
  replaceable BaseTerminal terminal_n;
end PartialBaseTwoPort;

model PartialTwoPort
  replaceable package PhaseSystem_n = PartialPhaseSystem;
  extends PartialBaseTwoPort(redeclare replaceable Terminal terminal_n(redeclare replaceable package PhaseSystem = PhaseSystem_n));
end PartialTwoPort;

connector Terminal
  replaceable package PhaseSystem = PartialPhaseSystem;
  input Real[PhaseSystem.n] i;
end Terminal;

connector Terminal_n 
  extends Terminal(redeclare replaceable package PhaseSystem = OnePhase);
end Terminal_n;

model RedeclareLocalClass 
  extends PartialTwoPort(redeclare package PhaseSystem_n = OnePhase,
    redeclare Terminal_n terminal_n(i(start = zeros(PhaseSystem_n.n))));
end RedeclareLocalClass;


// Result:
// class RedeclareLocalClass
//   input Real terminal_n.i[1](start = 0.0);
//   input Real terminal_n.i[2](start = 0.0);
// end RedeclareLocalClass;
// endResult
