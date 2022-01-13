
CREATE TABLE henkilo(id SERIAL PRIMARY KEY, name VARCHAR(255) NOT NULL,title VARCHAR(255) NOT NULL);

INSERT INTO henkilo (name, title) VALUES ('Juukeli', 'postimerkinliimaaja');
INSERT INTO henkilo (name, title) VALUES ('Pipsa', 'liimanojentaja');

SELECT * FROM henkilo;
