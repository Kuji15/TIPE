import customtkinter as ctk
from tkinter import filedialog, messagebox
import subprocess
import shutil
import os
import sys
import threading
import pandas as pd # NOUVEAU : Pour gérer les données
import numpy as np

# --- CONFIGURATION ---
ctk.set_appearance_mode("System")
ctk.set_default_color_theme("blue")

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

# --- FONCTION MAGIQUE DE STYLISATION ---
def convert_to_styled_excel(input_csv, output_excel):
    """
    Transforme le CSV OCaml (déjà formaté en tableau) 
    en un beau fichier Excel coloré.
    """
    # 1. Lecture du CSV tel quel (il est déjà pivoté par OCaml)
    try:
        df = pd.read_csv(input_csv)
    except Exception as e:
        raise ValueError(f"Impossible de lire le CSV : {str(e)}")

    # 2. Création du fichier Excel
    writer = pd.ExcelWriter(output_excel, engine='xlsxwriter')
    
    # On écrit le DataFrame tel quel, sans l'index (0, 1, 2...)
    df.to_excel(writer, sheet_name='Colloscope', index=False)

    workbook = writer.book
    worksheet = writer.sheets['Colloscope']

    # 3. Définition des Styles (Nuances de Vert)
    green_formats = []
    base_colors = [
        "#E8F5E9", "#C8E6C9", "#A5D6A7", "#81C784", 
        "#66BB6A", "#4CAF50", "#43A047", "#388E3C",
        "#2E7D32", "#1B5E20", "#69F0AE", "#00E676",
        "#00C853", "#B9F6CA", "#CCFF90", "#76FF03"
    ]
    
    # Création des objets formats
    for color in base_colors:
        f = workbook.add_format({'bg_color': color, 'border': 1, 'align': 'center', 'valign': 'vcenter'})
        green_formats.append(f)

    # Style par défaut (case vide ou en-tête)
    fmt_center = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'border': 1})
    fmt_header = workbook.add_format({'bold': True, 'bg_color': '#D3D3D3', 'border': 1, 'align': 'center', 'valign': 'vcenter'})

    # 4. Mise en page
    worksheet.set_column(0, 0, 15) # Colonne Créneau large
    worksheet.set_column(1, 1, 20) # Colonne Prof large
    worksheet.set_column(2, 20, 5) # Colonnes S1...S16 fines

    # 5. Application des couleurs
    # On itère sur les données du DataFrame
    # Attention : df.shape donne (nb_lignes, nb_colonnes)
    # Dans Excel, les données commencent à la ligne 1 (la ligne 0 est l'en-tête)
    
    for r_idx, row in df.iterrows():
        # On parcourt les colonnes
        for c_idx, col_name in enumerate(df.columns):
            # Les 2 premières colonnes sont Creneau et Prof -> On ne touche pas, ou on met une bordure simple
            if c_idx < 2:
                worksheet.write(r_idx + 1, c_idx, row[col_name], fmt_center)
                continue

            val = row[col_name]
            
            # On essaie de voir si c'est un numéro de groupe (Entier)
            try:
                # Pandas peut lire les vides comme NaN (float) ou None
                if pd.isna(val) or val == "":
                    worksheet.write(r_idx + 1, c_idx, "", fmt_center)
                else:
                    group_id = int(val)
                    # Couleur modulo 16
                    color_idx = group_id % 16
                    cell_format = green_formats[color_idx]
                    worksheet.write(r_idx + 1, c_idx, group_id, cell_format)
            except (ValueError, TypeError):
                # Si conversion impossible (ex: du texte parasite), on écrit en blanc
                worksheet.write(r_idx + 1, c_idx, str(val), fmt_center)

    # Réécriture propre des en-têtes (pour le style gris)
    for c_idx, col_name in enumerate(df.columns):
        worksheet.write(0, c_idx, col_name, fmt_header)

    writer.close()

# --- POPUP CUSTOM ---
class CustomPopup(ctk.CTkToplevel):
    def __init__(self, parent, title, message, status="success"):
        super().__init__(parent)
        width = 350
        height = 250
        self.geometry(f"{width}x{height}")
        self.title(title)
        self.resizable(False, False)
        self.attributes("-topmost", True)
        self.grab_set()

        if status == "success":
            icon_text = "✔"
            color = "#2CC985"
        else:
            icon_text = "✖"
            color = "#FF4757"

        self.lbl_icon = ctk.CTkLabel(self, text=icon_text, font=("Segoe UI", 50, "bold"), text_color=color)
        self.lbl_icon.pack(pady=(20, 10))
        self.lbl_title = ctk.CTkLabel(self, text=title.upper(), font=("Segoe UI", 16, "bold"))
        self.lbl_title.pack(pady=(0, 5))
        self.lbl_msg = ctk.CTkLabel(self, text=message, font=("Segoe UI", 12), text_color="gray", wraplength=300)
        self.lbl_msg.pack(pady=(0, 20))
        self.btn_close = ctk.CTkButton(self, text="C'est noté", command=self.destroy,
                                       fg_color=color, hover_color=color,
                                       width=120, height=35, font=("Segoe UI", 12, "bold"))
        self.btn_close.pack(pady=10)

# --- APPLICATION ---
class ColloscopeApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Générateur de Colloscope")
        self.geometry("600x550")
        self.resizable(False, True)
        self.input_filepath = None
        self.temp_output_path = None
        self.process = None

        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(4, weight=1)

        self.lbl_title = ctk.CTkLabel(self, text="Générateur d'Emploi du Temps", font=("Segoe UI", 24, "bold"))
        self.lbl_title.grid(row=0, column=0, pady=(20, 5))
        self.lbl_subtitle = ctk.CTkLabel(self, text="Optimisation par SAT Solver", font=("Segoe UI", 13), text_color="gray")
        self.lbl_subtitle.grid(row=1, column=0, pady=(0, 20))

        self.main_card = ctk.CTkFrame(self, fg_color=("white", "#2b2b2b"), corner_radius=20)
        self.main_card.grid(row=2, column=0, padx=40, pady=0, sticky="ew")
        self.main_card.grid_columnconfigure(0, weight=1)

        self.lbl_step1 = ctk.CTkLabel(self.main_card, text="1. Données d'entrée", font=("Segoe UI", 14, "bold"), anchor="w")
        self.lbl_step1.grid(row=0, column=0, padx=30, pady=(20, 10), sticky="w")
        self.btn_import = ctk.CTkButton(self.main_card, text="Importer le fichier CSV", command=self.load_csv, fg_color="gray", hover_color="#555", width=280, height=45, font=("Segoe UI", 13))
        self.btn_import.grid(row=1, column=0, pady=5)
        self.lbl_filename = ctk.CTkLabel(self.main_card, text="Aucun fichier choisi", font=("Segoe UI", 12), text_color="gray")
        self.lbl_filename.grid(row=2, column=0, pady=(0, 15))

        self.separator = ctk.CTkProgressBar(self.main_card, height=2, progress_color="gray")
        self.separator.set(1)
        self.separator.grid(row=3, column=0, padx=30, pady=10, sticky="ew")

        self.lbl_step2 = ctk.CTkLabel(self.main_card, text="2. Calcul", font=("Segoe UI", 14, "bold"), anchor="w")
        self.lbl_step2.grid(row=4, column=0, padx=30, pady=(10, 10), sticky="w")
        self.btn_run = ctk.CTkButton(self.main_card, text="LANCER L'OPTIMISATION", command=self.start_generation, state="disabled", width=280, height=45, font=("Segoe UI", 13, "bold"))
        self.btn_run.grid(row=5, column=0, pady=10)
        self.progress_bar = ctk.CTkProgressBar(self.main_card, height=10, mode="indeterminate", width=300)
        self.progress_bar.grid(row=6, column=0, padx=30, pady=(0, 20))
        self.progress_bar.grid_remove()

        self.btn_save = ctk.CTkButton(self.main_card, text="📥 TÉLÉCHARGER LE RÉSULTAT", command=self.save_file, fg_color="#2CC985", hover_color="#25A970", width=280, height=45, font=("Segoe UI", 13, "bold"))
        self.btn_save.grid(row=7, column=0, pady=(10, 30))
        self.btn_save.grid_remove()

        self.lbl_logs = ctk.CTkLabel(self, text="Détails techniques :", font=("Segoe UI", 10), anchor="w")
        self.lbl_logs.grid(row=3, column=0, padx=40, pady=(20, 0), sticky="w")
        self.txt_logs = ctk.CTkTextbox(self, height=80, font=("Consolas", 10), fg_color=("white", "#1a1a1a"), text_color="gray", corner_radius=10)
        self.txt_logs.grid(row=4, column=0, padx=30, pady=(5, 20), sticky="nsew")
        self.txt_logs.configure(state="disabled")

    def log(self, message):
        def _update():
            self.txt_logs.configure(state="normal")
            self.txt_logs.insert("end", "> " + message + "\n")
            self.txt_logs.see("end")
            self.txt_logs.configure(state="disabled")
        self.after(0, _update)

    def load_csv(self):
            initial_dir = os.path.join(os.path.expanduser('~'), 'Documents')
            
            filename = filedialog.askopenfilename(
                title="Sélectionnez le fichier CSV des professeurs",
                initialdir=initial_dir,
                filetypes=[
                    ("Fichiers CSV (Excel)", "*.csv"),
                    ("Tous les fichiers", "*.*")
                ]
            )

            if filename:
                basename = os.path.basename(filename)
                
                # --- VERIFICATION DE SÉCURITÉ ---
                # On empêche l'utilisateur d'utiliser "entree.csv" car c'est notre fichier de travail interne
                if basename.lower() == "entree.csv":
                    CustomPopup(self, 
                                "Nom de fichier interdit", 
                                "Le fichier ne doit pas s'appeler 'entree.csv'.\n"
                                "C'est un nom réservé par le logiciel pour ses calculs.\n\n"
                                "Veuillez renommer votre fichier (ex: 'profs.csv') et réessayez.", 
                                status="error")
                    return # On arrête tout ici, on ne charge pas le fichier
                # -------------------------------

                self.input_filepath = filename
                
                self.lbl_filename.configure(text=f"✔ {basename}", text_color=("#2CC985", "#2CC985"))
                self.btn_import.configure(fg_color=("gray75", "gray30"), border_color="#2CC985", border_width=2)
                
                self.btn_run.configure(state="normal")
                self.btn_save.grid_remove()
                self.log(f"Fichier chargé : {basename}")

    def start_generation(self):
        self.btn_run.configure(state="disabled", text="Calcul en cours...")
        self.btn_import.configure(state="disabled")
        self.btn_save.grid_remove()
        self.progress_bar.grid()
        self.progress_bar.start()
        self.txt_logs.configure(state="normal")
        self.txt_logs.delete("1.0", "end")
        self.txt_logs.configure(state="disabled")
        threading.Thread(target=self.run_ocaml_process, daemon=True).start()

    def run_ocaml_process(self):
        try:
            executable_path = resource_path(EXECUTABLE_NAME)
            work_dir = os.getcwd()
            target_csv = os.path.join(work_dir, "entree.csv")
            self.temp_output_path = os.path.join(work_dir, "colloscope_final.csv")
            if os.path.exists(self.temp_output_path): os.remove(self.temp_output_path)
            if not os.path.exists(executable_path): raise FileNotFoundError("Moteur OCaml introuvable.")
            shutil.copy(self.input_filepath, target_csv)
            self.log("Démarrage du moteur...")
            self.process = subprocess.Popen([executable_path], cwd=work_dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1, universal_newlines=True, encoding='utf-8', errors='replace')
            for line in self.process.stdout:
                line = line.strip()
                if line: self.log(line)
            self.process.wait()
            if self.process.returncode == 0 and os.path.exists(self.temp_output_path):
                self.after(0, self.on_success)
            else:
                self.log(f"Erreur code : {self.process.returncode}")
                self.after(0, self.on_failure)
        except Exception as e:
            self.log(f"Erreur critique : {str(e)}")
            self.after(0, self.on_failure)

    def on_success(self):
        self.progress_bar.stop()
        self.progress_bar.grid_remove()
        self.btn_run.configure(text="Recalculer", state="normal")
        self.btn_import.configure(state="normal")
        self.btn_save.grid()
        self.log("Terminé avec succès.")
        CustomPopup(self, "Succès", "Calcul terminé !\nVous pouvez télécharger l'emploi du temps coloré.", status="success")

    def on_failure(self):
        self.progress_bar.stop()
        self.progress_bar.grid_remove()
        self.btn_run.configure(text="Réessayer", state="normal")
        self.btn_import.configure(state="normal")
        CustomPopup(self, "Erreur", "Echec du calcul. Voir logs.", status="error")

    # --- MODIFICATION DE LA SAUVEGARDE ---
    def save_file(self):
        if not self.temp_output_path or not os.path.exists(self.temp_output_path):
            CustomPopup(self, "Erreur", "Fichier introuvable.", status="error")
            return

        # On propose d'enregistrer en EXCEL (.xlsx) par défaut
        target_path = filedialog.asksaveasfilename(
            defaultextension=".xlsx",
            filetypes=[("Fichier Excel", "*.xlsx"), ("Fichier CSV", "*.csv")],
            initialfile="Mon_Colloscope_Coloré.xlsx",
            title="Enregistrer le colloscope"
        )

        if target_path:
            try:
                # Si l'utilisateur a choisi .xlsx, on lance la conversion magique
                if target_path.endswith(".xlsx"):
                    self.log("Conversion en Excel coloré en cours...")
                    convert_to_styled_excel(self.temp_output_path, target_path)
                    self.log(f"Excel généré : {os.path.basename(target_path)}")
                else:
                    # S'il veut rester en CSV, on copie juste le fichier
                    shutil.copy(self.temp_output_path, target_path)
                    self.log(f"CSV sauvegardé : {os.path.basename(target_path)}")
                
                try:
                    if sys.platform == "win32": os.startfile(target_path)
                    elif sys.platform == "darwin": subprocess.call(["open", target_path])
                    else: subprocess.call(["xdg-open", target_path])
                except: pass

            except Exception as e:
                CustomPopup(self, "Erreur", f"Erreur de conversion : {str(e)}", status="error")

if __name__ == "__main__":
    app = ColloscopeApp()
    app.mainloop()