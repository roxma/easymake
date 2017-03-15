
DEP_PREFIX = dep

include ../../dep.mk

all:
	$(call DEP_MAKE,./make/fmt.module.mk)

	# this example shows how to clone a git repo dependency with cache
	# $(call DEP_MAKE,./make/crow.module.mk )

	cd src && $(MAKE)

clean:
	cd src && $(MAKE) clean
