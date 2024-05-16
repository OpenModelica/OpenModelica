model QuotedIdentifier
  Real 'a"b'(start = 1, fixed = true);
  Real 'c d'(start = 2, fixed = true);
  Real 'e"f g'(start = 3, fixed = true);
  Real 'h\'i //j'(start = 4, fixed = true);
  Real '\\\\\''(start = 5, fixed = true);
  Real '<&>'(start = 6, fixed = true);
  Real '*/ no code injection'(start = 7, fixed = true);
  Real '\''(start = 8, fixed = true);
  Real /*(y)*/ 'stupid,name'(start = 9, fixed = true);
equation
  der('a"b') = 1;
  der('c d') = -1;
  der('e"f g') = 2;
  der('h\'i //j') = -2;
  der('\\\\\'') = 3;
  der('<&>') = -3;
  der('*/ no code injection') = 4;
  der('\'') = -4;
  der('stupid,name') = 5;
end QuotedIdentifier;
