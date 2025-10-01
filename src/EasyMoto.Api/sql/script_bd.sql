-- ==============================================
-- EasyMoto - DDL + Seeds (Azure SQL)
-- Enums:
--  Usuario.Perfil: 0=OPERADOR, 1=ADMIN
--  Moto.Categoria: 0=POP, 1=SPORT, 2=E
--  Moto.StatusOperacional: 0=DISPONIVEL, 1=ALUGADA, 2=MANUTENCAO
--  Notificacao.Tipo: 0=MOTO_CADASTRADA, 1=MOTO_ATUALIZADA
--  Notificacao.Escopo: 0=GLOBAL, 1=USUARIO, 2=FILIAL
-- ==============================================

-- FILIAL
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Filial]') AND type = 'U')
BEGIN
  CREATE TABLE dbo.Filial (
    Id       INT IDENTITY(1,1) PRIMARY KEY,
    Nome     NVARCHAR(120) NOT NULL,
    Cep      CHAR(9)       NOT NULL,
    Cidade   NVARCHAR(120) NOT NULL,
    Uf       CHAR(2)       NOT NULL,
    CONSTRAINT UQ_Filial_Cep UNIQUE (Cep)
  );
END;

-- LEGENDA STATUS
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LegendaStatus]') AND type = 'U')
BEGIN
  CREATE TABLE dbo.LegendaStatus (
    Id        INT IDENTITY(1,1) PRIMARY KEY,
    Titulo    NVARCHAR(80)  NOT NULL,
    Descricao NVARCHAR(200) NULL,
    CorHex    CHAR(7)       NOT NULL, -- #RRGGBB
    Ativo     BIT           NOT NULL,
    CONSTRAINT UQ_LegendaStatus_Titulo UNIQUE (Titulo),
    CONSTRAINT CK_LegendaStatus_CorHex CHECK (CorHex LIKE '#[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]')
  );
END;

-- USUARIO
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Usuario]') AND type = 'U')
BEGIN
  CREATE TABLE dbo.Usuario (
    Id           INT IDENTITY(1,1) PRIMARY KEY,
    NomeCompleto NVARCHAR(150) NOT NULL,
    Email        NVARCHAR(160) NOT NULL,
    Telefone     NVARCHAR(20)  NULL,
    CPF          CHAR(11)      NOT NULL,
    CepFilial    CHAR(9)       NULL,
    -- A API deve gravar hash/senha de forma segura; mantemos coluna genérica:
    SenhaHash    NVARCHAR(200) NULL,
    Perfil       INT           NOT NULL, -- 0,1
    Ativo        BIT           NOT NULL,
    FilialId     INT           NOT NULL,
    CONSTRAINT FK_Usuario_Filial FOREIGN KEY (FilialId) REFERENCES dbo.Filial (Id),
    CONSTRAINT UQ_Usuario_Email UNIQUE (Email),
    CONSTRAINT UQ_Usuario_CPF   UNIQUE (CPF),
    CONSTRAINT CK_Usuario_Perfil CHECK (Perfil IN (0,1))
  );
  CREATE INDEX IX_Usuario_FilialId ON dbo.Usuario (FilialId);
END;

-- MOTO
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Moto]') AND type = 'U')
BEGIN
  CREATE TABLE dbo.Moto (
    Id                INT IDENTITY(1,1) PRIMARY KEY,
    Placa             NVARCHAR(8)   NOT NULL,
    Modelo            NVARCHAR(120) NOT NULL,
    Ano               INT           NOT NULL,
    Cor               NVARCHAR(30)  NULL,
    Ativo             BIT           NOT NULL,
    FilialId          INT           NOT NULL,
    Categoria         INT           NOT NULL, -- 0,1,2
    StatusOperacional INT           NOT NULL, -- 0,1,2
    LegendaStatusId   INT           NOT NULL,
    QrCode            NVARCHAR(50)  NULL,
    CONSTRAINT UQ_Moto_Placa UNIQUE (Placa),
    CONSTRAINT FK_Moto_Filial        FOREIGN KEY (FilialId)        REFERENCES dbo.Filial (Id),
    CONSTRAINT FK_Moto_LegendaStatus FOREIGN KEY (LegendaStatusId) REFERENCES dbo.LegendaStatus (Id),
    CONSTRAINT CK_Moto_Categoria         CHECK (Categoria IN (0,1,2)),
    CONSTRAINT CK_Moto_StatusOperacional CHECK (StatusOperacional IN (0,1,2))
  );
  CREATE INDEX IX_Moto_FilialId        ON dbo.Moto (FilialId);
  CREATE INDEX IX_Moto_LegendaStatusId ON dbo.Moto (LegendaStatusId);
END;

-- NOTIFICACAO
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Notificacao]') AND type = 'U')
BEGIN
  CREATE TABLE dbo.Notificacao (
    Id               INT IDENTITY(1,1) PRIMARY KEY,
    Tipo             INT           NOT NULL, -- 0,1
    Mensagem         NVARCHAR(200) NOT NULL,
    MotoId           INT           NULL,
    UsuarioOrigemId  INT           NOT NULL,
    Escopo           INT           NOT NULL, -- 0,1,2
    CriadaEm         DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_Notificacao_Moto    FOREIGN KEY (MotoId)          REFERENCES dbo.Moto (Id),
    CONSTRAINT FK_Notificacao_Usuario FOREIGN KEY (UsuarioOrigemId) REFERENCES dbo.Usuario (Id),
    CONSTRAINT CK_Notificacao_Tipo   CHECK (Tipo IN (0,1)),
    CONSTRAINT CK_Notificacao_Escopo CHECK (Escopo IN (0,1,2))
  );
  CREATE INDEX IX_Notificacao_MotoId          ON dbo.Notificacao (MotoId);
  CREATE INDEX IX_Notificacao_UsuarioOrigemId ON dbo.Notificacao (UsuarioOrigemId);
END;

-- NOTIFICACAO LEITURA (para /notificacoes/{id}/marcar-lida)
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NotificacaoLeitura]') AND type = 'U')
BEGIN
  CREATE TABLE dbo.NotificacaoLeitura (
    NotificacaoId INT       NOT NULL,
    UsuarioId     INT       NOT NULL,
    LidaEm        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_NotificacaoLeitura PRIMARY KEY (NotificacaoId, UsuarioId),
    CONSTRAINT FK_NotificacaoLeitura_Notificacao FOREIGN KEY (NotificacaoId) REFERENCES dbo.Notificacao (Id) ON DELETE CASCADE,
    CONSTRAINT FK_NotificacaoLeitura_Usuario     FOREIGN KEY (UsuarioId)     REFERENCES dbo.Usuario (Id)     ON DELETE CASCADE
  );
END;

-- ==============================================
-- SEEDS (idempotentes)
-- ==============================================

-- Filiais
IF NOT EXISTS (SELECT 1 FROM dbo.Filial WHERE Cep = '01001-000')
  INSERT dbo.Filial (Nome, Cep, Cidade, Uf) VALUES (N'Filial Centro', N'01001-000', N'São Paulo', N'SP');

IF NOT EXISTS (SELECT 1 FROM dbo.Filial WHERE Cep = '22070-000')
  INSERT dbo.Filial (Nome, Cep, Cidade, Uf) VALUES (N'Filial Copacabana', N'22070-000', N'Rio de Janeiro', N'RJ');

DECLARE @FilialCentroId INT  = (SELECT TOP 1 Id FROM dbo.Filial WHERE Cep = '01001-000');
DECLARE @FilialCopaId   INT  = (SELECT TOP 1 Id FROM dbo.Filial WHERE Cep = '22070-000');

-- Legendas
IF NOT EXISTS (SELECT 1 FROM dbo.LegendaStatus WHERE Titulo = N'Disponível')
  INSERT dbo.LegendaStatus (Titulo, Descricao, CorHex, Ativo) VALUES (N'Disponível', N'Moto pronta para uso', '#28A745', 1);

IF NOT EXISTS (SELECT 1 FROM dbo.LegendaStatus WHERE Titulo = N'Manutenção')
  INSERT dbo.LegendaStatus (Titulo, Descricao, CorHex, Ativo) VALUES (N'Manutenção', N'Moto em manutenção preventiva/corretiva', '#FFC107', 1);

DECLARE @LegendaDisponivelId  INT = (SELECT TOP 1 Id FROM dbo.LegendaStatus WHERE Titulo = N'Disponível');
DECLARE @LegendaManutencaoId  INT = (SELECT TOP 1 Id FROM dbo.LegendaStatus WHERE Titulo = N'Manutenção');

-- Usuarios
IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Email = N'ana.operadora@example.com')
  INSERT dbo.Usuario (NomeCompleto, Email, Telefone, CPF, CepFilial, Perfil, Ativo, FilialId, SenhaHash)
  VALUES (N'Ana Operadora', N'ana.operadora@example.com', N'11 99999-9999', '12345678909', '01001-000', 0, 1, @FilialCentroId, NULL);

IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE Email = N'bruno.admin@example.com')
  INSERT dbo.Usuario (NomeCompleto, Email, Telefone, CPF, CepFilial, Perfil, Ativo, FilialId, SenhaHash)
  VALUES (N'Bruno Admin', N'bruno.admin@example.com', N'21 98888-7777', '98765432100', '22070-000', 1, 1, @FilialCopaId, NULL);

DECLARE @UsuarioAnaId   INT = (SELECT TOP 1 Id FROM dbo.Usuario WHERE Email = N'ana.operadora@example.com');
DECLARE @UsuarioBrunoId INT = (SELECT TOP 1 Id FROM dbo.Usuario WHERE Email = N'bruno.admin@example.com');

-- Motos
IF NOT EXISTS (SELECT 1 FROM dbo.Moto WHERE Placa = N'ABC1D23')
  INSERT dbo.Moto (Placa, Modelo, Ano, Cor, Ativo, FilialId, Categoria, StatusOperacional, LegendaStatusId, QrCode)
  VALUES (N'ABC1D23', N'Honda CG 160 Fan', 2022, N'Preta', 1, @FilialCentroId, 0, 0, @LegendaManutencaoId, N'MOTO-ABC1D23');

IF NOT EXISTS (SELECT 1 FROM dbo.Moto WHERE Placa = N'XYZ9Z99')
  INSERT dbo.Moto (Placa, Modelo, Ano, Cor, Ativo, FilialId, Categoria, StatusOperacional, LegendaStatusId, QrCode)
  VALUES (N'XYZ9Z99', N'Yamaha Fazer 250', 2023, N'Azul', 1, @FilialCopaId, 1, 2, @LegendaDisponivelId, N'MOTO-XYZ9Z99');

DECLARE @Moto1Id INT = (SELECT TOP 1 Id FROM dbo.Moto WHERE Placa = N'ABC1D23');
DECLARE @Moto2Id INT = (SELECT TOP 1 Id FROM dbo.Moto WHERE Placa = N'XYZ9Z99');

-- Notificacoes
IF NOT EXISTS (SELECT 1 FROM dbo.Notificacao WHERE Mensagem = N'Moto cadastrada' AND MotoId = @Moto1Id)
  INSERT dbo.Notificacao (Tipo, Mensagem, MotoId, UsuarioOrigemId, Escopo)
  VALUES (0, N'Moto cadastrada', @Moto1Id, @UsuarioAnaId, 0);

IF NOT EXISTS (SELECT 1 FROM dbo.Notificacao WHERE Mensagem = N'Moto atualizada' AND MotoId = @Moto2Id)
  INSERT dbo.Notificacao (Tipo, Mensagem, MotoId, UsuarioOrigemId, Escopo)
  VALUES (1, N'Moto atualizada', @Moto2Id, @UsuarioBrunoId, 1);
