/** @addtogroup solverNewton
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>


#include <Solver/Newton/NewtonSettings.h>

NewtonSettings::NewtonSettings()
: iNewt_max                    (50)
, dRtol                        (1e-6)
, dAtol                        (1e-6)
, dDelta                    (1)
{
};

NewtonSettings::~NewtonSettings()
{

}

/*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
long int     NewtonSettings::getNewtMax()
{
    return iNewt_max;
}
void         NewtonSettings::setNewtMax(long int max)
{
    iNewt_max =max;
}
/* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
double         NewtonSettings::getRtol()
{
    return dRtol;
}
void         NewtonSettings::setRtol(double t)
{
    dRtol=t;
}
/*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
double         NewtonSettings::getAtol()
{
    return dAtol;
}
void         NewtonSettings::setAtol(double t)
{
    dAtol =t;
}
/*Dämpfungsfaktor (default: 0.9)*/
double         NewtonSettings::getDelta()
{
    return dDelta;
}
void         NewtonSettings::setDelta(double t)
{
    dDelta = t;
}

void NewtonSettings::load(string)
{
}
/** @} */ // end of solverNewton
