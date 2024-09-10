// name: SD
// keywords:
// status: correct
// cflags: -d=newInst,-nfScalarize,arrayConnect,combineSubscripts -f
//

connector C
  Real e;
  flow Real f;
end C;

model SF
  parameter Real p = 6;
  C c;
equation
  c.f = p;
end SF;

model CC
  parameter Integer N = 3;
  parameter Real p = 1;
  Real[N] x;
  C c;
equation
  x[1] = c.e;
  x[N] = c.f;
  for i in 2:N loop
    x[i] = x[i - 1] + p;
  end for;
end CC;

model SD
  parameter Integer N = 3;
  parameter Real[N] p = {1.0, 1.5, 2.0};
  CC[N] c(p = p, N = {3, 4, 5});
  SF s(p = 3);
equation
  connect(s.c, c[1].c);
  for i in 1:N - 1 loop
    connect(c[i + 1].c, c[i].c);
  end for;
end SD;

// Result:
// //! base 0.1.0
// package 'SD'
//   model 'SD'
//     parameter Integer 'N' = 3;
//     parameter Real[3] 'p' = {1.0, 1.5, 2.0};
//     parameter Integer[3] 'c.N' = {3, 4, 5};
//     parameter Real[3] 'c.p' = 'p'[:];
//     Real[3, {3, 4, 5}] 'c.x';
//     Real[3] 'c.c.e';
//     Real[3] 'c.c.f';
//     parameter Real 's.p' = 3.0;
//     Real 's.c.e';
//     Real 's.c.f';
//   equation
//     'c.x'[:,1] = 'c.c.e'[:];
//     'c.x'[:,'c.N'[:]] = 'c.c.f'[:];
//
//     for '$i1' in 1:3 loop
//       for 'i' in 2:({3, 4, 5})['$i1'] loop
//         'c.x'['$i1','i'] = 'c.x'['$i1','i' - 1] + 'c.p'['$i1'];
//       end for;
//     end for;
//
//     's.c.f' = 's.p';
//     'c.c.e'[2] = 'c.c.e'[1];
//     's.c.e' = 'c.c.e'[1];
//     'c.c.e'[3] = 'c.c.e'[1];
//     'c.c.f'[3] + 's.c.f' + 'c.c.f'[2] + 'c.c.f'[1] = 0.0;
//   end 'SD';
// end 'SD';
// endResult
