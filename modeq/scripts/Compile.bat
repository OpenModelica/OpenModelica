@echo off
cd "%MOSHHOME%\..\ModSimPack\Simulator"
g++ -o %1 CModelicaSimulator.cpp -I./ ../bin/dasrt.lib ../bin/ddassldassl.lib ../bin/dgesvlapack.lib ../bin/libmat.lib ../bin/libmx.lib
