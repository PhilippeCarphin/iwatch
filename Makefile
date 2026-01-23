# vim: ts=8:sw=8:sts=8:noet
#
PREFIX ?= localinstall

ifeq ($(shell uname),Darwin)
	INSTALL=ginstall
else
	INSTALL=install
endif

man: share/man/man1/iwatch.1 share/man/man1/pwatch.1

share/man/man1/%.1:share/man/man1/%.org
	pandoc -s -t man -f org $< -o $@

install: man
	$(INSTALL) -D share/man/man1/iwatch.1 $(DESTDIR)$(PREFIX)/share/man/man1/iwatch.1
	$(INSTALL) -D share/man/man1/pwatch.1 $(DESTDIR)$(PREFIX)/share/man/man1/pwatch.1
	$(INSTALL) -D bin/iwatch $(DESTDIR)$(PREFIX)/bin/iwatch
	$(INSTALL) -D bin/pwatch $(DESTDIR)$(PREFIX)/bin/pwatch
	$(INSTALL) -D etc/profile.d/iwatch-shell.bash $(DESTDIR)$(PREFIX)/etc/profile.d/iwatch-shell.bash

install-dev: man
	$(INSTALL) -d localinstall/{bin,share/man/man1,etc/profile.d}
	ln -snf ../../../../share/man/man1/iwatch.1 	localinstall/share/man/man1/iwatch.1
	ln -snf ../../../../share/man/man1/pwatch.1 	localinstall/share/man/man1/iwatch.1
	ln -snf ../../bin/iwatch			localinstall/bin/iwatch
	ln -snf ../../bin/pwatch 			localinstall/bin/pwatch
	ln -snf ../../../etc/profile.d/iwatch-shell.bash   localinstall/etc/profile.d/iwatch-shell.bash

