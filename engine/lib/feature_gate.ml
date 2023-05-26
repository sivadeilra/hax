open Base
open Utils

module DefaultSubtype = struct
  type error = Err [@@deriving show, yojson, eq]

  exception E of error

  let reject (type a b) : a -> b = fun _ -> raise @@ E Err

  include Features.SUBTYPE.Id

  let explain : error -> Features.Enumeration.t -> string =
   fun _ _ -> "unknown reason"
end

module%inlined_contents MakeExn
    (FA : Features.T)
    (FB : Features.T)
    (S0 : Features.SUBTYPE.T_Exn with module A = FA and module B = FB) =
struct
  open Ast
  module A = Ast.Make (FA)
  module B = Ast.Make (FB)
  module S = Features.SUBTYPE.WrapExns (S0)
  module FA = FA

  type ast_chunk = Item of A.item | Expr of A.expr | Ty of A.ty | Pat of A.pat
  [@@deriving show, yojson, eq]

  module Data = struct
    type t = { data : S.error; path : ast_chunk Non_empty_list.t }
    [@@deriving show, yojson, eq]

    let add (x : t) (chunk : ast_chunk) : t =
      { x with path = Non_empty_list.(append x.path [ chunk ]) }

    let ret (data : S.error) (chunk : ast_chunk) =
      { data; path = Non_empty_list.[ chunk ] }

    let item (x : t) : A.item =
      Non_empty_list.find_map_exn
        ~f:(function Item x -> Some x | _ -> None)
        x.path

    let span (x : t) : span =
      Non_empty_list.find_map_exn
        ~f:(function
          | Item x -> Some x.span
          | Expr x -> Some x.span
          | Pat x -> Some x.span
          | _ -> None)
        x.path
  end

  exception E of Data.t

  let raise x = raise (E x)

  module Implem : sig
    val dty : span -> A.ty -> B.ty
    val dpat : A.pat -> B.pat
    val dexpr : A.expr -> B.expr
    val ditem : A.item -> B.item list
  end = struct
    [%%inline_defs dmutability]

    let rec dty (span : span) (ty : A.ty) : B.ty =
      try [%inline_body dty] span ty with
      | S.E err -> raise @@ Data.ret err @@ Ty ty
      | E data -> raise @@ Data.add data @@ Ty ty

    and dgeneric_value = [%inline_body dgeneric_value]

    let dborrow_kind = [%inline_body dborrow_kind]

    let rec dpat (pat : A.pat) : B.pat =
      try [%inline_body dpat] pat with
      | S.E err -> raise @@ Data.ret err @@ Pat pat
      | E data -> raise @@ Data.add data @@ Pat pat

    and dpat' = [%inline_body dpat']
    and dfield_pat = [%inline_body dfield_pat]
    and dbinding_mode = [%inline_body dbinding_mode]
    and dsupported_monads = [%inline_body dsupported_monads]

    let rec dexpr (expr : A.expr) : B.expr =
      try [%inline_body dexpr] expr with
      | S.E err -> raise @@ Data.ret err @@ Expr expr
      | E data -> raise @@ Data.add data @@ Expr expr

    and dexpr' = [%inline_body dexpr']
    and dloop_kind = [%inline_body dloop_kind]
    and dloop_state = [%inline_body dloop_state]
    and darm = [%inline_body darm]
    and darm' = [%inline_body darm']
    and dlhs = [%inline_body dlhs]

    [%%inline_defs "Item.*" - ditem - ditem']

    let rec ditem (item : A.item) : B.item list =
      try [%inline_body ditem] item with
      | S.E err -> raise @@ Data.ret err @@ Item item
      | E data -> raise @@ Data.add data @@ Item item

    and ditem' = [%inline_body ditem']
  end

  include Implem
end
[@@add "subtype.ml"]

module%inlined_contents Make
    (FA : Features.T)
    (FB : Features.T)
    (S0 : sig
      include Features.SUBTYPE.T_Exn

      val explain : error -> Features.Enumeration.t -> string
      val metadata : Phase_utils.Metadata.t
    end
    with module A = FA
     and module B = FB) =
struct
  include MakeExn (FA) (FB) (S0)
  open Ast
  include Phase_utils.DefaultError

  let catch (type a b) (f : a -> b) (x : a) : b =
    try f x
    with E data ->
      Caml.raise
      @@ Error.E
           {
             kind =
               ExplicitRejection
                 { reason = S0.explain (fst data.data) (snd data.data) };
             span = Data.span data;
           }

  let dty : span -> A.ty -> B.ty = fun span -> catch @@ dty span
  let dpat : A.pat -> B.pat = catch dpat
  let dexpr : A.expr -> B.expr = catch dexpr
  let ditem : A.item -> B.item list = catch ditem
  let metadata = S0.metadata
end