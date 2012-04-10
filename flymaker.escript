#!/usr/bin/env escript
-export([main/1]).

main([Filename]) ->
  compile:file(Filename, [ warn_obsolete_guard
                         , warn_unused_import
                         , warn_shadow_vars
                         , warn_export_vars
                         , strong_validation
                         , report
                         , {i, "../include"}
                         , nowarn_unused_function
                         , nowarn_unused_vars
                         , nowarn_unused_record
                         ]).