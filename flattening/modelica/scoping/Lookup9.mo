// name:     Lookup9
// keywords: scoping
// status:   correct
//

package A
  package B
    partial model BB
      constant Real k=1;
    public
      parameter Real R0 = 0.5;
    end BB;
  end B;
  model AB
    extends B.BB(R0=R_0);
    parameter Real R_0 = 0.9;
  end AB;
end A;
model C
   A.AB h(R_0=0.7);
end C;

// Result:
// class C
//   parameter Real h.R0 = h.R_0;
//   parameter Real h.R_0 = 0.7;
// end C;
// endResult
