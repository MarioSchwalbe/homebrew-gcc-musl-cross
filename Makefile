#!/usr/bin/env false

# vim: set tabstop=8 shiftwidth=8 noexpandtab:

.DELETE_ON_ERROR:
SHELL   := /bin/bash

SUFFIX  := g++-8
BIN_DIR := /usr/local/opt/gcc-8-musl-cross/bin
TARGETS := $(sort $(patsubst %-$(SUFFIX), %, $(notdir $(wildcard $(BIN_DIR)/*-$(SUFFIX)))))
TESTS   := $(addprefix test-, $(TARGETS))

CXXFLAGS := -Os -Wall -Wextra
LDFLAGS  := -static -s

.DEFAULT_GOAL := default

$(TESTS):  CXX = $(BIN_DIR)/$(patsubst test-%,%-$(SUFFIX),$@)
$(TESTS):  test.cpp Makefile
	$(LINK.cc) $< $(LDLIBS) -o $@

TEST_HOST := mario@sylvester

$(TESTS:=.out):
%.out:  %
	@rsync $< $(TEST_HOST):/tmp
	set -o pipefail && ssh $(TEST_HOST) -- /tmp/$(notdir $<) | tee $@

DOCKERFILE := Dockerfile.alpine
# DOCKER_RUN_FLAGS := -v /bin/static-sh:/bin/sh:ro

$(TESTS:=.dock):
%.dock: % $(DOCKERFILE)
	@chmod 755 $<
	docker build -f $(DOCKERFILE) --build-arg APP=$< --tag $* .
	set -o pipefail && docker run $$(cat qemu-static) --rm $(DOCKER_RUN_FLAGS) $* | tee $@

default::  $(TESTS)
run::      $(TESTS:=.out)
docker::   $(TESTS:=.dock)

docker-image-rm::  $(TESTS)
	docker image rm $^ || true

file::  $(TESTS)
	@file $^

audit:: gcc-8-musl-cross.rb
	chmod 644 $<
	brew audit --strict $< || true
	brew audit --new-formula $<

clean::
	$(RM) $(wildcard $(TESTS:=.out) $(TESTS:=.dock))

distclean::  clean
	$(RM) $(wildcard $(TESTS))

# ***** end of source *****
