
CREATE TABLE henkilo(id SERIAL PRIMARY KEY, name VARCHAR(255) NOT NULL,yhteystieto VARCHAR(255) NOT NULL);

INSERT INTO henkilo (name, title) VALUES ('Juukeli', 'juukeli@juukelisto.com');
INSERT INTO henkilo (name, title) VALUES ('Pipsa', 'pipsa@juukelisto.com');

SELECT * FROM henkilo;

CREATE TABLE passeli(id SERIAL PRIMARY KEY, name VARCHAR(255) NOT NULL,maksut int NOT NULL, suoritettu BOOLEAN );
INSERT INTO passeli(name,maksut,suoritettu) VALUES ('Juukeli', 3, TRUE);
INSERT INTO passeli(name,maksut,suoritettu) VALUES ('Pipsa', 3, FALSE);

SELECT * FROM reskontra;
