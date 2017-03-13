
DEP_PREFIX = dep

include ../../dep.mk

all:
	$(call DEP_MAKE,make/fmt.module.mk)

	cd src && $(MAKE)

clean:
	cd src && $(MAKE) clean
