/****************************************************************************
** Meta object code from reading C++ file 'celldocument.h'
**
** Created: to 27. apr 10:52:32 2006
**      by: The Qt Meta Object Compiler version 59 (Qt 4.1.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "celldocument.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'celldocument.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 59
#error "This file was generated using the moc from 4.1.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__CellDocument[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
      19,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      20,   19,   19,   19, 0x05,
      38,   19,   19,   19, 0x05,
      54,   19,   19,   19, 0x05,
      75,   19,   19,   19, 0x05,
      92,   19,   19,   19, 0x05,
     115,   19,   19,   19, 0x05,

 // slots: signature, parameters, type, tag, flags
     134,   19,   19,   19, 0x0a,
     164,  155,   19,   19, 0x0a,
     182,   19,   19,   19, 0x0a,
     206,   19,   19,   19, 0x0a,
     233,  225,   19,   19, 0x0a,
     255,  250,   19,   19, 0x0a,
     284,  274,   19,   19, 0x0a,
     327,   19,   19,   19, 0x0a,
     356,  344,   19,   19, 0x0a,
     382,  344,   19,   19, 0x0a,
     418,  414,   19,   19, 0x0a,
     454,  443,   19,   19, 0x0a,
     484,  482,   19,   19, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__CellDocument[] = {
    "IAEX::CellDocument\0\0widthChanged(int)\0cursorChanged()\0"
    "viewExpression(bool)\0contentChanged()\0hoverOverFile(QString)\0"
    "forwardAction(int)\0toggleMainTreeView()\0editable\0setEditable(bool)\0"
    "cursorChangedPosition()\0updateScrollArea()\0changed\0setChanged(bool)\0"
    "link\0hoverOverUrl(QUrl)\0selected,\0"
    "selectedACell(Cell*,Qt::KeyboardModifiers)\0clearSelection()\0"
    "clickedCell\0mouseClickedOnCell(Cell*)\0mouseClickedOnCellOutput(Cell*)\0"
    "url\0linkClicked(const QUrl*)\0aCell,open\0cursorMoveAfter(Cell*,bool)\0"
    "b\0showHTML(bool)\0"
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
        case 0: widthChanged(*reinterpret_cast< int*>(_a[1])); break;
        case 1: cursorChanged(); break;
        case 2: viewExpression(*reinterpret_cast< bool*>(_a[1])); break;
        case 3: contentChanged(); break;
        case 4: hoverOverFile(*reinterpret_cast< QString*>(_a[1])); break;
        case 5: forwardAction(*reinterpret_cast< int*>(_a[1])); break;
        case 6: toggleMainTreeView(); break;
        case 7: setEditable(*reinterpret_cast< bool*>(_a[1])); break;
        case 8: cursorChangedPosition(); break;
        case 9: updateScrollArea(); break;
        case 10: setChanged(*reinterpret_cast< bool*>(_a[1])); break;
        case 11: hoverOverUrl(*reinterpret_cast< QUrl*>(_a[1])); break;
        case 12: selectedACell(*reinterpret_cast< Cell**>(_a[1]),*reinterpret_cast< Qt::KeyboardModifiers*>(_a[2])); break;
        case 13: clearSelection(); break;
        case 14: mouseClickedOnCell(*reinterpret_cast< Cell**>(_a[1])); break;
        case 15: mouseClickedOnCellOutput(*reinterpret_cast< Cell**>(_a[1])); break;
        case 16: linkClicked(*reinterpret_cast< const QUrl**>(_a[1])); break;
        case 17: cursorMoveAfter(*reinterpret_cast< Cell**>(_a[1]),*reinterpret_cast< bool*>(_a[2])); break;
        case 18: showHTML(*reinterpret_cast< bool*>(_a[1])); break;
        }
        _id -= 19;
    }
    return _id;
}

// SIGNAL 0
void IAEX::CellDocument::widthChanged(const int _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
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
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void IAEX::CellDocument::contentChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, 0);
}

// SIGNAL 4
void IAEX::CellDocument::hoverOverFile(QString _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 4, _a);
}

// SIGNAL 5
void IAEX::CellDocument::forwardAction(int _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 5, _a);
}
