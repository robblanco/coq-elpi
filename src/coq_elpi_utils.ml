(* coq-elpi: Coq terms as the object language of elpi                        *)
(* license: GNU Lesser General Public License Version 2.1 or later           *)
(* ------------------------------------------------------------------------- *)

module API = Elpi.API

let of_coq_loc l = {
  API.Ast.Loc.source_name =
    (match l.Loc.fname with Loc.InFile x -> x | Loc.ToplevelInput -> "(stdin)");
  source_start = l.Loc.bp;
  source_stop = l.Loc.ep;
  line = l.Loc.line_nb;
  line_starts_at = l.Loc.bol_pos;
}
let to_coq_loc {
  API.Ast.Loc.source_name = source_name;
  line = line;
  line_starts_at = line_starts_at;
  source_start = source_start;
  source_stop = source_stop;
} = Loc.create (Loc.InFile source_name) line line_starts_at source_start source_stop

let err ?loc msg =
  let loc = Option.map to_coq_loc loc in
  CErrors.user_err ~hdr:"elpi" ?loc msg

let feedback_fmt_write, feedback_fmt_flush =
  let b = Buffer.create 2014 in
  Buffer.add_substring b,
  (fun () ->
     let s = Buffer.to_bytes b in
     let s =
       let len = Bytes.length s in
       if len > 0 && Bytes.get s (len - 1) = '\n'
       then Bytes.sub_string s 0 (len - 1)
       else Bytes.to_string s in
     Feedback.msg_info Pp.(str s);
     Buffer.clear b)

let () = API.Setup.set_error (fun ?loc s -> err ?loc Pp.(str s))
let () = API.Setup.set_anomaly (fun ?loc s -> err ?loc Pp.(str s))
let () = API.Setup.set_type_error (fun ?loc s -> err ?loc Pp.(str s))
let warn = CWarnings.create ~name:"runtime" ~category:"elpi" Pp.str
let () = API.Setup.set_warn (fun ?loc x -> warn ?loc:(Option.map to_coq_loc loc) x)
let () = API.Setup.set_std_formatter (Format.make_formatter feedback_fmt_write feedback_fmt_flush)
let () = API.Setup.set_err_formatter (Format.make_formatter feedback_fmt_write feedback_fmt_flush)


let nYI s = err Pp.(str"Not Yet Implemented: " ++ str s)

let pp2string pp x =
  let b = Buffer.create 80 in
  let fmt = Format.formatter_of_buffer b in
  Format.fprintf fmt "%a%!" pp x;
  Buffer.contents b

module C = Constr
module EC = EConstr

let safe_destApp sigma t =
  match EC.kind sigma t with
  | C.App(hd,args) -> EC.kind sigma hd, args
  | x -> x, [||]

let mkGHole =
  DAst.make
    (Glob_term.GHole(Evar_kinds.InternalHole,Namegen.IntroAnonymous,None))

let mkApp ~depth t l =
  match l with
  | [] -> t
  | x :: xs ->
    match API.RawData.look ~depth t with
    | API.RawData.Const c -> API.RawData.mkApp c x xs
    | _ -> assert false

let string_split_on_char c s =
  let len = String.length s in
  let rec aux n x =
    if x = len then [String.sub s n (x-n)]
    else if s.[x] = c then String.sub s n (x-n) :: aux (x+1) (x+1)
    else aux n (x+1)
  in
    aux 0 0

