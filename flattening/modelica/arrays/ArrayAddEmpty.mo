// name:     ArrayAddEmpty
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
//

class AddEmpty
  Real[3, 0] A, B;
  Real[0, 0] C;
  Real ab[3, 0] = A + B; // Fine, the result is an empty matrix of type Real[3, 0]
  //Real ac = A + C; // Error,incompatible types Real[3, 0] and Real[0, 0]
end AddEmpty;

// Result:
// class AddEmpty
// equation
//   ab = {{}, {}, {}};
// end AddEmpty;
// endResult
