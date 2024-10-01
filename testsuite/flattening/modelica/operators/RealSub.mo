// name: RealSub
// keywords: real, subtraction
// status: correct
//
// tests Real subtraction
//

model RealSub
  constant Real r = 4711.2 - 1138.3;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end RealSub;

// Result:
// class RealSub
//   constant Real r = 3572.8999999999996;
// end RealSub;
// endResult
