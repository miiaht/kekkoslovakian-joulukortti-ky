import psycopg2
import requests
import os
import json

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

        SQL = "DELETE FROM kortit WHERE datecreated < (NOW() - interval '365 days');"
        cursor.execute(SQL)
        con.commit()
        return f"poistettu vanhat kortit"
            
        cursor.close()
    
    except (Exception,psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if con is not None:
            con.close()