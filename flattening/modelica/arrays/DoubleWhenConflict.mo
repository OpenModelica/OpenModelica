// name:     DoubleWhenConflict
// keywords: equations when
// status:   incorrect
//
// Close defined by two equations
// Drmodelica: 9.1 When-Statements (p. 293)
//

model DoubleWhenConflict
  Boolean close; // Erroneous model:
  parameter Real x = 5;
algorithm
  when x >= 5 then
    close := true;
  end when;
algorithm
  when x <= 5 then
    close := false;
  end when;
end DoubleWhenConflict;


// Result:
// class DoubleWhenConflict
// Boolean close;
// parameter Real x = 5;
// algorithm
//   when x >= 5.0 then
//     close := true;
//   end when;
//   when x <= 5.0 then
//     close := false;
//   end when;
// end DoubleWhenConflict;// endResult
