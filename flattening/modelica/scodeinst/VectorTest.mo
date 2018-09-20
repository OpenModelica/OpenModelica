// name: Visibility1
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
//     x1[1] = previous(x1[1]) + u[1];
//     x1[2] = previous(x1[2]) + u[2];
//     x1[3] = previous(x1[3]) + u[3];
//     x1[4] = previous(x1[4]) + u[4];
//     x1[5] = previous(x1[5]) + u[5];
//     x1[6] = previous(x1[6]) + u[6];
//     x1[7] = previous(x1[7]) + u[7];
//     x1[8] = previous(x1[8]) + u[8];
//     x1[9] = previous(x1[9]) + u[9];
//     x1[10] = previous(x1[10]) + u[10];
//     x2 = VectorTest.myfor(u, previous(x2));
//   end when;
//   y0 = sum(u);
//   y1 = VectorTest.mysum(u);
//   y2 = VectorTest.mysum(x2);
// end VT;
// endResult
