

--create source table 
USE master;
GO

CREATE TABLE dbo.Assets
(
    AssetID       INT NOT NULL PRIMARY KEY,
    AssetName     VARCHAR(100) NULL,
    AssetValue    DECIMAL(18,2) NULL,
    Location      VARCHAR(100) NULL,
    ModifiedDate  DATETIME NULL
);
GO
---Insert values into source table
INSERT INTO dbo.Assets (AssetID, AssetName, AssetValue, Location, ModifiedDate)
VALUES
(1, 'Laptop', 1500.00, 'Lagos Office', GETDATE()),
(2, 'Server', 5000.00, 'Data Center', GETDATE()),
(3, 'Router', 800.00, 'Head Office', GETDATE()),
(4, 'Firewall', 1200.00, 'Data Center', GETDATE()),
(5, 'Switch', 600.00, 'Branch Office', GETDATE());
GO
GO

CREATE TABLE dbo.Stage_Asset
(
    AssetID       INT NOT NULL,
    AssetName     VARCHAR(100) NULL,
    AssetValue    DECIMAL(18,2) NULL,
    Location      VARCHAR(100) NULL,
    ModifiedDate  DATETIME NULL
);
GO

---Create dbo.Dim_Asset (SCD Type 2)
GO

CREATE TABLE dbo.Dim_Asset
(
    AssetSK        INT IDENTITY(1,1) PRIMARY KEY,   -- Surrogate Key

    AssetID        INT NOT NULL,                    -- Business Key
    AssetName      VARCHAR(100) NULL,
    AssetValue     DECIMAL(18,2) NULL,
    Location       VARCHAR(100) NULL,

    EffectiveFrom  DATETIME NOT NULL DEFAULT GETDATE(),
    EffectiveTo    DATETIME NULL,
    IsCurrent      BIT NOT NULL DEFAULT 1
);
GO

----Load fresh data from source table
INSERT INTO dbo.Stage_Asset
(
    AssetID,
    AssetName,
    AssetValue,
    Location,
    ModifiedDate
)
SELECT
    AssetID,
    AssetName,
    AssetValue,
    Location,
    ModifiedDate
FROM dbo.Assets;

---FULL SCD TYPE 2 STRUCTURE (COMBINED SCRIPT)
-- 1. EXPIRE OLD RECORDS
UPDATE d
SET
    d.EffectiveTo = GETDATE(),
    d.IsCurrent = 0
FROM dbo.Dim_Asset d
JOIN dbo.Stage_Asset s
    ON d.AssetID = s.AssetID
WHERE d.IsCurrent = 1
AND (
    d.AssetName <> s.AssetName
    OR d.AssetValue <> s.AssetValue
    OR d.Location <> s.Location
);

-- 2. INSERT NEW & CHANGED RECORDS
INSERT INTO dbo.Dim_Asset
(
    AssetID,
    AssetName,
    AssetValue,
    Location,
    EffectiveFrom,
    EffectiveTo,
    IsCurrent
)
SELECT
    s.AssetID,
    s.AssetName,
    s.AssetValue,
    s.Location,
    GETDATE(),
    NULL,
    1
FROM dbo.Stage_Asset s
LEFT JOIN dbo.Dim_Asset d
    ON s.AssetID = d.AssetID
WHERE d.AssetID IS NULL
   OR d.IsCurrent = 0;