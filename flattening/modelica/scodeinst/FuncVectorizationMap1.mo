// name: FuncVectorizationMap1
// keywords: vectorization function map array reduction
// status: correct
// cflags: -d=newInst
//
// Checks vectorization mixed with mapping function.
//

model FuncVectorizationMap1
  function F
    input Real a[4];
    input Real c;
    output Real o = c;
  end F;

  Real b[2,3,4];
  Real g[2,3];
equation
  // Normal vectorization. each element
  g = F(b,1);
  // Internal function call F(b[i],1) needs vectorization
  g = array(F(b[i],1) for i in 1:2);
  // No vectorization for internal call. Just mapping.
  g = array(F(b[i,j],1) for j in 1:3, i in 1:2);
end FuncVectorizationMap1;


// Result:
// function FuncVectorizationMap1.F
//   input Real[4] a;
//   input Real c;
//   output Real o = c;
// end FuncVectorizationMap1.F;
//
// class FuncVectorizationMap1
//   Real b[1,1,1];
//   Real b[1,1,2];
//   Real b[1,1,3];
//   Real b[1,1,4];
//   Real b[1,2,1];
//   Real b[1,2,2];
//   Real b[1,2,3];
//   Real b[1,2,4];
//   Real b[1,3,1];
//   Real b[1,3,2];
//   Real b[1,3,3];
//   Real b[1,3,4];
//   Real b[2,1,1];
//   Real b[2,1,2];
//   Real b[2,1,3];
//   Real b[2,1,4];
//   Real b[2,2,1];
//   Real b[2,2,2];
//   Real b[2,2,3];
//   Real b[2,2,4];
//   Real b[2,3,1];
//   Real b[2,3,2];
//   Real b[2,3,3];
//   Real b[2,3,4];
//   Real g[1,1];
//   Real g[1,2];
//   Real g[1,3];
//   Real g[2,1];
//   Real g[2,2];
//   Real g[2,3];
// equation
//   g = array(FuncVectorizationMap1.F(b[$i1,$i2], 1.0) for $i2 in 1:3, $i1 in 1:2);
//   g = array(array(FuncVectorizationMap1.F(b[i,$i1], 1.0) for $i1 in 1:3) for i in 1:2);
//   g = array(FuncVectorizationMap1.F(b[i,j], 1.0) for j in 1:3, i in 1:2);
// end FuncVectorizationMap1;
// endResult
