# Copyright Zlatko Babic, 2025
# SQL script to fix migration from Zabbix 4.0 to 7.2
# It creates/deletes tables/indexes neccessary for zabbix DB v7.2
# At the end it creates also history/trends tables.
 
 CREATE TABLE `alerts` (
	`alertid`                bigint unsigned                           NOT NULL,
	`actionid`               bigint unsigned                           NOT NULL,
	`eventid`                bigint unsigned                           NOT NULL,
	`userid`                 bigint unsigned                           NULL,
	`clock`                  integer         DEFAULT '0'               NOT NULL,
	`mediatypeid`            bigint unsigned                           NULL,
	`sendto`                 varchar(1024)   DEFAULT ''                NOT NULL,
	`subject`                varchar(255)    DEFAULT ''                NOT NULL,
	`message`                text                                      NOT NULL,
	`status`                 integer         DEFAULT '0'               NOT NULL,
	`retries`                integer         DEFAULT '0'               NOT NULL,
	`error`                  varchar(2048)   DEFAULT ''                NOT NULL,
	`esc_step`               integer         DEFAULT '0'               NOT NULL,
	`alerttype`              integer         DEFAULT '0'               NOT NULL,
	`p_eventid`              bigint unsigned                           NULL,
	`acknowledgeid`          bigint unsigned                           NULL,
	PRIMARY KEY (alertid)
) ENGINE=InnoDB;

CREATE TABLE `auditlog` (
	`auditid`                varchar(25)                               NOT NULL,
	`userid`                 bigint unsigned                           NULL,
	`username`               varchar(100)    DEFAULT ''                NOT NULL,
	`clock`                  integer         DEFAULT '0'               NOT NULL,
	`ip`                     varchar(39)     DEFAULT ''                NOT NULL,
	`action`                 integer         DEFAULT '0'               NOT NULL,
	`resourcetype`           integer         DEFAULT '0'               NOT NULL,
	`resourceid`             bigint unsigned                           NULL,
	`resource_cuid`          varchar(25)                               NULL,
	`resourcename`           varchar(255)    DEFAULT ''                NOT NULL,
	`recordsetid`            varchar(25)                               NOT NULL,
	`details`                longtext                                  NOT NULL,
	PRIMARY KEY (auditid)
) ENGINE=InnoDB;

CREATE TABLE `acknowledges` (
	`acknowledgeid`          bigint unsigned                           NOT NULL,
	`userid`                 bigint unsigned                           NOT NULL,
	`eventid`                bigint unsigned                           NOT NULL,
	`clock`                  integer         DEFAULT '0'               NOT NULL,
	`message`                varchar(2048)   DEFAULT ''                NOT NULL,
	`action`                 integer         DEFAULT '0'               NOT NULL,
	`old_severity`           integer         DEFAULT '0'               NOT NULL,
	`new_severity`           integer         DEFAULT '0'               NOT NULL,
	`suppress_until`         integer         DEFAULT '0'               NOT NULL,
	`taskid`                 bigint unsigned                           NULL,
	PRIMARY KEY (acknowledgeid)
) ENGINE=InnoDB;

CREATE TABLE `auditlog_details` (	`auditid`                varchar(25)                               NOT NULL,		PRIMARY KEY (auditid)) ENGINE=InnoDB;

 alter TABLE `auditlog_details` add `oldvalue`  text not null;
 alter TABLE `auditlog_details` add `newvalue`  text not null;
 alter TABLE `auditlog_details` add `oldvalue`  text not null;
 
alter table config drop column default_lang;

CREATE TABLE `escalations` (
	`escalationid`           bigint unsigned                           NOT NULL,
	`actionid`               bigint unsigned                           NOT NULL,
	`triggerid`              bigint unsigned                           NULL,
	`eventid`                bigint unsigned                           NULL,
	`r_eventid`              bigint unsigned                           NULL,
	`nextcheck`              integer         DEFAULT '0'               NOT NULL,
	`esc_step`               integer         DEFAULT '0'               NOT NULL,
	`status`                 integer         DEFAULT '0'               NOT NULL,
	`itemid`                 bigint unsigned                           NULL,
	`acknowledgeid`          bigint unsigned                           NULL,
	PRIMARY KEY (escalationid)
) ENGINE=InnoDB;

CREATE UNIQUE INDEX `escalations_1` ON `escalations` (`triggerid`,`itemid`,`serviceid`,`escalationid`);
CREATE INDEX `escalations_2` ON `escalations` (`eventid`);
CREATE INDEX `escalations_3` ON `escalations` (`nextcheck`);

alter TABLE `alerts` add `parameters`  text not null;

alter table acknowledges drop column suppress_until;
alter table acknowledges drop column taskid;

CREATE TABLE `events` (
	`eventid`                bigint unsigned                           NOT NULL,
	`source`                 integer         DEFAULT '0'               NOT NULL,
	`object`                 integer         DEFAULT '0'               NOT NULL,
	`objectid`               bigint unsigned DEFAULT '0'               NOT NULL,
	`clock`                  integer         DEFAULT '0'               NOT NULL,
	`value`                  integer         DEFAULT '0'               NOT NULL,
	`acknowledged`           integer         DEFAULT '0'               NOT NULL,
	`ns`                     integer         DEFAULT '0'               NOT NULL,
	`name`                   varchar(2048)   DEFAULT ''                NOT NULL,
	`severity`               integer         DEFAULT '0'               NOT NULL,
	PRIMARY KEY (eventid)
) ENGINE=InnoDB;
CREATE INDEX `events_1` ON `events` (`source`,`object`,`objectid`,`clock`);
CREATE INDEX `events_2` ON `events` (`source`,`object`,`clock`);

# now create history tables
# cp /usr/share/zabbix/sql-scripts/mysql/option-patches/history_upgrade_prepare.sql history_upgrade_prepare_mod.sql
# vi history_upgrade_prepare_mod.sql
# remove all lines with RENAME 
# mysql -uroot -p zabbix < history_upgrade_prepare_mod.sql

# here complete SQL for the above history creation:
CREATE TABLE `history` (
        `itemid` bigint unsigned NOT NULL,
        `clock` integer DEFAULT '0' NOT NULL,
        `value` DOUBLE PRECISION DEFAULT '0.0000' NOT NULL,
        `ns` integer DEFAULT '0' NOT NULL,
        PRIMARY KEY (itemid,clock,ns)
) ENGINE=InnoDB;

CREATE TABLE `history_uint` (
        `itemid` bigint unsigned NOT NULL,
        `clock` integer DEFAULT '0' NOT NULL,
        `value` bigint unsigned DEFAULT '0' NOT NULL,
        `ns` integer DEFAULT '0' NOT NULL,
        PRIMARY KEY (itemid,clock,ns)
) ENGINE=InnoDB;

CREATE TABLE `history_str` (
        `itemid` bigint unsigned NOT NULL,
        `clock` integer DEFAULT '0' NOT NULL,
        `value` varchar(255) DEFAULT '' NOT NULL,
        `ns` integer DEFAULT '0' NOT NULL,
        PRIMARY KEY (itemid,clock,ns)
) ENGINE=InnoDB;

CREATE TABLE `history_log` (
        `itemid` bigint unsigned NOT NULL,
        `clock` integer DEFAULT '0' NOT NULL,
        `timestamp` integer DEFAULT '0' NOT NULL,
        `source` varchar(64) DEFAULT '' NOT NULL,
        `severity` integer DEFAULT '0' NOT NULL,
        `value` text NOT NULL,
        `logeventid` integer DEFAULT '0' NOT NULL,
        `ns` integer DEFAULT '0' NOT NULL,
        PRIMARY KEY (itemid,clock,ns)
) ENGINE=InnoDB;

CREATE TABLE `history_text` (
        `itemid` bigint unsigned NOT NULL,
        `clock` integer DEFAULT '0' NOT NULL,
        `value` text NOT NULL,
        `ns` integer DEFAULT '0' NOT NULL,
        PRIMARY KEY (itemid,clock,ns)
) ENGINE=InnoDB;


# continue with SQL

CREATE TABLE `trends` (
	`itemid`                 bigint unsigned                           NOT NULL,
	`clock`                  integer         DEFAULT '0'               NOT NULL,
	`num`                    integer         DEFAULT '0'               NOT NULL,
	`value_min`              DOUBLE PRECISION DEFAULT '0.0000'          NOT NULL,
	`value_avg`              DOUBLE PRECISION DEFAULT '0.0000'          NOT NULL,
	`value_max`              DOUBLE PRECISION DEFAULT '0.0000'          NOT NULL,
	PRIMARY KEY (itemid,clock)
) ENGINE=InnoDB;