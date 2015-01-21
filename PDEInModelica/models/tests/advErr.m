fileName = "conservationLaws.advection_res.mat";
varName = "u";
finalT = 0.2;
[nameT, data_2, nFrame] = openMat(fileName);

%uE = function adv(t,x)
%   if (0.5 + t < x )
%     uE = 1;
%   else
%     uE = 0;
%end;
  
if (getTimeMat(nFrame, nameT, data_2)) != finalT 
  error("times are not consistent");
end;

x = getVarMat("x", nFrame, nameT, data_2);

%u = getVarMat(varName, nFrame, nameT, data_2);
