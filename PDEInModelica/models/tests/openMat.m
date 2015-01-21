function [nameT, data_2, N] = openMat(fileName)
  load(fileName);
  nameT = transpose(name);
  N = size(data_2,2);
end;
