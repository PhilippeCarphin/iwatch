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
	$(INSTALL) -D share/man/man1/pwatch.1 $(DESTDIR)$(PREFIX)/share/man/man1/iwatch.1
	$(INSTALL) -D bin/iwatch $(DESTDIR)$(PREFIX)/bin/iwatch
	$(INSTALL) -D bin/pwatch $(DESTDIR)$(PREFIX)/bin/pwatch

