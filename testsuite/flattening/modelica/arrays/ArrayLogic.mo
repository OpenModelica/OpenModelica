// name: ArrayLogic
// keywords: array, operators, logic
// status: correct
//
// Tests vectorization of logical operators and, or, and not.
//

model ArrayLogic
  Boolean b[:] = {false, true};
  Boolean b2[:] = {true, false};
  Boolean nb[:] = not b;
  Boolean ab[:] = b and b2;
  Boolean ob[:] = b or b2;
  Boolean nb2[:,:] = not fill(b, 2);
  Boolean ab2[:,:] = fill(b, 2) and fill(b2, 2);
  Boolean ob2[:,:] = fill(b, 2) or fill(b2, 2);
end ArrayLogic;

// Result:
// class ArrayLogic
//   Boolean b[1];
//   Boolean b[2];
//   Boolean b2[1];
//   Boolean b2[2];
//   Boolean nb[1];
//   Boolean nb[2];
//   Boolean ab[1];
//   Boolean ab[2];
//   Boolean ob[1];
//   Boolean ob[2];
//   Boolean nb2[1,1];
//   Boolean nb2[1,2];
//   Boolean nb2[2,1];
//   Boolean nb2[2,2];
//   Boolean ab2[1,1];
//   Boolean ab2[1,2];
//   Boolean ab2[2,1];
//   Boolean ab2[2,2];
//   Boolean ob2[1,1];
//   Boolean ob2[1,2];
//   Boolean ob2[2,1];
//   Boolean ob2[2,2];
// equation
//   b = {false, true};
//   b2 = {true, false};
//   nb = not b;
//   ab = b and b2;
//   ob = b or b2;
//   nb2 = not {b, b};
//   ab2 = {b and b2, b and b2};
//   ob2 = {b or b2, b or b2};
// end ArrayLogic;
// endResult
