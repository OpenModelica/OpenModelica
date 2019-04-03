model P
  model A
    extends B(t2=t1);
    parameter Real t1=1 " some comment ";
  end A;

  model B
    parameter Real t2=2 "some other comment";
  end B;
end P;
