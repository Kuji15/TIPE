# 📅 Colloscope Generator

**Logiciel d'optimisation de planning de colles (CPGE).**
*Optimized Oral Exam Scheduler software.*

> **Langues / Languages :**
> [🇫🇷 Manuel en Français](#-manuel-dutilisation) | [🇬🇧 User Manual (English)](#-user-manual)

--


# 🇫🇷 Manuel d'Utilisation

## 0. Préparation de l'environnement virtuel
Installation de l'environnement Python (.venv)
Pour compiler ou modifier le logiciel, il est recommandé de travailler dans un environnement virtuel. Cela permet d'isoler les librairies du projet.

Pré-requis
Avoir Python 3.10+ installé sur votre machine.

Ouvrir un terminal (CMD/PowerShell sur Windows, Terminal sur Mac/Linux).

Se placer dans le dossier du projet : cd chemin/vers/le/projet.
### Linux/MacOs
#### 1. Créer l'environnement virtuel :
```bash
python3 -m venv .venv
```
#### 2. Activer l'environnement :
```bash
source .venv/bin/activate
```

#### 3. Vérification :
Votre terminal doit maintenant afficher (.venv) au début de la ligne.

Pour désactiver plus tard, tapez simplement deactivate.

### Windows
#### 1. Créer l'environnement virtuel :
```bash
python3 -m venv .venv
```
#### 2. Activer l'environnement :
##### Si CMD : 
```bash
.venv\Scripts\activate.bat
```

##### Si PowerShell :
```bash
.venv\Scripts\Activate.ps1
```


#### 3. Vérification :
Vérification : Votre terminal doit afficher (.venv) en vert au début de la ligne.

### 0.5 : Installation des dépendances
Une fois l'environnement activé (et que vous voyez (.venv)), installez les librairies nécessaires :
```bash
pip install pandas customtkinter xlsxwriter pyinstaller
```

## 1. Préparation du fichier d'entrée
Avant de lancer le logiciel, vous devez disposer d'un fichier **Excel (enregistré en .csv)** contenant les disponibilités des colleurs. **Le nom du fichier doit être différent de : "'entree.csv'"**

**Format attendu du fichier CSV :**
Le fichier doit respecter une structure précise (séparateur virgule ou point-virgule) :
* Colonne 1 : **Horaires** (ex: "Lun 17:00", "Mar 12:00")
* Colonne 2 : **Noms des professeurs** (ex: "M. Dupont", "Mme Martin")
* Colonne 3 : **Matière** (ex: "Maths", "Physique", "Anglais")

> **Note :** Assurez-vous qu'il n'y a pas de cellules fusionnées ou de mise en forme complexe. Sauvegardez bien en format **CSV (UTF-8)**.
## 1.5 Commandes bash
## 👨‍💻 Command Lines for Developers / Lignes de Commande

Si vous modifiez le code source, voici les commandes pour régénérer l'application.


### 👉 Windows

```bash
# 1. (Optionnel) Nettoyage des anciens builds
rmdir /s /q build dist
del *.spec

# 2. Compilation du moteur OCaml
ocamlfind ocamlopt -o colloscope -linkpkg -package csv,unix Properly_sat.ml input.ml output.ml final_input_version.ml

# 3. Création de l'exécutable final
pyinstaller --noconsole --onefile --add-data "colloscope.exe;." --collect-all customtkinter colloscope_generator.py
```
### 👉 Linux/MacOS
```bash
# 1. (Optionnel) Nettoyage des anciens builds
rm -rf build/ dist/ *.spec

# 2. Compilation du moteur OCaml
ocamlfind ocamlopt -o colloscope -linkpkg -package csv,unix Properly_sat.ml input.ml output.ml final_input_version.ml

# 3. Création de l'exécutable final
pyinstaller --noconsole --onefile --add-data "colloscope:." --collect-all customtkinter colloscope_generator.py
```
## 2. Lancer l'application
1.  Double-cliquez sur l'exécutable **`colloscope_generator.exe`** (ou le fichier application fourni).
2.  Une fenêtre noire/bleue s'ouvre.

## 3. Générer le Colloscope
Le processus se déroule en 3 étapes simples :

* **Étape 1 : Importation**
    * Cliquez sur le bouton **"Choisirle fichier CSV"**.
    * Sélectionnez votre fichier préparé à l'étape 1.
    * *Si le fichier est valide, le nom s'affiche en vert.*

* **Étape 2 : Calcul**
    * Cliquez sur le bouton **"Générer le colloscope"**.
    * Une barre de chargement apparaît. Le logiciel effectue des milliers de calculs pour trouver la meilleure répartition (cela peut prendre de 10 secondes à 1 minute).
    * Une fenêtre "Succès" apparaîtra quand le calcul est terminé.

* **Étape 3 : Sauvegarde**
    * Cliquez sur **"📥 Télécharger le fichier"** et choisissez où enregistrer votre fichier.
    * Nous vous recommandons de l'enregistrer en **.xlsx (Excel)** pour bénéficier des couleurs automatiques (code couleur par groupe d'étudiants).

### 4. Résolution de problèmes
* **Le logiciel bloque à l'étape 2 ?** Vérifiez que votre fichier CSV ne contient pas d'erreurs (caractères spéciaux bizarres, lignes vides).
* **L'antivirus bloque le logiciel ?** C'est normal pour les petits logiciels non signés. Vous pouvez autoriser l'exécution ou désactiver temporairement l'antivirus.

---

## 🇬🇧 User Manual
## 0. Preparing the virtual environment
Installing the Python environment (.venv)
To compile or modify the software, it is recommended to work in a virtual environment. This allows you to isolate the project's libraries.

Prerequisites
Have Python 3.10+ installed on your machine.

Open a terminal (CMD/PowerShell on Windows, Terminal on Mac/Linux).

Go to the project folder: cd path/to/the/project.
### Linux/MacOs
#### 1. Create the virtual environment :
```bash
python3 -m venv .venv
```
#### 2. Activate the environment :
```bash
source .venv/bin/activate
```

#### 3. Verification :
Your terminal should now display (.venv) at the beginning of the line.

To deactivate later, simply type deactivate.

### Windows
#### 1. Create the virtual environment :
```bash
python3 -m venv .venv
```
#### 2. ctivate the environment :
##### If using CMD : 
```bash
.venv\Scripts\activate.bat
```

##### If using PowerShell :
```bash
.venv\Scripts\Activate.ps1
```


#### 3. Verification :
Verification: Your terminal should display (.venv) in green at the beginning of the line.

### 0.5 : Installation of dependencies
Once the environment is activated (and you see (.venv)), install the necessary libraries:
```bash
pip install pandas customtkinter xlsxwriter pyinstaller
```

## 1. Preparing the Input File
Before running the software, you need an **Excel file (saved as .csv)** containing the professors' availability slots. **The name of the file must be different than "'entree.csv'"**

**Expected CSV Format:**
The file must follow a specific structure (comma or semicolon separated):
* Column 1: **Time Slots** (e.g., "Mon 17:00", "Tue 12:00")
* Column 2: **Professor Names** (e.g., "Mr. Smith", "Mrs. Doe")
* Column 3: **Subject** (e.g., "Maths", "Physics", "English")

> **Note:** Ensure there are no merged cells or complex formatting. Save as **CSV (UTF-8)**.
## 1.5 Bash commands
*If you modify the source code, run these commands to rebuild the app.*
### 👉 Windows

```bash
# 1. (Optional) Clean old builds
rmdir /s /q build dist
del *.spec

# 2. Compile OCaml Engine
ocamlfind ocamlopt -o colloscope -linkpkg -package csv,unix Properly_sat.ml input.ml output.ml final_input_version.ml

# 3. Build Final App
pyinstaller --noconsole --onefile --add-data "colloscope.exe;." --collect-all customtkinter colloscope_generator.py
```
### 👉 Linux/MacOS
```bash
# 1. (Optional) Clean old builds
rm -rf build/ dist/ *.spec

# 2. Compile OCaml Engine
ocamlfind ocamlopt -o colloscope -linkpkg -package csv,unix Properly_sat.ml input.ml output.ml final_input_version.ml

# 3. Build Final App (Note the ':' separator instead of ';')
pyinstaller --noconsole --onefile --add-data "colloscope:." --collect-all customtkinter colloscope_generator.py
```

## 2. Launching the App
1.  Double-click the **`colloscope_generator.exe`** executable (or the provided application file).
2.  The main window will open.

## 3. Generating the Schedule
The process follows 3 simple steps:

* **Step 1: Import**
    * Click on **"Choisirle fichier CSV"** (Import CSV).
    * Select the file prepared in Step 1.
    * *If valid, the filename will turn green.*

* **Step 2: Calculation**
    * Click on **"Générer le colloscope"** (Start Optimization).
    * A loading bar will appear. The software runs thousands of calculations to find the best distribution (this may take 10s to 1 min).
    * A "Success" popup will appear when finished.

* **Step 3: Save**
* Click on **“📥 Download file”** and choose where to save your file.
* We recommend saving it as **.xlsx (Excel)** to benefit from automatic colors (color coding by student group).

### 4. Troubleshooting
* **Stuck at Step 2?** Check your CSV file for errors (weird characters, empty lines).
* **Antivirus warning?** This is normal for unsigned custom software. You can allow execution or temporarily disable the antivirus.
