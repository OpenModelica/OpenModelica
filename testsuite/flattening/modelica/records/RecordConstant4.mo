// name:     RecordConstant4
// keywords: record, constant, array
// status:   correct
//
// Checks that modifiers are propagated when assigning records to other records,
// both scalar and arrays.
//

package P
  record R
    Real r;
    Real s = 1.0;
    Real t;
    Real u;
  end R;

  constant R cr(each r = 2.0, t = 4.0, u = 5.0);
  constant R[2] cr2(each r = 2.0, each s = 3.0, each t = 4.0, each u = 5.0);
end P;

model RecordConstant4
  constant P.R CR = P.cr;
  constant P.R CR2[2] = P.cr2;
end RecordConstant4;

// Result:
// function P.R "Automatically generated record constructor for P.R"
//   input Real r;
//   input Real s = 1.0;
//   input Real t;
//   input Real u;
//   output R res;
// end P.R;
//
// function P.R$cr "Automatically generated record constructor for P.R$cr"
//   input Real r;
//   input Real s = 1.0;
//   input Real t;
//   input Real u;
//   output R$cr res;
// end P.R$cr;
//
// function P.R$cr2 "Automatically generated record constructor for P.R$cr2"
//   input Real r;
//   input Real s = 1.0;
//   input Real t;
//   input Real u;
//   output R$cr2 res;
// end P.R$cr2;
//
// class RecordConstant4
//   constant Real CR.r = 2.0;
//   constant Real CR.s = 1.0;
//   constant Real CR.t = 4.0;
//   constant Real CR.u = 5.0;
//   constant Real CR2[1].r = 2.0;
//   constant Real CR2[1].s = 3.0;
//   constant Real CR2[1].t = 4.0;
//   constant Real CR2[1].u = 5.0;
//   constant Real CR2[2].r = 2.0;
//   constant Real CR2[2].s = 3.0;
//   constant Real CR2[2].t = 4.0;
//   constant Real CR2[2].u = 5.0;
// end RecordConstant4;
// endResult
