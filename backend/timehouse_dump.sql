-- MySQL dump 10.13  Distrib 8.0.46, for Linux (x86_64)
--
-- Host: localhost    Database: timehouse
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `timehouse`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `timehouse` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `timehouse`;

--
-- Table structure for table `families`
--

DROP TABLE IF EXISTS `families`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `families` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '家庭组ID',
  `name` varchar(100) NOT NULL COMMENT '组名',
  `owner_id` bigint unsigned NOT NULL COMMENT '群主ID',
  `invite_code` char(6) NOT NULL COMMENT '邀请码',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `invite_code` (`invite_code`),
  KEY `idx_owner_id` (`owner_id`),
  KEY `idx_invite_code` (`invite_code`),
  CONSTRAINT `families_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='家庭组表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `families`
--

LOCK TABLES `families` WRITE;
/*!40000 ALTER TABLE `families` DISABLE KEYS */;
INSERT INTO `families` VALUES (1,'xiaoguo',3,'PH84GL','2026-05-10 06:45:46','2026-05-10 06:45:46'),(2,'xiaoyu',3,'7EAZBN','2026-05-16 14:24:31','2026-05-16 14:24:31'),(3,'yamei',3,'RUVW3V','2026-05-16 15:52:39','2026-05-16 15:52:39');
/*!40000 ALTER TABLE `families` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `family_members`
--

DROP TABLE IF EXISTS `family_members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `family_members` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '成员ID',
  `family_id` bigint unsigned NOT NULL COMMENT '家庭组ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `role` enum('owner','admin','member','guest') DEFAULT 'member' COMMENT '角色',
  `permissions` json DEFAULT NULL COMMENT '权限列表["view","edit","delete","manage"]',
  `joined_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '加入时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_family_user` (`family_id`,`user_id`),
  KEY `idx_user_id` (`user_id`),
  CONSTRAINT `family_members_ibfk_1` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE,
  CONSTRAINT `family_members_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='家庭组成员表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `family_members`
--

LOCK TABLES `family_members` WRITE;
/*!40000 ALTER TABLE `family_members` DISABLE KEYS */;
INSERT INTO `family_members` VALUES (1,1,3,'owner','[\"view\", \"edit\", \"delete\", \"manage\"]','2026-05-10 06:45:46'),(2,2,3,'owner','[\"view\", \"edit\", \"delete\", \"manage\"]','2026-05-16 14:24:31'),(3,3,3,'owner','[\"view\", \"edit\", \"delete\", \"manage\"]','2026-05-16 15:52:39'),(5,2,6,'member','[\"view\", \"edit\"]','2026-05-16 16:04:30');
/*!40000 ALTER TABLE `family_members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `photos`
--

DROP TABLE IF EXISTS `photos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `photos` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '照片ID',
  `user_id` bigint unsigned NOT NULL COMMENT '用户ID',
  `family_id` bigint unsigned DEFAULT NULL COMMENT '家庭组ID',
  `url` varchar(500) NOT NULL COMMENT '照片URL',
  `thumbnail_url` varchar(500) NOT NULL COMMENT '缩略图URL',
  `file_name` varchar(255) NOT NULL COMMENT '文件名',
  `size` bigint unsigned NOT NULL COMMENT '文件大小（字节）',
  `content_type` varchar(50) NOT NULL COMMENT '文件类型',
  `taken_at` datetime DEFAULT NULL COMMENT '拍摄时间',
  `location` varchar(255) DEFAULT '' COMMENT '拍摄地点',
  `tags` json DEFAULT NULL COMMENT '标签',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_taken_at` (`taken_at`),
  KEY `idx_family_id` (`family_id`),
  CONSTRAINT `fk_photos_family_id` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE SET NULL,
  CONSTRAINT `photos_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='照片表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `photos`
--

LOCK TABLES `photos` WRITE;
/*!40000 ALTER TABLE `photos` DISABLE KEYS */;
INSERT INTO `photos` VALUES (15,1,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777209375914_scaled_39.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777209375914_scaled_39.jpg','scaled_39.jpg',89246,'image/jpeg','2026-04-26 13:15:46','未知','[]','2026-04-26 13:16:16','2026-04-26 13:16:16'),(16,1,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777209376429_scaled_34.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777209376429_scaled_34.jpg','scaled_34.jpg',77329,'image/jpeg','2026-04-26 13:15:46','未知','[]','2026-04-26 13:16:16','2026-04-26 13:16:16'),(17,1,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777209997626_scaled_38.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777209997626_scaled_38.jpg','scaled_38.jpg',104251,'image/jpeg','2026-04-26 13:26:07','未知','[]','2026-04-26 13:26:37','2026-04-26 13:26:37'),(18,1,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777209998033_scaled_37.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777209998033_scaled_37.jpg','scaled_37.jpg',108422,'image/jpeg','2026-04-26 13:26:08','未知','[]','2026-04-26 13:26:38','2026-04-26 13:26:38'),(21,3,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777210570103_scaled_38.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777210570103_scaled_38.jpg','scaled_38.jpg',104251,'image/jpeg','2026-04-26 13:35:40','未知','[]','2026-04-26 13:36:10','2026-04-26 13:36:10'),(22,3,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777210570568_scaled_37.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1777210570568_scaled_37.jpg','scaled_37.jpg',108422,'image/jpeg','2026-04-26 13:35:40','未知','[]','2026-04-26 13:36:10','2026-04-26 13:36:10'),(23,3,3,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778941993170_scaled_34.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778941993170_scaled_34.jpg','scaled_34.jpg',77329,'image/jpeg','2026-05-16 14:33:11','未知','[]','2026-05-16 14:33:13','2026-05-16 16:25:38'),(24,3,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778946618750_scaled_36.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778946618750_scaled_36.jpg','scaled_36.jpg',113590,'image/jpeg','2026-05-16 15:50:17','未知','[]','2026-05-16 15:50:19','2026-05-16 16:26:31'),(27,3,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778946731504_scaled_37.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778946731504_scaled_37.jpg','scaled_37.jpg',108422,'image/jpeg','2026-05-16 15:52:10','未知','[]','2026-05-16 15:52:11','2026-05-16 16:33:32'),(29,6,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778947639189_scaled_34.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778947639189_scaled_34.jpg','scaled_34.jpg',77329,'image/jpeg','2026-05-16 16:07:17','未知','[]','2026-05-16 16:07:19','2026-05-16 16:07:21'),(30,6,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778947639517_scaled_37.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778947639517_scaled_37.jpg','scaled_37.jpg',108422,'image/jpeg','2026-05-16 16:07:18','未知','[]','2026-05-16 16:07:19','2026-05-16 16:07:21'),(31,6,2,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778947656542_scaled_39.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778947656542_scaled_39.jpg','scaled_39.jpg',89246,'image/jpeg','2026-05-16 16:07:35','未知','[]','2026-05-16 16:07:36','2026-05-16 16:07:38'),(32,3,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778948770573_scaled_36.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778948770573_scaled_36.jpg','scaled_36.jpg',113590,'image/jpeg','2026-05-16 16:26:09','未知','[]','2026-05-16 16:26:10','2026-05-16 16:26:13'),(33,3,NULL,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950566938_scaled_38.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950566938_scaled_38.jpg','scaled_38.jpg',104251,'image/jpeg','2026-05-16 16:56:05','未知','[]','2026-05-16 16:56:07','2026-05-16 17:09:47'),(34,3,2,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950567308_scaled_37.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950567308_scaled_37.jpg','scaled_37.jpg',108422,'image/jpeg','2026-05-16 16:56:06','未知','[]','2026-05-16 16:56:07','2026-05-16 16:56:13'),(35,3,2,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950567734_scaled_36.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950567734_scaled_36.jpg','scaled_36.jpg',113590,'image/jpeg','2026-05-16 16:56:06','未知','[]','2026-05-16 16:56:07','2026-05-16 16:56:13'),(36,3,3,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950609358_scaled_34.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950609358_scaled_34.jpg','scaled_34.jpg',77329,'image/jpeg','2026-05-16 16:56:48','未知','[]','2026-05-16 16:56:49','2026-05-16 16:56:51'),(37,3,3,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950609717_scaled_39.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950609717_scaled_39.jpg','scaled_39.jpg',89246,'image/jpeg','2026-05-16 16:56:48','未知','[]','2026-05-16 16:56:49','2026-05-16 16:56:51'),(38,3,3,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950610026_scaled_38.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778950610026_scaled_38.jpg','scaled_38.jpg',104251,'image/jpeg','2026-05-16 16:56:48','未知','[]','2026-05-16 16:56:50','2026-05-16 16:56:52'),(39,3,1,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778951407984_scaled_39.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778951407984_scaled_39.jpg','scaled_39.jpg',89246,'image/jpeg','2026-05-16 17:10:06','未知','[]','2026-05-16 17:10:08','2026-05-16 17:10:12'),(40,3,1,'https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778951408432_scaled_34.jpg','https://timehouse-photos-cn-shanghai.tos-cn-shanghai.volces.com/photos/1778951408432_scaled_34.jpg','scaled_34.jpg',77329,'image/jpeg','2026-05-16 17:10:07','未知','[]','2026-05-16 17:10:08','2026-05-16 17:10:12');
/*!40000 ALTER TABLE `photos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `phone` varchar(20) NOT NULL COMMENT '手机号',
  `password` varchar(255) NOT NULL COMMENT '密码（bcrypt加密）',
  `nickname` varchar(50) DEFAULT '' COMMENT '昵称',
  `avatar` varchar(500) DEFAULT '' COMMENT '头像URL',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone` (`phone`),
  KEY `idx_phone` (`phone`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'18969954662','$2b$12$/zbBO9rCqHYmAiKIkQK..Of/IYcaoJnZyOR4u4Ylq7KT/CH1CUngy','','','2026-04-26 04:13:17','2026-04-26 04:13:17'),(2,'13800138000','$2b$12$aoiVsCQ/g9t3UPY0MMrzc.n6JKD4XqJbn6wJplsvXM7zhaflU9KNO','????','','2026-04-26 12:19:59','2026-04-26 12:19:59'),(3,'18058790612','$2b$12$c0ioGCY8Q.1uqHuRW9TV8.tKLVscM9FcVK9ybeX.JWbeIrHItK6zm','','','2026-04-26 13:27:46','2026-04-26 13:27:46'),(4,'13900001111','$2b$12$Lfigrd2fTc8CNYEdOnZkF.ShpRAs9EIvIalvazzcua/nFAixsjlpq','','','2026-05-10 02:46:24','2026-05-10 02:46:24'),(5,'13556295181','$2b$12$8nzAQcoy8QNF5IjjjuO/yuKJ0OMwhgJ2mjry2s87UGBM/Y9kIVFZK','','','2026-05-16 16:00:16','2026-05-16 16:00:16'),(6,'15306814275','$2b$12$jmPjw.5LhOQKpA3SRc7Aau5pLGEqAtAIvHn./W8RDMhwF42r0x7/m','','','2026-05-16 16:00:39','2026-05-16 16:00:39');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'timehouse'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-17  7:26:38
