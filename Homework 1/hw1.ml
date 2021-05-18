open Stdlib
open List

(*type definition for grammars*)
type ('nonterminal, 'terminal) symbol = N of 'nonterminal | T of 'terminal

(* function that returns true iff the set represented by the list a 
 * is a subset of the set represented by the list b*)
let rec subset a b = match a with
        | [] -> true
        | h::t -> if (List.mem h b) 
                  then subset t b
                  else false

(*function that returns true iff the represented sets are equal*)
let equal_sets a b = (subset a b) && (subset b a) 

(*function that finds elements unique to a (ie they are not in b)*)
let rec uniq a b = match a with
        | [] -> []
        | h::t -> if (List.mem h b)
                  then (uniq t b)
                  else h::(uniq t b) 

(*function that returns a list representing a∪b*)
let set_union a b = a@(uniq b a)

(*function that returns a list representing the union of all the members of the set a
 * a should represent a set of sets*)
let rec set_all_union a = match a with
        | [] -> []
        | h::t -> set_union h (set_all_union t) 

(* self_member *)
(* The relation types aren't flexible in Ocaml so if s is a set, then it is of type
 * 'a list. The memebers of s have their own types (lists, ints, floats, etc) so 
 * there's always at least one level between a set and its member. It wouldn't be
 * possible to write a function to test whether or not a set is a member of itself
 * because of that property. *)

(*function that returns the computed fixed point for f with respect to x*)
let rec computed_fixed_point eq f x =
        if (eq (f x) x)
        then x
        else (computed_fixed_point eq f (f x))

(* function that returns a list of non-terminating (nt) symbols given a list of symbols *)
let rec get_nt_from_rhs symbol_list = match symbol_list with
        | [] -> []
        | h::t -> match h with
                | N a -> a::(get_nt_from_rhs t)
                | T _ -> get_nt_from_rhs t

(* function that returns a rule's list of non-terminating symbols given a list of rules *)
let rec extract_nt lst = match lst with
        | [] -> []
        | h::t -> (get_nt_from_rhs (snd h))@(extract_nt t)    

(* function that returns a list of non-terminals reachable by a given grammar *)
let get_nt_from_g g = 
        let nonterm, rules = g in 
        nonterm::(extract_nt (List.filter (fun x -> if (fst x) = nonterm then true else false) rules))

(* function that returns list of reachable non-terminal symbols from a given list *)
let rec get_nt_sublist nt_list rules = match nt_list with
        | [] -> []
        | h::t -> (get_nt_from_g (h, rules))@(get_nt_sublist t rules)

(* function that returns list of all reachable non-terminals given a growing list of reachable symbols,
 * filtered grammar, and rules*)
let rec get_reachable_nt reached_nt all_nt rules =
        let nt_list = (uniq all_nt reached_nt) in 
                match nt_list with
                | [] -> all_nt
                | _ -> get_reachable_nt all_nt (set_union (get_nt_sublist nt_list rules) all_nt) rules

(* function that returns a list of reachable symbols by comparing a given list to g *)
let rec get_reachable_rules g sym_list = 
        let start,rules = g in match rules with 
        | [] -> []
        | h::t -> let nt = (fst h) in (if (List.mem nt sym_list) 
                                       then h::(get_reachable_rules (start, t) sym_list)
                                       else get_reachable_rules (start, t) sym_list)

(*function that returns a copy of the grammar g with all unreachable rules removed
 * should preserve the order of the rules*)
let filter_reachable g =
        let start, rules = g in 
        let reachable_nt = get_reachable_nt [start] (get_nt_from_g g) rules in
        let final_rules = get_reachable_rules g reachable_nt in
        (start, final_rules)
