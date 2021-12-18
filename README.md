# Kekkoslovakian Joulukortti Ky

## Branchit (esim.:)
- main: sisältää toimivan tuotantoympäristöön tarkoitetun koodin
- dev: kehitystason toimiva koodi asuu täällä
- henkilökohtaiset dev-branchit: varsinainen kehitys tapahtuu näissä

Omien dev-branchien nimeäminen vois olla esim. formaatissa dev-nimi-työ,
paitsi jos tää alkaa tuntua liian kuormittavalta. Hyvä puoli tässä olis se, 
että branchin nimestä saa suoraan selville kuka tekee mitä. Esimerkiksi kun
branchin nimi on dev-Kekkonen-terraform.

Tehdään kommitteja usein, jotta koodia on helppo jakaa ja se on ajan tasalla versionhallinnassa.

## Kansiot (esim.:)
- documentation: projektin dokumentaatio, rakennekuvat etc.
- source: lähdekoodi
    - api: rajanpinnan koodi (tarvitaanko tätä jos tehdään suoraan Terralla?)
    - frontend: frontin koodit
    - backend: bakkärin koodit
        - docker: imaget
        - functions: serverless-funktiot
    - terraform: IaC
