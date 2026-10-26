// name: EnumArray
// keywords: enum array
// status: correct
//
// Tests assignment of arrays indexed with enumerations.
//

model EnumArray
  type E = enumeration(one, two, three, four);

  input Real in1[E];
  input Real in2[E];
  input Real in3[4];
  output Real out1[E];
  output Real out2[4];
  output Real out3[E];
equation
  out1 = in1;
  out2 = in2;
  out3 = in3;
end EnumArray;

// Result:
// class EnumArray
//   input Real in1[E.one];
//   input Real in1[E.two];
//   input Real in1[E.three];
//   input Real in1[E.four];
//   input Real in2[E.one];
//   input Real in2[E.two];
//   input Real in2[E.three];
//   input Real in2[E.four];
//   input Real in3[1];
//   input Real in3[2];
//   input Real in3[3];
//   input Real in3[4];
//   output Real out1[E.one];
//   output Real out1[E.two];
//   output Real out1[E.three];
//   output Real out1[E.four];
//   output Real out2[1];
//   output Real out2[2];
//   output Real out2[3];
//   output Real out2[4];
//   output Real out3[E.one];
//   output Real out3[E.two];
//   output Real out3[E.three];
//   output Real out3[E.four];
// equation
//   out1[E.one] = in1[E.one];
//   out1[E.two] = in1[E.two];
//   out1[E.three] = in1[E.three];
//   out1[E.four] = in1[E.four];
//   out2[1] = in2[E.one];
//   out2[2] = in2[E.two];
//   out2[3] = in2[E.three];
//   out2[4] = in2[E.four];
//   out3[E.one] = in3[1];
//   out3[E.two] = in3[2];
//   out3[E.three] = in3[3];
//   out3[E.four] = in3[4];
// end EnumArray;
// endResult
