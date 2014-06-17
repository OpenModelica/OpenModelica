#include "UmfPackSettings.h"

UmfPackSettings::UmfPackSettings() : ILinSolverSettings(), useSparse(false) {

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
