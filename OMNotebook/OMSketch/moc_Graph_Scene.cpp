/****************************************************************************
** Meta object code from reading C++ file 'Graph_Scene.h'
**
** Created: Mon 18. Apr 19:15:49 2011
**      by: The Qt Meta Object Compiler version 62 (Qt 4.7.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "Graph_Scene.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'Graph_Scene.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 62
#error "This file was generated using the moc from 4.7.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
static const uint qt_meta_data_Graph_Scene[] = {

 // content:
       5,       // revision
       0,       // classname
       0,    0, // classinfo
       1,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       1,       // signalCount

 // signals: signature, parameters, type, tag, flags
      24,   13,   12,   12, 0x05,

       0        // eod
};

static const char qt_meta_stringdata_Graph_Scene[] = {
    "Graph_Scene\0\0scene_item\0"
    "item_selected(Graph_Scene*)\0"
};

const QMetaObject Graph_Scene::staticMetaObject = {
    { &QGraphicsScene::staticMetaObject, qt_meta_stringdata_Graph_Scene,
      qt_meta_data_Graph_Scene, 0 }
};

#ifdef Q_NO_DATA_RELOCATION
const QMetaObject &Graph_Scene::getStaticMetaObject() { return staticMetaObject; }
#endif //Q_NO_DATA_RELOCATION

const QMetaObject *Graph_Scene::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->metaObject : &staticMetaObject;
}

void *Graph_Scene::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_Graph_Scene))
        return static_cast<void*>(const_cast< Graph_Scene*>(this));
    return QGraphicsScene::qt_metacast(_clname);
}

int Graph_Scene::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QGraphicsScene::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: item_selected((*reinterpret_cast< Graph_Scene*(*)>(_a[1]))); break;
        default: ;
        }
        _id -= 1;
    }
    return _id;
}

// SIGNAL 0
void Graph_Scene::item_selected(Graph_Scene * _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}
QT_END_MOC_NAMESPACE
