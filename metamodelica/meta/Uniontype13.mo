package Uniontype13

record foo
  UT ut;
end foo;

uniontype UT
  record REC1
    Integer x;
  end REC1;
end UT;

function test
  input UT ut;
  output foo result;
algorithm
  result.ut := ut;
end test;

function fooIdent
  input foo f;
  output foo out;
algorithm
  out := f;
end fooIdent;

end Uniontype13;
