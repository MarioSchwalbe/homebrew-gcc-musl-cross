#!/usr/bin/env false

# vim: set tabstop=8 shiftwidth=8 noexpandtab:

.DELETE_ON_ERROR:

V        ?= 9
SUFFIX   := g++-$(V)
BIN_DIR  := $(wildcard /usr/local/Cellar/gcc-$(V)-musl-cross/*/bin)
TARGETS  := $(sort $(patsubst %-$(SUFFIX), %, $(notdir $(wildcard $(BIN_DIR)/*-$(SUFFIX)))))
TESTS    := $(addprefix test-, $(TARGETS))
FORMULAS := $(sort $(wildcard *.rb))

CXXFLAGS := -Os -Wall -Wextra
LDFLAGS  := -static -s

.DEFAULT_GOAL := default

$(TESTS):  CXX = $(BIN_DIR)/$(patsubst test-%,%-$(SUFFIX),$@)
$(TESTS):  test.cpp Makefile
	$(LINK.cc) $< $(LDLIBS) -o $@

TEST_HOST := mario@sylvester

$(TESTS:=.out):
%.out:  %
	rsync $< $(TEST_HOST):/tmp
	set -o pipefail && ssh $(TEST_HOST) -- /tmp/$(notdir $<) | tee $@

DOCKERFILE := Dockerfile.alpine
# DOCKERFILE := Dockerfile.scratch
# DOCKER_RUN_FLAGS := -v /bin/static-sh:/bin/sh:ro

$(TESTS:=.dock):
%.dock: % $(DOCKERFILE)
	@chmod 755 $<
	docker build -f $(DOCKERFILE) --build-arg TEST=$< --tag $* .
	set -o pipefail && docker run $$(cat qemu-static) --rm $(DOCKER_RUN_FLAGS) $* | tee $@

default::  $(TESTS)
run::      $(TESTS:=.out)
docker::   $(TESTS:=.dock)

file::  $(TESTS)
	@file $^

RemoveDockerImages::
	docker image rm $(TESTS) || true
	docker system prune --force
	docker image ls

RebuildAndTestAll::  $(FORMULAS)
	brew uninstall $^ || true
	brew fetch --build-from-source $^
	$(if $(J),HOMEBREW_MAKE_JOBS=$(J)) brew install --with-all-targets $^
	brew test $^

cmp::	$(FORMULAS)
	@colordiff -urp --from-file=$< $^ || true

audit:: $(FORMULAS)
	chmod 644 $^
	brew audit --strict $^ || true

clean::
	$(RM) $(wildcard $(TESTS:=.out) $(TESTS:=.dock))

distclean::  clean
	$(RM) $(wildcard $(TESTS))

# ***** end of source *****
