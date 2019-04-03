// name:     RangeVector
// keywords: <insert keywords here>
// status:   correct
//
// <insert description here>
//
// Drmodelica: 7.2  Array Constructor (p. 210)
//
class RangeVector
  Real v1[5] = 2.7 : 6.8; // v1 is {2.7, 3.7, 4.7, 5.7, 6.7}
  Real v2[5] = {2.7, 3.7, 4.7, 5.7, 6.7}; // v2 is equal to v1
  Integer v3[3] = 3 : 5; // v3 is {3, 4, 5}
  Integer v4empty[0] = 3 : 2; // v4empty is an empty Integer vector
  Real v5[4] = 1.0 : 2 : 8; // v5 is {1.0, 3.0, 5.0, 7.0}
  Integer v6[5] = 1 : -1 : -3; // v6 is {1, 0, -1, -2, -3}
  Real[0] v7none;  // v7 none is an empty Real vector
end RangeVector;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class <XXX>
// Real x;
// end <XXX>;
