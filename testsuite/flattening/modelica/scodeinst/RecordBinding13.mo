// name: RecordBinding13
// keywords:
// status: correct
// cflags: -d=newInst
//

record R
  parameter Integer n = 1 annotation(Evaluate=true);
end R;

function anyTrue
  input Boolean[:] b;
  output Boolean result;
algorithm
  result := false;
  for i in 1:size(b, 1) loop
    result := result or b[i];
  end for;
end anyTrue;

model RecordBinding13
  parameter Integer Ns = 1;
  parameter Integer Np = 2;
  parameter R r1;
  parameter R r2;
  parameter Integer[:, 2] k = {{0, 0}};
  parameter R[Ns, Np] r3 = {{if anyTrue({ks == k[i, 1] and kp == k[i, 2] for i in 1:size(k, 1)}) then r1 else r2 for kp in 1:Np} for ks in 1:Ns};
end RecordBinding13;

// Result:
// class RecordBinding13
//   final parameter Integer Ns = 1;
//   final parameter Integer Np = 2;
//   final parameter Integer r1.n = 1;
//   final parameter Integer r2.n = 1;
//   final parameter Integer k[1,1] = 0;
//   final parameter Integer k[1,2] = 0;
//   parameter Integer r3[1,1].n = 1;
//   parameter Integer r3[1,2].n = 1;
// end RecordBinding13;
// endResult
