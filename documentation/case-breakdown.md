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
