// name: EndUnknown
// status: correct
// teardown_command: rm -f EndUnknown_*

model EndUnknown

  function simpson "Simpson's numerical integration formula"
    input Real vals[:] "function values";
    input Real a "Lower limit";
    input Real b "Upper limit";
    output Real res;
    algorithm
    //assert(size(vals,1) >= 3,"Not enough points for Simpson integration!");
    if size(vals, 1) >= 3 then
      res := (b - a)/(size(vals, 1) - 1)*(vals[1] + 2*sum(vals[3:2:end - 1])
        + 4*sum(vals[2:2:end - 1]) + vals[end])/3;
    else
      res := (b - a)*sum(vals)/2;
    end if;
  end simpson;

  constant Real a = simpson({0.4, 0.3, 0.1, 0.2, 0.3},0,1);
  Real x(start=1);
equation
  der(x) = -a * x;
  annotation(__OpenModelica_commandLineOptions="-d=noevalfunc,gen");
end EndUnknown;

// Result:
// class EndUnknown
//   constant Real a = 0.24166666666666667;
//   Real x(start = 1.0);
// equation
//   der(x) = -0.24166666666666667 * x;
// end EndUnknown;
// endResult
