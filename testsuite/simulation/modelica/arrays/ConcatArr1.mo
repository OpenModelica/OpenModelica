// name:     ConcatArr1
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
// Drmodelica: 7.3 General Array concatenation (p. 213)
//

class ConcatArr1
  Real[5] c1 = cat(1, {1, 2}, {10, 12, 13}); // Result: {1, 2, 10, 12, 13}
  Real[2, 3] c2 = cat(2, {{1, 2}, {3, 4}}, {{10}, {11}}); // Result: {{1, 2, 10}, {3, 4, 11}}
end ConcatArr1;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class <XXX>
// Real x;
// end <XXX>;
