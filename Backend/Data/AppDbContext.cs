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
        public DbSet<ExamResult> ExamResults { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Table mapping
            modelBuilder.Entity<User>().ToTable("kullanicilar");
            modelBuilder.Entity<Lesson>().ToTable("dersler");
            modelBuilder.Entity<Topic>().ToTable("konular");
            modelBuilder.Entity<StudySession>().ToTable("calisma_kayitlari");
            modelBuilder.Entity<ExamResult>().ToTable("deneme_sonuclari");

            // Enum mapping for StudyType (PostgreSQL ENUM 'calisma_tipi')
            modelBuilder.HasPostgresEnum<StudyType>("public", "calisma_tipi");

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
                
                // DÜZELTME BURADA: 'Pomodoro' yerine 'pomodoro' (küçük harf)
                entity.Property(e => e.Type)
                    .HasColumnName("tip")
                    .HasColumnType("calisma_tipi")
                    .HasDefaultValueSql("'pomodoro'::public.calisma_tipi"); 
                
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

            // ExamResult configuration
            modelBuilder.Entity<ExamResult>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).HasColumnName("id");
                entity.Property(e => e.UserId).HasColumnName("kullanici_id").IsRequired();
                entity.Property(e => e.ExamName).HasColumnName("deneme_adi").IsRequired().HasMaxLength(255);
                entity.Property(e => e.NetScore).HasColumnName("net_skoru").HasColumnType("numeric(5, 2)").IsRequired();
                entity.Property(e => e.DetailsJson).HasColumnName("detaylar").HasColumnType("jsonb");
                entity.Property(e => e.Date).HasColumnName("tarih").HasDefaultValueSql("NOW()");

                entity.HasOne(d => d.User)
                    .WithMany(p => p.ExamResults)
                    .HasForeignKey(d => d.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
                
                entity.HasIndex(e => e.UserId).HasDatabaseName("idx_deneme_kullanici");
            });
        }
    }
}