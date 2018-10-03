// name: VectorTest
// keywords:
// status: correct
// cflags: -d=newInst,-nfScalarize --std=3.3
//

package VectorTest  
  constant Integer n = 10;

  function mysum  
    input Real[:] u;
    output Real y;
  algorithm
    y := sum(u);
  end mysum;

  function myfor  
    input Real[:] u;
    input Real[size(u, 1)] previous_x;
    output Real[size(u, 1)] x;
  algorithm
    for i in 1:size(u, 1) loop
      x[i] := previous_x[i] + u[i];
    end for;
  end myfor;

  model m  
    input Real[n] u(each start = 1);
    Real[size(u, 1)] x1;
    Real[size(u, 1)] x2;
    output Real y0;
    output Real y1;
    output Real y2;
  equation
    when Clock() then
      for i in 1:size(u, 1) loop
        x1[i] = previous(x1[i]) + u[i];
      end for;
      x2 = myfor(u, previous(x2));
    end when;
    y0 = sum(u);
    y1 = mysum(u);
    y2 = mysum(x2);
  end m;
end VectorTest;

model VT 
  extends VectorTest.m;
end VT;


// Result:
// function VectorTest.myfor
//   input Real[:] u;
//   input Real[size(u, 1)] previous_x;
//   output Real[size(u, 1)] x;
// algorithm
//   for i in 1:size(u, 1) loop
//     x[i] := previous_x[i] + u[i];
//   end for;
// end VectorTest.myfor;
//
// function VectorTest.mysum
//   input Real[:] u;
//   output Real y;
// algorithm
//   y := sum(u);
// end VectorTest.mysum;
//
// class VT
//   input Real[10] u(start = 1.0);
//   Real[10] x1;
//   Real[10] x2;
//   output Real y0;
//   output Real y1;
//   output Real y2;
// equation
//   when Clock() then
//     for i in 1:10 loop
//       x1[i] = previous(x1[i]) + u[i];
//     end for;
//     x2 = VectorTest.myfor(u, previous(x2));
//   end when;
//   y0 = sum(u);
//   y1 = VectorTest.mysum(u);
//   y2 = VectorTest.mysum(x2);
// end VT;
// endResult
