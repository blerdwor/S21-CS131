(* subset *)
let my_subset_test0 = subset [] []
let my_subset_test1 = subset [] [1;2]
let my_subset_test2 = not (subset [1] [])
let my_subset_test3 = not (subset [1;2;3] [4;5;6])
let my_subset_test4 = subset [1;1] [1;2;3]
let my_subset_test5 = subset [1;2;3;4;5] [3;3;2;5;1;4]
let my_subset_test7 = not (subset [1;2;3] [2;3;4])
let my_subset_test8 = subset ["a";"b"] ["a";"b";"c"]

(* equal_sets *)
let my_equal_sets_test0 = equal_sets [] []
let my_equal_sets_test1 = not (equal_sets [1;2] [])
let my_equal_sets_test2 = not (equal_sets [] [1;2])
let my_equal_sets_test3 = equal_sets [1;11;111] [1;11;111]
let my_equal_sets_test4 = equal_sets [1] [1;1;1]
let my_equal_sets_test5 = equal_sets [1;2;3] [1;2;3;2;3;1;2]
let my_equal_sets_test6 = not (equal_sets [2;2;2] [1;2;3])
let my_equal_sets_test7 = equal_sets ["a";"b"] ["b";"a"]
let my_equal_sets_test8 = not (equal_sets ["a";"b";"c"] ["e";"d"])

(* set_union *)
let my_set_union_test0 = equal_sets (set_union [] []) []
let my_set_union_test1 = equal_sets (set_union [] [1;2;3]) [1;2;3]
let my_set_union_test2 = equal_sets (set_union [1;2;3] []) [1;2;3]
let my_set_union_test3 = equal_sets (set_union [1;2] [1;2]) [1;2]
let my_set_union_test4 = equal_sets (set_union [1;2] [3;4]) [1;2;3;4]
let my_set_union_test5 = equal_sets (set_union [1] [2;2;2;2]) [1;2]
let my_set_union_test6 = equal_sets (set_union ["a";"b"] ["b";"c"]) ["a";"b";"c"]

(* no self_member because a function is not possible *)

(* computed_fixed_point test cases *)
let my_computed_fixed_point_test0 = not (computed_fixed_point (=) (fun x -> 1) 0 = 2)
let my_computed_fixed_point_test1 = computed_fixed_point (=) (fun x -> x) 4 = 4
let my_computed_fixed_point_test2 = computed_fixed_point (=) (fun x -> x) 10 = 10
let my_computed_fixed_point_test3 = computed_fixed_point (=) (fun x -> x * x) 1 = 1
let my_computed_fixed_point_test4 = computed_fixed_point (=) (fun x -> x *. x) 2. = infinity

(* filter_reachable *)
type limited_alphabet = | AA | BB | CC | DD | EE | FF

let rules =
	[AA, [N BB; N CC];
 	AA, [N DD; T "aa"];
	BB, [T "bb"];
	CC, [N DD; T "cc"];
	DD, [T "ldd"];
	EE, [N CC];
	FF, [T "ee"]]

let my_filter_reachable_test0 = filter_reachable (AA, rules) = (AA, [AA, [N BB; N CC]; AA, [N DD; T "aa"]; BB, [T "bb"]; CC, [N DD; T "cc"]; DD, [T "ldd"]])
let my_filter_reachable_test1 = filter_reachable (CC, rules) = (CC, [CC, [N DD; T "cc"]; DD, [T "ldd"]]);
