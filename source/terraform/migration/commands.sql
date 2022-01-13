
CREATE TABLE henkilo(id SERIAL PRIMARY KEY, name VARCHAR(255) NOT NULL,yhteystieto VARCHAR(255) NOT NULL);

INSERT INTO henkilo (name, yhteystieto) VALUES ('Juukeli', 'juukeli@juukelisto.com');
INSERT INTO henkilo (name, yhteystieto) VALUES ('Pipsa', 'pipsa@juukelisto.com');
INSERT INTO henkilo (name, yhteystieto) VALUES ('Justin', 'bieber@juukelisto.com');


SELECT * FROM henkilo;

CREATE TABLE passeli(id SERIAL PRIMARY KEY, name VARCHAR(255) NOT NULL,maksut_E int NOT NULL, suoritettu BOOLEAN );
INSERT INTO passeli(name,maksut_E,suoritettu) VALUES ('Juukeli', 3, TRUE);
INSERT INTO passeli(name,maksut_E,suoritettu) VALUES ('Pipsa', 3, FALSE);

SELECT * FROM passeli;
