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
//   constant enumeration(a, b, c, d) earr[MinMaxEnum.E.a] = MinMaxEnum.E.a;
//   constant enumeration(a, b, c, d) earr[MinMaxEnum.E.b] = MinMaxEnum.E.b;
//   constant enumeration(a, b, c, d) earr[MinMaxEnum.E.c] = MinMaxEnum.E.c;
//   constant enumeration(a, b, c, d) earr[MinMaxEnum.E.d] = MinMaxEnum.E.d;
//   constant enumeration(a, b, c, d) e1 = MinMaxEnum.E.a;
//   constant enumeration(a, b, c, d) e2 = MinMaxEnum.E.d;
//   constant enumeration(a, b, c, d) e3 = MinMaxEnum.E.a;
//   constant enumeration(a, b, c, d) e4 = MinMaxEnum.E.d;
//   constant enumeration(a, b, c, d) e5 = MinMaxEnum.E.a;
//   constant enumeration(a, b, c, d) e6 = MinMaxEnum.E.d;
//   constant enumeration(a, b, c, d) e7 = MinMaxEnum.E.b;
//   constant enumeration(a, b, c, d) e8 = MinMaxEnum.E.c;
// end MinMaxEnum;
// endResult
