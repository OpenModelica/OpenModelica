within ;
function printModels
  input String packageName;
protected
  String classNames[:];
  ModelManagement.Structure.AST.ClassAttributes classAttributes;
algorithm
  // get class names
  classNames := ModelManagement.Structure.AST.ClassesInPackage(packageName);

  // run through all packages
  for className in classNames loop
    // get classAttributes
    classAttributes := ModelManagement.Structure.AST.GetClassAttributes(packageName + "." + className);

    // is it a package?
    if (classAttributes.restricted == "package") then
      if (className <> "Utilities") then
        printModels(classAttributes.fullName);
      end if;
    elseif (classAttributes.restricted == "model") then
      Modelica.Utilities.Streams.print(classAttributes.fullName);
    end if;
  end for;
  annotation (uses(Modelica(version="3.2")));
end printModels;
