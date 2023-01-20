function func1
  input Real x;
  output Real func1_out;
algorithm
  func1_out := x;
end func1;

function func2
  input Real x1;
  input Real x2;
  output Real func2_out;
algorithm
  func2_out := x1 + x2;
end func2;

model hybridSys
  parameter Integer Niter=4;
  // Variables of the discrete event model
  Boolean phase_Start(start=true);
  Boolean phase_Loop1(start=false);
  Boolean phase_Loop2(start=false);
  Boolean phase_Loop3(start=false);
  Boolean phase_End(start=false);
  Real x_Start(start=0);
  Real x_Loop1(start=0);
  Real x_Loop2(start=0);
  Real x_Loop3(start=0);
  Real x_End(start=0);
  Boolean startCondition(start=false);
  Boolean loopCondition1(start=false);
  Boolean loopCondition2(start=false);
  Boolean loopCondition3(start=false);
  Boolean endCondition(start=false);
  // Variables of the continuous-time model
  Real x1(start=10),x2;
equation
  //---------------------
  // Continuous-time model
  der(x1) = -func1(x1);
  // No discrete-to-continuous interaction
  //x2 = func1(x1);
  // Discrete-to-continuous interaction
  x2 = func2(x1,x_End);
  //--------------------
  // Discrete-event model
  startCondition = time>1;
  loopCondition1 = pre(x_Loop1)<Niter+1;
  loopCondition2 = pre(x_Loop2)<Niter+1;
  loopCondition3 = pre(x_Loop3)<Niter;
  endCondition = not loopCondition3;
  phase_Start = pre(phase_Start) and not startCondition;
  phase_Loop1 = pre(phase_Start) and startCondition or pre(phase_Loop3) and loopCondition3 or pre(phase_Loop1) and not loopCondition1;
  phase_Loop2 = pre(phase_Loop1) and loopCondition1 or pre(phase_Loop2) and not loopCondition2;
  phase_Loop3 = pre(phase_Loop2) and loopCondition2 or pre(phase_Loop3) and not (loopCondition3 or endCondition);
  phase_End = pre(phase_Loop3) and endCondition;
  when phase_Start then
    x_Start = pre(x_Start)+1;
  end when;
  when phase_Loop1 then
    x_Loop1 = pre(x_Loop1)+1;
  end when;
  when phase_Loop2 then
    x_Loop2 = pre(x_Loop2)+1;
  end when;
  when phase_Loop3 then
    x_Loop3 = pre(x_Loop3)+1;
  end when;
  when phase_End then
    x_End = pre(x_End)+1;
  end when;
end hybridSys;
