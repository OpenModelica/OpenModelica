model BaseProperties
  parameter Integer a;
  parameter Integer b = 1;
end BaseProperties;

model BP
  extends BaseProperties(a = b);
end BP;
