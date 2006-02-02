/****************************************************************************
** Meta object code from reading C++ file 'celldocument.h'
**
** Created: ti 24. jan 12:19:48 2006
**      by: The Qt Meta Object Compiler version 58 (Qt 4.0.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "celldocument.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'celldocument.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 58
#error "This file was generated using the moc from 4.0.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__CellDocument[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
      15,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      20,   19,   19,   19, 0x05,
      38,   19,   19,   19, 0x05,
      54,   19,   19,   19, 0x05,
      75,   19,   19,   19, 0x05,

 // slots: signature, parameters, type, tag, flags
      92,   19,   19,   19, 0x0a,
     122,  113,   19,   19, 0x0a,
     140,   19,   19,   19, 0x0a,
     164,   19,   19,   19, 0x0a,
     191,  183,   19,   19, 0x0a,
     218,  208,   19,   19, 0x0a,
     261,   19,   19,   19, 0x0a,
     290,  278,   19,   19, 0x0a,
     320,  316,   19,   19, 0x0a,
     356,  345,   19,   19, 0x0a,
     386,  384,   19,   19, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__CellDocument[] = {
    "IAEX::CellDocument\0\0widthChanged(int)\0cursorChanged()\0"
    "viewExpression(bool)\0contentChanged()\0toggleMainTreeView()\0editable\0"
    "setEditable(bool)\0cursorChangedPosition()\0updateScrollArea()\0changed\0"
    "setChanged(bool)\0selected,\0selectedACell(Cell*,Qt::KeyboardModifiers)\0"
    "clearSelection()\0clickedCell\0mouseClickedOnCell(Cell*)\0url\0"
    "linkClicked(const QUrl*)\0aCell,open\0cursorMoveAfter(Cell*,bool)\0b\0"
    "showHTML(bool)\0"
};

const QMetaObject IAEX::CellDocument::staticMetaObject = {
    { &Document::staticMetaObject, qt_meta_stringdata_IAEX__CellDocument,
      qt_meta_data_IAEX__CellDocument, 0 }
};

const QMetaObject *IAEX::CellDocument::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::CellDocument::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__CellDocument))
	return static_cast<void*>(const_cast<CellDocument*>(this));
    return Document::qt_metacast(_clname);
}

int IAEX::CellDocument::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = Document::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: widthChanged(*(int*)_a[1]); break;
        case 1: cursorChanged(); break;
        case 2: viewExpression(*(bool*)_a[1]); break;
        case 3: contentChanged(); break;
        case 4: toggleMainTreeView(); break;
        case 5: setEditable(*(bool*)_a[1]); break;
        case 6: cursorChangedPosition(); break;
        case 7: updateScrollArea(); break;
        case 8: setChanged(*(bool*)_a[1]); break;
        case 9: selectedACell(*(Cell**)_a[1],*(Qt::KeyboardModifiers*)_a[2]); break;
        case 10: clearSelection(); break;
        case 11: mouseClickedOnCell(*(Cell**)_a[1]); break;
        case 12: linkClicked(*(const QUrl**)_a[1]); break;
        case 13: cursorMoveAfter(*(Cell**)_a[1],*(bool*)_a[2]); break;
        case 14: showHTML(*(bool*)_a[1]); break;
        }
        _id -= 15;
    }
    return _id;
}

// SIGNAL 0
void IAEX::CellDocument::widthChanged(const int _t1)
{
    void *_a[] = { 0, (void*)&_t1 };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void IAEX::CellDocument::cursorChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, 0);
}

// SIGNAL 2
void IAEX::CellDocument::viewExpression(const bool _t1)
{
    void *_a[] = { 0, (void*)&_t1 };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void IAEX::CellDocument::contentChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, 0);
}
