model ExternalNlsRecovery
  function f
    input Real x;
    output Real y;
    external "C" y = ExternalNlsRecovery_f(x) annotation(Library = "ExternalNlsRecovery-f.o");
  end f;
  Real x(start = 5.0);
equation
  f(x) = 1.0 + time;
end ExternalNlsRecovery;
