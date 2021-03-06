# Sequel Pro dump
# Version 2210
# http://code.google.com/p/sequel-pro
#
# Host: localhost (MySQL 5.1.39)
# Database: gifts
# Generation Time: 2010-05-25 17:45:30 +0400
# ************************************************************

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table system_cache
# ------------------------------------------------------------

DROP TABLE IF EXISTS `system_cache`;

CREATE TABLE `system_cache` (
  `id` varchar(32) NOT NULL DEFAULT '',
  `added` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `content` mediumblob,
  `is_code` tinyint(1) unsigned NOT NULL DEFAULT '0',
  KEY `id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table system_sessions
# ------------------------------------------------------------

DROP TABLE IF EXISTS `system_sessions`;

CREATE TABLE `system_sessions` (
  `id` varchar(32) NOT NULL DEFAULT '',
  `used` int(11) unsigned NOT NULL DEFAULT '0',
  `signature` varchar(100) NOT NULL DEFAULT '',
  `content` blob,
  KEY `id` (`id`),
  KEY `used` (`used`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table system_users
# ------------------------------------------------------------

DROP TABLE IF EXISTS `system_users`;

CREATE TABLE `system_users` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(30) NOT NULL DEFAULT '',
  `password` varchar(32) NOT NULL DEFAULT '',
  `added` int(11) unsigned NOT NULL DEFAULT '0',
  `modified` int(11) unsigned DEFAULT NULL,
  `last_visited` int(11) unsigned DEFAULT NULL,
  `last_used_ip` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user` (`username`,`password`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
