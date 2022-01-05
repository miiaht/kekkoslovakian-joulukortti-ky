
CREATE TABLE henkilostohallinta (
    id SERIAL PRIMARY KEY, 
    name VARCHAR(255) NOT NULL, 
    person_id int, 
    CONSTRAINT fk_person
        FOREIGN KEY (person_id)
            REFERENCES person(id)    
    )

INSERT INTO person (name, age, student) VALUES ('Elina', '31', 'true');

SELECT * FROM person;
