package PrettyPrintingTest
  model TopLevelClass
    PrettyPrintingTest.SomeClass someClass(a = 5, b = 6, d = 1) annotation(
      Placement(transformation(extent = {{-16, 0}, {18, 20}})));
  end TopLevelClass;

  model SomeClass
    parameter Real a = 1;
    parameter Real b = 2;
    parameter Real c = 3;
    parameter Real d = 4;
  end SomeClass;
end PrettyPrintingTest;