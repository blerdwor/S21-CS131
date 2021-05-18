type meme_nonterminals =
  | Meme | Doge | Swol | Angy | Words

let terrible_rules = function
     | Meme ->
         [[N Words; N Doge; N Words];
          [N Words; N Angy; N Words]]
     | Doge ->
         [[N Swol; N Words; N Angy];
          [T"Dogo"; T"Doggo"; T"DogoDoggo"]]
     | Swol ->
         [[T"He"; T"protec"; N Words; T"attac"]]
     | Angy ->
         [[N Words; N Words; N Words];
          [T"cat"];
          [T"panda"];
          [T"No"; T"talk"; T"me"; T"I"; T"angy"]]
     | Words ->
         [[T"and"]; [T"hehe"]; [T"teehee"]; [T"pain"];
          [T":^)"]; [T"yell"]; [T"i cri"]; [T"hhhhh"]]

let terrible_grammar = (Meme, terrible_rules)

let accept_empty_suffix = function
   | _::_ -> None
   | x -> Some x

let matcher_frag = ["hehe"; "No"; "talk"; "me"; "I"; "angy"; "yell"]

let make_matcher_test = 
  ((make_matcher terrible_grammar accept_empty_suffix matcher_frag) = Some [])

let parser_frag = [":^)";"He";"protec";"and";"attac";"pain";"hhhhh";"i cri";"yell";":^)"]

let make_parser_test = 
  match make_parser terrible_grammar parser_frag with
    | Some tree -> parse_tree_leaves tree = parser_frag
    | _ -> false
