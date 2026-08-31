// name:     ArrayAlgebraFunc
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
// Drmodelica: 7.7 Built-in Functions (p. 225)
//

class ArrayAlgebraFunc
  Real transp1[2, 2] = transpose([1, 2; 3, 4]); // Gives [1, 2; 3, 4] of type Integer[2, 2]
  Real transp2[2, 2, 1] = transpose({{{1},{2}},{{3},{4}}}); // Gives {{{1},{2}},{{3},{4}}} of type Integer[2, 2, 1]
  Real out[2, 2] = outerProduct({2, 1}, {3, 2}); // Gives {{6, 4}, {3, 2}}
  Real symm[2, 2] = symmetric({{1, 2}, {3, 1}}); // Gives {{1, 2}, {2, 1}}
  Real c[3] = cross({1, 0, 0}, {0, 1, 0}); // Gives {0, 0, 1}
  Real s[3, 3] = skew({1, 2, 3}); // Gives {{0, -3, 2}, {3, 0, -1}, {-2, 1, 0}};
end ArrayAlgebraFunc;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class <XXX>
// Real x;
// end <XXX>;
