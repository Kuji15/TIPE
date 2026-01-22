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



let get_max_var_index (fnc : fnc_t) = 
  fnc
  |> List.flatten (*concatenate all clauses in one*)
  |> List.map abs (*apply the absolute value on each variable*)
  |> List.fold_left max 0 (*find the maximum value in the list*)


  (*return sol in which the value at the index 0 is always 0, because the variable 0 is never used in propositional logic*)
let simplify_fnc (fnc : fnc_t) = 
  if empty_in fnc then raise Unsatisfiable;
  
  let max_idx = get_max_var_index fnc in 
  let sol_init = Array.make (max_idx + 1) 0 in
  
  (* Initial unit propagation *)
  let cleaned_fnc = simplify_all_unit_clauses fnc sol_init in

  let rec solve current_fnc current_sol =
    (* VICTORY CASE: No more clauses to fulfill *)
    if current_fnc = [] then 
      current_sol 
    (* DEFEATED CASE: An empty clause (contradiction) has been generated. *)
    else if empty_in current_fnc then 
      raise Unsatisfiable
    else
      let x = 
        try choose_var current_fnc current_sol 
        with Unsatisfiable -> raise Unsatisfiable 
      in
      try
        let sol_vrai = Array.copy current_sol in 
        sol_vrai.(x) <- 1;
        let next = remove_clause_with_known_uni current_fnc x in
        let simplified = simplify_all_unit_clauses next sol_vrai in
        solve simplified sol_vrai
      with Unsatisfiable ->
        (* acktracking *)
        let sol_faux = Array.copy current_sol in 
        sol_faux.(x) <- -1;
        let next = remove_clause_with_known_uni current_fnc (-x) in
        let simplified = simplify_all_unit_clauses next sol_faux in
        solve simplified sol_faux
  in
  
  solve cleaned_fnc sol_init




