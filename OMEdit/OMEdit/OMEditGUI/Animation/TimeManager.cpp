/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Volker Waurich <volker.waurich@tu-dresden.de>
 */

#include "TimeManager.h"

TimeManager::TimeManager(const double simTime, const double realTime, const double realTimeFactor, const double visTime,
                         const double hVisual, const double startTime, const double endTime)
  : _simTime(simTime),
    _realTime(realTime),
    _realTimeFactor(realTimeFactor),
    _visTime(visTime),
    _hVisual(hVisual),
    _startTime(startTime),
    _endTime(endTime),
    _pause(true),
    mSpeedUp(1.0),
    mTimeDiscretization(1000)
{
  mpUpdateSceneTimer = new QTimer;
  mpUpdateSceneTimer->setInterval(100);
  rt_ext_tp_tick_realtime(&_visualTimer);
}

void TimeManager::updateTick()
{
  _realTime = rt_ext_tp_tock(&_visualTimer)*1e9;
}

int TimeManager::getTimeFraction()
{
  return int(_visTime / (_endTime - _startTime)*mTimeDiscretization);
}

double TimeManager::getEndTime() const
{
  return _endTime;
}

void TimeManager::setEndTime(const double endTime)
{
  _endTime = endTime;
}

double TimeManager::getStartTime() const
{
  return _startTime;
}

void TimeManager::setStartTime(const double startTime)
{
  _startTime = startTime;
}

double TimeManager::getSimTime() const
{
  return _simTime;
}

void TimeManager::setSimTime(const double simTime)
{
  _simTime = simTime;
}

double TimeManager::getVisTime() const
{
  return _visTime;
}

void TimeManager::setVisTime(const double visTime)
{
  _visTime = visTime;
}

double TimeManager::getHVisual() const
{
  return _hVisual;
}

void TimeManager::setHVisual(const double hVis)
{
  _hVisual = hVis;
}

double TimeManager::getRealTime() const
{
  return _realTime;
}

double TimeManager::getRealTimeFactor() const
{
  return _realTimeFactor;
}

void TimeManager::setRealTimeFactor(const double rtf)
{
  _realTimeFactor = rtf;
}

bool TimeManager::isPaused() const
{
  return _pause;
}

void TimeManager::setPause(const bool status)
{
  _pause = status;
  if (status) {
    mpUpdateSceneTimer->stop();
  } else {
    mpUpdateSceneTimer->start();
  }
}

void TimeManager::setSpeedUp(double value)
{
  mSpeedUp = value;
}

double TimeManager::getSpeedUp()
{
  return mSpeedUp;
}
