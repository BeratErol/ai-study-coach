using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Backend.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:calisma_tipi.study_type", "pomodoro,manual");

            migrationBuilder.CreateTable(
                name: "kullanicilar",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ad_soyad = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    eposta = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    sifre = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    hedef_sinav = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    olusturulma_tarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_kullanicilar", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "deneme_sonuclari",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    kullanici_id = table.Column<int>(type: "integer", nullable: false),
                    deneme_adi = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    net_skoru = table.Column<decimal>(type: "numeric(5,2)", nullable: false),
                    detaylar = table.Column<string>(type: "jsonb", nullable: true),
                    tarih = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()")
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

            migrationBuilder.CreateTable(
                name: "dersler",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    kullanici_id = table.Column<int>(type: "integer", nullable: false),
                    ders_adi = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    renk_kodu = table.Column<string>(type: "character varying(7)", maxLength: 7, nullable: false, defaultValue: "#3498db")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_dersler", x => x.id);
                    table.ForeignKey(
                        name: "FK_dersler_kullanicilar_kullanici_id",
                        column: x => x.kullanici_id,
                        principalTable: "kullanicilar",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "konular",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ders_id = table.Column<int>(type: "integer", nullable: false),
                    konu_adi = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    is_tamamlandi = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_konular", x => x.id);
                    table.ForeignKey(
                        name: "FK_konular_dersler_ders_id",
                        column: x => x.ders_id,
                        principalTable: "dersler",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "calisma_kayitlari",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    kullanici_id = table.Column<int>(type: "integer", nullable: false),
                    konu_id = table.Column<int>(type: "integer", nullable: false),
                    sure_dakika = table.Column<int>(type: "integer", nullable: false),
                    tip = table.Column<int>(type: "calisma_tipi", nullable: false, defaultValue: 0),
                    tarih = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_calisma_kayitlari", x => x.id);
                    table.ForeignKey(
                        name: "FK_calisma_kayitlari_konular_konu_id",
                        column: x => x.konu_id,
                        principalTable: "konular",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_calisma_kayitlari_kullanicilar_kullanici_id",
                        column: x => x.kullanici_id,
                        principalTable: "kullanicilar",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_calisma_kayitlari_konu_id",
                table: "calisma_kayitlari",
                column: "konu_id");

            migrationBuilder.CreateIndex(
                name: "idx_calisma_kullanici",
                table: "calisma_kayitlari",
                column: "kullanici_id");

            migrationBuilder.CreateIndex(
                name: "idx_calisma_tarih",
                table: "calisma_kayitlari",
                column: "tarih");

            migrationBuilder.CreateIndex(
                name: "idx_deneme_kullanici",
                table: "deneme_sonuclari",
                column: "kullanici_id");

            migrationBuilder.CreateIndex(
                name: "IX_dersler_kullanici_id",
                table: "dersler",
                column: "kullanici_id");

            migrationBuilder.CreateIndex(
                name: "idx_konular_ders",
                table: "konular",
                column: "ders_id");

            migrationBuilder.CreateIndex(
                name: "IX_kullanicilar_eposta",
                table: "kullanicilar",
                column: "eposta",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "calisma_kayitlari");

            migrationBuilder.DropTable(
                name: "deneme_sonuclari");

            migrationBuilder.DropTable(
                name: "konular");

            migrationBuilder.DropTable(
                name: "dersler");

            migrationBuilder.DropTable(
                name: "kullanicilar");
        }
    }
}
