// name:     ArrayEmpty
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
// Drmodelica: 7.9 Empty Arrays (p. 231)
//

class Empty
  Real f[0] = fill(1., 0); // An empty vector of type Real[0] since 1. is Real
  Real x[0]; // An empty vector variable x of type Real[0]
  Real[0, 3] A; // An empty matrix variable A
  Real B[5, 0], C[0, 0]; // Empty matrices B and C
  Real A[:, :] = fill(0.0, 0, 1); // A Real 0 x 1 matrix
  Boolean B[:, :, :] = fill (false, 0, 1, 0); // A Boolean 0 x 1 x 0 array
end Empty;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class <XXX>
// Real x;
// end <XXX>;
