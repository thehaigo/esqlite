PROJECT = esqlite
DIALYZER = dialyzer

ERL       ?= erl
REBAR3 := $(shell which rebar3 2>/dev/null || echo ./rebar3)
REBAR3_VERSION := 3.23.0
REBAR3_URL := https://github.com/erlang/rebar3/releases/download/$(REBAR3_VERSION)/rebar3

ifeq (,$(STATIC_ERLANG_NIF))
all: compile
else
all: priv/esqlite3_nif.a
ERTS_INCLUDE_DIR ?= $(shell erl -noshell -s init stop -eval "io:format(\"~s/erts-~s/include/\", [code:root_dir(), erlang:system_info(version)]).")
CFLAGS += -DSTATIC_ERLANG_NIF=1 -I"$(ERTS_INCLUDE_DIR)"
CFLAGS += -DSQLITE_THREADSAFE=1 -DSQLITE_USE_URI -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS
OBJS = c_src/esqlite3_nif.c c_src/queue.c c_src/sqlite3/sqlite3.c
RANLIB ?= ranlib
ARFLAGS ?= rc
endif

priv/esqlite3_nif.a: $(OBJS:.c=.o)
	mkdir -p $(dir $@)
	$(AR) $(ARFLAGS) $@ $^
	$(RANLIB) $@

$(REBAR3):
	$(ERL) -noshell -s inets -s ssl \
	 -eval '{ok, saved_to_file} = httpc:request(get, {"$(REBAR3_URL)", []}, [], [{stream, "./rebar3"}])' \
	 -s init stop
	chmod +x ./rebar3

compile: $(REBAR3)
	$(REBAR3) compile

test: compile
	$(REBAR3) eunit

clean: $(REBAR3)
	$(REBAR3) clean

distclean:
	rm $(REBAR3)

# dializer

build-plt:
	@$(DIALYZER) --build_plt --output_plt .$(PROJECT).plt \
		--apps kernel stdlib

dialyze:
	@$(DIALYZER) --src src --plt .$(PROJECT).plt --no_native \
		-Werror_handling -Wrace_conditions -Wunmatched_returns -Wunderspecs

