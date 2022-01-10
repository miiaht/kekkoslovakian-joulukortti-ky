import psycopg2
import os
import json 
import requests
from google.cloud import secretmanager

# ENTRYPOINT
def excel_feed(request):
    con = None  
    try:
        project_id = os.environ.get('PROJECT_ID')

        # TODO: kirjoita funktio joka lukee csv-tiedoston bucketista


        dbname, password, db_socket_dir, user, bucket = hae_kirjautumistiedot(project_id)
        connecter = 'dbname={} user={} password={} host={}'.format(dbname, user, password, db_socket_dir)
        con = psycopg2.connect(connecter)
        cursor = con.cursor()

        # TODO: korvaa alla oleva csv:stä iteroiduilla tiedoilla
        request_json = request.get_json(silent=True)
        
        sender = request_json["sender"]
        message = request_json["message"]
        receiver = request_json["receiver"]
        image = request_json["image"]

        # TODO: luuppaa tää -> csv:n kaikki rivit kantaan
        SQL = "INSERT INTO kortit (lahettaja, tervehdysteksti, vastaanottajanemail, kuvaurl) VALUES (%s, %s, %s, %s)"
        data = (sender, message, receiver, image)
        cursor.execute(SQL, data)
        con.commit()
    
        cursor.close()

        return "Postitettu!"
        
    
    except (Exception,psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if con is not None:
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