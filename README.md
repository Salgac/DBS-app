# README

Repozitar projektu na DBS.

* Ruby version - 2.7.1

* Rails version - 6.1.3


Deploynute pomocou Linode na: 139.162.130.177:3000

---

Commit ID pre odovzdanie 1: dbeafbc

---

Commid ID pre odovzdanie 2: ff3d5d7

---

Commit ID pre odovzdanie 3: 0464061

- Poznamka: Migracia pre doplnenie stlpcov `company_id` zo zadania je zakomentovana, z dovodu ze na serveri nemam dostatok miesta - PG vracal nasledovnu chybu pocas migracie:

	`PG::DiskFull: ERROR: could not extend file "base/16405/16458.5": No space left on device`

---

Commit ID pre odovzdanie 3: b2c85e9

- Poznamka: GET `v2/companies` nefunguje koretkne, jednotlive county vypisuju pocet DISTINCT zaznamov pre `cin`.
