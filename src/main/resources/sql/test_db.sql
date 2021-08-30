--use test
CREATE TABLE `xdual` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `x` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
--change sql
insert into xdual(id,x) values(null,now());