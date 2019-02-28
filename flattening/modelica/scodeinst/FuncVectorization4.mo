// name: FuncVectorization4
// keywords: vectorization function
// status: correct
// cflags: -d=newInst
//
//

model FuncVectorization4
  function f
    input Real[:, :] x;
    output Real s = 0.0;
  algorithm
    for i in 1:size(x, 1) loop
      s := s + sum(abs(x[i, :]));
    end for;
  end f;

  Real x;
equation 
  x = f({{time, 2, 3}, {4, 5, 6}});
  x = f({{1, 2, 3}, {4, 5, 6}});
end FuncVectorization4;


// Result:
// function FuncVectorization4.f
//   input Real[:, :] x;
//   output Real s = 0.0;
// algorithm
//   for i in 1:size(x, 1) loop
//     s := s + sum(array(abs(x[i,$i1]) for $i1 in 1:size(x[i,:], 1)));
//   end for;
// end FuncVectorization4.f;
//
// class FuncVectorization4
//   Real x;
// equation
//   x = FuncVectorization4.f({{time, 2.0, 3.0}, {4.0, 5.0, 6.0}});
//   x = 21.0;
// end FuncVectorization4;
// endResult
