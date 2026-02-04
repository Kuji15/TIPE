# 📅 Colloscope Generator

**Logiciel d'optimisation de planning de colles (CPGE).**
*Optimized Oral Exam Scheduler software.*

> **Langues / Languages :**
> [🇫🇷 Manuel en Français](#-manuel-dutilisation) | [🇬🇧 User Manual (English)](#-user-manual)

---

## 🇫🇷 Manuel d'Utilisation

### 1. Préparation du fichier d'entrée
Avant de lancer le logiciel, vous devez disposer d'un fichier **Excel (enregistré en .csv)** contenant les disponibilités des colleurs.

**Format attendu du fichier CSV :**
Le fichier doit respecter une structure précise (séparateur virgule ou point-virgule) :
* Colonne 1 : **Horaires** (ex: "Lun 17:00", "Mar 12:00")
* Colonne 2 : **Noms des professeurs** (ex: "M. Dupont", "Mme Martin")
* Colonne 3 : **Matière** (ex: "Maths", "Physique", "Anglais")

> **Note :** Assurez-vous qu'il n'y a pas de cellules fusionnées ou de mise en forme complexe. Sauvegardez bien en format **CSV (UTF-8)**.

### 2. Lancer l'application
1.  Double-cliquez sur l'exécutable **`interface_moderne.exe`** (ou le fichier application fourni).
2.  Une fenêtre noire/bleue s'ouvre.

### 3. Générer le Colloscope
Le processus se déroule en 3 étapes simples :

* **Étape 1 : Importation**
    * Cliquez sur le bouton **"Importer le fichier CSV"**.
    * Sélectionnez votre fichier préparé à l'étape 1.
    * *Si le fichier est valide, le nom s'affiche en vert.*

* **Étape 2 : Calcul**
    * Cliquez sur le bouton **"LANCER L'OPTIMISATION"**.
    * Une barre de chargement apparaît. Le logiciel effectue des milliers de calculs pour trouver la meilleure répartition (cela peut prendre de 10 secondes à 1 minute).
    * Une fenêtre "Succès" apparaîtra quand le calcul est terminé.

* **Étape 3 : Sauvegarde**
    * Un bouton vert **"📥 TÉLÉCHARGER LE RÉSULTAT"** apparaît.
    * Cliquez dessus et choisissez où enregistrer votre fichier.
    * Nous vous recommandons de l'enregistrer en **.xlsx (Excel)** pour bénéficier des couleurs automatiques (code couleur par groupe d'étudiants).

### 4. Résolution de problèmes
* **Le logiciel bloque à l'étape 2 ?** Vérifiez que votre fichier CSV ne contient pas d'erreurs (caractères spéciaux bizarres, lignes vides).
* **L'antivirus bloque le logiciel ?** C'est normal pour les petits logiciels non signés. Vous pouvez autoriser l'exécution ou désactiver temporairement l'antivirus.

---

## 🇬🇧 User Manual

### 1. Preparing the Input File
Before running the software, you need an **Excel file (saved as .csv)** containing the professors' availability slots.

**Expected CSV Format:**
The file must follow a specific structure (comma or semicolon separated):
* Column 1: **Time Slots** (e.g., "Mon 17:00", "Tue 12:00")
* Column 2: **Professor Names** (e.g., "Mr. Smith", "Mrs. Doe")
* Column 3: **Subject** (e.g., "Maths", "Physics", "English")

> **Note:** Ensure there are no merged cells or complex formatting. Save as **CSV (UTF-8)**.

### 2. Launching the App
1.  Double-click the **`interface_moderne.exe`** executable (or the provided application file).
2.  The main window will open.

### 3. Generating the Schedule
The process follows 3 simple steps:

* **Step 1: Import**
    * Click on **"Importer le fichier CSV"** (Import CSV).
    * Select the file prepared in Step 1.
    * *If valid, the filename will turn green.*

* **Step 2: Calculation**
    * Click on **"LANCER L'OPTIMISATION"** (Start Optimization).
    * A loading bar will appear. The software runs thousands of calculations to find the best distribution (this may take 10s to 1 min).
    * A "Success" popup will appear when finished.

* **Step 3: Save**
    * A green button **"📥 TÉLÉCHARGER LE RÉSULTAT"** (Download Result) will appear.
    * Click it and choose where to save your file.
    * We recommend saving as **.xlsx (Excel)** to enjoy automatic coloring (color-coded by student groups).

### 4. Troubleshooting
* **Stuck at Step 2?** Check your CSV file for errors (weird characters, empty lines).
* **Antivirus warning?** This is normal for unsigned custom software. You can allow execution or temporarily disable the antivirus.
