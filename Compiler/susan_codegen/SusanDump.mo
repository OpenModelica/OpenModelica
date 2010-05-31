package SusanDump
  
public import Tpl;

//public 
function __templPackage
  input Tpl.Text inText;
  input Tpl.TemplPackage in__tp;
  output Tpl.Text outText;
algorithm
  (outText) := matchcontinue (inText, in__tp)
    local
      Text ts;
    case (ts,
      TplAbsyn.TEMPL_PACKAGE(
         name = __name, 
         extendsList = __extendsList,
         imports = __imports,
         templateDefs = __templateDefs) )
      local
        Integer ind, ap; 
        PathIdent __name;
        list<String> __extendsList;
        list<PathIdent> __imports;
        list<TemplateDef> __templateDefs;
      equation
        ts = Tpl.write(ts, "package ");
        ts = __pathIdend(ts, __name);
        ts = Tpl.nl(ts);
        ts = Tpl.nl(ts);
        ts = Tpl.listMap(ts, __extendsList, s0_templPackage, "\n");
        //ts = s0_templPackage(ts, __extendsList, Tpl.nl);
        ts = Tpl.nl(ts);
        //ts = s1_templPackage(ts, __imports);
        ts = Tpl.nl(ts);
        //ts = s2_templPackage(ts, __templateDefs);        
      then ts;
  end matchcontinue;      
end __templPackage;


function s0__templPackage
  input Tpl.Text inText;
  input String in__it;
  output Tpl.Text outText;
algorithm
  outText := matchcontinue (inText, in__it)
    case (ts, __it) 
      local
        Text ts;
        String __it;
      equation
        ts = Tpl.write(ts, "extends \"");
        ts = Tpl.writeParseNL(ts, __it);              
    then ts;
  end matchcontinue;      
end s0__templPackage;

// or can be optimized to
function so0__templPackage
  input Tpl.Text inText;
  input String in__it;
  output Tpl.Text outText;
algorithm
  outText := Tpl.write(inText, "extends \"");
  outText := Tpl.writeParseNL(outText, __it);
  outText := Tpl.write(outText, "\"");          
end so0__templPackage;



end SusanDump;
