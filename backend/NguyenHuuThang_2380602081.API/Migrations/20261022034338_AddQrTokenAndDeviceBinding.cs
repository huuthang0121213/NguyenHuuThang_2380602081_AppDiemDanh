using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NguyenHuuThang_2380602081.API.Migrations
{
    /// <inheritdoc />
    public partial class AddQrTokenAndDeviceBinding : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "FacePhotoBase64",
                table: "AttendanceRecords",
                newName: "FaceEmbeddingJson");

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "Students",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "DeviceRegisteredAt",
                table: "Students",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "FaceEmbeddingJson",
                table: "Students",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "FaceRegisteredAt",
                table: "Students",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "CheckInMethod",
                table: "AttendanceRecords",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(50)",
                oldMaxLength: 50);

            migrationBuilder.AddColumn<string>(
                name: "DeviceId",
                table: "AttendanceRecords",
                type: "nvarchar(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "QrTokenUsed",
                table: "AttendanceRecords",
                type: "nvarchar(512)",
                maxLength: 512,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "QrTokens",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Token = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    SessionId = table.Column<int>(type: "int", nullable: false),
                    UsedByStudentId = table.Column<int>(type: "int", nullable: true),
                    IssuedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UsedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    IsUsed = table.Column<bool>(type: "bit", nullable: false),
                    DeviceId = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_QrTokens", x => x.Id);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "QrTokens");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "DeviceRegisteredAt",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "FaceEmbeddingJson",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "FaceRegisteredAt",
                table: "Students");

            migrationBuilder.DropColumn(
                name: "DeviceId",
                table: "AttendanceRecords");

            migrationBuilder.DropColumn(
                name: "QrTokenUsed",
                table: "AttendanceRecords");

            migrationBuilder.RenameColumn(
                name: "FaceEmbeddingJson",
                table: "AttendanceRecords",
                newName: "FacePhotoBase64");

            migrationBuilder.AlterColumn<string>(
                name: "CheckInMethod",
                table: "AttendanceRecords",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(100)",
                oldMaxLength: 100);
        }
    }
}
