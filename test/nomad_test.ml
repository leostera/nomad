[@@@warning "-8"]

open Riot

let main () =
  Riot__Logs.set_log_level (Some Trace);
  Riot.Net.Socket.Logger.set_log_level (Some Trace);
  Caravan.Logger.set_log_level (Some Trace);
  Logger.set_log_level (Some Trace);
  let (Ok _) = Logger.start ~print_source:true () in
  sleep 0.1;
  Logger.info (fun f -> f "starting nomad caravan");

  let handler conn req =
    Logger.info (fun f -> f "req: %a" Http.Request.pp req);
    let status = `OK in
    let body = "hello world" in
    let headers =
      Http.Header.of_list
        [
          ("content-length", body |> String.length |> string_of_int);
          ("connection", "close");
        ]
    in

    let res = Http.Response.make ~version:req.version ~status ~headers () in
    let res = Nomad.Http1.to_string res body in
    Logger.info (fun f -> f "res:\n%s" (Bigstringaf.to_string res));
    let bytes = Caravan.Socket.send conn res |> Result.get_ok in
    Logger.info (fun f -> f "wrote %d bytes" bytes);
    ()
  in

  let (Ok pid) =
    Caravan.start_link ~port:2112 ~acceptor_count:1
      (module Nomad.Caravan_handler)
      { buffer = Bigstringaf.empty; handler }
  in
  wait_pids [ pid ]

let () = Riot.run ~workers:0 @@ main
