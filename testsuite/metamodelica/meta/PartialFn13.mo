// name:     PartialFn13
// keywords: PartialFn
// status:  correct
//
// Using function pointers, partially evaluated functions
//

partial function PartFn
  input Real x;
  output Real y;
end PartFn;

function FullFn
  extends PartFn;
  input Real extraReal1;
  input Real extraReal2;
algorithm
  y := x * ((extraReal1 + extraReal2) / 2.0);
end FullFn;

function CallerFn
  input Real inReal;
  input PartFn inPartFn;
  output Real outReal;
algorithm
  outReal := if (inReal < 2.0) then inPartFn(inReal) else CallerFn(inReal - 1.0,inPartFn);
end CallerFn;

function TestFn
  input Real inReal;
  output Real outReal;
algorithm
  outReal := CallerFn(inReal, function FullFn(extraReal1 = 1.5, extraReal2 = 7.5));
end TestFn;

model PartialFn13
  Real x;
  Real y;
equation
  x = 4.0;
  y = TestFn(x);
end PartialFn13;

// class PartialFn13
// Real x;
// Real y;
// equation
//   x = 4.0;
//   y = TestFn(x);
// end PartialFn13;
