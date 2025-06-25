// name: LookupLibrary1
// keywords:
// status: correct
//
// Tests that libraries can be looked up even when not explicitly loaded.
//

model LookupLibrary1
  Modelica.Units.SI.Angle angle;
end LookupLibrary1;

// Result:
// class LookupLibrary1
//   Real angle(quantity = "Angle", unit = "rad", displayUnit = "deg");
// end LookupLibrary1;
// Notification: Automatically loaded package Complex 4.1.0 due to uses annotation from Modelica.
// Notification: Automatically loaded package ModelicaServices 4.1.0 due to uses annotation from Modelica.
// Notification: Automatically loaded package Modelica 4.1.0 due to usage.
//
// endResult
