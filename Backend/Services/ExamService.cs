using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Backend.Data;
using Backend.DTOs;
using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Services
{
    public class ExamService : IExamService
    {
        private readonly AppDbContext _context;

        public ExamService(AppDbContext context)
        {
            _context = context;
        }

        public async Task<ExamResponseDto> AddExamAsync(int userId, CreateExamDto dto)
        {
            var exam = new Exam
            {
                UserId = userId,
                Title = dto.Title,
                Date = dto.Date,
                Type = dto.Type,
                ExamDetails = dto.Details.Select(d => new ExamDetail
                {
                    LessonName = d.LessonName,
                    Correct = d.Correct,
                    Incorrect = d.Incorrect,
                    Net = d.Correct - (d.Incorrect * 0.25m)
                }).ToList()
            };

            _context.Exams.Add(exam);
            await _context.SaveChangesAsync();

            return MapToExamResponseDto(exam);
        }

        public async Task<IEnumerable<ExamResponseDto>> GetExamResultsAsync(int userId)
        {
            var exams = await _context.Exams
                .Include(e => e.ExamDetails)
                .Where(e => e.UserId == userId)
                .OrderByDescending(e => e.Date)
                .ToListAsync();

            return exams.Select(MapToExamResponseDto);
        }

        public async Task<ExamAnalysisDto> GetExamAnalysisAsync(int userId)
        {
            var exams = await _context.Exams
                .Include(e => e.ExamDetails)
                .Where(e => e.UserId == userId)
                .OrderBy(e => e.Date) // chronological order for graph
                .ToListAsync();

            if (!exams.Any())
            {
                return new ExamAnalysisDto();
            }

            var allDetails = exams.SelectMany(e => e.ExamDetails).ToList();

            // Calculate lesson averages
            var averages = allDetails
                .GroupBy(d => d.LessonName)
                .Select(g => new LessonAverageDto
                {
                    LessonName = g.Key,
                    AverageNet = Math.Round(g.Average(d => d.Net), 2)
                }).ToList();

            // Prepare chronological progress
            var progress = exams.Select(e => new ExamProgressDto
            {
                ExamId = e.Id,
                ExamTitle = e.Title,
                ExamType = e.Type,
                Date = e.Date,
                TotalNet = e.ExamDetails.Sum(d => d.Net),
                Lessons = e.ExamDetails.Select(d => new LessonNetDto
                {
                    LessonName = d.LessonName,
                    Net = d.Net
                }).ToList()
            }).ToList();

            return new ExamAnalysisDto
            {
                LessonAverages = averages,
                ProgressOverTime = progress
            };
        }

        private ExamResponseDto MapToExamResponseDto(Exam exam)
        {
            return new ExamResponseDto
            {
                Id = exam.Id,
                Title = exam.Title,
                Date = exam.Date,
                Type = exam.Type,
                TotalNet = exam.ExamDetails.Sum(d => d.Net),
                Details = exam.ExamDetails.Select(d => new ExamDetailResponseDto
                {
                    Id = d.Id,
                    LessonName = d.LessonName,
                    Correct = d.Correct,
                    Incorrect = d.Incorrect,
                    Net = d.Net
                }).ToList()
            };
        }
    }
}
