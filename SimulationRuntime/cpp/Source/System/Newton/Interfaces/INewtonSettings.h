#pragma once

#include "../../Solver/Interfaces/ISolverSettings.h"



/*****************************************************************************/
/**

Klasse zur Kapselung der Parameter (Einstellungen) für Newton.
Hier werden default-Einstellungen entsprechend der allgemeinen Simulations-
einstellugnen gemacht, diese können überprüft und ev. Fehleinstellungen korrigiert 
werden.
\date     Montag, 1. August 2005
\author   Daniel Kanth
$Id: NewtonSettings.h,v 1.1 2007/04/25 02:18:37 danikant Exp $
\par	Synopsis:
NewtonSettings(&System, &Global);
*/
/*****************************************************************************
Copyright (c) 2004, Bosch Rexroth AG, All rights reserved
*****************************************************************************/
class INewtonSettings 
{
public:
	~INewtonSettings(){};
	/*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
	virtual long int    getNewtMax() =0;					
	virtual void    setNewtMax(long int) =0;	
	/* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
	virtual double		getRtol() = 0;
	virtual void		setRtol(double) = 0;				
	/*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
	virtual double		getAtol() = 0;						
	virtual void		setAtol(double) = 0;				
	/*Dämpfungsfaktor (default: 0.9)*/
	virtual double	    getDelta() = 0;							
	virtual void	    setDelta(double) = 0;		
	virtual void load(string)=0;
};
