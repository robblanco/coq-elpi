(* Generates the induction principle.

   license: GNU Lesser General Public License Version 2.1 or later           
   ------------------------------------------------------------------------- *)

From elpi Require Export elpi derive.param1 derive.param1_functor.

Elpi Db derive.induction.db lp:{{

type induction-db term -> term -> prop.

:name "induction-db:fail"
induction-db T _ :-
  coq.say "derive.induction: can't find the induction principle for "
          {coq.term->string T},
  stop.

}}.

Elpi Command derive.induction.

Elpi Accumulate File "coq-lib-extra.elpi".
Elpi Accumulate File "derive/param1.elpi".
Elpi Accumulate Db derive.param1.db.

Elpi Accumulate Db derive.param1.functor.db.

Elpi Accumulate Db derive.induction.db.
Elpi Accumulate File "derive/induction.elpi".
Elpi Accumulate lp:{{
  main [str I, str O] :- !, coq.locate I GR, derive.induction.main (global GR) O _.
  main [str I] :- !,
    coq.locate I GR, Name is {coq.gr->id GR} ^ "_induction",
    derive.induction.main (global GR) Name _.
  main _ :- usage.

  usage :-
    coq.error "Usage: derive.induction <inductive type name> [<output name>]".
}}.  
Elpi Typecheck.

