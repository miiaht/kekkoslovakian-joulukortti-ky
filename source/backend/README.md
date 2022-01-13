# Verkkopalvelun "backend"

Backend on toteutettu kokonaisuudessaan Cloud Functions -palvelussa. Functions-kansio sisältää palvelun käyttämät funktiot.
Jokainen kansio sisältää minimissään seuraavat:
- main.py: funktion ohjelmakoodi
- requirements.txt: funktion vaatimat ulkoiset kirjastot
- funktion_nimi.zip: edelliset tiedostot paketoituna

Backend rakennetaan Terraformilla osana Webapp-kokonaisuutta, joka määrittelee verkkosovelluksen tarvitseman infran ja toiminnallisuuden.
Webapp rakentuu, kun "terraform init" ja "terraform apply" ajetaan kansiossa "./source/terraform/Webapp/".