fileName = "conservationLaws.advection_res.mat";
[nameT, data_2, N] = openMat(fileName);
for i = 1:N
  getTimeMat(i, nameT, data_2) 
end
