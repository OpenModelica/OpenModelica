"""Call fmi2FreeInstance(NULL) on an FMI 2.0 Model Exchange FMU and write
a line to the output file when the call returns.

usage: fmi2FreeInstanceNull.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model


def main(fmu, output):
    md = read_model_description(fmu)
    m = FMU2Model(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.modelExchange.modelIdentifier)
    # FMI 2.0 2.1.5: if a null pointer is provided for c, the call is ignored
    m.dll.fmi2FreeInstance(None)
    with open(output, "w") as f:
        f.write("fmi2FreeInstance(NULL) returned\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
