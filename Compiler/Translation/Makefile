srcdir = ..
top_builddir = ../..
localedir = $(top_builddir)/build/share/locale/
locales = de sv

release:
	for locale in $(locales); do mkdir -p $(localedir)/$$locale/LC_MESSAGES && msgfmt -o$(localedir)/$$locale/LC_MESSAGES/openmodelica.mo $$locale.po; done
update:
	xgettext --msgid-bugs-address=openmodelica@ida.liu.se --copyright-holder="Open Source Modelica Consortium (OSMC)" --package-name=OpenModelica --package-version=trunk -oopenmodelica.pot -LC++ --from-code=UTF-8 $(ALL_DIRS:%=%/*.mo) $(TEMPLATE_DIR:%=%/*.tpl)
	sed -i s/CHARSET/UTF-8/ openmodelica.pot

merge-all: update
	for f in $(locales); do msgmerge -U $$f.po openmodelica.pot; done

include ../Makefile.common
