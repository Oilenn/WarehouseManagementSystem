CREATE TABLE dbo.UnitsOfMeasure
(
    UnitId int IDENTITY(1, 1) NOT NULL,
    Code nvarchar(16) NOT NULL,
    Name nvarchar(50) NOT NULL,

    CONSTRAINT PK_UnitsOfMeasure PRIMARY KEY CLUSTERED (UnitId),
    CONSTRAINT UQ_UnitsOfMeasure_Code UNIQUE (Code),
    CONSTRAINT CK_UnitsOfMeasure_Code CHECK (LEN(TRIM(Code)) > 0),
    CONSTRAINT CK_UnitsOfMeasure_Name CHECK (LEN(TRIM(Name)) > 0)
);

CREATE TABLE dbo.Products
(
    ProductId int IDENTITY(1, 1) NOT NULL,
    Sku nvarchar(64) NOT NULL,
    Name nvarchar(200) NOT NULL,
    Description nvarchar(1000) NULL,
    UnitId int NOT NULL,
    IsActive bit NOT NULL CONSTRAINT DF_Products_IsActive DEFAULT (1),

    CONSTRAINT PK_Products PRIMARY KEY CLUSTERED (ProductId),
    CONSTRAINT UQ_Products_Sku UNIQUE (Sku),
    CONSTRAINT FK_Products_Unit FOREIGN KEY (UnitId) REFERENCES dbo.UnitsOfMeasure (UnitId),
    CONSTRAINT CK_Products_Sku CHECK (LEN(TRIM(Sku)) > 0),
    CONSTRAINT CK_Products_Name CHECK (LEN(TRIM(Name)) > 0)
);

CREATE TABLE dbo.Warehouses
(
    WarehouseId int IDENTITY(1, 1) NOT NULL,
    Code nvarchar(32) NOT NULL,
    Name nvarchar(100) NOT NULL,
    Address nvarchar(500) NULL,
    IsActive bit NOT NULL CONSTRAINT DF_Warehouses_IsActive DEFAULT (1),

    CONSTRAINT PK_Warehouses PRIMARY KEY CLUSTERED (WarehouseId),
    CONSTRAINT UQ_Warehouses_Code UNIQUE (Code),
    CONSTRAINT CK_Warehouses_Code CHECK (LEN(TRIM(Code)) > 0),
    CONSTRAINT CK_Warehouses_Name CHECK (LEN(TRIM(Name)) > 0)
);

CREATE TABLE dbo.Suppliers
(
    SupplierId int IDENTITY(1, 1) NOT NULL,
    Code nvarchar(32) NOT NULL,
    Name nvarchar(200) NOT NULL,
    IsActive bit NOT NULL CONSTRAINT DF_Suppliers_IsActive DEFAULT (1),

    CONSTRAINT PK_Suppliers PRIMARY KEY CLUSTERED (SupplierId),
    CONSTRAINT UQ_Suppliers_Code UNIQUE (Code),
    CONSTRAINT CK_Suppliers_Code CHECK (LEN(TRIM(Code)) > 0),
    CONSTRAINT CK_Suppliers_Name CHECK (LEN(TRIM(Name)) > 0)
);

CREATE TABLE dbo.StockBalances
(
    WarehouseId int NOT NULL,
    ProductId int NOT NULL,
    Quantity decimal(18, 3) NOT NULL CONSTRAINT DF_StockBalances_Quantity DEFAULT (0),
    Version rowversion NOT NULL,

    CONSTRAINT PK_StockBalances PRIMARY KEY CLUSTERED (WarehouseId, ProductId),
    CONSTRAINT FK_StockBalances_Warehouse FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses (WarehouseId),
    CONSTRAINT FK_StockBalances_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
    CONSTRAINT CK_StockBalances_Quantity CHECK (Quantity >= 0)
);

CREATE TABLE dbo.Receipts
(
    ReceiptId bigint IDENTITY(1, 1) NOT NULL,
    DocumentNumber nvarchar(50) NOT NULL,
    SupplierId int NOT NULL,
    WarehouseId int NOT NULL,
    ReceivedAtUtc datetime2(7) NOT NULL CONSTRAINT DF_Receipts_ReceivedAtUtc DEFAULT (SYSUTCDATETIME()),
    Note nvarchar(1000) NULL,

    CONSTRAINT PK_Receipts PRIMARY KEY CLUSTERED (ReceiptId),
    CONSTRAINT UQ_Receipts_DocumentNumber UNIQUE (DocumentNumber),
    CONSTRAINT FK_Receipts_Supplier FOREIGN KEY (SupplierId) REFERENCES dbo.Suppliers (SupplierId),
    CONSTRAINT FK_Receipts_Warehouse FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses (WarehouseId),
    CONSTRAINT CK_Receipts_DocumentNumber CHECK (LEN(TRIM(DocumentNumber)) > 0)
);

CREATE TABLE dbo.ReceiptItems
(
    ReceiptId bigint NOT NULL,
    ProductId int NOT NULL,
    Quantity decimal(18, 3) NOT NULL,

    CONSTRAINT PK_ReceiptItems PRIMARY KEY CLUSTERED (ReceiptId, ProductId),
    CONSTRAINT FK_ReceiptItems_Receipt FOREIGN KEY (ReceiptId) REFERENCES dbo.Receipts (ReceiptId),
    CONSTRAINT FK_ReceiptItems_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
    CONSTRAINT CK_ReceiptItems_Quantity CHECK (Quantity > 0)
);

CREATE TABLE dbo.WriteOffs
(
    WriteOffId bigint IDENTITY(1, 1) NOT NULL,
    DocumentNumber nvarchar(50) NOT NULL,
    WarehouseId int NOT NULL,
    WrittenOffAtUtc datetime2(7) NOT NULL CONSTRAINT DF_WriteOffs_WrittenOffAtUtc DEFAULT (SYSUTCDATETIME()),
    Reason nvarchar(500) NOT NULL,

    CONSTRAINT PK_WriteOffs PRIMARY KEY CLUSTERED (WriteOffId),
    CONSTRAINT UQ_WriteOffs_DocumentNumber UNIQUE (DocumentNumber),
    CONSTRAINT FK_WriteOffs_Warehouse FOREIGN KEY (WarehouseId) REFERENCES dbo.Warehouses (WarehouseId),
    CONSTRAINT CK_WriteOffs_DocumentNumber CHECK (LEN(TRIM(DocumentNumber)) > 0),
    CONSTRAINT CK_WriteOffs_Reason CHECK (LEN(TRIM(Reason)) > 0)
);

CREATE TABLE dbo.WriteOffItems
(
    WriteOffId bigint NOT NULL,
    ProductId int NOT NULL,
    Quantity decimal(18, 3) NOT NULL,

    CONSTRAINT PK_WriteOffItems PRIMARY KEY CLUSTERED (WriteOffId, ProductId),
    CONSTRAINT FK_WriteOffItems_WriteOff FOREIGN KEY (WriteOffId) REFERENCES dbo.WriteOffs (WriteOffId),
    CONSTRAINT FK_WriteOffItems_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
    CONSTRAINT CK_WriteOffItems_Quantity CHECK (Quantity > 0)
);

CREATE TABLE dbo.Transfers
(
    TransferId bigint IDENTITY(1, 1) NOT NULL,
    DocumentNumber nvarchar(50) NOT NULL,
    SourceWarehouseId int NOT NULL,
    DestinationWarehouseId int NOT NULL,
    TransferredAtUtc datetime2(7) NOT NULL CONSTRAINT DF_Transfers_TransferredAtUtc DEFAULT (SYSUTCDATETIME()),
    Note nvarchar(1000) NULL,

    CONSTRAINT PK_Transfers PRIMARY KEY CLUSTERED (TransferId),
    CONSTRAINT UQ_Transfers_DocumentNumber UNIQUE (DocumentNumber),
    CONSTRAINT FK_Transfers_SourceWarehouse FOREIGN KEY (SourceWarehouseId) REFERENCES dbo.Warehouses (WarehouseId),
    CONSTRAINT FK_Transfers_DestinationWarehouse FOREIGN KEY (DestinationWarehouseId) REFERENCES dbo.Warehouses (WarehouseId),
    CONSTRAINT CK_Transfers_DocumentNumber CHECK (LEN(TRIM(DocumentNumber)) > 0),
    CONSTRAINT CK_Transfers_DifferentWarehouses CHECK (SourceWarehouseId <> DestinationWarehouseId)
);

CREATE TABLE dbo.TransferItems
(
    TransferId bigint NOT NULL,
    ProductId int NOT NULL,
    Quantity decimal(18, 3) NOT NULL,

    CONSTRAINT PK_TransferItems PRIMARY KEY CLUSTERED (TransferId, ProductId),
    CONSTRAINT FK_TransferItems_Transfer FOREIGN KEY (TransferId) REFERENCES dbo.Transfers (TransferId),
    CONSTRAINT FK_TransferItems_Product FOREIGN KEY (ProductId) REFERENCES dbo.Products (ProductId),
    CONSTRAINT CK_TransferItems_Quantity CHECK (Quantity > 0)
);

CREATE INDEX IX_Products_UnitId
    ON dbo.Products (UnitId);

CREATE INDEX IX_StockBalances_Product_Warehouse
    ON dbo.StockBalances (ProductId, WarehouseId)
    INCLUDE (Quantity);

CREATE INDEX IX_Receipts_Warehouse_ReceivedAtUtc
    ON dbo.Receipts (WarehouseId, ReceivedAtUtc DESC, ReceiptId DESC)
    INCLUDE (SupplierId);

CREATE INDEX IX_Receipts_Supplier_ReceivedAtUtc
    ON dbo.Receipts (SupplierId, ReceivedAtUtc DESC, ReceiptId DESC)
    INCLUDE (WarehouseId);

CREATE INDEX IX_ReceiptItems_Product_Receipt
    ON dbo.ReceiptItems (ProductId, ReceiptId)
    INCLUDE (Quantity);

CREATE INDEX IX_WriteOffs_Warehouse_WrittenOffAtUtc
    ON dbo.WriteOffs (WarehouseId, WrittenOffAtUtc DESC, WriteOffId DESC);

CREATE INDEX IX_WriteOffItems_Product_WriteOff
    ON dbo.WriteOffItems (ProductId, WriteOffId)
    INCLUDE (Quantity);

CREATE INDEX IX_Transfers_SourceWarehouse_TransferredAtUtc
    ON dbo.Transfers (SourceWarehouseId, TransferredAtUtc DESC, TransferId DESC)
    INCLUDE (DestinationWarehouseId);

CREATE INDEX IX_Transfers_DestinationWarehouse_TransferredAtUtc
    ON dbo.Transfers (DestinationWarehouseId, TransferredAtUtc DESC, TransferId DESC)
    INCLUDE (SourceWarehouseId);

CREATE INDEX IX_TransferItems_Product_Transfer
    ON dbo.TransferItems (ProductId, TransferId)
    INCLUDE (Quantity);
