// name:     Annotations2
// keywords: declaration annotations comments
// status:   correct
//
// The frontend has special rules for absoluteValue, check that it doesn't
// overwrite existing comments/annotations.
//

model Annotations2
  type Power = Real;
  type TemperatureDifference = Real annotation(absoluteValue = false);

  parameter Power Test1 = 0 "test1";
  parameter TemperatureDifference Test2 = 0 "test2" annotation(absoluteValue = true);
  parameter TemperatureDifference Test3 = 0 "test3";
  annotation(__OpenModelica_commandLineOptions="--showAnnotations");
end Annotations2;

// Result:
// class Annotations2
//   parameter Real Test1 = 0.0 "test1";
//   parameter Real Test2 = 0.0 "test2" annotation(absoluteValue = true);
//   parameter Real Test3 = 0.0 "test3" annotation(absoluteValue = false);
//   annotation(__OpenModelica_commandLineOptions = "--showAnnotations");
// end Annotations2;
// endResult
