open Properly_sat
open Input

let input = Csv.load ~separator:',' "entree.csv";; (*The error here is normal, Csv is not an Ocaml module *)

(* ===================== TYPEDEF ================= *)
type variable = {
 week: int;
 group : int;
 time_slot : int;
 id_colleur : int 
}



(* ===================== GLOBAL VARIABLES ================= *)
let number_of_weeks = 1 
let nb_groups = 16

let nb_tab = nb_math_phy_ang input
let time_slots_tab = time_slot_tab_and_number input 
let nom_colleur_tab = colleur_list_and_number input

let nb_slots = snd time_slots_tab (*17 times slots, 32 resources/disponibilities*)

let nb_colleur_math = nb_tab.(0)
let nb_colleur_phy = nb_tab.(1)
let nb_colleur_ang = nb_tab.(2)

let nb_total_colleurs = nb_colleur_ang + nb_colleur_math + nb_colleur_phy


(* ====================== COLLEUR DATA ===================== *)
let colleur_slots = colleurs_slots_array input

let colleur_names = colleur_name_array input

(* ================== UTILS ================= *)
let get_colleur_name id = 
  if id < Array.length colleur_names then colleur_names.(id) else "Inconnu"

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

let get_time_string t = 
  let arr = time_array input in
  arr.(t);;

let print_week_solution sol real_week_num =
  Printf.printf "\n=== SEMAINE %d ===\n" real_week_num;
  Printf.printf "Grp | %-10s | %-15s | Matière\n" "Créneau" "Professeur";
  Printf.printf "--------------------------------------------\n";
  Array.iteri (fun i valeur ->
    if valeur > 0 && i > 0 then
      let v = decode i in
      if v.week = 0 then
        let nom_prof = get_colleur_name v.id_colleur in
        let time_str = get_time_string v.time_slot in
        let matiere = if v.id_colleur < nb_colleur_math then "Maths" 
                      else if v.id_colleur < (nb_colleur_math + nb_colleur_phy) then "Physique" else "Anglais" in
        Printf.printf " %2d | %-10s | %-15s | %s\n" v.group time_str nom_prof matiere
  ) sol

let shuffle list = (*for the random between week*)
  let tagged = List.map (fun c -> (Random.bits (), c)) list in
  let sorted = List.sort compare tagged in
  List.map snd sorted

(* ================== HISTORIC LOGIC (Teachers Rotation) ================= *)

let last_seen_math = Array.make nb_groups (-1)
let last_seen_phy  = Array.make nb_groups (-1)
let last_seen_ang  = Array.make nb_groups (-1)

let limit_math = nb_colleur_math
let limit_phy  = nb_colleur_math + nb_colleur_phy

let is_math id = id < limit_math
let is_phy id  = id >= limit_math && id < limit_phy
let is_ang id  = id >= limit_phy

let update_prof_history sol =
  Array.iteri (fun i valeur ->
    if valeur > 0 && i > 0 then
      let v = decode i in
      if v.week = 0 then
        if is_math v.id_colleur then last_seen_math.(v.group) <- v.id_colleur
        else if is_phy v.id_colleur then last_seen_phy.(v.group) <- v.id_colleur
        else if is_ang v.id_colleur then last_seen_ang.(v.group) <- v.id_colleur
  ) sol

(* ================== CONSTRAINTS ================= *)
let rec at_most_one vars = 
  match vars with [] -> [] | h::t -> (List.map (fun y -> [-h; -y]) t) @ at_most_one t
let exactly_one vars = [vars] @ at_most_one vars

let generate_availability_constraints () = (*if Teacher isnt here, we can give him students *)
  let clauses = ref [] in
  for g = 0 to nb_groups - 1 do
    for t = 0 to nb_slots - 1 do
      for id = 0 to nb_total_colleurs - 1 do
        if not (List.mem t colleur_slots.(id)) then
          clauses := [-(encode {week=0; group=g; time_slot=t; id_colleur=id})] :: !clauses
      done
    done
  done; !clauses

let generate_resource_constraints () = (*Teacher's Ubiquity*)
  let clauses = ref [] in
  for id = 0 to nb_total_colleurs - 1 do
    for t = 0 to nb_slots - 1 do
      if List.mem t colleur_slots.(id) then
        let vars = ref [] in
        for g = 0 to nb_groups - 1 do
          vars := (encode {week=0; group=g; time_slot=t; id_colleur=id}) :: !vars
        done;
        clauses := !clauses @ (at_most_one !vars)
    done
  done; !clauses

let generate_student_ubiquity_constraints () = 
  let clauses = ref [] in
  for g = 0 to nb_groups - 1 do
    for t = 0 to nb_slots - 1 do
      let vars = ref [] in
      for id = 0 to nb_total_colleurs - 1 do
        if List.mem t colleur_slots.(id) then
          vars := (encode {week=0; group=g; time_slot=t; id_colleur=id}) :: !vars
      done;
      clauses := !clauses @ (at_most_one !vars)
    done
  done; !clauses


(* Even Week : Grp 0-7 = Physique, Grp 8-15 = Anglais *)
(* Odd Week : Grp 0-7 = Anglais, Grp 8-15 = Physique *)


let generate_parity_curriculum_constraints real_week =
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

    (* 2. MATHS : Always 1 colle *)
    clauses := !clauses @ (exactly_one !math_vars);

    (* 3. Parity Logic *)
    let must_do_phy = 
      if g < 8 then is_even_week    
      else not is_even_week          
    in

    if must_do_phy then (
      clauses := !clauses @ (exactly_one !phy_vars); (*Force Phy*)
      List.iter (fun v -> clauses := [-v] :: !clauses) !ang_vars
    ) else (
      clauses := !clauses @ (exactly_one !ang_vars);  (*Force Ang*)
      List.iter (fun v -> clauses := [-v] :: !clauses) !phy_vars
    )
    
  done; !clauses

(* Simple rotation: We forbid the previous teacher ONLY IN MATHS *)
(* For Physics and English, the system is saturated (8 slots for 8 groups), *)
(* so we must allow repeating a teacher, otherwise it causes a deadlock. *)

let generate_rotation_constraints () =
  let clauses = ref [] in
  for g = 0 to nb_groups - 1 do
    
    (* 1. Maths Rotation*)
    let last_m = last_seen_math.(g) in
    if last_m <> -1 then 
      for t=0 to nb_slots-1 do if List.mem t colleur_slots.(last_m) then
        clauses := [-(encode {week=0; group=g; time_slot=t; id_colleur=last_m})] :: !clauses
      done;
  done; !clauses

(* ================== MAIN ================= *)
(*let debug_data () =
  Printf.printf "\n=== DEBUG DATA ===\n";
  Printf.printf "Nombre de semaines : %d\n" number_of_weeks;
  Printf.printf "Nombre de groupes : %d\n" nb_groups;
  Printf.printf "Nombre de créneaux total (nb_slots) : %d\n" nb_slots;
  Printf.printf "Nombre de colleurs total : %d\n" nb_total_colleurs;
  Printf.printf "Maths: %d, Phy: %d, Ang: %d\n" nb_colleur_math nb_colleur_phy nb_colleur_ang;
  
  Printf.printf "\n--- Détail des disponibilités ---\n";
  Array.iteri (fun i slots ->
    let nom = get_colleur_name i in
    let nb = List.length slots in
    if nb = 0 then Printf.printf "[ALERTE] %s a 0 créneaux !\n" nom
    else Printf.printf "%s : %d créneaux\n" nom nb
  ) colleur_slots;
  Printf.printf "==================\n";
  flush stdout *)


let main () =
  (*debug_data ();*)
  Random.self_init ();
  Printf.printf "--- GÉNÉRATION AVEC PARITÉ (16 SEMAINES) ---\n";
  Printf.printf "Règle : Grp 0-7 (Sem1=Ang, Sem2=Phy) | Grp 8-15 (Sem1=Phy, Sem2=Ang)\n\n";

  for w = 0 to 15 do 
    let real_week = w + 1 in
    Printf.printf "Semaine %d... " real_week; flush stdout;
    
    let all_clauses = 
      generate_availability_constraints () @
      generate_resource_constraints () @
      generate_student_ubiquity_constraints () @
      generate_parity_curriculum_constraints real_week @
      generate_rotation_constraints () 
    in
    
    let shuffled_clauses = shuffle all_clauses in 
    (*shuffle on the clause because, first time : group 0 is on top of priority, if we don't shuffle, 
    it will stay on top of priority so the SAT will attribute the same teacher. Then, if we shuffle, for exemple the
    group 7 will be on the top and then all the teachers will be changed *)
    
    try
      let solution = Properly_sat.simplify_fnc shuffled_clauses in
      print_week_solution solution real_week;
      update_prof_history solution;
      Printf.printf "OK.\n";
    with Properly_sat.Unsatisfiable -> 
      Printf.printf "\n[ECHEC] Semaine %d impossible.\n" real_week; exit 0
  done

let () = main ()    