%%%-------------------------------------------------------------------
%%% @author Jack Tang <himars@gmail.com>
%%% @copyright (C) 2014, Jack Tang
%%% @doc
%%%
%%% @end
%%% Created : 18 Oct 2014 by Jack Tang <himars@gmail.com>
%%%-------------------------------------------------------------------
-module(erl_notify_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    application_utils:start_supervisor(?MODULE, erl_notify_sup, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%%
%% @spec init(Args) -> {ok, {SupFlags, [ChildSpec]}} |
%%                     ignore |
%%                     {error, Reason}
%% @end
%%--------------------------------------------------------------------
init([erl_notify_sup]) ->
    application_utils:one4one_supervisor([]);

init(_Args) ->
    ok.

%%%===================================================================
%%% Internal functions
%%%===================================================================
