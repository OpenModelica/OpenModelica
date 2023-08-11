package TestNonStandardExtensions

model InnerDefinition
  parameter Real x = 1;
end InnerDefinition;

model TestTopLevelOuter
  outer InnerDefinition o;
  parameter Real y = 2;
end TestTopLevelOuter;

end TestNonStandardExtensions;
