
all: $(PREFIX)/include/crow.h

$(PREFIX)/include/crow.h:
	$(call DEP_MAKE,boost.module.mk)
	$(call DEP_GIT,https://github.com/ipkn/crow.git,crow,4e39b23e455e455f1878b3e68d729a1737f3e431)
	cd crow && mkdir -p build && cd build && cmake .. -DCMAKE_INSTALL_PREFIX=$(PREFIX) -DBOOST_ROOT=$(DEP_PREFIX) && make
	cd crow && mkdir -p $(PREFIX) && cp -r include $(PREFIX)/include


