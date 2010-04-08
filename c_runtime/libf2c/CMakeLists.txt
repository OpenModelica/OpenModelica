# Sources and Headers
set(MISC 
  f77vers.c i77vers.c main.c s_rnge.c abort_.c exit_.c getarg_.c iargc_.c
  getenv_.c signal_.c s_stop.c s_paus.c system_.c cabs.c 
  derf_.c derfc_.c erf_.c erfc_.c sig_die.c uninit.c)
set(POW pow_ci.c pow_dd.c pow_di.c pow_hh.c pow_ii.c pow_ri.c pow_zi.c pow_zz.c)
set(CX 	c_abs.c c_cos.c c_div.c c_exp.c c_log.c c_sin.c c_sqrt.c)
set(DCX	z_abs.c z_cos.c z_div.c z_exp.c z_log.c z_sin.c z_sqrt.c)
set(REAL r_abs.c r_acos.c r_asin.c r_atan.c r_atn2.c r_cnjg.c r_cos.c
  r_cosh.c r_dim.c r_exp.c r_imag.c r_int.c
  r_lg10.c r_log.c r_mod.c r_nint.c r_sign.c
  r_sin.c r_sinh.c r_sqrt.c r_tan.c r_tanh.c)
set(DBL	d_abs.c d_acos.c d_asin.c d_atan.c d_atn2.c
  d_cnjg.c d_cos.c d_cosh.c d_dim.c d_exp.c
  d_imag.c d_int.c d_lg10.c d_log.c d_mod.c
  d_nint.c d_prod.c d_sign.c d_sin.c d_sinh.c
  d_sqrt.c d_tan.c d_tanh.c)
set(INT i_abs.c 
  i_dim.c i_dnnt.c i_indx.c i_len.c i_mod.c i_nint.c i_sign.c
  lbitbits.c lbitshft.c)
set(HALF h_abs.c h_dim.c h_dnnt.c h_indx.c h_len.c h_mod.c h_nint.c h_sign.c)
set(CMP l_ge.c l_gt.c l_le.c l_lt.c hl_ge.c hl_gt.c hl_le.c hl_lt.c)
set(EFL	ef1asc_.c ef1cmc_.c)
set(CHAR f77_aloc.c s_cat.c s_cmp.c s_copy.c)
set(I77 backspac.c close.c dfe.c dolio.c due.c endfile.c err.c
  fmt.c fmtlib.c ftell_.c iio.c ilnw.c inquire.c lread.c lwrite.c
  open.c rdfmt.c rewind.c rsfe.c rsli.c rsne.c sfe.c sue.c
  typesize.c uio.c util.c wref.c wrtfmt.c wsfe.c wsle.c wsne.c xwsne.c)
set(QINT pow_qq.c qbitbits.c qbitshft.c ftell64_.c)
set(TIME dtime_.c etime_.c)

SET(f2c_headers f2c.h
			    fio.h
			    sysdep1.h
			    fmt.h
#			    math.h 
			    signal1.h
			    arith.h
			    lio.h
			    fp.h
			    rawio.h) 


# If you get an error compiling dtime_.c or etime_.c, try adding
# -DUSE_CLOCK to the CFLAGS assignment above; if that does not work,
# omit ${TIME} from OFILES  assignment below.

# To get signed zeros in write statements on IEEE-arithmetic systems,
# add -DSIGNED_ZEROS to the CFLAGS assignment below and add signbit.c
# to the end of the OFILES  assignment below.

# For INTEGER*8 support (which requires system-dependent adjustments to
# f2c.h), add ${QINT} to the OFILES  assignment below...
#add_executable(arithchk arithchk.c)
#if(UNIX)
#  target_link_libraries(arithchk m)
#endif()
#set_target_properties(arithchk PROPERTIES COMPILE_DEFINITIONS 
#  "NO_FPINIT;NO_LONG_LONG")
#ADD_CUSTOM_COMMAND(
#   OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/arith.h
#   COMMAND arithchk > ${CMAKE_CURRENT_BINARY_DIR}/arith.h
#   DEPENDS arithchk
#   )


set(OFILES  ${MISC} ${POW} ${CX} ${DCX} ${REAL} ${DBL} ${INT} 
  ${HALF} ${CMP} ${EFL} ${CHAR} ${I77} ${TIME})
# Library f2c
if(WIN32)
  ADD_DEFINITIONS(/D_COMPLEX_DEFINED /DUSE_CLOCK /DMSDOS /DNO_ONEXIT /D_MSC_VER /D__STDC__ /D_CRT_SECURE_NO_DEPRECATE)
ELSE(WIN32)
  ADD_DEFINITIONS(-fPIC -DNON_UNIX_STDIO)
ENDIF(WIN32)
add_library(f2c  ${OFILES} ${f2c_headers})
#set_property(TARGET f2c PROPERTY PREFIX lib)

# Install
INSTALL(TARGETS f2c
		ARCHIVE DESTINATION lib)
INSTALL(FILES f2c.h DESTINATION include)
		
