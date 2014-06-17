#include "UmfPack.h"

UmfPack::UmfPack(IAlgLoop* algLoop, ILinSolverSettings* settings) : _iterationStatus(CONTINUE), _umfpackSettings(settings), _algLoop(algLoop)
{

}

UmfPack::~UmfPack() {
}

void UmfPack::initialize()
{
	_algLoop->setUseSparseFormat(_umfpackSettings->getUseSparseFormat());
	_algLoop->initialize();
	std::cerr << "Umfpack-initialize not implemented" << std::endl;
}

void UmfPack::solve()
{
	std::cerr << "Umfpack-solve not implemented" << std::endl;
}

IAlgLoopSolver::ITERATIONSTATUS UmfPack::getIterationStatus()
{
	return _iterationStatus;
}

void UmfPack::stepCompleted(double time)
{
	std::cerr << "Umfpack-step completed not implemented" << std::endl;
}
