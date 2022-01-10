from google.cloud import storage

def html_kortti(lahettaja, teksti, kuvan_url):
    kortti = f'<!doctype html>\
        <html>\
            <head>\
                <title>Hyvää joulua!</title>\
            </head>\
            <bodystyle="background-color:#f7f4eb;">\
                <h1>{teksti}</h1>\
                <p>\
                    <img src="{kuvan_url}"alt="christmas_image" style="max-width:100%;height:auto;">\
                </p>\
                <h2>{lahettaja}</h2>\
                    <h5>Kekkoslovakian Joulukortit Ky</h5>\
            </body>\
        </html>'

    return kortti

