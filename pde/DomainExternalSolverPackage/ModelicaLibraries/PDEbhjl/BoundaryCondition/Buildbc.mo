record Buildbc 
  parameter Integer n;
  parameter Data data[n];
  parameter BCType bc[n]={{data[i].bcType,data[i].val,data[i].index} for i in 1
      :n};
end Buildbc;
