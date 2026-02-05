(* ================= PART 1 : UTILITARIES ================= *)

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

let to_lower s =
  String.map Char.lowercase_ascii s

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

(* ================= PART 2 : SUBJECT SORT ================= *)


let get_prof_rank prof_name =
  try
    let ic = open_in "entree.csv" in
    let target = to_lower (String.trim prof_name) in
    
    let rec loop () =
      try
        let line = input_line ic in
        let parts = split_string ',' line in
        match parts with
        | _ :: name_csv :: matiere_csv :: _ ->
            let name_clean = to_lower (String.trim name_csv) in
            if name_clean <> "" && (contains name_clean target || contains target name_clean) then
              let m = to_lower matiere_csv in
            
              if contains m "math" || contains m "alg" || contains m "geom" || contains m "analy" then 1
              else if contains m "phy" || contains m "chim" || contains m "opt" || contains m "elec" || contains m "meca" then 2
              else if contains m "ang" || contains m "eng" || contains m "lv1" || contains m "esp" || contains m "all" then 3
              else if contains m "info" then 4
              else 5 
            else loop ()
        | _ -> loop ()
      with End_of_file -> 5
    in
    let res = loop () in
    close_in ic;
    res
  with _ -> 5
let compare_rows (c1, p1) (c2, p2) =
  let r1 = get_prof_rank p1 in
  let r2 = get_prof_rank p2 in
  if r1 <> r2 then compare r1 r2
  else
    let cmp_prof = String.compare p1 p2 in
    if cmp_prof <> 0 then cmp_prof 
    else String.compare c1 c2  

(* ================= PART 3 : CSV GENERATION ================= *)

type record_export = {
  semaine: int;
  groupe: int;
  creneau: string;
  prof: string;
  matiere: string;
}


let generate_csv_content (records : record_export list) (weeks : int list) =
  
  let raw_keys = List.map (fun r -> (r.creneau, r.prof, r.matiere)) records in
  
  let unique_keys = 
    List.fold_left (fun acc x -> 
      if List.mem x acc then acc else x :: acc
    ) [] raw_keys 
  in

  let rows_header = List.sort (fun (c1, p1, _) (c2, p2, _) -> 
    compare_rows (c1, p1) (c2, p2)
  ) unique_keys in
  let header_line = 
    ["Creneau"; "Professeur"; "Matiere"] @ 
    (List.map (fun w -> "S" ^ string_of_int w) weeks) 
  in
  let csv_rows = List.map (fun (creneau, prof, matiere) ->
    let row_start = [creneau; prof; matiere] in
    
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

  header_line :: csv_rows

(* ================= PART 4 : FINAL EXPORT ================= *)

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

let export_to_csv base_filename (assignments : record_export list) weeks =
  let safe_filename = get_unique_filename base_filename in
  Printf.printf "Ecriture dans %s...\n" safe_filename;
  let content_list = generate_csv_content assignments weeks in
  
  let oc = open_out safe_filename in
  List.iter (fun row ->
    let line = String.concat "," row in
    output_string oc (line ^ "\n")
  ) content_list;
  close_out oc;
  Printf.printf "Fichier cree avec succes.\n"