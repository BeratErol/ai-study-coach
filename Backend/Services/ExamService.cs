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
        private readonly IAiService _aiService;

        public ExamService(AppDbContext context, IAiService aiService)
        {
            _context = context;
            _aiService = aiService;
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

        public async Task<bool> DeleteExamAsync(int userId, int examId)
        {
            var exam = await _context.Exams
                .FirstOrDefaultAsync(e => e.Id == examId && e.UserId == userId);
            if (exam == null) return false;
            _context.Exams.Remove(exam);
            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<ExamResponseDto?> UpdateExamAsync(int userId, int examId, CreateExamDto dto)
        {
            var exam = await _context.Exams
                .Include(e => e.ExamDetails)
                .FirstOrDefaultAsync(e => e.Id == examId && e.UserId == userId);
            if (exam == null) return null;

            exam.Title = dto.Title;
            exam.Date = dto.Date;
            exam.Type = dto.Type;
            _context.ExamDetails.RemoveRange(exam.ExamDetails);
            exam.ExamDetails = dto.Details.Select(d => new ExamDetail
            {
                LessonName = d.LessonName,
                Correct = d.Correct,
                Incorrect = d.Incorrect,
                Net = d.Correct - (d.Incorrect * 0.25m)
            }).ToList();

            await _context.SaveChangesAsync();
            return MapToExamResponseDto(exam);
        }

        public async Task<IEnumerable<ExamResponseDto>> GetExamsByTypeAsync(int userId, string type)
        {
            var exams = await _context.Exams
                .Include(e => e.ExamDetails)
                .Where(e => e.UserId == userId &&
                            e.Type.ToLower().Contains(type.ToLower()))
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

            // Enriched fields
            var byLesson = allDetails
                .GroupBy(d => d.LessonName)
                .Select(g => new ByLessonDto
                {
                    Name       = g.Key,
                    AverageNet = Math.Round(g.Average(d => d.Net), 2),
                    Correct    = g.Sum(d => d.Correct),
                    Incorrect  = g.Sum(d => d.Incorrect)
                })
                .OrderByDescending(b => b.AverageNet)
                .ToList();

            var bestLesson  = byLesson.FirstOrDefault();
            var worstLesson = byLesson.LastOrDefault();

            // Trend: compare last 2 exam nets
            var examNets = progress.Select(p => p.TotalNet).ToList();
            string trend = "stable";
            if (examNets.Count >= 2)
            {
                var diff = examNets.Last() - examNets[^2];
                if (diff > 2)       trend = "improving";
                else if (diff < -2) trend = "declining";
            }

            var avgNet = exams.Any()
                ? Math.Round(exams.Average(e => e.ExamDetails.Sum(d => d.Net)), 2)
                : 0;

            return new ExamAnalysisDto
            {
                LessonAverages  = averages,
                ProgressOverTime = progress,
                BestLesson  = bestLesson?.Name,
                WorstLesson = worstLesson?.Name,
                BestNet     = bestLesson?.AverageNet ?? 0,
                WorstNet    = worstLesson?.AverageNet ?? 0,
                Trend       = trend,
                TotalExams  = exams.Count,
                AverageNet  = avgNet,
                ByLesson    = byLesson
            };
        }

        public async Task<string> GetAiRecommendationAsync(int userId)
        {
            var analysis = await GetExamAnalysisAsync(userId);
            if (analysis.LessonAverages == null || !analysis.LessonAverages.Any())
                return "Henüz yeterli deneme verisi yok. Tavsiye için en az bir deneme girin.";

            var lowLessons = analysis.LessonAverages.Where(a => a.AverageNet < 20).Select(a => a.LessonName);
            var prompt = $"Öğrencinin ders ortalamaları şöyledir: {string.Join(", ", analysis.LessonAverages.Select(a => $"{a.LessonName}: {a.AverageNet} net"))}. " +
                         $"Özellikle şu derslerde düşük performans sergiliyor: {string.Join(", ", lowLessons)}. " +
                         $"Lütfen bu öğrenciye bugün ne çalışması gerektiği hakkında kısa, motivasyon verici ve net bir tavsiye ver.";

            return await _aiService.GenerateTextRecommendationAsync(prompt);
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
