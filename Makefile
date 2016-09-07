DOMAIN=tools.jmap.io
DHPARAMDIR=/etc/ssl/dhparam/
DHPARAM=$(DOMAIN).dhparam
PRIVATEKEY=$(DOMAIN).privatekey
PUBLICCERT=$(DOMAIN).publiccert

PACKAGES=                   \
  build-essential           \
  fcgiwrap                  \
  nginx                     \

PERLPACKAGES=                     \
  Net::CalDAVTalk                 \

all: $(DHPARAM) $(PUBLICCERT)

$(DHPARAM):
	openssl dhparam -outform pem -out $(DHPARAM) 2048

$(PUBLICCERT) : $(PRIVATEKEY)
	openssl req -key $(PRIVATEKEY) -new -nodes -out $@ -days 365 -x509 -subj '/C=AU/ST=Victoria/L=Melbourne/O=$(DOMAIN)/OU=testing/CN=*.$(DOMAIN)'

$(PRIVATEKEY):
	openssl genrsa -out $@ 2048;

install: all
	apt-get install -y $(PACKAGES)
	$(foreach PERLPACKAGE, $(PERLPACKAGES), yes | cpan $(PERLPACKAGE) &&) true
	install -o root -g root -m 755 -d $(DHPARAMDIR)
	install -o root -g root -m 644 $(DHPARAM) $(DHPARAMDIR)/$(DHPARAM)
	install -o root -g root -m 644 $(PUBLICCERT) /etc/ssl/certs/$(PUBLICCERT)
	install -o root -g root -m 644 $(PRIVATEKEY) /etc/ssl/private/$(PRIVATEKEY)
	install -o root -g root -m 644 nginx.conf /etc/nginx/sites-available/$(DOMAIN).conf
	ln -fs /etc/nginx/sites-available/$(DOMAIN).conf /etc/nginx/sites-enabled/$(DOMAIN).conf
	/etc/init.d/nginx restart

diff: all
	diff -Nu /etc/nginx/sites-enabled/$(DOMAIN).conf nginx.conf || true
	diff -Nu /etc/ssl/certs/$(PUBLICCERT) $(PUBLICCERT)         || true
	diff -Nu /etc/ssl/private/$(PRIVATEKEY) $(PRIVATEKEY)       || true

clean:
	rm -f $(DHPARAM) $(PUBLICCERT) $(PRIVATEKEY)
