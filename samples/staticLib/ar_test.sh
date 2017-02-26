set -x
make bin/libmylib.a
g++ -o bin/target add_test.cpp -I. -Lbin -lmylib 
