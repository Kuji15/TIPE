type variable = int 
type solution_t = variable array 
type fnc_t = variable list list

exception Unsatisfiable
exception Satisfiable

let rec empty_in (fnc : fnc_t) =
  match fnc with
  | [] -> false
  | h :: t when h = [] -> true
  | h :: t -> empty_in t

let choose_var (fnc:fnc_t) (solution : solution_t) =
  (*Search the unassigned variable*)
  let rec find_var_in_clauses = function
    | [] -> raise Unsatisfiable
    | clause :: rest ->
        match List.find_opt (fun x -> solution.(abs x) = 0) clause with
        | Some v -> abs v 
        | None -> find_var_in_clauses rest
  in
  find_var_in_clauses fnc

let var_clause_uni (fnc : fnc_t) =
  let rec find_uni = function
    | [] -> 0
    | clause :: rest ->
        match clause with
        | [x] -> x
        | _ -> find_uni rest
  in
  find_uni fnc


let abs (x:variable) = (*return the absolute value of x*)
  if x < 0 then (-x) 
  else x



let rec list_parcours (l: variable list) (x : variable) = 
  (*parcours of the fnc, if x is in the clause, then return true.*)
  match l with 
  | [] -> false
  | h :: t when h = x || h = -x -> true
  | _ :: t -> list_parcours t x 



let rec remove_clause_with_known_uni (fnc : fnc_t) (x : variable) = 
  (*Remove all clauses where x is in it, and delete -x from all other clauses.*)
  match fnc with 
  | [] -> []
  | clause :: rest -> 
    if List.exists (fun lit -> lit = x) clause then 
      remove_clause_with_known_uni rest x
    else 
      let cleaned_clause = List.filter (fun lit -> lit <> -x) clause in 
      if cleaned_clause = [] then
        raise Unsatisfiable
      else 
        cleaned_clause :: remove_clause_with_known_uni rest x 
  



let simplify_clause_uni (fnc : fnc_t) (sol : solution_t) = 
  (*remove all the unit clause and set the value of each variable of those unit clause*)
    let var = var_clause_uni fnc in
    let new_fnc = ref [] in
      if (var != 0) then begin 
          sol.(abs var)<- var ;
          new_fnc := (remove_clause_with_known_uni fnc var)
      end else
        new_fnc := fnc;

    !new_fnc


let rec simplify_all_unit_clauses (fnc : fnc_t) (sol : solution_t) =
  let var = var_clause_uni fnc in
  if var != 0 then
    let new_fnc = remove_clause_with_known_uni fnc var in
    sol.(abs var) <- if var > 0 then 1 else -1;  (* Set 1 for true, -1 for false *)
    simplify_all_unit_clauses new_fnc sol  (* Continue until there is no more unit clauses left *)
  else
    fnc

let fnc_length (fnc : fnc_t) = 
  fnc
  |> List.flatten           (*concatenate all clauses in one*)
  |> List.map abs              (*apply the absolute value on each variable*)
  |> List.sort_uniq compare   (*remove repetition*)
  |> List.length      





let simplify_fnc (fnc : fnc_t) = 
  if empty_in fnc then raise Unsatisfiable;
  
  let n = fnc_length fnc in
  let sol = Array.make (n+1) 0 in
  
  (* Step 1 1 : Simplify all unit clauses  *)
  let cleaned_fnc = simplify_all_unit_clauses fnc sol in
  
  (* Step 2 : Assigning remaining variables *)
  let rec assign_remaining_vars current_fnc =
    try
      let x = choose_var current_fnc sol in
      sol.(x) <- 1;  (* Assigned true by default *)
      let new_fnc = remove_clause_with_known_uni current_fnc x in
      if empty_in new_fnc then 
        sol
      else
        (* Simplfify after assignment *)
        let simplified_fnc = simplify_all_unit_clauses new_fnc sol in
        assign_remaining_vars simplified_fnc
    with
    | Unsatisfiable -> sol  (* All variables are assigned double meaning : Succes or fail*)
  in
  
  assign_remaining_vars cleaned_fnc 
  (*return sol in which the value at the index 0 is always 0, because the variable 0 is never used in propositional logic*)


(*
let remove_first_value (tab : variable array) = 
  let n = Array.length tab in
  let new_tab = Array.make (n-1) 0 in
  for i = 1 to (n-1) do
    new_tab.(i-1) <- tab.(i);
  done;
  new_tab;;
In case in which we need to have the first variable at the index 0, a more human way to read
*)
