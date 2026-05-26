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

        if (existing.Description != defaults.Description)
        {
            existing.Description = defaults.Description;
            changed = true;
        }

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
        new("Push-Ups", "Klassische Liegestütze", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 200, "Reps"),
        new("Sit-Ups", "Bauchmuskeltraining", WorkoutCategory.Core, ExerciseDifficulty.Easy, 300, "Reps"),
        new("Squats", "Kniebeugen", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 200, "Reps"),
        new("Burpees", "Ganzkörper-Übung", WorkoutCategory.Cardio, ExerciseDifficulty.Hard, 100, "Reps"),
        new("Plank", "Unterarmstütz", WorkoutCategory.Strength, ExerciseDifficulty.Easy, 600, "Time"),
        new("Pull-Ups", "Klimmzüge", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 50, "Reps"),
        new("Jumping Jacks", "Hampelmänner", WorkoutCategory.Cardio, ExerciseDifficulty.Easy, 500, "Reps"),
        new("Lunges", "Ausfallschritte", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 150, "Reps"),
        new("Mountain Climbers", "Bergsteiger", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 400, "Reps"),
        new("Leg Raises", "Beinheben", WorkoutCategory.Core, ExerciseDifficulty.Medium, 200, "Reps"),

        new("Dips", "Körpergewicht-Übung für Arme und Brust", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 120, "Reps"),
        new("Shoulder Taps", "Stabilität für Schultern und Rumpf", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 160, "Reps"),
        new("Glute Bridges", "Aktiviert Gesäß und hintere Kette", WorkoutCategory.Strength, ExerciseDifficulty.Easy, 220, "Reps"),
        new("Wall Sit", "Statischer Beinkraft-Hold an der Wand", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 420, "Time"),
        new("Pike Push-Ups", "Schulterfokussierte Liegestütz-Variante", WorkoutCategory.Strength, ExerciseDifficulty.Hard, 80, "Reps"),
        new("Calf Raises", "Wadenheben für Unterschenkelkraft", WorkoutCategory.Strength, ExerciseDifficulty.Easy, 300, "Reps"),
        new("Superman Hold", "Rückenstrecker und Körperspannung", WorkoutCategory.Strength, ExerciseDifficulty.Easy, 360, "Time"),
        new("Triceps Push-Ups", "Enge Liegestütze für Trizeps und Brust", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 120, "Reps"),
        new("Step-Ups", "Einbeinige Beinkraft auf einer stabilen Erhöhung", WorkoutCategory.Strength, ExerciseDifficulty.Medium, 180, "Reps"),
        new("Bear Crawl", "Kraft und Koordination im Vierfüßlergang", WorkoutCategory.Strength, ExerciseDifficulty.Hard, 300, "Time"),

        new("High Knees", "Schnelle Kniehebelauf-Intervalle", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 360, "Time"),
        new("Skater Jumps", "Seitliche Sprünge für Ausdauer und Balance", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 180, "Reps"),
        new("Butt Kicks", "Laufbewegung mit Fersen Richtung Gesäß", WorkoutCategory.Cardio, ExerciseDifficulty.Easy, 360, "Time"),
        new("Fast Feet", "Schnelle Fußarbeit auf der Stelle", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 300, "Time"),
        new("Jump Squats", "Explosive Kniebeugen mit Sprung", WorkoutCategory.Cardio, ExerciseDifficulty.Hard, 120, "Reps"),
        new("Star Jumps", "Explosive Hampelmann-Variante", WorkoutCategory.Cardio, ExerciseDifficulty.Hard, 120, "Reps"),
        new("Running in Place", "Locker bis intensiv auf der Stelle laufen", WorkoutCategory.Cardio, ExerciseDifficulty.Easy, 600, "Time"),
        new("Jump Rope", "Seilspringen für Koordination und Kondition", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 600, "Time"),
        new("Side Shuffles", "Seitliche Schritte für Agilität", WorkoutCategory.Cardio, ExerciseDifficulty.Easy, 300, "Time"),
        new("Shadow Boxing", "Boxkombinationen ohne Gegner", WorkoutCategory.Cardio, ExerciseDifficulty.Medium, 600, "Time"),

        new("Russian Twists", "Rotation für seitliche Bauchmuskeln", WorkoutCategory.Core, ExerciseDifficulty.Medium, 220, "Reps"),
        new("Bicycle Crunches", "Dynamische Crunches mit Beinwechsel", WorkoutCategory.Core, ExerciseDifficulty.Medium, 240, "Reps"),
        new("Dead Bug", "Kontrollierte Rumpfstabilität in Rückenlage", WorkoutCategory.Core, ExerciseDifficulty.Easy, 180, "Reps"),
        new("Hollow Hold", "Statischer Core-Hold mit hoher Spannung", WorkoutCategory.Core, ExerciseDifficulty.Hard, 300, "Time"),
        new("Side Plank", "Seitlicher Unterarmstütz", WorkoutCategory.Core, ExerciseDifficulty.Medium, 360, "Time"),
        new("Flutter Kicks", "Schnelle Beinwechsel für den unteren Bauch", WorkoutCategory.Core, ExerciseDifficulty.Medium, 300, "Reps"),
        new("Heel Touches", "Seitliche Bauchmuskeln mit kurzen Crunches", WorkoutCategory.Core, ExerciseDifficulty.Easy, 240, "Reps"),
        new("V-Ups", "Ganzkörper-Crunch mit gestreckten Armen und Beinen", WorkoutCategory.Core, ExerciseDifficulty.Hard, 120, "Reps"),
        new("Reverse Crunches", "Kontrolliertes Anheben der Hüfte", WorkoutCategory.Core, ExerciseDifficulty.Medium, 180, "Reps"),
        new("Bird Dog", "Rumpfstabilität mit diagonalem Arm-Bein-Heben", WorkoutCategory.Core, ExerciseDifficulty.Easy, 180, "Reps"),
        new("Scissor Kicks", "Gekreuzte Beinbewegung für den unteren Bauch", WorkoutCategory.Core, ExerciseDifficulty.Medium, 240, "Reps"),

        new("Hamstring Stretch", "Dehnung für die Beinrückseite", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 300, "Time"),
        new("Hip Flexor Stretch", "Dehnung für Hüftbeuger und vordere Hüfte", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 300, "Time"),
        new("Cat-Cow Stretch", "Mobilisiert Wirbelsäule und Rumpf", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Reps"),
        new("Child's Pose", "Ruhige Dehnung für Rücken und Schultern", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 300, "Time"),
        new("Cobra Stretch", "Öffnet Brust und Bauchvorderseite", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Time"),
        new("Shoulder Stretch", "Dehnung für Schulter und oberen Rücken", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Time"),
        new("Chest Opener", "Öffnet Brust und vordere Schulter", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Time"),
        new("Butterfly Stretch", "Dehnung für Innenschenkel und Hüfte", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 300, "Time"),
        new("Calf Stretch", "Dehnung für die Waden", WorkoutCategory.Flexibility, ExerciseDifficulty.Easy, 240, "Time")
    ];
}
