// name: WhenClocks
// keywords: synchronous features
// status: correct

model WhenClocks
  Real x;
equation
  when Clock() then
    x = previous(x) + 1;
  end when;
  when Clock(time > 0.5) then
    x = previous(x) + 1;
  end when;
end WhenClocks;

// Result:
// class WhenClocks
//   Real x;
// equation
//   when Clock() then
//     x = 1.0 + previous(x);
//   end when;
//   when Clock(time > 0.5, 0.0) then
//     x = 1.0 + previous(x);
//   end when;
// end WhenClocks;
// endResult
