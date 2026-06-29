#!/usr/bin/env python3
from pathlib import Path
import re
import sys


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


def source_path(model: str) -> Path:
    parts = model.split(".")
    if len(parts) < 2:
        raise ValueError(f"model name is not qualified: {model}")
    return Path(parts[0], *parts[1:]).with_suffix(".mo")


def dependency(text: str) -> str:
    match = re.search(r'sx\s*=\s*"modelica://([^/]+)/([^"]+)"', text)
    if not match:
        raise ValueError("missing sx resource annotation")
    return f"{match.group(1)}/{match.group(2)}"


def old_result(path: Path) -> str:
    if not path.exists():
        return ""
    text = path.read_text()
    marker = "// Result:"
    if marker not in text:
        return ""
    return text[text.index(marker):].rstrip() + "\n"


def write_mos(model: str) -> Path:
    source = source_path(model)
    if not source.exists():
        raise FileNotFoundError(source)

    text = source.read_text()
    if "__OpenModelica_simulationFlags" not in text:
        raise ValueError(f"{model} has no __OpenModelica_simulationFlags annotation")

    package = model.split(".", 1)[0]
    out = Path(f"{model}.mos")
    body = TEMPLATE.format(model=model, package=package, dependency=dependency(text))
    result = old_result(out)
    out.write_text(body + ("\n" + result if result else ""))
    return out


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("usage: generateModelicaDataReconciliationMos.py Model.Name [Model.Name ...]")

    generated = [write_mos(model) for model in sys.argv[1:]]
    for path in generated:
        print(path)


if __name__ == "__main__":
    main()
