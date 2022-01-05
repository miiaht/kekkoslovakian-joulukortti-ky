import psycopg2
import os
import json 
import requests

def rivinhakija(request):
    con = None  
    try:
        dbname = os.environ.get('DBNAME')
        user = os.environ.get('USER')
        password = os.environ.get('PASSWORD')
        db_socket_dir = os.environ.get('DB_SOCKET_DIR')
        connecter = 'dbname={} user={} password={} host={}'.format(dbname, user, password, db_socket_dir)
        con = psycopg2.connect(connecter)
        cursor = con.cursor()

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
            items.append(dict)

        jsoned = json.dumps(items, indent = 4) 
        return jsoned
            
        cursor.close()
    
    except (Exception,psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if con is not None:
            con.close()