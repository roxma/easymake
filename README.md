# Getting Started with Easymake #


  
## Introduction ##

Easymake is a generic makefile for C/C++ on linux system. For simple C/C++ applications, you don&rsquo;t even need to write a single line of makefile code to build your target with easymake.

Features description:

* Finds and compiles all C/C++ source files in the directory recursively (optional). Places the object files and target files in a separate directory.
* Only re-compiles the changed and affected source files.
* Supports Simple unit testing.
* Handles more than one entry point in the project.

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

Why bother writing a Makefile?

![multi_entries](./doc/images/multi_entries.gif)

