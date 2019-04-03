package AlgPatternm

function f1
  input Integer i;
  output Integer o1;
  output Integer o2;
algorithm
  (o1,o2) := f2(i);
end f1;

function f2
  input Integer i;
  output tuple<Integer,Integer> o;
algorithm
  o := (i,2*i);
end f2;

end AlgPatternm;
