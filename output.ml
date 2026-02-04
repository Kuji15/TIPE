(* output.ml *)

(* ================= PARTIE 1 : OUTILS ROBUSTES (COMPATIBILITÉ) ================= *)

(* Fonction split manuelle (car String.split_on_char n'existe pas sur les vieux OCaml) *)
let split_string sep s =
  let rec aux acc i =
    try
      let idx = String.index_from s i sep in
      let sub = String.sub s i (idx - i) in
      aux (sub :: acc) (idx + 1)
    with Not_found ->
      let sub = String.sub s i (String.length s - i) in
      List.rev (sub :: acc)
  in
  aux [] 0

(* Met en minuscule proprement *)
let to_lower s =
  String.map Char.lowercase_ascii s

(* Cherche si s1 contient sub (insensible à la casse) *)
let contains s sub =
  let len_s = String.length s in
  let len_sub = String.length sub in
  if len_sub > len_s then false
  else
    let rec check i =
      if i > len_s - len_sub then false
      else
        if String.sub s i len_sub = sub then true
        else check (i + 1)
    in
    check 0

(* ================= PARTIE 2 : TRI CHRONOLOGIQUE INTELLIGENT ================= *)

(* Trouve le jour dans la chaîne *)
let get_day_weight s =
  let low_s = to_lower s in
  if contains low_s "lun" then 1
  else if contains low_s "mar" then 2
  else if contains low_s "mer" then 3
  else if contains low_s "jeu" then 4
  else if contains low_s "ven" then 5
  else if contains low_s "sam" then 6
  else if contains low_s "dim" then 7
  else 99 (* Pas de jour trouvé *)

(* Extrait le premier nombre trouvé dans la chaîne (l'heure) *)
let get_first_number s =
  let len = String.length s in
  let rec find_digit_start i =
    if i >= len then None
    else match s.[i] with
    | '0'..'9' -> Some i
    | _ -> find_digit_start (i + 1)
  in
  match find_digit_start 0 with
  | None -> 0 (* Pas de chiffre -> on met 0h par défaut *)
  | Some start ->
      let rec find_digit_end i =
        if i >= len then i
        else match s.[i] with
        | '0'..'9' -> find_digit_end (i + 1)
        | _ -> i
      in
      let end_idx = find_digit_end start in
      try 
        int_of_string (String.sub s start (end_idx - start))
      with _ -> 0

(* Calcule le score final : Jour * 100 + Heure *)
let get_slot_score creneau_str =
  let w_jour = get_day_weight creneau_str in
  let h = get_first_number creneau_str in
  (w_jour * 100) + h

(* Comparaison pour le tri *)
let compare_rows (c1, p1) (c2, p2) =
  let score1 = get_slot_score c1 in
  let score2 = get_slot_score c2 in
  if score1 <> score2 then score1 - score2
  else String.compare p1 p2

(* ================= PARTIE 3 : FORMATAGE MATRICE (PIVOT) ================= *)

type assignment = {
  semaine: int;
  groupe: int;
  creneau: string;
  prof: string;
}

let to_record (s, g, c, p) = { semaine=s; groupe=g; creneau=c; prof=p }

let pivot_data assignments =
  let records = List.map to_record assignments in
  
  (* 1. Liste des semaines (Colonnes) *)
  let weeks = 
    List.map (fun r -> r.semaine) records 
    |> List.sort_uniq compare 
  in

  (* 2. Liste Créneau+Prof triée chronologiquement (Lignes) *)
  let rows_header = 
    List.map (fun r -> (r.creneau, r.prof)) records 
    |> List.sort_uniq compare_rows
  in

  (* 3. En-tête *)
  let header = 
    ["Creneau"; "Professeur"] @ 
    (List.map (fun w -> "S" ^ string_of_int w) weeks) 
  in

  (* 4. Remplissage *)
  let csv_rows = List.map (fun (creneau, prof) ->
    let row_start = [creneau; prof] in
    
    let week_cells = List.map (fun w ->
      try
        let found = List.find (fun r -> 
          r.semaine = w && r.creneau = creneau && r.prof = prof
        ) records in
        string_of_int found.groupe
      with Not_found -> ""
    ) weeks in
    
    row_start @ week_cells
  ) rows_header in

  header :: csv_rows

(* ================= PARTIE 4 : EXPORT FINAL ================= *)

let get_unique_filename base_name =
  if not (Sys.file_exists base_name) then base_name
  else
    let rec find_free_name i =
      let name_without_ext = Filename.remove_extension base_name in
      let ext = Filename.extension base_name in
      let candidate = Printf.sprintf "%s_%d%s" name_without_ext i ext in
      if not (Sys.file_exists candidate) then candidate
      else find_free_name (i + 1)
    in
    find_free_name 1

let export_to_csv base_filename raw_assignments =
  let safe_filename = get_unique_filename base_filename in
  Printf.printf "Transformation des données (Tri Chronologique Robust)...\n";
  let csv_content = pivot_data raw_assignments in
  try
    Csv.save safe_filename csv_content;
    Printf.printf "\n[SUCCES] Fichier généré : %s\n" safe_filename
  with e ->
    Printf.printf "\n[ERREUR] Impossible d'écrire le fichier : %s\n" (Printexc.to_string e)