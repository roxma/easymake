
all: $(PREFIX)/include/fmt/format.h

$(PREFIX)/include/fmt/format.h:

	# If this library has more dependencies
	# $(call DEP_MAKE,boost)

	$(call DEP_DOWNLOAD,https://github.com/fmtlib/fmt/archive/3.0.1.tar.gz,3.0.1.tar.gz,md5sum=b2c97427a696182b013d2cc0a2f939fe)
	tar -zxf 3.0.1.tar.gz
	cd fmt-3.0.1 && cmake  . -DCMAKE_INSTALL_PREFIX=$(PREFIX)
	make -C fmt-3.0.1
	make -C fmt-3.0.1 install

