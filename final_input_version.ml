open Properly_sat
open Input
open Output
open Unix

(* ===================== TYPEDEF ================= *)
type variable = {
  week: int;
  group : int;
  time_slot : int;
  id_colleur : int 
}

(* Storage's type before optimization *)
type raw_assignment = {
  r_week: int;
  mutable r_group: int; (* Mutable, because we gonna swap them *)
  r_slot: int;
  r_prof: int;
}

(* ===================== VARIABLES GLOBALES ================= *)
let input = Csv.load ~separator:',' "entree.csv"

let nb_tab = Input.nb_math_phy_ang input
let time_slots_tab = Input.time_slot_tab_and_number input 
let nom_colleur_tab = Input.colleur_list_and_number input

let nb_groups = 16
let nb_slots = snd time_slots_tab 
let nb_colleur_math = nb_tab.(0)
let nb_colleur_phy = nb_tab.(1)
let nb_colleur_ang = nb_tab.(2)
let nb_total_colleurs = nb_colleur_ang + nb_colleur_math + nb_colleur_phy

(* Tabs *)
let time_names_array = Array.of_list (fst time_slots_tab)
let colleur_names = Input.colleur_name_array input
let colleur_slots = Input.colleurs_slots_array input

(* NOUVEAU : Récupération des matières par ID de colleur *)
(* Nécessite la modification dans input.ml *)
let colleur_subjects = Input.colleurs_subjects_array input 

(* ================== UTILS ENCODAGE ================= *)
let get_colleur_name id = 
  if id < Array.length colleur_names then colleur_names.(id) else "Inconnu"

let get_time_string id =
  if id < Array.length time_names_array then time_names_array.(id) else "Inconnu"

let encode x = 
  (x.id_colleur + nb_total_colleurs * (x.time_slot + nb_slots * (x.group + nb_groups * x.week))) + 1

let decode n = 
  let n = n - 1 in
  let id_colleur = n mod nb_total_colleurs in
  let rest1 = n / nb_total_colleurs in
  let time_slot = rest1 mod nb_slots in
  let rest2 = rest1 / nb_slots in
  let group = rest2 mod nb_groups in
  let week = rest2 / nb_groups in
  {week; group; time_slot; id_colleur}

let shuffle list = 
  let tagged = List.map (fun c -> (Random.bits (), c)) list in
  let sorted = List.sort compare tagged in
  List.map snd sorted

(* ================== LOGIQUE MATIÈRE ================= *)
let limit_math = nb_colleur_math
let limit_phy  = nb_colleur_math + nb_colleur_phy
let is_math id = id < limit_math
let is_phy id  = id >= limit_math && id < limit_phy
let is_ang id  = id >= limit_phy

let get_subject_type pid =
  if is_math pid then 0
  else if is_phy pid then 1
  else 2

(* ================== GESTION DE LA MÉMOIRE ================= *)
(* We remember the last time a group saw a teacher. *)
let last_seen_matrix = Array.make_matrix nb_groups nb_total_colleurs (-10)

let update_rolling_history solution_array current_real_week =
  Array.iteri (fun i is_true ->
    if i > 0 && is_true > 0 then begin
      let v = decode i in
      if v.week = 0 then 
        last_seen_matrix.(v.group).(v.id_colleur) <- current_real_week
    end
  ) solution_array

(* Cycle restriction: Teachers seen SINCE the beginning of the cycle are prohibited *)
let generate_cycle_constraints current_real_week cycle_length =
  let clauses = ref [] in
  let start_of_cycle = ((current_real_week - 1) / cycle_length) * cycle_length + 1 in
  
  for g = 0 to nb_groups - 1 do
    for p = 0 to nb_total_colleurs - 1 do
      let last_seen = last_seen_matrix.(g).(p) in
      
      (* If seen in the current cycle *)
      if last_seen >= start_of_cycle then begin
         List.iter (fun s ->
            let id = encode {week=0; group=g; time_slot=s; id_colleur=p} in
            clauses := [-id] :: !clauses 
         ) colleur_slots.(p)
      end
    done
  done;
  !clauses

(* ================== CONSTRAINTS GENERATORS ================= *)

let rec at_most_one vars = 
  match vars with [] -> [] |
  h::t -> (List.map (fun y -> [-h; -y]) t) @ at_most_one t
let exactly_one vars = [vars] @ at_most_one vars

(* Structure (Dispo, Ubiquity) *)
let generate_structural_constraints () = 
  let clauses = ref [] in
  for g = 0 to nb_groups - 1 do
    for t = 0 to nb_slots - 1 do
      for id = 0 to nb_total_colleurs - 1 do
        if not (List.mem t colleur_slots.(id)) then
          clauses := [-(encode {week=0; group=g; time_slot=t; id_colleur=id})] :: !clauses
      done
    done
  done;
  for id = 0 to nb_total_colleurs - 1 do
    List.iter (fun t -> 
      let vars = ref [] in
      for g = 0 to nb_groups - 1 do
        vars := (encode {week=0; group=g; time_slot=t; id_colleur=id}) :: !vars
      done;
      clauses := !clauses @ (at_most_one !vars)
    ) colleur_slots.(id)
  done;
  for g = 0 to nb_groups - 1 do
    for t = 0 to nb_slots - 1 do
      let vars = ref [] in
      for id = 0 to nb_total_colleurs - 1 do
        if List.mem t colleur_slots.(id) then
          vars := (encode {week=0; group=g; time_slot=t; id_colleur=id}) :: !vars
      done;
      clauses := !clauses @ (at_most_one !vars)
    done
  done;
  !clauses

(* Program (STRICT parity) *)
let generate_curriculum_constraints real_week =
  let clauses = ref [] in
  let is_even_week = (real_week mod 2 = 0) in
  
  for g = 0 to nb_groups - 1 do
    let math_vars = ref [] in
    let phy_vars = ref [] in
    let ang_vars = ref [] in

    for t = 0 to nb_slots - 1 do
      for id = 0 to nb_total_colleurs - 1 do
        if List.mem t colleur_slots.(id) then
          let v = encode {week=0; group=g; time_slot=t; id_colleur=id} in
          if is_math id then math_vars := v :: !math_vars
          else if is_phy id then phy_vars := v :: !phy_vars
          else if is_ang id then ang_vars := v :: !ang_vars
      done
    done;
    clauses := !clauses @ (exactly_one !math_vars);

    let must_do_phy = if g < 8 then is_even_week else not is_even_week in
    if must_do_phy then (
      clauses := !clauses @ (exactly_one !phy_vars);
      List.iter (fun v -> clauses := [-v] :: !clauses) !ang_vars
    ) else (
      clauses := !clauses @ (exactly_one !ang_vars);
      List.iter (fun v -> clauses := [-v] :: !clauses) !phy_vars
    )
  done;
  !clauses

(* ================== POST-TREATMENT OPTIMIZER ================= *)

(* Calculates the “cost” of fairness: sum of the squares of repetitions *)
let calculate_equity_score assignments =
  let counts = Array.make_matrix nb_groups nb_total_colleurs 0 in
  Array.iter (fun a ->
    counts.(a.r_group).(a.r_prof) <- counts.(a.r_group).(a.r_prof) + 1
  ) assignments;
  let score = ref 0 in
  for g = 0 to nb_groups - 1 do
    for p = 0 to nb_total_colleurs - 1 do
      let n = counts.(g).(p) in
      if n > 1 then score := !score + (n * n * n) (* Cubic penality *)
    done
  done;
  !score


let has_conflict assignments week group slot_id ignore_index =
  let conflict = ref false in
  for i = 0 to Array.length assignments - 1 do
    if i <> ignore_index then
      let a = assignments.(i) in
      if a.r_week = week && a.r_group = group && a.r_slot = slot_id then
        conflict := true
  done;
  !conflict

(* Hill Climbing Algorithm *)
let optimize_distribution raw_list =
  Printf.printf "\n--- OPTIMISATION POST-TRAITEMENT (LISSAGE) ---\n";
  let arr = Array.of_list raw_list in
  let n = Array.length arr in
  let current_score = ref (calculate_equity_score arr) in
  Printf.printf "Score initial d'injustice : %d\n" !current_score;
  let iterations = 100000 in (* Number of try *)
  let improved = ref 0 in

  for k = 1 to iterations do
    (* 1. We choose two random time slots*)
    let i = Random.int n in
    let j = Random.int n in
    
    let a1 = arr.(i) in
    let a2 = arr.(j) in
    
    (* Conditions for exchange: Same week, same subject, different groups *)
    if i <> j && a1.r_week = a2.r_week && a1.r_group <> a2.r_group && 
       (get_subject_type a1.r_prof = get_subject_type a2.r_prof) then
      begin
        (* Schedule conflict check *)
        let conflict1 = has_conflict arr a1.r_week a1.r_group a2.r_slot i in
        let conflict2 = has_conflict arr a2.r_week a2.r_group a1.r_slot j in
        
        if not conflict1 && not conflict2 then begin
     
          (* We try the swap *)
          let old_g1 = a1.r_group in
          let old_g2 = a2.r_group in
          
          a1.r_group <- old_g2;
          a2.r_group <- old_g1;
          
          let new_score = calculate_equity_score arr in
          
          if new_score < !current_score then begin
            current_score := new_score;
            incr improved;
          end else begin
            (* Annulation *)
            a1.r_group <- old_g1;
            a2.r_group <- old_g2;
          end
        end
      end
  done;
  Printf.printf "Optimisation terminée. %d améliorations effectuées.\n" !improved;
  Printf.printf "Score final d'injustice : %d\n" !current_score;
  Array.to_list arr

(* ================== SOLVER ================= *)

let solve_with_retry clauses max_retries =
  let rec aux attempt =
    if attempt > max_retries then raise Properly_sat.Unsatisfiable
    else
      try
        let shuffled = shuffle clauses in
        Properly_sat.simplify_fnc shuffled
      with Properly_sat.Unsatisfiable ->
        aux (attempt + 1)
  in
  aux 1

(* ================== MAIN ================= *)

let main () =
  Random.self_init ();
  Printf.printf "--- GENERATION ROBUSTE + OPTIMISATION ---\n";
  let global_raw_assignments = ref [] in

  for w = 0 to 15 do 
    let real_week = w + 1 in
    Printf.printf "S%d" real_week;
    flush Stdlib.stdout;
    
    let mandatory = 
      generate_structural_constraints () @ 
      generate_curriculum_constraints real_week 
    in

    let final_solution = 
      try
        (* We'll try with a limited 4-week trial period.*)
        let equity = generate_cycle_constraints real_week 4 in
        
        let s = solve_with_retry (mandatory @ equity) 10 in
       
        Printf.printf " : Générée \n"; s
      
      with Properly_sat.Unsatisfiable ->
        (* Help: fill in without memory *)
        let s = solve_with_retry mandatory 20 in
        Printf.printf " [Secours]";
        s
    in

    update_rolling_history final_solution real_week;
    Array.iteri (fun i is_true ->
      if i > 0 && is_true > 0 then begin
        let v = decode i in
        if v.week = 0 then
          let ra = {
            r_week = real_week;
            r_group = v.group;
            r_slot = v.time_slot;
            r_prof = v.id_colleur
          } in
          global_raw_assignments := ra :: !global_raw_assignments
      end
    ) final_solution;
  done;

  (*=== OPTIMIZATION === *)
  let optimized_assignments = optimize_distribution !global_raw_assignments in

  Printf.printf "\nConversion vers CSV...\n";

  let csv_ready_list = List.map (fun ra ->
    {
      Output.semaine = ra.r_week;
      Output.groupe = ra.r_group;
      Output.creneau = get_time_string ra.r_slot;
      Output.prof = get_colleur_name ra.r_prof;
      Output.matiere = colleur_subjects.(ra.r_prof)
    }
  ) optimized_assignments in

  let weeks_list = 
    let rec aux i acc = if i < 1 then acc else aux (i-1) (i::acc) in
    aux 16 [] 
  in

  Printf.printf "--- EXPORT CSV ---\n";
  Output.export_to_csv "colloscope_final.csv" csv_ready_list weeks_list

let () = main ()