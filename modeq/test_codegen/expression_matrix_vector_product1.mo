
function expression_matrix_vector_product1
  input Real matr[2,2];
  input Real vect[2];
  output Real[2] rvect;
algorithm
  rvect := vect*matr;
end expression_matrix_vector_product1;

model mo
end mo;
