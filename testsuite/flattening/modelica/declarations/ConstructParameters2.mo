// name:     ConstructParameters2
// keywords: declaration,algorithm
// status:   correct
//
// Show how to perform the same task
// as in ConstructParameters1 but with legal
// Modelica.

record Prec
  Real p3, p4;
end Prec;

function fc
  output Prec p;
  input  Real p1, p2;
algorithm
  p.p3 := p1*p2;
  p.p4 := p.p3*p1 + p2;
end fc;

model ConstructParameters2
  parameter Real p1=2.0, p2=3.0;
protected
  parameter Prec prec = fc(p1,p2);
  parameter Real p3=prec.p3,p4 = prec.p4;
end ConstructParameters2;

// Result:
// function Prec "Automatically generated record constructor for Prec"
//   input Real p3;
//   input Real p4;
//   output Prec res;
// end Prec;
//
// function fc
//   output Prec p;
//   input Real p1;
//   input Real p2;
// algorithm
//   p.p3 := p1 * p2;
//   p.p4 := p.p3 * p1 + p2;
// end fc;
//
// class ConstructParameters2
//   parameter Real p1 = 2.0;
//   parameter Real p2 = 3.0;
//   protected parameter Real prec.p3 = 6.0;
//   protected parameter Real prec.p4 = 15.0;
//   protected parameter Real p3 = prec.p3;
//   protected parameter Real p4 = prec.p4;
// end ConstructParameters2;
// endResult
