// name: CombineSubscripts3
// keywords:
// status: correct
// cflags: -d=newInst,-nfScalarize,combineSubscripts -f
//

record A
  Real[4] x;
  Real p;
end A;

model CombineSubscripts3
  A[3] b;
equation
  for i in 1:3 loop
    for j in 2:3 loop
      b[i].x[j] = b[i].x[j - 1] + b[i].p;
    end for;
  end for;
end CombineSubscripts3;

// Result:
// package 'CombineSubscripts3'
//   model 'CombineSubscripts3'
//     Real[3] 'b.p';
//     Real[3, 4] 'b.x';
//   equation
//     for 'i' in 1:3 loop
//       for 'j' in 2:3 loop
//         'b.x'['i','j'] = 'b.x'['i','j' - 1] + 'b.p'['i'];
//       end for;
//     end for;
//   end 'CombineSubscripts3';
// end 'CombineSubscripts3';
// endResult
