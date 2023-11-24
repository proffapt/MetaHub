-- --------------------------------------------------------
-- Server version:               5.5.35-0+wheezy1 - (Debian)
-- Server OS:                    debian-linux-gnu
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;

-- Dumping database structure for latest
CREATE DATABASE IF NOT EXISTS `latest` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `latest`;

-- Dumping structure for table latest.buynsell
CREATE TABLE IF NOT EXISTS `buynsell` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `type` enum('B','S','D','H','T','L') NOT NULL DEFAULT 'B',
  `msg` varchar(250) NOT NULL,
  `nick` varchar(32) NOT NULL,
  `dated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `msg_nick` (`msg`,`nick`),
  KEY `type` (`type`),
  FULLTEXT KEY `msg` (`msg`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='The table storing information about users selling/buying/hiring things etc.';

-- Dumping structure for table latest.ctgtable
CREATE TABLE IF NOT EXISTS `ctgtable` (
  `id` tinyint(3) unsigned zerofill NOT NULL AUTO_INCREMENT,
  `name` varchar(15) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Listing of all categories.';

-- Dumping structure for table latest.deletions
CREATE TABLE IF NOT EXISTS `deletions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nick` varchar(32) NOT NULL,
  `msg` varchar(250) NOT NULL,
  `dated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nick_msg` (`nick`,`msg`),
  KEY `dated` (`dated`),
  FULLTEXT KEY `msg` (`msg`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='The information published when users are about to delete something from their share and others might need it.';

-- Dumping structure for table latest.entries
CREATE TABLE IF NOT EXISTS `entries` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ctg` tinyint(3) unsigned NOT NULL,
  `msg` tinytext NOT NULL,
  `nick` smallint(5) unsigned NOT NULL,
  `date` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `date` (`date`),
  KEY `ctg` (`ctg`),
  KEY `nick` (`nick`),
  FULLTEXT KEY `msg` (`msg`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Listing of all additions with their tags etc.';

-- Dumping structure for table latest.filenames
CREATE TABLE IF NOT EXISTS `filenames` (
  `magnet_id` int(10) unsigned NOT NULL,
  `filename` tinytext NOT NULL,
  UNIQUE KEY `magnet_id` (`magnet_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Table to track all filenames extracted from magnets attached to entries';

-- Dumping structure for table latest.guestbook
CREATE TABLE IF NOT EXISTS `guestbook` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nick` varchar(32) NOT NULL,
  `msg` varchar(250) NOT NULL,
  `dated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nick_msg` (`nick`,`msg`),
  UNIQUE KEY `nick` (`nick`),
  KEY `dated` (`dated`),
  FULLTEXT KEY `msg` (`msg`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Dumping structure for table latest.magnets
CREATE TABLE IF NOT EXISTS `magnets` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `eid` int(10) unsigned NOT NULL,
  `tth` char(39) NOT NULL,
  `size` bigint(20) unsigned NOT NULL,
  `nick` smallint(5) unsigned NOT NULL,
  `date` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `eid_tth` (`eid`,`tth`),
  UNIQUE KEY `tth_nick` (`tth`,`nick`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Table populated with magnets of various entries.';

-- Dumping structure for table latest.messages
CREATE TABLE IF NOT EXISTS `messages` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `message` text NOT NULL,
  `from` varchar(25) NOT NULL DEFAULT 'hjpotter92',
  `to` varchar(25) NOT NULL DEFAULT 'hjpotter92',
  `delivered` enum('Y','N') NOT NULL DEFAULT 'N',
  `dated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `from_dated` (`from`,`dated`),
  KEY `from` (`from`),
  KEY `to` (`to`),
  FULLTEXT KEY `message` (`message`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='All offline messages users send to each other.';

-- Dumping structure for table latest.modtable
CREATE TABLE IF NOT EXISTS `modtable` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `nick` varchar(30) NOT NULL,
  `added_by` varchar(30) NOT NULL,
  `active` enum('Y','N') NOT NULL DEFAULT 'Y',
  `deletions` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `date` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nick` (`nick`),
  KEY `nick_added_by` (`nick`,`added_by`),
  KEY `active` (`active`),
  KEY `date` (`date`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Table of all the moderators of all time.';

-- Dumping structure for procedure latest.NewEntry
DELIMITER //
CREATE DEFINER=`offliner`@`localhost` PROCEDURE `NewEntry`(IN `ctg` VARCHAR(15), IN `msg` TINYTEXT, IN `nick` VARCHAR(32), IN `tth` CHAR(39), IN `name` TINYTEXT, IN `size` BIGINT, OUT `eid` INT, OUT `maid` INT
)
    COMMENT 'Automated procedure to insert a new entry'
BEGIN
    DECLARE exit HANDLER
    FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            SET maid = -1;
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO entries (msg, nick, date, ctg)
    SELECT
        msg,
        m.id,
        NOW(),
        c.id
    FROM modtable m, ctgtable c
    WHERE c.name = ctg
        AND m.nick = nick
    LIMIT 1;
    SET eid = LAST_INSERT_ID();
    CALL NewMagnet( nick, tth, name, size, eid, maid );
    COMMIT;
END//
DELIMITER ;

-- Dumping structure for procedure latest.NewMagnet
DELIMITER //
CREATE DEFINER=`offliner`@`localhost` PROCEDURE `NewMagnet`(IN `nick` VARCHAR(32), IN `tth` CHAR(39), IN `name` TINYTEXT, IN `size` BIGINT, IN `eid` INT, OUT `maid` INT)
    COMMENT 'Automated insertion to magnets and filename tables'
BEGIN
    DECLARE exit HANDLER
    FOR SQLEXCEPTION, SQLWARNING
        BEGIN
            SET maid = -1;
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO magnets (eid, tth, size, nick, date)
    SELECT
        eid,
        tth,
        size,
        m.id,
        NOW()
    FROM modtable m
    WHERE m.nick = nick;
    SET maid = LAST_INSERT_ID();
    INSERT INTO filenames
    VALUES( LAST_INSERT_ID(), name );
    COMMIT;
END//
DELIMITER ;

-- Dumping structure for table latest.news
CREATE TABLE IF NOT EXISTS `news` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `nick` varchar(32) NOT NULL,
  `msg` varchar(250) NOT NULL,
  `dated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nick_msg` (`nick`,`msg`),
  KEY `dated` (`dated`),
  FULLTEXT KEY `msg` (`msg`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Recent happenings in and around the campus/country.';

-- Dumping structure for table latest.replies
CREATE TABLE IF NOT EXISTS `replies` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `bns_id` int(10) unsigned NOT NULL,
  `msg` varchar(250) NOT NULL,
  `nick` varchar(32) NOT NULL,
  `dated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `bns_id_msg` (`bns_id`,`msg`),
  KEY `bns_id` (`bns_id`),
  KEY `dated` (`dated`),
  KEY `nick` (`nick`),
  FULLTEXT KEY `msg` (`msg`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Replies to buynsell messages from interested users.';

-- Dumping structure for table latest.requests
CREATE TABLE IF NOT EXISTS `requests` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ctg` varchar(15) NOT NULL,
  `msg` varchar(250) NOT NULL,
  `nick` varchar(32) NOT NULL,
  `filled` enum('Y','N','C') NOT NULL DEFAULT 'N',
  `dated` datetime NOT NULL,
  `filldate` datetime DEFAULT NULL,
  `filledby` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nick_msg` (`nick`,`msg`),
  UNIQUE KEY `ctg_msg` (`ctg`,`msg`),
  KEY `filled` (`filled`),
  KEY `dated` (`dated`),
  KEY `filldate` (`filldate`),
  KEY `filledby` (`filledby`),
  FULLTEXT KEY `msg` (`msg`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Requests from users in any of the categories.';

-- Dumping structure for table latest.suggestions
CREATE TABLE IF NOT EXISTS `suggestions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ctg` varchar(15) NOT NULL,
  `msg` varchar(250) NOT NULL,
  `nick` varchar(32) NOT NULL,
  `dated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nick_msg` (`nick`,`msg`),
  UNIQUE KEY `ctg_msg` (`ctg`,`msg`),
  KEY `dated` (`dated`),
  FULLTEXT KEY `msg` (`msg`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='Suggestions to other users about random stuff.';

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
