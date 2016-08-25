/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#include "Visualizer.h"


OMVisualBase::OMVisualBase(const std::string& modelFile, const std::string& path)
		: _modelFile(modelFile),
		  _path(path),
		  _shapes(),
		  _xmlFileName(assembleXMLFileName(modelFile, path)),
		  _xmlDoc()

{
}

void OMVisualBase::initXMLDoc()
{
	// Check if the XML file is available.
	if (!fileExists(_xmlFileName))
	{
		std::string msg = "Could not find the visual XML file" + _xmlFileName + ".";
		std::cout<<msg<<std::endl;
	}
		// read xml
		osgDB::ifstream t;
		// unused const char * titel = _xmlFileName.c_str();
		t.open(_xmlFileName.c_str(), std::ios::binary);      // open input file
		t.seekg(0, std::ios::end);    // go to the end
		int length = t.tellg();       // report location (this is the length)
		t.seekg(0, std::ios::beg);    // go back to the beginning
		char* buffer = new char[length];    // allocate memory for a buffer of appropriate dimension
		t.read(buffer, length);       // read the whole file into the buffer
		t.close();
		std::string buff = std::string(buffer);  // strings are good
		std::string buff2 = buff.substr(0, buff.find("</visualization>"));  // remove the crappy ending
		buff2.append("</visualization>");
		char* buff3 = strdup(buff2.c_str());  // cast to char*
		_xmlDoc.parse<0>(buff3);
		std::cout<<"laoded XML"<<std::endl;

}

void OMVisualBase::initVisObjects()
{
	rapidxml::xml_node<>* rootNode = _xmlDoc.first_node();
	ShapeObject shape;
	rapidxml::xml_node<>* expNode;

	//Begin std::vector<T>::reserve()
	//int i = 0;
	//for (rapidxml::xml_node<>* shapeNode = rootNode->first_node("shape"); shapeNode; shapeNode = shapeNode->next_sibling())
	//    ++i;
	//LOGGER_WRITE(std::string("============Number of iterations1 ") + std::to_string(i), LC_LOADER, LL_DEBUG);
	//_shapes.reserve(i);
	// End std::vector<T>::reserve()

	for (rapidxml::xml_node<>* shapeNode = rootNode->first_node("shape"); shapeNode; shapeNode = shapeNode->next_sibling())
	{
		expNode = shapeNode->first_node((const char*) "ident")->first_node();
		shape._id = std::string(expNode->value());

		expNode = shapeNode->first_node((const char*) "type")->first_node();

		if (expNode == 0)
		{
			std::cout<<"The type of  "<<shape._id<<" is not supported right in the visxml file."<<std::endl;
		}
		else
		{
			//std::cout<<"shape._id "<<shape._id;

			shape._type = std::string(expNode->value());

			expNode = shapeNode->first_node((const char*) "length")->first_node();
			shape._length = getObjectAttributeForNode(expNode);
			expNode = shapeNode->first_node((const char*) "width")->first_node();
			shape._width = getObjectAttributeForNode(expNode);
			expNode = shapeNode->first_node((const char*) "height")->first_node();
			shape._height = getObjectAttributeForNode(expNode);

			expNode = shapeNode->first_node((const char*) "lengthDir")->first_node();
			shape._lDir[0] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._lDir[1] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._lDir[2] = getObjectAttributeForNode(expNode);

			expNode = shapeNode->first_node((const char*) "widthDir")->first_node();
			shape._wDir[0] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._wDir[1] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._wDir[2] = getObjectAttributeForNode(expNode);

			expNode = shapeNode->first_node((const char*) "r")->first_node();
			shape._r[0] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._r[1] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._r[2] = getObjectAttributeForNode(expNode);

			expNode = shapeNode->first_node((const char*) "r_shape")->first_node();
			shape._rShape[0] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._rShape[1] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._rShape[2] = getObjectAttributeForNode(expNode);

			expNode = shapeNode->first_node((const char*) "color")->first_node();
			shape._color[0] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._color[1] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._color[2] = getObjectAttributeForNode(expNode);

			expNode = shapeNode->first_node((const char*) "T")->first_node();
			shape._T[0] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._T[1] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._T[2] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._T[3] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._T[4] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._T[5] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._T[6] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._T[7] = getObjectAttributeForNode(expNode);
			expNode = expNode->next_sibling();
			shape._T[8] = getObjectAttributeForNode(expNode);

			expNode = shapeNode->first_node((const char*) "specCoeff")->first_node();
			shape._specCoeff = getObjectAttributeForNode(expNode);

			_shapes.push_back(shape);
			std::cout<<" done"<<std::endl;
		}
	} // end for-loop
}

void OMVisualBase::clearXMLDoc()
{
	_xmlDoc.clear();
}

rapidxml::xml_node<>* OMVisualBase::getFirstXMLNode() const
{
	return _xmlDoc.first_node();
}

const std::string OMVisualBase::getModelFile() const
{
	return _modelFile;
}

const std::string OMVisualBase::getPath() const
{
	return _path;
}

const std::string OMVisualBase::getXMLFileName() const
{
	return _xmlFileName;
}

void OMVisualBase::appendVisVariable(const rapidxml::xml_node<>* node, std::vector<std::string>& visVariables) const
{
	if (strcmp("cref", node->name()) == 0)
	{
		char* cref = node->value();
		visVariables.push_back(std::string(cref));
	}
}


///--------------------------------------------------///
///ABSTRACT VISUALIZER CLASS-------------------------///
///--------------------------------------------------///

VisualizerAbstract::VisualizerAbstract()
		: _visType(VisType::NONE),
		  _baseData(nullptr),
		  _viewerStuff(nullptr),
		  _nodeUpdater(nullptr),
		  _timeManager(nullptr)
{
}

VisualizerAbstract::VisualizerAbstract(const std::string& modelFile, const std::string& path, const VisType visType)
		: _visType(visType),
		  _baseData(nullptr),
		  _viewerStuff(new OMVisScene()),
		  _nodeUpdater(new UpdateVisitor()),
		  _timeManager(new TimeManager(0.0, 0.0, 0.0, 0.0, 0.1, 0.0, 100.0))
{
	_baseData = new OMVisualBase(modelFile, path);
	_viewerStuff->getScene().setPath(path);
	std::cout<<"INITED VisualizerAbstract"<<std::endl;
}

void VisualizerAbstract::initData()
{
	std::cout<<"initData 1"<<std::endl;

    // In case of reloading, we need to make sure, that we have empty members.
    _baseData->clearXMLDoc();
	std::cout<<"initData 2"<<std::endl;

    // Initialize XML file and get visAttributes.
    _baseData->initXMLDoc();
	std::cout<<"initData 3"<<std::endl;

    _baseData->initVisObjects();
	std::cout<<"initData 4"<<std::endl;
}

void VisualizerAbstract::initVisualization()
{
    std::cout<<"Initialize visualization."<<std::endl;
    initializeVisAttributes(_timeManager->getStartTime());
    _timeManager->setVisTime(_timeManager->getStartTime());
    _timeManager->setRealTimeFactor(0.0);
    _timeManager->setPause(true);
}

TimeManager* VisualizerAbstract::getTimeManager() const
{
    return _timeManager;
}

void VisualizerAbstract::sceneUpdate()
{
    _timeManager->updateTick();

    if (!_timeManager->isPaused())
    {
        updateScene(_timeManager->getVisTime());
        _timeManager->setVisTime(_timeManager->getVisTime() + _timeManager->getHVisual());
        if (_timeManager->getVisTime() >= _timeManager->getEndTime() - 1.e-6)
        {
            _timeManager->setPause(true);
        }
    }
}

void VisualizerAbstract::setUpScene()
{
    // Build scene graph.
    _viewerStuff->getScene().setUpScene(_baseData->_shapes);
}

VisType VisualizerAbstract::getVisType() const
{
    return _visType;
}

OMVisualBase* VisualizerAbstract::getBaseData() const
{
    return _baseData;
}



OMVisScene* VisualizerAbstract::getOMVisScene() const
{
    return _viewerStuff;
}

std::string VisualizerAbstract::getModelFile() const
{
    return _baseData->getModelFile();
}

void VisualizerAbstract::startVisualization()
{
    if (_timeManager->getVisTime() < _timeManager->getEndTime() - 1.e-6)
    {
        _timeManager->setPause(false);
    }
    else
        std::cout<<"There is nothing left to visualize. Initialize the model first."<<std::endl;
}

void VisualizerAbstract::pauseVisualization()
{
    _timeManager->setPause(true);
}


///--------------------------------------------------///
///MAT VISUALIZER CLASS------------------------------///
///--------------------------------------------------///


VisualizerMAT::VisualizerMAT(const std::string& modelFile, const std::string& path)
        : VisualizerAbstract(modelFile, path, VisType::MAT),
          _matReader()
{
}

void VisualizerMAT::initData()
{
    VisualizerAbstract::initData();
    readMat(_baseData->getModelFile(), _baseData->getPath());
    _timeManager->setStartTime(omc_matlab4_startTime(&_matReader));
    _timeManager->setEndTime(omc_matlab4_stopTime(&_matReader));
}

void VisualizerMAT::initializeVisAttributes(const double time)
{
    if (0.0 > time)
        std::cout<<"Cannot load visualization attributes for time point < 0.0."<<std::endl;
    updateVisAttributes(time);
}

void VisualizerMAT::readMat(const std::string& modelFile, const std::string& path)
{
    std::string resFileName = path + modelFile;     // + "_res.mat";

    // Check if the MAT file exists.
    if (!fileExists(resFileName))
    {
        std::string msg = "Could not find MAT file" + resFileName + ".";
        std::cout<<msg<<std::endl;
    }
    else
    {
        // Read mat file.
        auto ret = omc_new_matlab4_reader(resFileName.c_str(), &_matReader);
        // Check return value.
        if (0 != ret)
        {
            std::string msg(ret);
            std::cout<<msg<<std::endl;
        }
    }

    /*
     FILE * fileA = fopen("allVArs.txt", "w+");
     omc_matlab4_print_all_vars(fileA, &matReader);
     fclose(fileA);
     */
}

void VisualizerMAT::updateVisAttributes(const double time)
{
	std::cout<<"updateVisAttributes at "<<time <<std::endl;
    // Update all shapes.
    unsigned int shapeIdx = 0;
    rAndT rT;
    osg::ref_ptr<osg::Node> child = nullptr;
    ModelicaMatReader* tmpReaderPtr = &_matReader;
    try
    {
    	std::cout<<"try at "<<time <<std::endl;

        for (auto& shape : _baseData->_shapes)
        {
        	//std::cout<<"shape "<<shape._id <<std::endl;

            // Get the values for the scene graph objects
            updateObjectAttributeMAT(&shape._length, time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._width, time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._height, time, tmpReaderPtr);

            updateObjectAttributeMAT(&shape._lDir[0], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._lDir[1], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._lDir[2], time, tmpReaderPtr);

            updateObjectAttributeMAT(&shape._wDir[0], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._wDir[1], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._wDir[2], time, tmpReaderPtr);

            updateObjectAttributeMAT(&shape._r[0], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._r[1], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._r[2], time, tmpReaderPtr);

            updateObjectAttributeMAT(&shape._rShape[0], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._rShape[1], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._rShape[2], time, tmpReaderPtr);

            updateObjectAttributeMAT(&shape._T[0], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._T[1], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._T[2], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._T[3], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._T[4], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._T[5], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._T[6], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._T[7], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._T[8], time, tmpReaderPtr);

            updateObjectAttributeMAT(&shape._color[0], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._color[1], time, tmpReaderPtr);
            updateObjectAttributeMAT(&shape._color[2], time, tmpReaderPtr);

            updateObjectAttributeMAT(&shape._specCoeff, time, tmpReaderPtr);

            rT = rotateModelica2OSG(osg::Vec3f(shape._r[0].exp, shape._r[1].exp, shape._r[2].exp),
                                osg::Vec3f(shape._rShape[0].exp, shape._rShape[1].exp, shape._rShape[2].exp),
                                osg::Matrix3(shape._T[0].exp, shape._T[1].exp, shape._T[2].exp,
                                             shape._T[3].exp, shape._T[4].exp, shape._T[5].exp,
                                             shape._T[6].exp, shape._T[7].exp, shape._T[8].exp),
                                osg::Vec3f(shape._lDir[0].exp, shape._lDir[1].exp, shape._lDir[2].exp),
                                osg::Vec3f(shape._wDir[0].exp, shape._wDir[1].exp, shape._wDir[2].exp),
                                shape._length.exp, shape._width.exp, shape._height.exp, shape._type);

            assemblePokeMatrix(shape._mat, rT._T, rT._r);
            // Update the shapes.
            _nodeUpdater->_shape = shape;
            //shape.dumpVisAttributes();
            // Get the scene graph nodes and stuff.
            child = _viewerStuff->getScene().getRootNode()->getChild(shapeIdx);  // the transformation
            child->accept(*_nodeUpdater);
            ++shapeIdx;
        }
    }
    catch (std::exception& ex)
    {
        std::string msg = "Error in VisualizerMAT::updateVisAttributes at time point " + std::to_string(time)
                          + "\n" + std::string(ex.what());
        throw(msg);
    }
}

void VisualizerMAT::updateScene(const double time)
{
    if (0.0 > time)

    _timeManager->updateTick();  //for real-time measurement
    double visTime = _timeManager->getRealTime();

    updateVisAttributes(time);

    _timeManager->updateTick();  //for real-time measurement
    visTime = _timeManager->getRealTime() - visTime;
    _timeManager->setRealTimeFactor(_timeManager->getHVisual() / visTime);
}

void VisualizerMAT::updateObjectAttributeMAT(ShapeObjectAttribute* attr, double time, ModelicaMatReader* reader)
{
    if (!attr->isConst)
        attr->exp = omcGetVarValue(reader, attr->cref.c_str(), time);
}

double VisualizerMAT::omcGetVarValue(ModelicaMatReader* reader, const char* varName, double time)
{
    double val = 0.0;
    ModelicaMatVariable_t* var = nullptr;
    var = omc_matlab4_find_var(reader, varName);
    if (var == nullptr)
        std::cout<<"Did not get variable from result file. Variable name is "<<std::string(varName)<<std::endl;
    else
        omc_matlab4_val(&val, reader, var, time);

    return val;
}

void VisualizerMAT::setSimulationSettings(const UserSimSettingsMAT& simSetMAT)
{
    auto newVal = simSetMAT.speedup * _timeManager->getHVisual();
    _timeManager->setHVisual(newVal);
}


OMVisScene::OMVisScene()
        : _scene()
{
}

void OMVisScene::dumpOSGTreeDebug()
{
    // The node traverser which dumps the tree
    InfoVisitor infoVisitor;
    _scene.getRootNode()->accept(infoVisitor);
}

OSGScene& OMVisScene::getScene()
{
    return _scene;
}


OSGScene::OSGScene()
        : _rootNode(new osg::Group()),
          _path("")
{
}

int OSGScene::setUpScene(std::vector<ShapeObject> allShapes)
{
	std::cout<<"SETUPSCENE"<<std::endl;
    int isOk(0);
	for (std::vector<ShapeObject>::size_type i = 0; i != allShapes.size(); i++)
    {

		ShapeObject shape = allShapes[i];

		osg::ref_ptr<osg::Geode> geode;
		osg::ref_ptr<osg::StateSet> ss;

        std::string type = shape._type;

		//color
		osg::ref_ptr<osg::Material> material = new osg::Material();
		material->setDiffuse(osg::Material::FRONT, osg::Vec4f(0.0, 0.0, 0.0, 0.0));

		//matrix transformation
		osg::ref_ptr<osg::MatrixTransform> transf = new osg::MatrixTransform();

		//stl node
		if (isCADType(type))
		{

			std::string filename = extractCADFilename(type);
			filename = _path + filename;

			std::cout<<"Its a STL and the filename is "<<filename<<std::endl;
			// \todo What do we do at this point?
			if (!fileExists(filename))
			{
				std::cout<<"Could not find the file "<< filename<<std::endl;
				isOk = 1;
				return isOk;
            }

            osg::ref_ptr<osg::Node> node = osgDB::readNodeFile(filename);
            osg::ref_ptr<osg::StateSet> ss = node->getOrCreateStateSet();

            ss->setAttribute(material.get());
            node->setStateSet(ss);
            transf->addChild(node.get());
        }
        //geode with shape drawable
        else
        {
            osg::ref_ptr<osg::ShapeDrawable> shapeDraw = new osg::ShapeDrawable();
            shapeDraw->setColor(osg::Vec4(1.0, 1.0, 1.0, 1.0));
            geode = new osg::Geode();
            geode->addDrawable(shapeDraw.get());
            osg::ref_ptr<osg::StateSet> ss = geode->getOrCreateStateSet();
            ss->setAttribute(material.get());
            geode->setStateSet(ss);
            transf->addChild(geode.get());
        }

        _rootNode->addChild(transf.get());

    }

    return isOk;
}

osg::ref_ptr<osg::Group> OSGScene::getRootNode()
{
    return _rootNode;
}

std::string OSGScene::getPath() const
{
    return _path;
}

void OSGScene::setPath(const std::string path)
{
    _path = path;
}


UpdateVisitor::UpdateVisitor()
        : _shape()
{
    setTraversalMode(NodeVisitor::TRAVERSE_ALL_CHILDREN);
}

/**
 MatrixTransform
 */
void UpdateVisitor::apply(osg::MatrixTransform& node)
{
    //std::cout<<"MT "<<node.className()<<"  "<<node.getName()<<std::endl;
    node.setMatrix(_shape._mat);
    traverse(node);
}

/**
 Geode
 */
void UpdateVisitor::apply(osg::Geode& node)
{
    //std::cout<<"GEODE "<< _shape._id<<" "<<std::endl;
    osg::ref_ptr<osg::StateSet> ss = node.getOrCreateStateSet();

    //its a stl-file
    if (isCADType(_shape._type))
    {
        std::string filename = extractCADFilename(_shape._type);
        osg::ref_ptr<osg::Node> node = osgDB::readNodeFile(filename);

    }
    //its a drawable
    else
    {
        osg::ref_ptr<osg::Drawable> draw = node.getDrawable(0);
        draw->dirtyDisplayList();
        //osg::ref_ptr<osg::ShapeDrawable> shapeDraw = dynamic_cast<osg::ShapeDrawable*>(draw.get());
        //shapeDraw->setColor(osg::Vec4(visAttr.color,1.0));

        if (_shape._type == "pipecylinder")
            draw->setShape(new osg::Cylinder(osg::Vec3f(0.0, 0.0, 0.0), _shape._width.exp / 2.0, _shape._length.exp));
        else if (_shape._type == "cylinder")
            draw->setShape(new osg::Cylinder(osg::Vec3f(0.0, 0.0, 0.0), _shape._width.exp / 2.0, _shape._length.exp));
        else if (_shape._type == "box")
            draw->setShape(new osg::Box(osg::Vec3f(0.0, 0.0, 0.0), _shape._width.exp, _shape._height.exp, _shape._length.exp));
        else if (_shape._type == "cone")
            draw->setShape(new osg::Cone(osg::Vec3f(0.0, 0.0, 0.0), _shape._width.exp / 2.0, _shape._length.exp));
        else if (_shape._type == "sphere")
            draw->setShape(new osg::Sphere(osg::Vec3f(0.0, 0.0, 0.0), _shape._length.exp / 2.0));
        else
        {
            std::cout<<"Unknown type, we make a capsule."<<std::endl;
            //string id = string(visAttr.type.begin(), visAttr.type.begin()+11);
            draw->setShape(new osg::Capsule(osg::Vec3f(0.0, 0.0, 0.0), 0.1, 0.5));
        }
        //std::cout<<"SHAPE "<<draw->getShape()->className()<<std::endl;
        node.addDrawable(draw.get());
    }
    //osg::Material *material = dynamic_cast<osg::Material*>(ss->getAttribute(osg::StateAttribute::MATERIAL));
    osg::ref_ptr<osg::Material> material = new osg::Material;
    material->setDiffuse(osg::Material::FRONT, osg::Vec4f(_shape._color[0].exp / 255, _shape._color[1].exp / 255, _shape._color[2].exp / 255, 1.0));
    ss->setAttribute(material);
    node.setStateSet(ss);
    traverse(node);
}

InfoVisitor::InfoVisitor()
		: _level(0)
{
	setTraversalMode(NodeVisitor::TRAVERSE_ALL_CHILDREN);
}

std::string InfoVisitor::spaces()
{
	return std::string(_level * 2, ' ');
}

void InfoVisitor::apply(osg::Node& node)
{
	std::cout << spaces() << node.libraryName() << "::" << node.className() << std::endl;
	++_level;
	traverse(node);
	--_level;
}

void InfoVisitor::apply(osg::Geode& geode)
{
	std::cout << spaces() << geode.libraryName() << "::" << geode.className() << std::endl;
	++_level;
	for (size_t i = 0; i < geode.getNumDrawables(); ++i)
	{
		osg::Drawable* drawable = geode.getDrawable(i);
		std::cout << spaces() << drawable->libraryName() << "::" << drawable->className() << std::endl;
	}
	traverse(geode);
	--_level;
}


osg::Vec3f Mat3mulV3(osg::Matrix3 M, osg::Vec3f V)
{
	return osg::Vec3f(M[0] * V[0] + M[1] * V[1] + M[2] * V[2], M[3] * V[0] + M[4] * V[1] + M[5] * V[2], M[6] * V[0] + M[7] * V[1] + M[8] * V[2]);
}

osg::Vec3f V3mulMat3(osg::Vec3f V, osg::Matrix3 M)
{
	return osg::Vec3f(M[0] * V[0] + M[3] * V[1] + M[6] * V[2], M[1] * V[0] + M[4] * V[1] + M[7] * V[2], M[2] * V[0] + M[5] * V[1] + M[8] * V[2]);
}

osg::Matrix3 Mat3mulMat3(osg::Matrix3 M1, osg::Matrix3 M2)
{
	osg::Matrix3 M3;
	for (int i = 0; i < 3; ++i)
	{
		for (int j = 0; j < 3; ++j)
		{
			//cout<<" i and j "<<i<<" "<<j<<endl;
			float x = 0.0;
			for (int k = 0; k < 3; ++k)
			{
				//cout<<M1[i*3+k]<<" * "<<M2[k*3+j]<<" = "<<M1[i*3+k]*M2[k*3+j]<<endl;
				x = M1[i * 3 + k] * M2[k * 3 + j] + x;
			}
			M3[i * 3 + j] = x;
		}
	}

	return M3;
}

osg::Vec3f normalize(osg::Vec3f vec)
{
	osg::Vec3f vecOut;
	if (vec.length() >= 100 * 1.e-15)
		vecOut = vec / vec.length();
	else
		vec / 100 * 1.e-15;
	return vecOut;
}


osg::Vec3f cross(osg::Vec3f vec1, osg::Vec3f vec2)
{
	osg::Vec3f vecOut;
	return osg::Vec3f(vec1[1] * vec2[2] - vec1[2] * vec2[1], vec1[2] * vec2[0] - vec1[0] * vec2[2], vec1[0] * vec2[1] - vec1[1] * vec2[0]);
}


Directions fixDirections(osg::Vec3f lDir, osg::Vec3f wDir)
{
	Directions dirs;
	osg::Vec3f e_x;
	osg::Vec3f e_y;

	//lengthDirection
	double abs_n_x = lDir.length();
	if (abs_n_x < 1e-10)
		e_x = osg::Vec3f(1.0, 0.0, 0.0);
	else
		e_x = lDir / abs_n_x;

	//widthDirection
	osg::Vec3f n_z_aux = cross(e_x, wDir);
	osg::Vec3f e_y_aux;
	if (n_z_aux * n_z_aux > 1e-6)
		e_y_aux = wDir;
	else
	{
		if (fabs(e_x[0]) > 1e-6)
			e_y_aux = osg::Vec3f(0, 1, 0);
		else
			e_y_aux = osg::Vec3f(1, 0, 0);
	}
	e_y = cross(normalize(cross(e_x, e_y_aux)), e_x);

	dirs._lDir = e_x;
	dirs._wDir = e_y;
	return dirs;
}

//osg::Matrix assemblePokeMatrix(osg::Matrix M, const osg::Matrix3& T, const osg::Vec3f& r)
void assemblePokeMatrix(osg::Matrix& M, const osg::Matrix3& T, const osg::Vec3f& r)
{
	M(3, 3) = 1.0;
	for (int row = 0; row < 3; ++row)
	{
		M(3, row) = r[row];
		M(row, 3) = 0.0;
		for (int col = 0; col < 3; ++col)
			M(row, col) = T[row * 3 + col];
	}
	//return M;
}


rAndT rotateModelica2OSG(osg::Vec3f r, osg::Vec3f r_shape, osg::Matrix3 T, osg::Vec3f lDirIn, osg::Vec3f wDirIn, float length, float width, float height, std::string type)
{
	rAndT res;

	Directions dirs = fixDirections(lDirIn, wDirIn);
	osg::Vec3f hDir = dirs._lDir ^ dirs._wDir;

	//std::cout<<"lDir1 "<<dirs.lDir[0]<<", "<<dirs.lDir[1]<<", "<<dirs.lDir[2]<<", "<<std::endl;
	//std::cout<<"wDir1 "<<dirs.wDir[0]<<", "<<dirs.wDir[1]<<", "<<dirs.wDir[2]<<", "<<std::endl;
	//std::cout<<"hDir "<<hDir[0]<<", "<<hDir[1]<<", "<<hDir[2]<<", "<<std::endl;

	osg::Vec3f r_offset = osg::Vec3f(0.0, 0.0, 0.0);  // since in osg, the rotation starts in the symmetric centre and in msl at the end of the body, we need an offset here of l/2 for some geometries
	osg::Matrix3 T0 = osg::Matrix3(dirs._wDir[0], dirs._wDir[1], dirs._wDir[2], hDir[0], hDir[1], hDir[2], dirs._lDir[0], dirs._lDir[1], dirs._lDir[2]);

	if (type == "cylinder")
	{
		/*
		 r = r + r_shape;
		 r_offset = dirs.lDir*length/2.0;
		 r_offset = V3mulMat3(r_offset,T);
		 res.r = r+r_offset;
		 */
		r_offset = dirs._lDir * length / 2.0;
		res._r = V3mulMat3(r_shape + r_offset, T);
		res._r = res._r + r;
		res._T = Mat3mulMat3(T0, T);
	}
	else if (type == "sphere")
	{
		T0 = osg::Matrix3(dirs._lDir[0], dirs._lDir[1], dirs._lDir[2], dirs._wDir[0], dirs._wDir[1], dirs._wDir[2], hDir[0], hDir[1], hDir[2]);
		r_offset = dirs._lDir * length / 2.0;
		res._r = V3mulMat3(r_shape + r_offset, T);
		res._r = res._r + r;
		res._T = Mat3mulMat3(T0, T);
	}
	else if (type == "cone")
	{
		// no offset needed
		res._r = V3mulMat3(r_shape, T);
		res._r = res._r + r;
		res._T = Mat3mulMat3(T0, T);
	}
	else if (type == "box")
	{
		r_offset = dirs._lDir * length / 2.0;
		res._r = V3mulMat3(r_shape + r_offset, T);
		res._r = res._r + r;
		res._T = Mat3mulMat3(T0, T);
	}
	else if (isCADType(type))
	{
		r = r + r_shape;
		res._T = T;
		res._r = r;
		//r_offset = dirs.lDir*length/2.0;
	}
	else
	{
		r_offset = dirs._lDir * length / 2.0;
		res._r = V3mulMat3(r_shape + r_offset, T);
		res._r = res._r + r;
		res._T = Mat3mulMat3(T0, T);
	}

	//std::cout<<"lDir "<<dirs.lDir[0]<<", "<<dirs.lDir[1]<<", "<<dirs.lDir[2]<<", "<<std::endl;
	//std::cout<<"wDir "<<dirs.wDir[0]<<", "<<dirs.wDir[1]<<", "<<dirs.wDir[2]<<", "<<std::endl;
	//std::cout<<"hDir "<<hDir[0]<<", "<<hDir[1]<<", "<<hDir[2]<<", "<<std::endl;
	//cout<<"rin "<<r[0]<<", "<<r[1]<<", "<<r[2]<<", "<<std::endl;
	//cout<<"roffset "<<r_offset[0]<<", "<<r_offset[1]<<", "<<r_offset[2]<<", "<<std::endl;
	return res;
}

