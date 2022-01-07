# Kekkos-API
Rajapinta välittää palvelun frontendin (Cloud Run -kontti) pyynnöt backendiin (Cloud Functions):
- hae-kaikki (GET) palauttaa tiedot kaikista korteista (myös luetuista)
    - urlin path: /all
- hae-yksi (GET) palauttaa asiakkaalle tämän vastaanottaman kortin
    - urlin path: /single
- lisaa-kortti (POST) lisää kortin järjestelmään
    - urlin path: /add

Huom: rajapinta ei vielä käytä API-keytä.