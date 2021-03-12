# Windows Subsystem for Linux - README for OpenModelica

This way of building OpenModelica is useful if you want to use a Unix shell and tools on a Windows 10 computer. You don't need to run a VM and Windows Subsystem for Linux (WSL) should be noticeably faster than doing so.

If you want to use the executables from Windows look at [Windows instructions](README-OMDev-MINGW.md) or cross compile for Windows 10 . Please let us know how you did it when it's working ;-)

## Get Windows Subsystem for Linux on Windows 10
Follow the instructions from Microsoft to install a Linux distribution.
  - [WSL install guide](https://docs.microsoft.com/de-de/windows/wsl/install-win10)

## Install build dependencies
See the Dependencies for Linux in [Linux instructions](README.Linux.md) or use
```bash
echo deb http://build.openmodelica.org/apt bionic nightly | sudo tee -a /etc/apt/sources.list
echo deb-src http://build.openmodelica.org/apt bionic nightly | sudo tee -a /etc/apt/sources.list

# Get key for OpenModelica
wget -q http://build.openmodelica.org/apt/openmodelica.asc -O- | sudo apt-key add -

sudo apt update
sudo apt build-dep openmodelica
```
## Install additional dependencies
If you want to build documentation and run all tests successfully you need some additional programs. There are two options:

- Instal the bare minimum to run the testsuite:
```bash
sudo apt update
sudo apt install flex zip unzip libomp-dev
```

OR

- Install a lot more to test everything and build documentation and so on.<br>
See [Dockerfile.build-deps](https://github.com/OpenModelica/OpenModelicaBuildScripts/blob/master/docker/Dockerfile.build-deps) from OpenModelicaBuildScripts/docker to get the up to date dependencies and do everything stated in the RUN instruction.

## Get OpenModelica from Git
Get OpenModelica from our [Github repository](https://github.com/OpenModelica/OpenModelica).
```bash
git clone --recursive https://openmodelica.org/git-readonly/OpenModelica.git OpenModelica
```

## Build OpenModelicaCompiler
```bash
cd OpenModelica
autoconf
./configure CC=clang CXX=clang++ -without-omc -with-cppruntime
make -j4    # Or 4 with the number of cores you have
```

## Test your build
```bash
make test -j4
```
