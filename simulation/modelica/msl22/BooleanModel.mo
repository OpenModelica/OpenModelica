model Booleanmodel

  Boolean startForward;
  Integer mode(start=2,fixed=true);

equation

  startForward = pre(mode)==1 or initial();
  mode = if time < 0.5 then 2 else if time < 0.7 then 1 else 0;
end Booleanmodel;

