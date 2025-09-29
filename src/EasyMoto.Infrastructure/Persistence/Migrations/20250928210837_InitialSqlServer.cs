using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace EasyMoto.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialSqlServer : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "filiais",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    nome = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    cep = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    cidade = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    uf = table.Column<string>(type: "nvarchar(2)", maxLength: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_filiais", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "legenda_status",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    titulo = table.Column<string>(type: "nvarchar(80)", maxLength: 80, nullable: false),
                    descricao = table.Column<string>(type: "nvarchar(255)", maxLength: 255, nullable: true),
                    cor_hex = table.Column<string>(type: "nvarchar(7)", maxLength: 7, nullable: true),
                    ativo = table.Column<bool>(type: "bit", nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_legenda_status", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "moto",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    placa = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    modelo = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    ano = table.Column<int>(type: "int", nullable: false),
                    cor = table.Column<string>(type: "nvarchar(40)", maxLength: 40, nullable: false),
                    ativo = table.Column<bool>(type: "bit", nullable: false),
                    filial_id = table.Column<int>(type: "int", nullable: false),
                    categoria = table.Column<int>(type: "int", nullable: false),
                    status_operacional = table.Column<int>(type: "int", nullable: false),
                    legenda_status_id = table.Column<int>(type: "int", nullable: true),
                    qrcode = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_moto", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "notificacao",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    tipo = table.Column<int>(type: "int", nullable: false),
                    mensagem = table.Column<string>(type: "nvarchar(280)", maxLength: 280, nullable: false),
                    moto_id = table.Column<int>(type: "int", nullable: true),
                    usuario_origem_id = table.Column<int>(type: "int", nullable: false),
                    criada_em = table.Column<DateTime>(type: "datetime2", nullable: false),
                    escopo = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notificacao", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "usuarios",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    nome_completo = table.Column<string>(type: "nvarchar(160)", maxLength: 160, nullable: false),
                    email = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    senha_hash = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    telefone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    cpf = table.Column<string>(type: "nvarchar(14)", maxLength: 14, nullable: false),
                    cep_filial = table.Column<string>(type: "nvarchar(10)", maxLength: 10, nullable: false),
                    perfil = table.Column<int>(type: "int", nullable: false),
                    ativo = table.Column<bool>(type: "bit", nullable: false),
                    FilialId = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_usuarios", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "notificacao_leitura",
                columns: table => new
                {
                    notificacao_id = table.Column<int>(type: "int", nullable: false),
                    usuario_id = table.Column<int>(type: "int", nullable: false),
                    lido_em = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notificacao_leitura", x => new { x.notificacao_id, x.usuario_id });
                    table.ForeignKey(
                        name: "FK_notificacao_leitura_notificacao_notificacao_id",
                        column: x => x.notificacao_id,
                        principalTable: "notificacao",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "filiais");

            migrationBuilder.DropTable(
                name: "legenda_status");

            migrationBuilder.DropTable(
                name: "moto");

            migrationBuilder.DropTable(
                name: "notificacao_leitura");

            migrationBuilder.DropTable(
                name: "usuarios");

            migrationBuilder.DropTable(
                name: "notificacao");
        }
    }
}
