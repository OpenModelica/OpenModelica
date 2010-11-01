/****************************************************************************
** Meta object code from reading C++ file 'Tools.h'
**
** Created: Tue 12. Oct 16:06:55 2010
**      by: The Qt Meta Object Compiler version 62 (Qt 4.7.0)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "Tools.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'Tools.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 62
#error "This file was generated using the moc from 4.7.0. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
static const uint qt_meta_data_Tools[] = {

 // content:
       5,       // revision
       0,       // classname
       0,    0, // classinfo
      17,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

 // slots: signature, parameters, type, tag, flags
       7,    6,    6,    6, 0x08,
      18,    6,    6,    6, 0x08,
      30,    6,    6,    6, 0x08,
      48,    6,    6,    6, 0x08,
      60,    6,    6,    6, 0x08,
      75,    6,    6,    6, 0x08,
      91,    6,    6,    6, 0x08,
     102,    6,    6,    6, 0x08,
     114,    6,    6,    6, 0x08,
     126,    6,    6,    6, 0x08,
     140,    6,    6,    6, 0x08,
     156,    6,    6,    6, 0x08,
     176,    6,    6,    6, 0x08,
     192,    6,    6,    6, 0x08,
     210,    6,    6,    6, 0x08,
     222,    6,    6,    6, 0x08,
     233,    6,    6,    6, 0x08,

       0        // eod
};

static const char qt_meta_stringdata_Tools[] = {
    "Tools\0\0draw_arc()\0draw_rect()\0"
    "draw_round_rect()\0draw_line()\0"
    "draw_ellipse()\0draw_polyline()\0"
    "draw_new()\0draw_save()\0draw_open()\0"
    "draw_shapes()\0msg_save_file()\0"
    "msg_dnt_save_file()\0draw_xml_save()\0"
    "draw_image_save()\0draw_copy()\0draw_cut()\0"
    "draw_paste()\0"
};

const QMetaObject Tools::staticMetaObject = {
    { &QMainWindow::staticMetaObject, qt_meta_stringdata_Tools,
      qt_meta_data_Tools, 0 }
};

#ifdef Q_NO_DATA_RELOCATION
const QMetaObject &Tools::getStaticMetaObject() { return staticMetaObject; }
#endif //Q_NO_DATA_RELOCATION

const QMetaObject *Tools::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->metaObject : &staticMetaObject;
}

void *Tools::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_Tools))
        return static_cast<void*>(const_cast< Tools*>(this));
    return QMainWindow::qt_metacast(_clname);
}

int Tools::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QMainWindow::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: draw_arc(); break;
        case 1: draw_rect(); break;
        case 2: draw_round_rect(); break;
        case 3: draw_line(); break;
        case 4: draw_ellipse(); break;
        case 5: draw_polyline(); break;
        case 6: draw_new(); break;
        case 7: draw_save(); break;
        case 8: draw_open(); break;
        case 9: draw_shapes(); break;
        case 10: msg_save_file(); break;
        case 11: msg_dnt_save_file(); break;
        case 12: draw_xml_save(); break;
        case 13: draw_image_save(); break;
        case 14: draw_copy(); break;
        case 15: draw_cut(); break;
        case 16: draw_paste(); break;
        default: ;
        }
        _id -= 17;
    }
    return _id;
}
QT_END_MOC_NAMESPACE
