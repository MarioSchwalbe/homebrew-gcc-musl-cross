#!/usr/bin/env false

# vim: set tabstop=8 shiftwidth=8 noexpandtab:

.DELETE_ON_ERROR:
SHELL   := /bin/bash

BIN_DIR := /usr/local/opt/gcc-musl-cross/bin
# BIN_DIR := /usr/local/Cellar/gcc-musl-cross/8.3.0/bin

SUFFIX  := gcc-8
TARGETS := $(sort $(patsubst %-ld, %, $(notdir $(wildcard $(BIN_DIR)/*-ld))))
TESTS   := $(addprefix test-, $(TARGETS))

CFLAGS  := -Os -Wall -Wextra
LDFLAGS := -static

.DEFAULT_GOAL := default

$(TESTS):  CC = $(BIN_DIR)/$(patsubst test-%,%-$(SUFFIX),$@)
$(TESTS):  test.c Makefile
	$(LINK.c) $< $(LDLIBS) -o $@

TEST_HOST := mario@sylvester

$(TESTS:=.out):
%.out:  %
	@rsync $* $(TEST_HOST):/tmp
	set -o pipefail && ssh $(TEST_HOST) -- /tmp/$(notdir $*) | tee $@

DOCKERFILE := Dockerfile.alpine
# DOCKER_RUN_FLAGS := -v /bin/static-sh:/bin/sh:ro

$(TESTS:=.dock):
%.dock: % $(DOCKERFILE)
	@chmod 755 $*
	docker build -f $(DOCKERFILE) --build-arg APP=$* --tag $* .
	set -o pipefail && docker run $$(cat qemu-static) --rm $(DOCKER_RUN_FLAGS) $* | tee $@

default::  $(TESTS)
run::      $(TESTS:=.out)
docker::   $(TESTS:=.dock)

docker-image-rm::  $(TESTS)
	docker image rm $^ || true

file::  $(TESTS)
	@file $^

audit:: gcc-musl-cross.rb
	chmod 644 $<
	brew audit --strict $<
	brew audit --new-formula $<

clean::
	$(RM) $(wildcard $(TESTS:=.out) $(TESTS:=.dock))

distclean::  clean
	$(RM) $(wildcard $(TESTS))

# ***** end of source *****
