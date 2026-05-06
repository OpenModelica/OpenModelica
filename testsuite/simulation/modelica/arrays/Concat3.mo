// name:     Concat3
// keywords: <insert keywords here>
// status:   correct
//
// MORE WORK HAS TO BE DONE ON THIS FILE!
// Drmodelica: 7.3 General Array concatenation (p. 213)
//

class Concat3
  Real[2, 3] r1 = cat(1, {{1.0, 2.0, 3}}, {{4, 5, 6}});
  Real[2, 6] r2 = cat(2, r1, r1);
end Concat3;

// insert expected flat file here. Can be done by issuing the command
// ./omc XXX.mo >> XXX.mo and then comment the inserted class.
//
// class Concat3
// Real r1[1,1];
// Real r1[1,2];
// Real r1[1,3];
// Real r1[2,1];
// Real r1[2,2];
// Real r1[2,3];
// Real r2[1,1];
// Real r2[1,2];
// Real r2[1,3];
// Real r2[1,4];
// Real r2[1,5];
// Real r2[1,6];
// Real r2[2,1];
// Real r2[2,2];
// Real r2[2,3];
// Real r2[2,4];
// Real r2[2,5];
// Real r2[2,6];
// equation
//   r1[1,1] = 1.0;
//   r1[1,2] = 2.0;
//   r1[1,3] = 3.0;
//   r1[2,1] = 4;
//   r1[2,2] = 5;
//   r1[2,3] = 6;
//   r2 = cat(2,{{r1[1,1],r1[1,2],r1[1,3]},{r1[2,1],r1[2,2],r1[2,3]}},{{r1[1,1],r1[1,2],r1[1,3]},{r1[2,1],r1[2,2],r1[2,3]}});
// end Concat3;
