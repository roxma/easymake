# Easymake - Why Bother To Write Makefilessssss? #


  
## Introduction ##

Easymake is a generic makefile for C/C++ on linux system. For simple C/C++ applications, you don&rsquo;t even need to write a single line of makefile code to build your target with easymake.

Features description:

* Finds and compiles all C/C++ source files in the directory recursively (optional). Places the object files and target files in a separate directory.
* Only re-compiles the changed and affected source files.
* Supports Simple unit testing.
* Handles more than one entry point in the project.

***NOTICE***: Easymake is designed to be easy to use on some simple applications, not as a highly flexible or extensible template. If you want to be more customizable, you may take a look at [this](https://gist.github.com/samuelsmal/e43f2001cfc81fee18b6) for start.

## Getting Started ##

### Basics

```
git clone https://github.com/roxma/easymake
cd easymake/samples/basics
cp ../../easymake.mk Makefile
make
./bin/add  # if you rename add.cpp to myprogram.cpp, then you get ./bin/myprogram.cpp
```

![basics](./doc/images/basics.gif)

### Unit Testing

Files with `*_test.cpp` or `*_test.c` pattern will be used for testing (inspired by golang).

![unit_test](./doc/images/unit_test.gif)

### Multi Entries

![multi_entries](./doc/images/multi_entries.gif)

### Options

Easymake is trying to follow the Makefile Conventions [(1)](https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html#Implicit-Variables) [(2)](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html). The following options are supported.

- `CFLAGS` Extra flags to give to the C compiler.
- `CXXFLAGS` Extra flags to give to the C++ compiler.
- `LDFLAGS` Extra flags to give to compilers when they are supposed to invoke the linker
- `LDLIBS` Library flags or names given to compilers when they are supposed to invoke the linker
- `ARFLAGS` Flags to give the archive-maintaining program; default `cr`

