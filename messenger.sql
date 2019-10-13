/* Урок 3. Задача N1
Проанализировать структуру БД vk, которую мы создали на занятии, 
и внести предложения по усовершенствованию (если такие идеи есть). 
Напишите пожалуйста, всё-ли понятно по структуре. 
*/

DROP DATABASE IF EXISTS messanger;
CREATE DATABASE messanger;
USE messanger;

/* таблица users содержит основные реквизиты, идентифицирующие пользователя, допинформацию вынесли в специальную базу ptofiles
 для ускорения работы основной таблицы
 */
DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL PRIMARY KEY, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
    firstname VARCHAR(50) COMMENT 'Имя', -- COMMENT на случай, если поле неочевидное
    lastname VARCHAR(50) COMMENT 'Фамилия', -- COMMENT на случай, если поле неочевидное
    email VARCHAR(120) UNIQUE,
    phone BIGINT, 
    INDEX users_phone_idx(phone), -- телефон является уникальным идентификатором пользователя
    INDEX users_firstname_lastname_idx(firstname, lastname),
    INDEX users_lastname_firstname_idx(lastname, firstname)  -- добавили поиск по фамилии
);
    
/* дополнительная таблица к users, содержит допинформацию о пользователях, используется при необходимости
   наименование в апострофах, так как пересекается с системным именем
 */
DROP TABLE IF EXISTS `profiles`;
CREATE TABLE `profiles` (
	user_id SERIAL PRIMARY KEY,
    gender CHAR(1),
    birthday DATE,
 	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(),
    hometown VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES users(id) 
    	ON UPDATE CASCADE -- на все связанные таблицы распространяется изменение в родительской таблице
    	ON DELETE restrict -- запрет изменения удаления родительского ключа при наличии записей с этим ключом в дочерних таблицах
    -- , FOREIGN KEY (photo_id) REFERENCES media(id) -- включим после создания таблицы media, так как пока еще не создана родительсакя база
);

/* таблица сообщений пользователей */
DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL PRIMARY KEY,
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT,
    created_at DATETIME DEFAULT NOW(), -- можно будет даже не упоминать это поле при вставке
    INDEX messages_from_user_id (from_user_id),
    INDEX messages_to_user_id (to_user_id),
    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id)
);

/* запрос друзей */
DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	-- id SERIAL PRIMARY KEY, -- изменили на композитный ключ (initiator_user_id, target_user_id)
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    `status` ENUM('requested', 'approved', 'unfriended', 'declined'),
    -- `status` TINYINT UNSIGNED, -- в этом случае в коде хранили бы цифирный enum (0, 1, 2, 3...)
	requested_at DATETIME DEFAULT NOW(),
	confirmed_at DATETIME,
	
    PRIMARY KEY (initiator_user_id, target_user_id),
	INDEX (initiator_user_id), -- потому что обычно будем искать друзей конкретного пользователя
    INDEX (target_user_id),
    FOREIGN KEY (initiator_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)
);

/* сообщества */
DROP TABLE IF EXISTS communities;
CREATE TABLE communities(
	id SERIAL PRIMARY KEY,
	name VARCHAR(150),

	INDEX communities_name_idx(name)
);

/* таблица users_communities содержит связи между сообществами и пользователями */
DROP TABLE IF EXISTS users_communities;
CREATE TABLE users_communities(
	user_id BIGINT UNSIGNED NOT NULL,
	community_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, community_id), -- один пользователь может только один раз состоять в сообществе, делаем индекс чтобы не было 2 записей о пользователе и сообществе
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (community_id) REFERENCES communities(id)
);

/* таблица media_types содержит типы медиаданных, ее не индексируем, так как записей мало и индекс будет замедлять работу */
DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types(
	id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    created_at DATETIME DEFAULT NOW(),  -- информаци о создании типа данных
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP --  информация об изменении типа данных
);

/* таблиц media хранит медиаданные */
DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL PRIMARY KEY,
    media_type_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
  	body TEXT,
    filename VARCHAR(255),
    size INT,
	metadata JSON,
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX (user_id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (media_type_id) REFERENCES media_types(id)
);

/* добавляем в таблицу profiles ключ на медиаданные из созданной таблицы media */
-- DROP INDEX photo_idx;
CREATE INDEX photo_idx ON `profiles`(photo_id); -- REFERENCES media(id);

/* фото альбомы пользователя */
DROP TABLE IF EXISTS photo_albums;
CREATE TABLE photo_albums (
	id SERIAL PRIMARY KEY,
	name varchar(255) DEFAULT NULL,
    user_id BIGINT UNSIGNED DEFAULT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id)
);

/* фото пользователя */
DROP TABLE IF EXISTS `photos`;
CREATE TABLE photos (
	id SERIAL PRIMARY KEY,
	album_id BIGINT UNSIGNED NOT NULL,
	media_id BIGINT UNSIGNED NOT NULL,

	FOREIGN KEY (album_id) REFERENCES photo_albums(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);


/* Урок 3. Задача N2
Добавить необходимую таблицу/таблицы для того чтобы можно было использовать лайки для медиафайлов. 
постов и пользователей */

DROP TABLE IF EXISTS likes;
CREATE TABLE likes (
	id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    media_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    liked_at BIGINT UNSIGNED NOT NULL,
    like_type ENUM('like', 'dislike'), -- добавили вид лайка пользователя
    PRIMARY KEY (user_id, media_id),  -- первичный ключ создаем по связке, так как отношение пользователя к медиа должно быть уникальным  
    FOREIGN KEY (liked_at) REFERENCES users(id), -- индекс поставившего лайк
    FOREIGN KEY (media_id) REFERENCES media(id) -- индекс медиа, которому поставили лайк
);


/* Урок 3. Задача N3
Используя сервис http://filldb.info или другой по вашему желанию, сгенерировать тестовые данные для всех таблиц, 
учитывая логику связей. Для всех таблиц, где это имеет смысл, создать не менее 100 строк. 
Создать локально БД vk и загрузить в неё тестовые данные. */


#
# TABLE STRUCTURE FOR: users
#


INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('1', 'Norwood', 'Doyle', 'braun.nicole@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('2', 'Jules', 'Emmerich', 'kirlin.bailee@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('3', 'Sonia', 'Feest', 'chase.morar@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('4', 'Nat', 'Towne', 'cartwright.carolina@example.com', '802965');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('5', 'Jeffrey', 'Barrows', 'raphaelle63@example.org', '222');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('6', 'Junius', 'Crist', 'dan14@example.org', '394');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('7', 'Alicia', 'Dietrich', 'maiya.bernier@example.org', '139735');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('8', 'Ilene', 'Morissette', 'frieda.marks@example.net', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('9', 'Evans', 'Baumbach', 'delmer66@example.com', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('10', 'Jaren', 'Cartwright', 'christop.heaney@example.net', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('11', 'Adaline', 'Bode', 'maggio.crystel@example.org', '3241292700');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('12', 'Cedrick', 'Johns', 'ruecker.zena@example.net', '66');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('13', 'Isaac', 'King', 'mohr.jeffrey@example.org', '374307529');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('14', 'Cortney', 'Stiedemann', 'johnston.ophelia@example.com', '997949');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('15', 'Art', 'Swaniawski', 'werner77@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('16', 'Alva', 'Ryan', 'pascale17@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('17', 'Alan', 'Koch', 'marjolaine.daniel@example.com', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('18', 'Katrina', 'Robel', 'schoen.tabitha@example.com', '682470');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('19', 'Elody', 'Spencer', 'walter.keara@example.com', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('20', 'Muriel', 'Lowe', 'odessa.dickens@example.com', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('21', 'Alyce', 'Krajcik', 'dokuneva@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('22', 'Reece', 'Halvorson', 'maximillia.gorczany@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('23', 'Colin', 'Harber', 'kariane.thompson@example.org', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('24', 'Darryl', 'Rath', 'adelle.spinka@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('25', 'Pierce', 'Runte', 'reanna.ledner@example.net', '458');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('26', 'Hassie', 'Renner', 'nicolas28@example.org', '750');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('27', 'Jerome', 'Swift', 'josue57@example.com', '329');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('28', 'Nicklaus', 'Fritsch', 'walsh.carolina@example.org', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('29', 'Finn', 'Turner', 'faustino74@example.org', '367706');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('30', 'Nash', 'Moen', 'martina63@example.net', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('31', 'Sallie', 'Wisozk', 'will.maverick@example.net', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('32', 'Brendan', 'Hackett', 'anthony.klocko@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('33', 'Dorris', 'Abshire', 'veum.jody@example.net', '722');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('34', 'Roel', 'Schiller', 'pouros.brett@example.com', '383');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('35', 'Keaton', 'Windler', 'dillon.dubuque@example.com', '876');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('36', 'Deshawn', 'Little', 'betsy.stehr@example.net', '287');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('37', 'Dannie', 'Schiller', 'considine.gillian@example.net', '299218');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('38', 'Hazle', 'Murazik', 'judd91@example.org', '495');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('39', 'Rubye', 'Baumbach', 'murazik.marge@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('40', 'Jake', 'Reynolds', 'clemmie.bahringer@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('41', 'Okey', 'Ratke', 'xrunolfsson@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('42', 'Aubree', 'Medhurst', 'stracke.rosalind@example.org', '602436');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('43', 'Joesph', 'Keebler', 'ocie.glover@example.com', '230');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('44', 'Tessie', 'Kautzer', 'qwatsica@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('45', 'Crystel', 'Feeney', 'rgottlieb@example.org', '213999');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('46', 'Olga', 'Schmeler', 'mgraham@example.org', '250');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('47', 'Neal', 'Bartell', 'cummerata.vicenta@example.net', '901614');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('48', 'Cecelia', 'Swift', 'melyssa61@example.com', '33');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('49', 'Jed', 'Cronin', 'jackson92@example.org', '133');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('50', 'Baron', 'Trantow', 'adah98@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('51', 'Kip', 'Hudson', 'laurel79@example.org', '4085683712');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('52', 'Georgiana', 'Kshlerin', 'rachael78@example.net', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('53', 'Novella', 'Gleason', 'streich.trisha@example.net', '272');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('54', 'David', 'Pagac', 'bahringer.myrtie@example.net', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('55', 'Emery', 'Kuhlman', 'wilton38@example.com', '553');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('56', 'Creola', 'Kutch', 'kaleb46@example.org', '920846');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('57', 'Charley', 'Ratke', 'ihessel@example.org', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('58', 'Elroy', 'D\'Amore', 'witting.madie@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('59', 'Elise', 'Spinka', 'amanda.jenkins@example.org', '625857');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('60', 'Raphael', 'Rutherford', 'cierra.mccullough@example.net', '421217263');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('61', 'Lamar', 'Emard', 'akeem80@example.org', '927075');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('62', 'Montana', 'McGlynn', 'robyn.wyman@example.com', '153647');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('63', 'Alize', 'Durgan', 'mosciski.brendon@example.org', '129564');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('64', 'Minnie', 'Bradtke', 'ekiehn@example.com', '54033');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('65', 'Yoshiko', 'Witting', 'shaniya.white@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('66', 'Lilyan', 'Brekke', 'mccullough.jacky@example.net', '141096');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('67', 'Rigoberto', 'Crona', 'emma41@example.org', '521206');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('68', 'Allene', 'Collier', 'jeanette11@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('69', 'Audreanne', 'Fadel', 'goodwin.marlin@example.org', '803821');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('70', 'Cruz', 'Hamill', 'lockman.jocelyn@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('71', 'Jeanette', 'Johnston', 'dbode@example.net', '707');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('72', 'Johann', 'Kunze', 'kohler.hardy@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('73', 'Justus', 'Stamm', 'selina.carter@example.com', '50');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('74', 'Felix', 'Legros', 'garrett91@example.net', '177723');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('75', 'Tessie', 'Dooley', 'ilene99@example.net', '900348');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('76', 'Brandt', 'Thompson', 'ratke.peyton@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('77', 'Magali', 'Prosacco', 'lindsay67@example.com', '7454317504');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('78', 'Talon', 'Brekke', 'emmalee.hettinger@example.org', '7576753248');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('79', 'Annalise', 'Dicki', 'carolyne.keebler@example.org', '13');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('80', 'Emmet', 'Barton', 'clindgren@example.com', '600');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('81', 'Bria', 'Hills', 'jakubowski.addie@example.net', '363');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('82', 'Angie', 'Wolff', 'rohan.ned@example.com', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('83', 'Eden', 'Paucek', 'rebeca.barrows@example.org', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('84', 'Elsa', 'Hauck', 'xgerhold@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('85', 'Orpha', 'Herman', 'sterling.barton@example.net', '808');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('86', 'Burnice', 'King', 'rstroman@example.com', '59');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('87', 'Brent', 'Lubowitz', 'marcia.schaden@example.com', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('88', 'Cristal', 'Mayer', 'kohler.kyle@example.com', '232162');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('89', 'Justyn', 'Jacobson', 'pzulauf@example.org', '936');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('90', 'Valentina', 'Marvin', 'candida.casper@example.org', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('91', 'Diamond', 'Kunde', 'nichole18@example.com', '265');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('92', 'Dejuan', 'Tremblay', 'kcassin@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('93', 'Julianne', 'Mitchell', 'corwin.hope@example.org', '53');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('94', 'Luisa', 'Murazik', 'ipouros@example.net', '515');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('95', 'Shawna', 'Corwin', 'ijohnston@example.org', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('96', 'Julio', 'Nolan', 'kaylah83@example.org', '0');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('97', 'Hortense', 'Nikolaus', 'xmitchell@example.com', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('98', 'Gideon', 'Deckow', 'amalia40@example.org', '615');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('99', 'Scarlett', 'Daugherty', 'schuster.aric@example.net', '1');
INSERT INTO `users` (`id`, `firstname`, `lastname`, `email`, `phone`) VALUES ('100', 'Ryley', 'Koss', 'kunze.camylle@example.net', '358');



#
# TABLE STRUCTURE FOR: communities
#


INSERT INTO `communities` (`id`, `name`) VALUES ('75', 'ab');
INSERT INTO `communities` (`id`, `name`) VALUES ('78', 'adipisci');
INSERT INTO `communities` (`id`, `name`) VALUES ('21', 'aliquid');
INSERT INTO `communities` (`id`, `name`) VALUES ('65', 'aperiam');
INSERT INTO `communities` (`id`, `name`) VALUES ('89', 'architecto');
INSERT INTO `communities` (`id`, `name`) VALUES ('15', 'aut');
INSERT INTO `communities` (`id`, `name`) VALUES ('19', 'aut');
INSERT INTO `communities` (`id`, `name`) VALUES ('50', 'aut');
INSERT INTO `communities` (`id`, `name`) VALUES ('94', 'aut');
INSERT INTO `communities` (`id`, `name`) VALUES ('26', 'blanditiis');
INSERT INTO `communities` (`id`, `name`) VALUES ('41', 'consequuntur');
INSERT INTO `communities` (`id`, `name`) VALUES ('11', 'corrupti');
INSERT INTO `communities` (`id`, `name`) VALUES ('44', 'cupiditate');
INSERT INTO `communities` (`id`, `name`) VALUES ('24', 'delectus');
INSERT INTO `communities` (`id`, `name`) VALUES ('84', 'delectus');
INSERT INTO `communities` (`id`, `name`) VALUES ('88', 'delectus');
INSERT INTO `communities` (`id`, `name`) VALUES ('33', 'distinctio');
INSERT INTO `communities` (`id`, `name`) VALUES ('52', 'distinctio');
INSERT INTO `communities` (`id`, `name`) VALUES ('60', 'dolor');
INSERT INTO `communities` (`id`, `name`) VALUES ('56', 'dolore');
INSERT INTO `communities` (`id`, `name`) VALUES ('9', 'dolores');
INSERT INTO `communities` (`id`, `name`) VALUES ('87', 'dolores');
INSERT INTO `communities` (`id`, `name`) VALUES ('30', 'dolorum');
INSERT INTO `communities` (`id`, `name`) VALUES ('45', 'dolorum');
INSERT INTO `communities` (`id`, `name`) VALUES ('62', 'dolorum');
INSERT INTO `communities` (`id`, `name`) VALUES ('57', 'eligendi');
INSERT INTO `communities` (`id`, `name`) VALUES ('76', 'eligendi');
INSERT INTO `communities` (`id`, `name`) VALUES ('37', 'est');
INSERT INTO `communities` (`id`, `name`) VALUES ('61', 'est');
INSERT INTO `communities` (`id`, `name`) VALUES ('1', 'et');
INSERT INTO `communities` (`id`, `name`) VALUES ('20', 'et');
INSERT INTO `communities` (`id`, `name`) VALUES ('29', 'et');
INSERT INTO `communities` (`id`, `name`) VALUES ('39', 'et');
INSERT INTO `communities` (`id`, `name`) VALUES ('67', 'et');
INSERT INTO `communities` (`id`, `name`) VALUES ('71', 'et');
INSERT INTO `communities` (`id`, `name`) VALUES ('95', 'eum');
INSERT INTO `communities` (`id`, `name`) VALUES ('36', 'eveniet');
INSERT INTO `communities` (`id`, `name`) VALUES ('100', 'ex');
INSERT INTO `communities` (`id`, `name`) VALUES ('69', 'fuga');
INSERT INTO `communities` (`id`, `name`) VALUES ('6', 'fugiat');
INSERT INTO `communities` (`id`, `name`) VALUES ('99', 'id');
INSERT INTO `communities` (`id`, `name`) VALUES ('92', 'illum');
INSERT INTO `communities` (`id`, `name`) VALUES ('70', 'inventore');
INSERT INTO `communities` (`id`, `name`) VALUES ('74', 'ipsa');
INSERT INTO `communities` (`id`, `name`) VALUES ('81', 'ipsam');
INSERT INTO `communities` (`id`, `name`) VALUES ('25', 'labore');
INSERT INTO `communities` (`id`, `name`) VALUES ('34', 'laborum');
INSERT INTO `communities` (`id`, `name`) VALUES ('47', 'laborum');
INSERT INTO `communities` (`id`, `name`) VALUES ('18', 'maiores');
INSERT INTO `communities` (`id`, `name`) VALUES ('23', 'maxime');
INSERT INTO `communities` (`id`, `name`) VALUES ('4', 'molestiae');
INSERT INTO `communities` (`id`, `name`) VALUES ('43', 'molestiae');
INSERT INTO `communities` (`id`, `name`) VALUES ('68', 'nihil');
INSERT INTO `communities` (`id`, `name`) VALUES ('35', 'nostrum');
INSERT INTO `communities` (`id`, `name`) VALUES ('64', 'numquam');
INSERT INTO `communities` (`id`, `name`) VALUES ('48', 'occaecati');
INSERT INTO `communities` (`id`, `name`) VALUES ('16', 'odit');
INSERT INTO `communities` (`id`, `name`) VALUES ('59', 'omnis');
INSERT INTO `communities` (`id`, `name`) VALUES ('98', 'omnis');
INSERT INTO `communities` (`id`, `name`) VALUES ('5', 'perspiciatis');
INSERT INTO `communities` (`id`, `name`) VALUES ('2', 'placeat');
INSERT INTO `communities` (`id`, `name`) VALUES ('12', 'placeat');
INSERT INTO `communities` (`id`, `name`) VALUES ('72', 'praesentium');
INSERT INTO `communities` (`id`, `name`) VALUES ('77', 'praesentium');
INSERT INTO `communities` (`id`, `name`) VALUES ('97', 'quaerat');
INSERT INTO `communities` (`id`, `name`) VALUES ('63', 'quas');
INSERT INTO `communities` (`id`, `name`) VALUES ('13', 'qui');
INSERT INTO `communities` (`id`, `name`) VALUES ('66', 'qui');
INSERT INTO `communities` (`id`, `name`) VALUES ('27', 'quia');
INSERT INTO `communities` (`id`, `name`) VALUES ('22', 'quibusdam');
INSERT INTO `communities` (`id`, `name`) VALUES ('96', 'quibusdam');
INSERT INTO `communities` (`id`, `name`) VALUES ('93', 'quisquam');
INSERT INTO `communities` (`id`, `name`) VALUES ('8', 'quo');
INSERT INTO `communities` (`id`, `name`) VALUES ('49', 'quos');
INSERT INTO `communities` (`id`, `name`) VALUES ('7', 'recusandae');
INSERT INTO `communities` (`id`, `name`) VALUES ('32', 'repellat');
INSERT INTO `communities` (`id`, `name`) VALUES ('42', 'saepe');
INSERT INTO `communities` (`id`, `name`) VALUES ('91', 'sapiente');
INSERT INTO `communities` (`id`, `name`) VALUES ('3', 'sed');
INSERT INTO `communities` (`id`, `name`) VALUES ('14', 'similique');
INSERT INTO `communities` (`id`, `name`) VALUES ('38', 'sint');
INSERT INTO `communities` (`id`, `name`) VALUES ('31', 'sit');
INSERT INTO `communities` (`id`, `name`) VALUES ('55', 'sit');
INSERT INTO `communities` (`id`, `name`) VALUES ('85', 'sit');
INSERT INTO `communities` (`id`, `name`) VALUES ('51', 'soluta');
INSERT INTO `communities` (`id`, `name`) VALUES ('80', 'sunt');
INSERT INTO `communities` (`id`, `name`) VALUES ('28', 'tempore');
INSERT INTO `communities` (`id`, `name`) VALUES ('82', 'tempore');
INSERT INTO `communities` (`id`, `name`) VALUES ('53', 'unde');
INSERT INTO `communities` (`id`, `name`) VALUES ('73', 'ut');
INSERT INTO `communities` (`id`, `name`) VALUES ('17', 'velit');
INSERT INTO `communities` (`id`, `name`) VALUES ('54', 'vero');
INSERT INTO `communities` (`id`, `name`) VALUES ('40', 'vitae');
INSERT INTO `communities` (`id`, `name`) VALUES ('83', 'vitae');
INSERT INTO `communities` (`id`, `name`) VALUES ('10', 'voluptas');
INSERT INTO `communities` (`id`, `name`) VALUES ('46', 'voluptatem');
INSERT INTO `communities` (`id`, `name`) VALUES ('58', 'voluptatem');
INSERT INTO `communities` (`id`, `name`) VALUES ('86', 'voluptatem');
INSERT INTO `communities` (`id`, `name`) VALUES ('90', 'voluptatem');
INSERT INTO `communities` (`id`, `name`) VALUES ('79', 'voluptatum');


#
# TABLE STRUCTURE FOR: friend_requests
#

INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('1', '1', 'declined', '2019-03-24 05:13:29', '1995-08-19 18:23:28');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('2', '2', 'unfriended', '1978-12-16 12:31:46', '1983-10-05 18:41:05');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('3', '3', 'declined', '1971-08-29 08:38:55', '2002-02-13 19:57:44');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('4', '4', 'approved', '2015-12-29 22:26:11', '1970-07-31 03:31:27');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('5', '5', 'approved', '1979-06-07 15:42:26', '2014-06-02 00:57:55');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('6', '6', 'requested', '2002-10-26 21:24:55', '2004-02-14 04:52:27');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('7', '7', 'approved', '2017-12-04 19:55:24', '2003-04-28 19:04:24');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('8', '8', 'unfriended', '1991-06-18 06:44:43', '1996-05-08 16:10:57');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('9', '9', 'approved', '1992-04-02 18:08:30', '2011-09-04 17:37:36');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('10', '10', 'requested', '1983-09-30 23:41:23', '1980-07-31 19:31:43');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('11', '11', 'declined', '2008-11-16 19:02:49', '1975-05-22 11:56:02');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('12', '12', 'declined', '1991-06-13 21:56:07', '1987-07-10 12:36:47');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('13', '13', 'requested', '1998-06-02 16:31:14', '2006-11-25 05:45:42');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('14', '14', 'declined', '1978-09-09 15:05:29', '1995-10-10 00:29:31');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('15', '15', 'unfriended', '1999-07-28 10:32:16', '1993-10-10 05:16:14');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('16', '16', 'unfriended', '2002-02-16 20:33:34', '2015-10-18 12:45:07');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('17', '17', 'declined', '2015-10-16 00:38:59', '1992-05-19 19:15:02');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('18', '18', 'approved', '1983-06-08 17:59:27', '2004-02-18 21:46:38');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('19', '19', 'requested', '2019-09-12 15:42:00', '1991-01-20 21:17:09');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('20', '20', 'unfriended', '1989-06-22 11:10:47', '2008-05-05 10:43:32');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('21', '21', 'declined', '2011-05-20 17:18:16', '1994-01-24 21:52:37');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('22', '22', 'declined', '2010-12-13 02:23:16', '1994-09-16 19:41:53');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('23', '23', 'approved', '2005-01-03 19:22:01', '1988-06-18 01:47:09');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('24', '24', 'requested', '2011-02-25 02:23:54', '2005-01-17 00:24:02');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('25', '25', 'declined', '2003-10-22 20:23:31', '1975-01-31 19:27:47');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('26', '26', 'unfriended', '2012-07-13 13:11:08', '1996-05-28 00:37:54');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('27', '27', 'declined', '2005-05-31 02:52:54', '1989-09-08 10:58:34');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('28', '28', 'declined', '1988-10-09 01:34:25', '1970-01-06 14:58:37');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('29', '29', 'requested', '2012-05-08 06:48:00', '1987-05-21 19:55:45');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('30', '30', 'declined', '2018-06-14 17:54:59', '2002-04-17 15:36:11');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('31', '31', 'requested', '1982-07-19 20:02:46', '1970-04-18 00:00:59');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('32', '32', 'approved', '1970-08-04 09:26:52', '1981-03-07 10:43:18');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('33', '33', 'requested', '1985-10-15 07:32:37', '2012-05-05 12:23:43');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('34', '34', 'approved', '2016-02-16 01:56:11', '1990-05-24 04:20:29');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('35', '35', 'unfriended', '1984-10-19 19:14:23', '1974-09-19 14:50:25');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('36', '36', 'unfriended', '1975-04-24 17:44:50', '2010-07-30 19:24:17');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('37', '37', 'unfriended', '2000-06-28 12:52:47', '2019-08-04 08:46:37');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('38', '38', 'approved', '2015-09-23 15:39:27', '1990-01-05 21:18:56');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('39', '39', 'unfriended', '2007-03-08 13:11:31', '1980-09-12 13:12:59');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('40', '40', 'approved', '2002-02-09 02:26:05', '2001-11-13 07:22:41');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('41', '41', 'declined', '1999-08-31 08:39:36', '1998-11-04 16:12:29');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('42', '42', 'requested', '1972-09-15 20:29:56', '1984-11-09 07:58:07');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('43', '43', 'unfriended', '1975-07-02 23:47:58', '1988-10-29 16:14:41');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('44', '44', 'requested', '1983-11-30 22:46:47', '1992-06-11 23:12:20');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('45', '45', 'approved', '1999-02-14 08:46:32', '2014-01-11 05:30:26');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('46', '46', 'approved', '2016-12-14 07:57:19', '1977-05-08 12:25:49');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('47', '47', 'approved', '1978-08-26 05:23:49', '1982-09-22 09:48:56');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('48', '48', 'approved', '1973-04-08 12:04:00', '1991-10-23 21:56:22');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('49', '49', 'unfriended', '1983-09-29 05:42:49', '1985-11-13 15:25:35');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('50', '50', 'declined', '2006-03-17 17:48:36', '1977-02-15 13:49:06');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('51', '51', 'declined', '1979-09-06 02:34:16', '1970-05-30 14:46:13');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('52', '52', 'requested', '2013-05-03 11:49:34', '2006-12-14 16:36:34');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('53', '53', 'approved', '1986-10-05 00:51:40', '1982-09-30 13:10:31');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('54', '54', 'requested', '1992-06-16 06:10:30', '2008-03-01 12:21:58');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('55', '55', 'requested', '1990-06-29 22:20:35', '2008-03-03 11:49:34');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('56', '56', 'approved', '1971-07-11 19:38:16', '1988-01-03 08:10:23');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('57', '57', 'declined', '1989-10-18 04:06:12', '2018-08-13 14:40:53');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('58', '58', 'approved', '2003-08-09 06:25:10', '2017-08-09 12:36:08');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('59', '59', 'declined', '2003-09-01 21:03:07', '1988-08-01 12:58:46');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('60', '60', 'approved', '1979-12-14 22:47:07', '2004-05-01 14:58:22');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('61', '61', 'requested', '1987-10-01 04:13:45', '2011-02-08 19:41:36');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('62', '62', 'declined', '1980-05-09 13:35:05', '2001-11-26 17:46:37');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('63', '63', 'declined', '2003-11-12 12:58:16', '1993-10-29 06:31:40');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('64', '64', 'approved', '1990-11-04 01:55:00', '1975-07-24 07:13:49');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('65', '65', 'unfriended', '2006-05-26 10:55:37', '2006-09-08 10:28:06');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('66', '66', 'declined', '1986-09-28 04:30:46', '1975-06-21 03:15:18');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('67', '67', 'approved', '1970-10-31 06:28:34', '2002-12-28 19:32:19');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('68', '68', 'requested', '1984-03-21 03:01:19', '1980-06-14 04:12:29');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('69', '69', 'approved', '1978-10-19 01:31:57', '1975-11-17 23:17:27');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('70', '70', 'approved', '2001-01-07 13:20:54', '2017-02-12 03:04:29');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('71', '71', 'approved', '1991-03-16 11:14:00', '1975-04-27 14:11:11');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('72', '72', 'unfriended', '1997-10-12 07:48:03', '1993-07-24 03:39:48');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('73', '73', 'approved', '1995-09-26 03:37:30', '1988-02-24 07:27:21');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('74', '74', 'declined', '1989-06-28 07:50:12', '1988-11-05 22:37:26');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('75', '75', 'unfriended', '2012-07-02 00:40:19', '1976-07-09 14:03:18');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('76', '76', 'unfriended', '1976-01-07 06:09:10', '2013-10-28 13:07:29');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('77', '77', 'declined', '2001-02-17 00:37:35', '2004-11-09 12:06:47');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('78', '78', 'approved', '1978-11-11 03:53:02', '2011-06-25 23:16:18');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('79', '79', 'unfriended', '2007-01-22 05:03:58', '1991-08-10 11:00:24');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('80', '80', 'declined', '1994-05-25 09:04:21', '2002-10-29 09:53:25');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('81', '81', 'approved', '1985-01-03 18:39:02', '1991-12-08 20:10:39');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('82', '82', 'approved', '2002-05-19 12:37:24', '1990-04-14 00:18:44');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('83', '83', 'unfriended', '1983-08-25 01:03:11', '1990-12-02 01:16:39');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('84', '84', 'unfriended', '1999-02-03 14:48:35', '2003-10-31 15:14:33');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('85', '85', 'declined', '1987-06-03 07:53:09', '1994-11-09 14:40:43');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('86', '86', 'unfriended', '1999-10-24 07:08:50', '1984-07-05 23:50:00');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('87', '87', 'requested', '2003-06-11 22:26:39', '1988-04-27 17:02:19');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('88', '88', 'declined', '2012-01-14 06:39:53', '2004-06-14 03:08:08');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('89', '89', 'unfriended', '1979-12-31 03:18:04', '2010-12-03 19:53:17');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('90', '90', 'unfriended', '1989-04-22 02:31:11', '1979-08-15 11:11:22');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('91', '91', 'approved', '1985-01-12 13:23:57', '2002-02-15 23:23:28');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('92', '92', 'declined', '2003-04-22 19:19:35', '2005-08-18 08:40:44');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('93', '93', 'requested', '2016-11-28 06:05:04', '1992-04-21 14:01:41');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('94', '94', 'approved', '1998-09-17 23:46:40', '2009-05-16 02:36:18');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('95', '95', 'unfriended', '2018-06-23 06:49:13', '1988-09-28 21:42:31');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('96', '96', 'declined', '2005-11-06 16:30:48', '1976-10-30 02:30:21');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('97', '97', 'requested', '1994-06-19 07:56:40', '1984-02-14 11:48:59');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('98', '98', 'unfriended', '2002-11-21 12:14:28', '1970-09-04 03:34:52');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('99', '99', 'declined', '2008-07-22 19:04:41', '1997-10-13 07:08:14');
INSERT INTO `friend_requests` (`initiator_user_id`, `target_user_id`, `status`, `requested_at`, `confirmed_at`) VALUES ('100', '100', 'unfriended', '2016-05-18 02:22:57', '1994-02-11 04:17:46');


#
# TABLE STRUCTURE FOR: messages
#

INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('1', '1', '1', 'Ipsa quia quia laudantium ut ut eos. Qui excepturi maiores qui nihil dolores. Culpa culpa pariatur sit quos hic. At voluptas voluptas magni consectetur.', '2001-02-13 15:05:06');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('2', '2', '2', 'Debitis minima qui perspiciatis aperiam sed ut. Corrupti est qui molestiae quos. Sit ut dolores similique nesciunt eius ea quisquam.', '2012-09-04 21:12:16');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('3', '3', '3', 'Dolor sint dolore provident tempore suscipit nihil tempore. Quia autem sit recusandae et necessitatibus fugit. Vitae eius quia minus voluptatem recusandae commodi. Libero distinctio ducimus vel quasi aut similique. Sit exercitationem eos adipisci quae architecto facere.', '1987-05-12 07:52:24');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('4', '4', '4', 'Dolor officiis qui rerum facere voluptates recusandae numquam. Ducimus autem totam itaque error. Voluptatum quibusdam ex optio aut pariatur asperiores quis minus. Quos quis expedita perspiciatis nulla non quidem.', '2005-03-26 18:24:31');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('5', '5', '5', 'Neque nostrum enim quod nostrum beatae aliquam. Nesciunt magnam sint delectus. Impedit magnam est esse error suscipit aut quia.', '2013-03-25 18:10:55');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('6', '6', '6', 'Aut suscipit totam iure ea blanditiis sunt accusamus. Incidunt eveniet ut magni soluta similique omnis amet doloribus. Voluptatem libero saepe eos iste omnis architecto corporis omnis.', '2019-09-27 07:17:50');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('7', '7', '7', 'Perferendis minima rerum distinctio voluptatem iure magni et. Neque minus in vitae est. Sunt et consequatur dolore maiores provident dolores.', '2001-06-23 14:42:41');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('8', '8', '8', 'Impedit aperiam necessitatibus qui maiores soluta porro. Incidunt in sunt repellat ut totam consequatur. Laborum dolorem modi non delectus dolorem. Animi quae corrupti quos corrupti possimus qui consequuntur est.', '2010-12-09 06:47:54');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('9', '9', '9', 'Blanditiis eligendi consequuntur eveniet quisquam. Vitae perferendis exercitationem voluptas ducimus qui sed quia quod. Ea libero eum asperiores sit. Sit vel consequuntur unde animi in quia.', '2011-11-25 15:29:41');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('10', '10', '10', 'Quas aut hic dicta sequi qui molestiae quas. Iste libero reiciendis cumque aperiam deleniti et quia.', '1996-09-20 21:30:57');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('11', '11', '11', 'At rerum est harum aliquid illum fugiat. Perspiciatis corporis sequi ad voluptas aut voluptatem non. Quasi quo commodi amet consequatur in. Ex excepturi est suscipit ipsum. Minus laboriosam aut eum pariatur velit quo architecto ut.', '1982-09-07 03:15:56');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('12', '12', '12', 'Omnis aspernatur qui animi sed ipsa dolorem cum. Nesciunt non ut aut et voluptatem tempora quaerat. Minima rerum molestiae vero dignissimos quas. Aut unde minus cupiditate et.', '2017-11-28 21:30:15');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('13', '13', '13', 'Sapiente veritatis culpa non. Modi sapiente quod possimus perspiciatis voluptas doloribus assumenda. Tenetur aliquam ea maxime possimus. Consequuntur repellendus omnis ipsam.', '1982-08-03 21:11:18');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('14', '14', '14', 'Et dignissimos quibusdam ut dolores sapiente laboriosam hic. Eius commodi repellendus quaerat ut cupiditate officiis ut. Quos vero in enim eum dolores.', '1970-08-24 13:09:41');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('15', '15', '15', 'Ipsam ut molestias asperiores ut iusto. Veritatis non quisquam dolorem minus. Ea minima facere ut nesciunt et.', '1981-12-28 17:01:44');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('16', '16', '16', 'Laboriosam maxime sit et voluptatibus iure est dolorem. Quae accusantium reiciendis omnis facilis assumenda.', '2018-09-25 02:05:18');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('17', '17', '17', 'Neque tenetur delectus dolorem laborum possimus sit et. Mollitia autem sit tempore consequuntur ratione enim rerum quis. Eos laborum incidunt recusandae ea.', '1983-02-10 02:40:31');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('18', '18', '18', 'Vel similique molestias nam laboriosam. Sed autem optio voluptatem dolores dolorum maiores eligendi laborum. Doloremque amet sint ea neque.', '2002-09-22 16:19:09');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('19', '19', '19', 'Id voluptatem voluptate aliquid sint velit consequatur. Excepturi rerum blanditiis non enim est quis quae. Et rerum voluptate quo. Et id voluptatibus magni ut non delectus quisquam fugiat.', '1996-04-19 11:53:27');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('20', '20', '20', 'Aliquam vitae cumque eveniet voluptas. Reprehenderit delectus error ipsam non aut aliquam. Amet inventore repudiandae hic cum. Quisquam et voluptatem veniam debitis hic. Itaque ipsa sed rerum sapiente in.', '1983-01-06 02:30:21');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('21', '21', '21', 'Dolor necessitatibus a rerum repellendus dolorem. Praesentium consectetur non inventore non. Vero et dolores suscipit sed. Sunt dolores est fugiat.', '1992-03-10 07:33:56');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('22', '22', '22', 'Facilis ipsam ut beatae aliquid architecto. Magnam et ipsum aut quos dolore. Voluptatibus odit blanditiis iusto. Fugiat voluptas est repellendus et laboriosam.', '1991-12-14 04:26:21');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('23', '23', '23', 'Est dignissimos modi aliquam accusamus ea doloremque. Nostrum ea et et consequatur vitae. Ab qui doloremque vel.', '1979-06-21 09:57:39');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('24', '24', '24', 'Nostrum molestiae dolor et et voluptas. Enim ut qui quia. Ea occaecati cum et aut eum neque beatae saepe. Tempora sunt quisquam ex magni est eaque cupiditate.', '1992-02-03 11:25:42');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('25', '25', '25', 'Ea voluptas sit occaecati perferendis est quod. Quis ut sed sed provident placeat. Eveniet error officiis quam quae totam maxime saepe. Cum et perspiciatis alias mollitia maiores. Iure ea est facere temporibus cum error.', '2016-12-16 06:22:57');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('26', '26', '26', 'Ut et esse voluptatem neque esse. In id ipsam in perferendis. Vero sint voluptas qui dolor dolor omnis.', '1984-12-11 04:25:01');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('27', '27', '27', 'Vero ratione vel magni ea. Velit quidem consequatur nihil et incidunt. Aut vero reprehenderit non.', '1989-01-06 23:00:26');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('28', '28', '28', 'Sed excepturi aspernatur minus non modi ad. Quia nesciunt vero blanditiis atque dolorem tenetur voluptatibus. Et voluptate sint numquam enim sed voluptatem mollitia.', '2007-08-09 00:48:05');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('29', '29', '29', 'Cum quo doloremque ut ab nemo deleniti ut. Quis error eligendi eum. Voluptatem nihil aut sunt. Adipisci praesentium debitis quia reiciendis blanditiis. Officia velit odio porro consequatur distinctio consequatur consequatur.', '1998-09-26 15:23:05');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('30', '30', '30', 'Temporibus rerum maiores repellendus. Vel autem soluta dignissimos aliquam qui. Magni ut consectetur cum nam est et. Quaerat possimus architecto voluptates.', '1982-05-24 19:48:25');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('31', '31', '31', 'Eos cumque voluptas dolore eum velit quia incidunt. Eum nemo similique neque eos provident ipsa. Autem omnis unde recusandae aut. Non voluptas deserunt maiores perferendis qui veniam.', '1978-10-30 22:16:16');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('32', '32', '32', 'Qui ut est corrupti iure nemo. Et quo qui non est in. Odio quod temporibus quibusdam earum deserunt molestiae.', '1981-08-19 18:51:56');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('33', '33', '33', 'Fugit velit dicta tenetur delectus facere. Ut in harum sit eos architecto incidunt. Animi aliquam veritatis omnis maiores quasi labore. Quis incidunt ipsum harum numquam perferendis quos.', '2017-03-29 14:03:39');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('34', '34', '34', 'Ratione qui id id dolor. Aut nam est et delectus enim et dolorum voluptas. Officia possimus nulla ea ut.', '2011-08-22 09:57:51');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('35', '35', '35', 'Odio qui asperiores porro vero ipsum ipsum vero. Quos dignissimos dicta aut.', '1979-12-10 22:38:47');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('36', '36', '36', 'Praesentium enim possimus non cum beatae tempore nesciunt est. Occaecati dignissimos quae quas fugiat provident et ut. Aut et sint numquam quo.', '1979-09-22 08:29:19');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('37', '37', '37', 'Ut veritatis dolorum quia voluptas rem praesentium qui quaerat. Voluptate voluptate eos exercitationem in dolorem assumenda. Minima culpa sint assumenda quia aperiam harum aut nesciunt.', '2002-12-11 16:05:51');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('38', '38', '38', 'Necessitatibus placeat aspernatur nobis modi. Error molestiae incidunt quaerat voluptatem pariatur ab. Ex dolor corrupti reprehenderit minima sit sed.', '1973-07-10 09:37:58');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('39', '39', '39', 'Earum et itaque recusandae sit dignissimos. Asperiores soluta est repellendus eligendi velit maiores. Eaque ad mollitia voluptatem. Quo corporis consequuntur numquam aut quo qui voluptas.', '1977-11-12 15:33:08');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('40', '40', '40', 'Minus quis nobis rerum qui beatae explicabo veniam. Velit quasi hic consequatur molestias dolor id molestias. Et consectetur nisi id est. Id qui ratione quod.', '1975-11-11 04:38:13');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('41', '41', '41', 'Et nam nemo veniam est aut. Et distinctio atque dolores minima commodi mollitia quis. Ut neque suscipit quidem odit in repellendus aliquam rerum.', '1973-09-16 22:10:00');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('42', '42', '42', 'Illum adipisci error harum suscipit debitis ea tempore. Ad perspiciatis quidem itaque quisquam. Velit facere inventore cupiditate ipsa quibusdam enim. Omnis et reiciendis illum cum corporis maxime exercitationem.', '1999-09-06 11:20:54');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('43', '43', '43', 'Aut suscipit iusto minus nemo. Adipisci earum animi eos velit nemo omnis. Eligendi vel rerum quae tempore excepturi eum. Sit vel magnam qui libero.', '2008-04-05 23:26:16');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('44', '44', '44', 'Dolor aut quisquam aliquid minus numquam quod. Est error eveniet et perferendis ducimus explicabo vitae. Repellendus sint delectus reprehenderit amet a. Ut delectus unde qui saepe maxime voluptatem.', '1986-10-28 04:08:40');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('45', '45', '45', 'Corrupti enim omnis ipsum fugiat nobis omnis dolorum. Saepe vel omnis numquam. Laboriosam voluptatum culpa rerum est vel molestias et non. Atque et consequatur aut qui quisquam quia expedita. Repellat sit recusandae consequatur et.', '1983-01-13 14:34:51');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('46', '46', '46', 'Architecto nam velit temporibus iure est. Magnam inventore ut dolorem sit. Neque laborum voluptas in aut.', '1996-03-28 23:21:37');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('47', '47', '47', 'Natus modi sint nam quibusdam nostrum aut. Est temporibus enim rerum architecto rerum sint nisi. Debitis quos aliquid error eligendi autem quia.', '1994-07-11 04:40:29');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('48', '48', '48', 'Ipsum beatae libero rerum qui id minima. Corporis excepturi neque officiis repellat recusandae fuga illum. Quia et alias adipisci sapiente magnam beatae. Omnis libero dicta repellendus recusandae.', '2003-02-28 21:51:28');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('49', '49', '49', 'Quidem et sequi qui repellat vero. Aspernatur fuga sunt cum ipsum non. Voluptas iusto repellat rerum eos vero qui dignissimos accusantium.', '1988-12-17 13:46:55');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('50', '50', '50', 'Eligendi ducimus inventore aliquid maiores voluptate. Aliquid iusto ducimus repudiandae excepturi sunt expedita. Enim odit blanditiis quae aut optio eum itaque. Rem dignissimos officia necessitatibus officia ad nobis assumenda.', '1994-10-26 07:20:48');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('51', '51', '51', 'Ipsam nostrum non ipsum ea alias nam. Ullam officiis ipsa consequatur consequatur sequi beatae cumque. Quia ut incidunt sed porro. Laboriosam natus sit quia illum doloremque consequatur ut.', '1973-11-14 16:06:15');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('52', '52', '52', 'Ea consectetur exercitationem officiis nam. Facilis consequuntur dolorem aperiam incidunt. Aut qui ad sed dolorum repudiandae.', '1973-05-07 10:02:10');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('53', '53', '53', 'Sit vel aut aut sed voluptatum. Ducimus molestiae ut enim excepturi explicabo eligendi recusandae.', '1970-07-20 08:13:38');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('54', '54', '54', 'Aliquid in cumque asperiores nemo nihil nulla ea aut. Qui officia sed nostrum ullam laboriosam voluptates occaecati. Maiores cupiditate saepe sequi delectus eveniet qui accusantium. Repudiandae sed aut suscipit dolores et quod atque sequi. Et consequatur omnis voluptas ducimus impedit.', '2014-07-07 15:37:00');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('55', '55', '55', 'Quia occaecati quibusdam dolor voluptatem quo aspernatur. Impedit aut ut qui eaque voluptatem doloremque. Ipsam architecto laborum qui dicta. Esse consequatur maiores quidem alias aut cupiditate. Voluptas saepe vel dolores error voluptatum cupiditate asperiores.', '2008-01-20 08:26:02');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('56', '56', '56', 'Quasi similique voluptatem accusantium adipisci rem facilis. Eligendi minus ut ex quibusdam distinctio qui sunt. Ex accusamus voluptate asperiores commodi omnis ipsum minus ducimus. Sint itaque explicabo ut eos dolor iusto enim. Et deserunt quasi et omnis aut id.', '1992-02-06 09:31:10');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('57', '57', '57', 'Assumenda est praesentium ut et. Beatae ullam quod ea expedita eius error magnam iusto.', '2018-10-26 07:52:31');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('58', '58', '58', 'Est unde qui qui dolores. Sunt est eveniet dolores rerum eos eveniet sapiente.', '1988-07-24 00:04:57');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('59', '59', '59', 'Molestiae architecto excepturi cum omnis placeat. Ipsam repellat quis numquam enim aliquam saepe. Aut ipsa officia aut accusamus aut ratione facere debitis. Animi doloribus delectus ex et.', '1977-06-15 16:16:01');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('60', '60', '60', 'Error est voluptate sed repellendus ut ut. Aut sequi repellendus illo quo aliquid cum. Et velit voluptatem ipsum officiis magnam.', '1971-09-18 22:16:19');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('61', '61', '61', 'Voluptate et facilis quae quidem molestias explicabo. Asperiores a error cupiditate id perferendis veniam sit.', '2001-08-16 22:45:30');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('62', '62', '62', 'Voluptatem sint dolores ducimus sint sapiente et deleniti. Consectetur dolorum tempora nihil. Repellat distinctio doloribus ipsum soluta. Sequi hic aut fuga.', '1989-06-09 17:42:51');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('63', '63', '63', 'Est a eos autem aut ut totam. Consequatur ipsum debitis quis facere deleniti. Eligendi id amet distinctio similique sit.', '2010-04-18 21:47:08');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('64', '64', '64', 'Perferendis illum unde dolores debitis sapiente non. Est repudiandae unde blanditiis voluptas molestias. Aperiam impedit nobis quo est. Repellat voluptatum vero labore.', '1981-01-11 06:57:24');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('65', '65', '65', 'Animi qui voluptatem sunt ad quam velit. Nihil ullam voluptas repellat.', '1992-12-31 18:53:47');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('66', '66', '66', 'Aut necessitatibus velit sint sit molestias modi. Qui rerum tempore asperiores. Aut quia quia aliquid omnis dolore. Dignissimos ad perspiciatis corporis repellendus ut.', '2012-02-04 14:50:14');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('67', '67', '67', 'Ipsum praesentium sint quia mollitia cumque quia tempora. Ab aliquam et eveniet totam iure voluptatem necessitatibus. Commodi odit hic ea. Qui cupiditate id et quia qui odit.', '1997-06-25 13:49:47');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('68', '68', '68', 'Et quas molestias vel. Facilis ut provident iusto vero illum itaque. Vel repellendus nobis debitis repudiandae ipsum doloremque.', '1999-08-15 13:08:19');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('69', '69', '69', 'Quo eos aspernatur sit officia. Qui reiciendis assumenda eos inventore delectus. Tempore natus minima nulla quod ut praesentium laborum.', '1981-02-24 03:51:04');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('70', '70', '70', 'Incidunt facere vero vel laudantium perspiciatis. Cupiditate aperiam quae dignissimos aspernatur sed. Ea itaque delectus iure velit distinctio labore hic.', '1972-12-04 04:12:31');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('71', '71', '71', 'Voluptates ut repudiandae odio ut. Magnam optio incidunt ut sint placeat et soluta. Laboriosam est omnis et nesciunt. Aut aperiam modi qui voluptatem sit. Non voluptatem est velit et libero.', '1995-01-21 21:48:25');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('72', '72', '72', 'Ipsam perspiciatis magni accusamus veritatis modi ut adipisci molestias. Et excepturi et est eos ex. Accusamus nam vero aut vero. Qui ut saepe illo consequatur qui quis.', '1976-04-03 02:25:52');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('73', '73', '73', 'Sit blanditiis temporibus est itaque necessitatibus animi. Ut minima eius deserunt odio blanditiis autem qui.', '1979-11-30 20:33:47');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('74', '74', '74', 'Repudiandae et id quasi molestias. Ut explicabo aliquid laudantium natus quo aspernatur. Natus eaque sit qui cum qui neque totam.', '2016-07-07 23:33:28');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('75', '75', '75', 'Perspiciatis ad earum repellendus officia. Sint alias facere repudiandae quis repudiandae qui.', '1971-06-28 12:37:00');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('76', '76', '76', 'Illum distinctio vero voluptatem dignissimos. Consequatur et aspernatur recusandae. Molestias nihil et qui saepe.', '2000-02-10 05:17:51');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('77', '77', '77', 'Est alias a rerum maiores iste nam iste. Reiciendis id quia natus ut alias officia incidunt. Rerum minus id et. Ipsam praesentium praesentium quis.', '1989-10-02 18:35:19');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('78', '78', '78', 'At est doloremque quis sit odit eveniet ea. Dignissimos quo consequatur ad. Nobis eaque sed minima quia est at.', '1976-10-23 10:26:16');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('79', '79', '79', 'Eligendi quasi minima debitis recusandae. Aliquid beatae illum voluptates et animi.', '1991-07-24 06:12:18');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('80', '80', '80', 'Beatae reiciendis praesentium eum nihil tempore omnis rerum. Temporibus qui eveniet quos eos temporibus fugit voluptatum. Deleniti quam quasi ut laboriosam.', '1988-04-12 12:05:53');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('81', '81', '81', 'Quo omnis sunt et hic. Hic ipsam voluptatum debitis eaque ea debitis et. Saepe atque quasi magnam sint.', '2010-03-31 08:35:07');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('82', '82', '82', 'Hic quam sed ut voluptate sint accusamus. Ratione libero ut recusandae. Dolorem sint est quia.', '1989-12-20 22:15:47');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('83', '83', '83', 'Sequi et optio asperiores non. Ratione qui vero recusandae ut in. Dolorem quo cumque voluptas ut exercitationem aut quas consequatur. Expedita laborum repudiandae soluta rerum iusto ipsum nihil.', '1987-09-13 07:16:57');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('84', '84', '84', 'Dolorum tempora sapiente nihil nobis sunt nisi. Occaecati vero expedita placeat et quis consectetur. Recusandae suscipit illo eum vero voluptatum. Blanditiis inventore excepturi eveniet cum quisquam voluptas.', '2015-12-12 18:08:50');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('85', '85', '85', 'Hic reprehenderit eum voluptatum eum culpa. Nobis hic sed similique perspiciatis consequuntur et. Et et inventore dicta omnis iusto. Eum quos sequi mollitia laborum repudiandae laudantium.', '2008-01-01 05:19:04');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('86', '86', '86', 'Possimus omnis eligendi eius enim nostrum omnis assumenda. Maxime iste dicta omnis debitis ipsa aperiam nostrum aut. Ea facilis quis commodi dolore. Quibusdam quia deserunt laudantium ea voluptatem fugit. Perspiciatis alias inventore sed sapiente sed nobis.', '2000-06-14 16:50:45');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('87', '87', '87', 'Quo eius qui laborum. Ex doloribus voluptatum adipisci temporibus at ipsum qui. Et quis corrupti soluta mollitia.', '1981-12-26 22:49:01');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('88', '88', '88', 'Sed veritatis laboriosam consequatur sit asperiores molestiae velit. Optio odio quaerat corporis consequatur aut pariatur. Facilis quia vitae expedita nostrum.', '1981-08-08 00:07:32');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('89', '89', '89', 'Rerum ut iste dolorem laboriosam. Similique porro voluptatibus debitis ducimus. Aspernatur reiciendis fuga ut doloremque.', '2019-07-27 09:54:24');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('90', '90', '90', 'Voluptatem est quaerat occaecati velit ad. Labore aspernatur tenetur modi quam ut labore eaque commodi.', '1988-04-26 23:35:14');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('91', '91', '91', 'Et dolores facere aut sunt saepe omnis suscipit. In aspernatur occaecati consequuntur. Voluptatem ad qui architecto eum ratione dolor repellendus. Iusto odio voluptatem in mollitia cumque.', '1986-03-13 23:59:17');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('92', '92', '92', 'Exercitationem qui maxime ducimus et corporis aut. Vero eum et sed. Totam omnis rem eos quia et. Placeat sapiente qui sed magni eos corporis accusamus.', '1976-06-09 19:02:44');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('93', '93', '93', 'Qui id occaecati vero quod. Id magni voluptatem ut adipisci non facere. Magni dolor quia cumque ullam. Quaerat vero itaque voluptatem quia quos.', '1981-12-16 07:25:52');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('94', '94', '94', 'Consequatur sapiente sunt omnis maiores. Blanditiis aut corporis velit voluptatem quis. Ea rerum quo distinctio. Deserunt minus non et explicabo veniam tempora.', '2016-04-09 16:12:52');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('95', '95', '95', 'Illo dicta quam dicta dolorem sapiente. Enim ut explicabo deleniti rerum ullam accusantium. Ipsam minus aliquam repellendus ut.', '1988-06-29 23:28:38');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('96', '96', '96', 'Quo aspernatur aut nulla. Rem quis tempora voluptas error soluta aliquam praesentium. Sed voluptatum qui modi ducimus temporibus numquam est.', '1980-09-09 04:38:44');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('97', '97', '97', 'Ullam ratione ut tempora quia nostrum quas. Et corrupti nostrum cumque hic accusamus ut cum. Eum provident numquam fugit ducimus et nobis.', '1996-10-30 17:35:05');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('98', '98', '98', 'Sed at molestiae atque minima nisi necessitatibus rerum. Maxime magnam iste itaque possimus nostrum rerum neque. Modi alias vitae excepturi nesciunt repellendus porro. Placeat sit mollitia numquam nihil delectus.', '1993-11-17 07:47:36');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('99', '99', '99', 'Quia aliquam sed atque iure praesentium necessitatibus natus. Quisquam voluptatem ut iusto sint voluptatem et. Quia id aut harum et et vel aperiam.', '1996-12-03 01:44:06');
INSERT INTO `messages` (`id`, `from_user_id`, `to_user_id`, `body`, `created_at`) VALUES ('100', '100', '100', 'Iste modi quod aut nostrum id fugiat. Enim tenetur id eligendi molestiae dolores sed harum expedita.', '1982-05-14 18:25:26');


#
# TABLE STRUCTURE FOR: profiles
#

INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('1', 'k', '2010-08-03', NULL, '1999-11-13 02:03:13', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('2', 'k', '1994-08-14', NULL, '2015-04-10 15:53:19', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('3', 'k', '1997-07-15', NULL, '1986-01-26 04:24:43', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('4', 'x', '1989-11-12', NULL, '1971-09-11 03:17:50', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('5', 'o', '1986-04-22', NULL, '2012-09-30 21:07:05', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('6', 'y', '1979-02-07', NULL, '2007-03-29 01:59:21', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('7', 'o', '2010-03-14', NULL, '1989-05-11 14:45:27', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('8', 'w', '1977-06-05', NULL, '2006-11-22 13:51:54', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('9', 'a', '1985-08-06', NULL, '1997-11-27 14:40:30', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('10', 'u', '1987-09-26', NULL, '1971-02-18 21:38:58', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('11', 't', '2011-05-21', NULL, '1984-08-26 12:38:32', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('12', 'k', '1993-04-17', NULL, '1988-06-12 02:02:08', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('13', 'r', '2003-01-04', NULL, '1976-11-07 02:11:16', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('14', 'g', '2013-10-19', NULL, '1980-11-22 16:59:49', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('15', 'c', '1985-07-20', NULL, '1986-12-02 07:34:54', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('16', 'h', '1991-08-09', NULL, '1991-12-19 12:01:32', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('17', 'e', '1970-03-23', NULL, '2015-07-27 13:42:31', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('18', 'k', '1973-08-16', NULL, '1971-01-11 12:12:36', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('19', 'u', '2009-03-29', NULL, '1997-11-19 11:54:15', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('20', 'q', '1984-08-03', NULL, '1980-03-14 11:28:04', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('21', 's', '2007-08-03', NULL, '1988-02-28 07:24:37', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('22', 'f', '1994-03-19', NULL, '2013-10-19 12:41:02', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('23', 'x', '1975-07-27', NULL, '2001-05-27 10:23:02', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('24', 't', '1987-08-10', NULL, '1983-07-20 22:39:16', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('25', 'q', '1999-11-18', NULL, '2014-07-11 13:34:31', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('26', 'd', '1973-02-03', NULL, '1983-06-04 13:11:15', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('27', 'g', '1977-12-13', NULL, '2004-12-13 22:42:36', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('28', 'm', '2004-04-03', NULL, '2010-06-02 11:46:50', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('29', 'm', '2018-06-27', NULL, '1992-05-04 00:57:26', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('30', 'm', '1986-10-27', NULL, '1982-12-17 22:08:52', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('31', 'z', '1996-01-22', NULL, '2011-12-17 12:58:38', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('32', 'y', '1989-04-05', NULL, '1975-02-03 17:37:21', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('33', 'y', '1976-08-27', NULL, '2003-09-27 20:29:31', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('34', 'q', '1982-03-20', NULL, '2006-08-17 06:46:51', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('35', 'p', '2003-02-04', NULL, '2004-12-07 11:06:23', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('36', 'g', '1987-12-14', NULL, '2013-11-06 13:03:55', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('37', 'a', '2017-09-01', NULL, '1979-03-26 08:01:08', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('38', 'k', '1993-03-25', NULL, '2007-09-10 00:30:13', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('39', 'r', '2011-09-05', NULL, '1985-12-07 09:16:01', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('40', 'u', '1996-01-01', NULL, '1982-06-05 20:29:28', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('41', 's', '2009-01-21', NULL, '2004-03-18 09:56:27', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('42', 'o', '2000-07-18', NULL, '1989-11-15 01:26:03', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('43', 'c', '1970-10-03', NULL, '2011-06-13 08:02:39', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('44', 'f', '1982-04-30', NULL, '1978-11-19 06:25:09', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('45', 'n', '1973-05-04', NULL, '1970-03-15 08:15:50', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('46', 'o', '1977-01-12', NULL, '1992-04-11 08:00:07', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('47', 'a', '2004-07-17', NULL, '1988-12-28 18:43:07', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('48', 'd', '2003-08-13', NULL, '2000-04-11 11:32:02', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('49', 'f', '2008-10-13', NULL, '2013-03-14 05:56:12', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('50', 'b', '1971-05-27', NULL, '1993-09-13 12:32:34', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('51', 'g', '2006-07-24', NULL, '1993-03-02 01:43:07', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('52', 'o', '1977-02-11', NULL, '2014-07-06 02:01:19', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('53', 'k', '1992-11-11', NULL, '2018-02-18 03:18:55', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('54', 'f', '1986-07-27', NULL, '2012-03-01 02:32:13', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('55', 'f', '2005-08-21', NULL, '1993-10-15 12:05:53', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('56', 'w', '1973-07-17', NULL, '1996-09-11 11:43:21', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('57', 'a', '1988-10-17', NULL, '1975-12-11 18:12:03', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('58', 'v', '2013-12-08', NULL, '1987-09-01 10:15:47', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('59', 'c', '1997-06-04', NULL, '1989-09-12 20:08:54', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('60', 'h', '1970-04-05', NULL, '1973-11-22 01:39:06', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('61', 'c', '1981-08-08', NULL, '2001-09-20 18:31:13', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('62', 'e', '1986-04-24', NULL, '2019-05-14 12:50:39', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('63', 'y', '1970-08-26', NULL, '1971-07-09 19:14:34', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('64', 't', '1993-06-26', NULL, '1976-11-04 23:44:54', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('65', 'd', '1993-07-19', NULL, '2001-01-28 00:32:13', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('66', 'i', '1994-08-29', NULL, '2005-04-30 13:54:44', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('67', 'k', '1983-03-05', NULL, '1975-12-18 12:53:29', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('68', 'o', '1992-03-28', NULL, '1973-09-12 21:02:48', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('69', 'p', '2016-06-10', NULL, '1975-11-14 16:15:36', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('70', 'd', '1992-10-02', NULL, '1985-11-02 10:24:45', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('71', 'c', '1979-04-13', NULL, '1983-03-09 20:43:36', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('72', 'u', '1987-04-03', NULL, '2016-10-02 01:57:08', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('73', 'y', '2008-10-11', NULL, '2002-04-30 01:31:32', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('74', 'y', '2002-02-06', NULL, '2017-01-09 02:49:50', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('75', 'y', '1997-05-15', NULL, '1992-02-29 20:11:16', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('76', 'z', '2011-02-14', NULL, '1996-09-07 09:51:05', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('77', 'y', '1992-11-19', NULL, '1993-05-31 20:19:17', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('78', 'm', '2000-10-06', NULL, '1991-12-21 03:12:23', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('79', 'h', '1985-03-21', NULL, '2014-07-22 08:18:40', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('80', 'x', '1971-06-27', NULL, '1978-04-28 12:00:20', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('81', 'l', '1991-06-28', NULL, '1997-12-15 05:49:27', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('82', 'n', '1970-01-03', NULL, '1995-07-22 22:24:34', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('83', 's', '2015-07-21', NULL, '2015-10-06 09:45:36', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('84', 'g', '1981-08-28', NULL, '1989-03-29 06:19:22', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('85', 'k', '1995-11-19', NULL, '1986-06-05 00:40:58', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('86', 'd', '1982-03-31', NULL, '2002-02-23 09:56:28', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('87', 'e', '1986-01-13', NULL, '2019-04-13 18:05:52', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('88', 'v', '2009-08-27', NULL, '1979-05-14 05:41:24', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('89', 'i', '1986-03-07', NULL, '2000-10-12 14:04:52', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('90', 'c', '2009-11-11', NULL, '1981-07-26 09:39:20', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('91', 'q', '1970-03-29', NULL, '1987-05-30 13:27:29', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('92', 'r', '2004-03-18', NULL, '2009-09-15 22:09:39', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('93', 'l', '1980-06-13', NULL, '2004-09-04 14:56:43', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('94', 'k', '1999-08-02', NULL, '2002-08-04 16:36:57', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('95', 'x', '2015-03-29', NULL, '2003-04-07 10:19:07', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('96', 'd', '1996-02-12', NULL, '1973-08-24 01:10:55', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('97', 'r', '1986-11-22', NULL, '1984-07-29 13:14:34', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('98', 'f', '1973-05-10', NULL, '2013-06-13 00:39:22', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('99', 'z', '1970-05-29', NULL, '1992-01-23 08:25:20', NULL);
INSERT INTO `profiles` (`user_id`, `gender`, `birthday`, `photo_id`, `created_at`, `hometown`) VALUES ('100', 's', '1984-03-17', NULL, '2013-08-16 14:44:12', NULL);


#
# TABLE STRUCTURE FOR: users_communities
#


INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('1', '1');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('2', '2');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('3', '3');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('4', '4');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('5', '5');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('6', '6');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('7', '7');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('8', '8');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('9', '9');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('10', '10');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('11', '11');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('12', '12');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('13', '13');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('14', '14');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('15', '15');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('16', '16');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('17', '17');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('18', '18');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('19', '19');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('20', '20');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('21', '21');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('22', '22');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('23', '23');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('24', '24');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('25', '25');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('26', '26');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('27', '27');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('28', '28');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('29', '29');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('30', '30');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('31', '31');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('32', '32');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('33', '33');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('34', '34');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('35', '35');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('36', '36');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('37', '37');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('38', '38');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('39', '39');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('40', '40');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('41', '41');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('42', '42');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('43', '43');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('44', '44');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('45', '45');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('46', '46');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('47', '47');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('48', '48');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('49', '49');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('50', '50');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('51', '51');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('52', '52');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('53', '53');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('54', '54');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('55', '55');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('56', '56');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('57', '57');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('58', '58');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('59', '59');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('60', '60');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('61', '61');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('62', '62');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('63', '63');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('64', '64');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('65', '65');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('66', '66');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('67', '67');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('68', '68');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('69', '69');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('70', '70');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('71', '71');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('72', '72');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('73', '73');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('74', '74');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('75', '75');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('76', '76');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('77', '77');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('78', '78');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('79', '79');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('80', '80');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('81', '81');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('82', '82');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('83', '83');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('84', '84');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('85', '85');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('86', '86');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('87', '87');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('88', '88');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('89', '89');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('90', '90');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('91', '91');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('92', '92');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('93', '93');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('94', '94');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('95', '95');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('96', '96');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('97', '97');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('98', '98');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('99', '99');
INSERT INTO `users_communities` (`user_id`, `community_id`) VALUES ('100', '100');


