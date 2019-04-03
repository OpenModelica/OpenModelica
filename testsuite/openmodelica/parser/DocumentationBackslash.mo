// name: DocumentationBackslash
// status: correct
//
// See bug #1143. Dymola allows this behaviour even though the specification
// does not. So we need to print the warnings.
//

model DocumentationBackslash
  annotation(Diagram(coordinateSystem(extent={{-100.0,-100.0},{100.0,100.0}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Documentation(info="
 <em>Extras\Libraries\CommunicationMSWindows.dll</em>", revisions=""));
end DocumentationBackslash;

// Result:
// [openmodelica/parser/DocumentationBackslash.mo:9:158-9:172:writable] Warning: Lexer treating \ as \\, since \L is not a valid Modelica escape sequence.
// [openmodelica/parser/DocumentationBackslash.mo:9:158-9:182:writable] Warning: Lexer treating \ as \\, since \C is not a valid Modelica escape sequence.
//
// class DocumentationBackslash
// end DocumentationBackslash;
// endResult
