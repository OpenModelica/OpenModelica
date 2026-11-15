package FmuResourcePlus
  impure function readK
    input String file;
    output Real k;
  algorithm
    k := Modelica.Utilities.Strings.scanReal(Modelica.Utilities.Streams.readLine(file, 1));
  end readK;

  model M
    parameter String file = Modelica.Utilities.Files.loadResource("modelica://FmuResourcePlus/Resources/a+b.txt");
    parameter String file1 = Modelica.Utilities.Files.loadResource("modelica:/FmuResourcePlus/Resources/a+b.txt");
    parameter Real k(fixed = false);
    parameter Real k1(fixed = false);
  initial equation
    k = readK(file);
    k1 = readK(file1);
  end M;
end FmuResourcePlus;
