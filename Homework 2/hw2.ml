open Stdlib
open List 

type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

(*****************************convert_grammar**********************************)

(* funtion that finds the rule when passed a nonterminal as an argument
 * and concatenates them *)
let rec get_rules nt rules = match rules with
         | [] -> []
         | (nonterm, sym_list)::t when nt = nonterm -> sym_list::(get_rules nt t)
         | (nonterm, sym_list)::t -> get_rules nt t

(* function that converts HW1 grammar to HW2 grammar *)
let convert_grammar g = fst g, fun nt -> get_rules nt (snd g)

(***************************parse_tree_leaves**********************************)

(* function that traverses the parse tree from left to right and produces
 * a list of the leaves encountered *)
let parse_tree_leaves tree = 
        let rec helper = function
                | [] -> []
                | (Leaf leaf)::t -> leaf::(helper t)
                | (Node (_, tree_list))::t -> (helper tree_list)@(helper t)
        in helper [tree]

(******************************make_matcher************************************)

(* input: a list of rules rules_lst, an acceptor a, a production function pf, a fragment frag (list)
 * output: the output of the acceptor so None or Some
 *
 * parse_rules extracts the first rule in the list and calls parse_symbols to parse the symbols
 * if parse_symbols returns None which means the rule didn't match with the fragment -> recurse on the other rules
 * by default return the rules_lst as Some type *)
(* input: a single rule (list), an acceptor a, a production function pf, a fragment frag (list)
 * output: the output of the acceptor so None or Some
 *
 * parse_symbols extracts the first symbol in rule and tries to match it with the first symbol in frag 
 * if there's a match -> return acceptor Some
 * otherwise -> recurse on the remaining rules *)
let rec parse_rules rules_lst frag pf a =
  match rules_lst with
  | [] -> None
  | rule::rst_rules -> match parse_symbols rule pf a frag with                                      
                       | None -> parse_rules rst_rules frag pf a (* if the acceptor returned None, then try the next rule *)
                       | Some e -> Some e                        (* return the Some that the acceptor returned *)
and parse_symbols rule pf a frag =
  match rule with
  | [] -> a frag
  | fst_symbol::rst_symbols -> match fst_symbol with
  (* term_sym match frag? *)   | T e -> (match frag with
                                        | fst_frag::rst_frag when e = fst_frag -> parse_symbols rst_symbols pf a rst_frag
                                        | _ -> None)     
  (* expand non-term_sym *)    | N e -> let alt_lst = (pf e) and curried_a fragment = parse_symbols rst_symbols pf a fragment in  
                                          parse_rules alt_lst frag pf curried_a             

(* function that returns a matcher for the grammar gram *)
let make_matcher gram = 
  let (expr, prod_func) = gram in 
    let alt_lst = (prod_func expr) in 
      fun accept frag -> (parse_rules alt_lst frag prod_func accept)

(*****************************make_parser**************************************)

(* only accepts an empty fragment *)
let parse_tree_acceptor tree = function
  | [] -> Some tree
  | _ -> None

(* the exact same as make_mather's helper functions
 * only difference is that it constructs tree nodes to return instead of
 * just returning what the acceptor returns *)
let rec parse_rules_tree start_sym child_nodes rules_lst frag pf a =
  match rules_lst with
  | [] -> None
  | rule::rst_rules -> match parse_symbols_tree start_sym child_nodes rule pf a frag with
                       | None -> parse_rules_tree start_sym child_nodes rst_rules frag pf a
                       | Some e -> Some e
and parse_symbols_tree start_sym child_nodes rule pf a frag =
  match rule with
  | [] -> a (Node (start_sym, child_nodes)) frag (* construct the tree by calling acceptor *)
  | fst_symbol::rst_symbols -> match fst_symbol with
  (* term_sym match frag? *)   | T e -> (match frag with
                                         | fst_frag::rst_frag when e = fst_frag -> parse_symbols_tree start_sym (child_nodes@[Leaf e]) rst_symbols pf a rst_frag
                                         | _ -> None)       
  (* expand non-term sym *)    | N e -> let alt_lst = (pf e) 
                                        and curried_a tree1 frag1 = parse_symbols_tree start_sym (child_nodes@[tree1]) rst_symbols pf a frag1 
                                        in parse_rules_tree e [] alt_lst frag pf curried_a

(* function that returns a parser for the grammar gram *)
let make_parser gram =
  let (expr, prod_func) = gram in
    let alt_lst = (prod_func expr) in
      fun frag -> parse_rules_tree expr [] alt_lst frag prod_func parse_tree_acceptor
