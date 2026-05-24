using System.Text.Json;
using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services
{
    public class UserProfileService : IUserProfileService
    {
        private readonly AppDbContext _db;

        public UserProfileService(AppDbContext db)
        {
            _db = db;
        }

        public async Task<UserProfileResponseDto> UpsertProfileAsync(int userId, UserProfileRequestDto dto)
        {
            var profile = await _db.UserProfiles.FirstOrDefaultAsync(p => p.UserId == userId);

            if (profile == null)
            {
                profile = new UserProfile { UserId = userId, CreatedAt = DateTime.UtcNow };
                _db.UserProfiles.Add(profile);
            }

            profile.Gender = dto.Gender;
            profile.EducationLevel = dto.EducationLevel;
            profile.TargetExam = dto.TargetExam;
            // Npgsql timestamptz sütunu UTC Kind zorunlu kılar; JSON'dan gelen
            // tarih Unspecified olabilir — UTC'ye normalize et.
            profile.ExamDate = dto.ExamDate.HasValue
                ? DateTime.SpecifyKind(dto.ExamDate.Value, DateTimeKind.Utc)
                : null;
            profile.StudyType = dto.StudyType;
            profile.HasWeekdaySchool = dto.HasWeekdaySchool;
            profile.WeekdayStartTime = dto.WeekdayStartTime;
            profile.WeekdayEndTime = dto.WeekdayEndTime;
            profile.WeekdayStudyHours = dto.WeekdayStudyHours;
            profile.HasWeekendCourse = dto.HasWeekendCourse;
            profile.WeekendStartTime = dto.WeekendStartTime;
            profile.WeekendStudyHours = dto.WeekendStudyHours;
            profile.WeekdayLatestTime = dto.WeekdayLatestTime;
            profile.WeekendLatestTime = dto.WeekendLatestTime;
            profile.OffDaysJson = JsonSerializer.Serialize(dto.OffDays);
            profile.StrongSubjectsJson = JsonSerializer.Serialize(dto.StrongSubjects);
            profile.WeakSubjectsJson = JsonSerializer.Serialize(dto.WeakSubjects);
            profile.UpdatedAt = DateTime.UtcNow;

            await _db.SaveChangesAsync();
            return ToResponseDto(profile);
        }

        public async Task<UserProfileResponseDto?> GetProfileAsync(int userId)
        {
            var profile = await _db.UserProfiles.FirstOrDefaultAsync(p => p.UserId == userId);
            return profile == null ? null : ToResponseDto(profile);
        }

        private static UserProfileResponseDto ToResponseDto(UserProfile p) => new()
        {
            Id = p.Id,
            UserId = p.UserId,
            Gender = p.Gender,
            EducationLevel = p.EducationLevel,
            TargetExam = p.TargetExam,
            ExamDate = p.ExamDate,
            StudyType = p.StudyType,
            HasWeekdaySchool = p.HasWeekdaySchool,
            WeekdayStartTime = p.WeekdayStartTime,
            WeekdayEndTime = p.WeekdayEndTime,
            WeekdayStudyHours = p.WeekdayStudyHours,
            HasWeekendCourse = p.HasWeekendCourse,
            WeekendStartTime = p.WeekendStartTime,
            WeekendStudyHours = p.WeekendStudyHours,
            WeekdayLatestTime = p.WeekdayLatestTime,
            WeekendLatestTime = p.WeekendLatestTime,
            OffDays = JsonSerializer.Deserialize<List<int>>(p.OffDaysJson) ?? new(),
            StrongSubjects = JsonSerializer.Deserialize<List<string>>(p.StrongSubjectsJson) ?? new(),
            WeakSubjects = JsonSerializer.Deserialize<List<string>>(p.WeakSubjectsJson) ?? new(),
            CreatedAt = p.CreatedAt,
            UpdatedAt = p.UpdatedAt,
        };
    }
}
