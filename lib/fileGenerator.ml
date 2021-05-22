(** This module is the entry point for code generation.
 ** It dispatches to the actual code generation in the Generator module.
 ** And when we support printing of Tactics/Type classes it would also dispatch to that in here.
 **  *)
open Util

module CS = CoqSyntax
module GG = GallinaGen
module VG = VernacGen
module L = Language

let unscoped_preamble = "Require Import core unscoped.\n\n"
let unscoped_preamble_axioms = "Require Import core core_axioms unscoped unscoped_axioms.\n"
let scoped_preamble = "Require Import core fintype.\n\n"
let scoped_preamble_axioms = "Require Import core core_axioms fintype fintype_axioms.\n"
let base_preamble = Scanf.format_from_string "Require Import %s.\n\n" "%s"

let get_preambles outfile_basename =
  let base_preamble = Printf.sprintf base_preamble outfile_basename in
  match !Settings.scope_type with
  | L.Unscoped -> (unscoped_preamble, unscoped_preamble_axioms ^ base_preamble)
  | L.WellScoped -> (scoped_preamble, scoped_preamble_axioms ^ base_preamble)

(** Generate all the liftings (= Up = fatarrow^y_x) for all pairs of sorts in the current component.
 ** So that we can later build the lifting functions "X_ty_ty", "X_ty_vl" etc. *)
let getUps component =
  let open List in
  let cart = cartesian_product component component in
  let singles = map (fun (x, y) -> (L.Single x, y)) cart in
  let blists = map (fun (x, y) -> (L.BinderList ("p", x), y)) cart in
  let scope_type = !Settings.scope_type in
  match scope_type with
  | L.WellScoped -> List.append singles blists
  | L.Unscoped -> singles

(* deriving a comparator for a type and packing it in a module
 * from https://stackoverflow.com/a/59266326 *)
(* I refactored out the code where I needed the comparator to call stable_dedup on a list but leaving this in for reference *)
(* module UpsComp = struct
 *   module T = struct
 *     type t = L.binder * string [@@deriving compare]
 *     let sexp_of_t = Sexplib0.Sexp_conv.sexp_of_opaque
 *   end
 *
 *   include T
 *   include Comparable.Make(T)
 * end *)

(** Generate the fixpoints/lemmas for all the connected components *)
let genCode components =
  let open RWEM.Syntax in
  let open RWEM in
  let open VG in
  let* (_, code, fext_code) = m_fold (fun (done_ups, vexprs, fext_exprs) component ->
      let* substSorts = substOf (List.hd component) in
      let new_ups = getUps substSorts in
      let ups = list_diff new_ups done_ups in
      let* { as_units; as_fext_units } = CodeGenerator.gen_code component ups in
      pure @@ (ups @ done_ups, vexprs @ as_units, fext_exprs @ as_fext_units))
      ([], [], []) components in
  pure { as_units = code; as_fext_units = fext_code }

let genTactics () =
  let open RWEM in
  let open AutomationGen in
  let open GG in
  let open Termutil in
  let info = {
    asimpl_rewrite_lemmas = ["instId_tm"; "compComp_tm"; "compComp'_tm"; "rinstId_tm"; "compRen_tm";
                             "compRen'_tm"; "renComp_tm"; "renComp'_tm"; "renRen_tm"; "renRen'_tm";
                             "varL_tm"; "varLRen_tm" ];
    asimpl_cbn_functions = ["subst_tm"; "ren_tm"];
    asimpl_unfold_functions = ["up_ren"; "upRen_tm_tm"; "up_tm_tm" ];
    substify_lemmas = ["rinstInst_tm"];
    auto_unfold_functions = ["subst1"; "subst2"; "Subst1";  "Subst2";  "ids";  "ren1"; "ren2"; "Ren1";  "Ren2";  "Subst_tm";  "Ren_tm"; "VarInstance_tm"];
    arguments = [];
    classes = [ "Up_tm", [ binder_ [ "X"; "Y" ] ], [ constructor_ "up_tm" (arr1_ (ref_ "X") (ref_ "Y")) ] ];
    instances = [ CG_Subst 1, "tm", [underscore_; underscore_; underscore_]
                ; CG_Ren 1, "tm", [underscore_; underscore_; underscore_]
                ; CG_Var, "tm", [underscore_; underscore_]
                ; CG_Up, "tm", [underscore_; underscore_] ];
    notations = [ NG_VarConstr ("x", "tm"), app_ref "var_tm" [ ref_ "x" ]
                ; NG_VarInst ("x", "tm"), app_ref ~expl:true "ids" [ underscore_; underscore_; ref_ ClassGen.(instance_name "tm" CG_Var); ref_ "x" ]
                ; NG_Var, ref_ "var_tm"
                ; NG_Up "tm", ref_ "up_tm"
                ; NG_Up "tm", ref_ "up_tm_tm"
                ; NG_SubstApply ("s", "sigma_tm"), app_ref "subst_tm" [ ref_ "sigma_tm"; ref_ "s" ]
                ; NG_Subst "sigma_tm", app_ref "subst_tm" [ ref_ "sigma_tm" ]
                ; NG_RenApply ("s", "xi_tm"), app_ref "ren_tm" [ ref_ "xi_tm"; ref_ "s" ]
                ; NG_Ren "xi_tm", app_ref "ren_tm" [ ref_ "xi_tm" ] ];
  } in
  pure (AutomationGenerator.gen_additional info)

let make_file preamble code tactics =
  let pp_code = VG.pr_vernac_units code in
  let pp_tactics = VG.pr_vernac_units tactics in
  let text = Pp.(string_of_ppcmds (pp_code ++ pp_tactics)) in
  preamble ^ text

(** Generate the Coq file. Here we convert the Coq AST to pretty print expressions and then to strings. *)
let genFile outfile_basename =
  let open RWEM.Syntax in
  let open RWEM in
  let open VG in
  let* components = getComponents in
  let* { as_units = code; as_fext_units = fext_code } = genCode components in
  let* { as_units = automation; as_fext_units = fext_automation } = genTactics () in
  let preamble, preamble_axioms = get_preambles outfile_basename in
  pure (make_file preamble code automation, make_file preamble_axioms fext_code fext_automation)

(** Run the computation constructed by genFile *)
let run_gen_code hsig outfile = RWEM.rwe_run (genFile outfile) hsig