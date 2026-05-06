// name:     ArrayAddEmpty
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
// ??Error - not yet implemented
// Drmodelica: 7.9 Empty Arrays (p. 231)
//

class AddEmpty
  Real[3, 0] A, B;
  Real[0, 0] C;
  Real ab[3, 0] = A + B;// Fine, the result is an empty matrix of type Real[3, 0]
  //Real ac = A + C; // Error,incompatible types Real[3, 0] and Real[0, 0]
end AddEmpty;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class <XXX>
// Real x;
// end <XXX>;
