// name:     VectorTest
// keywords: vector wholedim bug1170
// status:   correct
// Tests the vector function, and determination of unspecified vector dimensions
// from a function call.
//
// Fix for bug #1170: http://openmodelica.ida.liu.se:8080/cb/issue/1170?navigation=true

model VectorTest
  function PolyToRelCoord
    input Real T[4, 4];
    input Real s[3, :];
    output Real r[3, size(s, 2)];
  protected
    Real p[4];
  algorithm
    for i in 1:size(s, 2) loop
      p := vector(T*[s[:, i]; 1]);
      r[:, i] := p[1:3];
    end for;
  end PolyToRelCoord;

  constant Real H[4,4] = diagonal(ones(4));
  constant Real ply[3,4] = [1.0, 0.0, 0.0, 1.0; 1.0, 0.0, 1.0, 0.0; 0.0, 0.0, 1.0, 1.0];
  constant Real plyprime[3,:] = PolyToRelCoord(H,ply);
end VectorTest;

// function VectorTest.PolyToRelCoord
// input Real[4, 4] T;
// input Real[3, :] s;
// output Real[3, size(s,2)] r;
// protected Real[4] p;
// algorithm
//   for i in 1:size(s,2) loop
//     p := {T[1,1] * s[1,i] + T[1,2] * s[2,i] + T[1,3] * s[3,i] + T[1,4],T[2,1] * s[1,i] + T[2,2] * s[2,i] + T[2,3] * s[3,i] + T[2,4],T[3,1] * s[1,i] + T[3,2] * s[2,i] + T[3,3] * s[3,i] + T[3,4],T[4,1] * s[1,i] + T[4,2] * s[2,i] + T[4,3] * s[3,i] + T[4,4]};
//     r[:,i] := p[{1,2,3}];
//   end for;
// end VectorTest.PolyToRelCoord;
//
// Result:
// function VectorTest.PolyToRelCoord
//   input Real[4, 4] T;
//   input Real[3, :] s;
//   output Real[3, size(s, 2)] r;
//   protected Real[4] p;
// algorithm
//   for i in 1:size(s, 2) loop
//     p := {T[1,1] * s[1,i] + T[1,2] * s[2,i] + T[1,3] * s[3,i] + T[1,4], T[2,1] * s[1,i] + T[2,2] * s[2,i] + T[2,3] * s[3,i] + T[2,4], T[3,1] * s[1,i] + T[3,2] * s[2,i] + T[3,3] * s[3,i] + T[3,4], T[4,1] * s[1,i] + T[4,2] * s[2,i] + T[4,3] * s[3,i] + T[4,4]};
//     r[:,i] := {p[1], p[2], p[3]};
//   end for;
// end VectorTest.PolyToRelCoord;
//
// class VectorTest
//   constant Real H[1,1] = 1.0;
//   constant Real H[1,2] = 0.0;
//   constant Real H[1,3] = 0.0;
//   constant Real H[1,4] = 0.0;
//   constant Real H[2,1] = 0.0;
//   constant Real H[2,2] = 1.0;
//   constant Real H[2,3] = 0.0;
//   constant Real H[2,4] = 0.0;
//   constant Real H[3,1] = 0.0;
//   constant Real H[3,2] = 0.0;
//   constant Real H[3,3] = 1.0;
//   constant Real H[3,4] = 0.0;
//   constant Real H[4,1] = 0.0;
//   constant Real H[4,2] = 0.0;
//   constant Real H[4,3] = 0.0;
//   constant Real H[4,4] = 1.0;
//   constant Real ply[1,1] = 1.0;
//   constant Real ply[1,2] = 0.0;
//   constant Real ply[1,3] = 0.0;
//   constant Real ply[1,4] = 1.0;
//   constant Real ply[2,1] = 1.0;
//   constant Real ply[2,2] = 0.0;
//   constant Real ply[2,3] = 1.0;
//   constant Real ply[2,4] = 0.0;
//   constant Real ply[3,1] = 0.0;
//   constant Real ply[3,2] = 0.0;
//   constant Real ply[3,3] = 1.0;
//   constant Real ply[3,4] = 1.0;
//   constant Real plyprime[1,1] = 1.0;
//   constant Real plyprime[1,2] = 0.0;
//   constant Real plyprime[1,3] = 0.0;
//   constant Real plyprime[1,4] = 1.0;
//   constant Real plyprime[2,1] = 1.0;
//   constant Real plyprime[2,2] = 0.0;
//   constant Real plyprime[2,3] = 1.0;
//   constant Real plyprime[2,4] = 0.0;
//   constant Real plyprime[3,1] = 0.0;
//   constant Real plyprime[3,2] = 0.0;
//   constant Real plyprime[3,3] = 1.0;
//   constant Real plyprime[3,4] = 1.0;
// end VectorTest;
// endResult
