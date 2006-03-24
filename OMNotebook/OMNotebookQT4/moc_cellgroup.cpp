/****************************************************************************
** Meta object code from reading C++ file 'cellgroup.h'
**
** Created: to 23. mar 15:11:42 2006
**      by: The Qt Meta Object Compiler version 59 (Qt 4.1.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "cellgroup.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'cellgroup.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 59
#error "This file was generated using the moc from 4.1.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__CellGroup[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
       4,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // slots: signature, parameters, type, tag, flags
      23,   17,   16,   16, 0x0a,
      50,   43,   16,   16, 0x0a,
      72,   66,   16,   16, 0x0a,
      87,   16,   16,   16, 0x09,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__CellGroup[] = {
    "IAEX::CellGroup\0\0style\0setStyle(CellStyle)\0closed\0setClosed(bool)\0"
    "focus\0setFocus(bool)\0adjustHeight()\0"
};

const QMetaObject IAEX::CellGroup::staticMetaObject = {
    { &Cell::staticMetaObject, qt_meta_stringdata_IAEX__CellGroup,
      qt_meta_data_IAEX__CellGroup, 0 }
};

const QMetaObject *IAEX::CellGroup::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::CellGroup::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__CellGroup))
	return static_cast<void*>(const_cast<CellGroup*>(this));
    return Cell::qt_metacast(_clname);
}

int IAEX::CellGroup::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = Cell::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: setStyle(*reinterpret_cast< CellStyle*>(_a[1])); break;
        case 1: setClosed(*reinterpret_cast< bool*>(_a[1])); break;
        case 2: setFocus(*reinterpret_cast< bool*>(_a[1])); break;
        case 3: adjustHeight(); break;
        }
        _id -= 4;
    }
    return _id;
}
