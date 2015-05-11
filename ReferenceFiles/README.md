# Generating reference files

Generating good reference files is not easy. You want to be able to
compare files with enough time points, but time points cost storage.
No reference file should be greater than 1MB, and ideally less than
200 kB or so.

## Filtering a results file using OpenModelica

Once you performed a simulation and got a reference file, you first
need to know which variables to compare between test runs.
Once you know this, you can tell the OMC to filter the file:
```Modelica
filterSimulationResults("inFile.mat", "outFile.mat", {"x", "y", "z"});
```
This removes any variables not called x, y, or z from the result file.
Put the file under a directory here, and compress it using:
```bash
xz --best MyPackage/MyModel.mat
git add MyPackage/MyModel.mat.xz
```

## Converting existing reference files

Use a script like the following if the mos-file only used
compareSimulationResults and did not assign the variables to filter
to a variable for easy use.

```bash
for f in *.mos; do
  MAT=`echo $f | sed "s/[.]mos/.mat/"`
  sed -i -e '/^0/d' -e /^loadModel/d -e /^simulate/d -e '/^"ThermoSysPro/d' -e "s/compareSimulationResults./filterSimulationResults(\"$MAT\",/" -e  "s,// Result:,getErrorString()," "$f"
  echo "$f"
  omc "$f"
done

for f in *.mat; do
  du -h $f ReferenceFiles/$f
done
```

```bash
for f in *.mos; do
  # MAT=`echo $f | sed "s/[.]mos/.mat/"`
  MAT=`echo $f | sed "s/[.]mos//" | rev | cut -d. -f1 | rev`.mat
  VARS=`grep -v "^//" $f | grep -v loadModel | grep "{[^{]*}"`
  cat > a.mos <<EOL
filterSimulationResults("$MAT","ReferenceFiles/$MAT",$VARS
getErrorString();
EOL
  omc a.mos
  rm -f a.mos
done
```

If the model uses the model testing scripts, you might be able to
simply change the common file to produce the filtered outputs directly.
