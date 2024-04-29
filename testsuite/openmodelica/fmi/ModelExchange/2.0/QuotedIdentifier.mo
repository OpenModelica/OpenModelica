model QuotedIdentifier
  Real 'a"b'(start = 1, fixed = true);
  Real 'c d'(start = 1, fixed = true);
  Real 'e"f g'(start = 1, fixed = true);
  Real 'h\'i //j'(start = 1, fixed = true);
  Real '\\\\\''(start = 1, fixed = true);
  Real '*/ no code injection'(start = 1, fixed = true);
  Real '\''(start = 1, fixed = true);
  Real /*(y)*/ 'stupid,name'(start = 1, fixed = true);
equation
  der('a"b') = 1;
  der('c d') = -1;
  der('e"f g') = 2;
  der('h\'i //j') = -2;
  der('\\\\\'') = 3;
  der('*/ no code injection') = 4;
  der('\'') = -4;
  der('stupid,name') = 5;
end QuotedIdentifier;
