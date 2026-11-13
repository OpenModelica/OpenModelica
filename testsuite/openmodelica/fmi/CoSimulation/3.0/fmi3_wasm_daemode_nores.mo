model DaeModeNoRes "No residual is left for IDA: every equation is solved explicitly"
  Real u = 2*time;
  discrete Real d(start = 0, fixed = true);
  Integer k(start = 0, fixed = true);
equation
  when u > 1.5 then
    d = pre(u);
  end when;
  when sample(0, 0.5) then
    k = pre(k) + 1;
  end when;
  annotation(
    __OpenModelica_commandLineOptions = "--daeMode",
    experiment(StopTime = 2));
end DaeModeNoRes;
