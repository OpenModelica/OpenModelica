model gctest
  String str[:] = Modelica.Utilities.Streams.readFile("gc.mo"); // Reads itself
  String s;
algorithm
  for i in 1:1000 loop
    // print(String(i) + "\n");
    s := String(i) + "\n";
    if noEvent(i == 1000) then print(s); end if;
    for j in 1:size(str, 1) loop
      // print(str[j] + "\n");
     s := str[j] + "\n";
     if  noEvent(i == 1000) then print(s); end if;
    end for;
  end for;
end gctest;