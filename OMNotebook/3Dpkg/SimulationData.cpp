/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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


#include "SimulationData.h"
#include <iostream>

using namespace IAEX;
using namespace std;

namespace IAEX {
	// Implementation SimulationData
	SimulationData::SimulationData(void)
	{
		keyPoints_ = new QList<SimulationKeypoint *>();
		objects_ = new QList<SimulationObject>();
		visroot_ = new SoSeparator();

		cam_ = new SoPerspectiveCamera();
		cam_->position = SbVec3f(5,5,5);
		//visroot_->addChild(cam_);
		// temp
		//SimulationObject obj("cube", "obj", visroot_);
		//objects_->append(obj);
		//SimulationObject obj2("sphere", "obj2", visroot_);
		//objects_->append(obj2);
	}

	SimulationData::~SimulationData(void)
	{
	}

	void SimulationData::addObject(QString type, QString name, QString params) {
		SimulationObject obj(type, name, params, visroot_);
		objects_->append(obj);
	}

	void SimulationData::parse(QString filename) {
		//SimulationObject obj("sphere", "h", "", visroot_);
		//objects_->append(obj);

		//start_time = 0;
		//SimulationKeypoint point1(start_time);
		//point1.addVar("x", SbVec3f(0,0,0));
		//point1.addVar("rot", SbVec3f(0,1,0));
		//keyPoints_->append(point1);

		//SimulationKeypoint point2(2.5);
		//point2.addVar("x", SbVec3f(0,5,0));
		//point2.addVar("rot", SbVec3f(-0.2f,1,0.2f));
		//keyPoints_->append(point2);

		//end_time = 5;
		//SimulationKeypoint point3(end_time);
		//point3.addVar("x", SbVec3f(5,0,0));
		//point3.addVar("rot", SbVec3f(0.5,1,0.5));
		//keyPoints_->append(point3);
	}

	void SimulationData::clear() {
		//while (!keyPoints_->isEmpty()) {
		//	delete keyPoints_->takeFirst();
		//}
		keyPoints_->clear();
		objects_->clear();
		visroot_->removeAllChildren();

		SoSeparator *decoration = new SoSeparator();
		SoCube *hc = new SoCube();//5,0,5);
		SoScale *sc = new SoScale();//5,0,2.5);
		sc->scaleFactor.setValue(5, 0.001, 5);
		SoDrawStyle *style = new SoDrawStyle();
		style->style = SoDrawStyleElement::LINES;
		SoLightModel *lightm = new SoLightModel();
		lightm->model = SoLightModel::BASE_COLOR;

		decoration->addChild(style);
		decoration->addChild(lightm);
		decoration->addChild(sc);
		decoration->addChild(hc);

		visroot_->addChild(decoration);
	}

	int SimulationData::size(void) {
		return keyPoints_->size();
	}

	// time in ms
	float SimulationData::get_start_time(void) {
		if (keyPoints_->size() > 0) {
			return keyPoints_->at(0)->time;
		} else {
			return 0;
		}
	}

	float SimulationData::get_end_time(void) {
		if (keyPoints_->size() > 0) {
			return keyPoints_->back()->time;
		} else {
			return 0;
		}
	}

	void SimulationData::setFrame(float time) {
//		cout << "setFrame(" << time << ")" << endl;
		if (keyPoints_->size() < 2) {
			// not enough!
			return;
		}

		if (time > end_time) {
			return;
		}

		QList<SimulationKeypoint *>::iterator k;
		SimulationKeypoint *k1 = NULL;
		SimulationKeypoint *k2 = NULL;

		for (k = keyPoints_->begin(); k != keyPoints_->end(); k++) {
			float t = (*k)->time;
			if (t > time) {
				break;
			}
		}
		if (k == keyPoints_->end()) {
			k--;
		}

		k2 = *k;
		k--;
		k1 = *k;

		QList<QString> keylist = k1->vars.keys();
		QList<QString>::iterator t;
		//cout << "k1 keys: ";
		//for (t = keylist.begin(); t != keylist.end(); t++) {
		//	cout << (*t).toStdString() << "=" << k1->vars.value(*t) << endl;
		//}
		//cout << endl;

		//keylist = k2->vars.keys();
		//cout << "k2 keys: ";
		//for (t = keylist.begin(); t != keylist.end(); t++) {
		//	cout << (*t).toStdString() << "=" << k2->vars.value(*t) << endl;
		//}
		//cout << endl;

		QList<SimulationObject>::iterator i;
		for (i = objects_->begin(); i != objects_->end(); i++) {
			QString name = (*i).getName();
			//cout << name.toStdString() << ",";

			//QString pos = (*i).getPosVar();
			//QString rot = (*i).getDirVar();
			//QString type = (*i).getType();

			if ((*i).hasPosition) {
				SbVec3f p1;
				p1[0] = k1->vars.value(name + ".frame_a[1]");
				p1[1] = k1->vars.value(name + ".frame_a[2]");
				p1[2] = k1->vars.value(name + ".frame_a[3]");
				SbVec3f p2;
				p2[0] = k2->vars.value(name + ".frame_a[1]");
				p2[1] = k2->vars.value(name + ".frame_a[2]");
				p2[2] = k2->vars.value(name + ".frame_a[3]");
				SbVec3f p = p2 - p1;
				p = p1 + p * (float)(time - k1->time)/(float)(k2->time - k1->time);

				(*i).setPosition(p);
			}

			if ((*i).hasRotation) {
				SbVec3f r1;
				r1[0] = k1->vars.value(name + ".frame_b[1]");
				r1[1] = k1->vars.value(name + ".frame_b[2]");
				r1[2] = k1->vars.value(name + ".frame_b[3]");
				SbVec3f r2;
				r2[0] = k2->vars.value(name + ".frame_b[1]");
				r2[1] = k2->vars.value(name + ".frame_b[2]");
				r2[2] = k2->vars.value(name + ".frame_b[3]");
				float t = (float)(time - k1->time)/(float)(k2->time - k1->time);

				//SbRotation rot1 = SbRotation(SbVec3f(0,1,0), r1 - (*i).translation->translation.getValue());
				//SbRotation rot2 = SbRotation(SbVec3f(0,1,0), r2 - (*i).translation->translation.getValue());

				//SbRotation rot = SbRotation::slerp(rot1, rot2, t);
				SbVec3f r = r2 - r1;
				r = r1 + r * t;
				SbRotation rot = SbRotation(SbVec3f(0,1,0), r - (*i).translation->translation.getValue());

				(*i).setRotationDir(rot);
			}

			if ((*i).hasSize) {
				SbVec3f s1;
				s1[0] = k1->vars.value(name + ".size[1]");
				s1[1] = k1->vars.value(name + ".size[2]");
				s1[2] = k1->vars.value(name + ".size[3]");
				SbVec3f s2;
				s2[0] = k2->vars.value(name + ".size[1]");
				s2[1] = k2->vars.value(name + ".size[2]");
				s2[2] = k2->vars.value(name + ".size[3]");
				SbVec3f s = s2 - s1;
				s = s1 + s * (float)(time - k1->time)/(float)(k2->time - k1->time);

				(*i).setScale(s);
			}

			if ((*i).hasOffset) {
				SbVec3f o1;
				o1[0] = k1->vars.value(name + ".offset[1]");
				o1[1] = k1->vars.value(name + ".offset[2]");
				o1[2] = k1->vars.value(name + ".offset[3]");
				SbVec3f o2;
				o2[0] = k2->vars.value(name + ".offset[1]");
				o2[1] = k2->vars.value(name + ".offset[2]");
				o2[2] = k2->vars.value(name + ".offset[3]");
				SbVec3f o = o2 - o1;
				o = o1 + o * (float)(time - k1->time)/(float)(k2->time - k1->time);

				(*i).setOffset(o);
			}
				/*			if (rot != "") {
				SbVec3f r1 = k1->vars.value(rot);
				SbVec3f r2 = k2->vars.value(rot);
				if (r1.length() == 0) {
					r1.setValue(0,1,0);
				}
				if (r2.length() == 0) {
					r2.setValue(0,1,0);
				}

				SbVec3f r = r2 - r1;
				r = r1 + r * (time - k1->time)/(k2->time - k1->time);
				//cout << r[0] << " " << r[1] << " " << r[2] << endl;

				(*i).setRotationDir(r);
			}*/
		}
		//cout << endl;
	}

	void SimulationData::addKeypoint(SimulationKeypoint *point) {
		//QString tmp = point->toString();
		//cout << tmp.toStdString() << endl;
		keyPoints_->append(point);
		start_time = keyPoints_->at(0)->time;
		end_time = keyPoints_->back()->time;
		//cout << "size: " << keyPoints_->size() << endl;
	}

	void SimulationData::viewAll(SbViewportRegion vpr) {
		cam_->viewAll(visroot_, vpr, 1.0);
	}

	// Implementation SimulationKeypoint
	SimulationKeypoint::SimulationKeypoint(double time)  {
		this->time = time;
	}

	SimulationKeypoint::SimulationKeypoint()  {
		this->time = 0;
	}

	SimulationKeypoint::~SimulationKeypoint()  {
	}

	void SimulationKeypoint::addVar(QString name, float value) {
		//cout << "addVar(" << name.toStdString() << ")=" << value << endl;
		vars.insert(name, value);
	}

	void SimulationKeypoint::setTime(double time) {
		this->time = time;
	}

	QString SimulationKeypoint::toString(void) {
		QString tmp = "";

		tmp = QString("Time: %1\n").arg(this->time);
		tmp += "Vars:\n";

		QHashIterator<QString, float> i(vars);
		while (i.hasNext()) {
			i.next();
			tmp += QString("\"%1\" : %2\n").arg(i.key()).arg(i.value());
		}

		return tmp;
	}

	// Implementation SimulationObject
	SimulationObject::SimulationObject(QString type, QString name, QString params, SoSeparator *parent) {
		this->type = type;
		this->name = name;
		this->parent = parent;

		hasPosition = hasSize = hasOffset = hasRotation = false;

		QString rest = params;
		int pos;
		color = new SbColor(0.6f, 0.6f, 0.6f);

		while ((pos = rest.indexOf(";")) > 0) {
			QString pair = rest.left(pos);
			QString p = pair.left(pair.indexOf("="));
			QString v = pair.mid(pair.indexOf("=")+1);

			if (p == "color") {
				this->color = parseColor(v);
			} else if (p == "model") {
				this->modelfilename = v;
			} else if (p == "shape") {
				this->shape = v;
			}

			rest = rest.mid(pos+1);
		}

		objectGroup = new SoSeparator();

		if (type == "SimpleVisual.PositionRotation") {
			hasPosition = true;
			hasRotation = true;
		} else if (type == "SimpleVisual.PositionSize") {
			hasPosition = true;
			hasSize = true;
		} else if (type == "SimpleVisual.PositionRotationSize") {
			hasSize = true;
			hasPosition = true;
			hasRotation = true;
		} else if (type == "SimpleVisual.PositionRotationSizeOffset") {
			hasSize = true;
			hasPosition = true;
			hasRotation = true;
			hasOffset = true;
		} else { //	type == "SimpleVisual.Position" or unknown
			hasPosition = true;
		}

		SoBaseColor *col = new SoBaseColor();
		col->rgb = *color;
		objectGroup->addChild(col);

		if (hasPosition) {
			translation = new SoTranslation();
			objectGroup->addChild(translation);
		}

		if (hasRotation) {
			rotation = new SoRotation();
			objectGroup->addChild(rotation);
		}

		if (hasOffset) {
			offset = new SoTranslation();
			objectGroup->addChild(offset);
		}

		if (hasSize) {
			scale = new SoScale();
			objectGroup->addChild(scale);
		}

		if (!modelfilename.isEmpty()) {
			SoInput in;
			if (in.openFile(modelfilename.toStdString().c_str())) {
				SoSeparator *model = SoDB::readAll(&in);
		        if (model) {
					objectGroup->addChild(model);
				}
			}
		} else if (shape == "cube") {
			SoCube *cube = new SoCube();
			cube->width = 1;
			cube->height = 1;
			cube->depth = 1;
			objectGroup->addChild(cube);
		} else if (shape == "cylinder") {
			SoCylinder *cylinder = new SoCylinder();
			cylinder->radius = 1;
			cylinder->height = 1;
			objectGroup->addChild(cylinder);
		} else { // eg sphere or unknown
			SoSphere *sphere = new SoSphere();
			sphere->radius = 0.5;
			objectGroup->addChild(sphere);
		}
		//if (type == "SimpleVisual.Cube") {
		//	SoCube *cube = new SoCube();
		//	cube->width = 1;
		//	cube->height = 1;
		//	cube->depth = 1;
		//	objectGroup->addChild(cube);
		//} else if (type == "SimpleVisual.Sphere") {
		//	SoSphere *sphere = new SoSphere();
		//	sphere->radius = 1;
		//	objectGroup->addChild(new SoSphere());
		//} else
		//	objectGroup->addChild(new SoSphere());

		parent->addChild(objectGroup);
	}

	SbColor* SimulationObject::parseColor(QString coldef) {
		if (coldef == "red")
			return new SbColor(1.0f, 0.0f, 0.0f);
		else if (coldef == "green")
			return new SbColor(0.0f, 1.0f, 0.0f);
		else if (coldef == "blue")
			return new SbColor(0.0f, 0.0f, 1.0f);
		else
			return new SbColor(0.6f, 0.6f, 0.6f);
	}
/*	SimulationObject::SimulationObject(QString type, QString posVar, QString dirVar, SoSeparator *parent) {
		this->type = type;
		this->posVar = posVar;
		this->dirVar = dirVar;
		this->parent = parent;

		objectGroup = new SoSeparator();
		translation = new SoTranslation();
		rotation = new SoRotation();
		objectGroup->addChild(translation);
		objectGroup->addChild(rotation);

		if (type == "cube") {
			objectGroup->addChild(new SoCube());
		} else if (type == "sphere") {
			objectGroup->addChild(new SoCube());
		}

		parent->addChild(objectGroup);
	}*/

	SimulationObject::~SimulationObject() {
	}

	void SimulationObject::setPosition(SbVec3f pos) {
//		cout << "setpos(" << pos[0] << "," << pos[1] << "," << pos[2] << ")" << endl;
		translation->translation.setValue(pos);
	}

	void SimulationObject::setOffset(SbVec3f pos) {
//		cout << "setpos(" << pos[0] << "," << pos[1] << "," << pos[2] << ")" << endl;
		offset->translation.setValue(pos);
	}

	void SimulationObject::setRotationDir(SbRotation dir) {
		//if (dir.length() > 0.01)
		rotation->rotation.setValue(dir);//SbRotation(SbVec3f(0,1,0), dir - translation->translation.getValue()));
	}

	void SimulationObject::setScale(SbVec3f s) {
		//if (0 == s[0] == s[1] == s[2]) {
		//	//sanity check
		//	scale->scaleFactor.setValue(1, 1, 1);
		//} else {
			scale->scaleFactor.setValue(s[0], s[1], s[2]);
		//}
	}

	QString SimulationObject::getPosVar() {
		return posVar;
	}
	QString SimulationObject::getName() {
		return name;
	}
	void SimulationObject::setPosVar(QString val) {
		posVar = val;
	}

	QString SimulationObject::getDirVar() {
		return dirVar;
	}
	void SimulationObject::setDirVar(QString val) {
		dirVar = val;
	}

	QString SimulationObject::getType() {
		return type;
	}
	void SimulationObject::setType(QString val) {
		type = val;
	}

	SoSeparator* SimulationObject::getParent() {
		return parent;
	}
	void SimulationObject::setParent(SoSeparator *val) {
		parent = val;
	}

}






	//void SimulationData::traverse(QDomNode frame, SoSeparator *parent) {
	//	QDomNode n = frame; //->firstChild();

	//	//		while(!n.isNull()) {
	//	if (!n.isNull()) {
	//		QDomElement e = n.toElement();
	//		if(!e.isNull()) {
	//			//cout << e.tagName().toStdString() << " "
	//			//	<< e.attribute("name").toStdString() << endl;

	//			//if (e.tagName() == "node") {
	//			//	SoSeparator *tmp = new SoSeparator();
	//			//	parent->addChild(tmp);
	//			//	traverse(&n, tmp);
	//			//} else
	//			if (e.tagName() == "object") {
	//				SoSeparator *group = new SoSeparator();
	//				QDomNode obj = n.firstChild();
	//				while (!obj.isNull()) {
	//					QDomElement obj_element = obj.toElement();
	//					if (!obj_element.isNull()) {
	//						if (obj_element.tagName() == "translation") {
	//							float x,y,z = 0.0f;
	//							QString str;
	//							str = obj_element.attribute("x");
	//							x = str.toFloat();
	//							str = obj_element.attribute("y");
	//							y = str.toFloat();
	//							str = obj_element.attribute("z");
	//							z = str.toFloat();

	//							SoTranslation *transl = new SoTranslation();
	//							transl->translation.setValue(x, y, z);
	//							group->addChild(transl);
	//						} else if (obj_element.tagName() == "rotation") {
	//							float x,y,z,angle = 0.0f;
	//							QString str;
	//							str = obj_element.attribute("x");
	//							x = str.toFloat();
	//							str = obj_element.attribute("y");
	//							y = str.toFloat();
	//							str = obj_element.attribute("z");
	//							z = str.toFloat();
	//							str = obj_element.attribute("angle");
	//							angle = str.toFloat();

	//							SoRotation *rot = new SoRotation();
	//							rot->rotation.setValue(SbVec3f(x, y, z), angle);
	//							group->addChild(rot);
	//						} else if (obj_element.tagName() == "scale") {
	//							float x,y,z = 0.0f;
	//							QString str;
	//							str = obj_element.attribute("x");
	//							x = str.toFloat();
	//							str = obj_element.attribute("y");
	//							y = str.toFloat();
	//							str = obj_element.attribute("z");
	//							z = str.toFloat();

	//							SoScale *scale = new SoScale();
	//							scale->scaleFactor.setValue(x, y, z);
	//							group->addChild(scale);
	//						} else if (obj_element.tagName() == "color") {
	//							float r,g,b = 0.0f;
	//							QString str;
	//							str = obj_element.attribute("r");
	//							r = str.toFloat();
	//							str = obj_element.attribute("g");
	//							g = str.toFloat();
	//							str = obj_element.attribute("b");
	//							b = str.toFloat();

	//							SoBaseColor *col = new SoBaseColor();
	//							col->rgb = SbColor(r, g, b);
	//							group->addChild(col);
	//						} else if (obj_element.tagName() == "object") {
	//							traverse(obj, group);
	//						}
	//					}
	//					obj = obj.nextSibling();
	//				}

	//				QString name = e.attribute("name");

	//				if (!name.isNull()) {
	//					SoMFString str;
	//					str.setValue(name.toStdString().data());

	//					SoAnnotation *annotation = new SoAnnotation;
	//					SoFont *font = new SoFont;
	//					SoText2 *text = new SoText2;
	//					SoBaseColor *col = new SoBaseColor;
	//					col->rgb = SbColor(1.0f, 1.0f, 1.0f);

	//					text->string = str;
	//					font->name = "Arial:bold";
	//					font->size = 14;
	//					annotation->addChild(col);
	//					annotation->addChild(font);
	//					annotation->addChild(text);
	//					group->addChild(annotation);
	//				}

	//				QString style = e.attribute("primitive");
	//				QString meshfile = e.attribute("mesh");
	//				if (!meshfile.isNull()) {

	//				}
	//				else if (style == "cube") {
	//					SoCube *cube = new SoCube();
	//					group->addChild(cube);
	//				} else if (style == "cone") {
	//					SoCone *cone = new SoCone();
	//					group->addChild(cone);
	//				} else if (style == "cylinder") {
	//					SoCylinder *cylinder = new SoCylinder();
	//					group->addChild(cylinder);
	//				} else if (style == "sphere") {
	//					SoSphere *sphere = new SoSphere();
	//					group->addChild(sphere);
	//				}

	//				parent->addChild(group);
	//			}
	//		}
	//		//			n = n.nextSibling();
	//	}
	//}
