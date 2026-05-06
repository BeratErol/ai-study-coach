using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddUserProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "kullanici_profilleri",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    kullanici_id = table.Column<int>(type: "integer", nullable: false),
                    cinsiyet = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    egitim_seviyesi = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    hedef_sinav = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    sinav_tarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    calisma_tipi = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    hafta_ici_okul = table.Column<bool>(type: "boolean", nullable: false),
                    hafta_ici_baslangic = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    hafta_ici_bitis = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    hafta_ici_ders_saati = table.Column<int>(type: "integer", nullable: false),
                    hafta_sonu_kurs = table.Column<bool>(type: "boolean", nullable: false),
                    hafta_sonu_baslangic = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    hafta_sonu_ders_saati = table.Column<int>(type: "integer", nullable: false),
                    hafta_ici_en_gec = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    hafta_sonu_en_gec = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    tatil_gunleri_json = table.Column<string>(type: "text", nullable: false, defaultValue: "[]"),
                    guclu_dersler_json = table.Column<string>(type: "text", nullable: false, defaultValue: "[]"),
                    zayif_dersler_json = table.Column<string>(type: "text", nullable: false, defaultValue: "[]"),
                    olusturulma_tarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()"),
                    guncelleme_tarihi = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "NOW()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_kullanici_profilleri", x => x.id);
                    table.ForeignKey(
                        name: "FK_kullanici_profilleri_kullanicilar_kullanici_id",
                        column: x => x.kullanici_id,
                        principalTable: "kullanicilar",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "idx_kullanici_profil_unique",
                table: "kullanici_profilleri",
                column: "kullanici_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "kullanici_profilleri");
        }
    }
}
