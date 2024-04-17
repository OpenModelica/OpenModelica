model QuotedIdentifier
  Real 'a"b';
  Real 'c d';
  Real 'e"f g';
  Real 'h\'i //j';
  Real '\\\\\'';
  Real '';
  Real '*/ no code injection';
  Real '\'';
equation
  der('a"b') = 1;
  der('c d') = -1;
  der('e"f g') = 2;
  der('h\'i //j') = -2;
  der('\\\\\'') = 3;
  der('') = -3;
  der('*/ no code injection') = 4;
  der('\'') = -4;
end QuotedIdentifier;
