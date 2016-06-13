
make bin/libmylib.so

g++ add_test.cpp -I. -L./bin/ -lmylib -o bin/target

LD_LIBRARY_PATH=./bin/ ./bin/target
