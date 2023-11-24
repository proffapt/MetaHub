-- --------------------------------------------------------
-- Server version:               5.5.35-0+wheezy1 - (Debian)
-- Server OS:                    debian-linux-gnu
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Dumping database structure for stats
CREATE DATABASE IF NOT EXISTS `stats` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `stats`;

-- Dumping structure for table stats.botStats
CREATE TABLE IF NOT EXISTS `botStats` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(32) NOT NULL,
  `regs` smallint(5) unsigned zerofill NOT NULL DEFAULT '00000',
  `unregs` smallint(5) unsigned zerofill NOT NULL DEFAULT '00000',
  `dated` date NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_dated` (`name`,`dated`),
  KEY `regs` (`regs`),
  KEY `unregs` (`unregs`),
  KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Bots and chatroom stats';

-- Dumping structure for table stats.hubtopics
CREATE TABLE IF NOT EXISTS `hubtopics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `topic` tinytext NOT NULL,
  `assignee` varchar(32) NOT NULL,
  `dated` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Historical archive of all hub topics';

-- Dumping structure for table stats.options
CREATE TABLE IF NOT EXISTS `options` (
  `option_id` tinyint(4) unsigned NOT NULL,
  `poll_id` mediumint(8) unsigned NOT NULL,
  `option` tinytext NOT NULL,
  UNIQUE KEY `option_id_poll_id` (`option_id`,`poll_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Storing poll options/choices';

-- Dumping structure for table stats.questions
CREATE TABLE IF NOT EXISTS `questions` (
  `poll_id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `deleted` bit(1) NOT NULL DEFAULT b'0',
  `question` tinytext NOT NULL,
  `nick` varchar(32) NOT NULL,
  `dated` datetime NOT NULL,
  PRIMARY KEY (`poll_id`),
  KEY `deleted` (`deleted`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Table to store poll questions/titles';

-- Dumping structure for table stats.scores
CREATE TABLE IF NOT EXISTS `scores` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nick` varchar(32) NOT NULL,
  `count` smallint(5) unsigned zerofill NOT NULL DEFAULT '00000',
  `messages` smallint(5) unsigned zerofill NOT NULL DEFAULT '00000',
  `dated` date NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nick_dated` (`nick`,`dated`),
  KEY `nick` (`nick`),
  KEY `count` (`count`),
  KEY `messages` (`messages`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Mainchat scores';

-- Dumping structure for table stats.toks
CREATE TABLE IF NOT EXISTS `toks` (
  `id` bigint(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(25) NOT NULL,
  `toks` float unsigned NOT NULL,
  `maxtoks` float unsigned NOT NULL,
  `maxtoksdate` date NOT NULL,
  `allowance` float unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Dumping structure for table stats.votes
CREATE TABLE IF NOT EXISTS `votes` (
  `poll_id` mediumint(8) unsigned NOT NULL,
  `option_id` tinyint(4) unsigned NOT NULL,
  `nick` varchar(32) NOT NULL,
  `dated` datetime NOT NULL,
  UNIQUE KEY `poll_id_nick` (`poll_id`,`nick`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Dumping structure for trigger stats.MAXTOKS
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='';
DELIMITER //
CREATE TRIGGER `MAXTOKS` BEFORE UPDATE ON `toks` FOR EACH ROW BEGIN
SET
NEW.maxtoks = CASE when new.toks > OLD.maxtoks then new.toks else old.maxtoks end,
NEW.maxtoksdate = CASE when NEW.toks > OLD.maxtoks then CURDATE() else old.maxtoksdate end;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
