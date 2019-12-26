SRC := $(wildcard day*.dart)
EXE := $(patsubst %.dart,bin/%,$(SRC))

all: $(EXE)

bin/%: gen/%.dart gen/util.dart gen/intcode.dart
	@mkdir -p bin
	dart2native $< -o $@

gen/%.dart: %.dart bin/denull
	@mkdir -p gen
	cp $< $@ && bin/denull $@

bin/denull: denull.dart
	@mkdir -p bin
	dart2native -o $@ $<

clean:
	rm -rf bin gen

.PHONY: all clean
.PRECIOUS: gen/%.dart
