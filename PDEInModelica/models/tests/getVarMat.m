function var = getVarMat(varName, n, nameT, data_2)
  varName = [varName "["];
  indexes = [];
  for i = 1:size(nameT,1)
    if isequal(varName,nameT(i,1:size(varName,2)))
	  indexes = [indexes i];
    end;
  end;
  var = data_2(indexes,n);
end;
