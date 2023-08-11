program cirkel;

  const pi = 3.14159;

  var o : real; 
      r : real;

  procedure init;
    begin
      r := 17.0
    end;

  function omkrets(radie : real) : real;

    function diameter: real;
      begin
	return 2.0 * radie
      end;

  begin
    return diameter() * pi
  end;

begin
  init();
  o := omkrets(r)
end.
