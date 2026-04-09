CREATE TABLE IF NOT EXISTS `strix_badge_positions` (
  `identifier` varchar(80) NOT NULL,
  `x` float NOT NULL DEFAULT 0.11,
  `y` float NOT NULL DEFAULT 0.06,
  `z` float NOT NULL DEFAULT 0.0,
  `rx` float NOT NULL DEFAULT 0.0,
  `ry` float NOT NULL DEFAULT 90.0,
  `rz` float NOT NULL DEFAULT 180.0,
  PRIMARY KEY (`identifier`)
);