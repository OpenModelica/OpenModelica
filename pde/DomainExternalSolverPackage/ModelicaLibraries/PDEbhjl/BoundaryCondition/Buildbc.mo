record Buildbc 
  parameter Integer n;
  parameter Data data[n];
  parameter BCType bc[n]={{data[i].bcType,data[i].g,data[i].q,data[i].index} 
      for i in 1:n};
end Buildbc;
