package LookupBuiltin

function identity
  input String str;
  output String o = str;
algorithm
end identity;

function id
  input String str;
  output String o = identity(str);
algorithm
end id;

end LookupBuiltin;
