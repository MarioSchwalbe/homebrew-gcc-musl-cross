#!/usr/bin/env false

# vim: set tabstop=8 shiftwidth=8 noexpandtab:

# BIN_DIR := /usr/local/opt/gcc-musl-cross/bin
BIN_DIR := /usr/local/Cellar/gcc-musl-cross/7.2.0/bin

TARGETS := $(patsubst %-gcc, %, $(notdir $(wildcard $(BIN_DIR)/*-gcc)))
TESTS   := $(addprefix test-, $(TARGETS))

CFLAGS  := -Os -Wall -Wextra
LDFLAGS := -static

.DEFAULT_GOAL := default

$(TESTS):  CC = $(BIN_DIR)/$(patsubst test-%,%,$@)-gcc
$(TESTS):  test.c
	$(LINK.c) $^ $(LDLIBS) -o $@

%.out:	%
	$< > $@

default::  $(TESTS)
run::      $(TESTS:=.out)

file::  $(TESTS)
	@file $^

installsize:: $(abspath $(BIN_DIR)/..)
	du -sh $<

audit:: gcc-musl-cross.rb
	brew audit --strict $<
	brew audit --new-formula $<

clean::
	$(RM) $(wildcard $(TESTS:=.out))

distclean::  clean
	$(RM) $(wildcard $(TESTS))

# ***** end of source *****
