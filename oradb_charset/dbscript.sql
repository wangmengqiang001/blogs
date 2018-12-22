CREATE TABLESPACE iscu DATAFILE '/u01/app/oracle/oradata/XE/owndb.dbf' size 100M autoextend on next 20M maxsize unlimited;

CREATE USER iscu IDENTIFIED BY iscu DEFAULT TABLESPACE iscu;

--
GRANT CONNECT,RESOURCE,CREATE VIEW  TO iscu;

CONN iscu/iscu;


create table ISCU_ACCOUNT
(
  id           VARCHAR2(32) not null,
  username      VARCHAR2(32),
  isavaliable  INTEGER
)
;
alter table ISCU_ACCOUNT
  add constraint PK_ISC_ACCOUNT primary key (ID);

INSERT INTO ISCU_ACCOUNT values('12345678901234567890','一二三四五六七八九十一二三四五六',10);
