# TIPE: Colloscope Generator (SAT Solver)

This project implements a SAT solver in OCaml to automatically generate an oral exam schedule (known as a "Colloscope" in French preparatory classes). It respects complex constraints such as availability, week parity, and teacher rotation.

## 📋 Prerequisites

To compile this project, you need:
* **OCaml**
* The **CSV** library (`opam install csv`)
* **Ocamlfind** (`opam install ocamlfind`)

## 📄 Input Format (Important)

The `entree.csv` file must strictly follow a specific format. 
The **first line** (header) must be exactly:

`Horaires,Nom,Matière`

*(Note: Do not translate these headers, as the program specifically looks for these French terms).*

## 🚀 Compilation & Execution

It is necessary to link the CSV library during compilation.

### 1. Compile
Use the following command in the terminal:

```bash
ocamlc Properly_Sat.ml
ocamlfind ocamlc -package csv -c input.ml
ocamlfind ocamlc -o test -package csv -linkpkg input.ml Properly_sat.ml final_input_version.ml
