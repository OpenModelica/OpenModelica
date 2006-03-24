/****************************************************************************
** Meta object code from reading C++ file 'cell.h'
**
** Created: to 23. mar 15:11:42 2006
**      by: The Qt Meta Object Compiler version 59 (Qt 4.1.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "cell.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'cell.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 59
#error "This file was generated using the moc from 4.1.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

static const uint qt_meta_data_IAEX__Cell[] = {

 // content:
       1,       // revision
       0,       // classname
       0,    0, // classinfo
      27,   10, // methods
       0,    0, // properties
       0,    0, // enums/sets

 // signals: signature, parameters, type, tag, flags
      12,   11,   11,   11, 0x05,
      27,   11,   11,   11, 0x05,
      46,   11,   11,   11, 0x05,
      64,   11,   11,   11, 0x05,
      81,   79,   11,   11, 0x05,
     123,   11,   11,   11, 0x05,
     144,  139,   11,   11, 0x05,
     166,   79,   11,   11, 0x05,

 // slots: signature, parameters, type, tag, flags
     191,  189,   11,   11, 0x0a,
     211,  206,   11,   11, 0x0a,
     240,  228,   11,   11, 0x0a,
     278,  273,   11,   11, 0x0a,
     309,  299,   11,   11, 0x0a,
     333,  327,   11,   11, 0x0a,
     361,  353,   11,   11, 0x0a,
     381,   11,   11,   11, 0x0a,
     405,  399,   11,   11, 0x0a,
     420,   11,   11,   11, 0x0a,
     445,  439,   11,   11, 0x0a,
     481,  472,   11,   11, 0x0a,
     506,  499,   11,   11, 0x0a,
     528,  521,   11,   11, 0x0a,
     553,  547,   11,   11, 0x0a,
     584,  578,   11,   11, 0x09,
     616,  602,   11,   11, 0x09,
     651,  641,   11,   11, 0x09,
     683,  675,   11,   11, 0x09,

       0        // eod
};

static const char qt_meta_stringdata_IAEX__Cell[] = {
    "IAEX::Cell\0\0clicked(Cell*)\0doubleClicked(int)\0changedWidth(int)\0"
    "selected(bool)\0,\0cellselected(Cell*,Qt::KeyboardModifiers)\0"
    "heightChanged()\0link\0openLink(const QUrl*)\0cellOpened(Cell*,bool)\0r\0"
    "addRule(Rule*)\0text\0setText(QString)\0text,format\0"
    "setText(QString,QTextCharFormat)\0html\0setTextHtml(QString)\0stylename\0"
    "setStyle(QString)\0style\0setStyle(CellStyle)\0tagname\0"
    "setCellTag(QString)\0setReadOnly(bool)\0focus\0setFocus(bool)\0"
    "applyLinksToText()\0color\0setBackgroundColor(QColor)\0selected\0"
    "setSelected(bool)\0height\0setHeight(int)\0hidden\0hideTreeView(bool)\0"
    "event\0wheelEvent(QWheelEvent*)\0label\0setLabel(QLabel*)\0"
    "newTreeWidget\0setTreeWidget(TreeView*)\0newWidget\0"
    "setMainWidget(QWidget*)\0counter\0addChapterCounter(QWidget*)\0"
};

const QMetaObject IAEX::Cell::staticMetaObject = {
    { &QWidget::staticMetaObject, qt_meta_stringdata_IAEX__Cell,
      qt_meta_data_IAEX__Cell, 0 }
};

const QMetaObject *IAEX::Cell::metaObject() const
{
    return &staticMetaObject;
}

void *IAEX::Cell::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_IAEX__Cell))
	return static_cast<void*>(const_cast<Cell*>(this));
    return QWidget::qt_metacast(_clname);
}

int IAEX::Cell::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QWidget::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: clicked(*reinterpret_cast< Cell**>(_a[1])); break;
        case 1: doubleClicked(*reinterpret_cast< int*>(_a[1])); break;
        case 2: changedWidth(*reinterpret_cast< int*>(_a[1])); break;
        case 3: selected(*reinterpret_cast< bool*>(_a[1])); break;
        case 4: cellselected(*reinterpret_cast< Cell**>(_a[1]),*reinterpret_cast< Qt::KeyboardModifiers*>(_a[2])); break;
        case 5: heightChanged(); break;
        case 6: openLink(*reinterpret_cast< const QUrl**>(_a[1])); break;
        case 7: cellOpened(*reinterpret_cast< Cell**>(_a[1]),*reinterpret_cast< bool*>(_a[2])); break;
        case 8: addRule(*reinterpret_cast< Rule**>(_a[1])); break;
        case 9: setText(*reinterpret_cast< QString*>(_a[1])); break;
        case 10: setText(*reinterpret_cast< QString*>(_a[1]),*reinterpret_cast< QTextCharFormat*>(_a[2])); break;
        case 11: setTextHtml(*reinterpret_cast< QString*>(_a[1])); break;
        case 12: setStyle(*reinterpret_cast< QString*>(_a[1])); break;
        case 13: setStyle(*reinterpret_cast< CellStyle*>(_a[1])); break;
        case 14: setCellTag(*reinterpret_cast< QString*>(_a[1])); break;
        case 15: setReadOnly(*reinterpret_cast< bool*>(_a[1])); break;
        case 16: setFocus(*reinterpret_cast< bool*>(_a[1])); break;
        case 17: applyLinksToText(); break;
        case 18: setBackgroundColor(*reinterpret_cast< QColor*>(_a[1])); break;
        case 19: setSelected(*reinterpret_cast< bool*>(_a[1])); break;
        case 20: setHeight(*reinterpret_cast< int*>(_a[1])); break;
        case 21: hideTreeView(*reinterpret_cast< bool*>(_a[1])); break;
        case 22: wheelEvent(*reinterpret_cast< QWheelEvent**>(_a[1])); break;
        case 23: setLabel(*reinterpret_cast< QLabel**>(_a[1])); break;
        case 24: setTreeWidget(*reinterpret_cast< TreeView**>(_a[1])); break;
        case 25: setMainWidget(*reinterpret_cast< QWidget**>(_a[1])); break;
        case 26: addChapterCounter(*reinterpret_cast< QWidget**>(_a[1])); break;
        }
        _id -= 27;
    }
    return _id;
}

// SIGNAL 0
void IAEX::Cell::clicked(Cell * _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 0, _a);
}

// SIGNAL 1
void IAEX::Cell::doubleClicked(int _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 1, _a);
}

// SIGNAL 2
void IAEX::Cell::changedWidth(const int _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 2, _a);
}

// SIGNAL 3
void IAEX::Cell::selected(const bool _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 3, _a);
}

// SIGNAL 4
void IAEX::Cell::cellselected(Cell * _t1, Qt::KeyboardModifiers _t2)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)), const_cast<void*>(reinterpret_cast<const void*>(&_t2)) };
    QMetaObject::activate(this, &staticMetaObject, 4, _a);
}

// SIGNAL 5
void IAEX::Cell::heightChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, 0);
}

// SIGNAL 6
void IAEX::Cell::openLink(const QUrl * _t1)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)) };
    QMetaObject::activate(this, &staticMetaObject, 6, _a);
}

// SIGNAL 7
void IAEX::Cell::cellOpened(Cell * _t1, const bool _t2)
{
    void *_a[] = { 0, const_cast<void*>(reinterpret_cast<const void*>(&_t1)), const_cast<void*>(reinterpret_cast<const void*>(&_t2)) };
    QMetaObject::activate(this, &staticMetaObject, 7, _a);
}
