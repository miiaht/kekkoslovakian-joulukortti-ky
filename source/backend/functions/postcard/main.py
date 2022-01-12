import psycopg2
import os
import json 
import requests
from google.cloud import secretmanager
import string
import random

def postcard(request):
    con = None  
    try:
        project_id = os.environ.get('PROJECT_ID')

        dbname, password, db_socket_dir, user = hae_kirjautumistiedot(project_id)
        connecter = 'dbname={} user={} password={} host={}'.format(dbname, user, password, db_socket_dir)
        con = psycopg2.connect(connecter)
        cursor = con.cursor()

        request_json = request.get_json(silent=True)
        
        sender = request_json["sender"]
        message = request_json["message"]
        receiver = request_json["receiver"]
        image = request_json["image"]

        salis = generoi_salis()

        SQL = "INSERT INTO kortit (lahettaja, tervehdysteksti, vastaanottajanemail, kuvaurl, salasana) VALUES (%s, %s, %s, %s, %s)"
        data = (sender, message, receiver, image, salis)
        cursor.execute(SQL, data)
        con.commit()
    
        cursor.close()

        return "Postitettu!"
        
    
    except (Exception,psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if con is not None:
            con.close()


def generoi_salis(size=10, chars=string.ascii_letters + string.digits):
           return ''.join(random.choice(chars) for _ in range(size))


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

    return db_name, db_passwd, db_socket_dir, db_user
