
package Modelica
 package Utilities
  package Streams

    function print "Print string to terminal or file"
      input String string="" "String to be printed";
      input String fileName="" "File where to print (empty string is the terminal)";
    external "C" myPuts(string,fileName) annotation(Include="#define myPuts(X,Y) fputs(X,stdout)");
    end print;

  end Streams;
 end Utilities;
end Modelica;

function random "Pseudo random number generator"
  input Integer seedIn[3] "Seed from last call";
  output Real x "Random number between 0 and 1";
  output Integer seedOut[3] "Modified seed for next call";
algorithm
  seedOut[1] := rem((171*seedIn[1]), 30269);
  seedOut[2] := rem((172*seedIn[2]), 30307);
  seedOut[3] := rem((170*seedIn[3]), 30323);
  // Zero is a poor seed, therefore substitute 1;
  for i in 1:3 loop
    if seedOut[i] == 0 then
       seedOut[i] := 1;
    end if;
  end for;
  x := rem((seedOut[1]/30269.0 + seedOut[2]/30307.0 + seedOut[3]/30323.0), 1.0);
end random;

function testRandom1
  input Integer seed_start[3] = {23,87,187};
  output Real x;
  protected
    Integer seed[3] = seed_start;
algorithm
  Modelica.Utilities.Streams.print("See if seed_start is OK\n");
  Modelica.Utilities.Streams.print("seed_start[1] = " + String(seed_start[1]) + "\n");
  Modelica.Utilities.Streams.print("seed_start[2] = " + String(seed_start[2]) + "\n");
  Modelica.Utilities.Streams.print("seed_start[3] = " + String(seed_start[3]) + "\n");
  Modelica.Utilities.Streams.print("See if seed is set from seed_start\n");
  Modelica.Utilities.Streams.print("seed[1] = " + String(seed[1]) + "\n");
  Modelica.Utilities.Streams.print("seed[2] = " + String(seed[2]) + "\n");
  Modelica.Utilities.Streams.print("seed[3] = " + String(seed[3]) + "\n");

  for i in 1:10 loop
   (x, seed) := random(seed);
   Modelica.Utilities.Streams.print("x = " + String(x,significantDigits=16) + "\n");
  end for;
end testRandom1;

function testRandom3 = testRandom1;

model testRandom2
  parameter Integer seed_start[3] = {23,87,187};
  Integer seed[3](start=seed_start, each fixed=true);
  parameter Real y = testRandom3(seed_start);
  Real x;
algorithm
  when sample(0,0.2) then
    (x, seed) := random(pre(seed));
    Modelica.Utilities.Streams.print("time = " + String(time, format=".1f") + ", x = " + String(x , format=".6f") + "\n");
  end when;
end testRandom2;
