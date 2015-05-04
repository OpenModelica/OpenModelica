model gctest
  String str[1000];
algorithm
  for i in 1:1000 loop
    str[i] := String(time);
    str[i] := str[i] + "\n";
  end for;
end gctest;
