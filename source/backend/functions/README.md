# Backendin funktiot (Cloud Functions)
Backend rakentuu rajapinnan takana toimivien Cloud Functions -funktioiden varaan.
Jokainen funktio on omassa kansiossaan Terraformia varten seuraavasti:
- main.py (funktio, entrypoint kommentoituna)
- requirements.txt (funktio riippuvuudet)

## Funktiot
- lue_kortti
    - asiakkaalle lähetetään funktioon ohjaava url (käytännössä API:n url, jossa kortin id argumenttina)
    - hakee tietokannasta kortin tiedot
    - jos sarake "hasbeenread" = false
        - palauttaa GET-pyyntöön html-tiedoston (kortin)
        - muuttaa sarakkeen "hasbeenread" -> true
    - muuten palauttaa esim. 404
