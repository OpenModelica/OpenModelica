// name:     DiagonalBlock
// keywords: reduction, for, matrix
// status:   correct
//
// Tests fix for bug #1149: http://openmodelica.ida.liu.se:8080/cb/issue/1149
//

block DiagonalBlock
  parameter Integer m5=3;
  parameter Integer m6=3;
  parameter Integer m7=1;
  parameter Integer m8=2;
  input Integer offset;
  output Real Xaux[m6,m5];
  output Real Ydia[m8,m7];
algorithm
  for k in 1:max(size(Xaux)) + offset loop
    Ydia[k,1]:=Xaux[k + abs(offset),k];
  end for;
end DiagonalBlock;

// Result:
// class DiagonalBlock
//   parameter Integer m5 = 3;
//   parameter Integer m6 = 3;
//   parameter Integer m7 = 1;
//   parameter Integer m8 = 2;
//   input Integer offset;
//   output Real Xaux[1,1];
//   output Real Xaux[1,2];
//   output Real Xaux[1,3];
//   output Real Xaux[2,1];
//   output Real Xaux[2,2];
//   output Real Xaux[2,3];
//   output Real Xaux[3,1];
//   output Real Xaux[3,2];
//   output Real Xaux[3,3];
//   output Real Ydia[1,1];
//   output Real Ydia[2,1];
// algorithm
//   for k in 1:3 + offset loop
//     Ydia[k,1] := Xaux[k + abs(offset),k];
//   end for;
// end DiagonalBlock;
// endResult
