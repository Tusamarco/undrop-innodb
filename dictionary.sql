
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SYS_COLUMNS` (
  `TABLE_ID` bigint(20) unsigned NOT NULL,
  `POS` int(10) unsigned NOT NULL,
  `NAME` varchar(255) DEFAULT NULL,
  `MTYPE` int(10) unsigned DEFAULT NULL,
  `PRTYPE` int(10) unsigned DEFAULT NULL,
  `LEN` int(10) unsigned DEFAULT NULL,
  `PREC` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`TABLE_ID`,`POS`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SYS_FIELDS`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SYS_FIELDS` (
  `INDEX_ID` bigint(20) unsigned NOT NULL,
  `POS` int(10) unsigned NOT NULL,
  `COL_NAME` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`INDEX_ID`,`POS`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SYS_INDEXES`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SYS_INDEXES` (
  `TABLE_ID` bigint(20) unsigned NOT NULL DEFAULT '0',
  `ID` bigint(20) unsigned NOT NULL DEFAULT '0',
  `NAME` varchar(120) DEFAULT NULL,
  `N_FIELDS` int(10) unsigned DEFAULT NULL,
  `TYPE` int(10) unsigned DEFAULT NULL,
  `SPACE` int(10) unsigned DEFAULT NULL,
  `PAGE_NO` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`TABLE_ID`,`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SYS_TABLES`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `SYS_TABLES` (
  `NAME` varchar(255) NOT NULL DEFAULT '',
  `ID` bigint(20) unsigned NOT NULL DEFAULT '0',
  `N_COLS` int(10) DEFAULT NULL,
  `TYPE` int(10) unsigned DEFAULT NULL,
  `MIX_ID` bigint(20) unsigned DEFAULT NULL,
  `MIX_LEN` int(10) unsigned DEFAULT NULL,
  `CLUSTER_NAME` varchar(255) DEFAULT NULL,
  `SPACE` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`NAME`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET character_set_client = @saved_cs_client */;

