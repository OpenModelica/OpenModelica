// name:     Enumeration1
// keywords: enumeration enum
// status:   correct
//
//
//

model Enumeration1
   type Color = enumeration(green "1st",blue "2st", yellow "3th");
   Real[Color] x;
equation
   x[Color.green] = 1;
   x[Color.blue] = 2;
   x[Color.yellow] = 3;
end Enumeration1;

// Result:
// class Enumeration1
//   Real x[Enumeration1.Color.green];
//   Real x[Enumeration1.Color.blue];
//   Real x[Enumeration1.Color.yellow];
// equation
//   x[Enumeration1.Color.green] = 1.0;
//   x[Enumeration1.Color.blue] = 2.0;
//   x[Enumeration1.Color.yellow] = 3.0;
// end Enumeration1;
// endResult
