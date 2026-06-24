#!/usr/bin/env python3
from pathlib import Path
import re


PACKAGE = "ModelicaDataReconciliationSimpleTests"
ROOT = Path(PACKAGE)

TEMPLATE = """// name:     {model}
// keywords: extraction algorithm
// status:   correct
// depends: ./{dependency}

setCommandLineOptions("--preOptModules+=dataReconciliation");
getErrorString();
loadFile("{package}/package.mo");
getErrorString();

AnnotationNamedModifiers:=getAnnotationNamedModifiers({model}, "__OpenModelica_simulationFlags");

simFlags:="-reconcile ";
for i in 1:size(AnnotationNamedModifiers, 1) loop
  simFlags:=simFlags+ " -"+AnnotationNamedModifiers[i]+"="+getAnnotationModifierValue({model}, "__OpenModelica_simulationFlags", AnnotationNamedModifiers[i]);
end for;
print("simFlags: "+simFlags);

simulate({model}, simflags=simFlags);
getErrorString();

"""


def model_name(path: Path) -> str:
    rel = path.with_suffix("").relative_to(ROOT)
    return ".".join((PACKAGE, *rel.parts))


def dependency(text: str) -> str:
    match = re.search(r'sx\s*=\s*"modelica://ModelicaDataReconciliationSimpleTests/([^"]+)"', text)
    if not match:
        raise ValueError("missing sx resource annotation")
    return f"{PACKAGE}/{match.group(1)}"


def old_result(path: Path) -> str:
    if not path.exists():
        return ""
    text = path.read_text()
    marker = "// Result:"
    if marker not in text:
        return ""
    return text[text.index(marker):].rstrip() + "\n"


def write_mos(source: Path) -> Path:
    text = source.read_text()
    model = model_name(source)
    out = Path(f"{model}.mos")
    body = TEMPLATE.format(model=model, package=PACKAGE, dependency=dependency(text))
    result = old_result(out)
    out.write_text(body + ("\n" + result if result else ""))
    return out


def main() -> None:
    sources = sorted(ROOT.glob("Models/**/*.mo"))
    generated = []
    for source in sources:
        if "__OpenModelica_simulationFlags" in source.read_text():
            generated.append(write_mos(source))

    for path in generated:
        print(path)


if __name__ == "__main__":
    main()
