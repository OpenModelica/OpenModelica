package B
  constant Real c=1,d=2;
end B;

class GroupImport
  import B.{c,e=d};
  Real r = c+e;
end GroupImport;
