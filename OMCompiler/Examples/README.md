# Examples

## Documentation

This directory stores Modelica examples and scripts used to build the OpenModelica User's Guide.

## Modelica Compliance Suite

### Dependencies

- Python 3 with modules
  - junit_xml
  - simplejson
  - natsort

- xsltproc

    ```bash
    sudo apt-get update
    sudo apt-get install xsltproc
    ```

- [Compliance Suite](https://github.com/modelica/Modelica-Compliance/) Modelica library

    ```modelica
    installPackage(ModelicaCompliance, "3.2.0-master", exactMatch=true); getErrorString();
    ```

### Environment variables

```bash
export COMPLIANCEEXTRAOMFLAGS="-d=newInst"
export COMPLIANCEEXTRAREPORTFLAGS="--expectedFailures=/path/to/OpenModelica/.CI/compliance.failures --flakyTests=/path/to/OpenModelica/.CI/compliance.flaky"
export COMPLIANCEPREFIX="compliance"
```

### Run script

```bash
omc -g=MetaModelica ComplianceSuite.mos
```

The sucessfull result can be found in file [compliance.html](./compliance.html)
and the failures in [compliance.failures](./compliance.failures).
