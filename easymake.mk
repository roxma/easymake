# author       : roxma
# version      : 8
# Descriptions : A generic makefiles under linux, to help you build 
#                your c/c++ programs easily without writing a long 
#                long tedious makefile.
# github       : https://github.com/roxma/easymake

# Execute "make show" for debug information.

# basic settings

# CFLAGS=
# CXXFLAGS=
# LDFLAGS=
ARFLAGS?=cr

# do not use ./bin
BUILD_ROOT?=bin


CXXEXT?=cpp
CEXT?=c

CC?=gcc
CXX?=g++
AR?=ar

# ENTRY_LIST
# VPATH=

################################################################
# internal implementations

#  clears out the suffix list with implicit rules
.SUFFIXES:

##
# A function to Check whether a string is begin with a non-empty 
# substring. If not, the result is empty string. Otherwise the result 
# is the substring.
# @param 1 substring to begin with
# @param 2 source string
BeginWith=$(if $(2),$(if $(patsubst $(1)%,,$(2)),,$(1)),)

##
# A function to read settings from a text file. Any line begin with
# a '#' character will be treated as comment and ommitted. Others
# will be in the result.
# $(call ReadSettings, $(file_name))
ReadSettings=$(shell if [ -f $(1) ]; then grep -v "^\#" $(1); fi;)

##
# A function to read the n-th line of a text file.
# $(call ReadLine, fine_name, line_num)
ReadLine=$(shell if [ -f $(1) ]; then sed -n $(2)p $(1); fi;)

## 
# @param 1 The word to find.
# @param 2 list of words
WordExist=$(strip $(foreach word,$(2),$(if $(patsubst $(strip $(1)),,$(strip $(word))),,$(1))))

##
# @param 1 A sub-word.
# @param 2 list of words.
# @param 3 error to show if no matched. If empty, this parameter has no
#   effect.
NonEmptyOrError     = $(if $(1),$(1),$(error $(2)))
SelectFirstMatch    = $(call NonEmptyOrError,$(word 1,$(foreach word,$(2),$(if $(findstring $(1),$(word)),$(word),) )),$(3))
SelectFileNameMatch = $(call NonEmptyOrError,$(word 1,$(foreach f,$(2),$(if $(filter $(1),$(notdir $(basename $(f)))),$(f),) )),$(3))

##
# Check if the file exists
# # @param 1 The file name
# # @note A name with $(VPATH) as base will fail here
FileExist=$(if $(wildcard $(1)),yes,)

IfFileExist=$(if $(wildcard $(1)),$(2),$(3))

##
# Search the path of the files, if a file name is based on $(VPATH), Then the
# corresopnding result of that element will be $(VPATH)/$(1)
# @param 1 A list of file name
SearchFilePath=$(foreach file,$(1),$(if $(call FileExist,$(file)),$(file),$(foreach vpathDir,$(VPATH),$(if $(call FileExist,$(vpathDir)/$(file)),$(vpathDir)/$(file)))))

##
# @param 1 Entry name
GetEntryPath4Timestamp=$(if $(call SearchFilePath,$(1)),$(call SearchFilePath,$(1)),$(shell if [ ! -f $(BUILD_ROOT)/easymake_entry_timestamp_$(1) ]; then  touch $(BUILD_ROOT)/easymake_entry_timestamp_$(1); fi)$(BUILD_ROOT)/easymake_entry_timestamp_$(1))

##
# If the user specifies $(ENTRY), and the $(ENTRY) is not a file, update its 
# timestamp, so that this entry will be picked next time.
ifneq ($(ENTRY),)
ifeq ($(strip $(call SearchFilePath,$(ENTRY))),)
    $(shell mkdir -p $(dir $(BUILD_ROOT)/easymake_entry_timestamp_$(ENTRY)))
    $(shell touch $(BUILD_ROOT)/easymake_entry_timestamp_$(ENTRY))
endif
endif

##
# Get the file with the newest timestamp
# @param 1 A list of files
# @return The index of files in the list
GetNewestFileIndex=$(shell newestIndex=1 && index=1 && newest=$(call GetEntryPath4Timestamp,$(word 1,$(1))) && for file in $(foreach file,$(1),$(call GetEntryPath4Timestamp,$(file)) ) ; do if [ $$file -nt $$newest ] ; then newest=$$file; newestIndex=$$index; fi; let index+=1; done && echo $$newestIndex)

##
# A function to decide the actual entry file.
# @param 1 the user-specified entry, could be an empty string
# @param 2 entry_list
# @param 3 error message if this function failed. If the entry is neither
# empty nor in the entry_list.
GetEntry=$(if $(call WordExist,$(1),$(2)),$(1),$(call SelectFileNameMatch,$(1),$(2),$(3)))

##
# Filter-out the sources that will not finally be linked into the target.
# @param 1 SOURCES 
# @param 2 ENTRY 
# @param 3 ENTRY_LIST
FilterSourcesToLink=$(filter-out $(filter-out $(2),$(3)), $(1))

##
# @param 1 sources
# @param 2 build_root
# @param 3 source file extension
GetCorrendingObjects=$(foreach _src,$(1),$(2)/$(_src:.$(3)=.o))

##
# Recursive wildcard
RWildcard=$(foreach d,$(wildcard $1*),$(call RWildcard,$d/,$2) $(filter $(subst *,%,$2),$d))

##
# @param 1 file name
# @param 2 key
ConfReadValue=$(shell cat $1 | awk  '{if ($$1=="$2") print $$2; }')

##
# @param 1 file name
# @param 2 key
# @param 3 value
CmdConfWriteValue= touch $1 ; fileContents="`cat $1`" ; echo "$$fileContents" |  awk '{if ((NF==2)&&($$1!="$2")) print $$1,$$2 ; } END{print "$2","$3" ;}' > $1


################################################################

ifneq (,$(call BeginWith,./,$(BUILD_ROOT)))
    # "./" in BUILD_ROOT may cause entry detecting problem.
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
    easymake_linker:=$(CXX)
endif
easymake_linker?=$(CC)

easymake_all_cppobjects:=$(call GetCorrendingObjects,$(CXXSRC),$(BUILD_ROOT),$(CXXEXT))
easymake_all_cobjects:=$(call GetCorrendingObjects,$(CSRC),$(BUILD_ROOT),$(CEXT))


# A file that contains a list of entries detected by easymake.
easymake_f_detected_entries:=$(BUILD_ROOT)/easymake_detected_entries

easymake_f_targets_dep_prefix:=$(BUILD_ROOT)/easymake_targets_dep

# The default target should be "all", Conforming to the makefile conventions
all:


##
# clean all .o .d .a .so files recursively in the BUILD_ROOT
#
clean:
clean: easymake_clean
.PHONY: easymake_clean
easymake_clean:
	rm -f $$(find $(BUILD_ROOT ) -name "*.o"   )
	rm -f $$(find $(BUILD_ROOT ) -name "*.d"   )
	rm -f $$(find $(BUILD_ROOT ) -name "*.a"   )
	rm -f $$(find $(BUILD_ROOT ) -name "*.so"  )
	rm -f $$(find $(BUILD_ROOT ) -name "*.out" )

##
# 
#
easymake_build_goals:=$(filter $(BUILD_ROOT)/%,$(MAKECMDGOALS))
ifeq ($(MAKECMDGOALS),)
easymake_build_goals:=$(filter $(BUILD_ROOT)/%,$(.DEFAULT_GOAL))
endif

easymake_build_goals:=$(filter-out $(BUILD_ROOT)/%.o $(BUILD_ROOT)/%.d $(BUILD_ROOT)/easymake_%,$(easymake_build_goals))


##
# Pattern rule Descriptions:
# 1. Prepare the directories, where the object file is gonna be created.
# 2. Compile the source code to object file.
# 3. Generate the .d dependency file, which specify what files this object 
#    files depends on. This is useful in the next make.
# 4. Prepare $(easymake_f_detected_entries), which is not empty.
# 5. 
# 6. Delete the name of the source file this target corresponds to, if it is 
#    listed in file $(easymake_f_detected_entries). Note that the grep command 
#    returns non-zero code if its output is empty, thus we have to make sure 
#    that the file $(easymake_f_detected_entries) is not empty.
# 7. If there is a main function defined in this object, add this file into the 
#    list defined in the file $(easymake_f_detected_entries).
#
$(BUILD_ROOT)/%.o: %.$(CXXEXT)
	@mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@  $(word 1,$^) 
	@$(CXX) -MM -MP -MF"$(@:.o=.d)" -MT"$@" $(CPPFLAGS) $(CXXFLAGS) $(word 1,$^) 
	@if [ ! -f $(easymake_f_detected_entries) ]; then echo " " > $(easymake_f_detected_entries); fi;
	@grep -v "^$(patsubst $(BUILD_ROOT)/%.o,%.$(CXXEXT),$@)$$" $(easymake_f_detected_entries) > $(BUILD_ROOT)/easymake_entries_tmp.d 
	@cp $(BUILD_ROOT)/easymake_entries_tmp.d $(easymake_f_detected_entries)
	@if [ $$(nm -g -C --format="posix" $@ | grep -c "^main T") -eq 1 ]; then echo "$(patsubst $(BUILD_ROOT)/%.o,%.$(CXXEXT),$@)" >> $(easymake_f_detected_entries) && echo "# main detected"; fi;

$(BUILD_ROOT)/%.o: %.$(CEXT)
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS)  -c -o $@ $(word 1,$^)
	@$(CC) -MM -MP -MF"$(@:.o=.d)" -MT"$@" $(CPPFLAGS) $(CFLAGS) $(word 1,$^) 
	@if [ ! -f $(easymake_f_detected_entries) ]; then echo " " > $(easymake_f_detected_entries); fi;
	@grep -v "^$(patsubst $(BUILD_ROOT)/%.o,%.$(CEXT),$@)$$" $(easymake_f_detected_entries) > $(BUILD_ROOT)/easymake_entries_tmp.d 
	@cp $(BUILD_ROOT)/easymake_entries_tmp.d $(easymake_f_detected_entries)
	@if [ $$(nm -g -C --format="posix" $@ | grep -c "^main T") -eq 1 ]; then echo "$(patsubst $(BUILD_ROOT)/%.o,%.$(CEXT),$@)" >> $(easymake_f_detected_entries) && echo "    # main detected"; fi;


##
# include all generated dependency files
#
ifneq ($(strip $(easymake_all_cppobjects)),)
    sinclude $(easymake_all_cppobjects:.o=.d)
endif
ifneq ($(strip $(easymake_all_cobjects)),)
    sinclude $(easymake_all_cobjects:.o=.d)
endif
sinclude $(wildcard $(easymake_f_targets_dep_prefix)_*)


# Read detected entries from file and filter out the unexisted.
easymake_entry_list = $(ENTRY_LIST) $(foreach file,$(call ReadSettings,$(easymake_f_detected_entries)),$(filter $(file),$(CXXSRC) $(CSRC)))

easymake_nontest_entry_list = $(filter-out %_test.$(CEXT),$(filter-out %_test.$(CXXEXT),$(easymake_entry_list)))
easymake_test_entry_list = $(filter %_test.$(CEXT),$(easymake_entry_list)) $(filter %_test.$(CXXEXT),$(easymake_entry_list))

easymake_get_entry      = $(if $(filter $(1),NONE)$(filter $(1),none),,$(call GetEntry,$(1),$(easymake_entry_list),"the ENTRY($(1)) is neither defined in the entry_list nor detected by easymake (e.g. $(1).cpp). detected values are $(easymake_entry_list)"))
easymake_get_cppsources = $(call FilterSourcesToLink , $(CXXSRC) , $(call easymake_get_entry,$(1)) , $(easymake_entry_list))
easymake_get_csources   = $(call FilterSourcesToLink , $(CSRC)   , $(call easymake_get_entry,$(1)) , $(easymake_entry_list))
easymake_get_objects    = $(call GetCorrendingObjects,$(call easymake_get_cppsources,$(1)),$(BUILD_ROOT),$(CXXEXT)) $(call GetCorrendingObjects,$(call easymake_get_csources,$(1)),$(BUILD_ROOT),$(CEXT))
easymake_check_so_target = $(if $(filter %.so,$(1)),NONE,$(1))

easymake_cmd_echo_and_exec = echo $(1) && $(1)
# param 1 the entry name
easymake_get_target = $(BUILD_ROOT)/$(notdir $(basename $(1)))

easymake_nontest_built_target_list = $(foreach e,$(easymake_nontest_built_entry_list),$(call IfFileExist,$(e),$(call easymake_get_target,$(e)),))

all: $(easymake_all_cppobjects) $(easymake_all_cobjects) $(easymake_nontest_built_target_list)
	@$(foreach e,$(filter-out $(easymake_nontest_built_entry_list),$(easymake_nontest_entry_list)),  echo -e "$(call easymake_get_target,$(e)): $(call easymake_get_objects,$(e))\neasymake_nontest_built_entry_list+=$(e)" > $(easymake_f_targets_dep_prefix)_$(notdir $(call easymake_get_target,$(e))).d ; ) true
	@$(foreach e,$(filter-out $(easymake_nontest_built_entry_list),$(easymake_nontest_entry_list)), $(call easymake_cmd_echo_and_exec, $(easymake_linker) -o $(call easymake_get_target,$(e)) $(call easymake_get_objects,$(e)) $(LDFLAGS)) && ) true

$(filter-out $(easymake_nontest_built_target_list),$(filter-out all %.so %.a,$(easymake_build_goals))): $(easymake_all_cppobjects) $(easymake_all_cobjects)
$(filter-out $(easymake_nontest_built_target_list),$(filter-out all %.so %.a,$(easymake_build_goals))) $(filter-out %.so,$(easymake_nontest_built_target_list)):
	@echo 
	@echo -e "$@: $(call easymake_get_objects,$(call easymake_check_so_target,$(notdir $@)))\neasymake_nontest_built_entry_list+=$(call easymake_get_entry,$(call easymake_check_so_target,$(notdir $@)))" > $(easymake_f_targets_dep_prefix)_$(notdir $@).d
	$(easymake_linker) $(LDFLAGS) -o $@ $(call easymake_get_objects,$(call easymake_check_so_target,$(notdir $@))) $(LOADLIBES) $(LDLIBS)

$(BUILD_ROOT)/%.so: $(easymake_all_cppobjects) $(easymake_all_cobjects)
	@echo 
	@echo -e "$@: $(call easymake_get_objects,NONE)\neasymake_nontest_built_entry_list+=$(call easymake_get_entry,NONE)" > $(easymake_f_targets_dep_prefix)_$(notdir $@).d
	$(easymake_linker) $(LDFLAGS) -o $@ $(call easymake_get_objects,NONE) $(LOADLIBES) $(LDLIBS)

$(BUILD_ROOT)/%.a: $(easymake_all_cppobjects) $(easymake_all_cobjects)
	@echo
#	@echo -e "$@: $(call easymake_get_objects,NONE)\neasymake_nontest_built_entry_list+=$(call easymake_get_entry,NONE)" > $(easymake_f_targets_dep_prefix)_$(notdir $@).d
	$(AR) $(ARFLAGS) $@ $(call easymake_get_objects,NONE)

# "check" is the standard target from standard makefile conventions
check: test
check:

test: $(easymake_all_cppobjects) $(easymake_all_cobjects)
	@$(foreach e, $(easymake_test_entry_list), $(call easymake_cmd_echo_and_exec, $(easymake_linker) -o $(call easymake_get_target,$(e)) $(call easymake_get_objects,$(e)) $(LDFLAGS))  && ) true
	@echo 
	@cnt=0; failed=0; $(foreach e,$(easymake_test_entry_list), echo '# run [$(call easymake_get_target,$(e))]' && { $(call easymake_get_target,$(e)) 2>&1 | sed "s/^/  # /g" 2>/dev/null; ret=$${PIPESTATUS[0]}; if [[ $$ret != 0 ]]; then echo "# test [$(call easymake_get_target,$(e))] failed [$$ret]"; failed=$$((failed+1));  fi; cnt=$$((cnt+1)); true; } 2>/dev/null && ) { echo "# $$cnt test complete. $$failed failed test."; }


