within emptyconvlib;
model MainModel

parameter Boolean boolParam = true;

Real someResult;

equation
if boolParam then
  someResult = time;
  else
  someResult = time*2;
  end if;

end MainModel;
