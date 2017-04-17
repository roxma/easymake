################################################################
# Copyright (c) 2016 roxma@qq.com
# https://github.com/roxma/easymake
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# CFLAGS=
# CXXFLAGS=
# LDFLAGS=

# do not use the default `rv` option
ARFLAGS=cr

GEN_DEP_FLAG ?= -MP -MMD

# do not use ./bin
BUILD_ROOT?=bin

CXXEXT?=cpp
CEXT?=c
CC?=cc
CXX?=c++
AR?=ar

# ENTRY_LIST
# VPATH=

IS_TEST?=$(filter %_test.$(CEXT) %_test.$(CXXEXT),$(1))

#  clears out the suffix list with implicit rules
.SUFFIXES:

################################################################

##
# $(call Em_src2obj,$(CSRC) $(CXXSRC),$(BUILD_ROOT))
Em_src2obj=$(foreach _src,$(1),$(2)/$(basename $(_src)).o)

# Recursive wildcard
Em_rwildcard=$(foreach d,$(wildcard $1*),$(call Em_rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

# NOTICE: "./" in BUILD_ROOT may cause entry detecting problem.
ifneq (,$(filter ./%,$(BUILD_ROOT)))
    $(error Please do not use prefix "./" in variable BUILD_ROOT=$(BUILD_ROOT))
endif

# if CXXSRC are not specified, automatically scan all .$(CXXEXT) files in the 
# current directories.
ifeq ($(strip $(CXXSRC)),)
    CXXSRC:=$(call Em_rwildcard,,*.$(CXXEXT)) $(foreach dir,$(VPATH),$(foreach src,$(call Em_rwildcard,$(dir),*.$(CXXEXT)),$(src:$(dir)/%=%)))
    CXXSRC:=$(strip $(CXXSRC))
endif
ifneq (,$(findstring ..,$(CXXSRC)))
    $(error ".." should not appear in the cpp source list: $(CXXSRC))
endif
# remove "./" in file path, which may cause pattern rules problems.
CXXSRC:=$(subst ./,,$(CXXSRC))

# if CSRC are not specified, automatically scan all .$(CEXT) files in the 
# current directories.
ifeq ($(strip $(CSRC)),)
    CSRC:=$(call Em_rwildcard,,*.$(CEXT)) $(foreach dir,$(VPATH),$(foreach src,$(call Em_rwildcard,$(dir),*.$(CEXT)),$(src:$(dir)/%=%)))
    CSRC:=$(strip $(CSRC))
endif
ifneq (,$(findstring ..,$(CSRC)))
    $(error ".." should not appear in the c source list: $(CSRC))
endif
# remove "./" in file path, which may cause pattern rules problems.
CSRC:=$(subst ./,,$(CSRC))

# if the project has c++ source, use g++ for linking instead of gcc
ifneq ($(strip $(CXXSRC)),)
    em_linker:=$(CXX)
endif
em_linker?=$(CC)

em_all_objects:=$(call Em_src2obj,$(CSRC) $(CXXSRC),$(BUILD_ROOT))


# A file that contains a list of entries detected by easymake.
em_f_entries:=$(BUILD_ROOT)/em_entries

# By convention, the default target should be "all"
all:

# If there is a main function defined in this object, register the source file
# as entry.
$(BUILD_ROOT)/%.o: %.$(CXXEXT)
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(GEN_DEP_FLAG) -c -o $@  $<
	@if [ $$(nm -g --format="posix" $@ | grep -c "^main T") -eq 1 ]; then 		\
		echo "$(patsubst $(BUILD_ROOT)/%.o,%.$(CXXEXT),$@)" >> $(em_f_entries);	\
		sort -u $(em_f_entries) -o $(em_f_entries); 							\
	fi;

$(BUILD_ROOT)/%.o: %.$(CEXT)
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(GEN_DEP_FLAG)  -c -o $@ $<
	@if [ $$(nm -g --format="posix" $@ | grep -c "^main T") -eq 1 ]; then		\
		echo "$(patsubst $(BUILD_ROOT)/%.o,%.$(CEXT),$@)" >> $(em_f_entries);	\
		sort -u $(em_f_entries) -o $(em_f_entries); 							\
		fi;

# include all generated dependency files
ifneq ($(strip $(em_all_objects)),)
    sinclude $(em_all_objects:.o=.d)
endif

# Read detected entries from file and filter out the non-existed source
em_entry_list = $(ENTRY_LIST) $(filter $(CXXSRC) $(CSRC),$(shell cat $(em_f_entries) 2>/dev/null))

Em_entry   = $(if $(filter none NONE,$(1)),,$(1))
Em_objects = $(call Em_src2obj,$(filter-out $(em_entry_list),$(CSRC) $(CXXSRC)) $(call Em_entry,$(1)),$(BUILD_ROOT))
Em_src2target = $(foreach src,$1,$(BUILD_ROOT)/$(notdir $(basename $(src))))

$(em_all_objects): $(filter-out $(BUILD_ROOT)/%,$(MAKEFILE_LIST))

$(BUILD_ROOT)/em_targets.mk: $(em_all_objects)
	@rm -f $@
	@$(foreach f,$(em_entry_list),										\
		echo 'all: $(call Em_src2target,$f)' >> $@;						\
		echo '$(call Em_src2target,$f): $(call Em_objects,$f)' >> $@;	\
		echo '	$(em_linker) $$^ $(LDFLAGS) -o $$@ $(LOADLIBES) $(LDLIBS)'	>> $@;	\
	)

# This recipe to handle rule "all: foo.so" or command "make foo.so"
$(BUILD_ROOT)/lib%.so lib%.so: $(call  Em_objects,NONE)
	@echo
	$(em_linker) $(call  Em_objects,NONE) $(LDFLAGS) -o $@ $(LOADLIBES) $(LDLIBS)

# This recipe to handle rule "all: foo.a" or command "make foo.a"
$(BUILD_ROOT)/lib%.a lib%.a: $(call  Em_objects,NONE)
	$(AR) $(ARFLAGS) $@ $(call  Em_objects,NONE)

all $(sort $(call Em_src2target,$(CSRC) $(CXXSRC))): $(em_all_objects) $(BUILD_ROOT)/em_targets.mk
	@$(if $(strip $(em_entry_list)),												\
		$(MAKE) --no-print-directory -f  $(BUILD_ROOT)/em_targets.mk 				\
		$(filter-out  %.so %.a %.o %.d,$(filter $(BUILD_ROOT)/%,$(MAKECMDGOALS)))	\
		)


# "check" is the standard target from standard makefile conventions
check: test
test: all
	@echo "--- running tests ..."
	@set -e; $(foreach f,$(em_entry_list),	$(if $(call IS_TEST,$f),	\
		$(call Em_src2target,$f);										\
	,))
	@echo "--- test complete."

clean: em_clean
.PHONY: em_clean test check
em_clean:
	if [ -d $(BUILD_ROOT) ]; then find $(BUILD_ROOT) '(' -name "*.o" -o -name "*.d" -o -name "*.a" -o -name "*.so" -o -name "em_*" ')' -exec rm -f '{}' ';' ; fi

