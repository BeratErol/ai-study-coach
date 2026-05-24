using Backend.Models;
using Microsoft.EntityFrameworkCore;

namespace Backend.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; } = null!;
        public DbSet<Lesson> Lessons { get; set; } = null!;
        public DbSet<Topic> Topics { get; set; } = null!;
        public DbSet<StudySession> StudySessions { get; set; } = null!;
        public DbSet<Exam> Exams { get; set; } = null!;
        public DbSet<ExamDetail> ExamDetails { get; set; } = null!;
        public DbSet<UserProfile> UserProfiles { get; set; } = null!;
        public DbSet<QuestionLog> QuestionLogs { get; set; } = null!;
        public DbSet<AppState> AppStates { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Table mapping
            modelBuilder.Entity<User>().ToTable("kullanicilar");
            modelBuilder.Entity<Lesson>().ToTable("dersler");
            modelBuilder.Entity<Topic>().ToTable("konular");
            modelBuilder.Entity<StudySession>().ToTable("calisma_kayitlari");
            modelBuilder.Entity<Exam>().ToTable("denemeler");
            modelBuilder.Entity<ExamDetail>().ToTable("deneme_detaylari");

            // User configuration
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.FullName).HasColumnName("ad_soyad").IsRequired().HasMaxLength(255);
                entity.Property(e => e.Email).HasColumnName("eposta").IsRequired().HasMaxLength(255);
                entity.HasIndex(e => e.Email).IsUnique();
                entity.Property(e => e.PasswordHash).HasColumnName("sifre").IsRequired().HasMaxLength(255);
                entity.Property(e => e.TargetExam).HasColumnName("hedef_sinav").HasMaxLength(100);
                entity.Property(e => e.CreatedAt).HasColumnName("olusturulma_tarihi").HasDefaultValueSql("NOW()");
            });

            // Lesson configuration
            modelBuilder.Entity<Lesson>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.UserId).HasColumnName("kullanici_id").IsRequired();
                entity.Property(e => e.Name).HasColumnName("ders_adi").IsRequired().HasMaxLength(100);
                entity.Property(e => e.ColorCode).HasColumnName("renk_kodu").HasMaxLength(7).HasDefaultValue("#3498db");

                entity.HasOne(d => d.User)
                    .WithMany(p => p.Lessons)
                    .HasForeignKey(d => d.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Topic configuration
            modelBuilder.Entity<Topic>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.LessonId).HasColumnName("ders_id").IsRequired();
                entity.Property(e => e.Name).HasColumnName("konu_adi").IsRequired().HasMaxLength(255);
                entity.Property(e => e.IsCompleted).HasColumnName("is_tamamlandi").HasDefaultValue(false);

                entity.HasOne(d => d.Lesson)
                    .WithMany(p => p.Topics)
                    .HasForeignKey(d => d.LessonId)
                    .OnDelete(DeleteBehavior.Cascade);
                
                entity.HasIndex(e => e.LessonId).HasDatabaseName("idx_konular_ders");
            });

            // StudySession configuration
            modelBuilder.Entity<StudySession>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.UserId).HasColumnName("kullanici_id").IsRequired();
                entity.Property(e => e.TopicId).HasColumnName("konu_id").IsRequired();
                entity.Property(e => e.DurationMinutes).HasColumnName("sure_dakika").IsRequired();
                
                // DÜZELTME BURADA: Enum yerine varchar(50) kullanıyoruz
                entity.Property(e => e.Type)
                    .HasColumnName("tip")
                    .HasColumnType("varchar(50)")
                    .HasDefaultValue("pomodoro")
                    .IsRequired();
                
                entity.Property(e => e.Date).HasColumnName("tarih").HasDefaultValueSql("NOW()");

                entity.HasOne(d => d.User)
                    .WithMany(p => p.StudySessions)
                    .HasForeignKey(d => d.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasOne(d => d.Topic)
                    .WithMany()
                    .HasForeignKey(d => d.TopicId)
                    .OnDelete(DeleteBehavior.Cascade);
                
                entity.HasIndex(e => e.UserId).HasDatabaseName("idx_calisma_kullanici");
                entity.HasIndex(e => e.Date).HasDatabaseName("idx_calisma_tarih");
            });

            // Exam configuration
            modelBuilder.Entity<Exam>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.UserId).HasColumnName("kullanici_id").IsRequired();
                entity.Property(e => e.Title).HasColumnName("deneme_adi").IsRequired().HasMaxLength(255);
                entity.Property(e => e.Date).HasColumnName("tarih").HasDefaultValueSql("NOW()");
                entity.Property(e => e.Type).HasColumnName("tip").HasColumnType("varchar(50)").IsRequired();

                entity.HasOne(d => d.User)
                    .WithMany(p => p.Exams)
                    .HasForeignKey(d => d.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                
                entity.HasIndex(e => e.UserId).HasDatabaseName("idx_deneme_kullanici");
            });

            // UserProfile configuration
            modelBuilder.Entity<UserProfile>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.UserId).HasColumnName("kullanici_id").IsRequired();
                entity.Property(e => e.Gender).HasColumnName("cinsiyet").HasMaxLength(20);
                entity.Property(e => e.EducationLevel).HasColumnName("egitim_seviyesi").HasMaxLength(50);
                entity.Property(e => e.TargetExam).HasColumnName("hedef_sinav").HasMaxLength(50);
                entity.Property(e => e.ExamDate).HasColumnName("sinav_tarihi");
                entity.Property(e => e.StudyType).HasColumnName("calisma_tipi").HasMaxLength(20);
                entity.Property(e => e.HasWeekdaySchool).HasColumnName("hafta_ici_okul");
                entity.Property(e => e.WeekdayStartTime).HasColumnName("hafta_ici_baslangic").HasMaxLength(10);
                entity.Property(e => e.WeekdayEndTime).HasColumnName("hafta_ici_bitis").HasMaxLength(10);
                entity.Property(e => e.WeekdayStudyHours).HasColumnName("hafta_ici_ders_saati");
                entity.Property(e => e.HasWeekendCourse).HasColumnName("hafta_sonu_kurs");
                entity.Property(e => e.WeekendStartTime).HasColumnName("hafta_sonu_baslangic").HasMaxLength(10);
                entity.Property(e => e.WeekendStudyHours).HasColumnName("hafta_sonu_ders_saati");
                entity.Property(e => e.WeekdayLatestTime).HasColumnName("hafta_ici_en_gec").HasMaxLength(10);
                entity.Property(e => e.WeekendLatestTime).HasColumnName("hafta_sonu_en_gec").HasMaxLength(10);
                entity.Property(e => e.OffDaysJson).HasColumnName("tatil_gunleri_json").HasDefaultValue("[]");
                entity.Property(e => e.StrongSubjectsJson).HasColumnName("guclu_dersler_json").HasDefaultValue("[]");
                entity.Property(e => e.WeakSubjectsJson).HasColumnName("zayif_dersler_json").HasDefaultValue("[]");
                entity.Property(e => e.CreatedAt).HasColumnName("olusturulma_tarihi").HasDefaultValueSql("NOW()");
                entity.Property(e => e.UpdatedAt).HasColumnName("guncelleme_tarihi").HasDefaultValueSql("NOW()");

                entity.HasOne(d => d.User)
                    .WithMany()
                    .HasForeignKey(d => d.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(e => e.UserId).IsUnique().HasDatabaseName("idx_kullanici_profil_unique");
            });
            modelBuilder.Entity<UserProfile>().ToTable("kullanici_profilleri");

            // QuestionLog configuration
            modelBuilder.Entity<QuestionLog>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.UserId).HasColumnName("kullanici_id").IsRequired();
                entity.Property(e => e.Date).HasColumnName("tarih").IsRequired().HasMaxLength(10);
                entity.Property(e => e.SubjectKey).HasColumnName("ders_anahtar").IsRequired().HasMaxLength(50);
                entity.Property(e => e.SubjectName).HasColumnName("ders_adi").IsRequired().HasMaxLength(100);
                entity.Property(e => e.Count).HasColumnName("soru_sayisi").IsRequired();

                entity.HasOne(d => d.User)
                    .WithMany()
                    .HasForeignKey(d => d.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(e => new { e.UserId, e.Date, e.SubjectKey })
                    .IsUnique()
                    .HasDatabaseName("idx_soru_log_unique");
            });
            modelBuilder.Entity<QuestionLog>().ToTable("soru_kayitlari");

            // AppState configuration — cihazdan bağımsız generic key-value deposu
            modelBuilder.Entity<AppState>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.UserId).HasColumnName("kullanici_id").IsRequired();
                entity.Property(e => e.Key).HasColumnName("anahtar").IsRequired().HasMaxLength(120);
                entity.Property(e => e.ValueJson).HasColumnName("deger_json").IsRequired();
                entity.Property(e => e.UpdatedAt).HasColumnName("guncelleme_tarihi").HasDefaultValueSql("NOW()");

                entity.HasOne(d => d.User)
                    .WithMany()
                    .HasForeignKey(d => d.UserId)
                    .OnDelete(DeleteBehavior.Cascade);

                entity.HasIndex(e => new { e.UserId, e.Key })
                    .IsUnique()
                    .HasDatabaseName("idx_app_state_unique");
            });
            modelBuilder.Entity<AppState>().ToTable("uygulama_durumu");

            // ExamDetail configuration
            modelBuilder.Entity<ExamDetail>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.ExamId).HasColumnName("deneme_id").IsRequired();
                entity.Property(e => e.LessonName).HasColumnName("ders_adi").IsRequired().HasMaxLength(100);
                entity.Property(e => e.Correct).HasColumnName("dogru").IsRequired();
                entity.Property(e => e.Incorrect).HasColumnName("yanlis").IsRequired();
                entity.Property(e => e.Net).HasColumnName("net").HasColumnType("numeric(5, 2)").IsRequired();

                entity.HasOne(d => d.Exam)
                    .WithMany(p => p.ExamDetails)
                    .HasForeignKey(d => d.ExamId)
                    .OnDelete(DeleteBehavior.Cascade);
                
                entity.HasIndex(e => e.ExamId).HasDatabaseName("idx_deneme_detay_sinav");
            });
        }
    }
}