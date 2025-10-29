# Examples

## Modelica Compliance Suite

### Dependencies

- Python 3
- xsltproc

    ```bash
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
