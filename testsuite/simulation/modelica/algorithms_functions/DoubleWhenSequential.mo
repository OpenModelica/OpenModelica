// name:     DoubleWhenSequential
// keywords: when
// status:   correct
//
// Drmodelica: 9.1 When-Statements (p. 293)
//

model DoubleWhenSequential
  Boolean close;          // Possible conflicting definitions resolved by
  //parameter Real time = 2;      // sequential assignments in an algorithm section
algorithm
  when time <= 2 then
    close := true;
  end when;

  when time <= 2 then
    close := false;
  end when;
end DoubleWhenSequential;


// class DoubleWhenSequential
// Boolean close;
// algorithm
//   when time <= 2.0 then
//     close := true;
//   end when;
//   when time <= 2.0 then
//     close := false;
//   end when;
// end DoubleWhenSequential;
