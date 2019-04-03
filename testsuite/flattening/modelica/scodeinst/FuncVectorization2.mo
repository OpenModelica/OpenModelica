// name: FuncVectorization2
// keywords: vectorization function
// status: correct
// cflags: -d=newInst
//
// Checks mixed vectorization where some arguments are vectorized over some
// dimensions while others are applied as is.
//


model FuncVectorization2
  function F
    input Integer a[4];
    input Integer b;
    output Integer o;
  end F;


  Integer b[2,3,4];
  Integer g[2,3];
equation
  g = F(b, 1);
end FuncVectorization2;


// Result:
// function FuncVectorization2.F
//   input Integer[4] a;
//   input Integer b;
//   output Integer o;
// end FuncVectorization2.F;
//
// class FuncVectorization2
//   Integer b[1,1,1];
//   Integer b[1,1,2];
//   Integer b[1,1,3];
//   Integer b[1,1,4];
//   Integer b[1,2,1];
//   Integer b[1,2,2];
//   Integer b[1,2,3];
//   Integer b[1,2,4];
//   Integer b[1,3,1];
//   Integer b[1,3,2];
//   Integer b[1,3,3];
//   Integer b[1,3,4];
//   Integer b[2,1,1];
//   Integer b[2,1,2];
//   Integer b[2,1,3];
//   Integer b[2,1,4];
//   Integer b[2,2,1];
//   Integer b[2,2,2];
//   Integer b[2,2,3];
//   Integer b[2,2,4];
//   Integer b[2,3,1];
//   Integer b[2,3,2];
//   Integer b[2,3,3];
//   Integer b[2,3,4];
//   Integer g[1,1];
//   Integer g[1,2];
//   Integer g[1,3];
//   Integer g[2,1];
//   Integer g[2,2];
//   Integer g[2,3];
// equation
//   g = array(FuncVectorization2.F(b[$i1,$i2], 1) for $i2 in 1:3, $i1 in 1:2);
// end FuncVectorization2;
// endResult
