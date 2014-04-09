PREFIX:=$(shell pwd)/install

all:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" MAKETYPE="Unix Makefiles" all

install: all
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" MAKETYPE="Unix Makefiles" install

test:
	@$(MAKE) -f Makefile PREFIX="$(PREFIX)" MAKETYPE="Unix Makefiles" test

run-mats:
	@$(MAKE) -f Makefile run-mats

e2etest:
	@$(MAKE) -f Makefile e2etest

e2eviewtests:
	@$(MAKE) -f Makefile e2eviewtests

clean:
	@$(MAKE) -f Makefile RM=rm RMOPTS=-rf clean

clean-xfd:
	@$(MAKE) -f Makefile RM=rm RMOPTS=-rf clean-xfd

clean-xfd-hard: clean-xfd

clean-all: clean-xfd

icu4c/source/Makefile:
	(cd icu4c/source && ./configure "--prefix=$(PREFIX)")

make-install-icu4c: icu4c/source/Makefile
	$(MAKE) -C icu4c/source install

make-install-couchdb-deps: make-install-icu4c
