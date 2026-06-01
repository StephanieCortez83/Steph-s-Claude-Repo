----------------------------------------
-- 02) DACS-2984 - Clone users for following facilities
----------------------------------------
USE [RevCycleDB]
GO
 
--Tenet 3 - ECH - East Cooper Medical Center to Tenet 3 - VEC - NEW East Cooper 
EXECUTE dbo.MAINTENANCE_CLONE_FACILITY_USER_AUTHORIZATION 1812, 2371
 
--Tenet 3 - CCD - Coastal Carolina Hospital to Tenet 3 - VCD - NEW Coastal Carolina 
EXECUTE dbo.MAINTENANCE_CLONE_FACILITY_USER_AUTHORIZATION 1811, 2373

--Tenet 3 - HHH - Hilton Head Hospital to Tenet 3 - VHI - NEW Hilton Head
EXECUTE dbo.MAINTENANCE_CLONE_FACILITY_USER_AUTHORIZATION 1813, 2372

