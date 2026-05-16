using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Backend.Migrations
{
    /// <inheritdoc />
    public partial class AddQuestionLog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "soru_kayitlari",
                columns: table => new
                {
                    id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    kullanici_id = table.Column<int>(type: "integer", nullable: false),
                    tarih = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    ders_anahtar = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    ders_adi = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    soru_sayisi = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_soru_kayitlari", x => x.id);
                    table.ForeignKey(
                        name: "FK_soru_kayitlari_kullanicilar_kullanici_id",
                        column: x => x.kullanici_id,
                        principalTable: "kullanicilar",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "idx_soru_log_unique",
                table: "soru_kayitlari",
                columns: new[] { "kullanici_id", "tarih", "ders_anahtar" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "soru_kayitlari");
        }
    }
}
