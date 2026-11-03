// name:     MinMaxEnum
// keywords: builtin functions min max
// status:   correct
//
// Usage of the min and max functions with enumerations.
//

model MinMaxEnum
  type E = enumeration(a, b, c, d);
  constant E earr[E] = E.a:E.d;

  constant E e1 = min(E.a, E.d);
  constant E e2 = max(E.a, E.d);
  constant E e3 = min(earr);
  constant E e4 = max(earr);
  constant E e5 = min(e for e in earr);
  constant E e6 = max(e for e in earr);
  constant E e7 = min(e for e in {E.c, E.b, E.d});
  constant E e8 = max(e for e in {E.a, E.c, E.b});
end MinMaxEnum;

// Result:
// class MinMaxEnum
//   constant enumeration(a, b, c, d) earr[E.a] = E.a;
//   constant enumeration(a, b, c, d) earr[E.b] = E.b;
//   constant enumeration(a, b, c, d) earr[E.c] = E.c;
//   constant enumeration(a, b, c, d) earr[E.d] = E.d;
//   constant enumeration(a, b, c, d) e1 = E.a;
//   constant enumeration(a, b, c, d) e2 = E.d;
//   constant enumeration(a, b, c, d) e3 = E.a;
//   constant enumeration(a, b, c, d) e4 = E.d;
//   constant enumeration(a, b, c, d) e5 = E.a;
//   constant enumeration(a, b, c, d) e6 = E.d;
//   constant enumeration(a, b, c, d) e7 = E.b;
//   constant enumeration(a, b, c, d) e8 = E.c;
// end MinMaxEnum;
// endResult
