$ErrorActionPreference = "Stop"

Write-Host "Building Docker image..."
docker build -t librarydocumentation `
  --build-arg OMC=openmodelica/openmodelica:v1.26.3-ompython `
  -f Dockerfile .

Write-Host "Running container..."
docker run --rm -it `
  -v "$(${PWD}.Path)\..\GenerateDoc.mos:/usr/share/doc/omc/testmodels/GenerateDoc.mos" `
  -v "$(${PWD}.Path)\..\generate_icons.py:/usr/share/doc/omc/testmodels/generate_icons.py" `
  -v ${PWD}\Output:/workspace `
  -w /workspace `
  librarydocumentation bash -c "omc /usr/share/doc/omc/testmodels/GenerateDoc.mos"
