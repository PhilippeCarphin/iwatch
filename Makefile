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
	$(INSTALL) -D -m 755 bin/iwatch                      $(DESTDIR)$(PREFIX)/bin/iwatch
	$(INSTALL) -D -m 755 bin/pwatch.1                    $(DESTDIR)$(PREFIX)/bin/pwatch
	$(INSTALL) -D -m 644 share/man/man1/iwatch.1         $(DESTDIR)$(PREFIX)/share/man/man1/iwatch.1
	$(INSTALL) -D -m 644 share/man/man1/pwatch.1         $(DESTDIR)$(PREFIX)/share/man/man1/pwatch.1

install-dev: man
	$(INSTALL) -d $(DESTDIR)$(PREFIX)
	$(INSTALL) -d $(DESTDIR)$(PREFIX)/bin
	$(INSTALL) -d $(DESTDIR)$(PREFIX)/share/man/man1
	ln -snf $(PWD)/bin/iwatch                      $(DESTDIR)$(PREFIX)/bin/iwatch
	ln -snf $(PWD)/bin/pwatch                      $(DESTDIR)$(PREFIX)/bin/pwatch
	ln -snf $(PWD)/share/man/man1/iwatch.1         $(DESTDIR)$(PREFIX)/share/man/man1/iwatch.1
	ln -snf $(PWD)/share/man/man1/pwatch.1         $(DESTDIR)$(PREFIX)/share/man/man1/pwatch.1
