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
