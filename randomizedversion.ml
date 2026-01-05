open Properly_sat

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
let nb_slots = 32

let nb_colleur_math = 10
let nb_colleur_phy = 4
let nb_colleur_ang = 4
let nb_total_colleurs = 18

(* ====================== TIME SLOTS ===================== *)
let lun_09h = 0
let lun_11h10 = 1
let lun_12h10 = 2
let lun_17h20 = 3
let lun_18h20 = 4
let mar_13h10 = 5
let mar_15h10 = 6
let mar_15h20 = 7
let mar_16h10 = 8
let mar_16h20 = 9
let mar_17h10 = 10
let mar_18h00 = 11
let mer_12h10 = 12
let mer_13h10 = 13
let jeu_13h10 = 14
let jeu_17h20 = 15
let jeu_18h20 = 16

(* ====================== COLLEUR DATA ===================== *)
let colleur_slots = [|
  (* ====== MATHS (IDs 0 à 9) ==*)
  [lun_09h; mar_16h10; mer_12h10]; (* 0 Lellouche *)
  [lun_11h10];                     (* 1 Dunand *)
  [lun_17h20; lun_18h20];          (* 2 Vitetta *)
  [lun_17h20; lun_18h20];          (* 3 Levifve *)
  [mar_15h10; mar_16h10];          (* 4 Avigdor *)
  [mar_16h10];                     (* 5 Reynier *)
  [mer_12h10];                     (* 6 Bernanose *)
  [mer_12h10; jeu_13h10];          (* 7 Boulmezaoud *)
  [mer_13h10];                     (* 8 Duhalde *)
  [jeu_17h20; jeu_18h20];          (* 9 Perrin *)

  (* ======= PHYSIQUE (IDs 10 à 13) ====== *)
  [mar_18h00; mer_12h10];           (* 10 Metzdorff *)
  [mer_12h10; mer_13h10; jeu_17h20];(* 11 Gruat *)
  [jeu_17h20; jeu_18h20];           (* 12 Bedes *)
  [jeu_18h20];                      (* 13 Sautel *)

  (* ===== ANGLAIS (IDs 14 à 17) ======= *)
  [lun_12h10; mar_13h10];           (* 14 Boglio *)
  [mar_13h10; mar_15h20];           (* 15 Bendrif *)
  [mar_15h10];                      (* 16 Foliard *)
  [mar_15h10; mar_16h10; mar_17h10];(* 17 Mulheim *)
|]

let colleur_names = [|
  "M. Lellouche"; "M. Dunand"; "M. Vitetta"; "M. Levifve"; "M. Avigdor";
  "M. Reynier"; "M. Bernanose"; "M. Boulmezaoud"; "M. Duhalde"; "M. Perrin";
  "M. Metzdorff"; "M. Gruat"; "M. Bedes"; "M. Sautel";
  "Mme Boglio"; "Mme Bendrif"; "Mme Foliard"; "Mme Mulheim"
|]

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
  if t = lun_09h then "Lun 09h00" else if t = lun_11h10 then "Lun 11h10"
  else if t = lun_12h10 then "Lun 12h10" else if t = lun_17h20 then "Lun 17h20"
  else if t = lun_18h20 then "Lun 18h20" else if t = mar_13h10 then "Mar 13h10"
  else if t = mar_15h10 then "Mar 15h10" else if t = mar_15h20 then "Mar 15h20"
  else if t = mar_16h10 then "Mar 16h10" else if t = mar_17h10 then "Mar 17h10"
  else if t = mar_18h00 then "Mar 18h00" else if t = mer_12h10 then "Mer 12h10"
  else if t = mer_13h10 then "Mer 13h10" else if t = jeu_13h10 then "Jeu 13h10"
  else if t = jeu_17h20 then "Jeu 17h20" else if t = jeu_18h20 then "Jeu 18h20"
  else "Autre"

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
                      else if v.id_colleur < 14 then "Phys" else "Angl" in
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

let is_math id = id < nb_colleur_math
let is_phy id = id >= nb_colleur_math && id < 14
let is_ang id = id >= 14

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

(* Rotation simple : On interdit le prof précédent UNIQUEMENT EN MATHS *)
(* En Physique et Anglais, le système est trop saturé (8 places pour 8 groupes), *)
(* on est obligé d'autoriser le redoublement de prof sinon ça bloque. *)

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
let main () =
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