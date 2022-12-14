open List

(* fonctions utilitaires *********************************************)
(* filter_map : ('a -> 'b option) -> 'a list -> 'b list
   disponible depuis la version 4.08.0 de OCaml dans le module List :
   pour chaque élément de `list', appliquer `filter' :
   - si le résultat est `Some e', ajouter `e' au résultat ;
   - si le résultat est `None', ne rien ajouter au résultat.
   Attention, cette implémentation inverse l'ordre de la liste *)
let filter_map filter list =
  let rec aux list ret =
    match list with
    | []   -> ret
    | h::t -> match (filter h) with
      | None   -> aux t ret
      | Some e -> aux t (e::ret)
  in aux list [];;

(* print_modele : int list option -> unit
   affichage du résultat *)
let print_modele: int list option -> unit = function
  | None   -> print_string "UNSAT\n"
  | Some modele -> print_string "SAT\n";
     let modele2 = sort (fun i j -> (abs i) - (abs j)) modele in
     List.iter (fun i -> print_int i; print_string " ") modele2;
     print_string "0\n";;

(* ensembles de clauses de test *)
let exemple_3_12 = [[1;2;-3];[2;3];[-1;-2;3];[-1;-3];[1;-2]];;
let exemple_7_2 = [[1;-1;-3];[-2;3];[-2]];;
let exemple_7_4 = [[1;2;3];[-1;2;3];[3];[1;-2;-3];[-1;-2;-3];[-3]];;
let exemple_7_8 = [[1;-2;3];[1;-3];[2;3];[1;-2]];;
let systeme = [[-1;2];[1;-2];[1;-3];[1;2;3];[-1;-2]];;
let coloriage = [[1;2;3];[4;5;6];[7;8;9];[10;11;12];[13;14;15];[16;17;18];[19;20;21];[-1;-2];[-1;-3];[-2;-3];[-4;-5];[-4;-6];[-5;-6];[-7;-8];[-7;-9];[-8;-9];[-10;-11];[-10;-12];[-11;-12];[-13;-14];[-13;-15];[-14;-15];[-16;-17];[-16;-18];[-17;-18];[-19;-20];[-19;-21];[-20;-21];[-1;-4];[-2;-5];[-3;-6];[-1;-7];[-2;-8];[-3;-9];[-4;-7];[-5;-8];[-6;-9];[-4;-10];[-5;-11];[-6;-12];[-7;-10];[-8;-11];[-9;-12];[-7;-13];[-8;-14];[-9;-15];[-7;-16];[-8;-17];[-9;-18];[-10;-13];[-11;-14];[-12;-15];[-13;-16];[-14;-17];[-15;-18]];;

(********************************************************************)

(* simplifie : int -> int list list -> int list list 
   applique la simplification de l'ensemble des clauses en mettant
   le littéral l à vrai *)
exception Vide


let rec simplifie l clauses =
  (*Pour chaques closes*)
  match clauses with
  | [] -> []  (*fin*)
  | x :: slauses ->
    let rec rmFrmClause clause = 
      (*Pour chaques litérales de la clause*)
      match clause with
      | [] -> []
      | x :: lclause ->
        (*Si litérale l positif alors on renvoi une exception Vide*)
        if x = l then
          raise (Vide)
        (*Si il est négatif on le retire de la clause*)
        else if x = -l then
          rmFrmClause lclause
        (*Si il n'est pas trouvé on regarde les autres littéraux de la clause*)
        else
          x :: rmFrmClause lclause
    (*Si la fonction rmFrmClause renvoie l'exception Vide on enlève la clause sinon on continu en gardant la clause modifiée (on non) par rmFrmClause*)
    in try rmFrmClause x :: simplifie l slauses with
    | Vide -> simplifie l slauses
;;

(*Test
  simplifie 1 [[1;2;3];[-1;2];[4;5]];; *)

(*contains : int -> int list -> bool
   revoi true si le litéral l est dans la clause en négatif ou positif
   et false sinon*)
let rec contains l clause =
  match clause with
  (*Littéral l non trouvé*)
  | [] -> false
  | x :: slause ->
    (*Si x est le littéral l alors true sinon continuer*)
    if x = l || x = -l then
      true 
    else
      contains l slause;;

(*Test contains
  contains 1 [0;2;4];;
  contains 0 [1;2;0];; *)

(* solveur_split : int list list -> int list -> int list option
   exemple d'utilisation de `simplifie' *)
(* cette fonction ne doit pas être modifiée, sauf si vous changez 
   le type de la fonction simplifie *)
let rec solveur_split clauses interpretation =
  (* l'ensemble vide de clauses est satisfiable *)
  if clauses = [] then Some interpretation else
  (* un clause vide n'est jamais satisfiable *)
  if mem [] clauses then None else
  (* branchement *) 
  let l = hd (hd clauses) in
  let branche = solveur_split (simplifie l clauses) (l::interpretation) in
  match branche with
  | None -> solveur_split (simplifie (-l) clauses) ((-l)::interpretation)
  | _    -> branche;;

(* tests *)
(* let () = print_modele (solveur_split systeme []) *)
(* let () = print_modele (solveur_split coloriage []) *)

(* solveur dpll récursif *)
    
(* unitaire : int list list -> int
    - si `clauses' contient au moins une clause unitaire, retourne
      le littéral de cette clause unitaire ;
    - sinon, lève une exception `Not_found' *)
let rec unitaire clauses =
  match clauses with
  (*Fin clause unitaire non trouvée*)
  | [] -> raise Not_found
  | clause::clauses ->
    match clause with
    (*Clause unitaire donc on renvoi le littéral*)
    | [l] -> l
    (*Clause pas unitaire on continu*)
    | _ -> unitaire clauses;;

(*Test unitaire
   unitaire [[1;2;4];[4;7]; [1;7]];;
   unitaire [[1;2;4];[7]; [1;7]];; *)
    

(*aplatir_list_rec : 'a list list -> 'a list -> 'a list
   fonction auxiliaire de aplatir_list
   transforme une liste 2D en liste 1D (récursivité terminale)
   l initialisé à []*)
let rec aplatir_list_rec ll l =
  match ll with
  (*fin on renvoi la liste*)
  | [] -> l
  | x::ll -> 
    match x with
    (*fin sous liste on continu avec les autres sous listes*)
    | [] -> aplatir_list_rec ll l
    (*on insert l'élément de la sous liste et continu avec cette même sous liste*)
    | y::l' -> aplatir_list_rec (l'::ll) (y::l);;

(*aplatir_list : 'a list list -> 'a list
   transforme une liste 2D en liste 1D (récursivité terminale)*)
let aplatir_list ll =
  aplatir_list_rec ll [];;

(*Test aplatir_list
   aplatir_list [[1;4;5];[4;7;2;5];[7;1;0;2;5;4]];;*)

(*is_in : 'a -> 'a list -> bool
   renvoie true si l'élément x est dans la liste l
   renvoie false sinon*)
let rec is_in x l =
  match l with
  (* fin x n'est pas dans l *)
  | [] -> false
  (* fin x est dans l *)
  | y::l when y = x -> true
  (* y n'est pas x on continu *)
  | y::l -> is_in x l;;

(*Tests is_in
   is_in 1 [4;5;8;4;6;4;5;2;4];;
   is_in 2 [4;5;8;4;6;4;5;2;4];;*)

exception Failure_no_pur

(*pur_rec : int list -> int
   fonction auxiliair de pur
   prend un ensemble en paramètre
   initialiser p à []
   (recursivité terminale)*)
let rec pur_rec l p =
  match l with
  (* Aucun éléments pur trouvé *)
  | [] -> raise Failure_no_pur
  | x::l -> 
    (* x déjà vérifié *)
    if is_in x p then
      pur_rec l p
    else
      (* x n'est pas pur on continu en ajoutant x et -x à la liste des précédents *)
      if is_in (-x) l then
        pur_rec l (-x::x::p)
      (* x est pur on le renvoi *)
      else
        x;;

(* pur : int list list -> int
    - si `clauses' contient au moins un littéral pur, retourne
      ce littéral ;
    - sinon, lève une exception `Failure "pas de littéral pur"' *)
let pur clauses =
  (*appelle pur_rec sur l'ensemble de tous les littéraux de chaque clauses*)
  pur_rec (aplatir_list clauses) [];;

(*Tests pur
   pur [[1;4;-5];[4;-7;-2;-5];[7;-1;2;5;-4]];;
   pur [[1;4;-5];[4;-7;-2;-5];[7;-1;2;5;4]];;*)

   
(* solveur_dpll_rec : int list list -> int list -> int list option *)
let rec solveur_dpll_rec clauses interpretation =
  (* fin clauses est satisfiable *)
  if clauses = [] then
    Some interpretation
    (* fin clauses n'est pas satisfiable *)
  else if List.mem [] clauses then
    None
  else 
    (* on cherche un littérale pur *)
    let l = try (pur clauses, true) with 
      (* Aucun littérale pur trouvé on prend le premier littérale de la premère clause *)
      | Failure_no_pur -> (hd (hd clauses), false)
    in match l with
    (* Si l est un littérale pur on simplifie clauses avec l et ajoute l à l'interprétation et on continu *)
    | (l, true) -> solveur_dpll_rec (simplifie l clauses) (l::interpretation)
    (* Le littérale l n'est pas pur *)
    | (l, false) -> 
      (* on créer des branches *)
      let branche = solveur_dpll_rec (simplifie l clauses) (l::interpretation) in
      (* On test la première branche *)
      match branche with
      (* Si elle n'est pas satisfiable on test l'autre branche *)
      | None -> solveur_dpll_rec (simplifie (-l) clauses) ((-l)::interpretation)
      (* Si elle est satisfiable on renvoi ses interpretations *)
      | _    -> branche;;

(* tests *)
(* let () = print_modele (solveur_dpll_rec systeme []) *)
(* let () = print_modele (solveur_dpll_rec coloriage []) *)

let () =
  let clauses = Dimacs.parse Sys.argv.(1) in
  print_modele (solveur_dpll_rec clauses []);;
