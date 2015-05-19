#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>
 

#include <Solver/Hybrj/HybrjSettings.h>

HybrjSettings::HybrjSettings()
: iNewt_max                    (50)
, dRtol                        (1e-6)
, dAtol                        (1.0)
, dDelta                    (0.9)
{
};
/*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
long int     HybrjSettings::getNewtMax()
{
    return iNewt_max;
}
void         HybrjSettings::setNewtMax(long int max)
{
    iNewt_max =max;
}    
/* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
double         HybrjSettings::getRtol()
{
    return dRtol;
}
void         HybrjSettings::setRtol(double t)
{
    dRtol=t;
}                
/*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
double         HybrjSettings::getAtol()
{
    return dAtol;
}                        
void         HybrjSettings::setAtol(double t)
{
    dAtol =t;
}                
/*Dämpfungsfaktor (default: 0.9)*/
double         HybrjSettings::getDelta()
{
    return dDelta;
}                            
void         HybrjSettings::setDelta(double t)
{
    dDelta = t;
}    

void HybrjSettings::load(string)
{
}