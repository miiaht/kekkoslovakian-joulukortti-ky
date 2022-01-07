import psycopg2
import requests
import os
import json
import flask

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

            dict = {}
            dict["id"] = str(result[0])
            dict["lahettaja"] = result[1]
            dict["tervehdysteksti"] = result[2]
            dict["vastaanottajanemail"] = result[3]
            dict["hasbeenread"] = result[4]
            dict["datecreated"] = result[5]
            dict["kuvaurl"] = result[6]

            jsoned = json.dumps(dict, indent = 4, sort_keys=False, default=str) 
            
            cursor.close()

            return jsoned

        else:
            response_msg = "Haku ok, mutta toiminto ei onnistu"
            return response_msg

            cursor.close()
    
    except (Exception,psycopg2.DatabaseError) as error:
        print(error)

        return "Sori, ei toimi..."

    finally:
        if con is not None:
            con.close()