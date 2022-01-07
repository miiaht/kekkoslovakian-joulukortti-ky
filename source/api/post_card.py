import psycopg2
import os
import json 
import requests

def postcard(request):
    con = None  
    try:
        dbname = os.environ.get('DBNAME')
        user = os.environ.get('USER')
        password = os.environ.get('PASSWORD')
        db_socket_dir = os.environ.get('DB_SOCKET_DIR')
        connecter = 'dbname={} user={} password={} host={}'.format(dbname, user, password, db_socket_dir)
        con = psycopg2.connect(connecter)
        cursor = con.cursor()

        request_json = request.get_json(silent=True)
        
        sender = request_json["sender"]
        message = request_json["message"]
        receiver = request_json["receiver"]


        SQL = "INSERT INTO kortit (lahettaja, tervehdysteksti, vastaanottajanemail, hasbeenread, kuvaurl) VALUES (%s, %s, %s, %s, %s)"
        data = (sender, message, receiver,"t", "kuvaurl")
        cursor.execute(SQL, data)
        con.commit()
    
        cursor.close()

        return "Postitettu!"
        
    
    except (Exception,psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if con is not None:
            con.close()
