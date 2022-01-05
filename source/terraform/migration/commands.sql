
CREATE TABLE henkilostohallinta (
    id SERIAL PRIMARY KEY, 
    name VARCHAR(255) NOT NULL, 
    title VARCHAR(255) NOT NULL
    )

INSERT INTO henkilostohallinta (name, title) VALUES ('Juukeli', 'postimerkinliimaaja');
INSERT INTO henkilostohallinta (name, title) VALUES ('Pipsa', 'liimanojentaja');

SELECT * FROM henkilostohallinta;
