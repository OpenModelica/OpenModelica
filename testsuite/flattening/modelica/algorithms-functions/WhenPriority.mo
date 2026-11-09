// name:     WhenPriority
// keywords: algorithm when
// status:   correct
//
// Close defined by two equations
//
// Drmodelica: 9.1 When-Statements (p. 293)
//

model WhenPriority
  Boolean close;
  parameter Real x = 5;
algorithm
  when x >= 5 then
    close := true;
  elsewhen x <= 5 then
    close := false;
  end when;
end WhenPriority;

// Result:
// class WhenPriority
//   Boolean close;
//   parameter Real x = 5.0;
// algorithm
//   when x >= 5.0 then
//     close := true;
//   elsewhen x <= 5.0 then
//     close := false;
//   end when;
// end WhenPriority;
// endResult
