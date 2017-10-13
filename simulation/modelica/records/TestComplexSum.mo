function 'sum' "Return sum of complex vector"
  input Complex v[:] "Vector";
  output Complex result "Complex sum of vector elements";
algorithm
  result:=Complex(sum(v[i].re for i in 1:size(v,1)), sum(v[i].im for i in 1:size(v,1)));
  annotation(Inline=true);
end 'sum';

model TestComplexSum1
  parameter Complex a[2]={Complex(1,2),Complex(2,3)};
  parameter Complex sum1 = 'sum'(a);
  parameter Complex sum2 = Complex(sum(a.re),sum(a.im));
end TestComplexSum1;
