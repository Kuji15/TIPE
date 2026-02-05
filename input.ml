type csv = string list list

(* ================= UTILS ================= *)

(* Fonction qui supprime les espaces pour éviter les doublons "M. Nom" vs "M.Nom" *)
let normalize_name s =
  String.concat "" (String.split_on_char ' ' s)

let index_list e l =
  let rec aux curr idx = match curr with
    | [] -> -1 
    | h :: t -> if h = e then idx else aux t (idx + 1)
  in aux l 0

(*=============== USEFUL COLLOSCOPE FUNCTION =================== *)

let colleur_list_and_number (data : csv) = 
  let nom_colleur = ref [] in
  List.iter (fun line ->
    match line with
    | _ :: nom_brut :: _ -> 
        let nom = normalize_name nom_brut in (* <--- NETTOYAGE ICI *)
        if nom <> "Nom" && nom <> "" && not (List.mem nom !nom_colleur) then 
          nom_colleur := nom :: !nom_colleur
    | _ -> ()
  ) data;
  let l = List.rev !nom_colleur in
  (l, List.length l)

let colleur_name_array (data : csv) = 
  let l = fst (colleur_list_and_number data) in
  Array.of_list l

let nb_math_phy_ang (data : csv) = 
  let noms_vus = ref [] in
  let math_nb = ref 0 in 
  let phy_nb = ref 0 in 
  let ang_nb = ref 0 in 
  List.iter (fun line ->
    match line with
    | _ :: nom_brut :: matiere :: _ -> 
        let nom = normalize_name nom_brut in (* <--- NETTOYAGE ICI *)
        if nom <> "Nom" && nom <> "" && not (List.mem nom !noms_vus) then begin
          noms_vus := nom :: !noms_vus;
          match String.trim matiere with
          | "Math" | "Maths" -> incr math_nb
          | "Physique" | "Phys" -> incr phy_nb
          | _ -> incr ang_nb
        end
    | _ -> ()
  ) data;
  [|!math_nb; !phy_nb; !ang_nb|]

let time_slot_tab_and_number (data : csv) = 
  let time_slots = ref [] in
  List.iter (fun line ->
    match line with
    | horaire :: _ -> 
        if horaire <> "Horaires" && horaire <> "" && not (List.mem horaire !time_slots) then
          time_slots := horaire :: !time_slots
    | _ -> ()
  ) data;
  let l = List.rev !time_slots in 
  (l, List.length l)

let time_array (data : csv) = 
  let l = fst (time_slot_tab_and_number data) in
  Array.of_list l


(*The following function is creating an list array in which the i_th element of 
    the array represents the list of time slot where the colleur colle *)  
let colleurs_slots_array (data : csv) = 
  let c_and_n = colleur_list_and_number data in
  let t_and_n = time_slot_tab_and_number data in
  let all_time_slots = fst t_and_n in
  let nb_colleur = snd c_and_n in
  let colleurs_name = fst c_and_n in
  

  let slots = Array.make nb_colleur [] in

  List.iteri (fun i current_name_clean ->
    List.iter (fun line -> 
      match line with 
      | horaire :: nom_brut :: _ -> 
          if normalize_name nom_brut = current_name_clean then begin
            let t_index = index_list horaire all_time_slots in
            if t_index <> -1 then 
              slots.(i) <- t_index :: slots.(i)
          end
      | _ -> ()
    ) data
  ) colleurs_name;
  slots

let colleurs_subjects_array (data : csv) =
  let names = fst (colleur_list_and_number data) in
  let subjects = Array.make (List.length names) "" in
  
  List.iteri (fun i current_name ->
    try 
      let line = List.find (fun l -> 
        match l with 
        | _ :: n :: _ -> normalize_name n = current_name
        | _ -> false
      ) data in
      
      match line with
      | _ :: _ :: m :: _ -> subjects.(i) <- String.trim m
      | _ -> subjects.(i) <- "Inconnu"
    with Not_found -> subjects.(i) <- "Inconnu"
  ) names;
  subjects