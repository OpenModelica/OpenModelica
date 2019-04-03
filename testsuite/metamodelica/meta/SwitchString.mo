function switchString
  output String x;
protected
  String ident = "IncludeDirectory";
algorithm
  x := match ident
    case "choices"              then "";
    case "Documentation"        then "";
    case "Dialog"               then "";
    case "Diagram"              then "";
    case "Icon"                 then "";
    case "Line"                 then "";
    case "Placement"            then "";
    case "preferredView"        then "";
    case "conversion"           then "";
    case "defaultComponentName" then "";
    case "revisionId"           then "";
    case "uses"                 then "";
    else then "bad";
  end match;
end switchString;
