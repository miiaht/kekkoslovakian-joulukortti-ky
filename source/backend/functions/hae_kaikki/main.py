import psycopg2
import os
import json
from google.cloud import secretmanager


# ENTRYPOINT:
def get_all(request):

    con = None  
    
    try:
        project_id = os.environ.get('PROJECT_ID')

        dbname, password, db_socket_dir, user = hae_kirjautumistiedot(project_id)
        
        # muodostetaan yhteys ja luodaan kursori
        connecter = 'dbname={} user={} password={} host={}'.format(dbname, user, password, db_socket_dir)
        con = psycopg2.connect(connecter)
        cursor = con.cursor()

        # merkataan onnistunut yhteys lokiin
        print("yhteys muodostettu")

        SQL = "SELECT * FROM kortit;"
        cursor.execute(SQL)
        result = cursor.fetchall()
        
        items = []
        for tuple in result:
            dict = {}
            dict["id"] = tuple[0]
            dict["lahettaja"] = tuple[1]
            dict["tervehdysteksti"] = tuple[2]
            dict["vastaanottajanemail"] = tuple[3]
            dict["hasbeenread"] = tuple[4]
            dict["datecreated"] = tuple[5]
            dict["kuvaurl"] = tuple[6]
            items.append(dict)

        return json.dumps(items, indent = 4, sort_keys=True, default=str)  
    
    except (Exception,psycopg2.DatabaseError) as error:
        print(error)

        return f"Sori, ei toimi: {error}"

    finally:
        cursor.close()
        
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

    return db_name, db_passwd, db_socket_dir, db_user