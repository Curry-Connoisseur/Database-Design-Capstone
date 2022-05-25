-- phpMyAdmin SQL Dump
-- version 4.8.5
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Dec 16, 2019 at 04:29 PM
-- Server version: 5.7.26
-- PHP Version: 7.2.18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `car rentals`
--
CREATE DATABASE IF NOT EXISTS `car rentals` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `car rentals`;

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `10_revenues_2019`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `10_revenues_2019` ()  Begin
SELECT CONCAT('$', FORMAT(SUM(Pay_Total), 2)) AS `Total Revenue for 2019` 
FROM payment, reservation
WHERE payment.Cust_ID=reservation.Cust_ID 
AND Reserv_Pickup <= '2019-12-31' AND Reserv_Pickup >= '2019-01-01' 
AND Reserv_Dropoff <= '2019-12-31' AND Reserv_Dropoff >= '2019-01-01' 
AND Pay_Status = 1;

/*(This query will return the total revenues that the company received for the 2019 profit year. This will allow us to determine various things like taxes on revenue that need to be paid, agent salaries, and others.)*/
END$$

DROP PROCEDURE IF EXISTS `11_Agent_assistance`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `11_Agent_assistance` ()  Begin
SELECT CONCAT(a.Agent_FName,' ', a.Agent_LName) AS `Agent Name`, CONCAT(c.Cust_Fname,' ', c.Cust_Lname) as `Customer being assisted`
FROM agent a, customer c, booking b, reservation r 
WHERE a.Agent_ID = b.Agent_ID AND b.Reserv_ID = r.Reserv_ID AND r.Cust_ID = c.Cust_ID;

/* this query will return which agent assisted which customer. This will be useful when the company sends surveys to our customers on how their service was. */
END$$

DROP PROCEDURE IF EXISTS `12_paystatus`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `12_paystatus` (IN `var_custid` INT(5))  Begin
SELECT p.Cust_ID, CONCAT(Cust_Fname, ' ', Cust_Lname) AS `Customer Name`, IF(Pay_Status = 0, "Not Paid", "Paid") AS `Payment Status`
FROM customer c, payment p
WHERE c.Cust_ID = p.Cust_ID AND p.Cust_ID = var_custid;

/*This query will ask for a customer ID input and return whether the customer has Paid yet or not. This can be useful if for example a customer calls the company to inquire whether we have recieved their payment */
END$$

DROP PROCEDURE IF EXISTS `13_viewPrevious_renters`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `13_viewPrevious_renters` (IN `var_carmodel` VARCHAR(20))  Begin
SELECT VehiDet_Model AS `Vehicle Model`, CONCAT(Cust_Fname, ' ',
Cust_Lname) AS `Customer Name`
FROM vehicle_details vd, vehicle v, reservation r, customer c
WHERE vd.VehiDet_ID = v.VehiDet_ID AND v.Vehi_ID = r.Vehi_ID AND
r.Cust_ID = c.Cust_ID AND vd.VehiDet_Model = var_carmodel;

/* This parameterized query will allow us to view exactly who has rented which cars when we input a Model name. This will be useful in seeing which cars our customers seem to prefer.*/

END$$

DROP PROCEDURE IF EXISTS `1_install_reversecam`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `1_install_reversecam` ()  Begin
SELECT CONCAT(VehiDet_Make, '  ', VehiDet_Model, '  ') AS `Car Name`, VehiDet_Year AS `Vehicle Model Year`, VehiDet_Type AS `Vehicle Registration`
FROM vehicle_details, vehicle 
WHERE vehicle.VehiDet_ID = vehicle_details.VehiDet_ID AND vehicle_details.VehiDet_Year < 2010 AND vehicle.Vehi_Availability = 1;

/*(We want to find out what vehicles were made before 2010 and are also currently on the lot, so that we can find all the vehicles that we need to install aftermarket reverse cameras onto for extra driver safety.)*/
END$$

DROP PROCEDURE IF EXISTS `2_promote_agent`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `2_promote_agent` ()  Begin
SELECT (CONCAT(agent_Fname, ' ', agent_Lname)) AS `Agent Name`
FROM booking, agent
WHERE agent.Agent_ID = booking.Agent_ID
GROUP BY booking.Agent_ID
HAVING COUNT(booking.Agent_ID) > 5;

/*( This query will pull the agent First and Last name of the agent(s) who have assisted in more than 5 bookings. This will be useful as we look for employees to give a promotion for outstanding service in assisting many customers.)*/
END$$

DROP PROCEDURE IF EXISTS `3_popular_cars`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `3_popular_cars` ()  Begin
SELECT VehiDet_Make AS `Vehicle Make`, VehiDet_Model AS `Vehicle Model`, COUNT(booking.Vehi_ID) AS `Number of Times Booked`
FROM booking, vehicle, vehicle_details
WHERE booking.Vehi_ID = vehicle.Vehi_ID AND vehicle.VehiDet_ID = vehicle_details.VehiDet_ID
GROUP BY booking.Vehi_ID
ORDER BY COUNT(booking.Vehi_ID) DESC;

/*(This query will pull the number of times each car has been booked for use by a customer. This will be helpful in figuring out what cars were the most popular, and will assist in our decision process of purchasing new fleet vehicles.)*/
END$$

DROP PROCEDURE IF EXISTS `4_unpaid_bill`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `4_unpaid_bill` ()  Begin
SELECT CONCAT(Cust_FName, ' ', Cust_LName) AS `Name`, Cust_Email AS `Customer Email`,  CONCAT(`Cust_Street`,' ', `Cust_City`) AS `Customer Address`, `Cust_State` AS `State`, `Cust_Zip` AS `Zip Code`
FROM customer, payment
WHERE Customer.Cust_ID=Payment.Cust_ID AND Pay_Status = 0;

/*(This query will return all the customers that have NOT paid their bills for the cars they rented from us. This will let us decide if we need to mail a reminder to their address to pay the bill.)*/
END$$

DROP PROCEDURE IF EXISTS `5_cust_renttime`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `5_cust_renttime` ()  Begin
SELECT cust_fname AS `Customer First Name`, cust_lname AS `Customer Last Name`,CONCAT(R.Reserv_Pickup, ' to ', R.Reserv_Dropoff) AS `Booking Dates`, DATEDIFF(R.Reserv_Dropoff, R.Reserv_Pickup) 
AS `Total Rental Time in Days` 
FROM Booking B, Reservation R, Customer C 
WHERE B.Reserv_ID = R.Reserv_ID AND R.Cust_ID = C.Cust_ID 
GROUP BY Book_ID 
ORDER BY Book_ID ASC;

/*(This query will return the total time that Each customer will be renting a particular vehicle from us. This query will be useful as we determine how much to charge each customer as the billing model is based on a charge-per-day basis, depending on the vehicle being rented.)*/
END$$

DROP PROCEDURE IF EXISTS `6_Personalized_car_budget`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `6_Personalized_car_budget` (IN `var_budget` DECIMAL(20,2))  Begin
SELECT CONCAT(vehidet_year, ' ',Vehidet_Make, ' ', vehidet_model) AS `Car Name`, CONCAT("$", FORMAT(VehiDet_Perday, 2)) AS `Daily Rental Cost`
FROM vehicle_details 
WHERE VehiDet_Perday <= var_budget
ORDER BY vehidet_make;

/* this query will ask for a dollar value from the customer, and the customer can input a value to see if there are cars at or below that budget. this can be useful for us as we can implement this query into our webpage in a 'car finder' based on budgets */

END$$

DROP PROCEDURE IF EXISTS `7_customer_state`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `7_customer_state` ()  Begin
SELECT DISTINCT Cust_State AS `Customer State`, COUNT(Cust_ID) AS `Total Customers From Each State`
FROM Customer
GROUP BY Cust_State
ORDER BY Cust_State ASC;

/*(This query will count the number of customers that our company serves from each state, AKA from what state do the majority of our customers come from. This will be useful if our company decides to expand, we can aim to start new franchises in the more popular states.)*/
END$$

DROP PROCEDURE IF EXISTS `8_September_rentals`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `8_September_rentals` ()  Begin
SELECT `VehiDet_Make` AS `Vehicle Make`, `VehiDet_Model` AS `Vehicle Model`, `VehiDet_Year` AS `Vehicle Year`
FROM reservation, vehicle_details, vehicle
WHERE reservation.Vehi_ID=vehicle.Vehi_ID AND vehicle.VehiDet_ID=vehicle_details.VehiDet_ID AND
Reserv_Pickup <= '2019-09-30' AND Reserv_Pickup >= '2019-09-01';

/*(This query will return a list of cars and their details that were rented out in the month of September. This will assist us in making sure that the cars that were rented out can be scheduled for maintenance upon return to help the cars last longer.) */
END$$

DROP PROCEDURE IF EXISTS `9_October_billing`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `9_October_billing` ()  Begin
SELECT reservation.Reserv_Dropoff AS `Reservation Dropoff Date`, CONCAT('$', billing.Bill_Total) AS `Total Bill`
FROM reservation, billing, booking
WHERE reservation.Reserv_ID = booking.Reserv_ID AND booking.Book_ID = billing.Book_ID AND (DATE(reservation.Reserv_Dropoff)) BETWEEN '2019-10-01' AND '2019-10-31'
GROUP BY reservation.Reserv_Pickup;

/*(This query will return a list of the bills that were made during the Month of October. This can assist the company during our monthly profit analysis as well as making sure with other queries that the customer has indeed paid off their bill.)*/
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `agent`
--

DROP TABLE IF EXISTS `agent`;
CREATE TABLE IF NOT EXISTS `agent` (
  `Agent_ID` int(11) NOT NULL,
  `Agent_FName` varchar(50) DEFAULT NULL,
  `Agent_LName` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`Agent_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `agent`
--

INSERT INTO `agent` (`Agent_ID`, `Agent_FName`, `Agent_LName`) VALUES
(1, 'Jesse', 'Knox'),
(2, 'Octavia', 'Bohan'),
(3, 'Herby', 'Spence'),
(4, 'Mimi', 'Bortolotti'),
(5, 'Shanie', 'Tuiller');

-- --------------------------------------------------------

--
-- Table structure for table `billing`
--

DROP TABLE IF EXISTS `billing`;
CREATE TABLE IF NOT EXISTS `billing` (
  `Bill_ID` int(11) NOT NULL,
  `Bill_Total` decimal(19,2) DEFAULT NULL,
  `Book_ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Bill_ID`),
  KEY `Book_ID` (`Book_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `billing`
--

INSERT INTO `billing` (`Bill_ID`, `Bill_Total`, `Book_ID`) VALUES
(1, '405.65', 1),
(2, '109.34', 2),
(3, '208.63', 3),
(4, '311.94', 4),
(5, '395.28', 5),
(6, '134.44', 6),
(7, '428.00', 7),
(8, '454.42', 8),
(9, '219.83', 9),
(10, '201.60', 10),
(11, '227.48', 11),
(12, '231.97', 12),
(13, '243.66', 13),
(14, '176.76', 14),
(15, '152.57', 15),
(16, '168.13', 16),
(17, '498.05', 17),
(18, '315.07', 18),
(19, '127.85', 19),
(20, '436.80', 20);

-- --------------------------------------------------------

--
-- Table structure for table `booking`
--

DROP TABLE IF EXISTS `booking`;
CREATE TABLE IF NOT EXISTS `booking` (
  `Book_ID` int(11) NOT NULL,
  `Book_Deposit` decimal(19,2) DEFAULT NULL,
  `Reserv_ID` int(11) DEFAULT NULL,
  `Agent_ID` int(11) DEFAULT NULL,
  `Vehi_ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Book_ID`),
  KEY `Reserv_ID` (`Reserv_ID`),
  KEY `Agent_ID` (`Agent_ID`),
  KEY `Vehi_ID` (`Vehi_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `booking`
--

INSERT INTO `booking` (`Book_ID`, `Book_Deposit`, `Reserv_ID`, `Agent_ID`, `Vehi_ID`) VALUES
(1, '123.05', 1, 1, 1),
(2, '186.25', 2, 2, 2),
(3, '280.48', 3, 2, 3),
(4, '104.33', 4, 4, 4),
(5, '290.33', 5, 5, 5),
(6, '99.06', 6, 2, 6),
(7, '80.65', 7, 4, 7),
(8, '142.59', 8, 2, 8),
(9, '67.70', 9, 2, 9),
(10, '313.85', 10, 1, 10),
(11, '120.27', 11, 1, 3),
(12, '401.27', 12, 2, 12),
(13, '159.66', 13, 5, 13),
(14, '467.50', 14, 4, 7),
(15, '301.11', 15, 2, 11),
(16, '356.17', 16, 5, 1),
(17, '268.74', 17, 4, 2),
(18, '59.91', 18, 2, 3),
(19, '494.22', 19, 1, 7),
(20, '467.36', 20, 1, 7);

--
-- Triggers `booking`
--
DROP TRIGGER IF EXISTS `Vehi_Availability`;
DELIMITER $$
CREATE TRIGGER `Vehi_Availability` AFTER INSERT ON `booking` FOR EACH ROW BEGIN 
UPDATE vehicle SET vehicle.Vehi_Availability = 0 WHERE vehicle.Vehi_ID = NEW.vehi_ID; 
/* this trigger will auto update the vehicle's availability whenever a new customer books it and the vehicle is on lot. */
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `compact`
--

DROP TABLE IF EXISTS `compact`;
CREATE TABLE IF NOT EXISTS `compact` (
  `Compact_ID` int(11) NOT NULL,
  `Vehi_ID` int(11) NOT NULL,
  `Compact_mileagePerGallon` int(15) NOT NULL,
  PRIMARY KEY (`Compact_ID`),
  KEY `VehiDet_ID` (`Vehi_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `compact`
--

INSERT INTO `compact` (`Compact_ID`, `Vehi_ID`, `Compact_mileagePerGallon`) VALUES
(1, 8, 25),
(2, 6, 22),
(3, 10, 23),
(4, 12, 32),
(5, 3, 33);

-- --------------------------------------------------------

--
-- Table structure for table `customer`
--

DROP TABLE IF EXISTS `customer`;
CREATE TABLE IF NOT EXISTS `customer` (
  `Cust_ID` int(11) NOT NULL,
  `Cust_Fname` varchar(50) DEFAULT NULL,
  `Cust_Lname` varchar(50) DEFAULT NULL,
  `Cust_Email` varchar(50) DEFAULT NULL,
  `Cust_Phone` varchar(50) DEFAULT NULL,
  `Cust_LicenseNum` varchar(50) DEFAULT NULL,
  `Cust_Street` varchar(50) DEFAULT NULL,
  `Cust_City` varchar(50) DEFAULT NULL,
  `Cust_State` varchar(50) DEFAULT NULL,
  `Cust_Zip` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`Cust_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `customer`
--

INSERT INTO `customer` (`Cust_ID`, `Cust_Fname`, `Cust_Lname`, `Cust_Email`, `Cust_Phone`, `Cust_LicenseNum`, `Cust_Street`, `Cust_City`, `Cust_State`, `Cust_Zip`) VALUES
(1, 'Alice', 'Dimblebee', 'adimblebee0@csmonitor.com', '601-417-6920', 'Ar07vcTsnw', '832 Randy Trail', 'Jackson', 'Mississippi', '39236'),
(2, 'Tawnya', 'Schade', 'tschade1@jigsy.com', '205-220-2474', 'f2e1Hg45gk', '270 Main Junction', 'Birmingham', 'Alabama', '35263'),
(3, 'Hebert', 'Corless', 'hcorless2@360.cn', '571-846-4655', 'FLp5IL', '77154 Truax Terrace', 'Ashburn', 'Virginia', '22093'),
(4, 'Chris', 'Turley', 'cturley3@twitpic.com', '816-953-3328', 'BOAOO2', '093 Tennyson Parkway', 'Kansas City', 'Missouri', '64142'),
(5, 'Chelsea', 'Goodday', 'cgoodday4@cnbc.com', '949-348-3539', 'smiw8D', '09 Mcguire Trail', 'Huntington Beach', 'California', '92648'),
(6, 'Kris', 'Billington', 'kbillington5@pen.io', '254-888-8429', 'NbqRWdPh', '3 Monica Place', 'Gatesville', 'Texas', '76598'),
(7, 'Bernette', 'Chelley', 'bchelley6@vkontakte.ru', '303-276-9852', 'WOJF2EHF7vN', '75 Barby Parkway', 'Aurora', 'Colorado', '80044'),
(8, 'Kiersten', 'Hatliff', 'khatliff7@wufoo.com', '916-323-3477', 'OO6x5OeYNYB', '6379 Lunder Terrace', 'Sacramento', 'California', '94207'),
(9, 'Gabby', 'Southgate', 'gsouthgate8@lycos.com', '304-871-6060', 'uJM2PbY', '525 Arrowood Trail', 'Huntington', 'West Virginia', '25705'),
(10, 'Wynn', 'Lundy', 'wlundy9@chicagotribune.com', '831-219-3949', 'Et5IPD', '9866 Paget Way', 'Santa Cruz', 'California', '95064'),
(11, 'Packston', 'Carrington', 'pcarringtona@sohu.com', '317-243-4594', '6Ae4Hgq06', '626 Waxwing Park', 'Indianapolis', 'Indiana', '46226'),
(12, 'Rosita', 'Rookes', 'rrookesb@liveinternet.ru', '573-882-2917', 'FIgJKD', '83908 Pleasure Street', 'Jefferson City', 'Missouri', '65105'),
(13, 'Fidelio', 'Stable', 'fstablec@wordpress.com', '571-457-6753', 'CULD2LJg', '7472 Briar Crest Court', 'Arlington', 'Virginia', '22234'),
(14, 'Franny', 'Kupper', 'fkupperd@cocolog-nifty.com', '213-502-5820', 'OcfGqbUie3', '271 Crowley Drive', 'Los Angeles', 'California', '90065'),
(15, 'Zulema', 'Babinski', 'zbabinskie@nyu.edu', '510-760-2635', 'gNTbeBsHmV', '4519 Dayton Junction', 'Oakland', 'California', '94605'),
(16, 'Zelma', 'Shynn', 'zshynnf@mozilla.org', '215-181-6400', 'byCJgNfhYM', '1411 Rutledge Court', 'Philadelphia', 'Pennsylvania', '19131'),
(17, 'Lonnie', 'Nuton', 'lnutong@tripadvisor.com', '952-820-5349', '2lnAhd5Ty307', '50 Bay Terrace', 'Minneapolis', 'Minnesota', '55441'),
(18, 'Ava', 'Arnoud', 'aarnoudh@sourceforge.net', '212-290-7054', 'AHjwRML', '10 Mifflin Place', 'Brooklyn', 'New York', '11254'),
(19, 'Eugenie', 'Treffry', 'etreffryi@nationalgeographic.com', '360-670-6455', 'b45pxL', '04498 Summerview Road', 'Seattle', 'Washington', '98158'),
(20, 'Merrili', 'Darridon', 'mdarridonj@dailymotion.com', '336-169-3578', 'wvc7jc2JMWeF', '4283 Lukken Plaza', 'Greensboro', 'North Carolina', '27499');

-- --------------------------------------------------------

--
-- Table structure for table `payment`
--

DROP TABLE IF EXISTS `payment`;
CREATE TABLE IF NOT EXISTS `payment` (
  `Pay_ID` int(11) NOT NULL,
  `Pay_Total` decimal(19,2) DEFAULT NULL,
  `Pay_Status` varchar(50) DEFAULT NULL,
  `Cust_ID` int(11) DEFAULT NULL,
  `Bill_ID` int(11) DEFAULT NULL,
  PRIMARY KEY (`Pay_ID`),
  KEY `Cust_ID` (`Cust_ID`),
  KEY `Bill_ID` (`Bill_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `payment`
--

INSERT INTO `payment` (`Pay_ID`, `Pay_Total`, `Pay_Status`, `Cust_ID`, `Bill_ID`) VALUES
(1, '363.72', '1', 1, 1),
(2, '382.72', '0', 2, 2),
(3, '114.42', '0', 3, 3),
(4, '406.18', '1', 4, 4),
(5, '284.94', '0', 5, 5),
(6, '234.88', '0', 6, 6),
(7, '112.41', '1', 7, 7),
(8, '261.00', '1', 8, 8),
(9, '464.76', '0', 9, 9),
(10, '412.81', '0', 10, 10),
(11, '82.98', '1', 11, 11),
(12, '302.79', '1', 12, 12),
(13, '155.90', '1', 13, 13),
(14, '159.48', '0', 14, 14),
(15, '233.41', '1', 15, 15),
(16, '115.69', '0', 16, 16),
(17, '422.70', '1', 17, 17),
(18, '130.09', '0', 18, 18),
(19, '205.99', '1', 19, 19),
(20, '418.75', '1', 20, 20);

-- --------------------------------------------------------

--
-- Table structure for table `reservation`
--

DROP TABLE IF EXISTS `reservation`;
CREATE TABLE IF NOT EXISTS `reservation` (
  `Reserv_ID` int(11) NOT NULL,
  `Reserv_Pickup` date DEFAULT NULL,
  `Reserv_Dropoff` date DEFAULT NULL,
  `Reserv_hadaccident` int(11) NOT NULL,
  `Cust_ID` int(11) DEFAULT NULL,
  `Vehi_ID` int(255) NOT NULL,
  PRIMARY KEY (`Reserv_ID`),
  KEY `Cust_ID` (`Cust_ID`),
  KEY `Vehi_ID` (`Vehi_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `reservation`
--

INSERT INTO `reservation` (`Reserv_ID`, `Reserv_Pickup`, `Reserv_Dropoff`, `Reserv_hadaccident`, `Cust_ID`, `Vehi_ID`) VALUES
(1, '2019-03-05', '2019-03-21', 1, 1, 1),
(2, '2019-06-05', '2019-06-13', 0, 2, 1),
(3, '2019-11-13', '2019-11-27', 0, 3, 2),
(4, '2019-06-21', '2019-07-10', 0, 4, 2),
(5, '2019-11-14', '2019-11-30', 0, 5, 3),
(6, '2018-12-12', '2018-12-28', 0, 6, 3),
(7, '2019-07-13', '2019-07-17', 1, 7, 3),
(8, '2019-10-27', '2019-10-31', 0, 8, 4),
(9, '2019-02-06', '2019-02-15', 0, 9, 5),
(10, '2019-10-08', '2019-10-20', 0, 10, 6),
(11, '2019-11-11', '2019-11-30', 0, 11, 7),
(12, '2019-03-19', '2019-04-12', 0, 12, 7),
(13, '2019-09-15', '2019-09-30', 0, 13, 7),
(14, '2019-10-16', '2019-10-25', 0, 14, 7),
(15, '2019-08-23', '2019-09-05', 0, 15, 8),
(16, '2019-05-09', '2019-07-11', 0, 16, 9),
(17, '2019-09-09', '2019-09-14', 0, 17, 10),
(18, '2019-08-31', '2019-09-19', 0, 18, 11),
(19, '2019-04-17', '2019-07-18', 0, 19, 12),
(20, '2019-06-11', '2019-08-03', 0, 20, 13);

--
-- Triggers `reservation`
--
DROP TRIGGER IF EXISTS `car_accident`;
DELIMITER $$
CREATE TRIGGER `car_accident` AFTER UPDATE ON `reservation` FOR EACH ROW BEGIN
UPDATE booking, reservation
SET booking.Book_Deposit = booking.Book_Deposit + '300'
WHERE booking.Reserv_ID = reservation.Reserv_ID AND reservation.Reserv_hadaccident = '1';
/* this trigger will add a 300 dollar surcharge to the deposit if the customer's rented car is involved in an accident. */
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `sports`
--

DROP TABLE IF EXISTS `sports`;
CREATE TABLE IF NOT EXISTS `sports` (
  `sports_ID` int(11) NOT NULL,
  `Vehi_ID` int(11) NOT NULL,
  `Sports_topspeed` decimal(25,2) NOT NULL,
  PRIMARY KEY (`sports_ID`),
  KEY `VehiDet_ID` (`Vehi_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `sports`
--

INSERT INTO `sports` (`sports_ID`, `Vehi_ID`, `Sports_topspeed`) VALUES
(1, 5, '118.00'),
(2, 7, '177.10'),
(3, 9, '170.00'),
(4, 11, '137.00'),
(5, 13, '155.00');

-- --------------------------------------------------------

--
-- Table structure for table `suv`
--

DROP TABLE IF EXISTS `suv`;
CREATE TABLE IF NOT EXISTS `suv` (
  `SUV_ID` int(11) NOT NULL,
  `Vehi_ID` int(11) NOT NULL,
  `SUV_Trunksize` decimal(13,2) NOT NULL,
  PRIMARY KEY (`SUV_ID`),
  KEY `VehiDet_ID` (`Vehi_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `suv`
--

INSERT INTO `suv` (`SUV_ID`, `Vehi_ID`, `SUV_Trunksize`) VALUES
(1, 4, '12.00'),
(2, 14, '16.00'),
(3, 15, '13.60'),
(4, 1, '26.10'),
(5, 2, '9.10');

-- --------------------------------------------------------

--
-- Table structure for table `vehicle`
--

DROP TABLE IF EXISTS `vehicle`;
CREATE TABLE IF NOT EXISTS `vehicle` (
  `Vehi_ID` int(11) NOT NULL,
  `VehiDet_ID` int(11) DEFAULT NULL,
  `Vehi_Availability` varchar(50) DEFAULT NULL,
  `Vehi_Registration` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`Vehi_ID`),
  KEY `VehiDet_ID` (`VehiDet_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `vehicle`
--

INSERT INTO `vehicle` (`Vehi_ID`, `VehiDet_ID`, `Vehi_Availability`, `Vehi_Registration`) VALUES
(1, 1, '1', 'SALFR2BN8AH456697'),
(2, 2, '0', '1HGCR6F58FA265360'),
(3, 3, '0', 'WBASP2C58CC157881'),
(4, 4, '1', '3GTU1YEJ1BG363579'),
(5, 5, '1', '3C6JD6DT3CG089795'),
(6, 6, '1', '1D4PT7GX5BW390789'),
(7, 7, '1', 'WAUHF98P48A974493'),
(8, 8, '1', 'WBAGL63452D561598'),
(9, 9, '1', '19UUA65566A853254'),
(10, 10, '0', 'WAUXF78K99A740372'),
(11, 11, '1', '1G6KF57915U800804'),
(12, 12, '1', 'WBAFU9C59BC160905'),
(13, 13, '1', 'WAUTFAFH3AN659657'),
(14, 14, '1', '1NBG5783FHEI45MCS'),
(15, 15, '1', '8NB5408GFRWELOY952');

-- --------------------------------------------------------

--
-- Table structure for table `vehicle_details`
--

DROP TABLE IF EXISTS `vehicle_details`;
CREATE TABLE IF NOT EXISTS `vehicle_details` (
  `VehiDet_ID` int(11) NOT NULL,
  `VehiDet_Make` varchar(50) DEFAULT NULL,
  `VehiDet_Model` varchar(50) DEFAULT NULL,
  `VehiDet_Year` varchar(50) DEFAULT NULL,
  `VehiDet_Type` varchar(50) DEFAULT NULL,
  `VehiDet_PerDay` decimal(19,2) DEFAULT NULL,
  PRIMARY KEY (`VehiDet_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `vehicle_details`
--

INSERT INTO `vehicle_details` (`VehiDet_ID`, `VehiDet_Make`, `VehiDet_Model`, `VehiDet_Year`, `VehiDet_Type`, `VehiDet_PerDay`) VALUES
(1, 'Jeep', 'Liberty', '2010', '#795', '15.00'),
(2, 'Lexus', 'LX', '2011', '#496', '20.00'),
(3, 'Pontiac', 'LeMans', '1991', '#548', '12.00'),
(4, 'Volkswagen', 'Tiguan', '2007', '#dea', '17.00'),
(5, 'Mazda', 'MX-5', '1993', '#277', '16.00'),
(6, 'Volvo', 'C70', '2003', '#c86', '20.00'),
(7, 'Mercedes', 'AMG GT-4', '2018', '#17a', '25.00'),
(8, 'Mazda', 'Mazda6', '2003', '#073', '17.00'),
(9, 'Ford', 'Focus RS', '2016', '#0a3', '20.00'),
(10, 'Subaru', 'Legacy', '1999', '#21c', '13.00'),
(11, 'Honda', 'Civic Si', '2007', '#0bc', '20.00'),
(12, 'Mazda', 'Mazda3', '2019', '#4f5', '15.00'),
(13, 'Volkswagen', 'GTI', '2003', '#dad', '18.00'),
(14, 'Honda', 'Pilot', '2013', '#45h', '21.00'),
(15, 'Toyota', 'Highlander', '2012', '#hf5', '20.00');

--
-- Constraints for dumped tables
--

--
-- Constraints for table `billing`
--
ALTER TABLE `billing`
  ADD CONSTRAINT `billing_ibfk_1` FOREIGN KEY (`Book_ID`) REFERENCES `booking` (`Book_ID`);

--
-- Constraints for table `booking`
--
ALTER TABLE `booking`
  ADD CONSTRAINT `booking_ibfk_1` FOREIGN KEY (`Agent_ID`) REFERENCES `agent` (`Agent_ID`),
  ADD CONSTRAINT `booking_ibfk_2` FOREIGN KEY (`Reserv_ID`) REFERENCES `reservation` (`Reserv_ID`),
  ADD CONSTRAINT `booking_ibfk_3` FOREIGN KEY (`Vehi_ID`) REFERENCES `vehicle` (`Vehi_ID`);

--
-- Constraints for table `compact`
--
ALTER TABLE `compact`
  ADD CONSTRAINT `compact_ibfk_1` FOREIGN KEY (`Vehi_ID`) REFERENCES `vehicle` (`Vehi_ID`);

--
-- Constraints for table `payment`
--
ALTER TABLE `payment`
  ADD CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`Cust_ID`) REFERENCES `customer` (`Cust_ID`),
  ADD CONSTRAINT `payment_ibfk_2` FOREIGN KEY (`Bill_ID`) REFERENCES `billing` (`Bill_ID`);

--
-- Constraints for table `reservation`
--
ALTER TABLE `reservation`
  ADD CONSTRAINT `reservation_ibfk_1` FOREIGN KEY (`Cust_ID`) REFERENCES `customer` (`Cust_ID`),
  ADD CONSTRAINT `reservation_ibfk_2` FOREIGN KEY (`Vehi_ID`) REFERENCES `vehicle` (`Vehi_ID`);

--
-- Constraints for table `sports`
--
ALTER TABLE `sports`
  ADD CONSTRAINT `sports_ibfk_1` FOREIGN KEY (`Vehi_ID`) REFERENCES `vehicle` (`Vehi_ID`);

--
-- Constraints for table `suv`
--
ALTER TABLE `suv`
  ADD CONSTRAINT `suv_ibfk_1` FOREIGN KEY (`Vehi_ID`) REFERENCES `vehicle` (`Vehi_ID`);

--
-- Constraints for table `vehicle`
--
ALTER TABLE `vehicle`
  ADD CONSTRAINT `vehicle_ibfk_1` FOREIGN KEY (`VehiDet_ID`) REFERENCES `vehicle_details` (`VehiDet_ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
