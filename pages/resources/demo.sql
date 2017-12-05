CREATE TABLE `UserAccount` (
  `id` bigint(20) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ArtifactGroup` (
  `name` varchar(255) NOT NULL,
  `commonName` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ArtifactProduct` (
  `name` varchar(255) NOT NULL,
  `commonName` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `group_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`name`),
  KEY `FKphli9gj4v9p9tx8k5dir5a64b` (`group_name`),
  CONSTRAINT `FKphli9gj4v9p9tx8k5dir5a64b` FOREIGN KEY (`group_name`) REFERENCES `ArtifactGroup` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ArtifactVersion` (
  `name` varchar(255) NOT NULL,
  `createdAt` datetime DEFAULT NULL,
  `artifact_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`name`),
  KEY `FK9odauy1f0bsyxmwplit990eoj` (`artifact_name`),
  CONSTRAINT `FK9odauy1f0bsyxmwplit990eoj` FOREIGN KEY (`artifact_name`) REFERENCES `ArtifactProduct` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ArtifactBinary` (
  `name` varchar(255) NOT NULL,
  `sizeBytes` bigint(20) NOT NULL,
  `type` int(11) DEFAULT NULL,
  `uploadedAt` datetime DEFAULT NULL,
  `version_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`name`),
  KEY `FK8fvcgsbj6sic89ir5bgayrted` (`version_name`),
  CONSTRAINT `FK8fvcgsbj6sic89ir5bgayrted` FOREIGN KEY (`version_name`) REFERENCES `ArtifactVersion` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `Vulnerability` (
  `id` bigint(20) NOT NULL,
  `closedAt` datetime DEFAULT NULL,
  `reportedAt` datetime DEFAULT NULL,
  `closedBy_id` bigint(20) DEFAULT NULL,
  `reportedBy_id` bigint(20) DEFAULT NULL,
  `versionIntroduced_name` varchar(255) DEFAULT NULL,
  `versionRemediated_name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FKsf5q4t64i811asr38ne5y765j` (`closedBy_id`),
  KEY `FKmtwmcb3q8wbrqhwua5agaib79` (`reportedBy_id`),
  KEY `FKidqj88vuv01ns85i5m8obhw35` (`versionIntroduced_name`),
  KEY `FKbxeu9v74wjif8cus0eqyc3kch` (`versionRemediated_name`),
  CONSTRAINT `FKbxeu9v74wjif8cus0eqyc3kch` FOREIGN KEY (`versionRemediated_name`) REFERENCES `ArtifactVersion` (`name`),
  CONSTRAINT `FKidqj88vuv01ns85i5m8obhw35` FOREIGN KEY (`versionIntroduced_name`) REFERENCES `ArtifactVersion` (`name`),
  CONSTRAINT `FKmtwmcb3q8wbrqhwua5agaib79` FOREIGN KEY (`reportedBy_id`) REFERENCES `UserAccount` (`id`),
  CONSTRAINT `FKsf5q4t64i811asr38ne5y765j` FOREIGN KEY (`closedBy_id`) REFERENCES `UserAccount` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `ArtifactGroup` WRITE;
/*!40000 ALTER TABLE `ArtifactGroup` DISABLE KEYS */;

INSERT INTO `ArtifactGroup` (`name`, `commonName`, `description`)
VALUES
	('com.example.repository','Example Repository','The code for this project'),
	('com.yahoo.elide','Elide','The magical library powering this project');

/*!40000 ALTER TABLE `ArtifactGroup` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `ArtifactProduct` WRITE;
/*!40000 ALTER TABLE `ArtifactProduct` DISABLE KEYS */;

INSERT INTO `ArtifactProduct` (`name`, `commonName`, `description`, `group_name`)
VALUES
	('elide-core','Core','The guts of Elide','com.yahoo.elide'),
	('elide-datastore-hibernate5','Hibernate5 Datastore','A datastore that uses Hibernate 5 to communicate with the database','com.yahoo.elide'),
	('elide-standalone','Standalone','A pre-configured, standalone Elide webservice','com.yahoo.elide');

/*!40000 ALTER TABLE `ArtifactProduct` ENABLE KEYS */;
UNLOCK TABLES;
