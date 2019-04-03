package Recursive

function facMetaModelica
  input Integer i;
  output Integer out;
algorithm
  out := matchcontinue i
    case 0 then 1;
    else i*facMetaModelica(i-1);
  end matchcontinue;
end facMetaModelica;

function facModelica
  input Integer i;
  output Integer out;
algorithm
  out := if i==0 then 1 else i*facModelica(i-1);
end facModelica;

end Recursive;
