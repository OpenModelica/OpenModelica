within ;
function traversePackage
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
      // is it called "Examples"
      if (className == "Examples") then
        printModels(classAttributes.fullName);
      else
        // traverse deeper
        traversePackage(classAttributes.fullName);
      end if;
    end if;
  end for;

  annotation (uses(Modelica(version="3.2")));
end traversePackage;
