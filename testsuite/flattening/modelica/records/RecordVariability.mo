// name:     Record Variability
// keywords: record
// status:   correct

record abcRec
  Integer a;
  parameter Integer b = 2;
  constant Integer c = 3;
end abcRec;

model example
  constant  Integer p = 13;
  constant  abcRec x = abcRec(1);
  parameter abcRec y = abcRec(4,p*2);
            abcRec z = abcRec(2,p);
end example;

// Result:
// function abcRec "Automatically generated record constructor for abcRec"
//   input Integer a;
//   input Integer b = 2;
//   protected Integer c = 3;
//   output abcRec res;
// end abcRec;
//
// class example
//   constant Integer p = 13;
//   constant Integer x.a = 1;
//   constant Integer x.b = 2;
//   constant Integer x.c = 3;
//   parameter Integer y.a = 4;
//   parameter Integer y.b = 26;
//   constant Integer y.c = 3;
//   Integer z.a = 2;
//   parameter Integer z.b = 13;
//   constant Integer z.c = 3;
// end example;
// endResult
