using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddExamAndDetailsModels : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "deneme_sonuclari");

            migrationBuilder.CreateTable(
                name: "denemeler",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    kullanici_id = table.Column<int>(type: "integer", nullable: false),
                    deneme_adi = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    tarih = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    tip = table.Column<string>(type: "varchar(50)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_denemeler", x => x.id);
                    table.ForeignKey(
                        name: "FK_denemeler_kullanicilar_kullanici_id",
                        column: x => x.kullanici_id,
                        principalTable: "kullanicilar",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "deneme_detaylari",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    deneme_id = table.Column<int>(type: "integer", nullable: false),
                    ders_adi = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    dogru = table.Column<int>(type: "integer", nullable: false),
                    yanlis = table.Column<int>(type: "integer", nullable: false),
                    net = table.Column<decimal>(type: "numeric(5,2)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_deneme_detaylari", x => x.id);
                    table.ForeignKey(
                        name: "FK_deneme_detaylari_denemeler_deneme_id",
                        column: x => x.deneme_id,
                        principalTable: "denemeler",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "idx_deneme_detay_sinav",
                table: "deneme_detaylari",
                column: "deneme_id");

            migrationBuilder.CreateIndex(
                name: "idx_deneme_kullanici",
                table: "denemeler",
                column: "kullanici_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "deneme_detaylari");

            migrationBuilder.DropTable(
                name: "denemeler");

            migrationBuilder.CreateTable(
                name: "deneme_sonuclari",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    kullanici_id = table.Column<int>(type: "integer", nullable: false),
                    tarih = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    detaylar = table.Column<string>(type: "jsonb", nullable: true),
                    deneme_adi = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    net_skoru = table.Column<decimal>(type: "numeric(5,2)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_deneme_sonuclari", x => x.id);
                    table.ForeignKey(
                        name: "FK_deneme_sonuclari_kullanicilar_kullanici_id",
                        column: x => x.kullanici_id,
                        principalTable: "kullanicilar",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "idx_deneme_kullanici",
                table: "deneme_sonuclari",
                column: "kullanici_id");
        }
    }
}
