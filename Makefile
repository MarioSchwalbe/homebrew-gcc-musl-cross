#!/usr/bin/env false

# vim: set tabstop=8 shiftwidth=8 noexpandtab:

BIN_DIR := /usr/local/opt/gcc-musl-cross/bin
BIN_DIR := /usr/local/Cellar/gcc-musl-cross/0.9.7/libexec/bin

TARGETS := $(patsubst %-gcc, %, $(notdir $(wildcard $(BIN_DIR)/*-gcc)))
TESTS   := $(addprefix hello-, $(TARGETS))

CFLAGS  := -O3 -Wall -Wextra
LDFLAGS := -static

%.out:	%
	$< > $@

hello-%: CC = $(BIN_DIR)/$*-gcc
hello-%: hello.c
	$(LINK.c) $^ $(LDLIBS) -o $@

default:: $(TESTS)
run::     $(TESTS:=.out)

file:: $(TESTS)
	@file $^

installsize:: $(abspath $(BIN_DIR)/../..)
	du -sh $<

gcc-musl-cross.diff: musl-cross/musl-cross.rb gcc-musl-cross.rb
	colordiff -urp $(if $(W),,-w) $^ > $@ || true

audit::   gcc-musl-cross.rb
	brew audit --strict $<
	brew audit --new-formula $<

clean distclean::
	$(RM) $(TESTS) *.out *.diff

# ***** end of source *****
