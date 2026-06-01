----------------------------------------
-- 01) DACS-2767 - Qualify Insert Modifiers into table [MODIFIER].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF (SELECT COUNT(*) FROM MODIFIER WHERE [MODIFIER_CD] = 'SH') <= 0
	INSERT INTO MODIFIER ([MODIFIER_CD],[DESCRIPTION]) VALUES ('SH','Accident Scene to Hospital');
ELSE
	PRINT('SH Modifier already exists.  Skipping insert');

IF (SELECT COUNT(*) FROM MODIFIER WHERE [MODIFIER_CD] = 'RH') <= 0
	INSERT INTO MODIFIER ([MODIFIER_CD],[DESCRIPTION]) VALUES ('RH','Residence to Hospital');
ELSE
	PRINT('RH Modifier already exists.  Skipping insert');

IF (SELECT COUNT(*) FROM MODIFIER WHERE [MODIFIER_CD] = 'EH') <= 0
	INSERT INTO MODIFIER ([MODIFIER_CD],[DESCRIPTION]) VALUES ('EH','Nursing Home to Hospital');
ELSE
	PRINT('EH Modifier already exists.  Skipping insert');

IF (SELECT COUNT(*) FROM MODIFIER WHERE [MODIFIER_CD] = 'NH') <= 0
	INSERT INTO MODIFIER ([MODIFIER_CD],[DESCRIPTION]) VALUES ('NH','Skilled Nursing to Hospital');
ELSE
	PRINT('NH Modifier already exists.  Skipping insert');

IF (SELECT COUNT(*) FROM MODIFIER WHERE [MODIFIER_CD] = 'GM') <= 0
	INSERT INTO MODIFIER ([MODIFIER_CD],[DESCRIPTION]) VALUES ('GM','Multiple Patients in transport');
ELSE
	PRINT('GM Modifier already exists.  Skipping insert');



/*
testing:
begin tran;
rollback tran;
commit tran;
SELECT DESCRIPTION, MODIFIER_CD FROM MODIFIER ORDER BY MODIFIER_CD
SELECT * FROM MODIFIER ORDER BY MODIFIER_CD
*/