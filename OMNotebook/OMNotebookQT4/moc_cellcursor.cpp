/****************************************************************************
** Meta object code from reading C++ file 'cellcursor.h'
**
** Created: ti 24. jan 12:19:48 2006
**      by: The Qt Meta Object Compiler version 58 (Qt 4.0.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "cellcursor.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'cellcursor.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 58
#error "This file was generated using the moc from 4.0.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__CellCursor[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       3,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      18,   17,   17,   17, 0x05,
      46,   36,   17,   17, 0x05,

 // slots: signature, parameters, type, tag, flags
      79,   17,   17,   17, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__CellCursor[] = {
    "IAEX::CellCursor\0\0changedPosition()\0x,y,xm,ym\0"
    "positionChanged(int,int,int,int)\0setFocus(bool)\0"
};

const QMetaObject IAEX::CellCursor::staticMetaObject = {
    { &Cell::staticMetaObject, qt_meta_stringdata_IAEX__CellCursor,
      qt_meta_data_IAEX__CellCursor, 0 }
};

const QMetaObject *IAEX::CellCursor::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::CellCursor::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__CellCursor))
	return static_cast<void*>(const_cast<CellCursor*>(this));
    return Cell::qt_metacast(_clname);
}

int IAEX::CellCursor::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = Cell::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: changedPosition(); break;
        case 1: positionChanged(*(int*)_a[1],*(int*)_a[2],*(int*)_a[3],*(int*)_a[4]); break;
        case 2: setFocus(*(bool*)_a[1]); break;
        }
        _id -= 3;
    }
    return _id;
}

// SIGNAL 0
void IAEX::CellCursor::changedPosition()
{
    QMetaObject::activate(this, &staticMetaObject, 0, 0);
}

// SIGNAL 1
void IAEX::CellCursor::positionChanged(int _t1, int _t2, int _t3, int _t4)
{
    void *_a[] = { 0, (void*)&_t1, (void*)&_t2, (void*)&_t3, (void*)&_t4 };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}
