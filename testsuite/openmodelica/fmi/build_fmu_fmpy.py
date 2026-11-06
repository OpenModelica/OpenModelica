#!/usr/bin/env python3
"""Build the binary of a source code FMU the way an importer does.

FMPy compiles the source files that modelDescription.xml (FMI 2.0) or
sources/buildDescription.xml (FMI 3.0) lists, with sources/ as the include
directory, and does not use the CMakeLists.txt of the FMU. The binaries of the
input FMU are left out, so the output FMU only has the ones FMPy built.

Usage:
    build_fmu_fmpy.py <source_fmu> <output_fmu>
"""
import os
import shutil
import sys
import tempfile
import zipfile


def main(argv):
    if len(argv) != 3:
        sys.stderr.write("usage: build_fmu_fmpy.py <source_fmu> <output_fmu>\n")
        return 2

    source_fmu, output_fmu = argv[1], os.path.abspath(argv[2])
    with tempfile.TemporaryDirectory() as tmp:
        unzipdir = os.path.join(tmp, "fmu")
        with zipfile.ZipFile(source_fmu) as z:
            z.extractall(unzipdir)
        shutil.rmtree(os.path.join(unzipdir, "binaries"), ignore_errors=True)

        try:
            from fmpy.build import build_platform_binary
        except ImportError:
            build_platform_binary = None
        if build_platform_binary:
            build_dir = os.path.join(tmp, "build")
            os.mkdir(build_dir)
            build_platform_binary(unzipdir, build_dir=build_dir)

        if os.path.exists(output_fmu):
            os.remove(output_fmu)
        with zipfile.ZipFile(output_fmu, "w", zipfile.ZIP_DEFLATED) as z:
            for root, _, files in os.walk(unzipdir):
                for f in files:
                    path = os.path.join(root, f)
                    z.write(path, os.path.relpath(path, unzipdir))

    if not build_platform_binary:
        from fmpy.util import compile_platform_binary
        compile_platform_binary(output_fmu)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
