#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Solver/UmfPack/UmfPackSettings.h>

UmfPackSettings::UmfPackSettings() : ILinSolverSettings(), useSparse(true) {

}

UmfPackSettings::~UmfPackSettings() {
}

bool UmfPackSettings::getUseSparseFormat() {
  return useSparse;
}

void UmfPackSettings::setUseSparseFormat(bool value) {
  useSparse = value;
}

void UmfPackSettings::load(std::string allocator)
{
}
