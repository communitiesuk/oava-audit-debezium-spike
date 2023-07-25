# Create databases
CREATE DATABASE IF NOT EXISTS `proxy_application`;

USE `proxy_application`;

DROP TABLE IF EXISTS `foo` ;
CREATE TABLE `foo`
(
    `id`                          char(36)          NOT NULL,
    `first_name`                  varchar(35)       NOT NULL,
    `last_name`                  varchar(35)       NOT NULL,
    PRIMARY KEY (`id`)
);

INSERT INTO foo (id, first_name, last_name) VALUES ("24621965-2d28-415e-90ad-a49fac7426f1", "HANNAH", "MAYHEW" );
INSERT INTO foo (id, first_name, last_name) VALUES ("dcdda787-335f-4aa7-9f77-465645b521f6", "GURPS", "BASSI" );

