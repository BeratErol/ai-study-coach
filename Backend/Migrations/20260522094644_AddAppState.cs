using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddAppState : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "uygulama_durumu",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    kullanici_id = table.Column<int>(type: "integer", nullable: false),
                    anahtar = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    deger_json = table.Column<string>(type: "text", nullable: false),
                    guncelleme_tarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_uygulama_durumu", x => x.id);
                    table.ForeignKey(
                        name: "FK_uygulama_durumu_kullanicilar_kullanici_id",
                        column: x => x.kullanici_id,
                        principalTable: "kullanicilar",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "idx_app_state_unique",
                table: "uygulama_durumu",
                columns: new[] { "kullanici_id", "anahtar" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "uygulama_durumu");
        }
    }
}
