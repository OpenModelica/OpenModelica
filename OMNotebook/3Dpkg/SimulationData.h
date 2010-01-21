/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

#pragma once

#include <Qt/qdom.h>
#include <QtCore/QString>
#include <QtCore/QFile>
#include <QtCore/QVector>
#include <QtCore/QHash>

#include <Inventor/nodes/SoSeparator.h>
#include <Inventor/nodes/SoTranslation.h>
#include <Inventor/nodes/SoRotation.h>
#include <Inventor/nodes/SoScale.h>
#include <Inventor/nodes/SoPerspectiveCamera.h>
#include <Inventor/nodes/SoDrawStyle.h>
#include <Inventor/nodes/SoLightModel.h>
#include <Inventor/fields/SoSFVec3f.h>
#include <Inventor/nodes/SoCube.h>
#include <Inventor/nodes/SoCone.h>
#include <Inventor/nodes/SoCylinder.h>
#include <Inventor/nodes/SoSphere.h>

#include <Inventor/nodes/SoAnnotation.h>
#include <Inventor/nodes/SoText2.h>
#include <Inventor/nodes/SoFont.h>
#include <Inventor/nodes/SoBaseColor.h>

namespace IAEX
{
	class SimulationKeypoint {
	public:
		SimulationKeypoint(double time);
		SimulationKeypoint();
		~SimulationKeypoint(void);

		void setTime(double time);
		void addVar(QString name, float value);
		QHash<QString, float> vars;
		double time;
		QString toString(void);

	private:
	};

	class SimulationObject {
	public:
//		SimulationObject(QString type, QString posVar, QString dirVar, SoSeparator *parent);
		SimulationObject(QString type, QString name, QString params, SoSeparator *parent);
		SimulationObject(SoSeparator *parent);
		~SimulationObject(void);

		QString getName();
		QString getPosVar();
		void setPosVar(QString val);
		QString getDirVar();
		void setDirVar(QString val);
		QString getType();
		void setType(QString val);
		SoSeparator* getParent();
		void setParent(SoSeparator *val);
		SbColor* parseColor(QString coldef);

		void setPosition(SbVec3f pos);
		void setRotationDir(SbRotation dir);
		void setScale(SbVec3f scale);
		void setOffset(SbVec3f offset);

		bool hasPosition;
		bool hasRotation;
		bool hasSize;
		bool hasOffset;

		SoTranslation *translation;
		SoRotation *rotation;
		SoScale *scale;
		SoTranslation *offset;

	private:
		QString name;
		QString type;
		QString posVar;
		QString dirVar;
		QString modelfilename;
		QString shape;

		SbColor *color;
		SoSeparator *objectGroup;
        SoSeparator *parent;
	};

	class SimulationData	{
	public:
		SimulationData(void);
		~SimulationData(void);

		void parse(QString filename);
		void clear(void);
		int size(void);
		float get_start_time(void);
		float get_end_time(void);
		void setFrame(float);
		SoSeparator *getSceneGraph() { return visroot_; }
		void addKeypoint(SimulationKeypoint *);
		void addObject(QString type, QString name, QString params);
		void viewAll(SbViewportRegion vpr);


	private:
		SoSeparator *visroot_;
		SoPerspectiveCamera *cam_;
		QList<SimulationKeypoint *> *keyPoints_;
		QList<SimulationObject> *objects_;
		float start_time;
		float end_time;
	};
}
