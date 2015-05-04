model WhenNoRetCall
  Integer i;
equation
  when sample(0,0.1) then
    Modelica.Utilities.Streams.print("printing at time: " + String(time));
    i = pre(i) + 1;
  end when;
end WhenNoRetCall;
