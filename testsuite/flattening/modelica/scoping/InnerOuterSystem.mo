// name:     InnerOuterSystem
// keywords: inner, outer, innerouter, modifications
// status:   correct
//
// Modelica specification example, 5.5 Simultaneous Inner/Outer Declarations
//

model ConditionalIntegrator "Simple differential equation if isEnabled"
  outer Boolean isEnabled;
  Real x(start=1);
equation
  der(x)=if isEnabled then (-x) else 0;
end ConditionalIntegrator;

model SubSystem "subsystem that 'enable' its conditional integrators"
  Boolean enableMe = time<=1;
  // Set inner isEnabled to outer isEnabled and enableMe
  inner outer Boolean isEnabled = isEnabled and enableMe;
  ConditionalIntegrator conditionalIntegrator;
  ConditionalIntegrator conditionalIntegrator2;
end SubSystem;

model InnerOuterSystem
  SubSystem subSystem;
  inner Boolean isEnabled = time>=0.5;
  // subSystem.conditionalIntegrator.isEnabled will be
  // 'isEnabled and subSystem.enableMe'
end InnerOuterSystem;

// Result:
// class InnerOuterSystem
//   Boolean subSystem.enableMe = time <= 1.0;
//   Boolean subSystem.isEnabled = isEnabled and subSystem.enableMe;
//   Real subSystem.conditionalIntegrator.x(start = 1.0);
//   Real subSystem.conditionalIntegrator2.x(start = 1.0);
//   Boolean isEnabled = time >= 0.5;
// equation
//   der(subSystem.conditionalIntegrator.x) = if subSystem.isEnabled then -subSystem.conditionalIntegrator.x else 0.0;
//   der(subSystem.conditionalIntegrator2.x) = if subSystem.isEnabled then -subSystem.conditionalIntegrator2.x else 0.0;
// end InnerOuterSystem;
// endResult
