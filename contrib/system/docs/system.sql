DROP TABLE IF EXISTS `ss_system_cache`;

CREATE TABLE `ss_system_cache` (
  `id` VARCHAR(32) COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `added` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  `content` MEDIUMTEXT,
  `is_code` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  KEY `id` (`id`)
)ENGINE=MyISAM
CHARACTER SET 'utf8' COLLATE 'utf8_general_ci';

DROP TABLE IF EXISTS `ss_system_cvs_messages`;

CREATE TABLE `ss_system_cvs_messages` (
  `message_id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `time_submitted` DATETIME NOT NULL,
  `author` VARCHAR(20) COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `tag` VARCHAR(50) COLLATE utf8_general_ci DEFAULT NULL,
  `message` TEXT COLLATE utf8_general_ci NOT NULL,
  PRIMARY KEY (`message_id`)
)ENGINE=MyISAM
AUTO_INCREMENT=1152 CHARACTER SET 'utf8' COLLATE 'utf8_general_ci';

DROP TABLE IF EXISTS `ss_system_sessions`;

CREATE TABLE `ss_system_sessions` (
  `id` VARCHAR(32) COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `used` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `signature` VARCHAR(100) COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `content` TEXT COLLATE utf8_general_ci,
  KEY `id` (`id`),
  KEY `used` (`used`)
)ENGINE=MyISAM
CHARACTER SET 'utf8' COLLATE 'utf8_general_ci';

DROP TABLE IF EXISTS `ss_system_users`;

CREATE TABLE `ss_system_users` (
  `id` INTEGER(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(30) COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `password` VARCHAR(32) COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `added` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `modified` INTEGER(10) UNSIGNED DEFAULT NULL,
  `last_visited` INTEGER(10) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user` (`username`, `password`)
)ENGINE=MyISAM
AUTO_INCREMENT=385 CHARACTER SET 'utf8' COLLATE 'utf8_general_ci';

DROP TABLE IF EXISTS `ss_system_warnings`;

CREATE TABLE `ss_system_warnings` (
  `warn_id` INTEGER(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `warn_date` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  `system_id` VARCHAR(20) COLLATE utf8_general_ci DEFAULT NULL,
  `vis_ip` VARCHAR(15) COLLATE utf8_general_ci NOT NULL DEFAULT '',
  `warn_message` MEDIUMTEXT NOT NULL,
  `warn_extended` MEDIUMTEXT,
  `critical` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`warn_id`),
  KEY `warn_date` (`warn_date`),
  KEY `vis_ip` (`vis_ip`)
)ENGINE=MyISAM
AUTO_INCREMENT=5450778 CHARACTER SET 'utf8' COLLATE 'utf8_general_ci';

DROP TABLE IF EXISTS `ss_system_warnings_tags`;

CREATE TABLE `ss_system_warnings_tags` (
  `warn_id` INTEGER(10) UNSIGNED NOT NULL DEFAULT '0',
  `tag` VARCHAR(20) COLLATE utf8_general_ci NOT NULL DEFAULT '',
  KEY `warn_id` (`warn_id`),
  KEY `tag` (`tag`)
)ENGINE=MyISAM
CHARACTER SET 'utf8' COLLATE 'utf8_general_ci';

