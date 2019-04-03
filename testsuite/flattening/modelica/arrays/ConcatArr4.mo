// name:     ConcatArr4
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
//

class ConcatArr4
  Real[1, 1, 1] A = {{{1}}};
  Real[1, 1, 2] B = {{{2, 3}}};
  Real[1, 1, 3] C = {{{4, 5, 6}}};
  Real[1, 1, 6] R = cat(3, A, B, C); // Result value: {{{1, 2, 3, 4, 5, 6}}};
end ConcatArr4;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class <XXX>
// Real x;
// end <XXX>;
