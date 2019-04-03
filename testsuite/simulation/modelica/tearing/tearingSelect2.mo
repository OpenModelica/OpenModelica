model tearingSelect2
   Real x1 annotation(tearingSelect = avoid);
   Real x2;
   Real x3;
   Real x4;
   Real x5;
   Real x6;
equation
   0 = x1*x1 + x2;
   0 = x1*x1 + x2 +x3;
   0 = x1*x1 + x3 + x4;
   0 = x1*x1 + x4 + x5;
   0 = x1*x1 + x5 + x6;
   0 = x1 + x6*x6;
end tearingSelect2;