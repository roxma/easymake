################################################################
# Copyright (c) 2017 roxma@qq.com
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


# A simple third-party dependency management tool for c/c++ project
#
# Usage:
#
#     DEP_PREFIX  ?= dep
#     include ./make/dep.mk
#     all:
#     	mkdir -p $(DEP_PREFIX)
#     	$(call DEP_MAKE,fmt)
#
# ./make/module.fmt.mk:
#
#     all: $(PREFIX)/include/fmt/format.h
#     
#     $(PREFIX)/include/fmt/format.h:
#     	if [ ! -d fmt ]; then git clone --depth 1 git@github.com:fmtlib/fmt.git; fi
#     	cd fmt && cmake  . -DCMAKE_INSTALL_PREFIX=$(PREFIX)
#     	make -C fmt
#     	make -C fmt install

_DEP_PATH:= $(abspath $(lastword $(MAKEFILE_LIST)))


DEP_PREFIX  ?= dep
DEP_BUILD   ?= $(DEP_PREFIX)/build/

_DEP_GET_NAME ?= $(if $2,$2,$(notdir $(basename $(basename $1))))

DEP_MAKE= 			\
		mkdir -p 	\
			"$(DEP_BUILD)/$(call _DEP_GET_NAME,$1,$2)" 		\
			"$(DEP_PREFIX)" && 								\
		$(MAKE) 											\
			-C "$(DEP_BUILD)/$(call _DEP_GET_NAME,$1,$2)" 	\
			-I $(abspath .)							\
			-I $(dir $(abspath $1))					\
			"DEP_NAME=$(call _DEP_GET_NAME,$1,$2)"	\
		 	"DEP_MODULE=$1" 						\
			"DEP_BUILD=$(abspath $(DEP_BUILD))"		\
			"DEP_PREFIX=$(abspath $(DEP_PREFIX))"	\
			-f "$(_DEP_PATH)" && 					\
		cd "$(DEP_PREFIX)/stow" && stow $(call _DEP_GET_NAME,$1,$2)

# DEP_CLEAN=rm -rf $(DEP_BUILD)/$(1); if [ -d $(DEP_PREFIX)/stow/$(1) ]; then cd $(DEP_PREFIX)/stow && stow --delete $(1) && rm -rf $(1) ; fi

# depdownload url,filename,sha256sum
DEP_DOWNLOAD= @echo "-- downloading $1 to $2";		\
	chk=$(firstword $(subst =, ,$3)); 				\
	sum=$(lastword $(subst =, ,$3)); 				\
	cdir=~/.cache/easymake;							\
	cfile="$$cdir/$(notdir $2)-$$sum-$$chk";	\
	if [ -f "$$cfile" ]; then						\
		echo "   [$2] cached as $$cfile";			\
		cp $$cfile $2;								\
	fi;												\
	echo "$$sum $2" > "$2.$$chk"; 					\
	if ! $$chk -c "$2.$$chk" 1>/dev/null 2>&1; then	\
		echo wget -O $2 "$1";$$chk -c "$2.$$chk";	\
		wget -O $2 "$1" &&							\
		mkdir -p $$cdir &&							\
		$$chk -c "$2.$$chk" && cp $2 $$cfile;		\
	else											\
		echo "   [$2] already downloaded";			\
	fi

# git repo, clone_to, commit sha
DEP_GIT=@				\
		cdir=~/.cache/easymake;				\
		cfile="$$cdir/$(notdir $2)-$3";		\
		echo "-- cloning $1 [$3] to $2"	&&	\
		if [ ! -d "$$cfile" ]; then			\
			rm -rf "$2" &&					\
			git clone "$1" "$2" &&			\
			cd "$2" &&						\
			echo "-- git" reset --hard "$3" &&	\
			git reset --hard "$3" &&		\
			cp -r . "$$cfile";				\
		else								\
			echo "   [$1] cached as $$cfile";	\
			cp -r $$cfile $2;					\
		fi


# TODO: implement DEP_GIT with caching

# TODO: support loading of pkgconfig for CXXFLAGS, CFLAGS ?

ifneq ($(DEP_MODULE),)
  PREFIX=$(abspath $(DEP_PREFIX)/stow/$(DEP_NAME))
  include $(DEP_MODULE)
endif

