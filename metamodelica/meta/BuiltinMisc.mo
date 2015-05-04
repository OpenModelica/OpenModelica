package BuiltinMisc

function myTick
  output Integer i;
algorithm
  i := tick();
end myTick;

function myPrint
  input String s;
algorithm
  print(s);
  print("\n");
end myPrint;

function myClock
  output Real r;
algorithm
  r := clock();
end myClock;

end BuiltinMisc;
