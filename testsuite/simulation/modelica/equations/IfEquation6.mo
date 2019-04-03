model testIfEqn6
  parameter Boolean test = true;
equation
  if initial() and test then
     Modelica.Utilities.Streams.print( "bla", "test.txt");
  end if;
end testIfEqn6;
