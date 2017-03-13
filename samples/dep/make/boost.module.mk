
all: $(PREFIX)/include/boost/lambda/lambda.hpp

$(PREFIX)/include/boost/lambda/lambda.hpp:
	$(call DEP_DOWNLOAD,https://nchc.dl.sourceforge.net/project/boost/boost/1.63.0/boost_1_63_0.tar.gz,boost_1_63_0.tar.gz,md5sum=7b493c08bc9557bbde7e29091f28b605)
	rm -rf boost_1_63_0
	tar -zxf boost_1_63_0.tar.gz
	cd boost_1_63_0 && ./bootstrap.sh --prefix=$(PREFIX) && ./b2 install

