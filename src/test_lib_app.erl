%%%-------------------------------------------------------------------
%% @doc test_lib public API
%% @end
%%%-------------------------------------------------------------------

-module(test_lib_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    test_lib_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
