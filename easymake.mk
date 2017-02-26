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

##
# @param 1 A sub-word.
# @param 2 list of words.
# @param 3 error to show if no matched. If empty, this parameter has no
#   effect.
NonEmptyOrError     = $(if $(1),$(1),$(error $(2)))
SelectFileNameMatch = $(call NonEmptyOrError,$(word 1,$(foreach f,$(2),$(if $(filter $(1),$(notdir $(basename $(f)))),$(f),) )),$(3))

##
# $(call IfFileExist,filename,then,else)
IfFileExist=$(if $(wildcard $(1)),$(2),$(3))

##
# $(call GetEntry,entry_name,entry_list,error_message)
GetEntry=$(if $(filter $(1),$(2)),$(1),$(call SelectFileNameMatch,$(1),$(2),$(3)))

##
# $(call GetCorrendingObjects,$(CSRC) $(CXXSRC),$(BUILD_ROOT))
GetCorrendingObjects=$(foreach _src,$(1),$(2)/$(basename $(_src)).o)

##
# Recursive wildcard
RWildcard=$(foreach d,$(wildcard $1*),$(call RWildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

CmdEchoAndExec = echo $(1) && $(1)

################################################################

# NOTICE: "./" in BUILD_ROOT may cause entry detecting problem.
ifneq (,$(filter ./%,$(BUILD_ROOT)))
    $(error Please do not use prefix "./" in variable BUILD_ROOT=$(BUILD_ROOT))
endif

# if CXXSRC are not specified, automatically scan all .$(CXXEXT) files in the 
# current directories.
ifeq ($(strip $(CXXSRC)),)
    CXXSRC:=$(call RWildcard,,*.$(CXXEXT)) $(foreach dir,$(VPATH),$(foreach src,$(call RWildcard,$(dir),*.$(CXXEXT)),$(src:$(dir)/%=%)))
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
    CSRC:=$(call RWildcard,,*.$(CEXT)) $(foreach dir,$(VPATH),$(foreach src,$(call RWildcard,$(dir),*.$(CEXT)),$(src:$(dir)/%=%)))
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

em_all_objects:=$(call GetCorrendingObjects,$(CSRC) $(CXXSRC),$(BUILD_ROOT))


# A file that contains a list of entries detected by easymake.
em_f_detected_entries:=$(BUILD_ROOT)/em_detected_entries

em_f_targets_dep_prefix:=$(BUILD_ROOT)/em_targets_dep

# By convention, the default target should be "all"
all:

##
# Pattern rule Descriptions:
# 1. Prepare the directories, where the object file is gonna be created.
# 2. Compile the source code to object file, and generate .d file.
# 3. If there is a main function defined in this object, register the source file as entry.
#
$(BUILD_ROOT)/%.o: %.$(CXXEXT)
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) $(GEN_DEP_FLAG) -c -o $@  $<
	@if [ $$(nm -g --format="posix" $@ | grep -c "^main T") -eq 1 ]; then echo "$(patsubst $(BUILD_ROOT)/%.o,%.$(CXXEXT),$@)" >> $(em_f_detected_entries); sort -u $(em_f_detected_entries) -o $(em_f_detected_entries); fi;

$(BUILD_ROOT)/%.o: %.$(CEXT)
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(GEN_DEP_FLAG)  -c -o $@ $<
	@if [ $$(nm -g --format="posix" $@ | grep -c "^main T") -eq 1 ]; then echo "$(patsubst $(BUILD_ROOT)/%.o,%.$(CEXT),$@)" >> $(em_f_detected_entries); sort -u $(em_f_detected_entries) -o $(em_f_detected_entries); fi;


##
# include all generated dependency files
#
ifneq ($(strip $(em_all_objects)),)
    sinclude $(em_all_objects:.o=.d)
endif
sinclude $(wildcard $(em_f_targets_dep_prefix)_*)


# Read detected entries from file and filter out the non-existed source
em_entry_list = $(ENTRY_LIST) $(filter $(CXXSRC) $(CSRC),$(shell cat $(em_f_detected_entries) 2>/dev/null))

em_test_list  = $(foreach e,$(em_entry_list),$(if $(call IS_TEST,$(e)),$(e),))
em_build_list = $(filter-out $(em_nontest_built_entry_list) $(em_test_list),$(em_entry_list))

em_entry   = $(if $(filter none NONE,$(1)),,$(call GetEntry,$(1),$(em_entry_list),"the ENTRY($(1)) is neither defined in the entry_list nor detected by easymake (e.g. $(1).cpp). detected values are $(em_entry_list)"))
em_objects = $(call GetCorrendingObjects,$(filter-out $(em_entry_list),$(CSRC) $(CXXSRC)) $(call em_entry,$(1)),$(BUILD_ROOT))

# Get target name from entry name
em_target = $(BUILD_ROOT)/$(notdir $(basename $(1)))
em_entry_name_from_target = $(if $(filter %.a %.so,$(notdir $@)),NONE,$(notdir $@))
em_nontest_built_exe = $(foreach e,$(em_nontest_built_entry_list),$(call IfFileExist,$(e),$(call em_target,$(e)),))

# Automatically find and compiles all c/cpp files, build the corresponding non test programs if any main function exists
all: $(em_all_objects) $(em_nontest_built_exe)
	@$(foreach e,$(em_build_list),  echo -e "$(call em_target,$(e)): $(call em_objects,$(e))\nem_built_target_list+=$(call em_target,$(e))\nem_nontest_built_entry_list+=$(e)" > $(em_f_targets_dep_prefix)_$(notdir $(call em_target,$(e))).d ; ) true
	@$(foreach e,$(em_build_list), $(call CmdEchoAndExec, $(em_linker) -o $(call em_target,$(e)) $(call em_objects,$(e)) $(LDFLAGS)) && ) true

# This recipe to handle command "make bin/foo"
# Explicit exec goals does not know their dependencies
$(filter-out  $(em_nontest_built_exe) %.so %.a %.o %.d,$(filter $(BUILD_ROOT)/%,$(MAKECMDGOALS))): $(em_all_objects)
	@echo 
	@echo -e "$@: $(call em_objects,$(em_entry_name_from_target))\nem_built_target_list+=$@\nem_nontest_built_entry_list+=$(call em_entry,$(em_entry_name_from_target))" > $(em_f_targets_dep_prefix)_$(notdir $@).d
	$(em_linker) $(call em_objects,$(em_entry_name_from_target)) $(LDFLAGS) -o $@ $(LOADLIBES) $(LDLIBS)

# targets built before have already know their own dependencies
$(em_nontest_built_exe):
	@echo 
	@echo -e "$@: $(call em_objects,$(em_entry_name_from_target))\nem_built_target_list+=$@\nem_nontest_built_entry_list+=$(call em_entry,$(em_entry_name_from_target))" > $(em_f_targets_dep_prefix)_$(notdir $@).d
	$(em_linker) $(call em_objects,$(em_entry_name_from_target)) $(LDFLAGS) -o $@ $(LOADLIBES) $(LDLIBS)

# This recipe to handle rule "all: foo.so" or command "make foo.so"
$(BUILD_ROOT)/lib%.so lib%.so: $(call  em_objects,NONE)
	@echo
	@echo -e "$@: $(call em_objects,NONE)\nem_built_target_list+=$@" > $(em_f_targets_dep_prefix)_$(notdir $@).d
	$(em_linker) $(call  em_objects,NONE) $(LDFLAGS) -o $@ $(LOADLIBES) $(LDLIBS)


# This recipe to handle rule "all: foo.a" or command "make foo.a"
$(BUILD_ROOT)/lib%.a lib%.a: $(call  em_objects,NONE)
	@echo $(filter-out $(em_entry_list),$(em_all_objects))
	@echo -e "$@: $(call em_objects,NONE)\nem_built_target_list+=$@" > $(em_f_targets_dep_prefix)_$(notdir $@).d
	$(AR) $(ARFLAGS) $@ $(call  em_objects,NONE)

# "check" is the standard target from standard makefile conventions
check: test
test: SHELL := /bin/bash
test: $(em_all_objects)
	@$(foreach e, $(em_test_list),  echo -e "$(call em_target,$(e)): $(call em_objects,$(e))\nem_built_target_list+=$(call em_target,$(e))\nem_test_built_entry_list+=$(e)" > $(em_f_targets_dep_prefix)_$(notdir $(call em_target,$(e))).d ; ) true
	@$(foreach e, $(em_test_list), $(call CmdEchoAndExec, $(em_linker) -o $(call em_target,$(e)) $(call em_objects,$(e)) $(LDFLAGS))  && ) true
	@echo 
	@cnt=0; failed=0; $(foreach e,$(em_test_list), echo '# run [$(call em_target,$(e))]' && { $(call em_target,$(e)) 2>&1 | sed "s/^/  # /g" 2>/dev/null; ret=$${PIPESTATUS[0]}; if [[ $$ret != 0 ]]; then echo "# test [$(call em_target,$(e))] failed [$$ret]"; failed=$$((failed+1));  fi; cnt=$$((cnt+1)); true; } 2>/dev/null && ) echo "# $$cnt test complete. $$failed failed test."

clean: em_clean
.PHONY: em_clean
em_clean:
	rm -f $(em_built_target_list)
	if [ -d $(BUILD_ROOT) ]; then find $(BUILD_ROOT) '(' -name "*.o" -o -name "*.d" -o -name "*.a" -o -name "*.so" -o -name "em_*" ')' -exec rm -f '{}' ';' ; fi

