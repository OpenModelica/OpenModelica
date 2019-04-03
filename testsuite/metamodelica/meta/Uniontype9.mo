 record foo
  Integer x;
  Real y;
  String z;
end foo;

uniontype UT
  record REC1
    Integer x;
    Real y;
    String z;
  end REC1;

  record REC2
    Integer i;
    Real r;
    String s;
    Boolean b;
  end REC2;

  record REC3
    UT ut;
  end REC3;

  record REC4
    foo f;
  end REC4;
end UT;

