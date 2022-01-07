# Kekkos-API
Rajapinta välittää palvelun frontendin (Cloud Run -kontti) pyynnöt backendiin (Cloud Functions):
- hae-kaikki (GET) palauttaa tiedot kaikista korteista (myös luetuista)
- hae-yksi (GET) palauttaa asiakkaalle tämän vastaanottaman kortin
- lisaa-kortti (POST) lisää kortin järjestelmään