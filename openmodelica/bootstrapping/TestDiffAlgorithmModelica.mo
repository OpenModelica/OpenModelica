function diffModelica
  import LexerModelicaDiff.{Token,TokenId,tokenContent,scan,scanString,filterModelicaDiff,modelicaDiffTokenEq};
  import DiffAlgorithm.{Diff,diff,printActual,printDiffTerminalColor};
  input String before;
  input String after;
protected
  list<Token> tbefore,tafter,tafter2;
  list<tuple<Diff, list<Token>>> diffs;
  String after2;
algorithm
  tbefore := scan(before);
  print(before + ":\n");
  print(sum(tokenContent(t) for t in tbefore));
  print("\n\n");
  tafter := scan(after);
  diffs := diff(tbefore, tafter, modelicaDiffTokenEq);
  diffs := filterModelicaDiff(diffs);
  // Scan a second time, with comments filtered into place
  after2 := printActual(diffs, tokenContent);
  tafter2 := scanString(after2);
  diffs := diff(tbefore, tafter2, modelicaDiffTokenEq);
  diffs := filterModelicaDiff(diffs);
  print(printDiffTerminalColor(diffs, tokenContent));
  print("\n\n");
end diffModelica;
