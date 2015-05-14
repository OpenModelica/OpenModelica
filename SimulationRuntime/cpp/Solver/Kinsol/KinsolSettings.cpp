#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>


#include <Solver/Kinsol/KinsolSettings.h>

KinsolSettings::KinsolSettings()
: iNewt_max         (700)
, dRtol           (1e-12)
, dAtol           (1.0)
, dDelta          (0.9)
{
};
/*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
long int     KinsolSettings::getNewtMax()
{
  return iNewt_max;
}
void     KinsolSettings::setNewtMax(long int max)
{
  iNewt_max =max;
}
/* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
double     KinsolSettings::getRtol()
{
  return dRtol;
}
void     KinsolSettings::setRtol(double t)
{
  dRtol=t;
}
/*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
double     KinsolSettings::getAtol()
{
  return dAtol;
}
void     KinsolSettings::setAtol(double t)
{
  dAtol =t;
}
/*Dämpfungsfaktor (default: 0.9)*/
double       KinsolSettings::getDelta()
{
  return dDelta;
}
void       KinsolSettings::setDelta(double t)
{
  dDelta = t;
}

void KinsolSettings::load(string)
{
}
