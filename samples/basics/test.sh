echo cp ../../easymake.mk Makefile
cp ../../easymake.mk Makefile

echo
echo make
make

echo
echo ./bin/add
./bin/add  # if you rename add.cpp to myprogram.cpp, then you get ./bin/myprogram.cpp

echo
echo -e "\n\ncreate add_test.cpp\n"
echo '#include <iostream>

#include "math/add.h"
#include <cassert>

int main(){
  assert(add(1,1)==3);
  return 0;
}
' > add_test.cpp

echo
echo make test
make test

