// name:     loadFileInteractiveQualifiedInit
// keywords: package hierarchy loading
// status: correct
//
// Package hierachy loading
//

package Something "Something"

  package Somewhere "Somewhere"

  end Somewhere;

  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end Something;
