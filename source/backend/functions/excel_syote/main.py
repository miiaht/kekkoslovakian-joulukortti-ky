import psycopg2
import os
import json 
import requests
from google.cloud import secretmanager, storage
import pandas as pd
import fsspec

# ENTRYPOINT:
def excel_feed(request):
    
    con = None

    try:
        project_id = os.environ.get('PROJECT_ID')
        
        # tietokannan kirjautumistiedot secreteistä
        dbname, password, db_socket_dir, user, bucket_name = hae_kirjautumistiedot(project_id)
        
        # excel-tiedosto bucketissa
        # blob_name = "excel-feed.csv"

        # tietokantayhteys
        connecter = 'dbname={} user={} password={} host={}'.format(dbname, user, password, db_socket_dir)
        con = psycopg2.connect(connecter)
        cursor = con.cursor()

        # Storage client täytyy initialisoida, vaikka sitä ei käytetä suoraan
        client = storage.Client()

        # haetaan csv storage-polusta
        csv_dataframe = pd.read_csv('gs://kekkos-ampari123/excel-feed/excel-feed.csv', encoding='utf-8')

        # muodostetaan Pandas dataframesta lista, formaatti:
        # [['Lähettäjä-1;Tervehdys-1;email-1;kuva-1'], ['Lähettäjä-2;Tervehdys-2;email-2;kuva-2']]
        data_list = csv_dataframe.values.tolist()
        
        for sublist in data_list:
            item_list = sublist[0].split(";")

            print(item_list)

            sender = item_list[0]
            message = item_list[1]
            receiver = item_list[2]
            image = item_list[3]

            # lisätään kortti tietokantaan
            SQL = "INSERT INTO kortit (lahettaja, tervehdysteksti, vastaanottajanemail, kuvaurl) VALUES (%s, %s, %s, %s)"
            data = (sender, message, receiver, image)
            
            cursor.execute(SQL, data)
            con.commit()
    
        # TODO: poista excel-tiedosto bucketista, kun triggeri toimii

        return "CSV-tiedosto käsitelty"
        
    except (Exception,psycopg2.DatabaseError) as error:
        print(error)

        return error

    finally:
        if con is not None:
            cursor.close()
            
            con.close()


def hae_kirjautumistiedot(project_id):
    client = secretmanager.SecretManagerServiceClient()
    
    path_db_name = f"projects/{project_id}/secrets/kortti-db-name/versions/latest"
    encr_db_name = client.access_secret_version(request={"name": path_db_name})
    db_name = encr_db_name.payload.data.decode("UTF-8")

    path_db_passwd = f"projects/{project_id}/secrets/kortti-db-pw/versions/latest"
    encr_db_passwd = client.access_secret_version(request={"name": path_db_passwd})
    db_passwd = encr_db_passwd.payload.data.decode("UTF-8")

    path_db_socker_dir = f"projects/{project_id}/secrets/kortti-db-socket-dir/versions/latest"
    encr_db_socket = client.access_secret_version(request={"name": path_db_socker_dir})
    db_socket_dir = encr_db_socket.payload.data.decode("UTF-8")

    path_db_user = f"projects/{project_id}/secrets/kortti-db-user/versions/latest"
    encr_db_user = client.access_secret_version(request={"name": path_db_user})
    db_user = encr_db_user.payload.data.decode("UTF-8")

    path_kortti_bucket_id = f"projects/{project_id}/secrets/kortti-bucket-id/versions/latest"
    encr_kortti_bucket_id = client.access_secret_version(request={"name": path_kortti_bucket_id})
    bucket_name = encr_kortti_bucket_id.payload.data.decode("UTF-8")

    return db_name, db_passwd, db_socket_dir, db_user, bucket_name