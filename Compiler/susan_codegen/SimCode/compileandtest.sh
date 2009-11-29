# This script will recompile the SimCodeC template and then the OMC compiler.
# After that it will compile the HelloWorld.mo module.
#
# Hooks in Codegen.mo will call the SimCodeC module and thus print some
# template generated code.

OMC=../../../build/bin/omc

echo "%%%%% Compiling template..."
$OMC +d=failtrace SimCodeC.tpl

echo "%%%%% Copying compiled template to Compiler dir..."
cp SimCodeC.mo ../..

echo "%%%%% Compiling test..."
make -C ../..

echo "%%%%% Result START"
cd GenTest
../$OMC +s HelloWorld.mo
cd ..
echo 
echo "%%%%% Result END"
