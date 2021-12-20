# Kekkoslovakian Joulukortti Ky

## Branchit
- main: sisältää toimivan tuotantoympäristöön tarkoitetun koodin
- dev: kehitystason toimiva koodi asuu täällä
- henkilökohtaiset dev-branchit: varsinainen kehitys tapahtuu näissä

Omien dev-branchien nimeäminen formaatissa dev-nimi-työ. Esimerkiksi jos Kekkonen työstää Terraformia,
työskentely-branchin nimi on dev-kekkonen-terraform.

Tehdään kommitteja usein, jotta koodia on helppo jakaa ja se on ajan tasalla versionhallinnassa.

## Kansiot
- documentation: projektin dokumentaatio, rakennekuvat etc.
- source: lähdekoodi
    - api: rajanpinnan koodi
    - frontend: frontin koodit
    - backend: bakkärin koodit
        - docker: imaget
        - functions: serverless-funktiot
    - terraform: IaC
