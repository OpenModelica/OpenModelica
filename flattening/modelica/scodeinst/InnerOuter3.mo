// name: InnerOuter3
// keywords:
// status: correct
// cflags: -d=newInst
//
// inner/outer example from the specification.
//

model ConditionalIntegrator
  outer Boolean isEnabled;
  Real x(start=1);
equation
  der(x)=if isEnabled then (-x) else 0;
end ConditionalIntegrator;

model SubSystem 
  Boolean enableMe = time<=1;
  inner outer Boolean isEnabled = isEnabled and enableMe;
  ConditionalIntegrator conditionalIntegrator;
  ConditionalIntegrator conditionalIntegrator2;
end SubSystem;

model InnerOuter3
  SubSystem subSystem;
  inner Boolean isEnabled = time>=0.5;
end InnerOuter3;

// Result:
// class InnerOuter3
//   Boolean subSystem.enableMe = time <= 1.0;
//   Boolean subSystem.isEnabled = isEnabled and subSystem.enableMe;
//   Real subSystem.conditionalIntegrator.x(start = 1);
//   Real subSystem.conditionalIntegrator2.x(start = 1);
//   Boolean isEnabled = time >= 0.5;
// equation
//   der(subSystem.conditionalIntegrator.x) = if subSystem.isEnabled then -subSystem.conditionalIntegrator.x else 0.0;
//   der(subSystem.conditionalIntegrator2.x) = if subSystem.isEnabled then -subSystem.conditionalIntegrator2.x else 0.0;
// end InnerOuter3;
// endResult
