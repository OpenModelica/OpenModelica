
function matrix_vector_product
  input Real matr[2,2];
  input Real vect[2];
  output Real[2] rvect;
algorithm
  rvect := vect*matr;
end matrix_vector_product;

model mo
end mo;
