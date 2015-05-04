package Uniontype12

uniontype UT
  record REC1
    Integer x;
  end REC1;
end UT;

uniontype Expression
  record ICONST
    Integer value;
  end ICONST;
  record ADD
    Expression lhs;
    Expression rhs;
  end ADD;
  record SUB
    Expression lhs;
    Expression rhs;
  end SUB;
end Expression;

end Uniontype12;
