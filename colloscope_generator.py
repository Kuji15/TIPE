import customtkinter as ctk
from tkinter import filedialog, messagebox
import subprocess
import shutil
import os
import sys
import threading
import pandas as pd
import re
import traceback
import xlsxwriter
import time

# --- LOGIQUE MÉTIER (INTOUCHABLE) ---
# --- (C'est exactement le code qui fonctionne, ne pas modifier) ---

if sys.platform.startswith('win'):
    EXECUTABLE_NAME = "colloscope.exe"
else:
    EXECUTABLE_NAME = "colloscope"

def resource_path(relative_path):
    try:
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)

def sanitize_input_for_ocaml(input_path, target_path):
    try:
        try:
            df = pd.read_csv(input_path, header=None, engine='python', encoding='utf-8')
        except:
            df = pd.read_csv(input_path, header=None, engine='python', encoding='latin-1')
        
        df = df.iloc[:, :3]
        df = df.fillna("")
        first = str(df.iloc[0, 0]).lower()
        if any(x in first for x in ["horaire", "jour", "creneau", "nom"]):
            df = df.iloc[1:]
        df.to_csv(target_path, index=False, header=False, sep=',', encoding='utf-8')
    except Exception as e:
        raise ValueError(f"Erreur nettoyage : {e}")

def convert_to_styled_excel(input_ocaml_csv, output_excel_path):
    print("--- ÉTAPE 1 : LECTURE ---")
    try:
        df = pd.read_csv(input_ocaml_csv, encoding='utf-8')
    except:
        df = pd.read_csv(input_ocaml_csv, encoding='latin-1')

    df.columns = [c.strip() for c in df.columns]
    col_map = {}
    week_cols = []
    for c in df.columns:
        low = c.lower()
        if "creneau" in low or "slot" in low: col_map[c] = "Creneau"
        elif "prof" in low: col_map[c] = "Professeur"
        elif "mat" in low: col_map[c] = "Matiere"
        elif c.upper().startswith("S") and c[1:].isdigit(): week_cols.append(c)
    
    df = df.rename(columns=col_map)
    if "Matiere" not in df.columns: df["Matiere"] = "Inconnu"
    if "Creneau" not in df.columns: df["Creneau"] = ""

    print("--- ÉTAPE 2 : CALCUL DES SCORES ---")
    def calculate_sort_key(row):
        mat = str(row['Matiere']).lower()
        if "math" in mat: s_mat = 1
        elif "phys" in mat: s_mat = 2
        elif "ang" in mat: s_mat = 3
        elif "info" in mat: s_mat = 4
        else: s_mat = 9

        cren = str(row['Creneau']).lower()
        if "lun" in cren: s_jour = 1
        elif "mar" in cren: s_jour = 2
        elif "mer" in cren: s_jour = 3
        elif "jeu" in cren: s_jour = 4
        elif "ven" in cren: s_jour = 5
        elif "sam" in cren: s_jour = 6
        else: s_jour = 9
        
        nums = re.findall(r'\d+', cren)
        if len(nums) >= 2: minutes = int(nums[0]) * 60 + int(nums[1])
        elif len(nums) == 1: minutes = int(nums[0]) * 60
        else: minutes = 0

        return (s_mat * 100000) + (s_jour * 10000) + minutes

    df['SCORE_TRI'] = df.apply(calculate_sort_key, axis=1)

    print("--- ÉTAPE 3 : TRI ET SAUVEGARDE INTERMÉDIAIRE ---")
    df_sorted = df.sort_values(by='SCORE_TRI', ascending=True)
    
    final_cols = ['Professeur', 'Matiere', 'Creneau', 'SCORE_TRI'] + week_cols
    final_cols = [c for c in final_cols if c in df_sorted.columns]
    df_ready = df_sorted[final_cols]

    temp_csv = "temp_sorted_debug.csv"
    df_ready.to_csv(temp_csv, index=False, encoding='utf-8')
    
    with open("VERIFICATION_TRI.txt", "w", encoding="utf-8") as f:
        for idx, row in df_ready.iterrows():
            f.write(f"{row['Professeur']} | {row['Matiere']} | {row['Creneau']} -> {row['SCORE_TRI']}\n")

    print("--- ÉTAPE 4 : RELECTURE PROPRE ET EXCEL ---")
    df_final_clean = pd.read_csv(temp_csv, encoding='utf-8')
    df_final_clean = df_final_clean.rename(columns={'Matiere': 'Matière', 'Creneau': 'Créneau'})
    
    writer = pd.ExcelWriter(output_excel_path, engine='xlsxwriter')
    cols_export = [c for c in df_final_clean.columns if c != 'SCORE_TRI']
    df_export = df_final_clean[cols_export]
    
    df_export.to_excel(writer, sheet_name='Colloscope', index=False)
    
    wb = writer.book
    ws = writer.sheets['Colloscope']
    
    colors = ["#FFB3BA", "#BAFFC9", "#BAE1FF", "#FFFFBA", "#FFDFBA", "#E0BBE4", "#957DAD", "#D291BC", "#FEC8D8", "#FFDFD3", "#B5EAD7", "#C7CEEA", "#E2F0CB", "#F2D7EE", "#D4F0F0", "#FDFD96"]
    formats = [wb.add_format({'bg_color': c, 'border': 1, 'align': 'center'}) for c in colors]
    fmt_base = wb.add_format({'border': 1, 'align': 'center', 'valign': 'vcenter'})
    fmt_head = wb.add_format({'bold': True, 'bg_color': '#D3D3D3', 'border': 1, 'align': 'center'})

    for i, col in enumerate(df_export.columns):
        ws.write(0, i, str(col), fmt_head)

    ws.set_column(0, 0, 20)
    ws.set_column(1, 1, 12)
    ws.set_column(2, 2, 16)

    start_col = 3
    for r_idx in range(len(df_export)):
        row = df_export.iloc[r_idx]
        ws.write(r_idx+1, 0, row.iloc[0], fmt_base)
        ws.write(r_idx+1, 1, row.iloc[1], fmt_base)
        ws.write(r_idx+1, 2, row.iloc[2], fmt_base)
        for c_idx in range(start_col, len(df_export.columns)):
            val = row.iloc[c_idx]
            if pd.isna(val) or str(val) == "":
                ws.write(r_idx+1, c_idx, "", fmt_base)
            else:
                try:
                    gid = int(float(val)) 
                    ws.write(r_idx+1, c_idx, gid, formats[gid % 16])
                except:
                    ws.write(r_idx+1, c_idx, str(val), fmt_base)
    writer.close()
    try: os.remove(temp_csv)
    except: pass

# --- NOUVELLE INTERFACE GRAPHIQUE (RESPONSIVE) ---

ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")

class ColloscopeApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        # Fenêtre Principale
        self.title("Colloscope Generator : TIPE")
        self.geometry("900x700") # Un peu plus grand au démarrage
        self.minsize(800, 600)   # Taille minimale pour ne pas casser le design
        self.resizable(True, True) # ✅ ON AUTORISE LE GRAND ÉCRAN
        
        # Variables
        self.input_filepath = None
        self.temp_output_path = None
        
        # --- LAYOUT PRINCIPAL ---
        # Une grille qui s'adapte
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(1, weight=1) # Le contenu s'étire

        # 1. HEADER (Titre)
        self.header_frame = ctk.CTkFrame(self, height=80, corner_radius=0, fg_color="#1F2937")
        self.header_frame.grid(row=0, column=0, sticky="ew")
        self.header_frame.grid_propagate(False)
        
        ctk.CTkLabel(self.header_frame, text="Générateur de Colloscope : TIPE", 
                     font=("Roboto Medium", 26), text_color="white").pack(side="top", padx=40, pady=10)

        # 2. CONTAINER SCROLLABLE (Optionnel, mais ici Frame simple centré)
        # On utilise une Frame centrée pour que sur grand écran, les boutons ne soient pas écartelés
        self.main_container = ctk.CTkFrame(self, fg_color="transparent")
        self.main_container.grid(row=1, column=0, padx=20, pady=20, sticky="nsew")
        self.main_container.grid_columnconfigure(0, weight=1)

        # --- ÉTAPE 1 : IMPORT ---
        self.card_1 = ctk.CTkFrame(self.main_container, corner_radius=15, fg_color="#374151")
        self.card_1.grid(row=0, column=0, sticky="ew", pady=(0, 20), padx=50) # Padding X pour centrer visuellement
        
        ctk.CTkLabel(self.card_1, text="ÉTAPE 1", font=("Roboto", 12, "bold"), text_color="#60A5FA").pack(anchor="w", padx=30, pady=(20, 0))
        ctk.CTkLabel(self.card_1, text="Importez le fichier des disponibilités", font=("Roboto", 18)).pack(anchor="w", padx=30, pady=(0, 15))
        
        # BOUTON : Largeur fixe (450), Hauteur (55)
        self.btn_import = ctk.CTkButton(self.card_1, text="📂  Choisir le fichier CSV", 
                                      command=self.load_csv, 
                                      height=55, width=450, # ✅ PLUS HAUT, MOINS LONG
                                      font=("Roboto", 15, "bold"), fg_color="#2563EB", hover_color="#1D4ED8")
        self.btn_import.pack(pady=(0, 10)) # Pas de fill="x", il reste centré
        
        self.lbl_filename = ctk.CTkLabel(self.card_1, text="Aucun fichier sélectionné", text_color="#9CA3AF")
        self.lbl_filename.pack(pady=(0, 20))

        # --- ÉTAPE 2 : TRAITEMENT ---
        self.card_2 = ctk.CTkFrame(self.main_container, corner_radius=15, fg_color="#374151")
        self.card_2.grid(row=1, column=0, sticky="ew", pady=(0, 20), padx=50)
        
        ctk.CTkLabel(self.card_2, text="ÉTAPE 2", font=("Roboto", 12, "bold"), text_color="#F472B6").pack(anchor="w", padx=30, pady=(20, 0))
        
        self.status_frame = ctk.CTkFrame(self.card_2, fg_color="transparent")
        self.status_frame.pack(fill="x", padx=30)
        ctk.CTkLabel(self.status_frame, text="Lancer le calcul", font=("Roboto", 18)).pack(side="left", pady=(0, 10))
        
        self.progress_bar = ctk.CTkProgressBar(self.card_2, orientation="horizontal", mode="indeterminate", width=450)
        # Cachée par défaut

        self.btn_run = ctk.CTkButton(self.card_2, text="🚀  Générer le colloscope", 
                                   command=self.start_generation, 
                                   height=55, width=450, # ✅ PLUS HAUT, MOINS LONG
                                   font=("Roboto", 15, "bold"), 
                                   fg_color="#DB2777", hover_color="#BE185D", state="disabled")
        self.btn_run.pack(pady=(0, 20))

        # --- ÉTAPE 3 : EXPORT ---
        self.card_3 = ctk.CTkFrame(self.main_container, corner_radius=15, fg_color="#374151")
        self.card_3.grid(row=2, column=0, sticky="ew", pady=(0, 20), padx=50)
        
        ctk.CTkLabel(self.card_3, text="ÉTAPE 3", font=("Roboto", 12, "bold"), text_color="#34D399").pack(anchor="w", padx=30, pady=(20, 0))
        ctk.CTkLabel(self.card_3, text="Sauvegarder le résultat", font=("Roboto", 18)).pack(anchor="w", padx=30, pady=(0, 15))
        
        self.btn_save = ctk.CTkButton(self.card_3, text="💾  Télécharger le fichier (.xlsx)", 
                                    command=self.save_file, 
                                    height=55, width=450, # ✅ PLUS HAUT, MOINS LONG
                                    font=("Roboto", 15, "bold"),
                                    fg_color="#059669", hover_color="#047857", state="disabled")
        self.btn_save.pack(pady=(0, 20))

        # 3. CONSOLE (Logs)
        self.console_frame = ctk.CTkFrame(self, height=120, fg_color="#111827", corner_radius=0)
        self.console_frame.grid(row=2, column=0, sticky="ew")
        self.console_frame.grid_propagate(False)
        
        ctk.CTkLabel(self.console_frame, text="JOURNAL D'ACTIVITÉ", font=("Consolas", 10, "bold"), text_color="#6B7280").pack(anchor="w", padx=10, pady=(5,0))
        
        self.txt_logs = ctk.CTkTextbox(self.console_frame, font=("Consolas", 11), fg_color="transparent", text_color="#D1D5DB")
        self.txt_logs.pack(fill="both", expand=True, padx=10, pady=5)

    def log(self, message):
        self.txt_logs.configure(state="normal")
        self.txt_logs.insert("end", "> " + str(message) + "\n")
        self.txt_logs.see("end")
        self.txt_logs.configure(state="disabled")

    def load_csv(self):
        fn = filedialog.askopenfilename()
        if fn:
            self.input_filepath = fn
            self.lbl_filename.configure(text=f"Fichier : {os.path.basename(fn)}", text_color="white")
            self.btn_run.configure(state="normal")
            self.log(f"Source chargée : {os.path.basename(fn)}")

    def start_generation(self):
        self.btn_run.configure(state="disabled", text="Calcul en cours...")
        self.progress_bar.pack(pady=(0, 10)) # Afficher la barre
        self.progress_bar.start()
        threading.Thread(target=self.run_process, daemon=True).start()

    def run_process(self):
        try:
            exe = resource_path(EXECUTABLE_NAME)
            wd = os.getcwd()
            target_input = os.path.join(wd, "entree.csv")
            
            sanitize_input_for_ocaml(self.input_filepath, target_input)
            
            self.log("Démarrage du moteur OCaml...")
            
            startupinfo = None
            if sys.platform == "win32":
                startupinfo = subprocess.STARTUPINFO()
                startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW

            p = subprocess.Popen([exe], cwd=wd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, 
                                 text=True, encoding='utf-8', errors='replace', startupinfo=startupinfo)
            for line in p.stdout: self.log(line.strip())
            p.wait()
            
            files = [f for f in os.listdir(wd) if "colloscope_final" in f and f.endswith(".csv")]
            if not files: raise FileNotFoundError("Pas de fichier généré.")
            files.sort(key=lambda x: os.path.getmtime(os.path.join(wd, x)), reverse=True)
            self.temp_output_path = os.path.join(wd, files[0])
            self.log(f"Succès OCaml. Fichier brut : {files[0]}")

            if p.returncode == 0:
                self.after(0, self.on_success)
            else:
                self.log(f"Erreur OCaml ({p.returncode})")
                self.after(0, self.stop_loading_fail)
                
        except Exception as e:
            self.log(f"CRASH : {e}")
            self.after(0, self.stop_loading_fail)

    def stop_loading_fail(self):
        self.progress_bar.stop()
        self.progress_bar.pack_forget()
        self.btn_run.configure(state="normal", text="🚀  Générer la Répartition")

    def on_success(self):
        self.progress_bar.stop()
        self.progress_bar.pack_forget()
        self.btn_run.configure(text="✅  Calcul Terminé")
        self.btn_save.configure(state="normal")
        self.log("Prêt pour l'export Excel.")

    def save_file(self):
        tp = filedialog.asksaveasfilename(defaultextension=".xlsx", filetypes=[("Excel", "*.xlsx")])
        if tp:
            try:
                convert_to_styled_excel(self.temp_output_path, tp)
                try:
                    if sys.platform == "win32": os.startfile(tp)
                    elif sys.platform == "darwin": subprocess.call(["open", tp])
                    else: subprocess.call(["xdg-open", tp])
                except: pass
                messagebox.showinfo("Succès", "Votre Colloscope est prêt !")
            except Exception:
                err = traceback.format_exc()
                messagebox.showerror("ERREUR", f"Détails :\n{err}")
                shutil.copy(self.temp_output_path, tp)

if __name__ == "__main__":
    app = ColloscopeApp()
    app.mainloop()