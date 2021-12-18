# On-premise / palvelinrekisteri
Asiakkaan on-premise näyttäis jakaantuvan ainakin kahteen osaan, mutta pelkästään
palvelinrekisterin perusteella vähän paha sanoa.

## Webbipalvelun palvelimet
- lb-01
- web-srv01
- web-srv02
- web-srv03
- db-srv01 (???)
- db-srv02 (???)

F5-loadbalancer, jonka takana sivuja pyörittävät palvelimet (Apache + PHP-moduuli) ja ainakin yksi tietokantapalvelin.
Toinen db saattaa olla backup tai sit sisältää henkilöstöhallinnan tietokannan.

## Reskontra
- fina-srv-01
    - Passeli Pro
- db-srv03 (Passelin db)
    - Microsoft SQL

Reskontra on rakennettu Microsoft Windows Server 2012 varaan.

# Kysymyksiä asiakkaalle / projektista
- Mitä tietokantapalvelimilla db-srv01 ja db-srv02 on ajettu?
- Tarkennus: mitä meinaa kohdassa "Transformaatio strategia": ei lift & shift?
- Edelliseen liittyen: mitä tarkoittaa "luodaan tyhjät vm:t simuloiduiksi työkuormiksi"?
- Tarkennus: mitä tarkoittaa kohdassa "tietoturvavaatimukset": ympäristön tulee olla eriytettynä jne.: mitä tässä tarkoittaa "ympäristö"
- Edelliseen liittyen: mitä tarkoittaa "on vaadittu tuotetuissa käyttöjärjestelmissä"?
