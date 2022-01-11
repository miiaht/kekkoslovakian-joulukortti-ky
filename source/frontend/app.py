from flask import Flask, render_template, redirect, url_for, request
from flask_bootstrap import Bootstrap
from flask_wtf import FlaskForm
from wtforms import StringField, SubmitField, widgets
from wtforms.fields.choices import RadioField, SelectField
from wtforms.validators import DataRequired, Email
from dotenv import load_dotenv
import os
import requests
import json


images = "https://storage.cloud.google.com/kekkos-ampari123/Asset%201.png?authuser=0", "https://storage.cloud.google.com/kekkos-ampari123/Asset%202.png?authuser=0"
#Formi jota käytetään index.html:ssä
class LetterForm(FlaskForm):
    sender = StringField('Lähettäjän nimi', validators=[DataRequired()])
    message = StringField('Kirjoita tähän joleterkut', validators=[DataRequired()])
    receiver = StringField('Vastaanottajan sähköposti', validators=[DataRequired()])
    image = RadioField(validators=[DataRequired()], choices=images)
    submit = SubmitField('Lähetä')




app = Flask(__name__)

load_dotenv()

# Flask-WTF requires an encryption key - the string can be anything
app.config['SECRET_KEY'] = os.environ.get('wtfKey')

# Flask-Bootstrap requires this line
Bootstrap(app)

@app.route('/', methods=['GET', 'POST'])
def index():
    # you must tell the variable 'form' what you named the class, above
    # 'form' is the variable name used in this template: index.html
    form = LetterForm()
    if form.validate_on_submit():
        post_data(form.data)
        return redirect(url_for("index"))
    
    return render_template('index.html', form=form)

#Lähetetään formin datan post metodilla json muodossa apiin.
def post_data(data_to_post):
    json_object = json.dumps(data_to_post, indent = 4) 
    url = os.environ.get('postUrl')
    headers = {'Content-type': 'application/json', 'Accept': 'text/plain'}
    x = requests.post(url, data = json_object, headers=headers)
    print(x.text)