encapsulated package Mod_Builtin


public function builtIn
input String mat_fname;
output String mod_fname;
algorithm
  mod_fname := matchcontinue (mat_fname)
  local
    String fname;
    case("disp") equation fname = "print"; then fname; 
    case("error") equation fname = "print"; then fname; 
    case("diag") equation fname = "diagonal"; then fname; 
    case("rdivide") equation fname = "rdivide"; then fname;   
end matchcontinue;
end builtIn;


end Mod_Builtin;
