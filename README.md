# Easymake

## Introduction ##

Easymake is a handy makefile for C/C++ applications on Linux system. For
simple applications, you don&rsquo;t even need to write a single line of
makefile code to build your target with easymake.

Features description:

- Finds and compiles all C/C++ source files in the directory recursively
  (optional). Places the object files and target files in a separate
  directory.
- Only re-compiles the changed and affected source files. That is, if you
  modify your header `foo.h`, all your source files with `#include "foo.h"`
  will be re-compiled.
- Supports Simple unit testing.
- Handles more than one entry point in the project.
- Support both [static library(libfoo.a)](samples/staticLib/Makefile) and
  [shared library(libfoo.so)](samples/so/Makefile) building.

***NOTICE***: Easymake is designed to be easy to use on some simple
applications, not as a highly flexible or extensible template. If you want
more customization, you might need to look for [a simple one](https://gist.github.com/samuelsmal/e43f2001cfc81fee18b6)
for start.

If your project is getting a bit more complicated with third-party library
dependencis, refer to the [dep example](samples/dep) which shows how I achive
that.

## Getting Started ##

### Basics

```
git clone https://github.com/roxma/easymake
cd easymake/samples/basics
cp ../../easymake.mk Makefile
make
./bin/add  # if you rename add.cpp to myprogram.cpp, then you get ./bin/myprogram.cpp
```

![basics](https://cloud.githubusercontent.com/assets/4538941/24320876/fcd504c4-1179-11e7-969f-d2f2c40270e9.gif)

### Unit Testing

Files with `*_test.cpp` or `*_test.c` pattern will be used for testing
(inspired by golang).

![unit_test](https://cloud.githubusercontent.com/assets/4538941/24320877/fea9002a-1179-11e7-8b2c-05149689fe57.gif)

### Multi Entries

![multi_entries](https://cloud.githubusercontent.com/assets/4538941/24320879/00e48756-117a-11e7-9dcc-d14729e26dca.gif)

### Options

Easymake is trying to follow the Makefile Conventions
[(1)](https://www.gnu.org/software/make/manual/html_node/Implicit-Variables.html#Implicit-Variables)
[(2)](https://www.gnu.org/prep/standards/html_node/Makefile-Conventions.html).
The following options are supported.

- `CFLAGS` Extra flags to give to the C compiler.
- `CXXFLAGS` Extra flags to give to the C++ compiler.
- `LDFLAGS` Extra flags to give to compilers when they are supposed to invoke the linker
- `LDLIBS` Library flags or names given to compilers when they are supposed to invoke the linker
- `ARFLAGS` Flags to give the archive-maintaining program; default `cr`

### Recommended Style

In the GIFs, I simply copy `easymake.mk` into my souce code directory as a
makefile. However, for code simplicity, I recommend the following style:

```
CXXFLAGS=-O2

# other options
# ...

include /path/to/easymake.mk
```

