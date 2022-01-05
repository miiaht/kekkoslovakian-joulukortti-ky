Päivitys 5.1.2022 - Elina:
    Uusi main.tf pelkästään Bastion hostin luonnille;
    main.tf sisältää seuraavien resurssien luonnin:
        VPC-yhteys                  "kekkoskakkos-vpc"
        subnet                      "kekkoskakkos-subnet"
        firewall-sääntö IAP:lle     "kekkoskakkos-firewall-allow-iap"
        Bastion-instanssi           "bastion-host"        
        IAP-secured Tunnel User -oikeudet käyttäjille Elina ja J-P
        