using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Data
{
    public static class DemoSeeder
    {
        public static async Task SeedAsync(AppDbContext db)
        {
            const string demoEmail = "demo@studycoach.com";
            if (await db.Users.AnyAsync(u => u.Email == demoEmail)) return;

            var hash = BCrypt.Net.BCrypt.HashPassword("Demo1234");
            var user = new User
            {
                FullName   = "Demo Öğrenci",
                Email      = demoEmail,
                PasswordHash = hash,
                TargetExam = "TYT",
                CreatedAt  = DateTime.UtcNow
            };
            db.Users.Add(user);
            await db.SaveChangesAsync();

            // Lessons
            var lessonData = new[]
            {
                ("Matematik",  "4F46E5", 0),
                ("Türkçe",     "10B981", 1),
                ("Fizik",      "EF4444", 2),
                ("Kimya",      "F59E0B", 3),
                ("Biyoloji",   "8B5CF6", 4),
            };

            var topicsByLesson = new[]
            {
                new[] { "Sayılar", "Cebir", "Geometri", "Trigonometri", "Olasılık" },
                new[] { "Paragraf", "Dil Bilgisi", "Anlam Bilgisi", "Noktalama", "Yazım Kuralları" },
                new[] { "Kuvvet ve Hareket", "Enerji", "Dalgalar", "Optik", "Elektrik" },
                new[] { "Atom Yapısı", "Periyodik Tablo", "Kimyasal Bağlar", "Reaksiyonlar", "Asit-Baz" },
                new[] { "Hücre", "Metabolizma", "Genetik", "Sinir Sistemi", "Ekosistem" },
            };

            var completedMap = new[]
            {
                new[] { true, true, true, false, false },
                new[] { true, true, false, false, false },
                new[] { true, true, false, false, false },
                new[] { true, false, false, false, false },
                new[] { true, true, true, false, false },
            };

            var lessons = new List<Lesson>();
            for (int i = 0; i < lessonData.Length; i++)
            {
                var (name, color, idx) = lessonData[i];
                var lesson = new Lesson
                {
                    UserId      = user.Id,
                    Name        = name,
                    ColorCode   = color,
                    PlannedDate = DateTime.UtcNow.AddDays(30 - idx * 5),
                    Topics      = topicsByLesson[i].Select((t, j) => new Topic
                    {
                        Name        = t,
                        IsCompleted = completedMap[i][j]
                    }).ToList()
                };
                lessons.Add(lesson);
                db.Lessons.Add(lesson);
            }
            await db.SaveChangesAsync();

            // Study sessions (28 pomodoros in last 14 days)
            var rng = new Random(42);
            var now = DateTime.UtcNow;
            var allTopics = lessons.SelectMany(l => l.Topics).ToList();

            for (int d = 0; d < 14; d++)
            {
                var dayDate  = now.AddDays(-d).Date;
                var count    = rng.Next(1, 4);
                for (int p = 0; p < count; p++)
                {
                    var topic = allTopics[rng.Next(allTopics.Count)];
                    db.StudySessions.Add(new StudySession
                    {
                        UserId          = user.Id,
                        TopicId         = topic.Id,
                        DurationMinutes = 25,
                        Type            = "pomodoro",
                        Date            = dayDate.AddHours(8 + p * 2)
                    });
                }
            }
            await db.SaveChangesAsync();

            // Exams (10 realistic results)
            var examData = new[]
            {
                ("TYT Deneme #1",  "TYT",  -25, new[] { ("Matematik", 18, 6), ("Türkçe", 22, 5), ("Fizik", 8, 4), ("Kimya", 7, 3), ("Biyoloji", 9, 2) }),
                ("TYT Deneme #2",  "TYT",  -22, new[] { ("Matematik", 20, 5), ("Türkçe", 24, 3), ("Fizik", 9, 3), ("Kimya", 8, 2), ("Biyoloji", 10, 2) }),
                ("TYT Deneme #3",  "TYT",  -19, new[] { ("Matematik", 22, 4), ("Türkçe", 23, 4), ("Fizik", 10, 3), ("Kimya", 9, 2), ("Biyoloji", 11, 1) }),
                ("AYT Deneme #1",  "AYT",  -18, new[] { ("Matematik", 19, 7), ("Fizik", 12, 4), ("Kimya", 10, 3), ("Biyoloji", 13, 2) }),
                ("TYT Deneme #4",  "TYT",  -15, new[] { ("Matematik", 24, 3), ("Türkçe", 25, 2), ("Fizik", 11, 2), ("Kimya", 10, 2), ("Biyoloji", 12, 1) }),
                ("TYT Deneme #5",  "TYT",  -12, new[] { ("Matematik", 25, 3), ("Türkçe", 26, 2), ("Fizik", 12, 2), ("Kimya", 11, 1), ("Biyoloji", 13, 1) }),
                ("AYT Deneme #2",  "AYT",  -10, new[] { ("Matematik", 22, 5), ("Fizik", 14, 3), ("Kimya", 12, 2), ("Biyoloji", 15, 1) }),
                ("TYT Deneme #6",  "TYT",  -7,  new[] { ("Matematik", 27, 2), ("Türkçe", 27, 2), ("Fizik", 13, 2), ("Kimya", 12, 1), ("Biyoloji", 14, 1) }),
                ("TYT Deneme #7",  "TYT",  -4,  new[] { ("Matematik", 28, 2), ("Türkçe", 28, 1), ("Fizik", 14, 1), ("Kimya", 13, 1), ("Biyoloji", 15, 1) }),
                ("TYT Deneme #8",  "TYT",  -1,  new[] { ("Matematik", 30, 1), ("Türkçe", 29, 1), ("Fizik", 15, 1), ("Kimya", 14, 0), ("Biyoloji", 16, 0) }),
            };

            foreach (var (title, type, daysAgo, details) in examData)
            {
                var exam = new Exam
                {
                    UserId = user.Id,
                    Title  = title,
                    Type   = type,
                    Date   = now.AddDays(daysAgo),
                    ExamDetails = details.Select(d => new ExamDetail
                    {
                        LessonName = d.Item1,
                        Correct    = d.Item2,
                        Incorrect  = d.Item3,
                        Net        = d.Item2 - (d.Item3 * 0.25m)
                    }).ToList()
                };
                db.Exams.Add(exam);
            }
            await db.SaveChangesAsync();
        }
    }
}
