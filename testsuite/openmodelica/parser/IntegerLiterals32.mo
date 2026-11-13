// name: IntegerLiterals (32-bit)
// keywords: integer
// status: correct
//
// Tests declaration of integers
// i5 and i6 are not initialized properly (if they are Integers)
//

model IntegerLiterals32
  constant Integer i1 = 33;
  constant Integer i2 = 0;
  constant Integer i3 = 100;
  constant Integer i4 = 30030044;
  constant Real i5 = -2147483648;
  constant Integer i6 = 2147483647;
  Integer i;
equation
  i = -2;
end IntegerLiterals32;
// Result:
// [IntegerLiterals32.mo:14:23-14:33:writable] Warning: Modelica only supports 32-bit signed integers! Transforming: 2147483648 into a real
// [IntegerLiterals32.mo:15:25-15:35:writable] Warning: OpenModelica only supports 31-bit signed integers! Truncating integer: 2147483647 to 1073741823
//
// class IntegerLiterals32
//   constant Integer i1 = 33;
//   constant Integer i2 = 0;
//   constant Integer i3 = 100;
//   constant Integer i4 = 30030044;
//   constant Real i5 = -2147483648.0;
//   constant Integer i6 = 1073741823;
//   Integer i;
// equation
//   i = -2;
// end IntegerLiterals32;
// endResult
