using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Backend.Migrations
{
    /// <inheritdoc />
    public partial class ChangeStudyTypeToString : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("ALTER TABLE calisma_kayitlari ALTER COLUMN tip DROP DEFAULT;");
            migrationBuilder.Sql("ALTER TABLE calisma_kayitlari ALTER COLUMN tip TYPE varchar(50) USING tip::text;");
            migrationBuilder.Sql("ALTER TABLE calisma_kayitlari ALTER COLUMN tip SET DEFAULT 'pomodoro';");
            migrationBuilder.Sql("DROP TYPE IF EXISTS public.calisma_tipi CASCADE;");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:public.calisma_tipi", "pomodoro,manual");

            migrationBuilder.AlterColumn<int>(
                name: "tip",
                table: "calisma_kayitlari",
                type: "calisma_tipi",
                nullable: false,
                defaultValueSql: "'pomodoro'::public.calisma_tipi",
                oldClrType: typeof(string),
                oldType: "varchar(50)",
                oldDefaultValue: "pomodoro");
        }
    }
}
