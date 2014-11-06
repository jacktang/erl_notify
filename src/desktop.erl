%%%-------------------------------------------------------------------
%%% @author Jack Tang <jack@taodi.local>
%%% @copyright (C) 2014, Jack Tang
%%% @doc
%%%
%%% @end
%%% Created : 18 Oct 2014 by Jack Tang <jack@taodi.local>
%%%-------------------------------------------------------------------
-module(desktop).

%% API
-export([notify_success/1, notify_success/2]).
-export([notify_errors/1, notify_errors/2]).
-export([notify_warnings/1, notify_warnings/2]).

%%%===================================================================
%%% API
%%%===================================================================
notify_success(Message) ->
    notify_success("Success!", Message).

notify_success(Title, Message) ->
    growl("success", Title, Message).


notify_errors(Message) ->
    growl("errors", "Errors...", Message).

notify_errors(Title, Message) ->
    growl("errors", Title, Message).

notify_warnings(Message) ->
    growl("warnings", "Warnings", Message).

notify_warnings(Title, Message) ->
    growl("warnings", Title, Message).

%%%===================================================================
%%% Internal functions
%%%===================================================================
growl(Image, Title, Message) ->
    ImagePath = filename:join([filename:dirname(code:which(erl_notify)), "..", "icons", Image]) ++ ".png",
    Cmd = case application:get_env(erl_notify, executable, auto) of
              auto ->
                  case os:type() of
                      {win32, _} ->
                          make_cmd("notifu", ImagePath, Title, Message);
                      {unix,linux} ->
                          % debian notify-send issue:
                          % http://askubuntu.com/questions/52960/notify-send-does-nothing-yet-libnotify-is-installed
                          make_cmd("notify-send", ImagePath, Title, Message);
                      _ ->
                          make_cmd("growlnotify", ImagePath, Title, Message)
                  end;
              Executable ->
                  make_cmd(Executable, ImagePath, Title, Message)
          end,
    os:cmd(lists:flatten(Cmd)).

make_cmd(Util, Image, Title, Message) when is_atom(Util) ->
    make_cmd(atom_to_list(Util), Image, Title, Message);

make_cmd("growlnotify" = Util, Image, Title, Message) ->
    [Util, " -n \"ErlNotify\" --image \"", Image,"\"",
     " -m \"", Message, "\" \"", Title, "\""];

make_cmd("notification_center" = _Util, _Image, Title, Message) ->
    AppleScript = io_lib:format("display notification \"~s\" with title \"~s\"", [Message, Title]),
    io_lib:format("osascript -e '~s'", [AppleScript]);

make_cmd("notify-send" = Util, Image, Title, Message) ->
    [Util, " -i \"", Image, "\"",
     " \"", Title, "\" \"", Message, "\" --expire-time=5000"];

make_cmd("notifu" = Util, Image, Title, Message) ->
    %% see http://www.paralint.com/projects/notifu/
    [Util, " /q /d 5000 /t ", image2notifu_type(Image), " ",
     "/p \"", Title, "\" /m \"", Message, "\""];

make_cmd("emacsclient" = Util, "warnings", Title, Message0) ->
    Message = lisp_format(Message0),
    io_lib:format("~s --eval \"(mapc (lambda (m) (lwarn \\\"sync: ~s\\\" :warning m)) (list ~s))\"",
                  [Util, Title, Message]);
make_cmd("emacsclient" = Util, "errors", Title, Message0) ->
    Message = lisp_format(Message0),
    io_lib:format("~s --eval \"(mapc (lambda (m) (lwarn \\\"sync: ~s\\\" :error m)) (list ~s))\"",
                  [Util, Title, Message]);
make_cmd("emacsclient" = Util, _, Title, Message0) ->
    Message = replace_chars(Message0, [{$\n, "\\n"}]),
    io_lib:format("~s --eval \"(message \\\"[sync] ~s: ~s\\\")\"",
                  [Util, Title, Message]);

make_cmd(UnsupportedUtil, _, _, _) ->
    error('unsupported-sync-executable',
           lists:flatten(io_lib:format("'sync' application environment variable "
                                       "named 'executable' has unsupported value: ~p",
                                       [UnsupportedUtil]))).

image2notifu_type("success") -> "info";
image2notifu_type("warnings") -> "warn";
image2notifu_type("errors") -> "error".


%% Return a new string with chars replaced.
%% @spec replace_chars(iolist(), [{char(), char() | string()}] -> iolist().
replace_chars(String, Tab) ->
    lists:map(fun (C) ->
                      proplists:get_value(C, Tab, C)
              end,
              lists:flatten(String)).

%% Return a new string constructed of source lines double quoted and
%% delimited by space.
%% spec lisp_format(StringOfLines :: iolist()) -> string().
lisp_format(String0) ->
    String1 = lists:flatten(String0),
    Lines1 = string:tokens(String1, [$\n]),
    String2 = string:join(Lines1, "\\\" \\\""),
    lists:flatten(["\\\"", String2, "\\\""]).
