open OUnit2
open Imap_types
open Imap_uint

let examples = [
  "* OK [HIGHESTMODSEQ 715194045007]", `OK (`HIGHESTMODSEQ (Uint64.of_string "715194045007"), "");
  "* OK [NOMODSEQ] Sorry, this mailbox format doesn't support modsequences",
  `OK (`NOMODSEQ, "Sorry, this mailbox format doesn't support modsequences");
  "* 4 FETCH (UID 8 MODSEQ (12121130956))",
  `FETCH (Uint32.of_int 4, [`UID (Uint32.of_int 8); `MODSEQ (Uint64.of_string "12121130956")]);
  "d105 OK [MODIFIED 7,9] Conditional STORE failed",
  `TAGGED ("d105", `OK (`MODIFIED
                          (Imap_set.(union
                                      (singleton (Uint32.of_int 7))
                                      (singleton (Uint32.of_int 9)))),
                        "Conditional STORE failed"));
  "* SEARCH 2 5 6 7 11 12 18 19 20 23 (MODSEQ 917162500)",
  `SEARCH (List.map Uint32.of_int [2; 5; 6; 7; 11; 12; 18; 19; 20; 23],
           (Uint64.of_string "917162500"));
  "* STATUS blurdybloop (MESSAGES 231 HIGHESTMODSEQ 7011231777)",
  `STATUS {st_mailbox = "blurdybloop";
           st_info_list = [`MESSAGES 231; `HIGHESTMODSEQ (Uint64.of_string "7011231777")]}
]

let test_parser ~ctxt s check =
  match Imap_parser.parse Imap_response.cont_req_or_resp_data_or_resp_done s with
  | `Ok x ->
    let pp fmt x =
      Sexplib.Sexp.pp_hum fmt (Imap_response.sexp_of_cont_req_or_resp_data_or_resp_done x)
    in
    assert_equal ~ctxt ~msg:s ~pp_diff:(fun fmt (x, check) ->
        Format.fprintf fmt "@[EXPECTED: @[%a@]@\nGOT: @[%a@]@]@."
          pp x pp check) x check
  | `Fail i -> failwith (Printf.sprintf "test_parser: %S near %d" s i)
  | `Exn exn -> raise exn

let test_responses =
  List.map (fun (ex, check) ->
      test_case (fun ctxt -> test_parser ~ctxt (ex ^ "\r\n") check))
    examples

let suite =
  "test_condstore" >:::
  [
    "test_parser" >::: test_responses
  ]

let () =
  run_test_tt_main suite
