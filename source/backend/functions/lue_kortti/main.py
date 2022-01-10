import psycopg2
import requests
import os
import json
import flask
import datetime
from google.cloud import storage

# ENTRYPOINT: rivinhakija
def rivinhakija(request):

    con = None  
    
    try:
        # TODO: muuta -> tiedot haetaan Secret Managerista
        dbname = os.environ.get('DBNAME')
        user = os.environ.get('USER')
        password = os.environ.get('PASSWORD')
        db_socket_dir = os.environ.get('DB_SOCKET_DIR')
        
        # muodostetaan yhteys ja luodaan kursori
        connecter = 'dbname={} user={} password={} host={}'.format(dbname, user, password, db_socket_dir)
        con = psycopg2.connect(connecter)
        cursor = con.cursor()

        # merkataan onnistunut yhteys lokiin
        print("yhteys muodostettu")

        # haetaan kortin x tiedot
        request_args = request.args

        if request_args and "id" in request_args:
            haettava_id = request_args["id"]

            SQL = "SELECT * FROM kortit WHERE id = %s;"
            
            cursor.execute(SQL,haettava_id)
            
            # huom: psykopg palauttaa tuplen
            result = cursor.fetchone()
            cursor.close()

            # kortin tiedot:
            # ---------------------------------------------------------
            # id = result[0], huom int!
            # lahettäjä = result[1]
            # tervehdysteksti = result[2]
            # vastaanottajan email = result[3]
            # hasbeenread = result[4]
            # date created = result[5]
            # kuvan url tai nimi = result[6]

            lahettaja, tervehdys = result[1], result[2]
            
            # muodostetaan kuvan url
            bucket_name = "kekkos-ampari123"
            blob_name = "kuva1.png"
            url = f"https://storage.cloud.google.com/{bucket_name}/{blob_name}"

            return html_kortti(lahettaja, tervehdys, url)


        else:
            response_msg = "Haku ok, mutta toiminto ei onnistu"
            return response_msg

            cursor.close()
    
    except (Exception,psycopg2.DatabaseError) as error:
        print(error)

        return f"Sori, ei toimi: {error}"

    finally:
        if con is not None:
            con.close()


def html_kortti(lahettaja, teksti, kuvan_url):
    kortti = f'<!doctype html>\
    <html>\
        <head>\
            <title>Hyvää joulua!</title>\
        </head>\
        <body style="background-color:#f7f4eb;">\
            <h1>{teksti}</h1>\
            <p>\
                <img src="{kuvan_url}" alt="christmas_image" style="max-width:100%;height:auto;">\
            </p>\
            <h2>{lahettaja}</h2>\
                <h5>Kekkoslovakian Joulukortit Ky</h5>\
        </body>\
    </html>'

    return kortti