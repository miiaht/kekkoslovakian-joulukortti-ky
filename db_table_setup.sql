CREATE TABLE kortit (
    Id SERIAL PRIMARY KEY,
    lahettaja varchar(50) NOT NULL,
    tervehdysteksti varchar(250) NOT NULL,
    vastaanottajanemail varchar(50) NOT NULL,
    hasbeenread BOOLEAN NOT NULL,
    dateCreated TIMESTAMP NOT NULL DEFAULT(NOW()),
    kuvaURL VARCHAR(250) NOT NULL
);


