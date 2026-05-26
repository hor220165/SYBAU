using Microsoft.EntityFrameworkCore;
using Sybau_Backend.Data;
using Sybau_Backend.Models;
using Sybau_Backend.Models.Enums;

namespace Sybau_Backend._Services;

public class DefaultExerciseSeeder
{
    private readonly FitnessDbContext _context;
    private readonly ILogger<DefaultExerciseSeeder> _logger;

    public DefaultExerciseSeeder(FitnessDbContext context, ILogger<DefaultExerciseSeeder> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task SeedAsync()
    {
        var existingExercises = await _context.Exercises.ToListAsync();
        var existingByName = existingExercises
            .GroupBy(exercise => exercise.Name, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(group => group.Key, group => group.First(), StringComparer.OrdinalIgnoreCase);

        var added = 0;
        var updated = 0;

        foreach (var exercise in DefaultExercises)
        {
            if (existingByName.TryGetValue(exercise.Name, out var existing))
            {
                if (ApplyDefaultRewards(existing, exercise)) updated++;
                continue;
            }

            _context.Exercises.Add(new Exercise(
                exercise.Name,
                exercise.Description,
                exercise.Category,
                exercise.Difficulty,
                ExerciseRewardRules.XpPerUnit(exercise.Difficulty),
                exercise.DailyLimit,
                exercise.Unit));
            added++;
        }

        foreach (var exercise in existingExercises)
        {
            var expectedXp = ExerciseRewardRules.XpPerUnit(exercise.Difficulty);
            if (Math.Abs(exercise.XpPerRep - expectedXp) <= 0.001) continue;

            exercise.XpPerRep = expectedXp;
            updated++;
        }

        if (added == 0 && updated == 0) return;

        await _context.SaveChangesAsync();
        _logger.LogInformation("Seeded {AddedCount} and updated {UpdatedCount} default exercises.", added, updated);
    }

    private static bool ApplyDefaultRewards(Exercise existing, SeedExercise defaults)
    {
        var changed = false;

        if (existing.Difficulty != defaults.Difficulty)
        {
            existing.Difficulty = defaults.Difficulty;
            changed = true;
        }

        var expectedXp = ExerciseRewardRules.XpPerUnit(existing.Difficulty);
        if (Math.Abs(existing.XpPerRep - expectedXp) > 0.001)
        {
            existing.XpPerRep = expectedXp;
            changed = true;
        }

        return changed;
    }

    private sealed record SeedExercise(
        string Name,
        string Description,
        WorkoutCategory Category,
        ExerciseDifficulty Difficulty,
        int DailyLimit,
        string Unit);

    private static readonly IReadOnlyList<SeedExercise> DefaultExercises =
    [
        new("Push-Ups", "Klassische Liegestuetze", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 200, "Reps"),
        new("Sit-Ups", "Bauchmuskeltraining", WorkoutCategory.Core, ExerciseDifficulty.Easy, 300, "Reps"),
        new("Squats", "Kniebeugen", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 200, "Reps"),
        new("Burpees", "Ganzkoerper-Uebung", WorkoutCategory.Cardio, ExerciseDifficulty.Hard, 100, "Reps"),
        new("Plank", "Unterarmstuetz", WorkoutCategory.Strength, ExerciseDifficulty.Easy, 600, "Time"),
        new("Pull-Ups", "Klimmzuege", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 50, "Reps"),
        new("Jumping Jacks", "Hampelmaenner", WorkoutCategory.Cardio, ExerciseDifficulty.Easy, 500, "Reps"),
        new("Lunges", "Ausfallschritte", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 150, "Reps"),
        new("Mountain Climbers", "Bergsteiger", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 400, "Reps"),
        new("Leg Raises", "Beinheben", WorkoutCategory.Core, ExerciseDifficulty.Medium, 200, "Reps"),

        new("Dips", "Koerpergewicht-Uebung fuer Arme und Brust", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 120, "Reps"),
        new("Shoulder Taps", "Stabilitaet fuer Schultern und Rumpf", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 160, "Reps"),
        new("Glute Bridges", "Aktiviert Gesass und hintere Kette", WorkoutCategory.Strength, ExerciseDifficulty.Easy, 220, "Reps"),
        new("Wall Sit", "Statischer Beinkraft-Hold an der Wand", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 420, "Time"),
        new("Pike Push-Ups", "Schulterfokussierte Liegestuetz-Variante", WorkoutCategory.Strength, ExerciseDifficulty.Hard, 80, "Reps"),
        new("Calf Raises", "Wadenheben fuer Unterschenkelkraft", WorkoutCategory.Strength, ExerciseDifficulty.Easy, 300, "Reps"),
        new("Superman Hold", "Rueckenstrecker und Koerperspannung", WorkoutCategory.Strength, ExerciseDifficulty.Easy, 360, "Time"),
        new("Triceps Push-Ups", "Enge Liegestuetze fuer Trizeps und Brust", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 120, "Reps"),
        new("Step-Ups", "Einbeinige Beinkraft auf einer stabilen Erhoehung", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 180, "Reps"),
        new("Bear Crawl", "Kraft und Koordination im Vierfuesslergang", WorkoutCategory.Strength, ExerciseDifficulty.Hard, 300, "Time"),

        new("High Knees", "Schnelle Kniehebelauf-Intervalle", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 360, "Time"),
        new("Skater Jumps", "Seitliche Spruenge fuer Ausdauer und Balance", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 180, "Reps"),
        new("Butt Kicks", "Laufbewegung mit Fersen Richtung Gesass", WorkoutCategory.Cardio, ExerciseDifficulty.Easy, 360, "Time"),
        new("Fast Feet", "Schnelle Fussarbeit auf der Stelle", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 300, "Time"),
        new("Jump Squats", "Explosive Kniebeugen mit Sprung", WorkoutCategory.Cardio, ExerciseDifficulty.Hard, 120, "Reps"),
        new("Star Jumps", "Explosive Hampelmann-Variante", WorkoutCategory.Cardio, ExerciseDifficulty.Hard, 120, "Reps"),
        new("Running in Place", "Locker bis intensiv auf der Stelle laufen", WorkoutCategory.Cardio, ExerciseDifficulty.Easy, 600, "Time"),
        new("Jump Rope", "Seilspringen fuer Koordination und Kondition", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 600, "Time"),
        new("Side Shuffles", "Seitliche Schritte fuer Agilitaet", WorkoutCategory.Cardio, ExerciseDifficulty.Easy, 300, "Time"),
        new("Shadow Boxing", "Boxkombinationen ohne Gegner", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 600, "Time"),

        new("Russian Twists", "Rotation fuer seitliche Bauchmuskeln", WorkoutCategory.Core, ExerciseDifficulty.Medium, 220, "Reps"),
        new("Bicycle Crunches", "Dynamische Crunches mit Beinwechsel", WorkoutCategory.Core, ExerciseDifficulty.Medium, 240, "Reps"),
        new("Dead Bug", "Kontrollierte Rumpfstabilitaet in Rueckenlage", WorkoutCategory.Core, ExerciseDifficulty.Easy, 180, "Reps"),
        new("Hollow Hold", "Statischer Core-Hold mit hoher Spannung", WorkoutCategory.Core, ExerciseDifficulty.Hard, 300, "Time"),
        new("Side Plank", "Seitlicher Unterarmstuetz", WorkoutCategory.Core, ExerciseDifficulty.Medium, 360, "Time"),
        new("Flutter Kicks", "Schnelle Beinwechsel fuer den unteren Bauch", WorkoutCategory.Core, ExerciseDifficulty.Medium, 300, "Reps"),
        new("Heel Touches", "Seitliche Bauchmuskeln mit kurzen Crunches", WorkoutCategory.Core, ExerciseDifficulty.Easy, 240, "Reps"),
        new("V-Ups", "Ganzkoerper-Crunch mit gestreckten Armen und Beinen", WorkoutCategory.Core, ExerciseDifficulty.Hard, 120, "Reps"),
        new("Reverse Crunches", "Kontrolliertes Anheben der Huefte", WorkoutCategory.Core, ExerciseDifficulty.Medium, 180, "Reps"),
        new("Bird Dog", "Rumpfstabilitaet mit diagonalem Arm-Bein-Heben", WorkoutCategory.Core, ExerciseDifficulty.Easy, 180, "Reps"),
        new("Scissor Kicks", "Gekreuzte Beinbewegung fuer den unteren Bauch", WorkoutCategory.Core, ExerciseDifficulty.Medium, 240, "Reps"),

        new("Hamstring Stretch", "Dehnung fuer die Beinrueckseite", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 300, "Time"),
        new("Hip Flexor Stretch", "Dehnung fuer Hueftbeuger und vordere Huefte", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 300, "Time"),
        new("Cat-Cow Stretch", "Mobilisiert Wirbelsaeule und Rumpf", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Reps"),
        new("Child's Pose", "Ruhige Dehnung fuer Ruecken und Schultern", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 300, "Time"),
        new("Cobra Stretch", "Oeffnet Brust und Bauchvorderseite", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Time"),
        new("Shoulder Stretch", "Dehnung fuer Schulter und oberen Ruecken", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Time"),
        new("Chest Opener", "Oeffnet Brust und vordere Schulter", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Time"),
        new("Butterfly Stretch", "Dehnung fuer Innenschenkel und Huefte", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 300, "Time"),
        new("Calf Stretch", "Dehnung fuer die Waden", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Time")
    ];
}
