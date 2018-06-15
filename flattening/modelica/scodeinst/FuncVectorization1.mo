// name: FuncVectorization1
// keywords: vectorization function
// status: correct
// cflags: -d=newInst
//
// Checks mixed vectorization where some arguments are vectorized while others
// are applied as is.
//

model FuncVectorization1
  function F
    input Integer a;
    input Integer b;
    output Integer c = a;
  end F;

  Integer b[3];
  Integer c[3];
equation 
  b = {1,2,3};
  c = F(1, b);
  c = F(b, 1);
end FuncVectorization1;


// Result:
// function FuncVectorization1.F
//   input Integer a;
//   input Integer b;
//   output Integer c = a;
// end FuncVectorization1.F;
//
// class FuncVectorization1
//   Integer b[1];
//   Integer b[2];
//   Integer b[3];
//   Integer c[1];
//   Integer c[2];
//   Integer c[3];
// equation
//   b[1] = 1;
//   b[2] = 2;
//   b[3] = 3;
//   c = array(FuncVectorization1.F(1, b[$i1]) for $i1 in 1:3);
//   c = array(FuncVectorization1.F(b[$i1], 1) for $i1 in 1:3);
// end FuncVectorization1;
// endResult
