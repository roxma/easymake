
DEP_PREFIX = dep

include ../../dep.mk

all:
	$(call DEP_MAKE,fmt)

	cd src && $(MAKE)

clean:
	cd src && $(MAKE) clean
