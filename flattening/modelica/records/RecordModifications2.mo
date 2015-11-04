// name:     RecordModifications2
// keywords: record modification #3479
// status:   correct
//
// Tests record modification propagation using very simplified models from
// Modelica.Electrical.Machines.
//

model DC_PermanentMagnet
  parameter Real wNominal;
  extends PartialBasicMachine(frictionParameters(wRef = wNominal));
end DC_PermanentMagnet;

record FrictionParameters
  parameter Real PRef = 0;
  parameter Real wRef;
end FrictionParameters;

model Friction
  Real tau;
  parameter FrictionParameters frictionParameters;
equation
  if frictionParameters.PRef <= 0 then
    tau = 0;
  else
    tau = 1;
  end if;
end Friction;

partial model PartialBasicMachine
  parameter FrictionParameters frictionParameters;
  Friction friction(final frictionParameters = frictionParameters);
end PartialBasicMachine;

model RecordModifications2
  DC_PermanentMagnet dcpm2(wNominal = wNominal, frictionParameters = frictionParameters);
  parameter Real wNominal = 2850;
  parameter FrictionParameters frictionParameters(PRef = 100);
end RecordModifications2;

// Result:
// function FrictionParameters "Automatically generated record constructor for FrictionParameters"
//   input Real PRef = 0.0;
//   input Real wRef;
//   output FrictionParameters res;
// end FrictionParameters;
//
// function FrictionParameters$frictionParameters "Automatically generated record constructor for FrictionParameters$frictionParameters"
//   input Real PRef = 0.0;
//   input Real wRef;
//   output FrictionParameters$frictionParameters res;
// end FrictionParameters$frictionParameters;
//
// class RecordModifications2
//   parameter Real dcpm2.frictionParameters.PRef = frictionParameters.PRef;
//   parameter Real dcpm2.frictionParameters.wRef = frictionParameters.wRef;
//   Real dcpm2.friction.tau;
//   parameter Real dcpm2.friction.frictionParameters.PRef = dcpm2.frictionParameters.PRef;
//   parameter Real dcpm2.friction.frictionParameters.wRef = dcpm2.frictionParameters.wRef;
//   parameter Real dcpm2.wNominal = wNominal;
//   parameter Real wNominal = 2850.0;
//   parameter Real frictionParameters.PRef = 100.0;
//   parameter Real frictionParameters.wRef;
// equation
//   dcpm2.friction.tau = 1.0;
// end RecordModifications2;
// endResult
