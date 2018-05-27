#!/usr/bin/env false

# vim: set tabstop=8 shiftwidth=8 noexpandtab:

# BIN_DIR := /usr/local/opt/gcc-musl-cross/bin
BIN_DIR := /usr/local/Cellar/gcc-musl-cross/7.2.0/bin

TARGETS := $(patsubst %-gcc-7, %, $(notdir $(wildcard $(BIN_DIR)/*-gcc-7)))
TESTS   := $(addprefix test-, $(TARGETS))

CFLAGS  := -Os -Wall -Wextra
LDFLAGS := -static

.DEFAULT_GOAL := default

$(TESTS):  CC = $(BIN_DIR)/$(patsubst test-%,%-gcc-7,$@)
$(TESTS):  test.c
	$(LINK.c) $^ $(LDLIBS) -o $@

# DOCKER_RUN_FLAGS := -v /bin/bash-static:/bin/sh:ro

$(TESTS:=.out):
%.out:	% Dockerfile
	chmod 755 $*
	docker build --build-arg APP=$* --tag $* .
	docker run $$(cat qemu-static) --rm $(DOCKER_RUN_FLAGS) --name $* $* | tee $@

default::  $(TESTS)
run::      $(TESTS:=.out)

file::  $(TESTS)
	@file $^

audit:: gcc-musl-cross.rb
	brew audit --strict $<
	brew audit --new-formula $<

clean::
	$(RM) $(wildcard $(TESTS:=.out))

distclean::  clean
	$(RM) $(wildcard $(TESTS))

# ***** end of source *****
