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

